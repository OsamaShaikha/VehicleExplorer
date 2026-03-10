# Zero Standing Privileges (ZSP) Implementation Guide

## 🎯 Overview

This guide implements **Zero Standing Privileges** for AWS EC2 instances, requiring operators to request access before connecting. This approach:

- ✅ Eliminates permanent access credentials
- ✅ Removes need for open RDP/SSH ports (closes security group ports 22 and 3389)
- ✅ Provides audit trail of all access requests and sessions
- ✅ Implements just-in-time (JIT) access
- ✅ Reduces attack surface significantly

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Operator Workflow                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. Operator requests access via AWS Console/CLI           │
│                         ↓                                   │
│  2. IAM policy evaluates request (MFA required)            │
│                         ↓                                   │
│  3. If approved, temporary session token generated         │
│                         ↓                                   │
│  4. Systems Manager Session Manager establishes session    │
│                         ↓                                   │
│  5. All commands logged to CloudWatch & S3                 │
│                         ↓                                   │
│  6. Session auto-terminates after timeout                  │
│                                                             │
└─────────────────────────────────────────────────────────────┘

No open ports (22/3389) required!
```

## 📋 Implementation Steps

### Step 1: Create IAM Role for EC2 Instances (5 minutes)

This role allows EC2 instances to communicate with Systems Manager.

#### 1.1 Create IAM Role

1. Go to **IAM Console** → **Roles** → **Create role**
2. Select trusted entity:
   - **Trusted entity type**: AWS service
   - **Use case**: EC2
   - Click **Next**

3. Attach permissions policies:
   - Search and select: `AmazonSSMManagedInstanceCore`
   - Search and select: `CloudWatchAgentServerPolicy` (for logging)
   - Click **Next**

4. Name and create:
   - **Role name**: `VehicleExplorer-SSM-Role`
   - **Description**: "Allows EC2 instances to use Systems Manager"
   - Click **Create role**

#### 1.2 Attach Role to EC2 Instance

**For existing instance:**
```
EC2 Console → Instances → Select your instance
Actions → Security → Modify IAM role
Select: VehicleExplorer-SSM-Role
Click: Update IAM role
```

**For new instance:**
- During launch, under "IAM instance profile", select `VehicleExplorer-SSM-Role`

---

### Step 2: Remove Open Ports from Security Group (2 minutes)

Now that we're using Session Manager, we can close the RDP/SSH ports.

#### 2.1 Update Security Group

1. Go to **EC2 Console** → **Security Groups**
2. Select your security group (e.g., `vehicle-explorer-sg`)
3. Click **Inbound rules** tab
4. Click **Edit inbound rules**
5. **Remove these rules**:
   - ❌ RDP (port 3389)
   - ❌ SSH (port 22)
6. **Keep these rules**:
   - ✅ HTTP (port 80) - for web traffic
   - ✅ HTTPS (port 443) - for web traffic
   - ✅ Custom TCP (port 5000) - for API (if needed)
7. Click **Save rules**

**Important**: No inbound management ports needed! Session Manager uses outbound HTTPS (443) to AWS services.

---

### Step 3: Create IAM Policy for Operators (10 minutes)

This policy defines who can request access and under what conditions.

#### 3.1 Create Custom IAM Policy

1. Go to **IAM Console** → **Policies** → **Create policy**
2. Click **JSON** tab
3. Paste this policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowStartSession",
      "Effect": "Allow",
      "Action": [
        "ssm:StartSession"
      ],
      "Resource": [
        "arn:aws:ec2:*:*:instance/*"
      ],
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "us-east-1"
        },
        "StringLike": {
          "ssm:resourceTag/Environment": [
            "production",
            "staging",
            "development"
          ]
        },
        "Bool": {
          "aws:MultiFactorAuthPresent": "true"
        }
      }
    },
    {
      "Sid": "AllowSessionManagerActions",
      "Effect": "Allow",
      "Action": [
        "ssm:DescribeSessions",
        "ssm:GetConnectionStatus",
        "ssm:DescribeInstanceProperties",
        "ssm:TerminateSession",
        "ec2:DescribeInstances"
      ],
      "Resource": "*"
    },
    {
      "Sid": "AllowSessionDocuments",
      "Effect": "Allow",
      "Action": [
        "ssm:StartSession"
      ],
      "Resource": [
        "arn:aws:ssm:*:*:document/AWS-StartSSHSession",
        "arn:aws:ssm:*:*:document/AWS-StartPortForwardingSession",
        "arn:aws:ssm:*:*:document/SSM-SessionManagerRunShell"
      ]
    }
  ]
}
```

4. Click **Next: Tags** (optional)
5. Click **Next: Review**
6. Name: `VehicleExplorer-SessionManager-Access`
7. Description: "Allows operators to request session access with MFA"
8. Click **Create policy**

#### 3.2 Key Policy Features

- ✅ **MFA Required**: `"aws:MultiFactorAuthPresent": "true"`
- ✅ **Region Restricted**: Only allows access in specified region
- ✅ **Tag-Based Access**: Only instances with specific tags
- ✅ **Audit Trail**: All actions logged to CloudTrail

---

### Step 4: Create IAM Group for Operators (5 minutes)

#### 4.1 Create Operator Group

1. Go to **IAM Console** → **User groups** → **Create group**
2. **Group name**: `VehicleExplorer-Operators`
3. **Attach permissions policies**:
   - Search and select: `VehicleExplorer-SessionManager-Access` (created above)
   - Search and select: `ReadOnlyAccess` (optional, for viewing resources)
4. Click **Create group**

#### 4.2 Add Users to Group

1. Select the group `VehicleExplorer-Operators`
2. Click **Add users**
3. Select users who need access
4. Click **Add users**

---

### Step 5: Enforce MFA for All Operators (10 minutes)

#### 5.1 Create MFA Enforcement Policy

1. Go to **IAM Console** → **Policies** → **Create policy**
2. Click **JSON** tab
3. Paste this policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyAllExceptListedIfNoMFA",
      "Effect": "Deny",
      "NotAction": [
        "iam:CreateVirtualMFADevice",
        "iam:EnableMFADevice",
        "iam:GetUser",
        "iam:ListMFADevices",
        "iam:ListVirtualMFADevices",
        "iam:ResyncMFADevice",
        "sts:GetSessionToken",
        "iam:ChangePassword",
        "iam:GetAccountPasswordPolicy"
      ],
      "Resource": "*",
      "Condition": {
        "BoolIfExists": {
          "aws:MultiFactorAuthPresent": "false"
        }
      }
    }
  ]
}
```

4. Name: `Require-MFA-Policy`
5. Click **Create policy**

#### 5.2 Attach to Operator Group

1. Go to **User groups** → `VehicleExplorer-Operators`
2. Click **Permissions** tab → **Add permissions** → **Attach policies**
3. Search and select: `Require-MFA-Policy`
4. Click **Attach policies**

#### 5.3 Setup MFA for Users

Each operator must set up MFA:

1. Go to **IAM Console** → **Users** → Select your user
2. Click **Security credentials** tab
3. Under **Multi-factor authentication (MFA)**, click **Assign MFA device**
4. Choose device type:
   - **Virtual MFA device** (recommended): Use Google Authenticator, Authy, etc.
   - **Hardware TOTP token**: Physical device
5. Follow the setup wizard
6. Click **Assign MFA**

---

### Step 6: Tag EC2 Instances for Access Control (2 minutes)

Tags determine which instances operators can access.

#### 6.1 Add Tags to Instance

1. Go to **EC2 Console** → **Instances**
2. Select your instance
3. Click **Tags** tab → **Manage tags**
4. Add these tags:
   - Key: `Environment`, Value: `production` (or `staging`, `development`)
   - Key: `Application`, Value: `VehicleExplorer`
   - Key: `Owner`, Value: `YourTeamName`
5. Click **Save**

---

### Step 7: Configure Session Manager Logging (10 minutes)

Enable comprehensive logging of all session activity.

#### 7.1 Create S3 Bucket for Session Logs

```powershell
# Using AWS CLI or PowerShell
aws s3 mb s3://vehicle-explorer-session-logs-YOUR-ACCOUNT-ID --region us-east-1
```

Or via Console:
1. Go to **S3 Console** → **Create bucket**
2. **Bucket name**: `vehicle-explorer-session-logs-YOUR-ACCOUNT-ID`
3. **Region**: Same as your EC2 instances
4. **Block all public access**: Enabled
5. Click **Create bucket**

#### 7.2 Create CloudWatch Log Group

1. Go to **CloudWatch Console** → **Log groups** → **Create log group**
2. **Log group name**: `/aws/ssm/vehicle-explorer-sessions`
3. **Retention**: 30 days (or as required)
4. Click **Create**

#### 7.3 Configure Session Manager Preferences

1. Go to **Systems Manager Console** → **Session Manager**
2. Click **Preferences** tab → **Edit**
3. Configure settings:

**General:**
- ✅ Enable Run As support for Linux instances
- ✅ Enable KMS encryption (optional but recommended)

**CloudWatch logging:**
- ✅ Enable CloudWatch logging
- Log group name: `/aws/ssm/vehicle-explorer-sessions`

**S3 logging:**
- ✅ Enable S3 logging
- S3 bucket name: `vehicle-explorer-session-logs-YOUR-ACCOUNT-ID`
- S3 key prefix: `session-logs/`
- ✅ Encrypt log data (optional)

**Session timeout:**
- Idle session timeout: `20 minutes`
- Max session duration: `60 minutes`

4. Click **Save**

---

### Step 8: Connect Using Session Manager (5 minutes)

Now operators can request access without open ports!

#### 8.1 Connect via AWS Console (Easiest)

1. Go to **EC2 Console** → **Instances**
2. Select your instance
3. Click **Connect** button
4. Select **Session Manager** tab
5. Click **Connect**

A browser-based terminal opens with full access!

#### 8.2 Connect via AWS CLI

**Prerequisites:**
```powershell
# Install AWS CLI
# Download from: https://aws.amazon.com/cli/

# Install Session Manager plugin
# Download from: https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html
```

**Start Session:**
```powershell
# List available instances
aws ec2 describe-instances --filters "Name=tag:Application,Values=VehicleExplorer" --query "Reservations[].Instances[].[InstanceId,Tags[?Key=='Name'].Value|[0],State.Name]" --output table

# Start session (replace INSTANCE-ID)
aws ssm start-session --target i-1234567890abcdef0

# For Windows PowerShell session
aws ssm start-session --target i-1234567890abcdef0 --document-name AWS-StartInteractiveCommand --parameters command="powershell.exe"
```

#### 8.3 Port Forwarding (for RDP/SSH)

You can forward ports without opening security group rules!

**Forward RDP (Windows):**
```powershell
# Forward local port 9999 to remote port 3389 (RDP)
aws ssm start-session --target i-1234567890abcdef0 --document-name AWS-StartPortForwardingSession --parameters "portNumber=3389,localPortNumber=9999"

# Then connect via RDP to localhost:9999
mstsc /v:localhost:9999
```

**Forward SSH (Linux):**
```bash
# Forward local port 9999 to remote port 22 (SSH)
aws ssm start-session --target i-1234567890abcdef0 --document-name AWS-StartPortForwardingSession --parameters "portNumber=22,localPortNumber=9999"

# Then connect via SSH to localhost:9999
ssh -p 9999 ec2-user@localhost
```

---

## 🔐 Access Request Workflow

### Operator Perspective

```
1. Operator needs to access production instance
   ↓
2. Operator logs into AWS Console with username/password
   ↓
3. AWS prompts for MFA code (Google Authenticator, etc.)
   ↓
4. After MFA verification, operator navigates to EC2
   ↓
5. Operator selects instance and clicks "Connect"
   ↓
6. Session Manager validates:
   - ✅ User has required IAM permissions
   - ✅ MFA was used for login
   - ✅ Instance has correct tags
   - ✅ Request is from allowed region
   ↓
7. If all checks pass, session is granted
   ↓
8. All commands are logged to CloudWatch and S3
   ↓
9. Session auto-terminates after 60 minutes (or idle timeout)
```

### What Gets Logged

Every session logs:
- ✅ Who accessed (IAM user/role)
- ✅ When accessed (timestamp)
- ✅ Which instance (instance ID)
- ✅ What commands were run (full transcript)
- ✅ Session duration
- ✅ Source IP address

---

## 📊 Monitoring and Auditing

### View Active Sessions

**Via Console:**
1. Go to **Systems Manager** → **Session Manager**
2. Click **Session history** tab
3. View all active and terminated sessions

**Via CLI:**
```powershell
# List active sessions
aws ssm describe-sessions --state Active

# List all sessions (last 30 days)
aws ssm describe-sessions --state History
```

### View Session Logs

**CloudWatch Logs:**
1. Go to **CloudWatch** → **Log groups**
2. Select `/aws/ssm/vehicle-explorer-sessions`
3. View log streams (one per session)

**S3 Logs:**
1. Go to **S3** → `vehicle-explorer-session-logs-YOUR-ACCOUNT-ID`
2. Navigate to `session-logs/` folder
3. Download session transcripts

### Create CloudWatch Alarms

**Alert on Unauthorized Access Attempts:**

1. Go to **CloudWatch** → **Alarms** → **Create alarm**
2. Select metric: **Logs** → **Log group** → `/aws/ssm/vehicle-explorer-sessions`
3. Create metric filter:
   - Filter pattern: `[time, request_id, event_type = AccessDenied*]`
   - Metric name: `UnauthorizedSessionAttempts`
4. Set alarm:
   - Threshold: `>= 1` in 5 minutes
   - Action: Send SNS notification to security team

**Alert on Root User Sessions:**

```
Filter pattern: [time, request_id, event_type, user_type = Root*]
```

---

## 🎯 Advanced: Time-Based Access

Restrict access to business hours only.

### Create Time-Based Policy

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowSessionDuringBusinessHours",
      "Effect": "Allow",
      "Action": "ssm:StartSession",
      "Resource": "*",
      "Condition": {
        "DateGreaterThan": {
          "aws:CurrentTime": "2024-01-01T09:00:00Z"
        },
        "DateLessThan": {
          "aws:CurrentTime": "2024-12-31T17:00:00Z"
        },
        "StringEquals": {
          "aws:RequestedRegion": "us-east-1"
        },
        "Bool": {
          "aws:MultiFactorAuthPresent": "true"
        }
      }
    }
  ]
}
```

This allows access only between 9 AM - 5 PM UTC.

---

## 🎯 Advanced: Approval Workflow

Require manager approval before granting access.

### Option 1: AWS Service Catalog

1. Create Service Catalog product for "Request Instance Access"
2. Configure approval workflow
3. Upon approval, temporary IAM role is assigned
4. Role expires after specified duration

### Option 2: Third-Party Tools

- **HashiCorp Boundary**: Enterprise access management
- **Teleport**: Open-source privileged access management
- **CyberArk**: Enterprise PAM solution
- **AWS Control Tower**: For multi-account governance

---

## 🎯 Advanced: Break-Glass Access

Emergency access when Systems Manager is unavailable.

### Create Break-Glass User

1. Create IAM user: `vehicle-explorer-emergency`
2. Attach policy allowing direct EC2 access
3. Store credentials in secure vault (e.g., AWS Secrets Manager)
4. Create CloudWatch alarm on any use of this user
5. Require incident ticket for credential retrieval

**Break-Glass Policy:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "EmergencyAccess",
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "ssm:*"
      ],
      "Resource": "*",
      "Condition": {
        "IpAddress": {
          "aws:SourceIp": "YOUR-OFFICE-IP/32"
        }
      }
    }
  ]
}
```

---

## 📋 Compliance and Audit Checklist

- [ ] All operators have MFA enabled
- [ ] No standing access (no permanent credentials)
- [ ] All RDP/SSH ports closed in security groups
- [ ] Session logging enabled (CloudWatch + S3)
- [ ] CloudWatch alarms configured for unauthorized access
- [ ] Session logs retained for required period (30-90 days)
- [ ] Regular access reviews conducted (quarterly)
- [ ] Break-glass procedures documented
- [ ] Incident response plan includes access revocation
- [ ] All sessions tagged with purpose/ticket number

---

## 🔧 Troubleshooting

### "Waiting for session to start" - Session won't connect

**Causes:**
1. SSM Agent not running on instance
2. Instance doesn't have IAM role attached
3. No internet connectivity (needs to reach AWS endpoints)

**Solutions:**
```powershell
# Check SSM Agent status (on Windows instance)
Get-Service AmazonSSMAgent

# Restart SSM Agent
Restart-Service AmazonSSMAgent

# Check IAM role is attached
# EC2 Console → Instance → Security → IAM role
```

### "User is not authorized to perform: ssm:StartSession"

**Cause:** IAM permissions issue

**Solution:**
1. Verify user is in `VehicleExplorer-Operators` group
2. Verify MFA was used for login
3. Check instance has correct tags
4. Verify region matches policy

### Session logs not appearing

**Cause:** IAM role missing CloudWatch permissions

**Solution:**
Add `CloudWatchAgentServerPolicy` to instance IAM role:
```
IAM → Roles → VehicleExplorer-SSM-Role → Attach policies
Search: CloudWatchAgentServerPolicy
Attach policy
```

---

## 💰 Cost Considerations

### Session Manager Pricing

- ✅ **Session Manager**: FREE (no additional charge)
- ✅ **Systems Manager**: FREE for basic features
- 💵 **CloudWatch Logs**: $0.50 per GB ingested
- 💵 **S3 Storage**: $0.023 per GB per month
- 💵 **Data Transfer**: Standard AWS data transfer rates

### Estimated Monthly Costs

**For 10 operators, 50 sessions/month, 30-minute average:**
- CloudWatch Logs: ~$2-5/month
- S3 Storage: ~$1/month
- **Total: ~$3-6/month**

**Compared to traditional bastion host:**
- EC2 instance: $8-15/month (t2.micro)
- Elastic IP: $3.60/month (if not attached)
- **Savings: ~$5-12/month**

Plus improved security and compliance!

---

## 📚 Additional Resources

- [AWS Systems Manager Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html)
- [IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [Zero Trust Architecture](https://aws.amazon.com/security/zero-trust/)
- [AWS Security Hub](https://aws.amazon.com/security-hub/)
- [AWS CloudTrail](https://aws.amazon.com/cloudtrail/)

---

## 🎉 Summary

You've successfully implemented Zero Standing Privileges! Your infrastructure now:

✅ Requires just-in-time access requests  
✅ Enforces MFA for all access  
✅ Has no open management ports (RDP/SSH)  
✅ Logs all session activity  
✅ Provides complete audit trail  
✅ Reduces attack surface significantly  
✅ Meets compliance requirements (SOC 2, PCI-DSS, HIPAA)  

**Security posture improved from:**
- ❌ Permanent credentials
- ❌ Open ports 22/3389
- ❌ No access logging
- ❌ No MFA requirement

**To:**
- ✅ Just-in-time access
- ✅ No open management ports
- ✅ Complete audit trail
- ✅ MFA enforced

**Next steps:**
1. Train operators on new access workflow
2. Document emergency procedures
3. Schedule quarterly access reviews
4. Monitor CloudWatch alarms
5. Review session logs regularly

---

**Congratulations! You've implemented enterprise-grade Zero Standing Privileges! 🔒**
