#!/bin/bash

# Deploy packwiz modpack to Minecraft server
# Using packwiz-installer for automatic updates

SERVER_IP="91.98.39.164"
SERVER_DIR="/opt/minecraft"
PACK_URL="https://raw.githubusercontent.com/jakubwarchol/minecraft-server-piekarnia/main/modpack/pack.toml"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Deploying Minecraft modpack to server${NC}"
echo "========================================"
echo "Server: $SERVER_IP"
echo "Pack URL: $PACK_URL"
echo ""

# Stop the server
echo -e "${YELLOW}Stopping Minecraft server...${NC}"
ssh root@$SERVER_IP "systemctl stop minecraft"

# Backup existing mods
echo -e "${YELLOW}Backing up existing server...${NC}"
ssh root@$SERVER_IP "cd $SERVER_DIR && tar -czf backup-$(date +%Y%m%d-%H%M%S).tar.gz mods/ config/ 2>/dev/null || true"

# Download packwiz-installer
echo -e "${YELLOW}Installing packwiz-installer...${NC}"
ssh root@$SERVER_IP "cd $SERVER_DIR && wget -q -O packwiz-installer.jar https://github.com/packwiz/packwiz-installer/releases/latest/download/packwiz-installer.jar"

# Create new startup script with packwiz-installer
echo -e "${YELLOW}Creating startup script...${NC}"
ssh root@$SERVER_IP "cat > $SERVER_DIR/start.sh << 'EOF'
#!/bin/bash

# Colors for output
GREEN='\\033[0;32m'
YELLOW='\\033[1;33m'
BLUE='\\033[0;34m'
NC='\\033[0m'

echo -e \"\${BLUE}Starting Minecraft Server with Modpack\${NC}\"
echo \"======================================\"

# Run packwiz installer to update/install mods
echo -e \"\${YELLOW}Checking for modpack updates...\${NC}\"
java -jar packwiz-installer.jar -g -s server $PACK_URL

if [ \$? -eq 0 ]; then
    echo -e \"\${GREEN}Modpack is up to date!\${NC}\"
else
    echo -e \"\${YELLOW}Warning: Modpack update had issues\${NC}\"
fi

echo \"\"
echo -e \"\${BLUE}Starting Minecraft server...\${NC}\"

# Start the Minecraft server
exec java -Xmx6G -Xms6G \\
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
EOF"

ssh root@$SERVER_IP "chmod +x $SERVER_DIR/start.sh"

# Test packwiz-installer
echo -e "${YELLOW}Testing modpack installation...${NC}"
ssh root@$SERVER_IP "cd $SERVER_DIR && java -jar packwiz-installer.jar -g -s server $PACK_URL"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Modpack installed successfully!${NC}"
else
    echo -e "${YELLOW}⚠ Check server for errors${NC}"
fi

# Start the server
echo -e "${BLUE}Starting Minecraft server...${NC}"
ssh root@$SERVER_IP "systemctl start minecraft"

echo ""
echo -e "${GREEN}Deployment complete!${NC}"
echo ""
echo -e "${BLUE}How to update the modpack:${NC}"
echo "1. Make changes locally in modpack/"
echo "2. Run: cd modpack && ~/go/bin/packwiz refresh"
echo "3. Commit and push: git add . && git commit -m 'Update' && git push"
echo "4. Restart server: ssh root@$SERVER_IP 'systemctl restart minecraft'"
echo ""
echo "The server will automatically download updates on each restart!"