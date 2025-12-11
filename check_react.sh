#!/bin/bash

# check_react.sh - React CVE-2025-55182 Vulnerability Scanner
# Author: Processware
# License: MIT
# CVE: CVE-2025-55182 (CVSS 10.0 - CRITICAL)
# 
# DISCLAIMER: Use this script at your own risk. The authors are not responsible
# for any data loss or damage caused by running this script. Always backup your
# project files before running automated updates.
#
# This script requires sudo to scan system-wide directories (Docker containers,
# system services, etc.) for vulnerable React installations.

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

VULNERABLE_FOUND=0
PROJECTS_UPDATED=0
MAX_DEPTH=10
DRY_RUN=false

# Parse command line arguments
for arg in "$@"; do
    case $arg in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help|-h)
            echo "React CVE-2025-55182 Vulnerability Scanner"
            echo ""
            echo "Usage: sudo ./check_react.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --dry-run    Preview changes without making modifications"
            echo "  --help, -h   Show this help message"
            echo ""
            echo "This script scans system-wide for vulnerable React installations."
            echo "Requires sudo for full system access (Docker, services, etc.)"
            exit 0
            ;;
    esac
done

# Check if running as root
if [ "$EUID" -ne 0 ] && [ "$DRY_RUN" = false ]; then
    echo -e "${RED}This script requires sudo to scan system-wide directories.${NC}"
    echo -e "${YELLOW}Run with: sudo ./check_react.sh${NC}"
    echo -e "${BLUE}Or use --dry-run to test without sudo: ./check_react.sh --dry-run${NC}"
    exit 1
fi

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  React CVE-2025-55182 Vulnerability Scanner (React2Shell)  ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
if [ "$DRY_RUN" = true ]; then
    echo -e "${BLUE}[DRY-RUN MODE] - No changes will be made${NC}"
    echo ""
fi

echo -e "${YELLOW}⚠️  CVE-2025-55182: CRITICAL (CVSS 10.0)${NC}"
echo "Unauthenticated Remote Code Execution in React Server Components"
echo "Actively exploited in the wild - Immediate patching required"
echo ""

# Validate version string to prevent command injection
validate_version() {
    local version="$1"
    if [[ $version =~ ^[\^~]?[0-9]+\.[0-9]+\.[0-9]+ ]]; then
        return 0
    fi
    return 1
}

# Check if version is vulnerable and return safe version
is_vulnerable() {
    local version="$1"
    
    if ! validate_version "$version"; then
        return 1
    fi
    
    # Remove ^ or ~ prefixes and pre-release tags
    local clean_version=$(echo "$version" | sed 's/[\^~]//g' | cut -d'-' -f1)
    
    # Extract major.minor.patch
    local major=$(echo "$clean_version" | cut -d'.' -f1)
    local minor=$(echo "$clean_version" | cut -d'.' -f2)
    local patch=$(echo "$clean_version" | cut -d'.' -f3)
    
    # Default patch to 0 if not specified
    patch=${patch:-0}
    
    # CVE-2025-55182: Check vulnerable React 19 versions
    if [ "$major" = "19" ]; then
        if [ "$minor" = "0" ] && [ "$patch" = "0" ]; then
            echo "19.0.1"
            return 0
        elif [ "$minor" = "1" ] && ([ "$patch" = "0" ] || [ "$patch" = "1" ]); then
            echo "19.1.2"
            return 0
        elif [ "$minor" = "2" ] && [ "$patch" = "0" ]; then
            echo "19.2.1"
            return 0
        fi
    fi
    
    return 1
}

# Create backup of package.json
create_backup() {
    local file="$1"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup="${file}.backup.${timestamp}"
    
    if cp "$file" "$backup" 2>/dev/null; then
        echo "$backup"
        return 0
    fi
    return 1
}

# Update project
update_project() {
    local dir="$1"
    local new_version="$2"
    
    echo ""
    echo -e "${YELLOW}📦 Updating React to $new_version...${NC}"
    echo "   📁 In: $dir"
    
    if [ "$DRY_RUN" = true ]; then
        echo -e "${BLUE}   [DRY-RUN] Would execute: npm install react@${new_version} react-dom@${new_version} --save --legacy-peer-deps${NC}"
        return 0
    fi
    
    # Validate version one more time
    if ! validate_version "$new_version"; then
        echo -e "${RED}   ❌ Invalid version string: $new_version${NC}"
        return 1
    fi
    
    cd "$dir" || return 1
    
    # Create backup before updating
    local backup=$(create_backup "package.json")
    if [ -n "$backup" ]; then
        echo "   💾 Backup created: $(basename "$backup")"
    fi
    
    # Check which package manager is available
    local result=0
    if [ -f "package-lock.json" ]; then
        echo "   Using npm..."
        npm install "react@${new_version}" "react-dom@${new_version}" --save --legacy-peer-deps 2>&1 | grep -v "npm WARN"
        result=$?
    elif [ -f "yarn.lock" ]; then
        echo "   Using yarn..."
        yarn add "react@${new_version}" "react-dom@${new_version}" 2>&1 | grep -v "warning"
        result=$?
    else
        echo "   Using npm (default)..."
        npm install "react@${new_version}" "react-dom@${new_version}" --save --legacy-peer-deps 2>&1 | grep -v "npm WARN"
        result=$?
    fi
    
    cd - > /dev/null || return 1
    
    if [ $result -eq 0 ]; then
        echo -e "${GREEN}   ✅ Successfully updated!${NC}"
        PROJECTS_UPDATED=$((PROJECTS_UPDATED + 1))
        return 0
    else
        echo -e "${RED}   ❌ Update failed!${NC}"
        return 1
    fi
}

# Main scanning logic
echo "=== Scanning System for Vulnerable React Installations ==="
echo ""
echo "Scanning directories:"
echo "  • User home directories"
echo "  • Docker containers (/var/lib/docker)"
echo "  • System services (/opt, /srv)"
echo "  • Application directories (/usr/local)"
echo ""

# Arrays to store vulnerable projects
declare -a VULN_DIRS
declare -a VULN_VERSIONS
declare -a NEW_VERSIONS
VULN_COUNT=0

# Search paths for system-wide scan
SEARCH_PATHS=(
    "/root"
    "/home"
    "/var/lib/docker"
    "/opt"
    "/srv"
    "/usr/local"
)

# Find all package.json files system-wide
for search_path in "${SEARCH_PATHS[@]}"; do
    if [ ! -d "$search_path" ]; then
        continue
    fi
    
    echo -e "${BLUE}Scanning: $search_path${NC}"
    
    while IFS= read -r package_file; do
        package_dir=$(dirname "$package_file")
        
        # Check if file contains react
        if grep -q '"react"' "$package_file" 2>/dev/null; then
            # Extract version
            version=""
            if command -v jq &> /dev/null; then
                version=$(jq -r '.dependencies.react // .devDependencies.react // empty' "$package_file" 2>/dev/null)
            else
                version=$(grep -o '"react"[[:space:]]*:[[:space:]]*"[^"]*"' "$package_file" | cut -d'"' -f4)
            fi
            
            if [ ! -z "$version" ]; then
                # Check if vulnerable
                new_version=$(is_vulnerable "$version")
                if [ $? -eq 0 ]; then
                    VULN_DIRS[$VULN_COUNT]="$package_dir"
                    VULN_VERSIONS[$VULN_COUNT]="$version"
                    NEW_VERSIONS[$VULN_COUNT]="$new_version"
                    VULNERABLE_FOUND=$((VULNERABLE_FOUND + 1))
                    
                    echo -e "${RED}⚠️  VULNERABLE: React $version${NC}"
                    echo "   📁 Location: $package_dir"
                    echo "   🔒 CVE-2025-55182: Remote Code Execution"
                    echo "   📦 Update to: $new_version"
                    
                    VULN_COUNT=$((VULN_COUNT + 1))
                    echo ""
                fi
            fi
        fi
    done < <(find "$search_path" -maxdepth "$MAX_DEPTH" -name "package.json" -type f 2>/dev/null | grep -v "node_modules")
done

# Update vulnerable projects
if [ $VULNERABLE_FOUND -gt 0 ]; then
    echo ""
    echo -e "${RED}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${RED}  CRITICAL: $VULNERABLE_FOUND Vulnerable Installation(s) Found${NC}"
    echo -e "${RED}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "These installations are vulnerable to CVE-2025-55182:"
    echo "• Unauthenticated Remote Code Execution"
    echo "• CVSS Score: 10.0 (CRITICAL)"
    echo "• Actively exploited in the wild"
    echo ""
    echo "=== Update Vulnerable Projects ==="
    echo ""
    
    for ((i=0; i<$VULN_COUNT; i++)); do
        dir="${VULN_DIRS[$i]}"
        version="${NEW_VERSIONS[$i]}"
        
        echo -e "${YELLOW}Project $((i+1))/$VULN_COUNT: $dir${NC}"
        read -p "   Update to React $version? (y/n): " -n 1 -r answer
        echo ""
        
        if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
            update_project "$dir" "$version"
        else
            echo "   ⏭️  Skipped"
        fi
        echo ""
    done
fi

# Summary
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "                         SUMMARY"
echo "═══════════════════════════════════════════════════════════"
if [ $VULNERABLE_FOUND -eq 0 ]; then
    echo -e "${GREEN}✅ No vulnerable versions found!${NC}"
    echo "Your system is protected against CVE-2025-55182"
else
    echo -e "${RED}⚠️  $VULNERABLE_FOUND vulnerable installation(s) found${NC}"
    echo -e "${GREEN}✅ $PROJECTS_UPDATED project(s) updated${NC}"
    
    if [ $PROJECTS_UPDATED -lt $VULNERABLE_FOUND ]; then
        echo -e "${YELLOW}⚠️  $((VULNERABLE_FOUND - PROJECTS_UPDATED)) project(s) remain vulnerable${NC}"
        echo ""
        echo "IMMEDIATE ACTION REQUIRED:"
        echo "• Update remaining projects manually"
        echo "• Review security logs for exploitation attempts"
        echo "• Consider temporary mitigations (WAF rules, network isolation)"
    fi
fi
echo "═══════════════════════════════════════════════════════════"
echo ""
