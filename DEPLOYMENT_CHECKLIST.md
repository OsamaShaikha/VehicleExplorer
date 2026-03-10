# Deployment Checklist

Use this checklist to ensure a smooth deployment of Vehicle Explorer.

## Pre-Deployment

### Code Review
- [ ] All code changes reviewed and approved
- [ ] No console.log or debug statements in production code
- [ ] No hardcoded credentials or sensitive data
- [ ] All TODO comments addressed or documented
- [ ] Code follows project coding standards

### Configuration
- [ ] Environment variables configured for target environment
- [ ] CORS origins updated for production domain
- [ ] API URLs updated in frontend environment files
- [ ] NHTSA API base URL verified in appsettings.json
- [ ] Logging levels appropriate for production

### Testing
- [ ] Application runs successfully locally
- [ ] All API endpoints tested manually
- [ ] Frontend displays data correctly
- [ ] Error handling tested
- [ ] Loading states verified
- [ ] Responsive design tested on mobile devices
- [ ] Cross-browser testing completed (Chrome, Firefox, Safari, Edge)

### Docker
- [ ] Docker images build successfully
- [ ] docker-compose.yml tested locally
- [ ] docker-compose.prod.yml tested
- [ ] Container logs reviewed for errors
- [ ] Container resource limits configured appropriately

### Documentation
- [ ] README.md updated with latest information
- [ ] API documentation (Swagger) reviewed
- [ ] Deployment guide reviewed
- [ ] Environment variables documented
- [ ] Known issues documented

## AWS EC2 Deployment

### Infrastructure Setup
- [ ] AWS account created and configured
- [ ] EC2 instance launched (t2.micro for Free Tier)
- [ ] Security group configured:
  - [ ] Port 22 (SSH) - Your IP only
  - [ ] Port 80 (HTTP) - 0.0.0.0/0
  - [ ] Port 443 (HTTPS) - 0.0.0.0/0
- [ ] Key pair created and downloaded (.pem file)
- [ ] Elastic IP allocated (optional, for static IP)

### Server Configuration
- [ ] Connected to EC2 instance via SSH
- [ ] System packages updated (`sudo yum update -y`)
- [ ] Docker installed and running
- [ ] Docker Compose installed
- [ ] Git installed
- [ ] User added to docker group

### Application Deployment
- [ ] Repository cloned to EC2 instance
- [ ] Environment variables configured
- [ ] Docker containers built successfully
- [ ] Docker containers started
- [ ] Application accessible via public IP
- [ ] Health check endpoint returns 200 OK
- [ ] API endpoints responding correctly
- [ ] Frontend loads and displays data

### Domain & SSL (Optional)
- [ ] Domain name configured (Route 53 or external)
- [ ] DNS A record points to EC2 IP
- [ ] SSL certificate obtained (Let's Encrypt)
- [ ] Nginx configured for HTTPS
- [ ] HTTP to HTTPS redirect configured
- [ ] Certificate auto-renewal configured

## Post-Deployment

### Verification
- [ ] Application accessible from public internet
- [ ] All features working as expected
- [ ] API endpoints responding correctly
- [ ] Frontend displays data correctly
- [ ] Error handling working
- [ ] Loading states displaying
- [ ] Responsive design working on mobile
- [ ] Performance acceptable (page load times)

### Monitoring Setup
- [ ] Application logs accessible
- [ ] Error logging configured
- [ ] Health check endpoint monitored
- [ ] AWS CloudWatch alarms configured (optional)
- [ ] Uptime monitoring configured (optional)

### Security
- [ ] SSH access restricted to specific IPs
- [ ] Unnecessary ports closed in security group
- [ ] HTTPS enabled (if domain configured)
- [ ] Environment variables not exposed
- [ ] No sensitive data in logs
- [ ] Regular security updates scheduled

### Backup & Recovery
- [ ] EC2 instance snapshot created
- [ ] Backup schedule configured
- [ ] Recovery procedure documented
- [ ] Rollback plan prepared

### Documentation
- [ ] Deployment date recorded
- [ ] Server details documented (IP, instance ID, etc.)
- [ ] Access credentials stored securely
- [ ] Deployment notes added to CHANGELOG.md
- [ ] Team notified of deployment

## Rollback Plan

If issues occur after deployment:

1. **Immediate Actions**
   - [ ] Stop affected containers: `docker-compose down`
   - [ ] Check logs: `docker-compose logs`
   - [ ] Identify root cause

2. **Rollback Options**
   - [ ] Revert to previous Docker image
   - [ ] Restore from EC2 snapshot
   - [ ] Redeploy previous version from Git

3. **Communication**
   - [ ] Notify team of issues
   - [ ] Update status page (if applicable)
   - [ ] Document incident

## Maintenance Schedule

### Daily
- [ ] Check application health
- [ ] Review error logs
- [ ] Monitor resource usage

### Weekly
- [ ] Review application logs
- [ ] Check for security updates
- [ ] Verify backups

### Monthly
- [ ] Update system packages
- [ ] Review and rotate logs
- [ ] Test backup restoration
- [ ] Review AWS costs

## Environment-Specific Checklists

### Development
- [ ] Debug logging enabled
- [ ] CORS allows localhost
- [ ] Hot reload configured
- [ ] Source maps enabled

### Staging (if applicable)
- [ ] Production-like configuration
- [ ] Test data loaded
- [ ] Performance testing completed
- [ ] Load testing completed

### Production
- [ ] Production logging level (Info/Warning)
- [ ] CORS restricted to production domain
- [ ] Source maps disabled
- [ ] Minification enabled
- [ ] Caching configured
- [ ] Rate limiting enabled (if implemented)

## Troubleshooting

### Application Not Accessible
- [ ] Check EC2 instance is running
- [ ] Verify security group rules
- [ ] Check Docker containers are running
- [ ] Review application logs
- [ ] Verify DNS configuration (if using domain)

### API Errors
- [ ] Check backend container logs
- [ ] Verify NHTSA API is accessible
- [ ] Check environment variables
- [ ] Verify database connections (if applicable)

### Performance Issues
- [ ] Check EC2 instance resources (CPU, memory)
- [ ] Review application logs for slow queries
- [ ] Check Docker container stats
- [ ] Consider upgrading instance type

### SSL Certificate Issues
- [ ] Verify certificate is valid
- [ ] Check certificate expiration date
- [ ] Verify Nginx configuration
- [ ] Check Let's Encrypt renewal

## Sign-Off

### Deployment Team
- [ ] Developer: _________________ Date: _______
- [ ] Reviewer: _________________ Date: _______
- [ ] DevOps: ___________________ Date: _______

### Approval
- [ ] Technical Lead: ____________ Date: _______
- [ ] Product Owner: ____________ Date: _______

---

## Quick Commands Reference

```bash
# Check application status
docker-compose ps

# View logs
docker-compose logs -f

# Restart application
docker-compose restart

# Stop application
docker-compose down

# Start application
docker-compose up -d

# Update application
git pull
docker-compose down
docker-compose up -d --build

# Check EC2 resources
top
df -h
free -m

# Check Docker resources
docker stats
docker system df
```

---

**Note**: Customize this checklist based on your specific deployment requirements and organizational policies.
