#!/bin/bash

# check_react.sh - React Vulnerability Scanner
# Author: Processware
# License: MIT
# 
# DISCLAIMER: Use this script at your own risk. The authors are not responsible
# for any data loss or damage caused by running this script. Always backup your
# project files before running automated updates.

# Kleuren voor output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

VULNERABLE_FOUND=0
PROJECTS_UPDATED=0
MAX_DEPTH=5
DRY_RUN=false

# Parse command line arguments
for arg in "$@"; do
    case $arg in
        --dry-run)
            DRY_RUN=true
            ;;
    esac
done

echo -e "${BLUE}🔍 React Server Components Vulnerability Scanner${NC}"
if [ "$DRY_RUN" = true ]; then
    echo -e "${BLUE}[DRY-RUN MODE] - No changes will be made${NC}"
fi
echo ""

# Validate version string to prevent command injection
validate_version() {
    local version="$1"
    # Check if version matches semantic versioning pattern
    if [[ $version =~ ^[\^~]?[0-9]+\.[0-9]+\.[0-9]+ ]]; then
        return 0
    fi
    return 1
}

# Functie om versie te controleren en terug te geven of kwetsbaar
is_vulnerable() {
    local version="$1"
    
    # Validate version string
    if ! validate_version "$version"; then
        return 1
    fi
    
    # Verwijder ^ of ~ voorvoegsels
    local clean_version=$(echo "$version" | sed 's/[\^~]//g' | cut -d'-' -f1)
    
    # Extract major.minor.patch
    local major=$(echo "$clean_version" | cut -d'.' -f1)
    local minor=$(echo "$clean_version" | cut -d'.' -f2)
    local patch=$(echo "$clean_version" | cut -d'.' -f3)
    
    # Default patch to 0 if not specified
    patch=${patch:-0}
    
    # Check kwetsbare versies
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

# Functie om project te updaten
update_project() {
    local dir="$1"
    local new_version="$2"
    
    echo ""
    echo -e "${YELLOW}📦 Updating React to $new_version...${NC}"
    echo "   📁 In: $dir"
    
    if [ "$DRY_RUN" = true ]; then
        echo -e "${BLUE}[DRY-RUN] Would execute: npm install react@${new_version} react-dom@${new_version} --save --legacy-peer-deps${NC}"
        return 0
    fi
    
    # Validate version one more time
    if ! validate_version "$new_version"; then
        echo -e "${RED}❌ Invalid version string: $new_version${NC}"
        return 1
    fi
    
    cd "$dir" || return 1
    
    # Create backup before updating
    local backup=$(create_backup "package.json")
    if [ -n "$backup" ]; then
        echo "   💾 Backup created: $(basename "$backup")"
    fi
    
    # Check welke package manager beschikbaar is
    local result=0
    if [ -f "package-lock.json" ]; then
        echo "   Using npm..."
        npm install "react@${new_version}" "react-dom@${new_version}" --save --legacy-peer-deps
        result=$?
    elif [ -f "yarn.lock" ]; then
        echo "   Using yarn..."
        yarn add "react@${new_version}" "react-dom@${new_version}"
        result=$?
    else
        echo "   Using npm (default)..."
        npm install "react@${new_version}" "react-dom@${new_version}" --save --legacy-peer-deps
        result=$?
    fi
    
    cd - > /dev/null || return 1
    
    if [ $result -eq 0 ]; then
        echo -e "${GREEN}✅ Successfully updated!${NC}"
        PROJECTS_UPDATED=$((PROJECTS_UPDATED + 1))
        return 0
    else
        echo -e "${RED}❌ Update failed!${NC}"
        return 1
    fi
}

# Main
echo "=== React Server Components Vulnerability Check ==="
echo ""

# Declareer arrays
declare -a VULN_DIRS
declare -a VULN_VERSIONS
declare -a NEW_VERSIONS
VULN_COUNT=0

# Zoek kwetsbare versies - ONLY in home directory (no sudo needed)
echo "Scanning from: $HOME"
echo ""

# Use find with maxdepth to limit recursion
while IFS= read -r package_file; do
    package_dir=$(dirname "$package_file")
    
    if grep -q "react" "$package_file" 2>/dev/null; then
        # Haal versie op
        local version=""
        if command -v jq &> /dev/null; then
            version=$(jq -r '.dependencies.react // .devDependencies.react // empty' "$package_file" 2>/dev/null)
        else
            version=$(grep -o '"react": "[^"]*"' "$package_file" | cut -d'"' -f4)
        fi
        
        if [ ! -z "$version" ]; then
            # Check of kwetsbaar
            new_version=$(is_vulnerable "$version")
            if [ $? -eq 0 ]; then
                VULN_DIRS[$VULN_COUNT]="$package_dir"
                VULN_VERSIONS[$VULN_COUNT]="$version"
                NEW_VERSIONS[$VULN_COUNT]="$new_version"
                VULNERABLE_FOUND=$((VULNERABLE_FOUND + 1))
                
                echo -e "${RED}⚠️  VULNERABLE: React $version${NC}"
                echo "   📁 Location: $package_dir"
                echo "   📦 Update to: $new_version"
                
                VULN_COUNT=$((VULN_COUNT + 1))
                echo ""
            fi
        fi
    fi
done < <(find "$HOME" -maxdepth "$MAX_DEPTH" -name "package.json" -type f 2>/dev/null | grep -v node_modules)

# Nu vragen om updates
if [ $VULNERABLE_FOUND -gt 0 ]; then
    echo ""
    echo "=== Update Vulnerable Projects ==="
    echo ""
    
    for ((i=0; i<$VULN_COUNT; i++)); do
        dir="${VULN_DIRS[$i]}"
        version="${NEW_VERSIONS[$i]}"
        
        echo -e "${YELLOW}Project $((i+1))/$VULN_COUNT: $dir${NC}"
        read -p "   Update? (y/n): " -n 1 -r answer
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
echo "=== Results ==="
if [ $VULNERABLE_FOUND -eq 0 ]; then
    echo -e "${GREEN}✅ No vulnerable versions found!${NC}"
else
    echo -e "${RED}⚠️  $VULNERABLE_FOUND vulnerable version(s) found${NC}"
    echo -e "${GREEN}✅ $PROJECTS_UPDATED project(s) updated${NC}"
fi
echo ""
