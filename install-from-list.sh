#!/bin/bash

# Install mods from mods.md file using packwiz
# Reads mod slugs directly from the simple list format

# Set packwiz path
PACKWIZ="$HOME/go/bin/packwiz"

# Check if we're in the modpack directory
if [ ! -f "pack.toml" ]; then
    echo "Error: pack.toml not found. Please run this from your packwiz modpack directory."
    exit 1
fi

# Check if mods.md exists
if [ ! -f "../mods.md" ]; then
    echo "Error: mods.md not found in parent directory."
    exit 1
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Reading mods from mods.md...${NC}"

# Read mods from the file (skip header lines and empty lines)
MODS=()
while IFS= read -r line; do
    # Skip empty lines and lines starting with #
    if [[ -n "$line" && ! "$line" =~ ^# ]]; then
        MODS+=("$line")
    fi
done < "../mods.md"

echo -e "${BLUE}Found ${#MODS[@]} mods to process${NC}"
echo "=========================================="

SUCCESSFUL=0
FAILED=0
SKIPPED=0

for i in "${!MODS[@]}"; do
    MOD="${MODS[$i]}"
    PROGRESS=$((i + 1))

    # Progress bar
    PCT=$(( PROGRESS * 100 / ${#MODS[@]} ))
    echo ""
    echo -e "${YELLOW}[$PROGRESS/${#MODS[@]}] ($PCT%) Processing: $MOD${NC}"

    # Check if already installed
    if [ -f "mods/${MOD}.pw.toml" ]; then
        echo -e "${GREEN}  ✓ Already installed${NC}"
        ((SKIPPED++))
        continue
    fi

    # Try to install the mod
    if $PACKWIZ modrinth install "$MOD" --yes >/dev/null 2>&1; then
        echo -e "${GREEN}  ✓ Successfully installed${NC}"
        ((SUCCESSFUL++))
    else
        echo -e "${RED}  ✗ Failed to install${NC}"
        ((FAILED++))
    fi

    # Small delay to avoid rate limiting
    sleep 0.1
done

echo ""
echo "=========================================="
echo -e "${BLUE}Refreshing packwiz index...${NC}"
$PACKWIZ refresh

echo ""
echo "=========================================="
echo -e "${BLUE}Installation Complete!${NC}"
echo -e "${GREEN}✓ Successful: $SUCCESSFUL${NC}"
echo -e "${YELLOW}⊙ Skipped: $SKIPPED${NC}"
echo -e "${RED}✗ Failed: $FAILED${NC}"
echo "──────────────────────────"
echo "Total mods: ${#MODS[@]}"