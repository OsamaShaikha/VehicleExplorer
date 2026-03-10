# AWS Upload Checklist - What Files to Deploy

## 🎯 Quick Answer

You need to upload your **compiled/built application files**, NOT your source code.

## 📦 What to Upload to AWS

### For Windows Server (IIS Deployment)

#### Backend Files (API)
```
✅ Upload these files from: backend/VehicleExplorer.API/bin/Release/net8.0/publish/

Required files:
├── VehicleExplorer.API.dll                    (Your compiled application)
├── VehicleExplorer.API.exe                    (Executable)
├── VehicleExplorer.Application.dll            (Application layer)
├── VehicleExplorer.Domain.dll                 (Domain layer)
├── VehicleExplorer.Infrastructure.dll         (Infrastructure layer)
├── appsettings.json                           (Configuration)
├── appsettings.Production.json                (Production config)
├── web.config                                 (IIS configuration)
└── All other .dll files in the folder         (Dependencies)

Total size: ~50-100 MB
```

#### Frontend Files (Angular App)
```
✅ Upload these files from: frontend/dist/vehicle-explorer/browser/

Required files:
├── index.html                                 (Main HTML file)
├── main-[hash].js                            (Compiled JavaScript)
├── polyfills-[hash].js                       (Browser compatibility)
├── styles-[hash].css                         (Compiled CSS)
├── assets/                                   (Images, fonts, etc.)
└── All other files in the folder

Total size: ~5-10 MB
```

---

## 🚫 What NOT to Upload

### Don't Upload These:
```
❌ Source code files (.cs, .ts files)
❌ node_modules/ folder (too large, 200+ MB)
❌ .git/ folder (version control)
❌ obj/ and bin/Debug/ folders
❌ .vs/ folder (Visual Studio files)
❌ package.json, package-lock.json
❌ .gitignore, .editorconfig
❌ README.md, documentation files
❌ Test projects
```

---

## 📋 Step-by-Step: What to Upload

### Option 1: Upload Entire Project (Easiest for Beginners)

If you're not sure, upload the entire project folder and build on the server:

```
✅ Upload: vehicle-explorer/ (entire folder)
Size: ~500 MB - 1 GB (includes node_modules)

Then build on the server:
- Backend: dotnet publish
- Frontend: npm install && npm run build
```

**Pros:**
- Simple, just upload everything
- Build on the server

**Cons:**
- Large upload size
- Takes longer
- Requires build tools on server

---

### Option 2: Upload Only Built Files (Recommended)

Build locally, upload only compiled files:

```
✅ Upload Backend: backend/VehicleExplorer.API/bin/Release/net8.0/publish/
✅ Upload Frontend: frontend/dist/vehicle-explorer/browser/

Size: ~60-110 MB total

No building needed on server!
```

**Pros:**
- Smaller upload size
- Faster deployment
- No build tools needed on server

**Cons:**
- Must build locally first
- Need to remember to rebuild after changes

---

## 🔨 How to Build Files Locally

### Build Backend (Windows)

```powershell
# Navigate to backend folder
cd vehicle-explorer/backend

# Build and publish
dotnet publish VehicleExplorer.API/VehicleExplorer.API.csproj -c Release -o ./publish

# Files will be in: backend/publish/
```

### Build Frontend (Windows)

```powershell
# Navigate to frontend folder
cd vehicle-explorer/frontend

# Install dependencies (first time only)
npm install

# Build for production
npm run build --configuration=production

# Files will be in: frontend/dist/vehicle-explorer/browser/
```

---

## 📤 How to Upload Files to AWS

### Method 1: Using Git (Recommended)

```powershell
# On your local machine
cd vehicle-explorer
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/YOUR-USERNAME/vehicle-explorer.git
git push -u origin main

# On AWS server (via RDP or Session Manager)
git clone https://github.com/YOUR-USERNAME/vehicle-explorer.git
cd vehicle-explorer
# Then build on server
```

**Pros:**
- Easy to update (just git pull)
- Version control
- Can exclude files with .gitignore

---

### Method 2: Using Remote Desktop (RDP)

```
1. Connect to AWS server via RDP
2. Open browser on server
3. Download your files:
   - From GitHub
   - From Google Drive
   - From Dropbox
   - From OneDrive
4. Extract and place in C:\inetpub\wwwroot\
```

**Pros:**
- Simple, visual
- No command line needed

**Cons:**
- Manual process
- Slower for large files

---

### Method 3: Using AWS S3 (For Large Files)

```powershell
# On your local machine
# Upload to S3
aws s3 cp vehicle-explorer/ s3://my-bucket/vehicle-explorer/ --recursive

# On AWS server
# Download from S3
aws s3 cp s3://my-bucket/vehicle-explorer/ C:\inetpub\wwwroot\vehicle-explorer\ --recursive
```

**Pros:**
- Fast for large files
- Can resume interrupted uploads

**Cons:**
- Requires AWS CLI setup
- Extra S3 storage costs

---

### Method 4: Using SCP/SFTP (For Linux)

```bash
# Upload files via SCP
scp -r vehicle-explorer/ ec2-user@YOUR-EC2-IP:/home/ec2-user/

# Or use FileZilla, WinSCP
```

---

## 📁 Recommended Folder Structure on AWS

### Windows Server (IIS)

```
C:\inetpub\wwwroot\
├── vehicle-api\                              (Backend)
│   ├── VehicleExplorer.API.dll
│   ├── appsettings.json
│   ├── appsettings.Production.json
│   └── ... (all other DLLs)
│
└── vehicle-app\                              (Frontend)
    ├── index.html
    ├── main-[hash].js
    ├── styles-[hash].css
    └── assets\
```

### Linux Server (Docker)

```
/home/ec2-user/
└── vehicle-explorer\
    ├── backend\
    │   └── (source code)
    ├── frontend\
    │   └── (source code)
    ├── docker-compose.yml
    └── Dockerfile
```

---

## 🎯 Quick Deployment Checklist

### Before Uploading:

- [ ] Backend builds successfully locally (`dotnet build`)
- [ ] Frontend builds successfully locally (`npm run build`)
- [ ] All tests pass (if you have tests)
- [ ] Configuration files updated (appsettings.json, environment.ts)
- [ ] Sensitive data removed (no passwords, API keys in code)

### Files to Upload:

**Option A - Upload Everything (Easiest):**
- [ ] Entire `vehicle-explorer/` folder

**Option B - Upload Built Files Only (Recommended):**
- [ ] Backend: `backend/publish/` folder contents
- [ ] Frontend: `frontend/dist/vehicle-explorer/browser/` folder contents
- [ ] Configuration: `appsettings.Production.json`

### After Uploading:

- [ ] Backend API accessible (http://YOUR-IP:5000/api/vehicles/makes)
- [ ] Frontend loads (http://YOUR-IP)
- [ ] Can search for car makes
- [ ] Can select year and view models
- [ ] No console errors in browser (F12)

---

## 💡 Pro Tips

### 1. Use .gitignore to Exclude Unnecessary Files

Create `.gitignore` file:
```
# Don't upload these
node_modules/
bin/
obj/
.vs/
*.user
*.suo
dist/
.angular/
```

### 2. Compress Before Uploading

```powershell
# Compress to ZIP
Compress-Archive -Path vehicle-explorer -DestinationPath vehicle-explorer.zip

# Upload single ZIP file (faster)
# Then extract on server
```

### 3. Use Environment Variables for Secrets

Don't hardcode in files:
```json
// ❌ Bad - Don't do this
{
  "ConnectionString": "Server=myserver;Password=mypassword123"
}

// ✅ Good - Use environment variables
{
  "ConnectionString": "${CONNECTION_STRING}"
}
```

### 4. Test Locally Before Uploading

```powershell
# Test backend
cd backend
dotnet run --project VehicleExplorer.API

# Test frontend
cd frontend
npm start

# Test together
docker-compose up
```

---

## 📊 File Size Reference

| What | Size | Upload Time (10 Mbps) |
|------|------|----------------------|
| Built backend only | ~50 MB | ~40 seconds |
| Built frontend only | ~10 MB | ~8 seconds |
| Source code (no node_modules) | ~50 MB | ~40 seconds |
| Full project (with node_modules) | ~500 MB | ~7 minutes |
| Compressed ZIP | ~100 MB | ~1.5 minutes |

---

## 🛠️ Troubleshooting

### "File too large to upload"

**Solution:**
1. Build locally
2. Upload only built files
3. Or use Git/S3 instead of RDP copy-paste

### "Upload keeps failing"

**Solution:**
1. Compress to ZIP first
2. Use Git instead
3. Upload to S3, then download on server
4. Check internet connection stability

### "Don't know which files to upload"

**Solution:**
Use Option 1 (upload everything), then build on server:
```powershell
# On server
cd vehicle-explorer/backend
dotnet publish -c Release -o C:\inetpub\wwwroot\vehicle-api

cd ../frontend
npm install
npm run build
Copy-Item dist/vehicle-explorer/browser/* C:\inetpub\wwwroot\vehicle-app -Recurse
```

---

## 📚 Related Guides

- **Windows Deployment**: `AWS_DEPLOYMENT_STEPS_WINDOWS.md`
- **Linux Deployment**: `AWS_DEPLOYMENT_STEPS.md`
- **Docker Guide**: `DOCKER_GUIDE.md`
- **Zero Standing Privileges**: `ZERO_STANDING_PRIVILEGES_GUIDE.md`

---

## 🎉 Summary

**Minimum files needed:**
1. ✅ Backend compiled DLLs (~50 MB)
2. ✅ Frontend built files (~10 MB)
3. ✅ Configuration files (appsettings.json)

**Total: ~60 MB**

**Easiest method:**
1. Push code to GitHub
2. Clone on AWS server
3. Build on server

**Fastest method:**
1. Build locally
2. Upload only built files
3. No building needed on server

Choose the method that works best for you! 🚀

---

**Need help? Check the deployment guides or ask for assistance!**
