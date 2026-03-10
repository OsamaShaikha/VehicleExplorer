# Windows SSH Setup Guide

## Problem: SSH Command Not Found on Windows

```
ssh : The term 'ssh' is not recognized...
```

---

## ✅ Solution 1: Use Git Bash (Easiest)

### If you have Git installed:

1. Open **Git Bash** (search in Start menu)
2. Navigate to your key location:
   ```bash
   cd /c/Users/YourUsername/Downloads
   ```
3. Set key permissions:
   ```bash
   chmod 400 vehicle-explorer-key.pem
   ```
4. Connect:
   ```bash
   ssh -i vehicle-explorer-key.pem ec2-user@13.49.138.123
   ```

**Download Git**: https://git-scm.com/download/win

---

## ✅ Solution 2: Install OpenSSH on Windows

### Step 1: Open PowerShell as Administrator
- Right-click Start → **Windows PowerShell (Admin)**

### Step 2: Install OpenSSH
```powershell
# Install OpenSSH Client
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0

# Verify installation
ssh -V
```

### Step 3: Connect
```powershell
# Navigate to key location
cd C:\Users\YourUsername\Downloads

# Connect
ssh -i vehicle-explorer-key.pem ec2-user@13.49.138.123
```

---

## ✅ Solution 3: Use PuTTY (GUI Tool)

### Step 1: Download PuTTY
- Download from: https://www.putty.org/
- Install with default options

### Step 2: Convert .pem to .ppk
1. Open **PuTTYgen** (installed with PuTTY)
2. Click **Load**
3. Change file filter to "All Files (*.*)"
4. Select your `vehicle-explorer-key.pem`
5. Click **Save private key**
6. Click **Yes** (save without passphrase)
7. Save as `vehicle-explorer-key.ppk`

### Step 3: Connect with PuTTY
1. Open **PuTTY**
2. **Session** settings:
   - Host Name: `ec2-user@13.49.138.123`
   - Port: `22`
   - Connection type: `SSH`
3. **Connection → SSH → Auth → Credentials**:
   - Click **Browse**
   - Select your `vehicle-explorer-key.ppk` file
4. (Optional) Save session:
   - Go back to **Session**
   - Saved Sessions: `vehicle-explorer`
   - Click **Save**
5. Click **Open**
6. Click **Accept** (trust host key)

You're connected! 🎉

---

## ✅ Solution 4: AWS Session Manager (No SSH Needed!)

### Most Secure - No SSH, No Keys, No Open Ports!

### Step 1: Attach IAM Role to Instance
1. Go to **EC2 Console** → **Instances**
2. Select your instance
3. **Actions** → **Security** → **Modify IAM role**
4. If no role exists:
   - Go to **IAM Console** → **Roles** → **Create role**
   - Trusted entity: **EC2**
   - Attach policy: `AmazonSSMManagedInstanceCore`
   - Name: `EC2-SSM-Role`
   - Create role
5. Select the role → **Update IAM role**
6. Wait 5 minutes for SSM agent to register

### Step 2: Connect via Session Manager
1. Go to **EC2 Console** → **Instances**
2. Select your instance
3. Click **Connect** button
4. Select **Session Manager** tab
5. Click **Connect**

Browser-based terminal opens! ✨

**Benefits:**
- ✅ No SSH installation needed
- ✅ No key management
- ✅ No open ports (port 22 can be closed)
- ✅ Full audit trail
- ✅ MFA support
- ✅ Works from any browser

**See full guide**: `ZERO_STANDING_PRIVILEGES_GUIDE.md`

---

## 🎯 Which Method Should I Use?

| Method | Difficulty | Security | Best For |
|--------|-----------|----------|----------|
| **Git Bash** | ⭐ Easy | ⭐⭐ Good | Quick start |
| **OpenSSH** | ⭐⭐ Medium | ⭐⭐ Good | PowerShell users |
| **PuTTY** | ⭐⭐ Medium | ⭐⭐ Good | GUI preference |
| **Session Manager** | ⭐ Easy | ⭐⭐⭐ Best | Production use |

**Recommendation**: Use **Session Manager** for production, **Git Bash** for quick testing.

---

## 🔧 Troubleshooting

### "Permission denied (publickey)"

**Cause**: Wrong key permissions or wrong key file

**Solution**:
```bash
# In Git Bash
chmod 400 vehicle-explorer-key.pem
ssh -i vehicle-explorer-key.pem ec2-user@13.49.138.123
```

### "Connection timed out"

**Cause**: Security group doesn't allow SSH (port 22)

**Solution**:
1. Go to **EC2** → **Security Groups**
2. Select your security group
3. **Inbound rules** → **Edit inbound rules**
4. Add rule:
   - Type: SSH
   - Port: 22
   - Source: My IP
5. Save rules

### "Host key verification failed"

**Cause**: First time connecting

**Solution**: Type `yes` when prompted

### "Bad permissions" error on Windows

**Cause**: Windows doesn't support chmod

**Solution**: Use PuTTY or Session Manager instead

---

## 📋 Quick Command Reference

### Git Bash / Linux / Mac
```bash
# Set permissions
chmod 400 vehicle-explorer-key.pem

# Connect
ssh -i vehicle-explorer-key.pem ec2-user@YOUR-IP

# Copy files to server
scp -i vehicle-explorer-key.pem file.txt ec2-user@YOUR-IP:/home/ec2-user/

# Copy folder to server
scp -i vehicle-explorer-key.pem -r folder/ ec2-user@YOUR-IP:/home/ec2-user/
```

### PowerShell (after OpenSSH installed)
```powershell
# Connect
ssh -i vehicle-explorer-key.pem ec2-user@YOUR-IP

# Copy files
scp -i vehicle-explorer-key.pem file.txt ec2-user@YOUR-IP:/home/ec2-user/
```

### Session Manager (AWS CLI)
```powershell
# Install Session Manager plugin first
# Download from: https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html

# Connect
aws ssm start-session --target i-1234567890abcdef0

# Port forwarding (for RDP, databases, etc.)
aws ssm start-session --target i-1234567890abcdef0 --document-name AWS-StartPortForwardingSession --parameters "portNumber=22,localPortNumber=9999"
```

---

## 🎉 Summary

**Quickest solution**: Use **Git Bash** (if Git installed)

**Best for production**: Use **Session Manager** (no SSH needed)

**For GUI lovers**: Use **PuTTY**

**Your EC2 IP**: `13.49.138.123`

**Your key file**: `vehicle-explorer-key.pem`

**Connect command**:
```bash
ssh -i vehicle-explorer-key.pem ec2-user@13.49.138.123
```

---

**Need more help? Check the deployment guides!**
- Linux deployment: `AWS_DEPLOYMENT_STEPS.md`
- Windows deployment: `AWS_DEPLOYMENT_STEPS_WINDOWS.md`
- Zero Standing Privileges: `ZERO_STANDING_PRIVILEGES_GUIDE.md`
