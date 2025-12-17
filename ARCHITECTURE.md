# Architecture Documentation

## System Overview

This application demonstrates a modern microservices architecture with event-driven communication, containerization, and cloud-native deployment patterns.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                         Frontend                             │
│                    (React + TypeScript)                      │
│                         Port: 80                             │
└──────────────────────┬──────────────────────────────────────┘
                       │ HTTP/REST
                       │
┌──────────────────────▼──────────────────────────────────────┐
│                      Backend API                             │
│               (Node.js + Express + TypeScript)               │
│                        Port: 3000                            │
└─────┬────────────────────────────────────────────┬──────────┘
      │                                            │
      │ SQL Queries                                │ Kafka Events
      │                                            │
┌─────▼─────────┐                        ┌────────▼──────────┐
│   PostgreSQL  │                        │      Kafka        │
│   Database    │                        │   Message Queue   │
│   Port: 5432  │                        │    Port: 9092     │
└───────────────┘                        └────────┬──────────┘
      ▲                                           │
      │                                           │ Consume Events
      │ SQL Queries                               │
      │                                           │
┌─────┴────────────────────────────────────┬─────▼──────────┐
│              Message Consumer             │                │
│                 (Python)                  │                │
│          Processes Kafka Events           │                │
└───────────────────────────────────────────┴────────────────┘
```

## Components

### 1. Frontend (React + TypeScript)

**Purpose**: User interface for task management

**Technology Stack**:
- React 18
- TypeScript
- Vite (build tool)
- Axios (HTTP client)

**Responsibilities**:
- Display tasks in an intuitive UI
- Handle user interactions
- Make API calls to backend
- Client-side validation

**Key Features**:
- Responsive design
- Real-time task updates
- Form validation
- Error handling

**Container**:
- Base: `node:20-alpine` (build), `nginx:alpine` (runtime)
- Exposed Port: 80
- Nginx reverse proxy configuration

### 2. Backend API (Node.js + Express + TypeScript)

**Purpose**: RESTful API for task management and event publishing

**Technology Stack**:
- Node.js 20
- Express.js
- TypeScript
- PostgreSQL driver (pg)
- KafkaJS

**Responsibilities**:
- CRUD operations for tasks
- Database management
- Kafka event publishing
- Request validation
- Error handling

**API Endpoints**:
- `GET /health` - Health check
- `GET /api/tasks` - List all tasks
- `GET /api/tasks/:id` - Get task by ID
- `POST /api/tasks` - Create new task
- `PUT /api/tasks/:id` - Update task
- `DELETE /api/tasks/:id` - Delete task

**Events Published**:
- `task.created` - When a task is created
- `task.updated` - When a task is updated
- `task.deleted` - When a task is deleted

**Container**:
- Base: `node:20-alpine`
- Exposed Port: 3000
- Multi-stage build for optimization

### 3. Message Consumer (Python)

**Purpose**: Process Kafka events and maintain audit log

**Technology Stack**:
- Python 3.11
- kafka-python
- psycopg2 (PostgreSQL driver)

**Responsibilities**:
- Consume events from Kafka
- Process task events
- Write to audit log table
- Error handling and retry logic

**Event Processing**:
```python
def process_task_event(event_data):
    # Extract event details
    event_type = event_data['event']
    task_data = event_data['task']
    
    # Write to audit log
    INSERT INTO task_audit_log (event_type, task_id, event_data)
    VALUES (event_type, task_id, json_data)
```

**Container**:
- Base: `python:3.11-slim`
- No exposed ports (internal service)

### 4. PostgreSQL Database

**Purpose**: Persistent data storage

**Schema**:

```sql
-- Tasks table
CREATE TABLE tasks (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Audit log table (created by consumer)
CREATE TABLE task_audit_log (
    id SERIAL PRIMARY KEY,
    event_type VARCHAR(50) NOT NULL,
    task_id INTEGER,
    event_data JSONB NOT NULL,
    processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Container**:
- Image: `postgres:16-alpine`
- Exposed Port: 5432
- Persistent volume for data

### 5. Apache Kafka

**Purpose**: Event streaming and message queue

**Components**:
- **Zookeeper**: Kafka coordination service
- **Kafka Broker**: Message broker

**Topics**:
- `task-events` - Task lifecycle events

**Configuration**:
- Single broker setup (development)
- Auto-create topics enabled
- Replication factor: 1

**Container**:
- Images: 
  - `confluentinc/cp-zookeeper:7.5.0`
  - `confluentinc/cp-kafka:7.5.0`
- Exposed Ports: 2181 (Zookeeper), 9092 (Kafka)

## Data Flow

### Create Task Flow

```
1. User submits task via Frontend
   ↓
2. Frontend sends POST /api/tasks to Backend
   ↓
3. Backend validates and inserts into PostgreSQL
   ↓
4. Backend publishes task.created event to Kafka
   ↓
5. Consumer receives event from Kafka
   ↓
6. Consumer writes audit log to PostgreSQL
   ↓
7. Backend returns task to Frontend
   ↓
8. Frontend displays new task
```

### Update Task Flow

```
1. User updates task via Frontend
   ↓
2. Frontend sends PUT /api/tasks/:id to Backend
   ↓
3. Backend updates task in PostgreSQL
   ↓
4. Backend publishes task.updated event to Kafka
   ↓
5. Consumer receives event from Kafka
   ↓
6. Consumer writes audit log to PostgreSQL
   ↓
7. Backend returns updated task to Frontend
   ↓
8. Frontend updates task display
```

## Kubernetes Architecture

### Namespace

All resources are deployed in the `task-app` namespace for isolation.

### Deployments

1. **PostgreSQL**
   - Replicas: 1
   - StatefulSet pattern (via single replica Deployment)
   - PersistentVolumeClaim for data
   - Liveness and readiness probes

2. **Zookeeper**
   - Replicas: 1
   - Required for Kafka operation

3. **Kafka**
   - Replicas: 1
   - Depends on Zookeeper
   - Liveness and readiness probes

4. **Backend**
   - Replicas: 2 (for high availability)
   - Rolling update strategy
   - Resource limits: 512Mi memory, 500m CPU
   - Health check endpoint

5. **Consumer**
   - Replicas: 1
   - Single instance for sequential processing
   - Resource limits: 256Mi memory, 200m CPU

6. **Frontend**
   - Replicas: 2 (for high availability)
   - Nginx serving static files
   - Reverse proxy to backend

### Services

- **postgres**: ClusterIP (internal only)
- **zookeeper**: ClusterIP (internal only)
- **kafka**: ClusterIP (internal only)
- **backend**: ClusterIP (accessed via frontend proxy)
- **frontend**: LoadBalancer (external access)

### ConfigMaps and Secrets

**ConfigMaps**:
- `backend-config`: Backend environment variables
- `consumer-config`: Consumer environment variables
- `postgres-config`: PostgreSQL configuration

**Secrets**:
- `backend-secret`: Database passwords
- `consumer-secret`: Database passwords
- `postgres-secret`: PostgreSQL password

## CI/CD Pipeline

### Pipeline Stages

```
┌──────────────┐
│  Code Push   │
└──────┬───────┘
       │
┌──────▼────────────┐
│   Test Phase      │
├───────────────────┤
│ - Backend tests   │
│ - Consumer tests  │
│ - Frontend tests  │
└──────┬────────────┘
       │
┌──────▼────────────┐
│   Build Phase     │
├───────────────────┤
│ - Build images    │
│ - Tag images      │
│ - Push to registry│
└──────┬────────────┘
       │
┌──────▼────────────┐
│  Deploy Phase     │
├───────────────────┤
│ - Apply K8s       │
│ - Rolling update  │
│ - Health checks   │
└──────┬────────────┘
       │
┌──────▼────────────┐
│Integration Tests  │
└───────────────────┘
```

### Workflow Jobs

1. **test-backend**
   - Node.js 20
   - PostgreSQL & Kafka services
   - Run Jest tests
   - Generate coverage

2. **test-consumer**
   - Python 3.11
   - Run pytest
   - Generate coverage

3. **test-frontend**
   - Node.js 20
   - Build production bundle
   - Run Vitest tests

4. **build-images**
   - Docker Buildx
   - Multi-platform support
   - Push to GitHub Container Registry
   - Image caching

5. **deploy**
   - kubectl configured
   - Apply Kubernetes manifests
   - Verify rollout status

6. **integration-tests**
   - Docker Compose environment
   - API endpoint testing
   - End-to-end verification

## Scalability Considerations

### Horizontal Scaling

**Backend**:
- Stateless design allows easy horizontal scaling
- Load balanced via Kubernetes Service
- Session-free (can add session store if needed)

**Frontend**:
- Static files served by Nginx
- CDN-ready
- Can scale to many replicas

**Consumer**:
- Single instance for ordered processing
- Can scale with consumer groups for parallel processing

### Vertical Scaling

Resource limits are configured conservatively and can be increased:

```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

### Database Scaling

Current setup uses single PostgreSQL instance. For production:
- Add read replicas
- Use managed database service (RDS, Cloud SQL)
- Implement connection pooling (PgBouncer)

### Kafka Scaling

Current setup uses single broker. For production:
- Add multiple brokers
- Increase replication factor
- Add more partitions for parallel processing

## High Availability

### Application Layer
- Multiple replicas (2) for frontend and backend
- Rolling updates with zero downtime
- Health checks and automatic restarts

### Data Layer
- PersistentVolumeClaims for PostgreSQL
- Kafka message persistence
- Regular backups recommended

### Monitoring
- Liveness probes: Service is running
- Readiness probes: Service can accept traffic
- Resource monitoring via Kubernetes metrics

## Security Best Practices

1. **Secrets Management**
   - Kubernetes Secrets for sensitive data
   - Never commit secrets to repository
   - Environment variable injection

2. **Network Security**
   - Services isolated in namespace
   - ClusterIP for internal services
   - LoadBalancer only for frontend

3. **Container Security**
   - Alpine-based images (smaller attack surface)
   - Multi-stage builds
   - Non-root users (recommended enhancement)

4. **API Security**
   - CORS enabled
   - Input validation
   - Error handling without information leakage

## Performance Optimization

1. **Frontend**
   - Production build with Vite
   - Code splitting
   - Nginx gzip compression

2. **Backend**
   - Connection pooling for PostgreSQL
   - Kafka batch processing
   - Compiled TypeScript

3. **Database**
   - Indexed primary keys
   - Query optimization
   - Connection pooling

4. **Caching**
   - Docker layer caching
   - Build cache (GitHub Actions)
   - Browser caching (Nginx)

## Disaster Recovery

### Backup Strategy

1. **Database**
   ```bash
   kubectl exec -it deployment/postgres -n task-app -- \
     pg_dump -U postgres taskdb > backup.sql
   ```

2. **Persistent Volumes**
   - Regular snapshots
   - Cloud provider backup solutions

### Recovery Procedures

1. **Database Restore**
   ```bash
   kubectl exec -i deployment/postgres -n task-app -- \
     psql -U postgres taskdb < backup.sql
   ```

2. **Application Recovery**
   - Redeploy from Git
   - Pull images from registry
   - Apply Kubernetes manifests

## Future Enhancements

1. **Authentication & Authorization**
   - JWT tokens
   - OAuth integration
   - Role-based access control

2. **Monitoring & Observability**
   - Prometheus metrics
   - Grafana dashboards
   - Distributed tracing (Jaeger)
   - Centralized logging (ELK stack)

3. **Advanced Features**
   - Caching layer (Redis)
   - API rate limiting
   - WebSocket for real-time updates
   - Search functionality (Elasticsearch)

4. **Infrastructure**
   - Service mesh (Istio)
   - API Gateway
   - Certificate management (cert-manager)
   - Auto-scaling (HPA)

5. **Development**
   - API documentation (Swagger)
   - End-to-end tests (Cypress)
   - Load testing (k6)
   - Security scanning

