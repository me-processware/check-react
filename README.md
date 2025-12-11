# React Vulnerability Scanner

A multi-platform utility to detect and automatically update vulnerable React versions (19.0.0, 19.1.0-1, 19.2.0) across your projects.

**Author:** Processware  
**License:** MIT  
**Version:** 1.0.0

---

## ⚠️ CRITICAL DISCLAIMER

**USE THIS SCRIPT AT YOUR OWN RISK**

The authors of this script are **NOT responsible** for:
- Data loss or corruption
- Broken dependencies or build failures
- Unexpected behavior in your projects
- Any damage caused by running this script

**Before using this script:**
1. ✅ **Backup all your project files** - This is mandatory
2. ✅ **Test in a non-production environment first**
3. ✅ **Review the script code** - Understand what it does
4. ✅ **Have a rollback plan** - Know how to revert changes

**This script modifies your `package.json` files. Mistakes can break your projects.**

---

## Overview

This tool scans your system for React projects with vulnerable versions and offers to update them automatically. It supports:

- **Windows** - PowerShell script
- **macOS** - Bash script
- **Linux** - Bash script
- **Node.js environments** - JavaScript version

### Detected Vulnerabilities

The scanner detects the following vulnerable React versions:

| Version | Vulnerability | Update To |
|---------|---|---|
| 19.0.0 | Server Component Security Issue | 19.0.1 |
| 19.1.0 | Dependency Injection Flaw | 19.1.2 |
| 19.1.1 | Dependency Injection Flaw | 19.1.2 |
| 19.2.0 | State Management Bug | 19.2.1 |

---

## Installation

### Option 1: Clone the Repository

```bash
git clone https://github.com/processware/check-react.git
cd check-react
```

### Option 2: Download Individual Scripts

Download the script for your platform:
- **Windows:** `check_react.ps1`
- **macOS/Linux:** `check_react.sh`
- **Node.js:** `check_react.js`

---

## Usage

### Windows (PowerShell)

#### Basic Usage
```powershell
# Run with user confirmation for each update
.\check_react.ps1
```

#### Dry-Run Mode (Preview Changes)
```powershell
# See what would be updated without making changes
.\check_react.ps1 -DryRun
```

**Requirements:**
- PowerShell 5.1 or later
- npm or yarn installed
- Read access to your home directory

**Execution Policy:**
If you get an execution policy error, run:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

### macOS / Linux (Bash)

#### Basic Usage
```bash
# Make script executable
chmod +x check_react.sh

# Run with user confirmation for each update
./check_react.sh
```

#### Dry-Run Mode (Preview Changes)
```bash
./check_react.sh --dry-run
```

**Requirements:**
- Bash 4.0 or later
- npm or yarn installed
- Read access to your home directory

---

### Node.js (JavaScript)

#### Basic Usage
```bash
# Install dependencies (if not already installed)
npm install

# Run with user confirmation for each update
node check_react.js
```

#### Dry-Run Mode (Preview Changes)
```bash
node check_react.js --dry-run
```

**Requirements:**
- Node.js 14 or later
- npm or yarn installed

---

## Features

### ✅ What This Script Does

- **Scans recursively** through your project directories
- **Detects vulnerable React versions** automatically
- **Shows clear warnings** with color-coded output
- **Creates backups** before making changes (improved version)
- **Supports multiple package managers** (npm and yarn)
- **Asks for confirmation** before updating each project
- **Provides detailed logging** of what was changed

### ❌ What This Script Does NOT Do

- Does NOT require root/admin privileges (improved version)
- Does NOT modify system files
- Does NOT install additional dependencies
- Does NOT change other packages (only React and React-DOM)
- Does NOT work offline (requires npm registry access)

---

## How It Works

### Step 1: Scanning
The script searches your home directory for `package.json` files:
- **Depth limit:** 5 levels (prevents excessive scanning)
- **Excludes:** `node_modules`, `.git`, `dist`, `build`, `.next`, `.cache`
- **Skips:** Symlinks (prevents infinite loops)

### Step 2: Detection
For each `package.json` found:
1. Reads the file and parses JSON
2. Checks `dependencies.react` and `devDependencies.react`
3. Compares version against known vulnerabilities
4. Reports any matches with recommended update version

### Step 3: User Confirmation
For each vulnerable project found:
1. Displays project location
2. Shows current and recommended versions
3. Asks user for confirmation (y/n)
4. Only proceeds if user confirms

### Step 4: Update
When user confirms:
1. Creates backup of `package.json` (with timestamp)
2. Runs `npm install` or `yarn add` with the new version
3. Reports success or failure
4. Continues to next project

### Step 5: Summary
Shows final report:
- Total vulnerable versions found
- Total projects updated
- Any failures encountered

---

## Security Considerations

### Version 1.0.0 Improvements

✅ **Input Validation**
- All version strings are validated against regex pattern
- Prevents command injection attacks
- Rejects malformed version strings

✅ **Privilege Management**
- No `sudo` or elevated privileges required
- Only scans user's home directory
- Cannot access system files

✅ **Safe File Operations**
- Uses `lstat()` to detect and skip symlinks
- Prevents infinite loops on circular symlinks
- Limits recursion depth to 5 levels
- Skips common directories (node_modules, etc.)

✅ **Backup Creation**
- Automatically creates timestamped backups
- Stores backups alongside original files
- Allows manual rollback if needed

✅ **Error Handling**
- Graceful handling of permission denied errors
- Continues processing even if one project fails
- Detailed error messages for debugging

### Known Limitations

⚠️ **Dependency Conflicts**
- Script does NOT resolve dependency conflicts
- If update fails, you may need manual intervention
- Test thoroughly before production use

⚠️ **Monorepo Support**
- Works with monorepos but updates each package separately
- May not handle workspaces optimally
- Consider using `--dry-run` first

⚠️ **Version Pinning**
- Script respects existing version specifiers (^, ~)
- May not update if version is pinned with exact version
- Manually edit package.json if needed

---

## Troubleshooting

### Script Won't Run

**Windows PowerShell:**
```powershell
# Check execution policy
Get-ExecutionPolicy

# Set to allow scripts
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Linux/macOS:**
```bash
# Make script executable
chmod +x check_react.sh

# Run with explicit bash
bash check_react.sh
```

### npm Install Fails

**Common causes:**
- Outdated npm version → Update: `npm install -g npm@latest`
- Network issues → Check internet connection
- Dependency conflicts → Review error messages
- Disk space → Ensure sufficient disk space

**Solution:**
1. Run with `--dry-run` to see what would happen
2. Navigate to project directory manually
3. Run `npm install react@VERSION --save` directly
4. Review error messages for specific issues

### Permission Denied Errors

**Linux/macOS:**
```bash
# Check file permissions
ls -la package.json

# Fix permissions if needed
chmod 644 package.json
```

**Windows:**
- Right-click PowerShell → Run as Administrator
- Or check folder permissions in Properties

### No Vulnerable Projects Found

This is **good news**! It means:
- ✅ Your React versions are up-to-date
- ✅ No known vulnerabilities detected
- ✅ Your projects are secure (for these specific CVEs)

---

## Examples

### Example 1: Basic Scan

```bash
$ ./check_react.sh
🔍 React Server Components Vulnerability Scanner
[DRY-RUN MODE] - No changes will be made

=== React Server Components Vulnerability Check ===

Scanning from: /Users/username

⚠️  VULNERABLE: React 19.0.0
   📁 Location: /Users/username/projects/myapp
   📦 Update to: 19.0.1

=== Update Vulnerable Projects ===

Project 1/1: /Users/username/projects/myapp
   Update? (y/n): y

📦 Updating React to 19.0.1...
   📁 In: /Users/username/projects/myapp
   Using npm...
   ✅ Successfully updated!

=== Results ===
⚠️  1 vulnerable version(s) found
✅ 1 project(s) updated
```

### Example 2: Dry-Run Mode

```powershell
PS> .\check_react.ps1 -DryRun
🔍 React Server Components Vulnerability Scanner
[DRY-RUN MODE] - No changes will be made

=== React Server Components Vulnerability Check ===

Scanning from: C:\Users\username

⚠️  VULNERABLE: React 19.1.0
   Location: C:\Users\username\projects\webapp
   Update to: 19.1.2

=== Update Vulnerable Projects ===

Project 1/1: C:\Users\username\projects\webapp
   Update? (y/n): y

📦 Updating React to 19.1.2...
   In: C:\Users\username\projects\webapp
   [DRY-RUN] Would execute: npm install react@19.1.2 react-dom@19.1.2 --save --legacy-peer-deps

=== Results ===
⚠️  1 vulnerable version(s) found
✅ 0 project(s) updated
```

### Example 3: No Vulnerabilities

```bash
$ ./check_react.sh
🔍 React Server Components Vulnerability Scanner

=== React Server Components Vulnerability Check ===

Scanning from: /home/user

=== Results ===
✅ No vulnerable versions found!
```

---

## Advanced Usage

### Backup Recovery

If an update breaks something, restore from backup:

```bash
# List available backups
ls -la package.json.backup.*

# Restore specific backup
cp package.json.backup.20250101_120000 package.json

# Reinstall dependencies
npm install
```

### Manual Update

If the script fails, update manually:

```bash
cd /path/to/project
npm install react@19.0.1 react-dom@19.0.1 --save
```

### Batch Processing

To update multiple projects without confirmation:

```bash
# Create a wrapper script
for dir in /path/to/projects/*/; do
    cd "$dir"
    npm install react@19.0.1 react-dom@19.0.1 --save
done
```

---

## Contributing

Found a bug? Have a suggestion? Please open an issue on GitHub:
https://github.com/processware/check-react/issues

### Security Issues

If you discover a security vulnerability in this script, please email security@processware.com instead of using the issue tracker.

---

## Changelog

### Version 1.0.0 (2025-01-11)
- ✅ Initial release
- ✅ Support for Windows, macOS, Linux
- ✅ JavaScript, PowerShell, and Bash versions
- ✅ Input validation and command injection prevention
- ✅ Backup creation before updates
- ✅ Dry-run mode for safe testing
- ✅ Comprehensive error handling

---

## License

MIT License - See LICENSE file for details

---

## Support

For questions or issues:
1. Check the [Troubleshooting](#troubleshooting) section
2. Review the [Examples](#examples) section
3. Open an issue on GitHub
4. Contact: support@processware.com

---

## Disclaimer (Again)

**This script is provided AS-IS without any warranty.** By using this script, you acknowledge that:

1. You have read and understood this entire README
2. You have backed up your project files
3. You understand the risks involved
4. You take full responsibility for any consequences
5. The authors are not liable for any damage

**Use responsibly. Test thoroughly. Backup always.**

---

**Last Updated:** January 11, 2025  
**Maintained by:** Processware
