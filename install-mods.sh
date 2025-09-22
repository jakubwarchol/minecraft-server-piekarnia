#!/bin/bash

# Batch install mods for packwiz from the modpack-mods.md file
# This script reads mod slugs and installs them using packwiz

# Set packwiz path
PACKWIZ="$HOME/go/bin/packwiz"

# Check if we're in the right directory
if [ ! -f "pack.toml" ]; then
    echo "Error: pack.toml not found. Please run this from your packwiz modpack directory."
    exit 1
fi

# Array of all mod slugs from your collection
MODS=(
    "3d-crops"
    "3d-ladders"
    "abridged"
    "aether"
    "ambientsounds"
    "appleskin"
    "ati-structures-vanilla-edition"
    "better-combat"
    "better-lanterns"
    "cave-dust"
    "clickvillagers"
    "comforts"
    "continuity"
    "coolrain"
    "crate-delight"
    "distanthorizons"
    "do-api"
    "door-tweaks"
    "elytra-physics"
    "elytra-slot"
    "elytra-trims"
    "enchant-icons-countxd"
    "enchanted-books-re-covered"
    "entity-model-features"
    "entityculling"
    "entitytexturefeatures"
    "fancy-crops"
    "farmers-delight"
    "farmers-delight-refabricated"
    "fat-cat"
    "fresh-animations"
    "horseman"
    "immediatelyfast"
    "inventory-profiles-next"
    "jei"
    "lets-do-addon-compat"
    "lets-do-addon-corn-expansion"
    "lets-do-bakery-farmcharm-compat"
    "lets-do-beachparty"
    "lets-do-brewery-farmcharm-compat"
    "lets-do-candlelight-farmcharm-compat"
    "lets-do-farm-charm"
    "lets-do-furniture"
    "lets-do-herbalbrews"
    "lets-do-wildernature"
    "lithium"
    "macaws-doors"
    "macaws-fences-and-walls"
    "macaws-lights-and-lamps"
    "macaws-paths-and-pavings"
    "macaws-roofs"
    "macaws-stairs"
    "macaws-windows"
    "more-delight"
    "mouse-tweaks"
    "new-glowing-ores"
    "noisium"
    "particle-rain"
    "pneumono_gravestones"
    "rays-3d-rails"
    "ribbits"
    "rightclickharvest"
    "sophisticated-backpacks"
    "sound"
    "status-effect-bars"
    "storage-delight"
    "subtle-effects"
    "supplementaries"
    "supplementaries-squared"
    "terralith"
    "toms-storage"
    "too-many-bows"
    "towns-and-towers"
    "trade-cycling"
    "trek"
    "veinminer"
    "veinminer-client"
    "vvi"
    "waystones"
    "xaeros-world-map"
    "yungs-better-desert-temples"
    "yungs-better-dungeons"
    "yungs-better-jungle-temples"
    "yungs-better-mineshafts"
    "yungs-better-nether-fortresses"
    "yungs-better-strongholds"
    "yungs-better-witch-huts"
    "yungs-bridges"
    "zoomify"
)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "Starting installation of ${#MODS[@]} mods..."
echo "=========================================="

SUCCESSFUL=0
FAILED=0
SKIPPED=0

for i in "${!MODS[@]}"; do
    MOD="${MODS[$i]}"
    PROGRESS=$((i + 1))
    echo ""
    echo -e "${YELLOW}[$PROGRESS/${#MODS[@]}] Processing: $MOD${NC}"

    # Check if already installed
    if [ -f "mods/${MOD}.pw.toml" ]; then
        echo -e "${GREEN}  ✓ Already installed${NC}"
        ((SKIPPED++))
        continue
    fi

    # Try to install the mod
    if $PACKWIZ modrinth install "$MOD" --yes 2>/dev/null; then
        echo -e "${GREEN}  ✓ Successfully installed${NC}"
        ((SUCCESSFUL++))
    else
        echo -e "${RED}  ✗ Failed to install${NC}"
        ((FAILED++))
    fi

    # Small delay to be nice to the API
    sleep 0.1
done

echo ""
echo "=========================================="
echo "Refreshing packwiz index..."
$PACKWIZ refresh

echo ""
echo "=========================================="
echo "Installation Complete!"
echo -e "${GREEN}Successful: $SUCCESSFUL${NC}"
echo -e "${YELLOW}Skipped: $SKIPPED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo "Total: ${#MODS[@]}"