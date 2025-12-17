# Task Manager - Multi-Service Application with Kubernetes & CI/CD

A full-stack task management application demonstrating microservices architecture, containerization, Kubernetes deployment, and CI/CD automation.

## 🏗️ Architecture

This application consists of multiple services:

- **Backend API** (Node.js/Express + TypeScript) - REST API for task management
- **Message Consumer** (Python) - Kafka consumer for event processing
- **Frontend** (React + TypeScript) - Modern web interface
- **Database** (PostgreSQL) - Data persistence
- **Message Queue** (Apache Kafka) - Event streaming

## 📋 Features

- ✅ Full CRUD operations for tasks
- ✅ Event-driven architecture with Kafka
- ✅ Audit logging via message consumer
- ✅ Containerized services with Docker
- ✅ Kubernetes deployment manifests
- ✅ Automated CI/CD pipeline with GitHub Actions
- ✅ Comprehensive test coverage
- ✅ Health checks and monitoring

## 🚀 Quick Start

### Prerequisites

- Docker & Docker Compose
- Node.js 20+ (for local development)
- Python 3.11+ (for local development)
- kubectl (for Kubernetes deployment)
- Kubernetes cluster (Minikube, kind, or cloud provider)

### Running Locally with Docker Compose

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd CICD-Lab
   ```

2. **Start all services**
   ```bash
   docker-compose up -d
   ```

3. **Access the application**
   - Frontend: http://localhost:3001
   - Backend API: http://localhost:3000
   - API Health: http://localhost:3000/health

4. **View logs**
   ```bash
   # All services
   docker-compose logs -f
   
   # Specific service
   docker-compose logs -f backend
   ```

5. **Stop services**
   ```bash
   docker-compose down
   ```

## ☸️ Kubernetes Deployment

### Prerequisites

- Running Kubernetes cluster
- kubectl configured to connect to your cluster
- Helm 3.0+ (recommended)

### Deploy with Helm (Recommended)

**Easiest way:**
```bash
./scripts/deploy-helm.sh
```

**Manual Helm deployment:**
```bash
# Build images
docker build -t task-backend:latest ./backend
docker build -t task-consumer:latest ./consumer
docker build -t task-frontend:latest ./frontend

# Deploy with Helm
helm install task-manager ./helm/task-manager \
  --namespace task-app \
  --create-namespace
```

**Check deployment:**
```bash
helm status task-manager -n task-app
kubectl get pods -n task-app
```

**See [HELM.md](HELM.md) for complete Helm documentation.**

### Deploy with kubectl (Alternative)

1. **Build Docker images**
   ```bash
   # Backend
   docker build -t task-backend:latest ./backend
   
   # Consumer
   docker build -t task-consumer:latest ./consumer
   
   # Frontend
   docker build -t task-frontend:latest ./frontend
   ```

2. **Load images to cluster** (for local clusters like Minikube)
   ```bash
   # If using Minikube
   minikube image load task-backend:latest
   minikube image load task-consumer:latest
   minikube image load task-frontend:latest
   ```

3. **Deploy using Kustomize**
   ```bash
   kubectl apply -k k8s/
   ```

4. **Check deployment status**
   ```bash
   kubectl get pods -n task-app
   kubectl get services -n task-app
   ```

5. **Access the application**
   ```bash
   # Get the frontend service URL (LoadBalancer or NodePort)
   kubectl get service frontend -n task-app
   
   # For Minikube
   minikube service frontend -n task-app
   ```

### Verify Deployment

```bash
# Check all pods are running
kubectl get pods -n task-app

# Check logs
kubectl logs -f deployment/backend -n task-app
kubectl logs -f deployment/consumer -n task-app

# Check database
kubectl exec -it deployment/postgres -n task-app -- psql -U postgres -d taskdb
```

## 🧪 Testing

### Backend Tests

```bash
cd backend
npm install
npm test
npm run test:coverage
```

### Consumer Tests

```bash
cd consumer
pip install -r requirements.txt
pytest test_consumer.py -v
pytest test_consumer.py --cov=consumer
```

### Frontend Tests

```bash
cd frontend
npm install
npm test
```

### Integration Tests

```bash
# Start all services
docker-compose up -d

# Wait for services to be ready
sleep 30

# Test API
curl http://localhost:3000/health
curl -X POST http://localhost:3000/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"title":"Test Task","description":"Test"}'

# Cleanup
docker-compose down
```

## 🔄 CI/CD Pipeline

The project includes GitHub Actions workflows for automated testing and deployment.

### Workflows

1. **CI/CD Pipeline** (`.github/workflows/ci-cd.yml`)
   - Runs on push to `main` or `develop`
   - Tests all services
   - Builds and pushes Docker images
   - Deploys to Kubernetes (when configured)
   - Runs integration tests

2. **Pull Request Tests** (`.github/workflows/test-on-pr.yml`)
   - Runs on all pull requests
   - Quality checks
   - Runs all tests
   - Comments on PR with results

### Pipeline Stages

```
┌─────────────────┐
│  Code Push/PR   │
└────────┬────────┘
         │
    ┌────▼────┐
    │  Tests  │
    ├─────────┤
    │ Backend │
    │Consumer │
    │Frontend │
    └────┬────┘
         │
    ┌────▼────────┐
    │    Build    │
    │Docker Images│
    └────┬────────┘
         │
    ┌────▼────────┐
    │   Deploy    │
    │ Kubernetes  │
    └────┬────────┘
         │
    ┌────▼────────┐
    │Integration  │
    │   Tests     │
    └─────────────┘
```

### Setting up CI/CD

1. **GitHub Container Registry**
   - Images are pushed to GitHub Container Registry (ghcr.io)
   - Requires GITHUB_TOKEN (automatically provided)

2. **Kubernetes Deployment** (Optional)
   - Add your Kubernetes config as a GitHub Secret: `KUBE_CONFIG`
   - Uncomment deployment steps in `ci-cd.yml`

## 📁 Project Structure

```
CICD-Lab/
├── backend/                 # Node.js/Express API
│   ├── src/
│   │   ├── index.ts        # Main application
│   │   └── app.test.ts     # Tests
│   ├── Dockerfile
│   ├── package.json
│   └── tsconfig.json
├── consumer/                # Python Kafka consumer
│   ├── consumer.py         # Main consumer
│   ├── test_consumer.py    # Tests
│   ├── Dockerfile
│   └── requirements.txt
├── frontend/                # React frontend
│   ├── src/
│   │   ├── App.tsx         # Main component
│   │   ├── App.test.tsx    # Tests
│   │   └── main.tsx
│   ├── Dockerfile
│   ├── nginx.conf
│   └── package.json
├── k8s/                     # Kubernetes manifests (kubectl)
│   ├── namespace.yaml
│   ├── postgres-deployment.yaml
│   ├── kafka-deployment.yaml
│   ├── backend-deployment.yaml
│   ├── consumer-deployment.yaml
│   ├── frontend-deployment.yaml
│   └── kustomization.yaml
├── helm/                    # Helm charts
│   └── task-manager/        # Main Helm chart
│       ├── Chart.yaml
│       ├── values.yaml      # Default values
│       ├── values-dev.yaml  # Dev environment
│       ├── values-prod.yaml # Prod environment
│       └── templates/       # K8s templates
├── .github/
│   └── workflows/
│       ├── ci-cd.yml       # Main CI/CD pipeline
│       └── test-on-pr.yml  # PR testing
├── scripts/                # Helper scripts
│   ├── deploy-helm.sh      # Helm deployment
│   └── ...
├── docker-compose.yml      # Local development
├── README.md               # Main documentation
├── HELM.md                 # Helm guide
└── DIAGRAM.md              # Visual diagrams
```

## 🔧 Development

### Backend Development

```bash
cd backend
npm install
npm run dev  # Start with hot reload
```

### Consumer Development

```bash
cd consumer
pip install -r requirements.txt
python consumer.py
```

### Frontend Development

```bash
cd frontend
npm install
npm run dev  # Start dev server
```

### Environment Variables

#### Backend
- `PORT` - Server port (default: 3000)
- `DB_HOST` - PostgreSQL host
- `DB_PORT` - PostgreSQL port (default: 5432)
- `DB_NAME` - Database name
- `DB_USER` - Database user
- `DB_PASSWORD` - Database password
- `KAFKA_BROKER` - Kafka broker address

#### Consumer
- Same database and Kafka configuration as backend

#### Frontend
- `VITE_API_URL` - Backend API URL

## 📊 Monitoring

### Health Checks

- Backend: `GET /health`
- Returns: `{"status":"healthy","timestamp":"..."}`

### Kubernetes Probes

All deployments include:
- Liveness probes
- Readiness probes
- Resource limits

### Logs

```bash
# Docker Compose
docker-compose logs -f [service]

# Kubernetes
kubectl logs -f deployment/[service] -n task-app
```

## 🗃️ Database Schema

### Tasks Table

```sql
CREATE TABLE tasks (
  id SERIAL PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  status VARCHAR(50) DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Audit Log Table (Created by Consumer)

```sql
CREATE TABLE task_audit_log (
  id SERIAL PRIMARY KEY,
  event_type VARCHAR(50) NOT NULL,
  task_id INTEGER,
  event_data JSONB NOT NULL,
  processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## 🔐 Security Considerations

- Secrets stored in Kubernetes Secrets
- Environment variables for configuration
- No hardcoded credentials in code
- Regular dependency updates
- Container image scanning recommended

## 🚧 Troubleshooting

### Services won't start

```bash
# Check Docker logs
docker-compose logs

# Restart services
docker-compose restart

# Full cleanup and restart
docker-compose down -v
docker-compose up -d
```

### Kubernetes pods not starting

```bash
# Check pod status
kubectl describe pod [pod-name] -n task-app

# Check logs
kubectl logs [pod-name] -n task-app

# Check events
kubectl get events -n task-app --sort-by='.lastTimestamp'
```

### Database connection issues

```bash
# Verify PostgreSQL is running
docker-compose ps postgres
kubectl get pods -l app=postgres -n task-app

# Check database connectivity
docker-compose exec backend sh -c 'nc -zv postgres 5432'
```

### Kafka connection issues

```bash
# Check Kafka is running
docker-compose ps kafka
kubectl get pods -l app=kafka -n task-app

# Check Kafka topics
docker-compose exec kafka kafka-topics --bootstrap-server localhost:9092 --list
```

## 📚 API Documentation

### Endpoints

#### Tasks

- `GET /api/tasks` - Get all tasks
- `GET /api/tasks/:id` - Get a specific task
- `POST /api/tasks` - Create a new task
  ```json
  {
    "title": "Task title",
    "description": "Task description"
  }
  ```
- `PUT /api/tasks/:id` - Update a task
  ```json
  {
    "title": "Updated title",
    "description": "Updated description",
    "status": "completed"
  }
  ```
- `DELETE /api/tasks/:id` - Delete a task

#### Health

- `GET /health` - Health check endpoint

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📝 License

This project is for educational purposes.

## 🎯 Next Steps

- [ ] Add authentication/authorization
- [ ] Implement rate limiting
- [ ] Add API documentation (Swagger/OpenAPI)
- [ ] Set up monitoring (Prometheus/Grafana)
- [ ] Add distributed tracing
- [ ] Implement caching (Redis)
- [ ] Add more comprehensive integration tests
- [ ] Set up production-ready logging

