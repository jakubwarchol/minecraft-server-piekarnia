# WordPress Docker Setup Guide

This guide will help you deploy WordPress in Docker containers on your Hetzner VPS alongside your existing Minecraft server.

## Architecture Overview

- **Minecraft**: Runs natively on port 25565 (unchanged)
- **WordPress**: Runs in Docker containers
  - nginx: Web server and reverse proxy (ports 80, 443)
  - WordPress: PHP-FPM application
  - MariaDB: MySQL database
  - Certbot: SSL certificate management
- **Domain**: Subdomain of dscp.team (e.g., blog.dscp.team)

---

## Prerequisites

- Root or sudo access to your Hetzner VPS (91.98.39.164)
- Domain access to configure DNS (will be done later)
- SSH access to the server

---

## Step 1: Install Docker and Docker Compose

SSH into your VPS:
```bash
ssh root@91.98.39.164
```

### Install Docker
```bash
# Update package list
apt update

# Install prerequisites
apt install -y apt-transport-https ca-certificates curl software-properties-common

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository (adjust for your OS if not Ubuntu)
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
apt update
apt install -y docker-ce docker-ce-cli containerd.io

# Verify installation
docker --version
```

### Install Docker Compose
```bash
# Install Docker Compose plugin
apt install -y docker-compose-plugin

# Verify installation
docker compose version
```

### Enable Docker on boot
```bash
systemctl enable docker
systemctl start docker
```

---

## Step 2: Upload WordPress Files to VPS

### Option A: Using SCP (from your local machine)
```bash
# From your local machine in the wordpress directory
scp -r . root@91.98.39.164:/opt/wordpress/
```

### Option B: Manual upload via SFTP
Use an SFTP client (FileZilla, Cyberduck, etc.) to upload the entire `wordpress` folder to `/opt/wordpress/` on your VPS.

### Option C: Clone from Git (if you commit the files)
```bash
# On the VPS
cd /opt
git clone <your-repo-url> wordpress
cd wordpress
```

---

## Step 3: Configure Environment Variables

```bash
# Navigate to the wordpress directory
cd /opt/wordpress

# Copy the example env file
cp .env.example .env

# Edit the .env file with your values
nano .env
```

Update these values in `.env`:
```env
# Generate strong passwords! Example: openssl rand -base64 32
MYSQL_ROOT_PASSWORD=<generate-a-strong-password>
MYSQL_DATABASE=wordpress
MYSQL_USER=wordpress_user
MYSQL_PASSWORD=<generate-another-strong-password>

# Your subdomain (choose one, e.g., blog.dscp.team or wp.dscp.team)
DOMAIN_NAME=blog.dscp.team

# Your email for Let's Encrypt notifications
LETSENCRYPT_EMAIL=your-email@example.com
```

Save and exit (Ctrl+X, then Y, then Enter in nano).

---

## Step 4: Configure Firewall

Ensure ports 80 and 443 are open for web traffic:

```bash
# If using UFW
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 25565/tcp  # Minecraft (should already be open)
ufw reload
ufw status

# If using iptables
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
iptables-save > /etc/iptables/rules.v4
```

---

## Step 5: Start WordPress Containers

```bash
cd /opt/wordpress

# Pull the latest images
docker compose pull

# Start the containers in detached mode
docker compose up -d

# Check that all containers are running
docker compose ps

# View logs if needed
docker compose logs -f
```

You should see 4 containers running:
- wordpress_nginx
- wordpress_app
- wordpress_mysql
- wordpress_certbot

---

## Step 6: Test Access (Before DNS)

Since DNS isn't configured yet, you can test by accessing via IP:

```bash
# Get your server IP (should be 91.98.39.164)
curl -4 icanhazip.com

# Test nginx is responding
curl http://91.98.39.164
```

You should see the WordPress installation page HTML.

---

## Step 7: Configure DNS (Do this when you have domain access)

When you have access to the dscp.team domain:

1. Go to your DNS provider (wherever dscp.team is registered)
2. Add an **A record**:
   - **Name**: `blog` (or whatever subdomain you chose)
   - **Type**: A
   - **Value**: `91.98.39.164`
   - **TTL**: 3600 (or default)

Wait for DNS propagation (can take 5 minutes to 48 hours, usually < 1 hour).

Test DNS propagation:
```bash
# From your local machine
nslookup blog.dscp.team
# or
dig blog.dscp.team
```

---

## Step 8: Complete WordPress Installation

1. Open your browser and go to: `http://blog.dscp.team` (or your chosen subdomain)
2. You'll see the WordPress installation wizard
3. Select your language
4. Fill in the site information:
   - Site Title
   - Username (don't use 'admin')
   - Strong password
   - Your email
5. Click "Install WordPress"
6. Log in with your credentials

---

## Step 9: Enable SSL (After DNS is working)

Once your domain is pointed and working:

```bash
cd /opt/wordpress

# Stop the containers
docker compose down

# Update nginx config to use your actual domain
nano nginx/conf.d/wordpress.conf
```

In `wordpress.conf`:
1. Replace `server_name _;` with `server_name blog.dscp.team;` (line 5)
2. Uncomment the redirect to HTTPS (lines 13-15)
3. Uncomment the entire HTTPS server block (lines 23-72)
4. Replace `YOUR_SUBDOMAIN.dscp.team` with your actual subdomain (3 locations)

Save and exit.

### Obtain SSL Certificate

```bash
# Run Certbot to get the certificate
docker compose run --rm certbot certonly --webroot \
  --webroot-path=/var/www/certbot \
  --email your-email@example.com \
  --agree-tos \
  --no-eff-email \
  -d blog.dscp.team

# Restart containers with SSL enabled
docker compose up -d

# Test SSL renewal (dry run)
docker compose run --rm certbot renew --dry-run
```

Your site should now be accessible via HTTPS!

---

## Step 10: Verify Everything Works

1. **Test WordPress**: https://blog.dscp.team
2. **Test Minecraft**: Should still work on port 25565
3. **Check SSL**: Browser should show padlock icon
4. **Test HTTP redirect**: http://blog.dscp.team should redirect to HTTPS

---

## Maintenance Commands

### View logs
```bash
cd /opt/wordpress
docker compose logs -f nginx
docker compose logs -f wordpress
docker compose logs -f mysql
```

### Restart containers
```bash
docker compose restart
```

### Stop containers
```bash
docker compose down
```

### Start containers
```bash
docker compose up -d
```

### Update containers
```bash
docker compose pull
docker compose up -d
```

### Backup WordPress data
```bash
# Backup database
docker compose exec mysql mysqldump -u wordpress_user -p wordpress > backup-$(date +%Y%m%d).sql

# Backup WordPress files
tar -czf wordpress-files-$(date +%Y%m%d).tar.gz -C /var/lib/docker/volumes wordpress_data
```

---

## Troubleshooting

### Containers won't start
```bash
# Check logs
docker compose logs

# Check if ports are already in use
ss -tlnp | grep -E ':(80|443)'
```

### Can't access WordPress
```bash
# Check nginx is running
docker compose ps

# Check nginx config syntax
docker compose exec nginx nginx -t

# Check container networking
docker network inspect wordpress_wordpress_network
```

### Database connection errors
```bash
# Check MySQL is running
docker compose ps

# Check MySQL logs
docker compose logs mysql

# Verify env variables
docker compose exec wordpress env | grep WORDPRESS_DB
```

### SSL certificate issues
```bash
# Check Certbot logs
docker compose logs certbot

# Manually test certificate
docker compose run --rm certbot certificates
```

---

## Security Recommendations

1. **Use strong passwords** for all database and WordPress accounts
2. **Keep containers updated** regularly with `docker compose pull && docker compose up -d`
3. **Install security plugins** in WordPress (e.g., Wordfence, iThemes Security)
4. **Regular backups** of both database and WordPress files
5. **Monitor logs** for suspicious activity
6. **Disable XML-RPC** if not needed (can be done via plugin or nginx config)
7. **Use 2FA** for WordPress admin login

---

## Next Steps

- Configure WordPress settings (permalinks, themes, plugins)
- Set up automated backups
- Configure WordPress caching (WP Super Cache or similar)
- Monitor resource usage: `docker stats`
- Set up monitoring/alerts for your site

---

## Support

If you encounter issues:
1. Check the logs: `docker compose logs`
2. Verify your .env file has correct values
3. Ensure DNS is properly configured
4. Check firewall rules are allowing traffic

For Minecraft server issues, check `/opt/minecraft/` directory (unchanged by this setup).
