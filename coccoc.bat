@echo off
setlocal enabledelayedexpansion

net session >nul 2>&1
if !errorLevel! == 0 (
    goto :main
) else (
    echo Requesting administrator privileges...
    powershell -Command "Start-Process cmd -ArgumentList '/c \"%~f0\"' -Verb RunAs"
    exit /b
)

:main
cd /d "%~dp0"

if not exist "install-coccoc.ps1" (
    echo install-coccoc.ps1 not found in current directory
    pause
    exit /b 1
)


powershell -Command "Get-Content \"install-coccoc.ps1\" -Encoding UTF8 | Out-File \"install-coccoc-fixed.ps1\" -Encoding UTF8"
del "install-coccoc.ps1" >nul 2>&1
ren "install-coccoc-fixed.ps1" "install-coccoc.ps1" >nul 2>&1


powershell -ExecutionPolicy Bypass -File "install-coccoc.ps1"

pause
