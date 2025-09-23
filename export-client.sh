#!/bin/bash

# Export modpack for CurseForge/Prism launcher clients
# Creates a downloadable modpack zip with all mods

set -e

# Configuration
MODPACK_DIR="./modpack"
EXPORT_DIR="./client-export"
OUTPUT_NAME="piekarnia-modpack"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Check packwiz is available
if ! command -v ~/go/bin/packwiz &> /dev/null; then
    log_error "packwiz not found. Install with: go install github.com/packwiz/packwiz@latest"
    exit 1
fi

# Function to export for CurseForge
export_curseforge() {
    log_info "Exporting modpack for CurseForge..."

    cd "$MODPACK_DIR"

    # Export as CurseForge pack
    ~/go/bin/packwiz curseforge export

    # Find the generated file
    local cf_file=$(ls -t *.zip | head -1)

    if [ -z "$cf_file" ]; then
        log_error "CurseForge export failed - no zip file created"
        return 1
    fi

    # Move to export directory
    mv "$cf_file" "../$EXPORT_DIR/${OUTPUT_NAME}-curseforge.zip"

    cd ..
    log_success "CurseForge pack exported: ${EXPORT_DIR}/${OUTPUT_NAME}-curseforge.zip"
}

# Function to export for Modrinth/Prism
export_modrinth() {
    log_info "Exporting modpack for Modrinth/Prism Launcher..."

    cd "$MODPACK_DIR"

    # Export as Modrinth pack
    ~/go/bin/packwiz modrinth export

    # Find the generated file
    local mr_file=$(ls -t *.mrpack | head -1)

    if [ -z "$mr_file" ]; then
        log_error "Modrinth export failed - no mrpack file created"
        return 1
    fi

    # Move to export directory
    mv "$mr_file" "../$EXPORT_DIR/${OUTPUT_NAME}.mrpack"

    cd ..
    log_success "Modrinth pack exported: ${EXPORT_DIR}/${OUTPUT_NAME}.mrpack"
}

# Function to create manual download pack
export_manual() {
    log_info "Creating manual mod download pack..."

    # Create temp directory
    local temp_dir="$EXPORT_DIR/temp_manual"
    mkdir -p "$temp_dir/mods"
    mkdir -p "$temp_dir/config"

    # Download all mods
    log_info "Downloading mods (this may take a while)..."

    cd "$MODPACK_DIR"

    # Use packwiz to download all mods
    for mod_file in mods/*.pw.toml; do
        if [ -f "$mod_file" ]; then
            local mod_name=$(basename "$mod_file" .pw.toml)
            echo -n "  Downloading $mod_name... "

            # Extract download URL from the .pw.toml file
            local url=$(grep "^url = " "$mod_file" | cut -d'"' -f2)
            local filename=$(grep "^filename = " "$mod_file" | cut -d'"' -f2)

            if [ -n "$url" ] && [ -n "$filename" ]; then
                if curl -sL "$url" -o "../$temp_dir/mods/$filename"; then
                    echo "✓"
                else
                    echo "✗"
                    log_error "Failed to download $mod_name"
                fi
            fi
        fi
    done

    # Copy configs if they exist
    if [ -d "config" ]; then
        cp -r config/* "../$temp_dir/config/" 2>/dev/null || true
    fi

    # Create README
    cat > "../$temp_dir/README.txt" << EOF
Piekarnia Modpack - Manual Installation
========================================

Minecraft Version: 1.21.1
Loader: Fabric 0.17.2

Installation Instructions:
1. Install Fabric loader 0.17.2 for Minecraft 1.21.1
2. Copy all files from 'mods' folder to your .minecraft/mods folder
3. Copy all files from 'config' folder to your .minecraft/config folder
4. Launch Minecraft with the Fabric profile

Mod Count: $(ls -1 "../$temp_dir/mods" | wc -l)

Generated: $(date)
EOF

    cd ..

    # Create zip archive
    cd "$EXPORT_DIR"
    zip -qr "${OUTPUT_NAME}-manual.zip" temp_manual/*
    rm -rf temp_manual
    cd ..

    log_success "Manual pack exported: ${EXPORT_DIR}/${OUTPUT_NAME}-manual.zip"
}

# Function to create installation instructions
create_instructions() {
    log_info "Creating installation instructions..."

    cat > "$EXPORT_DIR/INSTALLATION.md" << 'EOF'
# Piekarnia Modpack Installation Guide

## Quick Install Options

### Option 1: CurseForge Launcher (Recommended for Windows)
1. Download `piekarnia-modpack-curseforge.zip`
2. Open CurseForge launcher
3. Go to "My Modpacks" → Click "+" → "Import"
4. Select the downloaded zip file
5. Click "Play" when import completes

### Option 2: Prism Launcher (Recommended for Mac/Linux)
1. Download `piekarnia-modpack.mrpack`
2. Open Prism Launcher
3. Click "Add Instance" → "Import from zip"
4. Select the downloaded .mrpack file
5. Click "OK" and launch when ready

### Option 3: MultiMC
1. Download `piekarnia-modpack.mrpack`
2. Drag the file into MultiMC window
3. Follow the import wizard
4. Launch the instance

### Option 4: Manual Installation
1. Download `piekarnia-modpack-manual.zip`
2. Install Fabric Loader 0.17.2 for Minecraft 1.21.1
3. Extract the zip file
4. Copy contents of `mods` folder to `.minecraft/mods`
5. Copy contents of `config` folder to `.minecraft/config`
6. Launch Minecraft with Fabric profile

## Server Information
- **Server IP**: 91.98.39.164
- **Version**: Minecraft 1.21.1
- **Modpack**: Automatically synchronized

## Troubleshooting

### "Incompatible mod set" error
- Make sure you're using Minecraft 1.21.1
- Verify Fabric Loader is version 0.17.2
- Delete and re-download the modpack

### Performance Issues
- Allocate at least 4GB RAM (6-8GB recommended)
- In launcher settings, set JVM arguments: `-Xmx6G -Xms2G`

### Can't connect to server
- Verify you have the exact same mod versions
- Check that you're using Minecraft 1.21.1
- Ensure no additional client-side mods are installed

## Support
For issues or questions, contact the server administrator.

Last Updated: $(date)
EOF

    log_success "Installation instructions created"
}

# Main export function
main() {
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo -e "${BLUE}    Modpack Client Export Tool         ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo

    # Create export directory
    mkdir -p "$EXPORT_DIR"
    rm -f "$EXPORT_DIR"/*.zip "$EXPORT_DIR"/*.mrpack 2>/dev/null || true

    # Parse arguments
    case "${1:-all}" in
        curseforge)
            export_curseforge
            ;;
        modrinth)
            export_modrinth
            ;;
        manual)
            export_manual
            ;;
        all)
            export_curseforge || log_error "CurseForge export failed"
            export_modrinth || log_error "Modrinth export failed"
            export_manual || log_error "Manual export failed"
            create_instructions
            ;;
        *)
            echo "Usage: $0 [all|curseforge|modrinth|manual]"
            echo "  all        - Export for all platforms (default)"
            echo "  curseforge - Export for CurseForge launcher"
            echo "  modrinth   - Export for Modrinth/Prism launcher"
            echo "  manual     - Create manual installation pack"
            exit 1
            ;;
    esac

    # Show summary
    echo
    echo -e "${GREEN}Export Summary:${NC}"
    echo "═══════════════════════════════════════"
    ls -lh "$EXPORT_DIR"/*.{zip,mrpack} 2>/dev/null || true
    echo "═══════════════════════════════════════"
    echo
    echo -e "${YELLOW}Share these files with players:${NC}"
    echo "• CurseForge users: ${OUTPUT_NAME}-curseforge.zip"
    echo "• Prism/MultiMC users: ${OUTPUT_NAME}.mrpack"
    echo "• Manual install: ${OUTPUT_NAME}-manual.zip"
}

main "$@"