<#
.SYNOPSIS
Syncs the staging branch to main while removing all agentic coding files.
#>

$ErrorActionPreference = "Stop"

# List of files and directories to hide from main
$agentFiles = @(
    ".agents",
    "AGENTS.md",
    "skills-lock.json",
    "sync-to-main.ps1"
)

# 1. Check for a clean working directory
if (git status --porcelain) {
    Write-Host "Error: Your working directory is not clean." -ForegroundColor Red
    Write-Host "Please commit or stash your changes on staging before running this script." -ForegroundColor Yellow
    exit 1
}

# 2. Ensure we are on staging
$currentBranch = (git branch --show-current).Trim()
if ($currentBranch -ne "staging") {
    Write-Host "Error: You must be on the 'staging' branch to run this script." -ForegroundColor Red
    exit 1
}

Write-Host "Starting sync process..." -ForegroundColor Cyan

# 3. Check if main branch exists locally or remotely
$localMainExists = [bool](git branch --list main)
$remoteMainExists = [bool](git branch -r --list origin/main)

if (-not $localMainExists) {
    if ($remoteMainExists) {
        Write-Host "Tracking remote origin/main..."
        git checkout -b main origin/main
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Error: Failed to checkout main from origin/main." -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "Branch 'main' does not exist yet. Initializing 'main' from 'staging'..."
        git checkout -b main staging
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Error: Failed to create main branch." -ForegroundColor Red
            exit 1
        }

        Write-Host "Stripping agentic files for initial main commit..."
        foreach ($file in $agentFiles) {
            if (Test-Path $file) {
                git rm -rfq $file
                Remove-Item -Recurse -Force $file -ErrorAction SilentlyContinue
            }
        }

        git commit -m "chore: initial sanitized main branch"
        git checkout staging
        Write-Host "Initial 'main' branch successfully created and sanitized!" -ForegroundColor Green
        exit 0
    }
} else {
    git checkout main
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to switch to 'main' branch." -ForegroundColor Red
        exit 1
    }
}

# 4. Initiate a merge from staging using the 'ours' strategy to avoid conflicts
Write-Host "Merging changes from staging..."
$mergeOutput = git merge staging -s ours --no-commit 2>&1

if ($mergeOutput -match "Already up to date") {
    Write-Host "Main is already perfectly in sync with staging. No changes needed." -ForegroundColor Green
    git checkout staging
    exit 0
}

# 5. Wipe the current index and working tree
git rm -rfq .

# 6. Copy the entire file tree from staging
git checkout staging -- .

# 7. Strip out all agent-related files
Write-Host "Stripping agentic files..."
foreach ($file in $agentFiles) {
    if (Test-Path $file) {
        git rm -rfq --cached $file
        Remove-Item -Recurse -Force $file -ErrorAction SilentlyContinue
    }
}

# 8. Add all modifications to the index
git add .

# 9. Commit the merge
Write-Host "Finalizing the sync..."
if (git status --porcelain) {
    git commit -m "chore: auto-sync staging to main (sanitized)"
}

# 10. Return to staging
git checkout staging

Write-Host "Sync successful! The main branch has been updated and sanitized." -ForegroundColor Green
