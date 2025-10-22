# VPS Preparation (Do This NOW Before Files Arrive)

This is what you can do RIGHT NOW while waiting for your site files and domain access.

---

## Step 1: Prepare .env File Locally

On your local machine:
```bash
cd /Users/jakubwarchol/Dev/minecraft-server-piekarnia/wordpress

# Copy example to .env
cp .env.example .env

# Edit it
nano .env
```

Fill in (you can use temporary domain for now):
```env
# Generate strong passwords
MYSQL_ROOT_PASSWORD=<paste-strong-password-here>
MYSQL_DATABASE=wordpress
MYSQL_USER=wordpress_user
MYSQL_PASSWORD=<paste-another-strong-password-here>

# Placeholder domain (update later when you know it)
DOMAIN_NAME=blog.dscp.team

# Your email
LETSENCRYPT_EMAIL=your-email@example.com
```

**Generate passwords:**
```bash
# Run these to generate random passwords
openssl rand -base64 32
openssl rand -base64 32
```

Copy those passwords into your .env file.

---

## Step 2: Upload Files to VPS

```bash
# From your local machine, upload everything
cd /Users/jakubwarchol/Dev/minecraft-server-piekarnia

# Upload to VPS
scp -r wordpress root@91.98.39.164:/opt/
```

This uploads all your config files to the server.

---

## Step 3: SSH Into VPS

```bash
ssh root@91.98.39.164
```

---

## Step 4: Install Docker (if not installed)

Check if Docker is already installed:
```bash
docker --version
docker compose version
```

If you see version numbers, skip to Step 5. Otherwise:

```bash
# Update system
apt update && apt upgrade -y

# Install prerequisites
apt install -y apt-transport-https ca-certificates curl software-properties-common

# Add Docker's GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Verify installation
docker --version
docker compose version

# Enable Docker on boot
systemctl enable docker
systemctl start docker
```

---

## Step 5: Configure Firewall

```bash
# Check if UFW is active
ufw status

# If active, allow necessary ports
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'
ufw allow 25565/tcp comment 'Minecraft'
ufw allow 22/tcp comment 'SSH'

# Reload firewall
ufw reload

# Check status
ufw status numbered
```

If using iptables instead:
```bash
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -p tcp --dport 25565 -j ACCEPT
iptables-save > /etc/iptables/rules.v4
```

---

## Step 6: Verify Directory Structure

```bash
cd /opt/wordpress
ls -la

# You should see:
# docker-compose.yml
# .env
# nginx/
# README.md
# SETUP.md
# etc.
```

---

## Step 7: Pre-download Docker Images

This saves time later:
```bash
cd /opt/wordpress

# Pull all images (this might take a few minutes)
docker compose pull

# Verify images are downloaded
docker images
```

You should see:
- wordpress:6-fpm-alpine
- mariadb:10.11
- nginx:alpine
- certbot/certbot

---

## Step 8: Test Container Startup (Optional)

Quick test to make sure everything works:
```bash
cd /opt/wordpress

# Start containers
docker compose up -d

# Wait a moment
sleep 10

# Check status
docker compose ps

# All should be "Up" or "running"

# Test if nginx responds
curl -I http://localhost

# Should see HTTP/1.1 response

# Stop containers (we'll restart after migration)
docker compose down
```

---

## Step 9: Check Server Resources

Make sure you have enough space and memory:
```bash
# Check disk space
df -h

# Check memory
free -h

# Check what's using resources
htop  # or: top

# Check what's listening on ports
ss -tlnp | grep -E ':(80|443|25565)'
```

Make sure:
- At least 10GB free disk space
- At least 2GB free RAM (WordPress + MySQL need ~1GB total)
- Ports 80 and 443 are NOT already in use

---

## Step 10: Prepare for Migration

Create a temporary directory for when your files arrive:
```bash
mkdir -p /opt/wordpress/temp-files
cd /opt/wordpress/temp-files

# This is where you'll upload:
# - wordpress-backup.tar.gz (your WordPress files)
# - wordpress-db.sql (your database export)
```

---

## Quick System Check

Run these to verify everything is ready:
```bash
# Docker installed?
docker --version && echo "✅ Docker OK" || echo "❌ Docker not installed"

# Docker Compose installed?
docker compose version && echo "✅ Compose OK" || echo "❌ Compose not installed"

# Config files present?
[ -f /opt/wordpress/docker-compose.yml ] && echo "✅ Config files OK" || echo "❌ Config files missing"

# .env file configured?
[ -f /opt/wordpress/.env ] && echo "✅ .env OK" || echo "❌ .env missing"

# Images downloaded?
docker images | grep -q wordpress && echo "✅ Images OK" || echo "❌ Images not pulled"

# Ports available?
! ss -tlnp | grep -q ':80 ' && echo "✅ Port 80 free" || echo "⚠️  Port 80 in use"
! ss -tlnp | grep -q ':443 ' && echo "✅ Port 443 free" || echo "⚠️  Port 443 in use"

# Minecraft still running?
ss -tlnp | grep -q ':25565 ' && echo "✅ Minecraft still running" || echo "⚠️  Minecraft not detected"
```

---

## You're Ready! ✅

When your files arrive:
1. Upload them to `/opt/wordpress/temp-files/`
2. Follow **MIGRATION.md**

When you get domain access:
1. Point DNS A record to 91.98.39.164
2. Follow **SSL-SETUP.md**

---

## Useful Commands Reference

```bash
# View Docker logs
docker compose logs -f

# Check container status
docker compose ps

# Restart containers
docker compose restart

# Stop everything
docker compose down

# Start everything
docker compose up -d

# View resource usage
docker stats

# Clean up (if needed to start fresh)
docker compose down -v  # ⚠️  Deletes all data!
```

---

## What to Do While Waiting

- ✅ Make sure .env has strong passwords
- ✅ Decide on subdomain name (blog.dscp.team? wp.dscp.team?)
- ✅ Get your existing site backup ready
- ✅ Know your current WordPress admin credentials
- ✅ Have email ready for SSL certificate registration

---

Everything is ready for a quick migration once your files arrive! 🚀
