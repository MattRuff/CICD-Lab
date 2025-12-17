# Setup Guide

## Prerequisites Installation

### macOS

```bash
# Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Docker Desktop
brew install --cask docker

# Install Node.js
brew install node@20

# Install Python
brew install python@3.11

# Install kubectl
brew install kubectl

# Install Minikube (for local Kubernetes)
brew install minikube
```

### Linux (Ubuntu/Debian)

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo apt install docker-compose

# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Install Python
sudo apt install python3.11 python3-pip

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```

### Windows

```powershell
# Install Chocolatey (if not installed)
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Install Docker Desktop
choco install docker-desktop

# Install Node.js
choco install nodejs --version=20.0.0

# Install Python
choco install python --version=3.11.0

# Install kubectl
choco install kubernetes-cli

# Install Minikube
choco install minikube
```

## Local Development Setup

### 1. Clone the Repository

```bash
git clone <your-repo-url>
cd CICD-Lab
```

### 2. Install Dependencies

#### Backend
```bash
cd backend
npm install
cd ..
```

#### Frontend
```bash
cd frontend
npm install
cd ..
```

#### Consumer
```bash
cd consumer
pip install -r requirements.txt
cd ..
```

### 3. Start with Docker Compose

```bash
# Start all services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f
```

### 4. Verify Services

```bash
# Check backend health
curl http://localhost:3000/health

# Access frontend
open http://localhost:3001  # macOS
# or navigate to http://localhost:3001 in your browser
```

## Kubernetes Setup

### Option 1: Minikube (Local)

1. **Start Minikube**
   ```bash
   minikube start --cpus=4 --memory=8192
   ```

2. **Use Minikube's Docker daemon**
   ```bash
   eval $(minikube docker-env)
   ```

3. **Build images**
   ```bash
   docker build -t task-backend:latest ./backend
   docker build -t task-consumer:latest ./consumer
   docker build -t task-frontend:latest ./frontend
   ```

4. **Deploy**
   ```bash
   kubectl apply -k k8s/
   ```

5. **Access the application**
   ```bash
   minikube service frontend -n task-app
   ```

### Option 2: Kind (Kubernetes in Docker)

1. **Install Kind**
   ```bash
   # macOS
   brew install kind
   
   # Linux
   curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
   chmod +x ./kind
   sudo mv ./kind /usr/local/bin/kind
   ```

2. **Create cluster**
   ```bash
   kind create cluster --name task-app
   ```

3. **Load images**
   ```bash
   docker build -t task-backend:latest ./backend
   docker build -t task-consumer:latest ./consumer
   docker build -t task-frontend:latest ./frontend
   
   kind load docker-image task-backend:latest --name task-app
   kind load docker-image task-consumer:latest --name task-app
   kind load docker-image task-frontend:latest --name task-app
   ```

4. **Deploy**
   ```bash
   kubectl apply -k k8s/
   ```

5. **Port forward to access**
   ```bash
   kubectl port-forward service/frontend 8080:80 -n task-app
   # Access at http://localhost:8080
   ```

### Option 3: Cloud Provider (GKE, EKS, AKS)

#### Google Kubernetes Engine (GKE)

```bash
# Install gcloud CLI
# https://cloud.google.com/sdk/docs/install

# Authenticate
gcloud auth login

# Create cluster
gcloud container clusters create task-app-cluster \
  --zone us-central1-a \
  --num-nodes 3

# Get credentials
gcloud container clusters get-credentials task-app-cluster --zone us-central1-a

# Deploy
kubectl apply -k k8s/
```

#### Amazon EKS

```bash
# Install eksctl
# https://eksctl.io/installation/

# Create cluster
eksctl create cluster \
  --name task-app-cluster \
  --region us-east-1 \
  --nodegroup-name standard-workers \
  --node-type t3.medium \
  --nodes 3

# Deploy
kubectl apply -k k8s/
```

#### Azure AKS

```bash
# Install Azure CLI
# https://docs.microsoft.com/en-us/cli/azure/install-azure-cli

# Login
az login

# Create resource group
az group create --name task-app-rg --location eastus

# Create cluster
az aks create \
  --resource-group task-app-rg \
  --name task-app-cluster \
  --node-count 3 \
  --enable-addons monitoring \
  --generate-ssh-keys

# Get credentials
az aks get-credentials --resource-group task-app-rg --name task-app-cluster

# Deploy
kubectl apply -k k8s/
```

## GitHub Actions Setup

### 1. Enable GitHub Actions

1. Go to your repository on GitHub
2. Navigate to **Settings** > **Actions** > **General**
3. Enable "Allow all actions and reusable workflows"

### 2. Configure Container Registry

GitHub Container Registry (ghcr.io) is automatically configured with `GITHUB_TOKEN`.

To use a different registry:

1. Go to **Settings** > **Secrets and variables** > **Actions**
2. Add secrets:
   - `DOCKER_USERNAME`
   - `DOCKER_PASSWORD`
3. Update `.github/workflows/ci-cd.yml` to use your registry

### 3. Configure Kubernetes Deployment (Optional)

1. Get your kubeconfig:
   ```bash
   cat ~/.kube/config
   ```

2. Add as GitHub Secret:
   - Go to **Settings** > **Secrets and variables** > **Actions**
   - Add new secret: `KUBE_CONFIG`
   - Paste your kubeconfig content

3. Uncomment deployment steps in `.github/workflows/ci-cd.yml`

### 4. Trigger Pipeline

```bash
# Make a change and push to main
git add .
git commit -m "Initial setup"
git push origin main
```

The pipeline will automatically:
- Run all tests
- Build Docker images
- Push to container registry
- Deploy to Kubernetes (if configured)
- Run integration tests

## Verification Checklist

- [ ] Docker Desktop is running
- [ ] All containers start with `docker-compose up`
- [ ] Backend is accessible at http://localhost:3000/health
- [ ] Frontend is accessible at http://localhost:3001
- [ ] Can create and view tasks in the UI
- [ ] Minikube/Kubernetes cluster is running
- [ ] Kubernetes deployments are healthy
- [ ] GitHub Actions pipeline runs successfully

## Common Issues

### Docker Compose Issues

**Issue**: Ports already in use
```bash
# Find and kill processes using the ports
lsof -ti:3000 | xargs kill -9  # Backend
lsof -ti:3001 | xargs kill -9  # Frontend
lsof -ti:5432 | xargs kill -9  # PostgreSQL
```

**Issue**: Services can't connect to each other
```bash
# Recreate network
docker-compose down
docker network prune
docker-compose up -d
```

### Kubernetes Issues

**Issue**: Images not found
```bash
# For Minikube, make sure to use Minikube's Docker
eval $(minikube docker-env)

# Rebuild images
docker build -t task-backend:latest ./backend
docker build -t task-consumer:latest ./consumer
docker build -t task-frontend:latest ./frontend
```

**Issue**: Pods pending
```bash
# Check events
kubectl get events -n task-app --sort-by='.lastTimestamp'

# Check node resources
kubectl top nodes
```

### Node.js Issues

**Issue**: Permission errors on npm install
```bash
# Fix npm permissions
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

## Next Steps

1. Review the [README.md](README.md) for detailed usage instructions
2. Explore the application at http://localhost:3001
3. Check the CI/CD pipeline in GitHub Actions
4. Customize the application for your needs

## Support

For issues or questions:
1. Check the [Troubleshooting section in README.md](README.md#-troubleshooting)
2. Review GitHub Actions logs
3. Check container logs: `docker-compose logs -f`
4. Check Kubernetes logs: `kubectl logs -f deployment/backend -n task-app`

