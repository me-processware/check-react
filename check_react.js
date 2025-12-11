#!/usr/bin/env node
// check_react.js - React Vulnerability Scanner
// Author: Processware
// License: MIT
// 
// DISCLAIMER: Use this script at your own risk. The authors are not responsible
// for any data loss or damage caused by running this script. Always backup your
// project files before running automated updates.

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const readline = require('readline');

const RED = '\x1b[31m';
const GREEN = '\x1b[32m';
const YELLOW = '\x1b[33m';
const BLUE = '\x1b[34m';
const NC = '\x1b[0m';

const MAX_DEPTH = 5;
const TIMEOUT_MS = 30000;

let vulnerableFound = 0;
let projectsUpdated = 0;

// Validate version string to prevent command injection
function isValidVersion(version) {
    if (!version || typeof version !== 'string') return false;
    // Allow semantic versioning with optional ^ or ~ prefix
    return /^[\^~]?\d+\.\d+\.\d+/.test(version);
}

// Check if version is vulnerable and return safe version string
function isVulnerable(version) {
    if (!isValidVersion(version)) {
        return null;
    }
    
    const cleanVersion = version.replace(/[\^~]/, '').split('-')[0];
    const [major, minor, patch = '0'] = cleanVersion.split('.');
    
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
            // Skip common directories that shouldn't be searched
            if (['node_modules', '.git', '.next', 'dist', 'build', '.cache'].includes(file)) {
                return;
            }
            
            const filePath = path.join(startPath, file);
            
            try {
                const stat = fs.lstatSync(filePath); // Use lstat to detect symlinks
                
                // Skip symlinks to prevent loops
                if (stat.isSymbolicLink()) {
                    return;
                }
                
                if (stat.isDirectory()) {
                    results = results.concat(findPackageFiles(filePath, currentDepth + 1));
                } else if (file === 'package.json') {
                    results.push(filePath);
                }
            } catch (e) {
                // Skip files we can't read (permission denied, etc.)
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
        const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
        const backupPath = `${filePath}.backup.${timestamp}`;
        fs.copyFileSync(filePath, backupPath);
        return backupPath;
    } catch (e) {
        console.log(`${YELLOW}⚠️  Could not create backup: ${e.message}${NC}`);
        return null;
    }
}

async function updateProject(dir, newVersion, dryRun = false) {
    console.log(`\n📦 Updating React to ${newVersion}...`);
    console.log(`   📁 In: ${dir}`);
    
    if (dryRun) {
        console.log(`${BLUE}[DRY-RUN] Would execute: npm install react@${newVersion} react-dom@${newVersion} --save --legacy-peer-deps${NC}`);
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
        execSync(cmd, { cwd: dir, stdio: 'inherit', timeout: TIMEOUT_MS });
        console.log(`${GREEN}✅ Successfully updated!${NC}`);
        projectsUpdated++;
        return true;
    } catch (e) {
        console.log(`${RED}❌ Update failed: ${e.message}${NC}`);
        return false;
    }
}

async function main() {
    const args = process.argv.slice(2);
    const dryRun = args.includes('--dry-run');
    
    console.log(`${BLUE}🔍 React Server Components Vulnerability Scanner${NC}`);
    if (dryRun) {
        console.log(`${BLUE}[DRY-RUN MODE] - No changes will be made${NC}`);
    }
    console.log('');
    console.log('=== React Server Components Vulnerability Check ===');
    console.log('');
    
    const vulnDirs = [];
    const newVersions = [];
    
    // Search from home directory
    const startPath = process.env.USERPROFILE || process.env.HOME;
    console.log(`Scanning from: ${startPath}`);
    console.log('');
    
    const packageFiles = findPackageFiles(startPath);
    
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
    
    // Update loop
    if (vulnerableFound > 0) {
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
                rl.question('   Update? (y/n): ', async (answer) => {
                    if (answer.toLowerCase() === 'y' || answer.toLowerCase() === 'yes') {
                        await updateProject(dir, version, dryRun);
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
    console.log('=== Results ===');
    if (vulnerableFound === 0) {
        console.log(`${GREEN}✅ No vulnerable versions found!${NC}`);
    } else {
        console.log(`${RED}⚠️  ${vulnerableFound} vulnerable version(s) found${NC}`);
        console.log(`${GREEN}✅ ${projectsUpdated} project(s) updated${NC}`);
    }
    console.log('');
}

main().catch(console.error);
