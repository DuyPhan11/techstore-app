@echo off
title TechStore - Frontend Server
echo ========================================================
echo   Starting TechStore Frontend (Port 5500)
echo ========================================================
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :5500 ^| findstr LISTENING') do (
    taskkill /f /pid %%a >nul 2>&1
)
cd /d "%~dp0frontend"
call npx serve -l 5500 -c serve.json
pause
