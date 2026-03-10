# Git Setup and Push to GitHub

## Step 1: Install Git for Windows

1. Download Git from: https://git-scm.com/download/win
2. Run the installer with default settings
3. Restart your terminal/PowerShell after installation

## Step 2: Configure Git (First Time Only)

Open PowerShell and run:

```powershell
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

## Step 3: Initialize Git Repository

Navigate to your project folder and run:

```powershell
cd D:\VEHICLE_PROJECT\vehicle-explorer

# Initialize git repository
git init

# Add all files
git add .

# Create first commit
git commit -m "Initial commit: Complete Vehicle Explorer with backend and frontend"
```

## Step 4: Connect to GitHub Repository

You mentioned your GitHub repo: https://github.com/OsamaShaikha/VehicleExplorer

```powershell
# Add remote repository
git remote add origin https://github.com/OsamaShaikha/VehicleExplorer.git

# Check current branch name
git branch

# If branch is 'master', rename to 'main' (GitHub default)
git branch -M main

# Push to GitHub
git push -u origin main
```

## Step 5: If Repository Already Exists on GitHub

If you get an error about existing content, you have two options:

### Option A: Force Push (Overwrites GitHub)
```powershell
git push -u origin main --force
```

### Option B: Pull First, Then Push
```powershell
git pull origin main --allow-unrelated-histories
git push -u origin main
```

## What Will Be Pushed

### Backend Files (35 files)
- VehicleExplorer.Domain (6 files)
- VehicleExplorer.Application (18 files)
- VehicleExplorer.Infrastructure (4 files)
- VehicleExplorer.API (7 files)

### Frontend Files
- Complete Angular 21 application
- All components, services, and configurations
- Material Design UI

### Configuration Files
- docker-compose.yml
- Dockerfiles for backend and frontend
- .gitignore files
- Documentation files

## Files That Won't Be Pushed (in .gitignore)

- node_modules/
- bin/
- obj/
- .vs/
- .angular/
- Build artifacts

## Verify After Push

1. Go to: https://github.com/OsamaShaikha/VehicleExplorer
2. You should see:
   - `/backend` folder with all 4 projects
   - `/frontend` folder with Angular app
   - `docker-compose.yml`
   - Documentation files

## Future Updates

After making changes:

```powershell
# Check what changed
git status

# Add changes
git add .

# Commit with message
git commit -m "Description of changes"

# Push to GitHub
git push
```

## Troubleshooting

### Authentication Issues
GitHub requires a Personal Access Token (PAT) instead of password:

1. Go to: https://github.com/settings/tokens
2. Generate new token (classic)
3. Select scopes: `repo` (full control)
4. Copy the token
5. Use token as password when pushing

### Alternative: Use GitHub Desktop
If command line is difficult:
1. Download: https://desktop.github.com/
2. Clone your repository
3. Copy your files into the cloned folder
4. Commit and push using the GUI

---

**Note**: Make sure Docker is stopped before pushing to avoid conflicts with file locks:
```powershell
docker-compose down
```
