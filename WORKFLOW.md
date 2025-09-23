# Minecraft Server Piekarnia - Complete Workflow Guide

## Overview
This repository manages a Minecraft 1.21.1 Fabric server with automated modpack deployment using packwiz and GitHub.

## Architecture
```
Local Development → GitHub Repository → Minecraft Server
     (packwiz)        (version control)    (auto-update)
```

## Quick Commands

### Daily Operations
```bash
# Check for mod updates
./check-updates.sh

# Deploy changes to server
./deploy.sh

# Export modpack for players
./export-client.sh

# View server status
./deploy.sh status

# View server logs
./deploy.sh logs
```

## Initial Setup (Already Complete)

### 1. Server Setup
- Server IP: 91.98.39.164
- Minecraft 1.21.1 with Fabric 0.17.2
- 6GB RAM allocation
- Automated modpack updates via packwiz-installer-bootstrap

### 2. Local Environment
- Packwiz installed via Go
- GitHub repository: jakubwarchol/minecraft-server-piekarnia
- Modrinth collection: Fcn87KFP (89 mods)

## Workflow Details

### Adding New Mods

#### From Modrinth Collection
1. Check collection for new mods:
```bash
./check-updates.sh collection
```

2. Add specific mod:
```bash
cd modpack
~/go/bin/packwiz modrinth install <mod-slug>
```

3. Deploy to server:
```bash
./deploy.sh
```

#### Manual Addition
```bash
cd modpack
~/go/bin/packwiz modrinth install <mod-name>
# or
~/go/bin/packwiz curseforge install <mod-name>
```

### Updating Mods

#### Update All Mods
```bash
./check-updates.sh update
./deploy.sh
```

#### Update Specific Mod
```bash
cd modpack
~/go/bin/packwiz update <mod-name>
~/go/bin/packwiz refresh
cd ..
./deploy.sh
```

### Removing Mods
```bash
cd modpack
~/go/bin/packwiz remove <mod-name>
~/go/bin/packwiz refresh
cd ..
./deploy.sh
```

### Editing Mod Configurations

1. Edit config files locally:
```bash
cd modpack/config
# Edit configuration files
```

2. Deploy changes:
```bash
./deploy.sh
```

### Client Distribution

#### Generate All Formats
```bash
./export-client.sh
```

This creates:
- `client-export/piekarnia-modpack-curseforge.zip` - For CurseForge launcher
- `client-export/piekarnia-modpack.mrpack` - For Prism/MultiMC launcher
- `client-export/piekarnia-modpack-manual.zip` - For manual installation

#### Share with Players
1. Upload files to Discord/Google Drive/etc
2. Share `INSTALLATION.md` for setup instructions
3. Server IP: 91.98.39.164

## Script Descriptions

### deploy.sh
Main deployment script with:
- Prerequisite checking
- Automatic packwiz refresh
- Git commit and push
- Server backup creation
- Safe server restart
- Rollback capability

Usage:
```bash
./deploy.sh [deploy|status|logs|backup]
```

### check-updates.sh
Mod update checker with:
- Packwiz update detection
- Modrinth collection sync check
- Compatibility verification
- Update report generation

Usage:
```bash
./check-updates.sh [all|packwiz|collection|compatibility|update]
```

### export-client.sh
Client modpack exporter with:
- CurseForge format export
- Modrinth/Prism format export
- Manual installation pack
- Installation instructions

Usage:
```bash
./export-client.sh [all|curseforge|modrinth|manual]
```

## Troubleshooting

### Server Won't Start
1. Check logs: `./deploy.sh logs`
2. Look for mod conflicts or missing dependencies
3. Restore backup if needed:
```bash
ssh root@91.98.39.164 'cd /opt/minecraft && tar -xzf backup-[timestamp].tar.gz'
```

### Mod Compatibility Issues
1. Check if mod supports 1.21.1 Fabric
2. Verify all dependencies installed:
```bash
cd modpack
~/go/bin/packwiz refresh
```
3. Remove problematic mod:
```bash
~/go/bin/packwiz remove <mod-name>
```

### Git Push Failures
```bash
git pull origin main --no-edit
git push origin main
```

### Packwiz Command Not Found
```bash
# Use full path
~/go/bin/packwiz [command]

# Or add to PATH
echo 'export PATH=$PATH:~/go/bin' >> ~/.zshrc
source ~/.zshrc
```

## Best Practices

### Before Major Changes
1. Create server backup: `./deploy.sh backup`
2. Test in local instance first
3. Check mod compatibility

### Regular Maintenance
1. Weekly: Check for mod updates
2. Before adding mods: Check server performance
3. After updates: Test server stability

### Version Control
- Commit message format: "Update modpack - [description]"
- Always run `packwiz refresh` before committing
- Keep mods.md updated with collection changes

## File Structure
```
minecraft-server-piekarnia/
├── modpack/                 # Packwiz modpack
│   ├── pack.toml           # Pack metadata
│   ├── index.toml          # Mod index
│   ├── mods/               # Mod metadata files
│   └── config/             # Mod configurations
├── client-export/          # Exported modpacks
├── deploy.sh               # Deployment script
├── check-updates.sh        # Update checker
├── export-client.sh        # Client exporter
├── mods.md                 # Modrinth collection list
└── WORKFLOW.md            # This file
```

## Server Details
- **Location**: Hetzner Cloud
- **IP**: 91.98.39.164
- **Minecraft**: 1.21.1
- **Loader**: Fabric 0.17.2
- **RAM**: 6GB
- **Auto-update**: Yes (on restart)

## Support Channels
- GitHub Issues: For technical problems
- Discord: For player support
- Direct SSH: For emergency fixes

## Security Notes
- Never commit server passwords
- Keep backups before major changes
- Test updates locally first
- Monitor server performance

Last Updated: $(date)