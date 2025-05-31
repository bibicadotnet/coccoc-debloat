@echo off
PowerShell.exe -Command "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force"
PowerShell.exe -Command "irm https://raw.githubusercontent.com/bibicadotnet/coccoc-debloat/refs/heads/main/profile.ps1  | iex"
pause
