# WordPress Multisite Migration & Subdirectory to Subdomain Conversion

This guide covers migrating your WordPress Multisite from another server to Docker, **AND** converting from subdirectory structure to subdomain structure.

## Current Setup
- **Main site**: dscp.team
- **Sub site**: dscp.team/daily (subdirectory)

## Target Setup
- **Main site**: dscp.team (stays same)
- **Sub site**: daily.dscp.team (converted to subdomain)

---

## Part 1: Backup from Current Server

### Step 1: Export Database

On your current server:
```bash
# SSH into current server
ssh user@current-server

# Export the entire multisite database
mysqldump -u username -p database_name > wordpress-multisite-backup.sql

# Download to your local machine
scp user@current-server:wordpress-multisite-backup.sql ./
```

**OR** via phpMyAdmin:
- Export entire WordPress database
- Format: SQL
- Save as: `wordpress-multisite-backup.sql`

### Step 2: Backup WordPress Files

```bash
# On current server, create tarball of WordPress directory
cd /path/to/wordpress
tar -czf wordpress-multisite-files.tar.gz .

# Download to your local machine
scp user@current-server:wordpress-multisite-files.tar.gz ./
```

Make sure you have:
- All wp-content files (themes, plugins, uploads)
- wp-config.php (for reference)
- .htaccess

### Step 3: Note Current Configuration

From current server's `wp-config.php`, note these values:
```php
define('MULTISITE', true);
define('SUBDOMAIN_INSTALL', false);  // Currently false for subdirectory
define('DOMAIN_CURRENT_SITE', 'dscp.team');
define('PATH_CURRENT_SITE', '/');
$base = '/';
```

Also note:
- Database table prefix (usually `wp_`)
- Current WordPress admin credentials
- Which site is ID 1 (main) and which is ID 2 (daily)

---

## Part 2: Prepare VPS (Docker Setup)

### Step 1: Configure .env

On your local machine:
```bash
cd /Users/jakubwarchol/Dev/minecraft-server-piekarnia/wordpress
cp .env.example .env
nano .env
```

Fill in:
```env
MYSQL_ROOT_PASSWORD=<strong-password>
MYSQL_DATABASE=wordpress
MYSQL_USER=wordpress_user
MYSQL_PASSWORD=<strong-password>

MAIN_DOMAIN=dscp.team
SUB_DOMAIN=daily.dscp.team

LETSENCRYPT_EMAIL=your-email@example.com
```

### Step 2: Upload to VPS

```bash
# Upload configuration files
scp -r wordpress root@91.98.39.164:/opt/

# SSH into VPS
ssh root@91.98.39.164
```

### Step 3: Install Docker (if needed)

See **PREP-NOW.md** for Docker installation steps, or:
```bash
apt update && apt install -y docker.io docker-compose-plugin
systemctl enable --now docker
```

### Step 4: Upload Backup Files

From your local machine:
```bash
# Upload backups to VPS
scp wordpress-multisite-backup.sql root@91.98.39.164:/opt/wordpress/
scp wordpress-multisite-files.tar.gz root@91.98.39.164:/opt/wordpress/
```

---

## Part 3: Import & Configure Multisite

### Step 1: Start MySQL Container Only

```bash
cd /opt/wordpress

# Start MySQL only
docker compose up -d mysql

# Wait for MySQL to initialize
sleep 15

# Check it's running
docker compose ps
```

### Step 2: Import Database

```bash
# Import your database
docker compose exec -T mysql mysql -u root -p${MYSQL_ROOT_PASSWORD} ${MYSQL_DATABASE} < wordpress-multisite-backup.sql

# Verify import
docker compose exec mysql mysql -u root -p${MYSQL_ROOT_PASSWORD} ${MYSQL_DATABASE} -e "SHOW TABLES;"
```

You should see all your wp_ tables.

### Step 3: Extract WordPress Files

```bash
mkdir -p /opt/wordpress/temp-wp
cd /opt/wordpress
tar -xzf wordpress-multisite-files.tar.gz -C temp-wp/

# Verify extraction
ls -la temp-wp/
```

### Step 4: Update wp-config.php for Docker

Edit the extracted wp-config.php:
```bash
nano temp-wp/wp-config.php
```

Update database connection:
```php
define( 'DB_NAME', 'wordpress' );
define( 'DB_USER', 'wordpress_user' );
define( 'DB_PASSWORD', 'your_password_from_env' );
define( 'DB_HOST', 'mysql:3306' );
```

**CRITICAL**: Update multisite configuration from subdirectory to subdomain:
```php
define('MULTISITE', true);
define('SUBDOMAIN_INSTALL', true);  // Changed from false to TRUE
define('DOMAIN_CURRENT_SITE', 'dscp.team');
define('PATH_CURRENT_SITE', '/');
define('SITE_ID_CURRENT_SITE', 1);
define('BLOG_ID_CURRENT_SITE', 1);
```

Make sure these lines are present (usually at the end):
```php
/* Multisite */
define( 'WP_ALLOW_MULTISITE', true );
define( 'MULTISITE', true );
define( 'SUBDOMAIN_INSTALL', true );
define( 'DOMAIN_CURRENT_SITE', 'dscp.team' );
define( 'PATH_CURRENT_SITE', '/' );
define( 'SITE_ID_CURRENT_SITE', 1 );
define( 'BLOG_ID_CURRENT_SITE', 1 );

/* That's all, stop editing! Happy publishing. */
```

Save and exit.

### Step 5: Copy Files to WordPress Container

```bash
# Start WordPress container
docker compose up -d wordpress
sleep 10

# Remove default WordPress files
docker compose exec wordpress sh -c "rm -rf /var/www/html/*"

# Copy your files
docker cp temp-wp/. wordpress_app:/var/www/html/

# Fix permissions
docker compose exec wordpress chown -R www-data:www-data /var/www/html
docker compose exec wordpress chmod -R 755 /var/www/html
```

---

## Part 4: Convert Database from Subdirectory to Subdomain

This is the crucial step to convert dscp.team/daily → daily.dscp.team

### Step 1: Access MySQL

```bash
docker compose exec mysql mysql -u root -p${MYSQL_ROOT_PASSWORD} ${MYSQL_DATABASE}
```

### Step 2: Check Current Site Configuration

```sql
-- View sites table
SELECT * FROM wp_blogs;
```

You should see something like:
```
blog_id | site_id | domain    | path
1       | 1       | dscp.team | /
2       | 1       | dscp.team | /daily/
```

### Step 3: Update Sites Table

```sql
-- Update the daily site from subdirectory to subdomain
UPDATE wp_blogs
SET domain = 'daily.dscp.team', path = '/'
WHERE path = '/daily/';

-- Verify the change
SELECT * FROM wp_blogs;
```

Now you should see:
```
blog_id | site_id | domain          | path
1       | 1       | dscp.team       | /
2       | 1       | daily.dscp.team | /
```

### Step 4: Update Site Options

```sql
-- Check current values
SELECT blog_id, meta_key, meta_value
FROM wp_sitemeta
WHERE meta_key IN ('siteurl', 'home');

-- If needed, update main site URL (usually correct already)
UPDATE wp_sitemeta
SET meta_value = 'https://dscp.team'
WHERE meta_key = 'siteurl';
```

### Step 5: Update Site 2 (daily) Options

```sql
-- Check site 2 options
SELECT option_name, option_value
FROM wp_2_options
WHERE option_name IN ('siteurl', 'home');

-- Update site 2 URLs
UPDATE wp_2_options
SET option_value = 'https://daily.dscp.team'
WHERE option_name = 'siteurl';

UPDATE wp_2_options
SET option_value = 'https://daily.dscp.team'
WHERE option_name = 'home';

-- Verify
SELECT option_name, option_value
FROM wp_2_options
WHERE option_name IN ('siteurl', 'home');
```

### Step 6: Search & Replace URLs in Content

For main site (wp_posts):
```sql
-- Update main site content (if needed)
UPDATE wp_posts
SET post_content = REPLACE(post_content, 'http://old-domain.com', 'https://dscp.team')
WHERE post_content LIKE '%old-domain.com%';

UPDATE wp_posts
SET guid = REPLACE(guid, 'http://old-domain.com', 'https://dscp.team')
WHERE guid LIKE '%old-domain.com%';
```

For daily site (wp_2_posts):
```sql
-- Update daily site content URLs from /daily/ paths to subdomain
UPDATE wp_2_posts
SET post_content = REPLACE(post_content, 'dscp.team/daily/', 'daily.dscp.team/')
WHERE post_content LIKE '%dscp.team/daily/%';

UPDATE wp_2_posts
SET guid = REPLACE(guid, 'dscp.team/daily/', 'daily.dscp.team/')
WHERE guid LIKE '%dscp.team/daily/%';

-- Also update any absolute URLs
UPDATE wp_2_posts
SET post_content = REPLACE(post_content, 'http://dscp.team/daily', 'https://daily.dscp.team')
WHERE post_content LIKE '%dscp.team/daily%';
```

### Step 7: Update Upload Paths

```sql
-- Check current upload paths for site 2
SELECT option_name, option_value
FROM wp_2_options
WHERE option_name LIKE '%upload%';

-- If upload_path is set to old path, update it
UPDATE wp_2_options
SET option_value = REPLACE(option_value, '/daily', '')
WHERE option_name = 'upload_path' AND option_value LIKE '%/daily%';
```

Exit MySQL:
```sql
EXIT;
```

---

## Part 5: Start All Services & Test

### Step 1: Start Nginx

```bash
cd /opt/wordpress

# Start all services
docker compose up -d

# Check all containers are running
docker compose ps

# View logs
docker compose logs -f nginx
```

### Step 2: Test via IP (Before DNS)

```bash
# Test main site
curl -H "Host: dscp.team" http://91.98.39.164

# Test daily site
curl -H "Host: daily.dscp.team" http://91.98.39.164
```

### Step 3: Update Local hosts File for Testing

On your local machine (for testing before DNS):

**macOS/Linux:**
```bash
sudo nano /etc/hosts
```

**Windows:**
```
C:\Windows\System32\drivers\etc\hosts
```

Add these lines:
```
91.98.39.164 dscp.team
91.98.39.164 daily.dscp.team
```

Now you can test in browser:
- http://dscp.team
- http://daily.dscp.team

### Step 4: Login and Verify

1. Go to: http://dscp.team/wp-admin/network/
2. Login with your WordPress credentials
3. Check "My Sites" - you should see both sites
4. Visit each site:
   - http://dscp.team (main site)
   - http://daily.dscp.team (daily site)

---

## Part 6: Configure DNS (When Ready)

When you have domain access:

### DNS Records to Add

At your DNS provider for dscp.team:

1. **A Record for main domain:**
   - Type: A
   - Name: @ (or blank)
   - Value: 91.98.39.164
   - TTL: 3600

2. **A Record for subdomain:**
   - Type: A
   - Name: daily
   - Value: 91.98.39.164
   - TTL: 3600

### Test DNS Propagation

```bash
# From local machine
nslookup dscp.team
nslookup daily.dscp.team

# OR
dig dscp.team
dig daily.dscp.team
```

Both should point to 91.98.39.164.

### Remove hosts File Entry

Once DNS is working, remove the test entries from /etc/hosts.

---

## Part 7: Enable SSL/HTTPS

Once DNS is working, follow these steps:

### Step 1: Update nginx Config

```bash
cd /opt/wordpress
nano nginx/conf.d/wordpress.conf
```

On line 6, change:
```nginx
server_name _;
```

To:
```nginx
server_name dscp.team daily.dscp.team;
```

Uncomment the HTTPS redirect (lines 13-15):
```nginx
location / {
    return 301 https://$host$request_uri;
}
```

Comment out the temporary HTTP section (lines 17-48).

Uncomment BOTH HTTPS server blocks (lines 50-161).

Save and exit.

### Step 2: Obtain SSL Certificates

Get certificate for BOTH domains:
```bash
# Get cert for main domain and subdomain together
docker compose run --rm certbot certonly --webroot \
  --webroot-path=/var/www/certbot \
  --email your-email@example.com \
  --agree-tos \
  --no-eff-email \
  -d dscp.team \
  -d daily.dscp.team

# Restart to enable HTTPS
docker compose restart nginx
```

**OR** get wildcard certificate:
```bash
docker compose run --rm certbot certonly --manual \
  --preferred-challenges dns \
  --email your-email@example.com \
  --agree-tos \
  -d dscp.team \
  -d *.dscp.team
```

Note: Wildcard requires DNS TXT record verification.

### Step 3: Update WordPress URLs to HTTPS

```bash
docker compose exec mysql mysql -u root -p${MYSQL_ROOT_PASSWORD} ${MYSQL_DATABASE}
```

```sql
-- Main site
UPDATE wp_options SET option_value = 'https://dscp.team'
WHERE option_name IN ('siteurl', 'home');

-- Daily site
UPDATE wp_2_options SET option_value = 'https://daily.dscp.team'
WHERE option_name IN ('siteurl', 'home');

-- Update site metadata
UPDATE wp_sitemeta SET meta_value = 'https://dscp.team'
WHERE meta_key IN ('siteurl', 'home');

EXIT;
```

### Step 4: Restart and Test

```bash
docker compose restart

# Test HTTPS
curl -I https://dscp.team
curl -I https://daily.dscp.team
```

Visit in browser:
- https://dscp.team
- https://daily.dscp.team

Both should show padlock icons!

---

## Troubleshooting

### Site shows "Error establishing database connection"

Check wp-config.php database settings match your .env file:
```bash
docker compose exec wordpress cat /var/www/html/wp-config.php | grep DB_
```

### Daily site redirects to dscp.team/daily

Database wasn't updated correctly. Re-run Part 4 SQL queries.

### Images/assets not loading

Check upload URLs in database:
```sql
-- Find posts with old URLs
SELECT ID, post_content FROM wp_2_posts
WHERE post_content LIKE '%dscp.team/daily/%'
LIMIT 5;
```

Run search-replace again or use WP-CLI:
```bash
docker compose exec wordpress wp --allow-root search-replace \
  'dscp.team/daily' 'daily.dscp.team' \
  --all-tables --network
```

### Can't access Network Admin

Try accessing via:
- http://dscp.team/wp-admin/network/

If redirecting incorrectly, check wp-config.php multisite settings.

### One site works, other doesn't

Check wp_blogs table:
```sql
SELECT * FROM wp_blogs;
```

Both should have proper domain and path='/'.

### SSL certificate errors

Make sure certificate covers both domains:
```bash
docker compose run --rm certbot certificates
```

Should list both dscp.team and daily.dscp.team.

---

## Verification Checklist

After migration:

- [ ] Can access http://dscp.team
- [ ] Can access http://daily.dscp.team
- [ ] Can login to Network Admin
- [ ] Both sites show in "My Sites"
- [ ] Main site loads correctly
- [ ] Daily site loads correctly (NOT /daily)
- [ ] Images load on both sites
- [ ] Links work on both sites
- [ ] Can edit posts on both sites
- [ ] Plugins work on both sites
- [ ] Themes display correctly
- [ ] HTTPS works for both domains
- [ ] HTTP redirects to HTTPS
- [ ] No mixed content warnings

---

## Backup After Successful Migration

```bash
# Backup database
docker compose exec mysql mysqldump -u root -p${MYSQL_ROOT_PASSWORD} ${MYSQL_DATABASE} > multisite-migrated-$(date +%Y%m%d).sql

# Backup files
docker compose exec wordpress tar -czf /tmp/wp-files.tar.gz -C /var/www/html .
docker cp wordpress_app:/tmp/wp-files.tar.gz ./multisite-files-$(date +%Y%m%d).tar.gz

# Backup entire Docker setup
cd /opt
tar -czf wordpress-multisite-full-$(date +%Y%m%d).tar.gz wordpress/
```

---

## Important Notes

1. **Multisite remains active** - You still have network admin capabilities
2. **Shared plugins/themes** - Both sites share the same plugins and themes
3. **Separate content** - Each site has its own posts, pages, settings
4. **Subdomain structure** - Much cleaner URLs than subdirectories
5. **SSL for both** - Single certificate can cover both domains

---

## Quick Reference

```bash
# View all sites in network
docker compose exec wordpress wp --allow-root site list

# Switch to site 2 for WP-CLI commands
docker compose exec wordpress wp --allow-root --url=daily.dscp.team [command]

# Network-wide search-replace
docker compose exec wordpress wp --allow-root search-replace 'old' 'new' --network

# List all network plugins
docker compose exec wordpress wp --allow-root plugin list --network

# View multisite constants
docker compose exec wordpress wp --allow-root config get --type=constant | grep -i multi
```

---

Migration complete! You now have WordPress Multisite running with subdomain structure. 🎉
