@echo off
REM Start GraphQL Lab in Development Environment
REM This script uses the default .env file

setlocal enabledelayedexpansion

echo =========================================
echo Starting GraphQL Lab - DEV Environment
echo =========================================
echo.

cd /d "%~dp0.."

REM Check if .env exists
if not exist ".env" (
    echo Error: .env file not found!
    echo Please copy .env.example to .env and configure it.
    exit /b 1
)

echo Environment: DEVELOPMENT
echo Using config file: .env
echo.

REM Load .env file (basic version)
for /f "usebackq tokens=1,2 delims==" %%a in (".env") do (
    set "%%a=%%b"
)

echo Configuration:
echo   MySQL Database: %MYSQL_DATABASE%
echo   MySQL Port: %MYSQL_PORT%
echo   API Port: %API_PORT%
echo.

REM Start services
echo Starting services...
docker compose up -d

echo.
echo Services started successfully!
echo.
echo Available endpoints:
echo   - API: http://localhost:%API_PORT%
echo   - Health: http://localhost:%API_PORT%/health
echo   - MySQL: localhost:%MYSQL_PORT%
echo.
echo View logs:
echo   docker compose logs -f
echo.
echo Stop services:
echo   docker compose down

endlocal
