# Backend Verification Script
# Checks if all backend files were created correctly

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Backend Verification" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$errors = 0
$warnings = 0

# Check if backend folder exists
if (Test-Path "backend") {
    Write-Host "✓ backend/ folder exists" -ForegroundColor Green
} else {
    Write-Host "✗ backend/ folder missing!" -ForegroundColor Red
    $errors++
}

# Check projects
$projects = @(
    "VehicleExplorer.Domain",
    "VehicleExplorer.Application",
    "VehicleExplorer.Infrastructure",
    "VehicleExplorer.API"
)

Write-Host "`nChecking projects..." -ForegroundColor Yellow
foreach ($project in $projects) {
    $path = "backend\$project\$project.csproj"
    if (Test-Path $path) {
        Write-Host "✓ $project" -ForegroundColor Green
    } else {
        Write-Host "✗ $project missing!" -ForegroundColor Red
        $errors++
    }
}

# Check key files
Write-Host "`nChecking key files..." -ForegroundColor Yellow

$keyFiles = @(
    @{Path="backend\VehicleExplorer.Domain\Entities\Make.cs"; Name="Make entity"},
    @{Path="backend\VehicleExplorer.Domain\Interfaces\IVehicleRepository.cs"; Name="IVehicleRepository"},
    @{Path="backend\VehicleExplorer.Application\Common\Models\ApiResponse.cs"; Name="ApiResponse"},
    @{Path="backend\VehicleExplorer.Application\Common\Behaviors\LoggingBehavior.cs"; Name="LoggingBehavior"},
    @{Path="backend\VehicleExplorer.Application\Features\Vehicles\Queries\GetAllMakes\GetAllMakesQuery.cs"; Name="GetAllMakesQuery"},
    @{Path="backend\VehicleExplorer.Infrastructure\ExternalApis\NhtsaClient.cs"; Name="NhtsaClient"},
    @{Path="backend\VehicleExplorer.API\Controllers\VehiclesController.cs"; Name="VehiclesController"},
    @{Path="backend\VehicleExplorer.API\Program.cs"; Name="Program.cs"},
    @{Path="backend\Dockerfile"; Name="Dockerfile"}
)

foreach ($file in $keyFiles) {
    if (Test-Path $file.Path) {
        Write-Host "✓ $($file.Name)" -ForegroundColor Green
    } else {
        Write-Host "✗ $($file.Name) missing!" -ForegroundColor Red
        $errors++
    }
}

# Try to build
Write-Host "`nAttempting to build..." -ForegroundColor Yellow
try {
    $buildOutput = dotnet build backend\VehicleExplorer.API --nologo --verbosity quiet 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Build successful!" -ForegroundColor Green
    } else {
        Write-Host "⚠ Build has warnings or errors" -ForegroundColor Yellow
        Write-Host $buildOutput
        $warnings++
    }
} catch {
    Write-Host "✗ Build failed!" -ForegroundColor Red
    Write-Host $_.Exception.Message
    $errors++
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Verification Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if ($errors -eq 0 -and $warnings -eq 0) {
    Write-Host "✅ All checks passed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Your backend is ready!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Run: " -NoNewline
    Write-Host "dotnet run --project backend\VehicleExplorer.API" -ForegroundColor Cyan
    Write-Host "2. Open: " -NoNewline
    Write-Host "http://localhost:5000/swagger" -ForegroundColor Cyan
    Write-Host "3. Test: " -NoNewline
    Write-Host "http://localhost:5000/api/vehicles/makes" -ForegroundColor Cyan
} elseif ($errors -eq 0) {
    Write-Host "⚠ Verification completed with $warnings warning(s)" -ForegroundColor Yellow
    Write-Host "Backend should work, but check the warnings above." -ForegroundColor Yellow
} else {
    Write-Host "✗ Verification failed with $errors error(s)" -ForegroundColor Red
    Write-Host "Please run CREATE_COMPLETE_BACKEND.ps1 again" -ForegroundColor Red
}

Write-Host ""
