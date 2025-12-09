#!/bin/bash

# Start GraphQL Lab in Development Environment
# This script uses the default .env file

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

echo "========================================="
echo "Starting GraphQL Lab - DEV Environment"
echo "========================================="
echo ""

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "Error: .env file not found!"
    echo "Please copy .env.example to .env and configure it."
    exit 1
fi

echo "Environment: DEVELOPMENT"
echo "Using config file: .env"
echo ""

# Display current environment variables
echo "Configuration:"
echo "  MySQL Database: ${MYSQL_DATABASE:-graphqllab}"
echo "  MySQL Port: ${MYSQL_PORT:-3306}"
echo "  API Port: ${API_PORT:-8080}"
echo ""

# Start services
echo "Starting services..."
docker compose up -d

echo ""
echo "Services started successfully!"
echo ""
echo "Available endpoints:"
echo "  - API: http://localhost:${API_PORT:-8080}"
echo "  - Health: http://localhost:${API_PORT:-8080}/health"
echo "  - MySQL: localhost:${MYSQL_PORT:-3306}"
echo ""
echo "View logs:"
echo "  docker compose logs -f"
echo ""
echo "Stop services:"
echo "  docker compose down"
