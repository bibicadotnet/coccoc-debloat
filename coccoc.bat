@echo off
PowerShell.exe -Command "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force"
PowerShell.exe -Command "irm https://go.bibica.net/coccoc  | iex"
pause