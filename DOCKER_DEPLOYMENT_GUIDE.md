# Docker Deployment Guide

## 🐳 Running with Docker Compose

Your application is currently building with Docker! This will take 5-10 minutes the first time.

### What's Happening:

Docker Compose is:
1. ✅ Building backend Docker image (.NET 8.0)
2. ✅ Building frontend Docker image (Node 18 + Angular)
3. ✅ Setting up networking between containers
4. ✅ Starting both services

### Once Complete:

**Backend API**: http://localhost:5000
- Swagger UI: http://localhost:5000/swagger
- Health Check: http://localhost:5000/health
- API Endpoints: http://localhost:5000/api/vehicles/makes

**Frontend App**: http://localhost:4200
- Angular application
- Connects to backend automatically

---

## 📋 Docker Commands

### Start Services
```powershell
docker-compose up --build
```

### Start in Background (Detached)
```powershell
docker-compose up -d --build
```

### Stop Services
```powershell
docker-compose down
```

### View Logs
```powershell
# All services
docker-compose logs -f

# Backend only
docker-compose logs -f backend

# Frontend only
docker-compose logs -f frontend
```

### Restart Services
```powershell
docker-compose restart
```

### Rebuild After Code Changes
```powershell
docker-compose down
docker-compose up --build
```

---

## 🔍 Check Status

### List Running Containers
```powershell
docker-compose ps
```

### Check Container Logs
```powershell
docker logs vehicle-explorer-backend-1
docker logs vehicle-explorer-frontend-1
```

---

## 🛠️ Troubleshooting

### Port Already in Use

If you get "port already in use" error:

```powershell
# Find process using port 5000
netstat -ano | findstr :5000

# Kill the process (replace PID)
taskkill /PID <PID> /F

# Or change port in docker-compose.yml
ports:
  - "5001:5000"  # Use 5001 instead
```

### Container Won't Start

```powershell
# Check logs
docker-compose logs backend
docker-compose logs frontend

# Remove old containers and rebuild
docker-compose down
docker system prune -f
docker-compose up --build
```

### Frontend Can't Connect to Backend

Check CORS settings in `backend/VehicleExplorer.API/appsettings.json`:
```json
{
  "AllowedOrigins": "http://localhost:4200"
}
```

---

## 📦 What's in docker-compose.yml

```yaml
services:
  backend:
    build: ./backend
    ports:
      - "5000:5000"
    environment:
      - ASPNETCORE_ENVIRONMENT=Development
      - AllowedOrigins=http://localhost:4200

  frontend:
    build: ./frontend
    ports:
      - "4200:4200"
    depends_on:
      - backend
```

---

## 🚀 Production Deployment

For production, use `docker-compose.prod.yml`:

```powershell
docker-compose -f docker-compose.prod.yml up -d --build
```

This uses:
- Optimized production builds
- Nginx for frontend
- Environment-specific settings

---

## ✅ Success Checklist

- [ ] Docker Desktop is running
- [ ] Ran `docker-compose up --build`
- [ ] Backend accessible at http://localhost:5000/swagger
- [ ] Frontend accessible at http://localhost:4200
- [ ] Can search for car makes in the UI
- [ ] API returns data successfully

---

## 🎉 You're Running on Docker!

Once the build completes:
1. Open http://localhost:4200 for the frontend
2. Open http://localhost:5000/swagger for the API
3. Test the application!

**Build time**: 5-10 minutes first time, ~1 minute after that.
