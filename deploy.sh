#!/bin/bash

# Enhanced deployment script for Minecraft server modpack
# Features: error handling, rollback capability, validation, and status reporting

set -e  # Exit on error
set -u  # Exit on undefined variable
set -o pipefail  # Pipe failures cause script to fail

# Configuration
SERVER_IP="91.98.39.164"
SERVER_DIR="/opt/minecraft"
GITHUB_REPO="jakubwarchol/minecraft-server-piekarnia"
PACK_URL="https://raw.githubusercontent.com/${GITHUB_REPO}/main/modpack/pack.toml"
MODPACK_DIR="./modpack"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Error handler
error_handler() {
    local line_no=$1
    log_error "Script failed at line $line_no"
    log_error "Deployment aborted. Server state unchanged."
    exit 1
}

trap 'error_handler $LINENO' ERR

# Function to check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check if packwiz is installed
    if ! command -v ~/go/bin/packwiz &> /dev/null; then
        log_error "packwiz not found. Install with: go install github.com/packwiz/packwiz@latest"
        exit 1
    fi

    # Check if we're in the right directory
    if [ ! -d "$MODPACK_DIR" ]; then
        log_error "Modpack directory not found. Run from minecraft-server-piekarnia/"
        exit 1
    fi

    # Check if git repo is clean
    if [ -n "$(git status --porcelain)" ]; then
        log_warning "Git repository has uncommitted changes"
        read -p "Continue anyway? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Deployment cancelled"
            exit 0
        fi
    fi

    # Test SSH connection
    if ! ssh -o ConnectTimeout=5 root@${SERVER_IP} "echo 'SSH connection successful' > /dev/null"; then
        log_error "Cannot connect to server at ${SERVER_IP}"
        exit 1
    fi

    log_success "Prerequisites check passed"
}

# Function to refresh packwiz index
refresh_packwiz() {
    log_info "Refreshing packwiz index..."
    cd "$MODPACK_DIR"

    if ! ~/go/bin/packwiz refresh; then
        log_error "Failed to refresh packwiz index"
        exit 1
    fi

    cd ..
    log_success "Packwiz index refreshed"
}

# Function to validate pack.toml
validate_pack() {
    log_info "Validating modpack..."
    cd "$MODPACK_DIR"

    # Check pack.toml exists
    if [ ! -f "pack.toml" ]; then
        log_error "pack.toml not found"
        exit 1
    fi

    # Count mods
    local mod_count=$(find mods -name "*.pw.toml" 2>/dev/null | wc -l)
    log_info "Found $mod_count mods in pack"

    cd ..
    log_success "Modpack validation passed"
}

# Function to commit and push changes
push_to_github() {
    log_info "Pushing changes to GitHub..."

    # Stage changes
    git add .

    # Check if there are changes to commit
    if git diff --staged --quiet; then
        log_info "No changes to commit"
        return 0
    fi

    # Commit with timestamp
    local commit_msg="Update modpack - $(date '+%Y-%m-%d %H:%M:%S')"
    git commit -m "$commit_msg"

    # Push to GitHub
    if ! git push origin main; then
        log_error "Failed to push to GitHub"
        log_info "Trying to pull and merge..."
        git pull origin main --no-edit
        git push origin main
    fi

    log_success "Changes pushed to GitHub"
}

# Function to create server backup
create_backup() {
    log_info "Creating server backup..."

    local backup_name="backup-$(date +%Y%m%d-%H%M%S).tar.gz"

    ssh root@${SERVER_IP} "cd ${SERVER_DIR} && \
        tar -czf ${backup_name} mods/ config/ 2>/dev/null || true"

    log_success "Backup created: ${backup_name}"
    echo "$backup_name"  # Return backup name for potential rollback
}

# Function to check server status
check_server_status() {
    local status=$(ssh root@${SERVER_IP} "systemctl is-active minecraft" 2>/dev/null || echo "unknown")
    echo "$status"
}

# Function to wait for server to be ready
wait_for_server() {
    local max_wait=120  # 2 minutes
    local elapsed=0

    log_info "Waiting for server to start..."

    while [ $elapsed -lt $max_wait ]; do
        if ssh root@${SERVER_IP} "grep -q 'Done (' ${SERVER_DIR}/logs/latest.log 2>/dev/null"; then
            log_success "Server started successfully"
            return 0
        fi

        sleep 5
        elapsed=$((elapsed + 5))
        echo -n "."
    done

    echo
    log_error "Server failed to start within ${max_wait} seconds"
    return 1
}

# Function to restart server with new modpack
restart_server() {
    log_info "Restarting Minecraft server..."

    # Stop the server
    log_info "Stopping server..."
    ssh root@${SERVER_IP} "systemctl stop minecraft"

    # Wait for full stop
    sleep 3

    # Clear old logs to track new startup
    ssh root@${SERVER_IP} "rm -f ${SERVER_DIR}/logs/latest.log"

    # Start the server
    log_info "Starting server..."
    ssh root@${SERVER_IP} "systemctl start minecraft"

    # Wait and check if server starts successfully
    if wait_for_server; then
        log_success "Server restarted successfully"
        return 0
    else
        log_error "Server failed to start"
        return 1
    fi
}

# Function to display deployment summary
show_summary() {
    echo
    echo "=========================================="
    echo -e "${GREEN}Deployment Summary${NC}"
    echo "=========================================="
    echo -e "Server IP: ${BLUE}${SERVER_IP}${NC}"
    echo -e "Pack URL: ${BLUE}${PACK_URL}${NC}"
    echo -e "Server Status: ${GREEN}$(check_server_status)${NC}"
    echo
    echo -e "${YELLOW}Recent server logs:${NC}"
    ssh root@${SERVER_IP} "tail -5 ${SERVER_DIR}/logs/latest.log | grep -v '^$'" 2>/dev/null || true
    echo "=========================================="
}

# Main deployment function
deploy() {
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo -e "${BLUE}   Minecraft Modpack Deployment Tool   ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo

    # Run checks
    check_prerequisites
    validate_pack

    # Refresh packwiz
    refresh_packwiz

    # Push to GitHub
    push_to_github

    # Create backup before deployment
    local backup_file=$(create_backup)

    # Restart server
    if restart_server; then
        log_success "Deployment completed successfully!"
    else
        log_error "Deployment failed"
        log_warning "Backup available: ${backup_file}"
        log_info "To rollback: ssh root@${SERVER_IP} 'cd ${SERVER_DIR} && tar -xzf ${backup_file}'"
        exit 1
    fi

    # Show summary
    show_summary
}

# Parse command line arguments
case "${1:-deploy}" in
    deploy)
        deploy
        ;;
    status)
        log_info "Server status: $(check_server_status)"
        ssh root@${SERVER_IP} "systemctl status minecraft --no-pager | head -15"
        ;;
    logs)
        log_info "Recent server logs:"
        ssh root@${SERVER_IP} "tail -30 ${SERVER_DIR}/logs/latest.log"
        ;;
    backup)
        create_backup
        ;;
    *)
        echo "Usage: $0 [deploy|status|logs|backup]"
        echo "  deploy - Deploy modpack to server (default)"
        echo "  status - Check server status"
        echo "  logs   - View recent server logs"
        echo "  backup - Create server backup"
        exit 1
        ;;
esac