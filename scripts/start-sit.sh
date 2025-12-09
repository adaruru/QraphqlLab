#!/bin/bash

# Start GraphQL Lab in SIT Environment
# This script uses .env.sit configuration

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

echo "========================================="
echo "Starting GraphQL Lab - SIT Environment"
echo "========================================="
echo ""

# Check if .env.sit exists
if [ ! -f ".env.sit" ]; then
    echo "Error: .env.sit file not found!"
    echo "Please create .env.sit configuration file."
    exit 1
fi

echo "Environment: SIT (System Integration Test)"
echo "Using config file: .env.sit"
echo ""

# Load environment variables from .env.sit
export $(cat .env.sit | grep -v '^#' | xargs)

# Display current environment variables
echo "Configuration:"
echo "  MySQL Database: ${MYSQL_DATABASE}"
echo "  MySQL Port: 3307 (external), 3306 (internal)"
echo "  API Port: 8081 (external), 8080 (internal)"
echo ""

# Start services with SIT override
echo "Starting services..."
docker compose -f docker-compose.yml -f docker-compose.sit.yml --env-file .env.sit up -d

echo ""
echo "Services started successfully!"
echo ""
echo "Available endpoints:"
echo "  - API: http://localhost:8081"
echo "  - Health: http://localhost:8081/health"
echo "  - MySQL: localhost:3307"
echo ""
echo "View logs:"
echo "  docker compose -f docker-compose.yml -f docker-compose.sit.yml logs -f"
echo ""
echo "Stop services:"
echo "  docker compose -f docker-compose.yml -f docker-compose.sit.yml down"
