# React CVE-2025-55182 Vulnerability Scanner

**Critical Remote Code Execution vulnerability scanner and automated patcher for React Server Components**

**Author:** Processware  
**License:** MIT  
**Version:** 2.0.0  
**CVE:** CVE-2025-55182 (CVSS 10.0 - CRITICAL)

---

## ⚠️ CRITICAL SECURITY ALERT

**CVE-2025-55182** is an **unauthenticated remote code execution (RCE)** vulnerability in React Server Components with a **CVSS score of 10.0** (maximum severity).

### Immediate Threat
- ✅ **Actively exploited in the wild** by China-nexus threat groups
- ✅ **Added to CISA Known Exploited Vulnerabilities** catalog (Dec 5, 2025)
- ✅ **No authentication required** - attackers can exploit remotely
- ✅ **Full system compromise** possible through malicious HTTP requests

### Affected Versions
- React 19.0.0 → Update to 19.0.1
- React 19.1.0 → Update to 19.1.2
- React 19.1.1 → Update to 19.1.2
- React 19.2.0 → Update to 19.2.1

**If you're running any of these versions, patch immediately.**

---

## ⚠️ DISCLAIMER

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

## Why This Scanner Exists

CVE-2025-55182 allows attackers to execute arbitrary code on servers running vulnerable React versions. The vulnerability exists in React Server Components' payload deserialization logic.

**Even if your app doesn't implement React Server Function endpoints**, it may still be vulnerable if it uses React Server Components.

This scanner helps you:
- ✅ Detect vulnerable React installations system-wide
- ✅ Automatically update to patched versions
- ✅ Protect Docker containers, system services, and user projects
- ✅ Prevent exploitation of CVE-2025-55182

---

## Why Sudo/Admin Privileges Are Required

This scanner needs system-wide access to find **all** vulnerable React installations, including:

### Linux/macOS
- **Docker containers:** `/var/lib/docker/` - Containerized applications
- **System services:** `/opt/`, `/srv/` - Production deployments
- **Application directories:** `/usr/local/` - System-wide installations
- **Root projects:** `/root/` - Admin-owned projects
- **User directories:** `/home/` - All user accounts

### Windows
- **Program Files:** `C:\Program Files\`, `C:\Program Files (x86)\`
- **User directories:** `C:\Users\`
- **Application data:** `C:\ProgramData\`

**Without elevated privileges**, the scanner can only check your personal home directory, potentially missing critical vulnerable installations in production environments.

---

## Installation

### Option 1: Clone the Repository

```bash
git clone https://github.com/me-processware/check-react.git
cd check-react
```

### Option 2: Download Individual Scripts

Download the script for your platform:
- **Windows:** `check_react.ps1`
- **macOS/Linux:** `check_react.sh`
- **Node.js:** `check_react.js`

---

## Usage

### Linux/macOS (Bash)

#### System-Wide Scan (Recommended)
```bash
# Make script executable
chmod +x check_react.sh

# Run with sudo for full system scan
sudo ./check_react.sh
```

#### Dry-Run Mode (Preview Changes)
```bash
# See what would be updated without making changes (no sudo needed)
./check_react.sh --dry-run
```

#### Help
```bash
./check_react.sh --help
```

---

### Windows (PowerShell)

#### System-Wide Scan (Recommended)
```powershell
# Run PowerShell as Administrator, then:
.\check_react.ps1
```

#### Dry-Run Mode (Preview Changes)
```powershell
# No admin privileges needed for dry-run
.\check_react.ps1 -DryRun
```

#### Help
```powershell
.\check_react.ps1 -Help
```

**Note:** If you get an execution policy error:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

### Node.js (JavaScript)

#### System-Wide Scan (Recommended)
```bash
# Linux/macOS
sudo node check_react.js

# Windows (run PowerShell as Administrator)
node check_react.js
```

#### Dry-Run Mode (Preview Changes)
```bash
# No sudo/admin needed for dry-run
node check_react.js --dry-run
```

#### Help
```bash
node check_react.js --help
```

---

## Features

### ✅ What This Script Does

- **System-wide scanning** - Finds vulnerable React installations everywhere
- **CVE-2025-55182 detection** - Specifically checks for this critical vulnerability
- **Automatic updates** - Patches to safe versions with user confirmation
- **Backup creation** - Saves `package.json` before making changes
- **Dry-run mode** - Preview changes without modifying anything
- **Multiple package managers** - Supports npm and yarn
- **Input validation** - Prevents command injection attacks
- **Detailed reporting** - Shows exactly what was found and updated

### ❌ What This Script Does NOT Do

- Does NOT modify system files
- Does NOT install additional dependencies
- Does NOT change other packages (only React and React-DOM)
- Does NOT work offline (requires npm registry access)
- Does NOT guarantee 100% protection (always review security logs)

---

## How It Works

### Step 1: Privilege Check
- Verifies sudo/admin privileges for system-wide scan
- Allows dry-run mode without elevated privileges

### Step 2: System-Wide Scanning
Searches the following locations:
- **Linux/macOS:** `/root`, `/home`, `/var/lib/docker`, `/opt`, `/srv`, `/usr/local`
- **Windows:** `C:\Users`, `C:\Program Files`, `C:\Program Files (x86)`, `C:\ProgramData`

Finds all `package.json` files (excluding `node_modules`) up to 10 levels deep.

### Step 3: Vulnerability Detection
For each `package.json` found:
1. Reads and parses the file
2. Checks `dependencies.react` and `devDependencies.react`
3. Compares version against CVE-2025-55182 vulnerable versions
4. Reports matches with recommended patch version

### Step 4: User Confirmation
For each vulnerable project:
1. Displays project location and current version
2. Shows CVE details and recommended update
3. Asks user for confirmation (y/n)
4. Only proceeds if user confirms

### Step 5: Automated Patching
When user confirms:
1. Creates timestamped backup of `package.json`
2. Detects package manager (npm or yarn)
3. Runs `npm install` or `yarn add` with patched version
4. Reports success or failure
5. Continues to next project

### Step 6: Summary Report
Shows final statistics:
- Total vulnerable installations found
- Total projects successfully updated
- Remaining vulnerable projects (if any)
- Recommended actions

---

## Example Output

```bash
$ sudo ./check_react.sh
╔════════════════════════════════════════════════════════════╗
║  React CVE-2025-55182 Vulnerability Scanner (React2Shell)  ║
╚════════════════════════════════════════════════════════════╝

⚠️  CVE-2025-55182: CRITICAL (CVSS 10.0)
Unauthenticated Remote Code Execution in React Server Components
Actively exploited in the wild - Immediate patching required

=== Scanning System for Vulnerable React Installations ===

Scanning directories:
  • User home directories
  • Docker containers (/var/lib/docker)
  • System services (/opt, /srv)
  • Application directories (/usr/local)

Scanning: /home
⚠️  VULNERABLE: React 19.0.0
   📁 Location: /home/user/myapp
   🔒 CVE-2025-55182: Remote Code Execution
   📦 Update to: 19.0.1

Scanning: /var/lib/docker
⚠️  VULNERABLE: React 19.1.0
   📁 Location: /var/lib/docker/containers/abc123/app
   🔒 CVE-2025-55182: Remote Code Execution
   📦 Update to: 19.1.2

═══════════════════════════════════════════════════════════
  CRITICAL: 2 Vulnerable Installation(s) Found
═══════════════════════════════════════════════════════════

These installations are vulnerable to CVE-2025-55182:
• Unauthenticated Remote Code Execution
• CVSS Score: 10.0 (CRITICAL)
• Actively exploited in the wild

=== Update Vulnerable Projects ===

Project 1/2: /home/user/myapp
   Update to React 19.0.1? (y/n): y

📦 Updating React to 19.0.1...
   📁 In: /home/user/myapp
   💾 Backup created: package.json.backup.20251211_143022
   Using npm...
   ✅ Successfully updated!

Project 2/2: /var/lib/docker/containers/abc123/app
   Update to React 19.1.2? (y/n): y

📦 Updating React to 19.1.2...
   📁 In: /var/lib/docker/containers/abc123/app
   💾 Backup created: package.json.backup.20251211_143045
   Using npm...
   ✅ Successfully updated!

═══════════════════════════════════════════════════════════
                         SUMMARY
═══════════════════════════════════════════════════════════
⚠️  2 vulnerable installation(s) found
✅ 2 project(s) updated
Your system is now protected against CVE-2025-55182
═══════════════════════════════════════════════════════════
```

---

## Security Features

### Input Validation
- All version strings validated against regex: `^[\^~]?\d+\.\d+\.\d+`
- Prevents command injection attacks
- Rejects malformed version strings

### Safe File Operations
- Uses `lstat()` to detect and skip symlinks
- Prevents infinite loops on circular symlinks
- Limits recursion depth to 10 levels
- Skips common directories (`node_modules`, `.git`, etc.)

### Backup Creation
- Automatically creates timestamped backups
- Format: `package.json.backup.YYYYMMDD_HHMMSS`
- Stored alongside original files
- Allows manual rollback if needed

### Dry-Run Mode
- Preview all changes before applying
- No elevated privileges required
- Safe testing environment
- Shows exact commands that would be executed

---

## Troubleshooting

### "Permission Denied" Errors

**Linux/macOS:**
```bash
# Make sure you're using sudo
sudo ./check_react.sh

# Check script permissions
chmod +x check_react.sh
```

**Windows:**
```powershell
# Run PowerShell as Administrator
# Right-click PowerShell → "Run as Administrator"
```

### npm Install Fails

**Common causes:**
- Outdated npm → Update: `npm install -g npm@latest`
- Network issues → Check internet connection
- Dependency conflicts → Review error messages
- Disk space → Ensure sufficient disk space

**Solution:**
1. Run with `--dry-run` to see what would happen
2. Navigate to project directory manually
3. Run `npm install react@VERSION --save` directly
4. Review error messages for specific issues

### No Vulnerable Projects Found

This is **good news**! It means:
- ✅ Your React versions are patched
- ✅ No CVE-2025-55182 vulnerabilities detected
- ✅ Your system is protected

---

## Backup Recovery

If an update breaks something, restore from backup:

```bash
# List available backups
ls -la package.json.backup.*

# Restore specific backup
cp package.json.backup.20251211_143022 package.json

# Reinstall dependencies
npm install
```

---

## Technical Details

### CVE-2025-55182 Overview

**Type:** Unauthenticated Remote Code Execution (RCE)  
**CVSS Score:** 10.0 (CRITICAL)  
**Attack Vector:** Network  
**Attack Complexity:** Low  
**Privileges Required:** None  
**User Interaction:** None  

**Vulnerability:** Unsafe deserialization in React's Flight protocol when handling server component payloads. Attackers can craft malicious HTTP requests to any Server Function endpoint that, when deserialized by React, achieves remote code execution on the server.

**Affected Packages:**
- `react-server-dom-webpack`
- `react-server-dom-parcel`
- `react-server-dom-turbopack`

**Timeline:**
- **Nov 29, 2025:** Discovered by Lachlan Davidson
- **Dec 3, 2025:** Publicly disclosed, patches released
- **Dec 5, 2025:** Added to CISA Known Exploited Vulnerabilities
- **Ongoing:** Active exploitation by threat actors

---

## References

- **Official React Advisory:** https://react.dev/blog/2025/12/03/critical-security-vulnerability-in-react-server-components
- **NVD Entry:** https://nvd.nist.gov/vuln/detail/CVE-2025-55182
- **CISA Alert:** https://www.cisa.gov/news-events/alerts/2025/12/05/cisa-adds-one-known-exploited-vulnerability-catalog
- **Wiz Research:** https://www.wiz.io/blog/critical-vulnerability-in-react-cve-2025-55182
- **Palo Alto Unit 42:** https://unit42.paloaltonetworks.com/cve-2025-55182-react-and-cve-2025-66478-next/

---

## Contributing

Found a bug? Have a suggestion? Please open an issue on GitHub:
https://github.com/me-processware/check-react/issues

### Security Issues

If you discover a security vulnerability in this script, please email security@processware.com instead of using the issue tracker.

---

## Changelog

### Version 2.0.0 (2025-12-11)
- ✅ **BREAKING:** Now requires sudo/admin for system-wide scan
- ✅ Added CVE-2025-55182 specific detection and warnings
- ✅ System-wide scanning (Docker, services, all users)
- ✅ Dry-run mode for safe testing
- ✅ Improved output with CVE details
- ✅ Enhanced security warnings
- ✅ Better error handling and reporting

### Version 1.0.0 (2025-12-11)
- ✅ Initial release
- ✅ Support for Windows, macOS, Linux
- ✅ JavaScript, PowerShell, and Bash versions
- ✅ Input validation and command injection prevention
- ✅ Backup creation before updates

---

## License

MIT License - See LICENSE file for details

---

## Support

For questions or issues:
1. Check the [Troubleshooting](#troubleshooting) section
2. Review the [Example Output](#example-output) section
3. Open an issue on GitHub
4. Contact: support@processware.com

---

## Final Warning

**This vulnerability is actively being exploited.** If you find vulnerable installations:

1. ✅ **Patch immediately** - Don't delay
2. ✅ **Review security logs** - Check for exploitation attempts
3. ✅ **Isolate vulnerable systems** - Until patched
4. ✅ **Monitor for suspicious activity** - Ongoing vigilance required

**The scanner is a tool, not a silver bullet. Always maintain defense-in-depth security practices.**

---

**Last Updated:** December 11, 2025  
**Maintained by:** Processware  
**CVE:** CVE-2025-55182 (CVSS 10.0)
