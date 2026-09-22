@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Portable Local AI - Vision & Reasoning Router
cd /d "%~dp0"

set "MODELS_DIR=%~dp0Models"
set "SERVER="

:: Locate llama-server.exe
for /r "%~dp0llama-router" %%F in (llama-server.exe) do if not defined SERVER set "SERVER=%%F"

if not defined SERVER (
    echo ========================================================
    echo  [!] llama-server.exe was not found!
    echo ========================================================
    echo.
    echo  Please run Install-Llama-Router.bat first to download
    echo  the llama.cpp server binaries automatically.
    echo.
    pause
    exit /b 1
)

:: Create Models directory if it doesn't exist
if not exist "%MODELS_DIR%" mkdir "%MODELS_DIR%"

echo ========================================================
echo        PORTABLE USB LOCAL AI - MULTI-MODEL ROUTER
echo        Text Reasoning + Multimodal Vision Support
echo ========================================================
echo.

:: Automatically scan Models folder and pair vision models with mmproj projectors
echo [*] Scanning Models folder and configuring presets...
if exist "%~dp0scripts\scan_models.ps1" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\scan_models.ps1" -Root "%~dp0"
)
echo.

set "PRESET_ARG="
if exist "%~dp0models.ini" (
    set "PRESET_ARG=--models-preset "%~dp0models.ini""
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
echo.
echo [*] Opening Web UI in your default browser...
start "" "http://127.0.0.1:8080"
echo [*] Starting llama-server router...
echo.

"%SERVER%" --host 127.0.0.1 --port 8080 !PRESET_ARG! --models-dir "%MODELS_DIR%" --models-max 1 --ctx-size 8192 --n-gpu-layers 0

echo.
echo ========================================================
echo  Server stopped.
echo ========================================================
pause