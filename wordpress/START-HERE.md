# Quick Start Guide for WordPress Multisite Migration

## Current Status ✅

**VPS is ready!** (91.98.39.164)
- ✅ Ubuntu 24.04 LTS
- ✅ Docker 28.5.1 installed
- ✅ Docker Compose v2.40.1 installed
- ✅ Firewall configured (ports 22, 80, 443, 25565)
- ✅ Directory `/opt/wordpress/` created
- ✅ Minecraft server still running (untouched)

## What We're Doing

Migrating WordPress Multisite with structure change:
- **Current**: dscp.team + dscp.team/daily (subdirectory)
- **Target**: dscp.team + daily.dscp.team (subdomain)

---

## Your Step-by-Step Checklist

### Step 1: Get Repo Access & Upload Configs
```bash
# Clone this repo
git clone <repo-url>
cd minecraft-server-piekarnia/wordpress

# Upload all config files to VPS
scp -r . root@91.98.39.164:/opt/wordpress/
```

### Step 2: Configure Environment Variables
```bash
# SSH into VPS
ssh root@91.98.39.164
cd /opt/wordpress

# Create .env from example
cp .env.example .env
nano .env
```

Fill in:
```env
MYSQL_ROOT_PASSWORD=<generate-strong-password>
MYSQL_DATABASE=wordpress
MYSQL_USER=wordpress_user
MYSQL_PASSWORD=<generate-strong-password>

MAIN_DOMAIN=dscp.team
SUB_DOMAIN=daily.dscp.team

LETSENCRYPT_EMAIL=your-email@example.com
```

Generate passwords with: `openssl rand -base64 32`

### Step 3: Get WordPress Backup from Current Server

You need:
1. **Database dump**: `wordpress-multisite-backup.sql`
2. **WordPress files**: `wordpress-multisite-files.tar.gz`

See section in MULTISITE-MIGRATION.md on how to export these.

### Step 4: Upload Backup Files to VPS
```bash
# From your local machine
scp wordpress-multisite-backup.sql root@91.98.39.164:/opt/wordpress/temp-files/
scp wordpress-multisite-files.tar.gz root@91.98.39.164:/opt/wordpress/temp-files/
```

### Step 5: Follow the Main Migration Guide

**Open and follow: [MULTISITE-MIGRATION.md](MULTISITE-MIGRATION.md)**

This is the complete guide covering:
- Part 3: Import & Configure Multisite
- Part 4: Convert Database (subdirectory → subdomain)
- Part 5: Start & Test
- Part 6: DNS Configuration
- Part 7: Enable SSL

**Helper script available:** `convert-subdirectory-to-subdomain.sql`

---

## Key Files Reference

| File | Purpose |
|------|---------|
| **START-HERE.md** | This file - quick start guide |
| **MULTISITE-MIGRATION.md** | 📖 **Main migration guide** - follow this! |
| **convert-subdirectory-to-subdomain.sql** | SQL helper script for conversion |
| **PREP-NOW.md** | VPS prep steps (already done) |
| **docker-compose.yml** | Container orchestration |
| **.env.example** | Environment variables template |
| **nginx/conf.d/wordpress.conf** | Web server config for both domains |
| **SETUP.md** | Docker/VPS setup reference |
| **SSL-SETUP.md** | SSL configuration details |

---

## Quick Commands Reference

```bash
# SSH into VPS
ssh root@91.98.39.164

# Navigate to WordPress directory
cd /opt/wordpress

# View logs
docker compose logs -f

# Check running containers
docker compose ps

# Start containers
docker compose up -d

# Stop containers
docker compose down

# Access MySQL
docker compose exec mysql mysql -u root -p

# Access WordPress CLI
docker compose exec wordpress wp --allow-root [command]
```

---

## Important Notes

### About the Conversion
- Current multisite uses **subdirectory** structure (SUBDOMAIN_INSTALL=false)
- We're converting to **subdomain** structure (SUBDOMAIN_INSTALL=true)
- SQL script handles URL updates in database
- wp-config.php must be updated manually

### DNS Records Needed (Later)
When you have domain access:
```
Type: A
Name: @
Value: 91.98.39.164

Type: A
Name: daily
Value: 91.98.39.164
```

### Testing Before DNS
You can test via IP before DNS is configured:
```bash
curl -H "Host: dscp.team" http://91.98.39.164
curl -H "Host: daily.dscp.team" http://91.98.39.164
```

Or add to local `/etc/hosts`:
```
91.98.39.164 dscp.team
91.98.39.164 daily.dscp.team
```

---

## Troubleshooting

### If containers won't start:
```bash
docker compose logs
```

### If database connection fails:
Check .env passwords match what you configured.

### If site redirects incorrectly:
Check wp_blogs table and wp-config.php multisite settings.

### If stuck:
Read the detailed troubleshooting sections in MULTISITE-MIGRATION.md

---

## Support Resources

- **Full Migration Guide**: MULTISITE-MIGRATION.md (start here!)
- **SQL Helper**: convert-subdirectory-to-subdomain.sql
- **Docker Commands**: SETUP.md
- **SSL Setup**: SSL-SETUP.md

---

## Workflow Summary

```
1. Upload configs → 2. Configure .env → 3. Get backups from current server
        ↓
4. Upload backups → 5. Import DB → 6. Extract files → 7. Update wp-config.php
        ↓
8. Run SQL conversion → 9. Start containers → 10. Test via IP
        ↓
11. Configure DNS (when ready) → 12. Enable SSL → 13. Done! 🎉
```

---

## Current VPS State

- **IP**: 91.98.39.164
- **OS**: Ubuntu 24.04 LTS
- **RAM**: 15GB (4.4GB available)
- **Disk**: 75GB (66GB available)
- **Docker**: Ready
- **Ports Open**: 22, 80, 443, 25565
- **Minecraft**: Running on port 25565 (don't touch it!)

---

**Ready to start?** → Open **MULTISITE-MIGRATION.md** and begin at Part 2!

Good luck! 🚀
