@echo off
setlocal

set GITHUB_URL=https://raw.githubusercontent.com/Leqends/sml-depot/main/installer.ps1

powershell -ExecutionPolicy Bypass -Command "Invoke-Expression (Invoke-WebRequest -Uri '%GITHUB_URL%').Content"

endlocal
