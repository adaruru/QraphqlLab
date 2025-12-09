# Docker Setup Guide

This directory contains documentation for running the GraphQL Lab project using Docker Compose.

## Quick Start

### Prerequisites
- Docker Desktop installed and running
- Docker Compose (included with Docker Desktop)

### 1. Start the Application

```bash
# Start all services (MySQL + API)
docker-compose up -d

# View logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f api
docker-compose logs -f mysql
```

### 2. Verify the Setup

Check if services are running:
```bash
docker-compose ps
```

Test the API health endpoint:
```bash
curl http://localhost:8080/health
```

Expected response:
```json
{"status":"healthy","database":"connected"}
```

### 3. Stop the Application

```bash
# Stop services
docker-compose down

# Stop and remove volumes (WARNING: This will delete all data)
docker-compose down -v
```

## Services

### MySQL Service
- **Port**: 3306
- **Container**: `graphqllab-mysql`
- **Database**: `graphqllab`
- **Default credentials**:
  - Root password: `rootpassword`
  - User: `graphqluser`
  - Password: `graphqlpass`

### API Service
- **Port**: 8080
- **Container**: `graphqllab-api`
- **Health check**: http://localhost:8080/health

## Configuration

Configuration is managed through the `.env` file in the project root:

```env
# MySQL Configuration
MYSQL_ROOT_PASSWORD=rootpassword
MYSQL_DATABASE=graphqllab
MYSQL_USER=graphqluser
MYSQL_PASSWORD=graphqlpass
MYSQL_PORT=3306

# API Configuration
API_PORT=8080
GIN_MODE=debug
```

## Database Initialization

The MySQL database is automatically initialized on first startup with:
1. **Schema** (`infra/dbinit/schema.sql`) - Creates tables
2. **Seed data** (`infra/dbinit/seed.sql`) - Populates test data

## Connecting to MySQL

### From Host Machine
```bash
mysql -h 127.0.0.1 -P 3306 -u graphqluser -p
# Password: graphqlpass
```

### From API Container
The API automatically connects using environment variables:
- Host: `mysql` (Docker network hostname)
- Port: `3306`
- User: `graphqluser`
- Password: `graphqlpass`
- Database: `graphqllab`

### Using Docker Exec
```bash
docker exec -it graphqllab-mysql mysql -u graphqluser -p graphqllab
```

## Troubleshooting

### MySQL Container Won't Start
```bash
# Check logs
docker-compose logs mysql

# Remove volumes and restart
docker-compose down -v
docker-compose up -d
```

### API Can't Connect to Database
```bash
# Ensure MySQL is healthy
docker-compose ps

# Check API logs
docker-compose logs api

# Verify network connectivity
docker exec graphqllab-api ping mysql
```

### Rebuild Containers
```bash
# Rebuild all services
docker-compose build --no-cache

# Rebuild and restart
docker-compose up -d --build
```

## Development Workflow

### Making Code Changes
The API container needs to be rebuilt after code changes:

```bash
# Rebuild and restart API service only
docker-compose up -d --build api
```

### Resetting Database
```bash
# Stop services
docker-compose down

# Remove only the database volume
docker volume rm qraphqllab_mysql_data

# Restart (will reinitialize database)
docker-compose up -d
```

### Accessing Container Shell
```bash
# API container
docker exec -it graphqllab-api sh

# MySQL container
docker exec -it graphqllab-mysql bash
```

## Production Deployment

For production, modify the `.env` file:

```env
GIN_MODE=release
MYSQL_ROOT_PASSWORD=<strong-password>
MYSQL_PASSWORD=<strong-password>
```

Also consider:
- Using Docker secrets for sensitive data
- Implementing proper logging
- Setting up reverse proxy (nginx)
- Enabling HTTPS
- Regular database backups
