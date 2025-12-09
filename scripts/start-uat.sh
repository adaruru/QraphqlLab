#!/bin/bash

# Start GraphQL Lab in UAT Environment
# This script uses .env.uat configuration

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

echo "========================================="
echo "Starting GraphQL Lab - UAT Environment"
echo "========================================="
echo ""

# Check if .env.uat exists
if [ ! -f ".env.uat" ]; then
    echo "Error: .env.uat file not found!"
    echo "Please create .env.uat configuration file."
    exit 1
fi

echo "Environment: UAT (User Acceptance Test)"
echo "Using config file: .env.uat"
echo ""

# Load environment variables from .env.uat
export $(cat .env.uat | grep -v '^#' | xargs)

# Display current environment variables
echo "Configuration:"
echo "  MySQL Database: ${MYSQL_DATABASE}"
echo "  MySQL Port: 3308 (external), 3306 (internal)"
echo "  API Port: 8082 (external), 8080 (internal)"
echo "  GIN Mode: ${GIN_MODE}"
echo ""

# Start services with UAT override
echo "Starting services..."
docker compose -f docker-compose.yml -f docker-compose.uat.yml --env-file .env.uat up -d

echo ""
echo "Services started successfully!"
echo ""
echo "Available endpoints:"
echo "  - API: http://localhost:8082"
echo "  - Health: http://localhost:8082/health"
echo "  - MySQL: localhost:3308"
echo ""
echo "View logs:"
echo "  docker compose -f docker-compose.yml -f docker-compose.uat.yml logs -f"
echo ""
echo "Stop services:"
echo "  docker compose -f docker-compose.yml -f docker-compose.uat.yml down"
