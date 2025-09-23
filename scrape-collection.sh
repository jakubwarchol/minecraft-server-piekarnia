#!/bin/bash

# Script to scrape Modrinth collection and fetch all project details
# Usage: ./scrape-collection.sh <collection-url>
# Example: ./scrape-collection.sh https://modrinth.com/collection/Fcn87KFP

set -e

# Check if URL parameter is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <collection-url>"
    echo "Example: $0 https://modrinth.com/collection/Fcn87KFP"
    exit 1
fi

COLLECTION_URL="$1"
COLLECTION_ID=$(echo "$COLLECTION_URL" | grep -o '[^/]*$')

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}Scraping Modrinth Collection: $COLLECTION_ID${NC}"
echo "URL: $COLLECTION_URL"
echo "=========================================="

# Step 1: Scrape HTML and extract project IDs
echo -e "${YELLOW}Step 1: Extracting project IDs from HTML...${NC}"

curl -s "$COLLECTION_URL" | python3 -c "
import re
import sys
import json

html = sys.stdin.read()

# Look for all project types
project_links = {}
href_pattern = r'href=\"([^\"]+)\"'
all_hrefs = re.findall(href_pattern, html)

for href in all_hrefs:
    if href.startswith('/mod/'):
        project_links.setdefault('mod', []).append(href[5:])
    elif href.startswith('/resourcepack/'):
        project_links.setdefault('resourcepack', []).append(href[14:])
    elif href.startswith('/datapack/'):
        project_links.setdefault('datapack', []).append(href[10:])
    elif href.startswith('/plugin/'):
        project_links.setdefault('plugin', []).append(href[8:])
    elif href.startswith('/shader/'):
        project_links.setdefault('shader', []).append(href[8:])
    elif href.startswith('/modpack/'):
        project_links.setdefault('modpack', []).append(href[9:])

# Deduplicate and filter
all_project_ids = set()
project_types = {}

for ptype, links in project_links.items():
    for link in set(links):
        # Skip sub-paths and empty links
        if '/' in link or not link:
            continue
        all_project_ids.add(link)
        project_types[link] = ptype

# Remove navigation elements
nav_terms = ['settings', 'login', 'create', 'search', 'collections', 'following']
all_project_ids = {pid for pid in all_project_ids if pid not in nav_terms}

# Sort and save
final_ids = sorted(list(all_project_ids))

print(f'Found {len(final_ids)} projects')
for ptype in set(project_types.values()):
    count = sum(1 for pid in final_ids if project_types.get(pid) == ptype)
    print(f'  {ptype}: {count}')

# Save to JSON file
with open('project_ids.json', 'w') as f:
    json.dump(final_ids, f, indent=2)

print(f'Saved {len(final_ids)} project IDs to project_ids.json')
"

if [ ! -f "project_ids.json" ]; then
    echo -e "${RED}Failed to extract project IDs${NC}"
    exit 1
fi

PROJECT_COUNT=$(python3 -c "import json; print(len(json.load(open('project_ids.json'))))")
echo -e "${GREEN}✓ Extracted $PROJECT_COUNT project IDs${NC}"

# Step 2: Fetch project details from Modrinth API
echo ""
echo -e "${YELLOW}Step 2: Fetching project details from Modrinth API...${NC}"

python3 << 'EOF'
import json
import urllib.request
import urllib.parse
import sys

# Load project IDs
with open('project_ids.json', 'r') as f:
    project_ids = json.load(f)

print(f'Fetching details for {len(project_ids)} projects...')

# Prepare API request
ids_param = json.dumps(project_ids)
url = 'https://api.modrinth.com/v2/projects?ids=' + urllib.parse.quote(ids_param)

req = urllib.request.Request(url)
req.add_header('User-Agent', 'ModpackManager/1.0 (scrape-collection)')

try:
    # Fetch from API
    with urllib.request.urlopen(req) as response:
        projects = json.load(response)

    print(f'Successfully fetched {len(projects)} projects from API')

    # Process and organize results
    results = {
        'collection_id': sys.argv[1] if len(sys.argv) > 1 else 'unknown',
        'total': len(projects),
        'mods': [],
        'resourcepacks': [],
        'datapacks': [],
        'plugins': [],
        'shaders': [],
        'modpacks': []
    }

    # Categorize projects
    for project in projects:
        slug = project.get('slug', '')
        title = project.get('title', '')
        project_type = project.get('project_type', '')

        project_info = {
            'slug': slug,
            'title': title,
            'id': project.get('id', ''),
            'description': project.get('description', '')[:100] + '...' if project.get('description') else ''
        }

        if project_type == 'mod':
            results['mods'].append(project_info)
        elif project_type == 'resourcepack':
            results['resourcepacks'].append(project_info)
        elif project_type == 'datapack':
            results['datapacks'].append(project_info)
        elif project_type == 'plugin':
            results['plugins'].append(project_info)
        elif project_type == 'shader':
            results['shaders'].append(project_info)
        elif project_type == 'modpack':
            results['modpacks'].append(project_info)

    # Sort each category by slug
    for category in ['mods', 'resourcepacks', 'datapacks', 'plugins', 'shaders', 'modpacks']:
        results[category].sort(key=lambda x: x['slug'])

    # Save full results
    with open('collection_projects.json', 'w') as f:
        json.dump(results, f, indent=2)

    # Create simple slugs list for mods only
    mod_slugs = [mod['slug'] for mod in results['mods']]
    with open('collection_mod_slugs.txt', 'w') as f:
        for slug in mod_slugs:
            f.write(f'{slug}\n')

    # Create markdown documentation
    with open('collection_projects.md', 'w') as f:
        f.write(f'# Modrinth Collection Projects\n')
        f.write(f'Collection ID: {results["collection_id"]}\n')
        f.write(f'Total Projects: {results["total"]}\n\n')

        # Write each category
        categories = [
            ('mods', 'Mods'),
            ('resourcepacks', 'Resource Packs'),
            ('datapacks', 'Data Packs'),
            ('plugins', 'Plugins'),
            ('shaders', 'Shaders'),
            ('modpacks', 'Modpacks')
        ]

        for key, name in categories:
            if results[key]:
                f.write(f'## {name} ({len(results[key])})\n\n')
                for item in results[key]:
                    f.write(f'- **{item["title"]}** (`{item["slug"]}`)\n')
                    if item['description']:
                        f.write(f'  {item["description"]}\n')
                f.write('\n')

    # Print summary
    print('\nSummary:')
    print('-' * 40)
    print(f'Total projects: {results["total"]}')
    for key, name in categories:
        if results[key]:
            print(f'  {name}: {len(results[key])}')

    print('\nFiles created:')
    print('  - collection_projects.json (full details)')
    print('  - collection_projects.md (markdown documentation)')
    print('  - collection_mod_slugs.txt (mod slugs only)')

except urllib.error.HTTPError as e:
    print(f'API Error: {e.code} - {e.reason}')
    sys.exit(1)
except Exception as e:
    print(f'Error: {e}')
    sys.exit(1)
EOF

# Pass collection ID to Python script
python3 -c "import sys; sys.argv.append('$COLLECTION_ID'); exec(open('/dev/stdin').read())" < /dev/null

echo ""
echo -e "${GREEN}✓ Collection scraping complete!${NC}"
echo ""
echo -e "${BLUE}Output files:${NC}"
echo "  • project_ids.json - Raw project IDs"
echo "  • collection_projects.json - Full project details"
echo "  • collection_projects.md - Human-readable documentation"
echo "  • collection_mod_slugs.txt - List of mod slugs for packwiz"