@echo off
setlocal EnableExtensions
title Install llama.cpp Router - Windows x64 CPU
cd /d "%~dp0"

set "URL=https://github.com/ggml-org/llama.cpp/releases/download/b11065/llama-b11065-bin-win-cpu-x64.zip"
set "ZIP=%~dp0llama-b11065-bin-win-cpu-x64.zip"
set "DIR=%~dp0llama-router"

echo ========================================================
echo   Portable Local AI - llama.cpp Windows x64 CPU Setup
echo ========================================================
echo.
echo Downloading official llama.cpp CPU build (portable)...
echo URL: %URL%
echo.

where curl.exe >nul 2>&1
if errorlevel 1 (
    echo [!] ERROR: Windows curl.exe was not found.
    echo Please install curl or download the archive manually from GitHub.
    pause
    exit /b 1
)

curl.exe -L --fail --retry 3 -o "%ZIP%" "%URL%"
if errorlevel 1 (
    echo.
    echo [!] DOWNLOAD FAILED.
    echo Please check your Internet connection and try again.
    pause
    exit /b 1
)

if not exist "%ZIP%" (
    echo [!] ERROR: Archive file was not created.
    pause
    exit /b 1
)

echo.
echo [*] Extracting to %DIR%...
if exist "%DIR%" rmdir /s /q "%DIR%"
mkdir "%DIR%"

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -LiteralPath '%ZIP%' -DestinationPath '%DIR%' -Force"
if errorlevel 1 (
    echo.
    echo [!] EXTRACTION FAILED.
    pause
    exit /b 1
)

del /q "%ZIP%" >nul 2>&1

set "SERVER="
for /r "%DIR%" %%F in (llama-server.exe) do if not defined SERVER set "SERVER=%%F"

if not defined SERVER (
    echo.
    echo [!] ERROR: llama-server.exe was not found in extracted files.
    pause
    exit /b 1
)

echo.
echo ========================================================
echo  SUCCESS! llama.cpp Router is ready to use.
echo  Binary: %SERVER%
echo ========================================================
echo.
echo Next step:
echo 1. Put your .gguf models into the 'Models' folder.
echo 2. Run Start-AI-Router.bat to start chatting!
echo.
pause
