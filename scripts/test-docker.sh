#!/bin/bash

# Docker Compose Test Script
# This script tests the Docker Compose setup

set -e

echo "==================================="
echo "GraphQL Lab Docker Compose Test"
echo "==================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}→ $1${NC}"
}

# Check if Docker is installed
print_info "Checking Docker installation..."
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker Desktop."
    exit 1
fi
print_success "Docker is installed"

# Check if Docker Compose is available
print_info "Checking Docker Compose..."
if docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
elif docker-compose version &> /dev/null; then
    COMPOSE_CMD="docker-compose"
else
    print_error "Docker Compose is not available"
    exit 1
fi
print_success "Docker Compose is available: $COMPOSE_CMD"

# Validate docker-compose.yml
print_info "Validating docker-compose.yml..."
$COMPOSE_CMD config > /dev/null
print_success "docker-compose.yml is valid"

# Start services
print_info "Starting services..."
$COMPOSE_CMD up -d

# Wait for services to be healthy
print_info "Waiting for MySQL to be healthy (this may take 30-60 seconds)..."
COUNTER=0
MAX_TRIES=60
until $COMPOSE_CMD ps | grep -q "healthy" || [ $COUNTER -eq $MAX_TRIES ]; do
    sleep 2
    COUNTER=$((COUNTER+1))
    echo -n "."
done
echo ""

if [ $COUNTER -eq $MAX_TRIES ]; then
    print_error "MySQL failed to become healthy"
    $COMPOSE_CMD logs mysql
    exit 1
fi
print_success "MySQL is healthy"

# Wait a bit more for API to start
sleep 5

# Check if services are running
print_info "Checking service status..."
$COMPOSE_CMD ps

# Test API health endpoint
print_info "Testing API health endpoint..."
sleep 2
if curl -f http://localhost:8080/health > /dev/null 2>&1; then
    print_success "API health check passed"
    curl -s http://localhost:8080/health | python -m json.tool 2>/dev/null || curl -s http://localhost:8080/health
else
    print_error "API health check failed"
    print_info "API logs:"
    $COMPOSE_CMD logs api
    exit 1
fi

# Test database connectivity
print_info "Testing database connectivity..."
if $COMPOSE_CMD exec -T mysql mysql -u graphqluser -pgraphqlpass -e "SELECT COUNT(*) FROM users;" graphqllab > /dev/null 2>&1; then
    print_success "Database connectivity test passed"
    USER_COUNT=$($COMPOSE_CMD exec -T mysql mysql -u graphqluser -pgraphqlpass -e "SELECT COUNT(*) as count FROM users;" graphqllab -N -B | tail -1)
    print_info "Found $USER_COUNT users in database"
else
    print_error "Database connectivity test failed"
    exit 1
fi

echo ""
echo "==================================="
print_success "All tests passed!"
echo "==================================="
echo ""
print_info "Services are running:"
echo "  - MySQL: http://localhost:3306"
echo "  - API: http://localhost:8080"
echo "  - Health check: http://localhost:8080/health"
echo ""
print_info "To view logs:"
echo "  $COMPOSE_CMD logs -f"
echo ""
print_info "To stop services:"
echo "  $COMPOSE_CMD down"
