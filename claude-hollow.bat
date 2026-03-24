@echo off
for /f "delims=" %%i in ('where bash 2^>nul') do (
    set "BASH=%%i"
    goto :run
)
echo Error: bash not found. Please install Git for Windows: https://git-scm.com
exit /b 1
:run
cd /d "%~dp0"
"%BASH%" --login scripts/hollow.sh
