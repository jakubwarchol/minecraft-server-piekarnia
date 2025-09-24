#!/usr/bin/env python3
import json
import sys
import urllib.request
import urllib.parse
from pathlib import Path

def create_modpack_on_modrinth(token, mrpack_file):
    """Create a new modpack project on Modrinth and upload the initial version"""
    
    # Read the pack.toml to get metadata
    with open('pack.toml', 'r') as f:
        pack_content = f.read()
    
    # Extract basic info (simple parsing)
    name = "Piekarnia Modpack"
    slug = "piekarnia-modpack"
    description = "A curated Minecraft 1.21.1 Fabric modpack with 97 mods for enhanced gameplay"
    
    print("Creating modpack on Modrinth...")
    print(f"Name: {name}")
    print(f"Slug: {slug}")
    
    # Step 1: Create the project
    project_data = {
        "title": name,
        "slug": slug,
        "description": description,
        "body": """# Piekarnia Modpack

A carefully curated Minecraft 1.21.1 Fabric modpack featuring 97 mods for an enhanced survival experience.

## Features
- **World Generation**: Terralith, Incendium, Stellarity, YUNG's Better structures
- **Quality of Life**: Waystones, Tom's Storage, Sophisticated Backpacks
- **Visual Enhancements**: Fresh Animations, Entity Texture Features, Continuity
- **Gameplay**: Better Combat, Farmer's Delight, Let's Do series mods
- **Performance**: Lithium, ImmediatelyFast, Entity Culling

## Server
Join our server at: `91.98.39.164`

## Installation
1. Download and install this modpack through Modrinth launcher
2. Launch the game
3. Join the server!

## Mod List
Includes popular mods like:
- The Aether
- Deeper and Darker
- Supplementaries
- Farmer's Delight and addons
- YUNG's Better structures series
- And many more!
""",
        "categories": ["adventure", "decoration", "food", "optimization", "worldgen"],
        "client_side": "required",
        "server_side": "required",
        "project_type": "modpack",
        "license_id": "MIT",
        "game_versions": ["1.21.1"],
        "loaders": ["fabric"],
        "initial_versions": []
    }
    
    # Prepare the API request
    url = "https://api.modrinth.com/v2/project"
    data = json.dumps(project_data).encode('utf-8')
    
    req = urllib.request.Request(url, data=data, method='POST')
    req.add_header('Authorization', token)
    req.add_header('Content-Type', 'application/json')
    req.add_header('User-Agent', 'PiekarniaModpackUploader/1.0')
    
    try:
        with urllib.request.urlopen(req) as response:
            result = json.load(response)
            project_id = result['id']
            print(f"✓ Project created successfully!")
            print(f"  Project ID: {project_id}")
            print(f"  URL: https://modrinth.com/modpack/{slug}")
            return project_id, slug
    except urllib.error.HTTPError as e:
        if e.code == 400:
            # Project might already exist
            print(f"Project might already exist or validation error")
            error_body = e.read().decode('utf-8')
            print(f"Error: {error_body}")
            
            # Try to get existing project
            check_url = f"https://api.modrinth.com/v2/project/{slug}"
            check_req = urllib.request.Request(check_url)
            check_req.add_header('Authorization', token)
            check_req.add_header('User-Agent', 'PiekarniaModpackUploader/1.0')
            
            try:
                with urllib.request.urlopen(check_req) as response:
                    result = json.load(response)
                    print(f"Found existing project: {result['id']}")
                    return result['id'], slug
            except:
                sys.exit(1)
        else:
            print(f"HTTP Error: {e.code} - {e.reason}")
            print(e.read().decode('utf-8'))
            sys.exit(1)

def upload_version(token, project_id, mrpack_file):
    """Upload a new version of the modpack"""
    
    print(f"\nUploading version to project {project_id}...")
    
    # Read the mrpack file
    with open(mrpack_file, 'rb') as f:
        file_data = f.read()
    
    # Create multipart form data
    boundary = '----WebKitFormBoundary7MA4YWxkTrZu0gW'
    
    # Build the multipart body
    body_parts = []
    
    # Add JSON data
    version_data = {
        "name": "1.0.0",
        "version_number": "1.0.0",
        "changelog": "Initial release with 97 mods",
        "dependencies": [],
        "game_versions": ["1.21.1"],
        "version_type": "release",
        "loaders": ["fabric"],
        "featured": True,
        "project_id": project_id,
        "file_parts": ["piekarnia-modpack.mrpack"]
    }
    
    # Add data field
    body_parts.append(f'--{boundary}')
    body_parts.append('Content-Disposition: form-data; name="data"')
    body_parts.append('Content-Type: application/json')
    body_parts.append('')
    body_parts.append(json.dumps(version_data))
    
    # Add file field
    body_parts.append(f'--{boundary}')
    body_parts.append(f'Content-Disposition: form-data; name="file_parts"; filename="piekarnia-modpack.mrpack"')
    body_parts.append('Content-Type: application/octet-stream')
    body_parts.append('')
    
    # Join text parts and encode
    text_part = '\r\n'.join(body_parts).encode('utf-8')
    
    # Add file data
    end_boundary = f'\r\n--{boundary}--\r\n'.encode('utf-8')
    
    body = text_part + b'\r\n' + file_data + end_boundary
    
    # Make request
    url = "https://api.modrinth.com/v2/version"
    req = urllib.request.Request(url, data=body, method='POST')
    req.add_header('Authorization', token)
    req.add_header('Content-Type', f'multipart/form-data; boundary={boundary}')
    req.add_header('User-Agent', 'PiekarniaModpackUploader/1.0')
    
    try:
        with urllib.request.urlopen(req) as response:
            result = json.load(response)
            print(f"✓ Version uploaded successfully!")
            print(f"  Version ID: {result['id']}")
            print(f"  Version: {result['version_number']}")
            print(f"  Downloads: {result['downloads']}")
    except urllib.error.HTTPError as e:
        print(f"HTTP Error: {e.code} - {e.reason}")
        print(e.read().decode('utf-8'))
        sys.exit(1)

# Main execution
if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 upload_to_modrinth.py <MODRINTH_TOKEN>")
        sys.exit(1)
    
    token = sys.argv[1]
    mrpack_file = "Piekarnia Modpack-1.0.0.mrpack"
    
    # Check if file exists
    if not Path(mrpack_file).exists():
        print(f"Error: {mrpack_file} not found")
        sys.exit(1)
    
    print("=" * 50)
    print("Modrinth Modpack Uploader")
    print("=" * 50)
    
    # Create project and upload version
    project_id, slug = create_modpack_on_modrinth(token, mrpack_file)
    upload_version(token, project_id, mrpack_file)
    
    print("\n" + "=" * 50)
    print("✓ Upload complete!")
    print(f"View your modpack at: https://modrinth.com/modpack/{slug}")
    print("Share this link with your friends!")
