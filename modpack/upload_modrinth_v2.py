#!/usr/bin/env python3
import json
import sys
import os

def upload_to_modrinth(token, mrpack_file):
    """Upload modpack to Modrinth using curl command"""
    
    # Prepare the version data
    version_data = {
        "name": "1.0.0",
        "version_number": "1.0.0",
        "changelog": """Initial release of Piekarnia Modpack
        
- 97 carefully selected mods
- Enhanced world generation (Terralith, Incendium, Stellarity)
- Quality of life improvements
- Performance optimizations
- Server IP: 91.98.39.164""",
        "dependencies": [],
        "game_versions": ["1.21.1"],
        "version_type": "release",
        "loaders": ["fabric"],
        "featured": True,
        "status": "listed",
        "requested_status": "listed",
        "project_id": "piekarnia-modpack",
        "file_parts": ["primary.mrpack"],
        "primary_file": "primary.mrpack"
    }
    
    # First, let's try to create the project
    project_data = {
        "slug": "piekarnia-modpack",
        "title": "Piekarnia Modpack",
        "description": "A curated Minecraft 1.21.1 Fabric modpack with enhanced gameplay",
        "body": """# Piekarnia Modpack

A carefully curated Minecraft 1.21.1 Fabric modpack featuring 97 mods for an enhanced survival experience.

## Server IP: 91.98.39.164

## Features
- World Generation: Terralith, Incendium, Stellarity, YUNG's Better structures
- Quality of Life: Waystones, Tom's Storage, Sophisticated Backpacks
- Visual Enhancements: Fresh Animations, Entity Texture Features, Continuity
- Gameplay: Better Combat, Farmer's Delight, Let's Do series mods
- Performance: Lithium, ImmediatelyFast, Entity Culling""",
        "categories": ["adventure", "decoration", "optimization"],
        "client_side": "required",
        "server_side": "required",
        "project_type": "modpack",
        "license_id": "LicenseRef-All-Rights-Reserved",
        "game_versions": ["1.21.1"],
        "loaders": ["fabric"]
    }
    
    # Save project data to file
    with open('project_data.json', 'w') as f:
        json.dump(project_data, f)
    
    # Save version data to file
    with open('version_data.json', 'w') as f:
        json.dump(version_data, f)
    
    print("Creating/updating project on Modrinth...")
    
    # Use curl to create project
    curl_cmd = f'''curl -X POST https://api.modrinth.com/v2/project \
        -H "Authorization: {token}" \
        -H "Content-Type: application/json" \
        -H "User-Agent: PiekarniaUploader/1.0" \
        -d @project_data.json'''
    
    result = os.system(curl_cmd)
    
    print("\n\nNow uploading the modpack file...")
    
    # Use curl to upload version with file
    curl_upload = f'''curl -X POST https://api.modrinth.com/v2/version \
        -H "Authorization: {token}" \
        -H "User-Agent: PiekarniaUploader/1.0" \
        -F 'data={json.dumps(version_data)}' \
        -F 'primary.mrpack=@{mrpack_file}'
    '''
    
    print("Executing upload command...")
    result = os.system(curl_upload)
    
    if result == 0:
        print("\n✓ Upload successful!")
        print("Visit: https://modrinth.com/modpack/piekarnia-modpack")
    else:
        print("\nUpload may have failed. Check the output above.")

if __name__ == "__main__":
    token = sys.argv[1] if len(sys.argv) > 1 else None
    if not token:
        print("Please provide Modrinth token")
        sys.exit(1)
    
    mrpack = "Piekarnia Modpack-1.0.0.mrpack"
    if not os.path.exists(mrpack):
        print(f"File not found: {mrpack}")
        sys.exit(1)
    
    upload_to_modrinth(token, mrpack)
