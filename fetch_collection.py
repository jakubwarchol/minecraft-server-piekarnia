#!/usr/bin/env python3
import urllib.request
import json

# Fetch collection
url = "https://api.modrinth.com/v2/collection/Fcn87KFP"
req = urllib.request.Request(url, headers={'User-Agent': 'ModpackManager/1.0'})

with urllib.request.urlopen(req) as response:
    collection_data = json.load(response)
    
print(f"Collection: {collection_data.get('name', 'Unknown')}")
print(f"Description: {collection_data.get('description', 'No description')}")
print(f"Total mods: {len(collection_data.get('projects', []))}")
print()

project_ids = collection_data.get('projects', [])

if project_ids:
    # Fetch all project details in bulk
    ids_json = json.dumps(project_ids)
    projects_url = f"https://api.modrinth.com/v2/projects?ids={urllib.parse.quote(ids_json)}"
    req = urllib.request.Request(projects_url, headers={'User-Agent': 'ModpackManager/1.0'})
    
    with urllib.request.urlopen(req) as response:
        projects = json.load(response)
    
    # Sort by slug
    projects.sort(key=lambda x: x.get('slug', ''))
    
    print("All mod slugs from collection:")
    print("=" * 50)
    
    slugs = []
    for project in projects:
        slug = project.get('slug', 'unknown')
        title = project.get('title', 'Unknown')
        slugs.append(slug)
        print(f"{slug}")
    
    print()
    print(f"Total: {len(slugs)} mods")
    
    # Save to mods.md
    with open('mods_from_collection.md', 'w') as f:
        f.write("# Modrinth Collection Mods\n")
        f.write(f"# Collection ID: Fcn87KFP\n")
        f.write(f"# Total mods: {len(slugs)}\n\n")
        for slug in slugs:
            f.write(f"{slug}\n")
    
    print()
    print("Saved to mods_from_collection.md")
