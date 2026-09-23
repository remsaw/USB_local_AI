@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Portable Local AI - Portable History Router
cd /d "%~dp0"

:: Get current directory without trailing backslash
set "ROOT_DIR=%~dp0"
if "%ROOT_DIR:~-1%"=="\" set "ROOT_DIR=%ROOT_DIR:~0,-1%"

set "MODELS_DIR=%ROOT_DIR%\Models"
set "SERVER="

:: Check if llama-server.exe exists
if exist "%ROOT_DIR%\llama-router\llama-server.exe" (
    set "SERVER=%ROOT_DIR%\llama-router\llama-server.exe"
) else (
    for /r "%ROOT_DIR%\llama-router" %%F in (llama-server.exe) do (
        if exist "%%F" if not defined SERVER set "SERVER=%%F"
    )
)

:: If server not found, offer one-click installation
if not defined SERVER (
    echo ========================================================
    echo  [!] llama-server.exe was not found!
    echo ========================================================
    echo.
    echo  The llama.cpp server binaries have not been downloaded yet.
    echo.
    set /p "RUN_INSTALL=Would you like to download and install llama-server now? (Y/N): "
    if /i "!RUN_INSTALL!"=="Y" (
        echo.
        call "%ROOT_DIR%\Install-Llama-Router.bat"
        if exist "%ROOT_DIR%\llama-router\llama-server.exe" (
            set "SERVER=%ROOT_DIR%\llama-router\llama-server.exe"
        )
    )
    if not defined SERVER (
        echo.
        echo Please run Install-Llama-Router.bat first, then run Start-AI-Router.bat.
        echo.
        pause
        exit /b 1
    )
)

:: Ensure Models directory exists
if not exist "%MODELS_DIR%" mkdir "%MODELS_DIR%"

echo ========================================================
echo        PORTABLE USB LOCAL AI - MULTI-MODEL ROUTER
echo        Text Reasoning + Multimodal Vision Support
echo ========================================================
echo.

:: Automatically scan Models folder and pair vision models with mmproj projectors
echo [*] Scanning Models folder and configuring presets...
if exist "%ROOT_DIR%\scripts\scan_models.ps1" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%ROOT_DIR%\scripts\scan_models.ps1" -Root "%ROOT_DIR%"
)
echo.

:: Configure model loading
:: IMPORTANT: use the Models folder directly so /models?reload=1
:: can discover newly added GGUF files without editing models.ini.
set "MODEL_ARGS=--models-dir "%MODELS_DIR%""

:: Configure Web UI path if custom webui folder is present
set "WEBUI_ARG="
if exist "%ROOT_DIR%\webui" (
    set "WEBUI_ARG=--path "%ROOT_DIR%\webui""
)

echo --------------------------------------------------------
echo  Web UI URL : http://127.0.0.1:8080
echo  Storage    : %MODELS_DIR%
echo  Portability: USB Drive Mode (Zero Installation Required)
echo --------------------------------------------------------
echo.
echo  QUICK TIPS:
echo  1. Switching Models: Use the top-left dropdown in the Web UI.
echo     Models load on-demand and unload automatically to save RAM.
echo  2. Image Upload: Select a [VISION] model from the dropdown.
echo     Drag-and-drop an image or click the paperclip icon.
echo  3. Reasoning Models: Select a [TEXT/R1] model to view
echo     internal chain-of-thought tokens.
echo  4. MCP Servers: Access 'MCP Servers' directly in the left
echo     sidebar between Search and Settings.
echo  5. Portable History: conversations and uploaded files/images are saved
echo     to Data\conversations.json and Data\uploads\ on the USB drive.
echo.
echo [*] Starting Portable History service...
if exist "%ROOT_DIR%\Portable-History-Server.ps1" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$c = Get-NetTCPConnection -LocalPort 8765 -State Listen -ErrorAction SilentlyContinue; if ($c) { Stop-Process -Id $c.OwningProcess -Force -ErrorAction SilentlyContinue }" >nul 2>&1
    start "Portable AI History" /min powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%ROOT_DIR%\Portable-History-Server.ps1" -Root "%ROOT_DIR%" -Port 8765
) else (
    echo [!] Portable-History-Server.ps1 not found - continuing without portable history.
)
echo.
echo [*] Opening Web UI in your default browser...
start "" "http://127.0.0.1:8080"
echo [*] Starting llama-server router...
echo.

"%SERVER%" --host 127.0.0.1 --port 8080 !MODEL_ARGS! !WEBUI_ARG! --models-max 1 --ctx-size 8192 --n-gpu-layers 0 --webui-mcp-proxy

echo.
echo [*] Stopping Portable History service...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$c = Get-NetTCPConnection -LocalPort 8765 -State Listen -ErrorAction SilentlyContinue; if ($c) { Stop-Process -Id $c.OwningProcess -Force -ErrorAction SilentlyContinue }" >nul 2>&1

echo.
echo ========================================================
echo  Server stopped.
echo ========================================================
pause