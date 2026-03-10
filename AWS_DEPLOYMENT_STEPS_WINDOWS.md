# AWS Deployment - Windows Server

## 🎯 Goal
Deploy Vehicle Explorer to AWS EC2 Windows Server using IIS

## ⏱️ Time Required
45-60 minutes

---

## ✅ Pre-Deployment Checklist

- [ ] AWS Account created
- [ ] Credit card added to AWS (required even for Free Tier)
- [ ] Project pushed to GitHub (or have the code ready)
- [ ] Basic understanding of IIS

---

## 📋 Step-by-Step Deployment

### Step 1: Create Windows EC2 Instance (5 minutes)

1. Go to [AWS Console](https://console.aws.amazon.com/)
2. Search for "EC2" and click on it
3. Click **"Launch Instance"** (orange button)
4. Fill in the details:

```
Name: vehicle-explorer-windows
Application and OS Images: 
  - Click "Windows"
  - Select "Microsoft Windows Server 2022 Base" (Free tier eligible)
Instance type: t2.micro (Free tier eligible - 1 vCPU, 1 GB RAM)
  Note: t2.small (2 GB RAM) recommended for better performance
Key pair: Click "Create new key pair"
  - Name: vehicle-explorer-key
  - Type: RSA
  - Format: .pem (for PuTTY) or .ppk
  - Click "Create key pair" (downloads key file)
```

5. Network settings - Click **"Edit"**:
   - Auto-assign public IP: Enable
   - Firewall (security groups): Create security group
   - Security group name: vehicle-explorer-windows-sg
   - Add rules:
     - ✅ HTTP (port 80) - Anywhere (0.0.0.0/0)
     - ✅ HTTPS (port 443) - Anywhere (0.0.0.0/0)
     - ✅ Custom TCP (port 5000) - Anywhere (0.0.0.0/0) - for backend API
     - ⚠️ RDP (port 3389) - My IP - **Only if using traditional RDP (not recommended)**
   
   **Note**: For production, use Session Manager (no RDP port needed). See Step 2B.

6. Storage: 30 GB (Windows needs more space than Linux)

7. Click **"Launch instance"** (orange button)

8. Wait 5-10 minutes for instance to initialize (Windows takes longer than Linux)

9. Click on your instance and note:
   - **Public IPv4 address**
   - **Instance ID**

---

### Step 2: Choose Connection Method

You have two options for connecting to your Windows Server:

#### Option A: Traditional RDP (Quick Start)
- Uses open port 3389
- Requires managing passwords
- ⚠️ Less secure, not recommended for production

#### Option B: AWS Systems Manager Session Manager (Recommended)
- No open ports required
- Zero standing privileges
- MFA enforced
- Full audit trail
- ✅ Production-ready security

**For production deployments, skip to Step 2B and use Session Manager.**

---

### Step 2A: Traditional RDP Connection (5 minutes)

⚠️ **Security Warning**: This method requires open port 3389 and is less secure. For production, use Session Manager (Step 2B).

1. In EC2 Dashboard, select your instance
2. Click **"Connect"** button at the top
3. Go to **"RDP client"** tab
4. Click **"Get password"**
5. Click **"Upload private key file"** and select your .pem file
6. Click **"Decrypt password"**
7. Copy the password (you'll need it to connect)

**Connect via RDP:**

1. Press `Win + R`, type `mstsc`, press Enter
2. Enter the Public IPv4 address
3. Click "Connect"
4. Username: `Administrator`
5. Password: (paste the decrypted password)
6. Click "Yes" to accept certificate warning

You should now see the Windows Server desktop!

**Continue to Step 4.**

---

### Step 2B: Session Manager Connection (Recommended - 10 minutes)

✅ **Secure Method**: No open ports, MFA required, full audit trail.

#### Prerequisites

1. **Attach IAM Role to Instance**:
   - EC2 Console → Instances → Select instance
   - Actions → Security → Modify IAM role
   - If no role exists, create one:
     - IAM Console → Roles → Create role
     - Trusted entity: EC2
     - Attach policy: `AmazonSSMManagedInstanceCore`
     - Name: `VehicleExplorer-SSM-Role`
   - Select the role and click **Update IAM role**

2. **Remove RDP Port from Security Group**:
   - EC2 Console → Security Groups → Select your security group
   - Edit inbound rules → Remove port 3389 rule
   - Save rules

3. **Wait 5 minutes** for SSM Agent to register

#### Connect via Session Manager

1. Go to **EC2 Console** → **Instances**
2. Select your instance
3. Click **"Connect"** button
4. Select **"Session Manager"** tab
5. Click **"Connect"**

A browser-based PowerShell terminal opens!

#### For GUI Access (RDP via Port Forwarding)

If you need GUI access without open ports:

```powershell
# On your local machine, install Session Manager plugin
# Download from: https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html

# Forward RDP port
aws ssm start-session --target YOUR-INSTANCE-ID --document-name AWS-StartPortForwardingSession --parameters "portNumber=3389,localPortNumber=9999"

# In another terminal, connect via RDP
mstsc /v:localhost:9999
```

**For complete Zero Standing Privileges setup, see: `ZERO_STANDING_PRIVILEGES_GUIDE.md`**

You should now have access to the Windows Server!

---

### Step 3: Verify Connection

Confirm you're connected to the server (via RDP or Session Manager).

---

### Step 4: Install Prerequisites (15 minutes)

Open PowerShell as Administrator (right-click Start → Windows PowerShell (Admin))

#### 4.1 Install IIS with ASP.NET Core Hosting

```powershell
# Install IIS
Install-WindowsFeature -name Web-Server -IncludeManagementTools

# Install .NET 8.0 Hosting Bundle
# Download URL
$url = "https://download.visualstudio.microsoft.com/download/pr/8f5a7f6e-e7e8-4c1e-b8e5-9e4b5e5e5e5e/dotnet-hosting-8.0-win.exe"

# Download
Invoke-WebRequest -Uri "https://dotnet.microsoft.com/download/dotnet/thank-you/runtime-aspnetcore-8.0.0-windows-hosting-bundle-installer" -OutFile "$env:TEMP\dotnet-hosting.exe"

# Note: You'll need to manually download from browser
# Go to: https://dotnet.microsoft.com/download/dotnet/8.0
# Download "Hosting Bundle" for Windows
```

**Manual Installation (Easier):**

1. Open Internet Explorer (or Edge) on the server
2. Go to: `https://dotnet.microsoft.com/download/dotnet/8.0`
3. Download **"Hosting Bundle"** (ASP.NET Core Runtime)
4. Run the installer
5. Restart IIS: `iisreset`

#### 4.2 Install Node.js (for building Angular)

```powershell
# Download Node.js installer
# Go to: https://nodejs.org/
# Download LTS version (Windows Installer .msi)
# Run the installer with default options
```

#### 4.3 Install Git

```powershell
# Download Git for Windows
# Go to: https://git-scm.com/download/win
# Download and install with default options
```

After installations, restart PowerShell to refresh PATH.

---

### Step 5: Clone and Build Application (10 minutes)

Open PowerShell as Administrator:

```powershell
# Navigate to IIS root
cd C:\inetpub\wwwroot

# Clone repository
git clone https://github.com/YOUR-USERNAME/vehicle-explorer.git
cd vehicle-explorer

# Build Backend
cd backend
dotnet restore
dotnet publish -c Release -o C:\inetpub\wwwroot\vehicle-api

# Build Frontend
cd ..\frontend
npm install
npm run build --configuration=production

# Copy frontend build to IIS
Copy-Item -Path "dist\vehicle-explorer\browser\*" -Destination "C:\inetpub\wwwroot\vehicle-app" -Recurse -Force
```

---

### Step 6: Configure IIS for Backend API (10 minutes)

#### 6.1 Create Application Pool

1. Open **IIS Manager** (Start → type "IIS")
2. Click on **Application Pools** in left panel
3. Click **"Add Application Pool"** in right panel
4. Settings:
   - Name: `VehicleExplorerAPI`
   - .NET CLR version: `No Managed Code`
   - Managed pipeline mode: `Integrated`
   - Click OK

#### 6.2 Create Backend Website

1. In IIS Manager, right-click **"Sites"** → **"Add Website"**
2. Settings:
   - Site name: `VehicleExplorerAPI`
   - Application pool: `VehicleExplorerAPI`
   - Physical path: `C:\inetpub\wwwroot\vehicle-api`
   - Binding:
     - Type: `http`
     - IP address: `All Unassigned`
     - Port: `5000`
     - Host name: (leave empty)
   - Click OK

#### 6.3 Configure Backend Settings

Create `appsettings.Production.json` in `C:\inetpub\wwwroot\vehicle-api\`:

```powershell
# Create production config
$config = @"
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "Nhtsa": {
    "BaseUrl": "https://vpic.nhtsa.dot.gov/api/"
  },
  "AllowedOrigins": "http://YOUR-EC2-PUBLIC-IP"
}
"@

$config | Out-File -FilePath "C:\inetpub\wwwroot\vehicle-api\appsettings.Production.json" -Encoding UTF8
```

Replace `YOUR-EC2-PUBLIC-IP` with your actual EC2 public IP.

---

### Step 7: Configure IIS for Frontend (5 minutes)

#### 7.1 Create Frontend Website

1. In IIS Manager, right-click **"Sites"** → **"Add Website"**
2. Settings:
   - Site name: `VehicleExplorerApp`
   - Application pool: `DefaultAppPool`
   - Physical path: `C:\inetpub\wwwroot\vehicle-app`
   - Binding:
     - Type: `http`
     - IP address: `All Unassigned`
     - Port: `80`
     - Host name: (leave empty)
   - Click OK

#### 7.2 Configure URL Rewrite for Angular

Angular needs URL rewrite for routing. Create `web.config` in `C:\inetpub\wwwroot\vehicle-app\`:

```powershell
$webConfig = @"
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <system.webServer>
    <rewrite>
      <rules>
        <rule name="Angular Routes" stopProcessing="true">
          <match url=".*" />
          <conditions logicalGrouping="MatchAll">
            <add input="{REQUEST_FILENAME}" matchType="IsFile" negate="true" />
            <add input="{REQUEST_FILENAME}" matchType="IsDirectory" negate="true" />
          </conditions>
          <action type="Rewrite" url="/" />
        </rule>
      </rules>
    </rewrite>
    <staticContent>
      <mimeMap fileExtension=".json" mimeType="application/json" />
    </staticContent>
  </system.webServer>
</configuration>
"@

$webConfig | Out-File -FilePath "C:\inetpub\wwwroot\vehicle-app\web.config" -Encoding UTF8
```

#### 7.3 Install URL Rewrite Module

If URL Rewrite is not installed:

1. Download from: `https://www.iis.net/downloads/microsoft/url-rewrite`
2. Install the module
3. Restart IIS: `iisreset`

---

### Step 8: Update Frontend API URL (3 minutes)

Update the Angular environment file to point to your backend:

```powershell
# Navigate to frontend source
cd C:\inetpub\wwwroot\vehicle-explorer\frontend\src\environments

# Update environment.prod.ts
$envProd = @"
export const environment = {
  production: true,
  apiUrl: 'http://YOUR-EC2-PUBLIC-IP:5000/api'
};
"@

$envProd | Out-File -FilePath "environment.prod.ts" -Encoding UTF8

# Rebuild frontend
cd C:\inetpub\wwwroot\vehicle-explorer\frontend
npm run build --configuration=production

# Copy updated build
Copy-Item -Path "dist\vehicle-explorer\browser\*" -Destination "C:\inetpub\wwwroot\vehicle-app" -Recurse -Force
```

---

### Step 9: Configure Windows Firewall (2 minutes)

```powershell
# Allow HTTP traffic
New-NetFirewallRule -DisplayName "Allow HTTP" -Direction Inbound -LocalPort 80 -Protocol TCP -Action Allow

# Allow Backend API
New-NetFirewallRule -DisplayName "Allow Backend API" -Direction Inbound -LocalPort 5000 -Protocol TCP -Action Allow

# Allow HTTPS (for future)
New-NetFirewallRule -DisplayName "Allow HTTPS" -Direction Inbound -LocalPort 443 -Protocol TCP -Action Allow
```

---

### Step 10: Start Services and Test (2 minutes)

```powershell
# Restart IIS
iisreset

# Check if sites are running
# Open IIS Manager → Sites → both should show "Started"
```

**Test the application:**

1. Open browser on the server: `http://localhost`
2. Test API: `http://localhost:5000/api/vehicles/makes`
3. From your computer: `http://YOUR-EC2-PUBLIC-IP`

---

## 🎉 Success! Your App is Live!

Your application is now running on AWS Windows Server at: `http://YOUR-EC2-PUBLIC-IP`

---

## 🔧 Useful Commands

### Restart IIS
```powershell
iisreset
```

### View Application Logs
```powershell
# Backend logs
Get-Content "C:\inetpub\wwwroot\vehicle-api\logs\*.log" -Tail 50

# IIS logs
Get-Content "C:\inetpub\logs\LogFiles\W3SVC*\*.log" -Tail 50
```

### Check if .NET is installed
```powershell
dotnet --list-runtimes
```

### Check Application Pool Status
```powershell
Get-IISAppPool | Select-Object Name, State
```

### Restart Application Pool
```powershell
Restart-WebAppPool -Name "VehicleExplorerAPI"
```

### Update Application (after code changes)
```powershell
cd C:\inetpub\wwwroot\vehicle-explorer
git pull origin main

# Rebuild backend
cd backend
dotnet publish -c Release -o C:\inetpub\wwwroot\vehicle-api

# Rebuild frontend
cd ..\frontend
npm run build --configuration=production
Copy-Item -Path "dist\vehicle-explorer\browser\*" -Destination "C:\inetpub\wwwroot\vehicle-app" -Recurse -Force

# Restart IIS
iisreset
```

---

## 🛑 Troubleshooting

### Can't access the application?

1. **Check Security Group**:
   - Go to EC2 → Security Groups
   - Find `vehicle-explorer-windows-sg`
   - Verify ports 80 and 5000 are open to 0.0.0.0/0

2. **Check Windows Firewall**:
   ```powershell
   Get-NetFirewallRule | Where-Object {$_.DisplayName -like "*HTTP*"}
   ```

3. **Check IIS Sites are Running**:
   - Open IIS Manager
   - Both sites should show "Started"
   - If not, right-click → Start

4. **Check Application Pool**:
   ```powershell
   Get-IISAppPool -Name "VehicleExplorerAPI"
   ```
   - If stopped, start it in IIS Manager

### Backend returns 500 error?

1. **Check .NET Runtime is installed**:
   ```powershell
   dotnet --list-runtimes
   ```
   Should show: `Microsoft.AspNetCore.App 8.0.x`

2. **Check Application Pool settings**:
   - .NET CLR version must be "No Managed Code"
   - Managed pipeline mode: Integrated

3. **Check logs**:
   ```powershell
   Get-Content "C:\inetpub\wwwroot\vehicle-api\logs\*.log" -Tail 50
   ```

### CORS errors?

Update `appsettings.Production.json`:
```json
{
  "AllowedOrigins": "http://YOUR-EC2-PUBLIC-IP,http://localhost"
}
```

Then restart:
```powershell
iisreset
```

### Frontend shows blank page?

1. **Check browser console** (F12) for errors
2. **Verify API URL** in environment.prod.ts
3. **Check web.config** exists in frontend folder
4. **Rebuild frontend**:
   ```powershell
   cd C:\inetpub\wwwroot\vehicle-explorer\frontend
   npm run build --configuration=production
   Copy-Item -Path "dist\vehicle-explorer\browser\*" -Destination "C:\inetpub\wwwroot\vehicle-app" -Recurse -Force
   ```

---

## 💰 Cost Management

### Free Tier Limits (12 months)
- ✅ 750 hours/month of t2.micro Windows (enough for 1 instance running 24/7)
- ✅ 30 GB of EBS storage
- ✅ 15 GB data transfer out per month

**Note**: Windows instances use more resources than Linux. Consider t2.small for better performance (not free tier).

### To Avoid Charges
1. **Stop instance when not using**:
   - EC2 Dashboard → Instances → Select instance → Instance State → Stop
   - Stopped instances don't count toward 750 hours

2. **Set up billing alerts**:
   - AWS Console → Billing → Billing Preferences
   - Enable "Receive Billing Alerts"
   - Set alerts at $1, $5, $10

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

### 1. Get Elastic IP (keeps IP permanent)
```
EC2 → Elastic IPs → Allocate Elastic IP
Actions → Associate → Select your instance
```

### 2. Update DNS
- Go to your domain registrar
- Add A record: `@` → `YOUR-ELASTIC-IP`
- Add A record: `www` → `YOUR-ELASTIC-IP`

### 3. Update CORS in Backend
```json
{
  "AllowedOrigins": "http://vehicleexplorer.com,http://www.vehicleexplorer.com"
}
```

### 4. Update Frontend API URL
```typescript
export const environment = {
  production: true,
  apiUrl: 'http://vehicleexplorer.com:5000/api'
};
```

### 5. Add SSL Certificate (HTTPS)

1. **Get SSL Certificate** (free from Let's Encrypt or AWS Certificate Manager)
2. **Install in IIS**:
   - IIS Manager → Server Certificates → Import
3. **Update Site Bindings**:
   - Select site → Bindings → Add
   - Type: https, Port: 443, SSL certificate: (select your cert)

---

## 📊 Performance Optimization

### Enable Output Caching in IIS

```powershell
# For static files (frontend)
Set-WebConfigurationProperty -PSPath "IIS:\Sites\VehicleExplorerApp" -Filter "system.webServer/staticContent" -Name "clientCache.cacheControlMode" -Value "UseMaxAge"
Set-WebConfigurationProperty -PSPath "IIS:\Sites\VehicleExplorerApp" -Filter "system.webServer/staticContent" -Name "clientCache.cacheControlMaxAge" -Value "7.00:00:00"
```

### Enable Compression

```powershell
# Enable dynamic compression
Set-WebConfigurationProperty -PSPath "MACHINE/WEBROOT/APPHOST" -Filter "system.webServer/httpCompression" -Name "doDynamicCompression" -Value "True"

# Enable static compression
Set-WebConfigurationProperty -PSPath "MACHINE/WEBROOT/APPHOST" -Filter "system.webServer/httpCompression" -Name "doStaticCompression" -Value "True"
```

---

## 🔒 Security Best Practices

### 1. Use Session Manager Instead of RDP
- Eliminates need for open port 3389
- Requires MFA for access
- Provides complete audit trail
- See: `ZERO_STANDING_PRIVILEGES_GUIDE.md`

### 2. Restrict RDP Access (if using traditional method)
- Update security group to allow RDP only from your IP
- Change default Administrator password
- Consider disabling RDP entirely and using Session Manager

### 3. Keep Windows Updated
```powershell
# Check for updates
Install-Module PSWindowsUpdate
Get-WindowsUpdate
Install-WindowsUpdate -AcceptAll -AutoReboot
```

### 4. Enable HTTPS
- Get SSL certificate
- Redirect HTTP to HTTPS
- Update security group to allow only HTTPS (443)

### 5. Implement Zero Standing Privileges
- Remove all standing access
- Require just-in-time access requests
- Enforce MFA for all operators
- See complete guide: `ZERO_STANDING_PRIVILEGES_GUIDE.md`

### 6. Regular Backups
- Create AMI snapshots weekly
- EC2 → Instances → Actions → Image and templates → Create image

---

## 📚 Next Steps

- [ ] Implement Zero Standing Privileges (see `ZERO_STANDING_PRIVILEGES_GUIDE.md`)
- [ ] Set up billing alerts
- [ ] Create AMI backup of your instance
- [ ] Add SSL certificate for HTTPS
- [ ] Set up CloudWatch monitoring
- [ ] Configure automatic Windows updates
- [ ] Set up automated backups
- [ ] Enable MFA for all operators
- [ ] Close RDP port 3389 (use Session Manager instead)

---

## 📖 Related Documentation

- **Zero Standing Privileges Guide**: `ZERO_STANDING_PRIVILEGES_GUIDE.md` - Implement secure, audited access
- **Backend Architecture**: `BACKEND_ARCHITECTURE.md` - Understand the application structure
- **MediatR Guide**: `MEDIATR_GUIDE.md` - Learn about CQRS implementation
- **Linux Deployment**: `AWS_DEPLOYMENT_STEPS.md` - Alternative Linux deployment

---

## 🆘 Need Help?

- IIS Documentation: https://docs.microsoft.com/iis/
- ASP.NET Core on IIS: https://docs.microsoft.com/aspnet/core/host-and-deploy/iis/
- AWS Windows Guide: https://docs.aws.amazon.com/AWSEC2/latest/WindowsGuide/
- AWS Support: https://console.aws.amazon.com/support/

---

**Congratulations! You've deployed your application to AWS Windows Server! 🚀**
