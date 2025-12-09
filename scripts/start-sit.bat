@echo off
REM Start GraphQL Lab in SIT Environment
REM This script uses .env.sit configuration

setlocal enabledelayedexpansion

echo =========================================
echo Starting GraphQL Lab - SIT Environment
echo =========================================
echo.

cd /d "%~dp0.."

REM Check if .env.sit exists
if not exist ".env.sit" (
    echo Error: .env.sit file not found!
    echo Please create .env.sit configuration file.
    exit /b 1
)

echo Environment: SIT (System Integration Test^)
echo Using config file: .env.sit
echo.

REM Load .env.sit file
for /f "usebackq tokens=1,2 delims==" %%a in (".env.sit") do (
    set "%%a=%%b"
)

echo Configuration:
echo   MySQL Database: %MYSQL_DATABASE%
echo   MySQL Port: 3307 (external^), 3306 (internal^)
echo   API Port: 8081 (external^), 8080 (internal^)
echo.

REM Start services with SIT override
echo Starting services...
docker compose -f docker-compose.yml -f docker-compose.sit.yml --env-file .env.sit up -d

echo.
echo Services started successfully!
echo.
echo Available endpoints:
echo   - API: http://localhost:8081
echo   - Health: http://localhost:8081/health
echo   - MySQL: localhost:3307
echo.
echo View logs:
echo   docker compose -f docker-compose.yml -f docker-compose.sit.yml logs -f
echo.
echo Stop services:
echo   docker compose -f docker-compose.yml -f docker-compose.sit.yml down

endlocal
