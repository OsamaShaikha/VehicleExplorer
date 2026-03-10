# Push to GitHub - Run These Commands

## Step 1: Restart Your Terminal
Close and reopen PowerShell so Git is recognized in your PATH.

## Step 2: Navigate to Project
```powershell
cd D:\VEHICLE_PROJECT\vehicle-explorer
```

## Step 3: Verify Git is Working
```powershell
git --version
```
You should see something like: `git version 2.x.x`

## Step 4: Configure Git (First Time Only)
Replace with your actual name and email:
```powershell
git config --global user.name "Osama Shaikha"
git config --global user.email "your.email@example.com"
```

## Step 5: Initialize Git Repository
```powershell
git init
```

## Step 6: Add All Files
```powershell
git add .
```

## Step 7: Check What Will Be Committed
```powershell
git status
```
You should see all your backend and frontend files listed in green.

## Step 8: Create First Commit
```powershell
git commit -m "Complete Vehicle Explorer: Backend (.NET 8) + Frontend (Angular 21) + Docker"
```

## Step 9: Rename Branch to Main
```powershell
git branch -M main
```

## Step 10: Add GitHub Remote
```powershell
git remote add origin https://github.com/OsamaShaikha/VehicleExplorer.git
```

## Step 11: Push to GitHub

### If Repository is Empty or You Want to Overwrite:
```powershell
git push -u origin main --force
```

### If Repository Has Content You Want to Keep:
```powershell
git pull origin main --allow-unrelated-histories
git push -u origin main
```

## Authentication

When prompted for credentials:
- **Username**: OsamaShaikha
- **Password**: Use a Personal Access Token (NOT your GitHub password)

### Get Personal Access Token:
1. Go to: https://github.com/settings/tokens
2. Click "Generate new token (classic)"
3. Name: "Vehicle Explorer"
4. Select: ✓ repo (full control)
5. Click "Generate token"
6. Copy the token and use it as password

## Verify Success

After pushing, visit:
https://github.com/OsamaShaikha/VehicleExplorer

You should see:
- ✓ backend/ folder (4 projects, 35 files)
- ✓ frontend/ folder (Angular 21 app)
- ✓ docker-compose.yml
- ✓ All documentation files

## Future Updates

After making changes:
```powershell
git add .
git commit -m "Description of changes"
git push
```

---

## Quick Copy-Paste (After Restarting Terminal)

```powershell
cd D:\VEHICLE_PROJECT\vehicle-explorer
git config --global user.name "Osama Shaikha"
git config --global user.email "your.email@example.com"
git init
git add .
git commit -m "Complete Vehicle Explorer: Backend + Frontend + Docker"
git branch -M main
git remote add origin https://github.com/OsamaShaikha/VehicleExplorer.git
git push -u origin main --force
```

**Note**: The `--force` flag will overwrite any existing content in the repository.
