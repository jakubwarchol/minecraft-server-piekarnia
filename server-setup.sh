#!/bin/bash

# Server setup script for packwiz modpack
# This script sets up the Minecraft server with packwiz-installer

SERVER_IP="91.98.39.164"
SERVER_DIR="/opt/minecraft"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Setting up Minecraft server with packwiz-installer${NC}"
echo "========================================"

# First, we need to host the pack files
echo -e "${YELLOW}Step 1: Pack Hosting${NC}"
echo "Your pack files need to be accessible via HTTP/HTTPS."
echo "Options:"
echo "  1. GitHub Pages (free, easy)"
echo "  2. Netlify (free, drag-and-drop)"
echo "  3. Your own web server"
echo ""
echo "For GitHub Pages:"
echo "  - Push your modpack/ folder to a GitHub repo"
echo "  - Enable GitHub Pages in repo settings"
echo "  - Your pack URL will be: https://[username].github.io/[repo]/pack.toml"
echo ""

read -p "Enter your pack.toml URL (or press Enter to set up later): " PACK_URL

if [ -z "$PACK_URL" ]; then
    PACK_URL="https://your-username.github.io/your-repo/pack.toml"
    echo -e "${YELLOW}Using placeholder URL. Update this after hosting your pack.${NC}"
fi

echo ""
echo -e "${BLUE}Generating server installation script...${NC}"

# Create the server installation script
cat > deploy-to-server.sh << 'EOF'
#!/bin/bash

SERVER_IP="91.98.39.164"
SERVER_DIR="/opt/minecraft"
PACK_URL="PLACEHOLDER_URL"

echo "Deploying packwiz modpack to server..."

# Download packwiz-installer
echo "Downloading packwiz-installer..."
ssh root@$SERVER_IP "cd $SERVER_DIR && wget -O packwiz-installer.jar https://github.com/packwiz/packwiz-installer/releases/latest/download/packwiz-installer.jar"

# Create the startup script with packwiz-installer
echo "Creating startup script..."
ssh root@$SERVER_IP "cat > $SERVER_DIR/start.sh << 'STARTSCRIPT'
#!/bin/bash

# Run packwiz installer to update mods
echo 'Checking for modpack updates...'
java -jar packwiz-installer.jar -g -s server $PACK_URL

# Start the Minecraft server
echo 'Starting Minecraft server...'
java -Xmx6G -Xms6G \\
-XX:+UseG1GC -XX:+ParallelRefProcEnabled \\
-XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions \\
-XX:+DisableExplicitGC -XX:+AlwaysPreTouch \\
-XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 \\
-XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 \\
-XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem \\
-XX:MaxTenuringThreshold=1 -XX:G1NewSizePercent=30 \\
-XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M \\
-XX:G1ReservePercent=20 -XX:InitiatingHeapOccupancyPercent=15 \\
-jar fabric-server-launcher.jar nogui
STARTSCRIPT
"

ssh root@$SERVER_IP "chmod +x $SERVER_DIR/start.sh"

# Update systemd service
echo "Updating systemd service..."
ssh root@$SERVER_IP "systemctl stop minecraft"
ssh root@$SERVER_IP "systemctl daemon-reload"

echo "Done! The server will now auto-update the modpack on each restart."
echo "To start the server: systemctl start minecraft"
EOF

# Replace placeholder with actual URL
sed -i.bak "s|PLACEHOLDER_URL|$PACK_URL|g" deploy-to-server.sh
chmod +x deploy-to-server.sh

echo ""
echo -e "${GREEN}Setup complete!${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Host your pack files online:"
echo "   - GitHub: Push modpack/ to GitHub and enable Pages"
echo "   - Netlify: Drag modpack/ folder to netlify.com/drop"
echo ""
echo "2. Update PACK_URL in deploy-to-server.sh with your actual URL"
echo ""
echo "3. Run: ./deploy-to-server.sh"
echo ""
echo "4. Your server will auto-update whenever you push changes!"
echo ""
echo -e "${YELLOW}How the auto-update works:${NC}"
echo "- You edit mods/configs locally"
echo "- Run: packwiz refresh"
echo "- Push to GitHub/update hosting"
echo "- Server downloads updates on next restart"