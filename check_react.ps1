# check_react.ps1 - React Vulnerability Scanner
# Author: Processware
# License: MIT
#
# DISCLAIMER: Use this script at your own risk. The authors are not responsible
# for any data loss or damage caused by running this script. Always backup your
# project files before running automated updates.

param(
    [switch]$DryRun = $false
)

# Color definitions - with fallback for older PowerShell versions
$RED = "`e[31m"
$GREEN = "`e[32m"
$YELLOW = "`e[33m"
$BLUE = "`e[34m"
$NC = "`e[0m"

$VULNERABLE_FOUND = 0
$PROJECTS_UPDATED = 0
$MAX_DEPTH = 5

# Validate version string to prevent command injection
function Test-ValidVersion {
    param([string]$version)
    
    if ([string]::IsNullOrEmpty($version)) {
        return $false
    }
    
    # Check if version matches semantic versioning pattern
    return $version -match '^\^?~?\d+\.\d+\.\d+'
}

# Test if version is vulnerable
function Test-Vulnerable {
    param([string]$version)
    
    # Validate version string first
    if (-not (Test-ValidVersion $version)) {
        return $null
    }
    
    # Verwijder ^ of ~ voorvoegsels
    $cleanVersion = $version -replace '[\^~]', '' -split '-' | Select-Object -First 1
    
    # Parse versie
    $parts = $cleanVersion -split '\.'
    $major = $parts[0]
    $minor = $parts[1]
    $patch = [int]($parts[2] -as [int])
    
    if ($major -eq "19") {
        if ($minor -eq "0" -and $patch -eq 0) {
            return "19.0.1"
        }
        elseif ($minor -eq "1" -and ($patch -eq 0 -or $patch -eq 1)) {
            return "19.1.2"
        }
        elseif ($minor -eq "2" -and $patch -eq 0) {
            return "19.2.1"
        }
    }
    
    return $null
}

# Create backup of package.json
function New-Backup {
    param([string]$filePath)
    
    try {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $backupPath = "$filePath.backup.$timestamp"
        Copy-Item -Path $filePath -Destination $backupPath -ErrorAction Stop
        return $backupPath
    }
    catch {
        Write-Host "⚠️  Could not create backup: $_" -ForegroundColor Yellow
        return $null
    }
}

# Update project
function Update-Project {
    param([string]$dir, [string]$newVersion)
    
    Push-Location $dir
    
    Write-Host ""
    Write-Host "📦 Updating React to $newVersion..." -ForegroundColor Yellow
    Write-Host "   In: $dir"
    
    if ($DryRun) {
        Write-Host "   [DRY-RUN] Would execute: npm install react@$newVersion react-dom@$newVersion --save --legacy-peer-deps" -ForegroundColor Cyan
        Pop-Location
        return $true
    }
    
    # Validate version one more time
    if (-not (Test-ValidVersion $newVersion)) {
        Write-Host "   ❌ Invalid version string: $newVersion" -ForegroundColor Red
        Pop-Location
        return $false
    }
    
    # Create backup
    $backup = New-Backup "package.json"
    if ($backup) {
        Write-Host "   💾 Backup created: $(Split-Path -Leaf $backup)"
    }
    
    $success = $false
    
    if (Test-Path "package-lock.json") {
        Write-Host "   Using npm..."
        npm install "react@$newVersion" "react-dom@$newVersion" --save --legacy-peer-deps
        $success = $LASTEXITCODE -eq 0
    }
    elseif (Test-Path "yarn.lock") {
        Write-Host "   Using yarn..."
        yarn add "react@$newVersion" "react-dom@$newVersion"
        $success = $LASTEXITCODE -eq 0
    }
    else {
        Write-Host "   Using npm (default)..."
        npm install "react@$newVersion" "react-dom@$newVersion" --save --legacy-peer-deps
        $success = $LASTEXITCODE -eq 0
    }
    
    if ($success) {
        Write-Host "✅ Successfully updated!" -ForegroundColor Green
        $global:PROJECTS_UPDATED++
    }
    else {
        Write-Host "❌ Update failed!" -ForegroundColor Red
    }
    
    Pop-Location
    return $success
}

# Main
Write-Host "🔍 React Server Components Vulnerability Scanner" -ForegroundColor Cyan
if ($DryRun) {
    Write-Host "[DRY-RUN MODE] - No changes will be made" -ForegroundColor Cyan
}
Write-Host ""
Write-Host "=== React Server Components Vulnerability Check ===" -ForegroundColor Cyan
Write-Host ""

$vulnDirs = @()
$newVersions = @()

# Zoek package.json files - only in user home directory
Write-Host "Scanning from: $env:USERPROFILE"
Write-Host ""

# Get all package.json files from home directory with depth limit
$packageFiles = Get-ChildItem -Path $env:USERPROFILE -Filter "package.json" -Recurse -ErrorAction SilentlyContinue -Depth $MAX_DEPTH | 
    Where-Object { $_.FullName -notmatch "node_modules" }

foreach ($file in $packageFiles) {
    try {
        $content = Get-Content $file.FullName -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue
        
        # Get React version from dependencies or devDependencies
        $version = $null
        if ($content.dependencies.react) {
            $version = $content.dependencies.react
        }
        elseif ($content.devDependencies.react) {
            $version = $content.devDependencies.react
        }
        
        if ($version) {
            $newVersion = Test-Vulnerable $version
            
            if ($newVersion) {
                $VULNERABLE_FOUND++
                Write-Host "⚠️  VULNERABLE: React $version" -ForegroundColor Red
                Write-Host "   Location: $($file.Directory.FullName)"
                Write-Host "   Update to: $newVersion"
                
                $vulnDirs += $file.Directory.FullName
                $newVersions += $newVersion
                Write-Host ""
            }
        }
    }
    catch {
        # Skip invalid files
    }
}

# Update vragen
if ($VULNERABLE_FOUND -gt 0) {
    Write-Host ""
    Write-Host "=== Update Vulnerable Projects ===" -ForegroundColor Cyan
    Write-Host ""
    
    for ($i = 0; $i -lt $vulnDirs.Count; $i++) {
        $dir = $vulnDirs[$i]
        $version = $newVersions[$i]
        
        Write-Host "Project $($i+1)/$($vulnDirs.Count): $dir" -ForegroundColor Yellow
        
        $response = Read-Host "   Update? (y/n)"
        
        if ($response -match '^[yY]') {
            Update-Project $dir $version
        }
        else {
            Write-Host "   Skipped"
        }
        Write-Host ""
    }
}

# Summary
Write-Host ""
Write-Host "=== Results ===" -ForegroundColor Cyan
if ($VULNERABLE_FOUND -eq 0) {
    Write-Host "✅ No vulnerable versions found!" -ForegroundColor Green
}
else {
    Write-Host "⚠️  $VULNERABLE_FOUND vulnerable version(s) found" -ForegroundColor Red
    Write-Host "✅ $PROJECTS_UPDATED project(s) updated" -ForegroundColor Green
}
Write-Host ""
