@echo off
setlocal enabledelayedexpansion

:: Kiểm tra quyền admin
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

if not exist "profile.ps1" (
    echo profile.ps1 not found in current directory
    pause
    exit /b 1
)

:: Chuẩn hoá lại file PowerShell về UTF8
powershell -Command "Get-Content \"profile.ps1\" -Encoding UTF8 | Out-File \"install-coccoc-fixed.ps1\" -Encoding UTF8"
del "profile.ps1" >nul 2>&1
ren "install-coccoc-fixed.ps1" "profile.ps1" >nul 2>&1

:: Thực thi file PowerShell
powershell -ExecutionPolicy Bypass -File "profile.ps1"

pause
