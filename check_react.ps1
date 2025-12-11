# check_react.ps1 - React CVE-2025-55182 Vulnerability Scanner
# Author: Processware
# License: MIT
# CVE: CVE-2025-55182 (CVSS 10.0 - CRITICAL)
#
# DISCLAIMER: Use this script at your own risk. The authors are not responsible
# for any data loss or damage caused by running this script. Always backup your
# project files before running automated updates.
#
# This script requires administrator privileges to scan system-wide directories
# (Docker containers, system services, etc.) for vulnerable React installations.

param(
    [switch]$DryRun = $false,
    [switch]$Help = $false
)

if ($Help) {
    Write-Host "React CVE-2025-55182 Vulnerability Scanner"
    Write-Host ""
    Write-Host "Usage: .\check_react.ps1 [OPTIONS]"
    Write-Host "       (Run as Administrator for system-wide scan)"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -DryRun      Preview changes without making modifications"
    Write-Host "  -Help        Show this help message"
    Write-Host ""
    Write-Host "This script scans system-wide for vulnerable React installations."
    Write-Host "Requires administrator privileges for full system access."
    exit 0
}

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin -and -not $DryRun) {
    Write-Host "This script requires administrator privileges to scan system-wide directories." -ForegroundColor Red
    Write-Host "Run PowerShell as Administrator and try again." -ForegroundColor Yellow
    Write-Host "Or use -DryRun to test without admin: .\check_react.ps1 -DryRun" -ForegroundColor Cyan
    exit 1
}

$VULNERABLE_FOUND = 0
$PROJECTS_UPDATED = 0
$MAX_DEPTH = 10

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  React CVE-2025-55182 Vulnerability Scanner (React2Shell)  ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

if ($DryRun) {
    Write-Host "[DRY-RUN MODE] - No changes will be made" -ForegroundColor Cyan
    Write-Host ""
}

Write-Host "⚠️  CVE-2025-55182: CRITICAL (CVSS 10.0)" -ForegroundColor Yellow
Write-Host "Unauthenticated Remote Code Execution in React Server Components"
Write-Host "Actively exploited in the wild - Immediate patching required"
Write-Host ""

# Validate version string to prevent command injection
function Test-ValidVersion {
    param([string]$version)
    
    if ([string]::IsNullOrEmpty($version)) {
        return $false
    }
    
    return $version -match '^\^?~?\d+\.\d+\.\d+'
}

# Test if version is vulnerable
function Test-Vulnerable {
    param([string]$version)
    
    if (-not (Test-ValidVersion $version)) {
        return $null
    }
    
    # Remove ^ or ~ prefixes and pre-release tags
    $cleanVersion = $version -replace '[\^~]', '' -split '-' | Select-Object -First 1
    
    # Parse version
    $parts = $cleanVersion -split '\.'
    $major = $parts[0]
    $minor = $parts[1]
    $patch = [int]($parts[2] -as [int])
    
    # CVE-2025-55182: Check vulnerable React 19 versions
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
        Write-Host "   ⚠️  Could not create backup: $_" -ForegroundColor Yellow
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
        npm install "react@$newVersion" "react-dom@$newVersion" --save --legacy-peer-deps 2>&1 | Out-Null
        $success = $LASTEXITCODE -eq 0
    }
    elseif (Test-Path "yarn.lock") {
        Write-Host "   Using yarn..."
        yarn add "react@$newVersion" "react-dom@$newVersion" 2>&1 | Out-Null
        $success = $LASTEXITCODE -eq 0
    }
    else {
        Write-Host "   Using npm (default)..."
        npm install "react@$newVersion" "react-dom@$newVersion" --save --legacy-peer-deps 2>&1 | Out-Null
        $success = $LASTEXITCODE -eq 0
    }
    
    if ($success) {
        Write-Host "   ✅ Successfully updated!" -ForegroundColor Green
        $global:PROJECTS_UPDATED++
    }
    else {
        Write-Host "   ❌ Update failed!" -ForegroundColor Red
    }
    
    Pop-Location
    return $success
}

# Main
Write-Host "=== Scanning System for Vulnerable React Installations ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Scanning directories:"
Write-Host "  • User directories (C:\Users)"
Write-Host "  • Program Files"
Write-Host "  • Application data directories"
Write-Host ""

$vulnDirs = @()
$newVersions = @()

# Search paths for system-wide scan
$searchPaths = @(
    "C:\Users",
    "C:\Program Files",
    "C:\Program Files (x86)",
    "C:\ProgramData"
)

# Find all package.json files system-wide
foreach ($searchPath in $searchPaths) {
    if (-not (Test-Path $searchPath)) {
        continue
    }
    
    Write-Host "Scanning: $searchPath" -ForegroundColor Blue
    
    $packageFiles = Get-ChildItem -Path $searchPath -Filter "package.json" -Recurse -ErrorAction SilentlyContinue -Depth $MAX_DEPTH | 
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
                    Write-Host "   🔒 CVE-2025-55182: Remote Code Execution"
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
}

# Update vulnerable projects
if ($VULNERABLE_FOUND -gt 0) {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Red
    Write-Host "  CRITICAL: $VULNERABLE_FOUND Vulnerable Installation(s) Found" -ForegroundColor Red
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Red
    Write-Host ""
    Write-Host "These installations are vulnerable to CVE-2025-55182:"
    Write-Host "• Unauthenticated Remote Code Execution"
    Write-Host "• CVSS Score: 10.0 (CRITICAL)"
    Write-Host "• Actively exploited in the wild"
    Write-Host ""
    Write-Host "=== Update Vulnerable Projects ===" -ForegroundColor Cyan
    Write-Host ""
    
    for ($i = 0; $i -lt $vulnDirs.Count; $i++) {
        $dir = $vulnDirs[$i]
        $version = $newVersions[$i]
        
        Write-Host "Project $($i+1)/$($vulnDirs.Count): $dir" -ForegroundColor Yellow
        
        $response = Read-Host "   Update to React $version? (y/n)"
        
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
Write-Host "═══════════════════════════════════════════════════════════"
Write-Host "                         SUMMARY"
Write-Host "═══════════════════════════════════════════════════════════"
if ($VULNERABLE_FOUND -eq 0) {
    Write-Host "✅ No vulnerable versions found!" -ForegroundColor Green
    Write-Host "Your system is protected against CVE-2025-55182"
}
else {
    Write-Host "⚠️  $VULNERABLE_FOUND vulnerable installation(s) found" -ForegroundColor Red
    Write-Host "✅ $PROJECTS_UPDATED project(s) updated" -ForegroundColor Green
    
    if ($PROJECTS_UPDATED -lt $VULNERABLE_FOUND) {
        Write-Host "⚠️  $($VULNERABLE_FOUND - $PROJECTS_UPDATED) project(s) remain vulnerable" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "IMMEDIATE ACTION REQUIRED:"
        Write-Host "• Update remaining projects manually"
        Write-Host "• Review security logs for exploitation attempts"
        Write-Host "• Consider temporary mitigations (WAF rules, network isolation)"
    }
}
Write-Host "═══════════════════════════════════════════════════════════"
Write-Host ""
