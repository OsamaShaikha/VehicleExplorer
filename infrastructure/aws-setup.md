# AWS Deployment Guide - Vehicle Explorer

This guide covers deploying the Vehicle Explorer application to AWS Free Tier using EC2.

## Prerequisites

- AWS Account with Free Tier eligibility
- Basic knowledge of AWS EC2, Security Groups, and SSH
- Git installed on your local machine
- (Optional) Domain name for custom URL

## Deployment Options

### Option A: EC2 with Docker Compose (Recommended)

This is the simplest approach using a single EC2 instance running Docker containers.

#### Step 1: Launch EC2 Instance

1. Log in to [AWS Console](https://console.aws.amazon.com/)
2. Navigate to **EC2 Dashboard**
3. Click **Launch Instance**
4. Configure instance:
   - **Name**: `vehicle-explorer-app`
   - **AMI**: Amazon Linux 2023 (Free Tier eligible)
   - **Instance Type**: `t2.micro` (1 vCPU, 1 GB RAM - Free Tier)
   - **Key Pair**: Create new or select existing (download .pem file)
   - **Network Settings**:
     - Allow SSH (port 22) from your IP
     - Allow HTTP (port 80) from anywhere (0.0.0.0/0)
     - Allow HTTPS (port 443) from anywhere (0.0.0.0/0)
   - **Storage**: 8 GB gp3 (Free Tier includes 30 GB)
5. Click **Launch Instance**

#### Step 2: Connect to EC2 Instance

```bash
# Set permissions on your key file
chmod 400 your-key.pem

# Connect via SSH
ssh -i your-key.pem ec2-user@<EC2-PUBLIC-IP>
```

#### Step 3: Install Docker and Docker Compose

```bash
# Update system packages
sudo yum update -y

# Install Docker
sudo yum install docker -y

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add ec2-user to docker group
sudo usermod -a -G docker ec2-user

# Log out and back in for group changes to take effect
exit
# SSH back in
ssh -i your-key.pem ec2-user@<EC2-PUBLIC-IP>

# Verify Docker installation
docker --version

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify Docker Compose installation
docker-compose --version
```

#### Step 4: Clone and Deploy Application

```bash
# Install Git
sudo yum install git -y

# Clone repository
git clone <YOUR-REPO-URL>
cd vehicle-explorer

# Create production environment file (optional)
cat > .env.production <<EOF
ASPNETCORE_ENVIRONMENT=Production
NHTSA_BASE_URL=https://vpic.nhtsa.dot.gov/api/
ALLOWED_ORIGINS=http://<EC2-PUBLIC-IP>
EOF

# Build and start containers
docker-compose -f docker-compose.prod.yml up -d --build

# Check container status
docker-compose -f docker-compose.prod.yml ps

# View logs
docker-compose -f docker-compose.prod.yml logs -f
```

#### Step 5: Verify Deployment

1. Open browser and navigate to: `http://<EC2-PUBLIC-IP>`
2. Test API: `http://<EC2-PUBLIC-IP>/api/vehicles/makes`
3. Check health: `http://<EC2-PUBLIC-IP>/health`

#### Step 6: Configure Security Group (if needed)

If you can't access the application:

1. Go to EC2 Dashboard → Security Groups
2. Select your instance's security group
3. Edit Inbound Rules:
   - Type: HTTP, Port: 80, Source: 0.0.0.0/0
   - Type: HTTPS, Port: 443, Source: 0.0.0.0/0
   - Type: Custom TCP, Port: 5000, Source: 0.0.0.0/0 (for direct API access)

### Option B: Elastic Beanstalk (Multi-Container Docker)

For a more managed approach with auto-scaling and load balancing.

#### Step 1: Install EB CLI

```bash
pip install awsebcli --upgrade --user
```

#### Step 2: Initialize Elastic Beanstalk

```bash
cd vehicle-explorer
eb init -p docker vehicle-explorer --region us-east-1
```

#### Step 3: Create Dockerrun.aws.json

```json
{
  "AWSEBDockerrunVersion": 2,
  "containerDefinitions": [
    {
      "name": "backend",
      "image": "vehicle-explorer-backend",
      "essential": true,
      "memory": 512,
      "portMappings": [
        {
          "hostPort": 5000,
          "containerPort": 5000
        }
      ],
      "environment": [
        {
          "name": "ASPNETCORE_ENVIRONMENT",
          "value": "Production"
        }
      ]
    },
    {
      "name": "frontend",
      "image": "vehicle-explorer-frontend",
      "essential": true,
      "memory": 256,
      "portMappings": [
        {
          "hostPort": 80,
          "containerPort": 80
        }
      ],
      "links": ["backend"]
    }
  ]
}
```

#### Step 4: Deploy

```bash
eb create vehicle-explorer-env
eb open
```

## Domain Configuration (Optional)

### Using Route 53

1. Register domain in Route 53 or transfer existing domain
2. Create hosted zone
3. Add A record pointing to EC2 Elastic IP
4. Update `AllowedOrigins` in backend configuration

### SSL Certificate with Let's Encrypt

```bash
# SSH into EC2 instance
ssh -i your-key.pem ec2-user@<EC2-PUBLIC-IP>

# Install Certbot
sudo yum install certbot python3-certbot-nginx -y

# Stop containers temporarily
cd vehicle-explorer
docker-compose -f docker-compose.prod.yml down

# Obtain certificate
sudo certbot certonly --standalone -d yourdomain.com -d www.yourdomain.com

# Update nginx.conf to use SSL
# Restart containers
docker-compose -f docker-compose.prod.yml up -d
```

## Monitoring and Maintenance

### View Application Logs

```bash
# All services
docker-compose -f docker-compose.prod.yml logs -f

# Backend only
docker-compose -f docker-compose.prod.yml logs -f backend

# Frontend only
docker-compose -f docker-compose.prod.yml logs -f frontend
```

### Update Application

```bash
cd vehicle-explorer
git pull origin main
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml up -d --build
```

### Restart Services

```bash
# Restart all
docker-compose -f docker-compose.prod.yml restart

# Restart specific service
docker-compose -f docker-compose.prod.yml restart backend
```

### Check Resource Usage

```bash
# Container stats
docker stats

# Disk usage
df -h

# Memory usage
free -m
```

## Cost Optimization

### Free Tier Limits (12 months)

- **EC2**: 750 hours/month of t2.micro
- **EBS**: 30 GB of storage
- **Data Transfer**: 15 GB outbound per month

### Tips to Stay Within Free Tier

1. Use only one t2.micro instance
2. Stop instance when not in use (development/testing)
3. Monitor data transfer in CloudWatch
4. Set up billing alerts in AWS Billing Dashboard
5. Use CloudFront CDN for static assets (50 GB free/month)

## Troubleshooting

### Application Not Accessible

```bash
# Check if containers are running
docker-compose -f docker-compose.prod.yml ps

# Check container logs
docker-compose -f docker-compose.prod.yml logs

# Verify security group allows port 80
# Check EC2 instance public IP hasn't changed
```

### Backend API Errors

```bash
# Check backend logs
docker-compose -f docker-compose.prod.yml logs backend

# Verify NHTSA API is accessible
curl https://vpic.nhtsa.dot.gov/api/vehicles/getallmakes?format=json

# Check environment variables
docker-compose -f docker-compose.prod.yml exec backend env
```

### Out of Memory

```bash
# Check memory usage
free -m

# Restart containers to free memory
docker-compose -f docker-compose.prod.yml restart

# Consider upgrading to t3.small (not free tier)
```

### Docker Disk Space Issues

```bash
# Clean up unused images and containers
docker system prune -a

# Remove old images
docker image prune -a
```

## Security Best Practices

1. **Keep system updated**:
   ```bash
   sudo yum update -y
   ```

2. **Use environment variables** for sensitive data (never commit to Git)

3. **Restrict SSH access** to your IP only in security group

4. **Enable HTTPS** with Let's Encrypt SSL certificate

5. **Regular backups**: Create AMI snapshots of your EC2 instance

6. **Monitor logs** for suspicious activity

7. **Use IAM roles** instead of access keys when possible

## Backup and Recovery

### Create EC2 Snapshot

1. Go to EC2 Dashboard → Instances
2. Select your instance
3. Actions → Image and templates → Create image
4. Name: `vehicle-explorer-backup-YYYY-MM-DD`
5. Click Create image

### Restore from Snapshot

1. Go to EC2 Dashboard → AMIs
2. Select your backup AMI
3. Actions → Launch instance from AMI
4. Configure and launch new instance

## Additional Resources

- [AWS Free Tier Details](https://aws.amazon.com/free/)
- [EC2 User Guide](https://docs.aws.amazon.com/ec2/)
- [Docker Documentation](https://docs.docker.com/)
- [Let's Encrypt](https://letsencrypt.org/)
- [AWS Cost Explorer](https://aws.amazon.com/aws-cost-management/aws-cost-explorer/)

## Support

For issues specific to this application, please open an issue on the GitHub repository.

For AWS-specific issues, consult [AWS Support](https://aws.amazon.com/support/).
