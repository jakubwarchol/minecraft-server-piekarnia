#!/bin/bash

# Check for mod updates from Modrinth collection and packwiz
# Compares installed mods with latest available versions

set -e

# Configuration
COLLECTION_ID="Fcn87KFP"
MODPACK_DIR="./modpack"
MC_VERSION="1.21.1"
LOADER="fabric"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_update() {
    echo -e "${YELLOW}[↑]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Function to check packwiz updates
check_packwiz_updates() {
    log_info "Checking for mod updates via packwiz..."

    cd "$MODPACK_DIR"

    # Run packwiz update check
    echo
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo -e "${CYAN}    Packwiz Update Check               ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"

    ~/go/bin/packwiz update --all 2>&1 | while IFS= read -r line; do
        if [[ "$line" == *"Updating"* ]]; then
            log_update "$line"
        elif [[ "$line" == *"up to date"* ]]; then
            log_success "$line"
        else
            echo "  $line"
        fi
    done

    cd ..
}

# Function to check Modrinth collection
check_collection_updates() {
    log_info "Fetching Modrinth collection $COLLECTION_ID..."

    # Get collection data
    local collection_data=$(curl -s "https://api.modrinth.com/v2/collection/$COLLECTION_ID")

    if [ $? -ne 0 ] || [ -z "$collection_data" ]; then
        log_error "Failed to fetch collection data"
        return 1
    fi

    # Extract project IDs
    local project_ids=$(echo "$collection_data" | python3 -c "
import json, sys
data = json.load(sys.stdin)
for project_id in data.get('projects', []):
    print(project_id)
" 2>/dev/null)

    echo
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo -e "${CYAN}    Modrinth Collection Check          ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"

    local new_mods=0
    local current_mods=$(find "$MODPACK_DIR/mods" -name "*.pw.toml" 2>/dev/null | wc -l)

    # Get installed mod slugs
    local installed_slugs=$(find "$MODPACK_DIR/mods" -name "*.pw.toml" -exec basename {} .pw.toml \; 2>/dev/null | tr '\n' ' ')

    # Check each project in collection
    for project_id in $project_ids; do
        # Get project details
        local project_data=$(curl -s "https://api.modrinth.com/v2/project/$project_id")
        local slug=$(echo "$project_data" | python3 -c "import json, sys; print(json.load(sys.stdin).get('slug', ''))" 2>/dev/null)
        local title=$(echo "$project_data" | python3 -c "import json, sys; print(json.load(sys.stdin).get('title', ''))" 2>/dev/null)

        if [ -n "$slug" ]; then
            # Check if mod is installed
            if [[ ! " $installed_slugs " =~ " $slug " ]]; then
                log_update "NEW: $title ($slug) - available in collection but not installed"
                ((new_mods++))
            fi
        fi
    done

    echo
    log_info "Collection has $(echo "$project_ids" | wc -w) mods"
    log_info "Modpack has $current_mods mods installed"

    if [ $new_mods -gt 0 ]; then
        log_update "Found $new_mods new mods in collection"
        echo
        echo -e "${YELLOW}To add new mods from collection:${NC}"
        echo "  1. Check mods.md for the full list"
        echo "  2. Run: cd modpack && ~/go/bin/packwiz modrinth install <mod-slug>"
    else
        log_success "All collection mods are installed"
    fi
}

# Function to check for incompatible mods
check_compatibility() {
    log_info "Checking mod compatibility..."

    echo
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo -e "${CYAN}    Compatibility Check                ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"

    cd "$MODPACK_DIR"

    # Find client-only mods
    local client_only=$(grep -l 'side = "client"' mods/*.pw.toml 2>/dev/null | wc -l)
    local server_only=$(grep -l 'side = "server"' mods/*.pw.toml 2>/dev/null | wc -l)
    local both_sides=$(grep -l 'side = "both"' mods/*.pw.toml 2>/dev/null | wc -l)
    local no_side=$(find mods -name "*.pw.toml" -exec grep -L "^side = " {} \; 2>/dev/null | wc -l)

    echo "  Client-only mods: $client_only"
    echo "  Server-only mods: $server_only"
    echo "  Both sides: $both_sides"
    echo "  Universal: $no_side"

    # Check for known incompatible mods
    echo
    log_info "Checking for known issues..."

    # List of known problematic mods for servers
    local problematic_mods=("zoomify" "better-ping-display" "mouse-tweaks")

    for mod in "${problematic_mods[@]}"; do
        if [ -f "mods/${mod}.pw.toml" ]; then
            local side=$(grep "^side = " "mods/${mod}.pw.toml" | cut -d'"' -f2)
            if [ "$side" == "client" ]; then
                log_success "$mod is correctly marked as client-only"
            else
                log_update "$mod should be marked as client-only"
            fi
        fi
    done

    cd ..
}

# Function to generate update report
generate_report() {
    local report_file="update-report-$(date +%Y%m%d-%H%M%S).txt"

    {
        echo "Modpack Update Report"
        echo "Generated: $(date)"
        echo "=================================="
        echo
        echo "Minecraft Version: $MC_VERSION"
        echo "Loader: Fabric 0.17.2"
        echo "Modpack Version: $(grep version "$MODPACK_DIR/pack.toml" | head -1 | cut -d'"' -f2)"
        echo
        echo "Mod Statistics:"
        echo "  Total mods: $(find "$MODPACK_DIR/mods" -name "*.pw.toml" | wc -l)"
        echo "  Modrinth collection: $COLLECTION_ID"
        echo
        echo "To update all mods:"
        echo "  cd modpack && ~/go/bin/packwiz update --all"
        echo
        echo "To deploy updates:"
        echo "  ./deploy.sh"
    } > "$report_file"

    log_success "Report saved to: $report_file"
}

# Main function
main() {
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo -e "${BLUE}    Modpack Update Checker             ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo

    # Check prerequisites
    if ! command -v ~/go/bin/packwiz &> /dev/null; then
        log_error "packwiz not found"
        exit 1
    fi

    if [ ! -d "$MODPACK_DIR" ]; then
        log_error "Modpack directory not found"
        exit 1
    fi

    # Run checks based on argument
    case "${1:-all}" in
        packwiz)
            check_packwiz_updates
            ;;
        collection)
            check_collection_updates
            ;;
        compatibility)
            check_compatibility
            ;;
        all)
            check_packwiz_updates
            echo
            check_collection_updates
            echo
            check_compatibility
            echo
            generate_report
            ;;
        update)
            log_info "Updating all mods..."
            cd "$MODPACK_DIR"
            ~/go/bin/packwiz update --all
            cd ..
            log_success "Updates complete. Run ./deploy.sh to apply to server"
            ;;
        *)
            echo "Usage: $0 [all|packwiz|collection|compatibility|update]"
            echo "  all           - Run all checks (default)"
            echo "  packwiz       - Check for mod updates via packwiz"
            echo "  collection    - Check Modrinth collection for new mods"
            echo "  compatibility - Check mod compatibility"
            echo "  update        - Update all mods to latest versions"
            exit 1
            ;;
    esac

    echo
    echo -e "${GREEN}Check complete!${NC}"
    echo
    echo -e "${YELLOW}Quick Commands:${NC}"
    echo "• Update all: ./check-updates.sh update"
    echo "• Deploy: ./deploy.sh"
    echo "• Export for players: ./export-client.sh"
}

main "$@"