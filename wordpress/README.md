# WordPress Multisite Docker Deployment

Docker-based WordPress Multisite deployment configured to run alongside a Minecraft server on Hetzner VPS.

## Quick Overview

**Architecture:**
- WordPress Multisite + PHP-FPM (Alpine Linux)
- MariaDB 10.11 database
- Nginx web server with reverse proxy for multiple domains
- Certbot for Let's Encrypt SSL
- Docker Compose for orchestration

**Network:**
- HTTP: Port 80
- HTTPS: Port 443
- Minecraft: Port 25565 (unchanged, runs natively)

**Domains:**
- Main site: dscp.team
- Sub site: daily.dscp.team (converted from dscp.team/daily)

## Project Structure

```
wordpress/
├── docker-compose.yml                     # Main orchestration file
├── .env.example                           # Environment variables template
├── .env                                   # Your environment variables (gitignored)
├── .gitignore                             # Git ignore rules
├── nginx/
│   ├── nginx.conf                         # Main nginx configuration
│   └── conf.d/
│       └── wordpress.conf                 # Multisite configuration (both domains)
├── certbot/                               # SSL certificates (created on first run)
│   ├── conf/                              # Let's Encrypt certificates
│   └── www/                               # ACME challenge files
├── START-HERE.md                          # 👈 **START HERE** - Quick start guide
├── MULTISITE-MIGRATION.md                 # **Main migration guide**
├── convert-subdirectory-to-subdomain.sql  # Database conversion helper script
├── PREP-NOW.md                            # Pre-deployment prep (already done)
├── SETUP.md                               # Docker/VPS setup reference
├── SSL-SETUP.md                           # SSL configuration guide
└── README.md                              # This file
```

## 🚀 Getting Started

### **→ [START-HERE.md](START-HERE.md)** ← Begin here!

Quick overview of what's needed:

1. **Clone repo** and upload configs to VPS
2. **Configure .env** with passwords and domains
3. **Get backup files** from current WordPress server
4. **Follow [MULTISITE-MIGRATION.md](MULTISITE-MIGRATION.md)** for complete migration

**VPS Status:** ✅ Ready (Docker installed, firewall configured)

**Current State:**
- VPS IP: 91.98.39.164
- Docker: Installed and running
- Firewall: Configured (ports 80, 443, 25565)
- Directory: /opt/wordpress/ created
- Minecraft: Running normally (port 25565)

## Quick Commands

```bash
# Start containers
docker compose up -d

# Stop containers
docker compose down

# View logs
docker compose logs -f

# Restart containers
docker compose restart

# Update images
docker compose pull && docker compose up -d

# Check status
docker compose ps
```

## Requirements

- Docker Engine 20.10+
- Docker Compose v2
- Ubuntu/Debian VPS (tested on Ubuntu 22.04)
- Root or sudo access
- Domain with DNS access (dscp.team)

## Default Configuration

- **Database Name:** wordpress
- **Database User:** wordpress_user
- **PHP Version:** 8.2 (via wordpress:6-fpm-alpine)
- **MariaDB Version:** 10.11
- **Nginx Version:** Latest alpine
- **Upload Limit:** 64MB (configurable in nginx.conf)

## Security Features

✅ Isolated Docker network for services
✅ Strong SSL/TLS configuration (TLS 1.2+)
✅ Security headers (HSTS, X-Frame-Options, etc.)
✅ Automatic SSL certificate renewal
✅ Database not exposed to public
✅ Separate user for WordPress database access

## Maintenance

### Backups

```bash
# Database backup
docker compose exec mysql mysqldump -u wordpress_user -p wordpress > backup.sql

# Files backup
docker compose exec wordpress tar -czf /tmp/wordpress-files.tar.gz /var/www/html
docker compose cp wordpress:/tmp/wordpress-files.tar.gz ./
```

### Updates

```bash
# Update containers (pulls new images)
cd /opt/wordpress
docker compose pull
docker compose up -d

# Update WordPress core/plugins via WordPress admin
```

### Monitor Resources

```bash
# View resource usage
docker stats

# View disk usage
docker system df

# Clean up unused resources
docker system prune -a
```

## Troubleshooting

Common issues and solutions:

**Containers won't start:**
- Check logs: `docker compose logs`
- Verify ports 80/443 aren't in use: `ss -tlnp | grep -E ':(80|443)'`

**Can't access WordPress:**
- Check DNS: `nslookup your-subdomain.dscp.team`
- Check firewall: `ufw status`
- Test nginx config: `docker compose exec nginx nginx -t`

**Database connection errors:**
- Verify .env variables are correct
- Check MySQL is running: `docker compose ps`
- View MySQL logs: `docker compose logs mysql`

**SSL issues:**
- See [SSL-SETUP.md](SSL-SETUP.md)
- Check certificates: `docker compose run --rm certbot certificates`

## Documentation

- **[START-HERE.md](START-HERE.md)** - 👈 **Start here!** Quick start guide
- **[MULTISITE-MIGRATION.md](MULTISITE-MIGRATION.md)** - Complete migration guide for WordPress Multisite
- **[convert-subdirectory-to-subdomain.sql](convert-subdirectory-to-subdomain.sql)** - SQL helper script
- **[PREP-NOW.md](PREP-NOW.md)** - VPS preparation (already completed)
- **[SETUP.md](SETUP.md)** - Docker/VPS setup reference
- **[SSL-SETUP.md](SSL-SETUP.md)** - SSL/HTTPS configuration
- **[.env.example](.env.example)** - Environment variables reference

## Architecture Diagram

```
                Internet
                    |
                    | (ports 80, 443)
                    ↓
            +---------------+
            |  nginx        |  ← Reverse proxy + SSL termination
            |  (container)  |
            +---------------+
                    |
                    ↓
            +---------------+
            |  wordpress    |  ← PHP-FPM application
            |  (container)  |
            +---------------+
                    |
                    ↓
            +---------------+
            |  mysql        |  ← Database (not exposed)
            |  (container)  |
            +---------------+

            +---------------+
            |  certbot      |  ← SSL certificates
            |  (container)  |
            +---------------+


            Native on Host:
            +---------------+
            |  Minecraft    |  ← Port 25565 (unchanged)
            |  (native)     |
            +---------------+
```

## Tech Stack

- **Web Server:** Nginx (Alpine Linux)
- **Application:** WordPress 6.x + PHP 8.2-FPM
- **Database:** MariaDB 10.11
- **SSL:** Let's Encrypt via Certbot
- **Orchestration:** Docker Compose
- **OS:** Ubuntu 22.04 LTS (Hetzner VPS)

## Performance Optimization

The setup includes:
- FastCGI caching ready
- Gzip compression enabled
- Static file caching (30 days)
- Optimized PHP-FPM and MySQL settings
- Lightweight Alpine Linux images

For further optimization:
- Install WordPress caching plugin (WP Super Cache, W3 Total Cache)
- Configure Redis object cache
- Enable CDN (Cloudflare)
- Optimize images (WebP, lazy loading)

## License

This configuration is provided as-is for the dscp.team WordPress deployment.

## Support

For issues or questions:
1. Check documentation in this folder
2. Review Docker logs: `docker compose logs`
3. Verify configuration in .env file
4. Check Docker and system resources

---

**Status:** Ready for deployment
**Last Updated:** 2025-10-22
**Minecraft Server:** Unaffected by this installation
