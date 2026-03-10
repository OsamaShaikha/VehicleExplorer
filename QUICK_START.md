# Quick Start Guide

Get Vehicle Explorer up and running in 5 minutes!

## Prerequisites Check

```bash
# Check .NET version (need 8.0+)
dotnet --version

# Check Node version (need 18+)
node --version

# Check Docker (optional)
docker --version
docker-compose --version
```

## Option 1: Docker (Fastest) 🚀

```bash
# Clone and start
git clone <repo-url>
cd vehicle-explorer
docker-compose up --build

# Access the app
# Frontend: http://localhost:4200
# API: http://localhost:5000/swagger
```

That's it! The app is running.

## Option 2: Local Development

### Terminal 1 - Backend

```bash
cd vehicle-explorer/backend
dotnet restore
dotnet run --project VehicleExplorer.API
```

Backend will start at `http://localhost:5000`

### Terminal 2 - Frontend

```bash
cd vehicle-explorer/frontend
npm install
npm start
```

Frontend will start at `http://localhost:4200`

## Verify Installation

1. Open browser: `http://localhost:4200`
2. You should see the Vehicle Explorer interface
3. Try selecting a make (e.g., "Toyota")
4. Select a year (e.g., "2020")
5. View vehicle types and models

## Common Commands

### Backend

```bash
# Run tests
dotnet test

# Build
dotnet build

# Clean
dotnet clean

# Watch mode (auto-reload)
dotnet watch run --project VehicleExplorer.API
```

### Frontend

```bash
# Development server
npm start

# Run tests
npm test

# Build for production
npm run build

# Lint
npm run lint
```

### Docker

```bash
# Start services
docker-compose up

# Start in background
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f

# Rebuild
docker-compose up --build

# Production mode
docker-compose -f docker-compose.prod.yml up --build
```

## API Endpoints Quick Reference

```bash
# Get all makes
curl http://localhost:5000/api/vehicles/makes

# Get vehicle types for Toyota (makeId: 448)
curl http://localhost:5000/api/vehicles/makes/448/vehicle-types

# Get models for Toyota 2020
curl "http://localhost:5000/api/vehicles/makes/448/models?year=2020"

# Health check
curl http://localhost:5000/health
```

## Troubleshooting

### Port Already in Use

```bash
# Backend (port 5000)
# Windows
netstat -ano | findstr :5000
taskkill /PID <PID> /F

# Frontend (port 4200)
# Windows
netstat -ano | findstr :4200
taskkill /PID <PID> /F
```

### Docker Issues

```bash
# Clean everything
docker-compose down
docker system prune -a

# Rebuild from scratch
docker-compose up --build --force-recreate
```

### Backend Not Starting

```bash
# Check .NET SDK
dotnet --list-sdks

# Restore packages
cd backend
dotnet restore

# Check for errors
dotnet build
```

### Frontend Not Starting

```bash
# Clear node_modules
cd frontend
rm -rf node_modules package-lock.json
npm install

# Clear Angular cache
npm cache clean --force
```

### CORS Errors

Make sure backend `AllowedOrigins` in `appsettings.json` includes your frontend URL:

```json
{
  "AllowedOrigins": "http://localhost:4200"
}
```

### API Not Responding

1. Check backend is running: `http://localhost:5000/health`
2. Check Swagger UI: `http://localhost:5000/swagger`
3. Check logs in terminal
4. Verify NHTSA API is accessible: `curl https://vpic.nhtsa.dot.gov/api/vehicles/getallmakes?format=json`

## Development Workflow

1. **Start backend** in watch mode:
   ```bash
   cd backend
   dotnet watch run --project VehicleExplorer.API
   ```

2. **Start frontend** in dev mode:
   ```bash
   cd frontend
   npm start
   ```

3. **Make changes** - both will auto-reload

4. **Run tests** before committing:
   ```bash
   # Backend
   dotnet test
   
   # Frontend
   npm test
   ```

5. **Commit** using conventional commits:
   ```bash
   git add .
   git commit -m "feat: add new feature"
   git push
   ```

## Next Steps

- Read [README.md](README.md) for detailed documentation
- Check [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines
- Review [infrastructure/aws-setup.md](infrastructure/aws-setup.md) for deployment
- Explore the code structure in each layer

## Need Help?

- Check existing [GitHub Issues](https://github.com/your-repo/issues)
- Review [API Documentation](http://localhost:5000/swagger) when backend is running
- Read the [Clean Architecture guide](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)

## Useful Resources

- [.NET Documentation](https://docs.microsoft.com/en-us/dotnet/)
- [Angular Documentation](https://angular.io/docs)
- [MediatR Documentation](https://github.com/jbogard/MediatR)
- [FluentValidation Documentation](https://docs.fluentvalidation.net/)
- [NHTSA API Documentation](https://vpic.nhtsa.dot.gov/api/)

Happy coding! 🎉
