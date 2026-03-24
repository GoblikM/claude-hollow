@echo off
:: install.bat – Installs the `claude-hollow` command on Windows
::
:: Adds this repo's directory to the user PATH so that `claude-hollow`
:: works from CMD, PowerShell, and any terminal after a restart.

set "REPO=%~dp0"
if "%REPO:~-1%"=="\" set "REPO=%REPO:~0,-1%"

:: Check if already in PATH (case-insensitive via PowerShell)
powershell -NoProfile -Command ^
  "if ([Environment]::GetEnvironmentVariable('PATH','User') -split ';' | Where-Object { $_ -ieq '%REPO%' }) { exit 0 } else { exit 1 }" >nul 2>&1

if not errorlevel 1 (
  echo Already installed: %REPO% is already in your PATH.
  goto :done
)

powershell -NoProfile -Command ^
  "$p = [Environment]::GetEnvironmentVariable('PATH','User'); [Environment]::SetEnvironmentVariable('PATH', $p + ';%REPO%', 'User')"

echo.
echo  Installed: claude-hollow
echo  %REPO% added to your PATH.
echo.
echo  Restart your terminal, then type:  claude-hollow

:done
echo.
pause
