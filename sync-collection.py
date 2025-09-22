#!/usr/bin/env python3
"""
Sync Modrinth collection with packwiz modpack.
This script fetches mods from a Modrinth collection and adds them to packwiz.
"""

import json
import urllib.request
import subprocess
import os
import sys
import time

# Configuration
COLLECTION_ID = "Fcn87KFP"  # Your "1.21.1 final" collection
PACKWIZ_PATH = os.path.expanduser("~/go/bin/packwiz")  # Adjust if packwiz is elsewhere

def get_collection_mods(collection_id):
    """Fetch all project IDs from a Modrinth collection."""
    print(f"Fetching collection {collection_id}...")
    url = f"https://api.modrinth.com/v3/collection/{collection_id}"

    try:
        with urllib.request.urlopen(url) as response:
            data = json.loads(response.read())
            print(f"Found collection: {data['name']}")
            return data['projects']
    except Exception as e:
        print(f"Error fetching collection: {e}")
        return []

def get_mod_slug(project_id):
    """Get the slug for a project ID."""
    url = f"https://api.modrinth.com/v2/project/{project_id}"

    try:
        with urllib.request.urlopen(url) as response:
            data = json.loads(response.read())
            return data['slug'], data['title']
    except Exception as e:
        print(f"Error fetching project {project_id}: {e}")
        return None, None

def check_mod_installed(slug):
    """Check if a mod is already installed in packwiz."""
    mod_file = f"mods/{slug}.pw.toml"
    return os.path.exists(mod_file)

def install_mod(slug, title):
    """Install a mod using packwiz."""
    if check_mod_installed(slug):
        print(f"  ✓ {slug} ({title}) - already installed")
        return True

    print(f"  → Installing {slug} ({title})...")
    try:
        # Run packwiz modrinth install command
        result = subprocess.run(
            [PACKWIZ_PATH, "modrinth", "install", slug, "--yes"],
            capture_output=True,
            text=True,
            timeout=30
        )

        if result.returncode == 0:
            print(f"  ✓ {slug} ({title}) - installed successfully")
            return True
        else:
            print(f"  ✗ {slug} ({title}) - failed: {result.stderr}")
            return False
    except subprocess.TimeoutExpired:
        print(f"  ✗ {slug} ({title}) - timeout")
        return False
    except Exception as e:
        print(f"  ✗ {slug} ({title}) - error: {e}")
        return False

def main():
    # Check if we're in the right directory
    if not os.path.exists("pack.toml"):
        print("Error: pack.toml not found. Please run this from your packwiz modpack directory.")
        sys.exit(1)

    # Check if packwiz is available
    if not os.path.exists(PACKWIZ_PATH):
        print(f"Error: packwiz not found at {PACKWIZ_PATH}")
        print("Please install packwiz or update the PACKWIZ_PATH variable.")
        sys.exit(1)

    # Get mods from collection
    project_ids = get_collection_mods(COLLECTION_ID)
    if not project_ids:
        print("No mods found in collection.")
        sys.exit(1)

    print(f"\nFound {len(project_ids)} mods in collection")
    print("=" * 50)

    # Process each mod
    successful = 0
    failed = 0
    skipped = 0

    for i, project_id in enumerate(project_ids, 1):
        slug, title = get_mod_slug(project_id)
        if not slug:
            print(f"{i}/{len(project_ids)}: Failed to get info for {project_id}")
            failed += 1
            continue

        print(f"\n{i}/{len(project_ids)}: Processing {slug}")

        if check_mod_installed(slug):
            print(f"  ✓ Already installed")
            skipped += 1
        else:
            if install_mod(slug, title):
                successful += 1
            else:
                failed += 1

        # Small delay to be nice to the API
        time.sleep(0.1)

    # Refresh packwiz index
    print("\n" + "=" * 50)
    print("Refreshing packwiz index...")
    subprocess.run([PACKWIZ_PATH, "refresh"], capture_output=True)

    # Summary
    print("\n" + "=" * 50)
    print("SYNC COMPLETE")
    print(f"  Successful: {successful}")
    print(f"  Skipped (already installed): {skipped}")
    print(f"  Failed: {failed}")
    print(f"  Total: {len(project_ids)}")

if __name__ == "__main__":
    main()