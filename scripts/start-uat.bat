@echo off
REM Start GraphQL Lab in UAT Environment
REM This script uses .env.uat configuration

setlocal enabledelayedexpansion

echo =========================================
echo Starting GraphQL Lab - UAT Environment
echo =========================================
echo.

cd /d "%~dp0.."

REM Check if .env.uat exists
if not exist ".env.uat" (
    echo Error: .env.uat file not found!
    echo Please create .env.uat configuration file.
    exit /b 1
)

echo Environment: UAT (User Acceptance Test^)
echo Using config file: .env.uat
echo.

REM Load .env.uat file
for /f "usebackq tokens=1,2 delims==" %%a in (".env.uat") do (
    set "%%a=%%b"
)

echo Configuration:
echo   MySQL Database: %MYSQL_DATABASE%
echo   MySQL Port: 3308 (external^), 3306 (internal^)
echo   API Port: 8082 (external^), 8080 (internal^)
echo   GIN Mode: %GIN_MODE%
echo.

REM Start services with UAT override
echo Starting services...
docker compose -f docker-compose.yml -f docker-compose.uat.yml --env-file .env.uat up -d

echo.
echo Services started successfully!
echo.
echo Available endpoints:
echo   - API: http://localhost:8082
echo   - Health: http://localhost:8082/health
echo   - MySQL: localhost:3308
echo.
echo View logs:
echo   docker compose -f docker-compose.yml -f docker-compose.uat.yml logs -f
echo.
echo Stop services:
echo   docker compose -f docker-compose.yml -f docker-compose.uat.yml down

endlocal
