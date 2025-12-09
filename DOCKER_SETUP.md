# Docker Setup - Quick Reference

## Files Created

### Docker Configuration Files
- [Dockerfile](Dockerfile) - Go application multi-stage build
- [infra/Dockerfile.mysql](infra/Dockerfile.mysql) - MySQL with auto-initialization
- [docker-compose.yml](docker-compose.yml) - Complete orchestration
- [.dockerignore](.dockerignore) - Build optimization
- [.env](.env) - Environment variables

### Documentation
- [docker/README.md](docker/README.md) - Comprehensive Docker guide
- [scripts/test-docker.sh](scripts/test-docker.sh) - Automated testing script

## Quick Start Commands

### Start Everything
```bash
docker compose up -d
```

### Check Status
```bash
docker compose ps
docker compose logs -f
```

### Test API
```bash
curl http://localhost:8080/health
```

Expected response:
```json
{"status":"healthy","database":"connected"}
```

### Stop Everything
```bash
docker compose down
```

## Services Overview

| Service | Port | Container Name | Description |
|---------|------|----------------|-------------|
| MySQL | 3306 | graphqllab-mysql | Database with auto-init |
| API | 8080 | graphqllab-api | Go application |

## Database Access

### From Host
```bash
mysql -h 127.0.0.1 -P 3306 -u graphqluser -pgraphqlpass graphqllab
```

### From Container
```bash
docker exec -it graphqllab-mysql mysql -u graphqluser -pgraphqlpass graphqllab
```

## Architecture

```
┌─────────────────────────────────────────┐
│         Docker Compose Network          │
│                                         │
│  ┌────────────────┐  ┌──────────────┐ │
│  │   MySQL 8.0    │  │  Go API      │ │
│  │                │  │              │ │
│  │  Port: 3306    │◄─┤  Port: 8080  │ │
│  │                │  │              │ │
│  │  Auto-init:    │  │  Features:   │ │
│  │  - schema.sql  │  │  - Health    │ │
│  │  - seed.sql    │  │  - DB test   │ │
│  └────────────────┘  └──────────────┘ │
│         │                    │         │
└─────────┼────────────────────┼─────────┘
          │                    │
      Volume                   │
   (mysql_data)                │
                         Port Mapping
                         localhost:8080
```

## Features Implemented

### MySQL Container
- Based on MySQL 8.0 official image
- Automatic database initialization
- Copies `schema.sql` and `seed.sql` on first run
- Health check configured
- Persistent volume for data

### Go API Container
- Multi-stage build (builder + runtime)
- Minimal Alpine-based runtime image
- Environment variable configuration
- Database connection with retry
- Health check endpoint
- Automatic startup after MySQL is healthy

### Docker Compose
- Service orchestration
- Network isolation
- Volume management
- Health checks
- Environment variable support
- Dependency management (API waits for MySQL)

## Environment Variables

All configurable via `.env` file:

```env
# MySQL
MYSQL_ROOT_PASSWORD=rootpassword
MYSQL_DATABASE=graphqllab
MYSQL_USER=graphqluser
MYSQL_PASSWORD=graphqlpass
MYSQL_PORT=3306

# API
API_PORT=8080
GIN_MODE=debug
```

## Testing

Run the automated test script:

```bash
chmod +x scripts/test-docker.sh
./scripts/test-docker.sh
```

The script will:
1. Validate Docker installation
2. Validate docker-compose.yml
3. Start services
4. Wait for MySQL health check
5. Test API health endpoint
6. Test database connectivity
7. Report results

## Troubleshooting

### Services Won't Start
```bash
docker compose logs
docker compose ps
```

### Rebuild Containers
```bash
docker compose build --no-cache
docker compose up -d
```

### Reset Database
```bash
docker compose down -v
docker compose up -d
```

### Access Container Shell
```bash
# API
docker exec -it graphqllab-api sh

# MySQL
docker exec -it graphqllab-mysql bash
```

## Next Steps

The Docker environment is ready for:
1. ✅ Database operations
2. ✅ API development
3. ⏳ GraphQL integration
4. ⏳ RESTful API endpoints
5. ⏳ Frontend development

## Notes

- First startup takes longer (30-60 seconds) due to database initialization
- Database data persists in Docker volume `mysql_data`
- API automatically reconnects if MySQL restarts
- All ports are mapped to localhost for development
