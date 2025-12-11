#!/usr/bin/env node

// check_react.js - React CVE-2025-55182 Vulnerability Scanner
// Author: Processware
// License: MIT
// CVE: CVE-2025-55182 (CVSS 10.0 - CRITICAL)
// 
// DISCLAIMER: Use this script at your own risk. The authors are not responsible
// for any data loss or damage caused by running this script. Always backup your
// project files before running automated updates.
//
// This script requires root/admin privileges to scan system-wide directories
// (Docker containers, system services, etc.) for vulnerable React installations.

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const readline = require('readline');
const os = require('os');

const RED = '\x1b[31m';
const GREEN = '\x1b[32m';
const YELLOW = '\x1b[33m';
const BLUE = '\x1b[34m';
const CYAN = '\x1b[36m';
const NC = '\x1b[0m';

const MAX_DEPTH = 10;
const TIMEOUT_MS = 60000;

let vulnerableFound = 0;
let projectsUpdated = 0;
let dryRun = false;

// Parse command line arguments
if (process.argv.includes('--dry-run')) {
    dryRun = true;
}

if (process.argv.includes('--help') || process.argv.includes('-h')) {
    console.log('React CVE-2025-55182 Vulnerability Scanner');
    console.log('');
    console.log('Usage: node check_react.js [OPTIONS]');
    console.log('       (or with sudo for system-wide scan)');
    console.log('');
    console.log('Options:');
    console.log('  --dry-run    Preview changes without making modifications');
    console.log('  --help, -h   Show this help message');
    console.log('');
    console.log('This script scans system-wide for vulnerable React installations.');
    console.log('Requires root/admin privileges for full system access.');
    process.exit(0);
}

// Check if running with elevated privileges (Unix-like systems)
function isRoot() {
    if (process.platform === 'win32') {
        // On Windows, we'll skip the check and let the system handle permissions
        return true;
    }
    return process.getuid && process.getuid() === 0;
}

// Validate version string to prevent command injection
function isValidVersion(version) {
    if (!version || typeof version !== 'string') return false;
    return /^[\^~]?\d+\.\d+\.\d+/.test(version);
}

// Check if version is vulnerable and return safe version string
function isVulnerable(version) {
    if (!isValidVersion(version)) {
        return null;
    }
    
    const cleanVersion = version.replace(/[\^~]/, '').split('-')[0];
    const [major, minor, patch = '0'] = cleanVersion.split('.');
    
    // CVE-2025-55182: Check vulnerable React 19 versions
    if (major === '19') {
        if (minor === '0' && patch === '0') return '19.0.1';
        if (minor === '1' && (patch === '0' || patch === '1')) return '19.1.2';
        if (minor === '2' && patch === '0') return '19.2.1';
    }
    return null;
}

// Recursively find package.json files with depth limit
function findPackageFiles(startPath, currentDepth = 0) {
    let results = [];
    
    if (currentDepth > MAX_DEPTH) {
        return results;
    }
    
    try {
        const files = fs.readdirSync(startPath);
        
        files.forEach(file => {
            // Skip common directories
            if (['node_modules', '.git', '.next', 'dist', 'build', '.cache'].includes(file)) {
                return;
            }
            
            const filePath = path.join(startPath, file);
            
            try {
                const stat = fs.lstatSync(filePath);
                
                // Skip symlinks
                if (stat.isSymbolicLink()) {
                    return;
                }
                
                if (stat.isDirectory()) {
                    results = results.concat(findPackageFiles(filePath, currentDepth + 1));
                } else if (file === 'package.json') {
                    results.push(filePath);
                }
            } catch (e) {
                // Skip files we can't read
            }
        });
    } catch (e) {
        // Skip directories we can't read
    }
    
    return results;
}

// Create backup of package.json
function createBackup(filePath) {
    try {
        const timestamp = new Date().toISOString().replace(/[:.]/g, '-').split('T')[0] + '_' + 
                         new Date().toTimeString().split(' ')[0].replace(/:/g, '');
        const backupPath = `${filePath}.backup.${timestamp}`;
        fs.copyFileSync(filePath, backupPath);
        return backupPath;
    } catch (e) {
        console.log(`${YELLOW}⚠️  Could not create backup: ${e.message}${NC}`);
        return null;
    }
}

async function updateProject(dir, newVersion) {
    console.log(`\n📦 Updating React to ${newVersion}...`);
    console.log(`   📁 In: ${dir}`);
    
    if (dryRun) {
        console.log(`${BLUE}   [DRY-RUN] Would execute: npm install react@${newVersion} react-dom@${newVersion} --save --legacy-peer-deps${NC}`);
        return true;
    }
    
    try {
        // Create backup before updating
        const packageJsonPath = path.join(dir, 'package.json');
        const backup = createBackup(packageJsonPath);
        if (backup) {
            console.log(`   💾 Backup created: ${path.basename(backup)}`);
        }
        
        // Validate version string one more time
        if (!isValidVersion(newVersion)) {
            throw new Error(`Invalid version string: ${newVersion}`);
        }
        
        const cmd = `npm install react@${newVersion} react-dom@${newVersion} --save --legacy-peer-deps`;
        execSync(cmd, { cwd: dir, stdio: 'pipe', timeout: TIMEOUT_MS });
        console.log(`${GREEN}   ✅ Successfully updated!${NC}`);
        projectsUpdated++;
        return true;
    } catch (e) {
        console.log(`${RED}   ❌ Update failed: ${e.message}${NC}`);
        return false;
    }
}

async function main() {
    console.log(`${CYAN}╔════════════════════════════════════════════════════════════╗${NC}`);
    console.log(`${CYAN}║  React CVE-2025-55182 Vulnerability Scanner (React2Shell)  ║${NC}`);
    console.log(`${CYAN}╚════════════════════════════════════════════════════════════╝${NC}`);
    console.log('');
    
    if (dryRun) {
        console.log(`${BLUE}[DRY-RUN MODE] - No changes will be made${NC}`);
        console.log('');
    }
    
    // Check for root privileges
    if (!isRoot() && !dryRun && process.platform !== 'win32') {
        console.log(`${RED}This script requires root privileges to scan system-wide directories.${NC}`);
        console.log(`${YELLOW}Run with: sudo node check_react.js${NC}`);
        console.log(`${BLUE}Or use --dry-run to test without sudo: node check_react.js --dry-run${NC}`);
        process.exit(1);
    }
    
    console.log(`${YELLOW}⚠️  CVE-2025-55182: CRITICAL (CVSS 10.0)${NC}`);
    console.log('Unauthenticated Remote Code Execution in React Server Components');
    console.log('Actively exploited in the wild - Immediate patching required');
    console.log('');
    
    console.log('=== Scanning System for Vulnerable React Installations ===');
    console.log('');
    console.log('Scanning directories:');
    console.log('  • User home directories');
    console.log('  • Docker containers (/var/lib/docker)');
    console.log('  • System services (/opt, /srv)');
    console.log('  • Application directories (/usr/local)');
    console.log('');
    
    const vulnDirs = [];
    const newVersions = [];
    
    // Search paths for system-wide scan
    const searchPaths = process.platform === 'win32' 
        ? ['C:\\Users', 'C:\\Program Files', 'C:\\Program Files (x86)', 'C:\\ProgramData']
        : ['/root', '/home', '/var/lib/docker', '/opt', '/srv', '/usr/local'];
    
    // Find all package.json files system-wide
    for (const searchPath of searchPaths) {
        if (!fs.existsSync(searchPath)) {
            continue;
        }
        
        console.log(`${BLUE}Scanning: ${searchPath}${NC}`);
        const packageFiles = findPackageFiles(searchPath);
        
        packageFiles.forEach(packageFile => {
            try {
                const content = JSON.parse(fs.readFileSync(packageFile, 'utf8'));
                const version = content.dependencies?.react || content.devDependencies?.react;
                
                if (version) {
                    const newVersion = isVulnerable(version);
                    
                    if (newVersion) {
                        vulnerableFound++;
                        console.log(`${RED}⚠️  VULNERABLE: React ${version}${NC}`);
                        console.log(`   📁 Location: ${path.dirname(packageFile)}`);
                        console.log(`   🔒 CVE-2025-55182: Remote Code Execution`);
                        console.log(`   📦 Update to: ${newVersion}`);
                        
                        vulnDirs.push(path.dirname(packageFile));
                        newVersions.push(newVersion);
                        console.log('');
                    }
                }
            } catch (e) {
                // Skip invalid files
            }
        });
    }
    
    // Update loop
    if (vulnerableFound > 0) {
        console.log('');
        console.log(`${RED}═══════════════════════════════════════════════════════════${NC}`);
        console.log(`${RED}  CRITICAL: ${vulnerableFound} Vulnerable Installation(s) Found${NC}`);
        console.log(`${RED}═══════════════════════════════════════════════════════════${NC}`);
        console.log('');
        console.log('These installations are vulnerable to CVE-2025-55182:');
        console.log('• Unauthenticated Remote Code Execution');
        console.log('• CVSS Score: 10.0 (CRITICAL)');
        console.log('• Actively exploited in the wild');
        console.log('');
        console.log('=== Update Vulnerable Projects ===');
        console.log('');
        
        const rl = readline.createInterface({
            input: process.stdin,
            output: process.stdout
        });
        
        for (let i = 0; i < vulnDirs.length; i++) {
            const dir = vulnDirs[i];
            const version = newVersions[i];
            
            console.log(`${YELLOW}Project ${i+1}/${vulnDirs.length}: ${dir}${NC}`);
            
            await new Promise(resolve => {
                rl.question(`   Update to React ${version}? (y/n): `, async (answer) => {
                    if (answer.toLowerCase() === 'y' || answer.toLowerCase() === 'yes') {
                        await updateProject(dir, version);
                    } else {
                        console.log('   ⏭️  Skipped');
                    }
                    console.log('');
                    resolve();
                });
            });
        }
        
        rl.close();
    }
    
    // Summary
    console.log('');
    console.log('═══════════════════════════════════════════════════════════');
    console.log('                         SUMMARY');
    console.log('═══════════════════════════════════════════════════════════');
    if (vulnerableFound === 0) {
        console.log(`${GREEN}✅ No vulnerable versions found!${NC}`);
        console.log('Your system is protected against CVE-2025-55182');
    } else {
        console.log(`${RED}⚠️  ${vulnerableFound} vulnerable installation(s) found${NC}`);
        console.log(`${GREEN}✅ ${projectsUpdated} project(s) updated${NC}`);
        
        if (projectsUpdated < vulnerableFound) {
            console.log(`${YELLOW}⚠️  ${vulnerableFound - projectsUpdated} project(s) remain vulnerable${NC}`);
            console.log('');
            console.log('IMMEDIATE ACTION REQUIRED:');
            console.log('• Update remaining projects manually');
            console.log('• Review security logs for exploitation attempts');
            console.log('• Consider temporary mitigations (WAF rules, network isolation)');
        }
    }
    console.log('═══════════════════════════════════════════════════════════');
    console.log('');
}

main().catch(console.error);
