# Quick Start Guide

Get up and running in 5 minutes!

## 🚀 Fastest Way to Start

### Using Docker Compose (Recommended for first time)

```bash
# 1. Start all services
./scripts/start-local.sh

# 2. Open your browser
open http://localhost:3001
```

That's it! The app is running with all services.

## 📋 Common Commands

### Docker Compose

```bash
# Start services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Rebuild and restart
docker-compose up -d --build
```

### Kubernetes with Helm (Recommended)

```bash
# Deploy with Helm
./scripts/deploy-helm.sh

# Check status
helm status task-manager -n task-app
kubectl get pods -n task-app

# View logs
kubectl logs -f deployment/task-manager-backend -n task-app

# Upgrade
helm upgrade task-manager ./helm/task-manager -n task-app

# Uninstall
helm uninstall task-manager -n task-app
```

### Kubernetes with kubectl (Alternative)

```bash
# Deploy everything
./scripts/deploy-k8s.sh

# Check status
kubectl get pods -n task-app

# View logs
kubectl logs -f deployment/backend -n task-app

# Delete everything
kubectl delete namespace task-app
```

### Testing

```bash
# Run all tests
./scripts/test-all.sh

# Test individual services
cd backend && npm test
cd consumer && pytest test_consumer.py -v
cd frontend && npm test
```

### Cleanup

```bash
# Remove everything
./scripts/cleanup.sh
```

## 🔧 Development Workflow

### Backend Development

```bash
cd backend
npm install
npm run dev      # Start with hot reload
npm test         # Run tests
npm run build    # Build for production
```

### Consumer Development

```bash
cd consumer
pip install -r requirements.txt
python consumer.py          # Run consumer
pytest test_consumer.py -v  # Run tests
```

### Frontend Development

```bash
cd frontend
npm install
npm run dev      # Start dev server (port 3001)
npm test         # Run tests
npm run build    # Build for production
```

## 🐛 Troubleshooting

### Services won't start

```bash
# Check what's running
docker-compose ps

# View error logs
docker-compose logs backend
docker-compose logs consumer

# Full reset
docker-compose down -v
docker-compose up -d
```

### Port conflicts

```bash
# Find what's using the port
lsof -ti:3000 | xargs kill -9  # Backend
lsof -ti:3001 | xargs kill -9  # Frontend
lsof -ti:5432 | xargs kill -9  # PostgreSQL
```

### Kubernetes pods not starting

```bash
# Check pod status
kubectl describe pod <pod-name> -n task-app

# Check events
kubectl get events -n task-app --sort-by='.lastTimestamp'

# Restart a deployment
kubectl rollout restart deployment/backend -n task-app
```

## 📊 Verify Everything is Working

### 1. Check Backend Health

```bash
curl http://localhost:3000/health
# Should return: {"status":"healthy","timestamp":"..."}
```

### 2. Create a Task via API

```bash
curl -X POST http://localhost:3000/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"title":"Test Task","description":"Testing the API"}'
```

### 3. Get All Tasks

```bash
curl http://localhost:3000/api/tasks
```

### 4. Check Frontend

Open http://localhost:3001 in your browser and:
- Create a task
- Mark it as complete
- Delete it

### 5. Verify Kafka Consumer

```bash
# Check consumer logs
docker-compose logs consumer

# You should see messages like:
# "Processed event: task.created for task ID: 1"
```

### 6. Check Audit Log in Database

```bash
# Connect to database
docker-compose exec postgres psql -U postgres -d taskdb

# Query audit log
SELECT * FROM task_audit_log;

# Exit
\q
```

## 🎯 What to Try Next

1. **Modify the Frontend**
   - Change colors in `frontend/src/App.css`
   - Add new features to `frontend/src/App.tsx`
   - Rebuild and see changes

2. **Add API Endpoints**
   - Edit `backend/src/index.ts`
   - Add new routes
   - Write tests

3. **Extend Consumer**
   - Add new event types in `consumer/consumer.py`
   - Process events differently
   - Add more audit fields

4. **Deploy to Cloud**
   - Get a Kubernetes cluster (GKE, EKS, AKS)
   - Configure kubectl
   - Run `./scripts/deploy-k8s.sh`

5. **Setup CI/CD**
   - Push to GitHub
   - GitHub Actions will automatically run
   - Tests → Build → Deploy

## 📚 Learn More

- [README.md](README.md) - Full documentation
- [SETUP.md](SETUP.md) - Detailed setup instructions
- [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture
- [HELM.md](HELM.md) - Helm deployment guide
- [DIAGRAM.md](DIAGRAM.md) - Visual diagrams

## 💡 Tips

1. **Always check logs first** when debugging
   ```bash
   docker-compose logs -f
   ```

2. **Use health checks** to verify services
   ```bash
   curl http://localhost:3000/health
   ```

3. **Clean start** if things get weird
   ```bash
   docker-compose down -v
   docker-compose up -d
   ```

4. **Watch the consumer** to see events being processed
   ```bash
   docker-compose logs -f consumer
   ```

5. **Check resource usage** if pods are pending
   ```bash
   kubectl top nodes
   kubectl top pods -n task-app
   ```

## 🎓 Learning Path

1. ✅ Get it running locally (Docker Compose)
2. ✅ Explore the UI and API
3. ✅ Look at the code structure
4. ✅ Run the tests
5. ✅ Make a small change
6. ✅ Deploy to Kubernetes
7. ✅ Set up GitHub Actions
8. ✅ Make a pull request

## 🆘 Get Help

1. Check the logs
2. Read the error messages
3. Review [README.md](README.md) troubleshooting section
4. Check [SETUP.md](SETUP.md) for prerequisites
5. Look at [ARCHITECTURE.md](ARCHITECTURE.md) to understand the system

## 🎉 Success Checklist

- [ ] All services running with Docker Compose
- [ ] Can access frontend at http://localhost:3001
- [ ] Can create, update, and delete tasks
- [ ] Backend health check responds
- [ ] Consumer is processing events
- [ ] All tests pass
- [ ] Successfully deployed to Kubernetes (optional)
- [ ] CI/CD pipeline runs (optional)

Congratulations! You have a full microservices application running! 🚀

