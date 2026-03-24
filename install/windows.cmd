@echo off
:: Installs Claude Hollow — clones the repo here and adds the command to PATH.
::
:: Usage (CMD):
::   curl -fsSL https://raw.githubusercontent.com/GoblikM/claude-hollow/main/install.cmd -o install.cmd && install.cmd && del install.cmd

set REPO_URL=https://github.com/GoblikM/claude-hollow.git
set BRANCH=cestynak-hollow
set DEST=%CD%\claude-hollow

echo Cloning Claude Hollow into %DEST% ...
git clone --branch %BRANCH% %REPO_URL% %DEST%
if errorlevel 1 (
  echo.
  echo  Error: git clone failed. Make sure git is installed and you have internet access.
  pause & exit /b 1
)

powershell -NoProfile -Command ^
  "$dest = '%DEST%'; $p = [Environment]::GetEnvironmentVariable('PATH','User'); if (($p -split ';') -contains $dest) { Write-Host 'Already in PATH.' } else { [Environment]::SetEnvironmentVariable('PATH', $p + ';' + $dest, 'User'); Write-Host 'Added to PATH.' }"

echo.
echo  Installed: claude-hollow
echo  Restart your terminal and type: claude-hollow
echo.
pause
