# SSL Setup Guide (After DNS Configuration)

This guide walks you through enabling HTTPS with Let's Encrypt SSL certificates after your DNS is properly configured.

## Prerequisites

✅ DNS A record pointing your subdomain to 91.98.39.164
✅ WordPress containers running and accessible via HTTP
✅ Domain propagation complete (test with `nslookup blog.dscp.team`)

---

## Step 1: Update Nginx Configuration

SSH into your VPS:
```bash
ssh root@91.98.39.164
cd /opt/wordpress
```

Stop the containers:
```bash
docker compose down
```

Edit the nginx configuration:
```bash
nano nginx/conf.d/wordpress.conf
```

### Changes to make:

1. **Line 5**: Update the HTTP server_name
   ```nginx
   # Change from:
   server_name _;

   # To (replace with your actual subdomain):
   server_name blog.dscp.team;
   ```

2. **Lines 13-15**: Enable HTTPS redirect
   ```nginx
   # Uncomment these lines:
   location / {
       return 301 https://$host$request_uri;
   }
   ```

3. **Lines 17-30**: Comment out or remove the temporary HTTP location block
   ```nginx
   # Comment out or delete this section:
   # location / {
   #     fastcgi_pass wordpress:9000;
   #     ...
   # }
   ```

4. **Lines 37-72**: Uncomment the entire HTTPS server block

5. **Replace YOUR_SUBDOMAIN.dscp.team** in 3 places (lines 40, 44-46):
   ```nginx
   server_name blog.dscp.team;

   ssl_certificate /etc/letsencrypt/live/blog.dscp.team/fullchain.pem;
   ssl_certificate_key /etc/letsencrypt/live/blog.dscp.team/privkey.pem;
   ssl_trusted_certificate /etc/letsencrypt/live/blog.dscp.team/chain.pem;
   ```

Save and exit (Ctrl+X, Y, Enter).

---

## Step 2: Start Containers (HTTP Only)

Before getting the SSL certificate, start containers with HTTP only:

```bash
# Start containers
docker compose up -d

# Verify nginx is running
docker compose ps

# Test that your domain is accessible
curl -I http://blog.dscp.team
```

You should see a 200 OK response or WordPress redirect.

---

## Step 3: Obtain SSL Certificate

Run Certbot to get your SSL certificate:

```bash
# Replace with your actual subdomain and email
docker compose run --rm certbot certonly --webroot \
  --webroot-path=/var/www/certbot \
  --email your-email@example.com \
  --agree-tos \
  --no-eff-email \
  -d blog.dscp.team
```

**Expected output:**
```
Successfully received certificate.
Certificate is saved at: /etc/letsencrypt/live/blog.dscp.team/fullchain.pem
Key is saved at:         /etc/letsencrypt/live/blog.dscp.team/privkey.pem
```

If you see errors:
- **DNS errors**: Wait longer for DNS propagation
- **Connection errors**: Check firewall allows port 80
- **Domain validation fails**: Ensure nginx is serving the .well-known/acme-challenge/ path

---

## Step 4: Restart with HTTPS

Now that you have the certificates, restart to enable HTTPS:

```bash
# Restart all containers
docker compose restart

# Check logs for errors
docker compose logs nginx

# Verify HTTPS is working
curl -I https://blog.dscp.team
```

---

## Step 5: Test SSL Configuration

### Test in Browser
1. Go to https://blog.dscp.team
2. Check for padlock icon in address bar
3. Click the padlock to view certificate details
4. Verify it's issued by "Let's Encrypt"

### Test HTTP Redirect
```bash
curl -I http://blog.dscp.team
```
Should return `301 Moved Permanently` and redirect to HTTPS.

### Test SSL Grade
Go to: https://www.ssllabs.com/ssltest/analyze.html?d=blog.dscp.team

Should get an **A** or **A+** rating.

---

## Step 6: Set Up Automatic Renewal

Let's Encrypt certificates expire after 90 days. The Certbot container is configured to auto-renew.

Test the renewal process:
```bash
# Dry run (doesn't actually renew)
docker compose run --rm certbot renew --dry-run
```

If successful, you'll see:
```
Congratulations, all simulated renewals succeeded
```

The certbot container will automatically check for renewal twice daily.

---

## Step 7: Update WordPress URLs

WordPress may still have HTTP URLs in the database. Update them:

### Option A: Via WordPress Admin (Recommended)
1. Log in to WordPress admin: https://blog.dscp.team/wp-admin
2. Go to **Settings > General**
3. Update:
   - **WordPress Address (URL)**: https://blog.dscp.team
   - **Site Address (URL)**: https://blog.dscp.team
4. Click **Save Changes**

### Option B: Via Database (if locked out)
```bash
docker compose exec mysql mysql -u wordpress_user -p wordpress

# In MySQL prompt:
UPDATE wp_options SET option_value='https://blog.dscp.team' WHERE option_name='siteurl';
UPDATE wp_options SET option_value='https://blog.dscp.team' WHERE option_name='home';
EXIT;
```

---

## Troubleshooting

### Certificate not found error
```bash
# List certificates
docker compose run --rm certbot certificates

# Check certificate files exist
docker compose exec nginx ls -la /etc/letsencrypt/live/
```

### Mixed content warnings (HTTP resources on HTTPS page)
- Install "Really Simple SSL" WordPress plugin
- Or manually update theme/plugin URLs in WordPress admin

### Certificate renewal fails
```bash
# Check logs
docker compose logs certbot

# Manually renew
docker compose run --rm certbot renew --force-renewal
```

### Nginx fails to start after SSL config
```bash
# Test nginx configuration
docker compose exec nginx nginx -t

# Check for typos in wordpress.conf
nano nginx/conf.d/wordpress.conf

# View detailed nginx logs
docker compose logs nginx
```

---

## Manual Certificate Renewal

If automatic renewal fails, renew manually:

```bash
# Stop nginx (to free port 80)
docker compose stop nginx

# Renew certificate
docker compose run --rm certbot renew

# Start nginx
docker compose start nginx
```

---

## Security Best Practices

After enabling SSL:

1. ✅ Force HTTPS in WordPress settings
2. ✅ Enable HSTS header (already configured in nginx)
3. ✅ Update all internal links to HTTPS
4. ✅ Set up 301 redirects from HTTP to HTTPS (already configured)
5. ✅ Update Google Search Console with HTTPS version
6. ✅ Update any external links/bookmarks

---

## Certificate Locations

Certificates are stored in Docker volumes:

- **On host**: `./certbot/conf/live/blog.dscp.team/`
- **In container**: `/etc/letsencrypt/live/blog.dscp.team/`

Files:
- `fullchain.pem` - Full certificate chain
- `privkey.pem` - Private key
- `chain.pem` - Intermediate certificates
- `cert.pem` - Your certificate only

**Never share or commit `privkey.pem`!**

---

## Backup Certificates

Important before major changes:

```bash
# Backup certificates
cd /opt/wordpress
tar -czf certbot-backup-$(date +%Y%m%d).tar.gz certbot/

# Backup to another location
scp certbot-backup-*.tar.gz user@backup-server:/backups/
```

---

## Next Steps After SSL

- Configure WordPress caching plugins
- Set up CDN (Cloudflare, etc.)
- Install security plugins (Wordfence)
- Enable WordPress automatic updates
- Set up monitoring and uptime alerts

---

## Quick Reference Commands

```bash
# Check certificate expiry
docker compose run --rm certbot certificates

# Force certificate renewal
docker compose run --rm certbot renew --force-renewal

# Test renewal process
docker compose run --rm certbot renew --dry-run

# View nginx error logs
docker compose logs nginx | grep error

# Restart after config changes
docker compose restart nginx

# Check SSL configuration
docker compose exec nginx nginx -t
```

---

## Support

If SSL setup fails:
1. Verify DNS is working: `nslookup blog.dscp.team`
2. Check firewall allows ports 80 and 443
3. Ensure nginx is serving .well-known/acme-challenge/
4. Review Certbot logs: `docker compose logs certbot`
5. Test nginx config: `docker compose exec nginx nginx -t`

SSL should be working! 🎉🔒
