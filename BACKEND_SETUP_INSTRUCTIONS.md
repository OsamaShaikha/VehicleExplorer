# Backend Setup Instructions

## 🚀 Quick Start - Create Complete Backend

Your backend was accidentally deleted, but I've created scripts to recreate everything from scratch!

### Step 1: Run the Master Script

Open PowerShell in the `vehicle-explorer` folder and run:

```powershell
.\CREATE_COMPLETE_BACKEND.ps1
```

This single command will:
- ✅ Create all 4 backend projects (Domain, Application, Infrastructure, API)
- ✅ Create all source code files
- ✅ Set up project references
- ✅ Create Dockerfile
- ✅ Create solution file

**Time required**: ~30 seconds

---

### Step 2: Restore NuGet Packages

```powershell
cd backend
dotnet restore VehicleExplorer.API
```

---

### Step 3: Build the Project

```powershell
dotnet build VehicleExplorer.API
```

You should see: `Build succeeded. 0 Warning(s). 0 Error(s).`

---

### Step 4: Run the Backend

```powershell
dotnet run --project VehicleExplorer.API
```

The API will start on: `http://localhost:5000`

---

### Step 5: Test the API

Open your browser and go to:
- Swagger UI: http://localhost:5000/swagger
- Health Check: http://localhost:5000/health
- Get Makes: http://localhost:5000/api/vehicles/makes

---

## 📁 What Gets Created

```
backend/
├── VehicleExplorer.Domain/
│   ├── Entities/
│   │   ├── Make.cs
│   │   ├── VehicleType.cs
│   │   └── VehicleModel.cs
│   ├── Exceptions/
│   │   └── DomainException.cs
│   ├── Interfaces/
│   │   └── IVehicleRepository.cs
│   └── VehicleExplorer.Domain.csproj
│
├── VehicleExplorer.Application/
│   ├── Common/
│   │   ├── Behaviors/
│   │   │   ├── LoggingBehavior.cs
│   │   │   ├── ValidationBehavior.cs
│   │   │   └── CachingBehavior.cs
│   │   ├── Interfaces/
│   │   │   └── ICacheable.cs
│   │   └── Models/
│   │       └── ApiResponse.cs
│   ├── Features/
│   │   └── Vehicles/
│   │       └── Queries/
│   │           ├── GetAllMakes/
│   │           ├── GetVehicleTypes/
│   │           └── GetModels/
│   ├── DependencyInjection.cs
│   └── VehicleExplorer.Application.csproj
│
├── VehicleExplorer.Infrastructure/
│   ├── ExternalApis/
│   │   ├── NhtsaClient.cs
│   │   └── NhtsaResponseModels.cs
│   ├── DependencyInjection.cs
│   └── VehicleExplorer.Infrastructure.csproj
│
├── VehicleExplorer.API/
│   ├── Controllers/
│   │   └── VehiclesController.cs
│   ├── Middleware/
│   │   └── ExceptionHandlingMiddleware.cs
│   ├── Properties/
│   │   └── launchSettings.json
│   ├── Program.cs
│   ├── appsettings.json
│   ├── appsettings.Development.json
│   └── VehicleExplorer.API.csproj
│
├── Dockerfile
└── VehicleExplorer.slnx
```

---

## 🔧 Troubleshooting

### "Cannot find CREATE_COMPLETE_BACKEND.ps1"

Make sure you're in the `vehicle-explorer` folder:
```powershell
cd D:\VEHICLE_PROJECT\vehicle-explorer
dir *.ps1
```

You should see:
- CREATE_COMPLETE_BACKEND.ps1
- CREATE_BACKEND.ps1
- CREATE_INFRASTRUCTURE.ps1
- CREATE_API.ps1

---

### "Execution policy error"

Run this first:
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

Then run the script again.

---

### "dotnet command not found"

Install .NET 8.0 SDK from: https://dotnet.microsoft.com/download/dotnet/8.0

---

### Build errors

If you get build errors, try:
```powershell
cd backend
dotnet clean
dotnet restore VehicleExplorer.API
dotnet build VehicleExplorer.API
```

---

## 📤 Push to GitHub

After creating the backend:

```powershell
# Navigate to project root
cd D:\VEHICLE_PROJECT\vehicle-explorer

# Add all files
git add .

# Commit
git commit -m "Recreate complete backend project"

# Push to GitHub
git push origin main
```

(Or `git push origin master` if your branch is master)

---

## 🐳 Deploy to AWS

Once backend is created and pushed to GitHub:

1. SSH to your AWS server
2. Clone the repository
3. Run Docker:
   ```bash
   cd VehicleExplorer
   docker-compose -f docker-compose.prod.yml up -d --build
   ```

---

## ✅ Verification Checklist

After running the script, verify:

- [ ] All 4 project folders exist in `backend/`
- [ ] Can run `dotnet build backend/VehicleExplorer.API` successfully
- [ ] Can run `dotnet run --project backend/VehicleExplorer.API`
- [ ] Swagger UI loads at http://localhost:5000/swagger
- [ ] API returns data at http://localhost:5000/api/vehicles/makes

---

## 🎉 Success!

Your complete backend is now recreated from scratch!

**Next steps:**
1. Test locally
2. Push to GitHub
3. Deploy to AWS
4. Add frontend (if needed)

---

**Need help? Check the other guides:**
- `BACKEND_ARCHITECTURE.md` - Understand how it works
- `MEDIATR_GUIDE.md` - Learn about MediatR
- `AWS_DEPLOYMENT_STEPS.md` - Deploy to AWS
