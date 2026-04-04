### [MOST USED]

@echo off
title Shxdow Cleanup v3.1 Launcher
:: Force le script a regarder dans son propre dossier, meme avec des espaces
set "mypath=%~dp0"
cd /d "%mypath%"

:: --- VERIFICATION DES DROITS ADMIN ---
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] Requesting Administrative Privileges...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:: --- RECHERCHE AUTOMATIQUE ---
:: On cherche n'importe quel fichier .ps1 qui contient "Shxdow" ou "Cleanup"
for /f "delims=" %%i in ('dir /b /s "Shxdow*.ps1" "Cleanup*.ps1" 2^>nul') do set "myscript=%%i"

if defined myscript (
    echo [OK] Found: "%myscript%"
    echo [OK] Launching...
    powershell -NoProfile -ExecutionPolicy Bypass -File "%myscript%"
) else (
    echo.
    echo [!] ERROR: No .ps1 file found in: "%cd%"
    echo [!] Make sure your script is in this folder!
    echo.
    pause
)

pause
