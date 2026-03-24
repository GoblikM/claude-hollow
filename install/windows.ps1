# Installs Claude Hollow — clones the repo here and adds the command to PATH.
#
# Usage (PowerShell):
#   irm https://raw.githubusercontent.com/GoblikM/claude-hollow/main/install.ps1 | iex

$REPO_URL = "https://github.com/GoblikM/claude-hollow.git"
$BRANCH$BRANCH   = "cestynak-hollow"
$DEST     = Join-Path (Get-Location) "claude-hollow"

Write-Host "Cloning Claude Hollow into $DEST ..."
git clone --branch $BRANCH $REPO_URL $DEST
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: git clone failed. Make sure git is installed and you have internet access."
    exit 1
}

$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
$paths = $currentPath -split ";"
if ($paths -contains $DEST) {
    Write-Host "Already in PATH."
} else {
    [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$DEST", "User")
    Write-Host "Added to PATH."
}

Write-Host ""
Write-Host "Installed: claude-hollow"
Write-Host "Restart your terminal and type: claude-hollow"
