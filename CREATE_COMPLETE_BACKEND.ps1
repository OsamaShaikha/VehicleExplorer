# Complete Backend Creation - Master Script
# This script creates the entire backend project from scratch

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Vehicle Explorer Backend Generator" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Run backend creation
Write-Host "[1/3] Creating Application layer..." -ForegroundColor Yellow
& .\CREATE_BACKEND.ps1

# Step 2: Run infrastructure creation
Write-Host "`n[2/3] Creating Infrastructure layer..." -ForegroundColor Yellow
& .\CREATE_INFRASTRUCTURE.ps1

# Step 3: Run API creation
Write-Host "`n[3/3] Creating API layer..." -ForegroundColor Yellow
& .\CREATE_API.ps1

# Create solution file
Write-Host "`nCreating solution file..." -ForegroundColor Yellow
@"
{
  "solution": {
    "path": "VehicleExplorer.sln",
    "projects": [
      "backend\\VehicleExplorer.Domain\\VehicleExplorer.Domain.csproj",
      "backend\\VehicleExplorer.Application\\VehicleExplorer.Application.csproj",
      "backend\\VehicleExplorer.Infrastructure\\VehicleExplorer.Infrastructure.csproj",
      "backend\\VehicleExplorer.API\\VehicleExplorer.API.csproj"
    ]
  }
}
"@ | Out-File -FilePath "backend/VehicleExplorer.slnx" -Encoding UTF8

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  ✅ Backend Created Successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Project Structure:" -ForegroundColor Cyan
Write-Host "backend/" -ForegroundColor White
Write-Host "├── VehicleExplorer.Domain/          (Entities, Interfaces)" -ForegroundColor Gray
Write-Host "├── VehicleExplorer.Application/     (CQRS, MediatR, Behaviors)" -ForegroundColor Gray
Write-Host "├── VehicleExplorer.Infrastructure/  (NHTSA Client)" -ForegroundColor Gray
Write-Host "├── VehicleExplorer.API/             (Controllers, Middleware)" -ForegroundColor Gray
Write-Host "└── Dockerfile                       (Docker configuration)" -ForegroundColor Gray
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Open the project in Visual Studio or VS Code" -ForegroundColor White
Write-Host "2. Restore packages: " -NoNewline -ForegroundColor White
Write-Host "dotnet restore backend/VehicleExplorer.API" -ForegroundColor Cyan
Write-Host "3. Build the project: " -NoNewline -ForegroundColor White
Write-Host "dotnet build backend/VehicleExplorer.API" -ForegroundColor Cyan
Write-Host "4. Run the project: " -NoNewline -ForegroundColor White
Write-Host "dotnet run --project backend/VehicleExplorer.API" -ForegroundColor Cyan
Write-Host "5. Open Swagger: " -NoNewline -ForegroundColor White
Write-Host "http://localhost:5000/swagger" -ForegroundColor Cyan
Write-Host ""
Write-Host "Or use Docker:" -ForegroundColor Yellow
Write-Host "docker build -t vehicle-explorer-backend ./backend" -ForegroundColor Cyan
Write-Host "docker run -p 5000:5000 vehicle-explorer-backend" -ForegroundColor Cyan
Write-Host ""
