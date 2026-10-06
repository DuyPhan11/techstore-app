@echo off
title TechStore Launcher
echo ========================================================
echo   Launching TechStore Services...
echo ========================================================
start "TechStore Backend" cmd /c ""%~dp0start-backend.bat""
start "TechStore Frontend" cmd /c ""%~dp0start-frontend.bat""
echo.
echo Frontend: http://localhost:5500
echo Backend:  http://localhost:8080
echo.
echo Opening browser in 3 seconds...
timeout /t 3 /nobreak >nul
start http://localhost:5500
echo.
echo NOTE: Please wait about 10-15 seconds for the backend to finish compiling/starting.
pause
