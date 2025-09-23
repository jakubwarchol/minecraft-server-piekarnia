#!/usr/bin/env python3
import urllib.request
import re

# Project IDs from the collection page
project_ids = """1IjD5062
20p2kirx
3JQDJrYW
4I1XuqiY
4XJZeZbM
4q8UOK1d
5ZwdcRci
5sy6g3kz
7vxePowz
8YcE8y4T
9rlXSyLg
AAiRU4aQ
B8jaH3P1
BVzZfTc1
C7I0BCni
Cnejf5xM
DjLobEOy
Eh11TaTm
EsAfCjCV
FNi5IMiX
FOiJ92uI
GmwLse2I
GyKzAh3l
HJetCzWo
Heh3BbSv
HjmxVlSr
Ht4BfYp6
KuNKN7d2
LOpKHB2A
LTTvOp5L
NNAgCjsB
NcUtCpym
O7RBXm3n
SaCpeal4
VRLhWB91
XNlO7sBv
XZNI4Cpy
XpzGz7KD
YhmgMVyu
Z2mXHnxP
ZouiUX7t
aC3cM3Vq
b7NV2plI
cloth-config
dCCkNFwE
dxa0Bm8m
fFEIiSDQ
fM515JnW
fnAffV0n
gvQqBUqZ
iDyqnQLT
iP3wH1ha
jawg7zT1
jfvCMH0K
kNxa8z3e
kidLKymU
mSQF1NpT
nrikgvxm
o1C1Dkj5
oNB5jhlA
qIv5FhAA
qpPoAL6m
qwbArkQk
t5FRdP87
u6dRKJwZ
uCdwusMi
w4an97C2
w7ThoJFB
x02cBj9Y
z9Ve58Ih
znHQQtuU""".strip().split('\n')

print(f"Resolving {len(project_ids)} project IDs to slugs...")
print("=" * 50)

slugs = []
failed = []

for i, project_id in enumerate(project_ids, 1):
    try:
        # Use HEAD request to get redirect without downloading full page
        url = f"https://modrinth.com/mod/{project_id}"
        req = urllib.request.Request(url, method='HEAD')
        req.add_header('User-Agent', 'Mozilla/5.0')
        
        with urllib.request.urlopen(req) as response:
            final_url = response.geturl()
            # Extract slug from final URL
            match = re.search(r'/mod/([^/?#]+)', final_url)
            if match:
                slug = match.group(1)
                if slug != project_id:  # Only if it resolved to a different slug
                    slugs.append(slug)
                    print(f"[{i:2}/{len(project_ids)}] {project_id} → {slug}")
                else:
                    slugs.append(slug)
                    print(f"[{i:2}/{len(project_ids)}] {slug} (already a slug)")
            else:
                failed.append(project_id)
                print(f"[{i:2}/{len(project_ids)}] {project_id} → FAILED to extract")
    except Exception as e:
        # If HEAD fails, try GET
        try:
            url = f"https://modrinth.com/mod/{project_id}"
            req = urllib.request.Request(url)
            req.add_header('User-Agent', 'Mozilla/5.0')
            
            with urllib.request.urlopen(req) as response:
                final_url = response.geturl()
                match = re.search(r'/mod/([^/?#]+)', final_url)
                if match:
                    slug = match.group(1)
                    slugs.append(slug)
                    print(f"[{i:2}/{len(project_ids)}] {project_id} → {slug}")
                else:
                    failed.append(project_id)
                    print(f"[{i:2}/{len(project_ids)}] {project_id} → FAILED")
        except:
            failed.append(project_id)
            print(f"[{i:2}/{len(project_ids)}] {project_id} → ERROR")

print()
print(f"Successfully resolved: {len(slugs)}")
print(f"Failed: {len(failed)}")

# Save to file
with open('collection_slugs.md', 'w') as f:
    f.write('# Modrinth Collection Fcn87KFP - Resolved Slugs\n')
    f.write(f'# Total: {len(slugs)} mods\n\n')
    for slug in sorted(slugs):
        f.write(f'{slug}\n')

print(f"\nSaved {len(slugs)} slugs to collection_slugs.md")

if failed:
    print(f"\nFailed to resolve: {', '.join(failed)}")
