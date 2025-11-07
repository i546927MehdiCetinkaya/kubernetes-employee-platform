@echo off
echo =========================================
echo   STARTING BACKEND WITH DYNAMODB
echo =========================================
echo.

cd /d "%~dp0..\applications\hr-portal\backend"

set PORT=3001
set AWS_REGION=eu-west-1
set DYNAMODB_TABLE=innovatech-employees
set DYNAMODB_WORKSPACES_TABLE=innovatech-employees-workspaces

echo Backend will start on: http://localhost:3001
echo Connected to DynamoDB in eu-west-1
echo.
echo Press Ctrl+C to stop
echo.

npm start

pause
