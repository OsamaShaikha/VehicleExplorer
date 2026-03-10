# AWS Deployment - Quick Steps

## 🎯 Goal
Deploy Vehicle Explorer to AWS EC2 (Free Tier) using Docker

## ⏱️ Time Required
30-45 minutes

---

## ✅ Pre-Deployment Checklist

- [ ] AWS Account created
- [ ] Credit card added to AWS (required even for Free Tier)
- [ ] Project pushed to GitHub (or have the code ready)
- [ ] Docker files tested locally

---

## 📋 Step-by-Step Deployment

### Step 1: Create EC2 Instance (5 minutes)

1. Go to [AWS Console](https://console.aws.amazon.com/)
2. Search for "EC2" and click on it
3. Click **"Launch Instance"** (orange button)
4. Fill in the details:

```
Name: vehicle-explorer
Application and OS Images: Amazon Linux 2023 (Free tier eligible)
Instance type: t2.micro (Free tier eligible)
Key pair: Click "Create new key pair"
  - Name: vehicle-explorer-key
  - Type: RSA
  - Format: .pem
  - Click "Create key pair" (downloads .pem file)
```

5. Network settings - Click **"Edit"**:
   - Auto-assign public IP: Enable
   - Firewall (security groups): Create security group
   - Security group name: vehicle-explorer-sg
   - Add rules:
     - ✅ SSH (port 22) - My IP
     - ✅ HTTP (port 80) - Anywhere (0.0.0.0/0)
     - ✅ HTTPS (port 443) - Anywhere (0.0.0.0/0)

6. Storage: 8 GB (default is fine)

7. Click **"Launch instance"** (orange button)

8. Wait 2-3 minutes for instance to start

9. Click on your instance and note the **Public IPv4 address**

---

### Step 2: Connect to Your Server (2 minutes)

**On Windows (using PowerShell or Git Bash):**

```bash
# Navigate to where you downloaded the .pem file
cd Downloads

# Set permissions (Git Bash)
chmod 400 vehicle-explorer-key.pem

# Connect to EC2
ssh -i vehicle-explorer-key.pem ec2-user@YOUR-EC2-PUBLIC-IP
```

**Replace `YOUR-EC2-PUBLIC-IP` with the actual IP from Step 1**

Example: `ssh -i vehicle-explorer-key.pem ec2-user@3.15.123.456`

Type "yes" when asked about fingerprint.

You should now see a terminal prompt like: `[ec2-user@ip-xxx ~]$`

---

### Step 3: Install Docker (5 minutes)

Copy and paste these commands one by one:

```bash
# Update system
sudo yum update -y

# Install Docker
sudo yum install docker -y

# Start Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add your user to docker group
sudo usermod -a -G docker ec2-user

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Make it executable
sudo chmod +x /usr/local/bin/docker-compose

# Verify installations
docker --version
docker-compose --version
```

**Important**: Log out and back in for docker group to take effect:

```bash
exit
```

Then reconnect:
```bash
ssh -i vehicle-explorer-key.pem ec2-user@YOUR-EC2-PUBLIC-IP
```

---

### Step 4: Deploy Your Application (10 minutes)

```bash
# Install Git
sudo yum install git -y

# Clone your repository
git clone https://github.com/YOUR-USERNAME/vehicle-explorer.git
cd vehicle-explorer

# Update the production docker-compose file
# Edit the AllowedOrigins to use your EC2 IP
nano docker-compose.prod.yml
```

In the nano editor, find the backend environment section and update:
```yaml
environment:
  - ASPNETCORE_ENVIRONMENT=Production
  - AllowedOrigins=http://YOUR-EC2-PUBLIC-IP
```

Press `Ctrl+X`, then `Y`, then `Enter` to save.

```bash
# Build and start the application
docker-compose -f docker-compose.prod.yml up -d --build
```

This will take 5-10 minutes to build. You'll see:
- Building backend...
- Building frontend...
- Starting containers...

```bash
# Check if containers are running
docker-compose -f docker-compose.prod.yml ps
```

You should see both `backend` and `frontend` with status "Up".

---

### Step 5: Test Your Application (2 minutes)

Open your browser and go to:

```
http://YOUR-EC2-PUBLIC-IP
```

You should see the Vehicle Explorer application!

Test the API:
```
http://YOUR-EC2-PUBLIC-IP/api/vehicles/makes
```

You should see JSON data with car makes.

---

## 🎉 Success! Your App is Live!

Your application is now running on AWS at: `http://YOUR-EC2-PUBLIC-IP`

---

## 🔧 Useful Commands

### View Application Logs
```bash
# All logs
docker-compose -f docker-compose.prod.yml logs -f

# Backend only
docker-compose -f docker-compose.prod.yml logs -f backend

# Frontend only
docker-compose -f docker-compose.prod.yml logs -f frontend
```

### Restart Application
```bash
docker-compose -f docker-compose.prod.yml restart
```

### Stop Application
```bash
docker-compose -f docker-compose.prod.yml down
```

### Update Application (after code changes)
```bash
cd vehicle-explorer
git pull origin main
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml up -d --build
```

---

## 🛑 Troubleshooting

### Can't access the application?

1. **Check security group**:
   - Go to EC2 → Security Groups
   - Find `vehicle-explorer-sg`
   - Verify port 80 is open to 0.0.0.0/0

2. **Check containers are running**:
   ```bash
   docker-compose -f docker-compose.prod.yml ps
   ```

3. **Check logs for errors**:
   ```bash
   docker-compose -f docker-compose.prod.yml logs
   ```

### CORS errors?

Update the backend environment in `docker-compose.prod.yml`:
```yaml
- AllowedOrigins=http://YOUR-EC2-PUBLIC-IP
```

Then restart:
```bash
docker-compose -f docker-compose.prod.yml restart backend
```

---

## 💰 Cost Management

### Free Tier Limits (12 months)
- ✅ 750 hours/month of t2.micro (enough for 1 instance running 24/7)
- ✅ 30 GB of EBS storage
- ✅ 15 GB data transfer out per month

### To Avoid Charges
1. **Stop instance when not using** (doesn't count toward 750 hours)
2. **Set up billing alerts**:
   - AWS Console → Billing → Billing Preferences
   - Enable "Receive Billing Alerts"
   - Set alert at $1, $5, $10

### Stop Instance (saves hours)
```
EC2 Dashboard → Instances → Select instance → Instance State → Stop
```

### Start Instance Again
```
EC2 Dashboard → Instances → Select instance → Instance State → Start
```

**Note**: Public IP changes when you stop/start. Use Elastic IP (free if attached to running instance) to keep same IP.

---

## 🌐 Optional: Add Custom Domain

If you have a domain name (e.g., vehicleexplorer.com):

1. **Get Elastic IP** (keeps IP permanent):
   - EC2 → Elastic IPs → Allocate Elastic IP
   - Actions → Associate → Select your instance

2. **Update DNS**:
   - Go to your domain registrar
   - Add A record: `@` → `YOUR-ELASTIC-IP`
   - Add A record: `www` → `YOUR-ELASTIC-IP`

3. **Update CORS**:
   ```yaml
   - AllowedOrigins=http://vehicleexplorer.com,http://www.vehicleexplorer.com
   ```

4. **Add SSL (HTTPS)** - See full guide in `infrastructure/aws-setup.md`

---

## 📚 Next Steps

- [ ] Set up billing alerts
- [ ] Create AMI backup of your instance
- [ ] Add SSL certificate (Let's Encrypt)
- [ ] Set up monitoring (CloudWatch)
- [ ] Configure automatic backups

For detailed instructions, see: `infrastructure/aws-setup.md`

---

## 🆘 Need Help?

- Full deployment guide: `infrastructure/aws-setup.md`
- AWS Free Tier: https://aws.amazon.com/free/
- AWS Support: https://console.aws.amazon.com/support/

---

**Congratulations! You've deployed your application to AWS! 🚀**
