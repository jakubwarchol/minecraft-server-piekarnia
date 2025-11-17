# SEO & Performance Optimization Checklist

Complete implementation and verification checklist for daily.dscp.team optimizations.

## Overview

This checklist covers all optimizations from:
1. SEO improvements (RankMath, robots.txt)
2. Nginx performance configuration
3. WordPress caching setup
4. Google Search Console configuration
5. Verification and testing

**Total implementation time:** ~45-60 minutes
**Cost:** $0 (all free solutions)
**Expected impact:** 70-80% performance improvement + resolved GSC issues

---

## Phase 1: SEO Foundation

### 1.1 Deploy robots.txt

**File:** `wordpress/robots.txt`
**Target location:** `/var/www/html/robots.txt` (in WordPress container)

```bash
# SSH into VPS
ssh root@91.98.39.164

# Navigate to WordPress directory
cd /opt/wordpress

# Copy robots.txt to WordPress container
docker cp robots.txt wordpress:/var/www/html/robots.txt

# Verify ownership
docker compose exec wordpress chown www-data:www-data /var/www/html/robots.txt

# Test it's accessible
curl https://daily.dscp.team/robots.txt
```

**Expected output:**
```txt
User-agent: *
Allow: /
Disallow: /*?ref=*
...
Sitemap: https://daily.dscp.team/sitemap.xml
```

**Status:** ☐ Deployed | ☐ Verified

---

### 1.2 Install and Configure RankMath SEO

**Documentation:** `wordpress/RANKMATH-SETUP.md`

#### Installation

```bash
# Option 1: Via WordPress Admin
# 1. Network Admin → Plugins → Add New
# 2. Search: "Rank Math"
# 3. Install and Network Activate

# Option 2: Via WP-CLI
docker compose exec wordpress wp plugin install seo-by-rank-math --activate-network
```

**Status:** ☐ Installed | ☐ Network Activated

#### Configuration Checklist

Follow `RANKMATH-SETUP.md` for detailed instructions. Quick checklist:

- ☐ **Setup Wizard completed** (both sites)
- ☐ **Google Search Console connected**
- ☐ **Titles & Meta configured:**
  - ☐ Homepage title and description
  - ☐ Default post/page formats
  - ☐ Canonical URLs enabled
- ☐ **Open Graph configured:**
  - ☐ Facebook OG enabled
  - ☐ Default OG image uploaded (1200x630px)
  - ☐ Twitter Cards enabled
- ☐ **XML Sitemaps enabled:**
  - ☐ Posts included
  - ☐ Pages included
  - ☐ Images included
- ☐ **Sitemap submitted to GSC** (both domains)

**Verification:**

```bash
# Test canonical tags
curl -s https://daily.dscp.team | grep canonical
# Expected: <link rel="canonical" href="https://daily.dscp.team/" />

# Test Open Graph tags
curl -s https://daily.dscp.team | grep 'og:'
# Expected: Multiple <meta property="og:..."> tags

# Test sitemap exists
curl -s https://daily.dscp.team/sitemap_index.xml | head -20
# Expected: XML with sitemap list
```

**Status:** ☐ Configured | ☐ Verified

---

### 1.3 Deactivate Old Meta Tags Plugin

**Current plugin:** "Meta Tags Plugin" (by DSCP)

```bash
# Deactivate via WP-CLI
docker compose exec wordpress wp plugin deactivate meta-tags-plugin

# Or via WordPress Admin:
# Plugins → All Plugins → Meta Tags Plugin → Deactivate
```

**Status:** ☐ Deactivated | ☐ Deleted (optional)

---

## Phase 2: Nginx Performance Optimization

### 2.1 Backup Current nginx Configuration

```bash
# SSH into VPS
ssh root@91.98.39.164
cd /opt/wordpress

# Backup current config
docker compose exec nginx cp /etc/nginx/conf.d/wordpress.conf /etc/nginx/conf.d/wordpress.conf.backup
```

**Status:** ☐ Backed up

---

### 2.2 Upload Updated nginx Configuration

**File:** `wordpress/nginx/conf.d/wordpress.conf`
**Changes include:**
- Referral parameter stripping (`?ref=`)
- Enhanced security headers
- Gzip compression optimization
- Advanced caching rules
- Font CORS headers
- PHP version hiding

```bash
# From your local machine
cd /Users/jakubwarchol/Dev/minecraft-server-piekarnia/wordpress

# Copy updated config to VPS
scp nginx/conf.d/wordpress.conf root@91.98.39.164:/opt/wordpress/nginx/conf.d/wordpress.conf
```

**Status:** ☐ Uploaded

---

### 2.3 Test and Apply nginx Configuration

```bash
# SSH into VPS
ssh root@91.98.39.164
cd /opt/wordpress

# Test nginx configuration syntax
docker compose exec nginx nginx -t

# Expected output:
# nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
# nginx: configuration file /etc/nginx/nginx.conf test is successful
```

**If test passes:**

```bash
# Restart nginx to apply changes
docker compose restart nginx

# Verify nginx is running
docker compose ps nginx
# Expected: STATUS = Up X seconds
```

**If test fails:**

```bash
# Restore backup
docker compose exec nginx cp /etc/nginx/conf.d/wordpress.conf.backup /etc/nginx/conf.d/wordpress.conf
docker compose restart nginx

# Review error messages and fix configuration
```

**Status:** ☐ Tested | ☐ Applied | ☐ Verified

---

### 2.4 Verify nginx Optimizations

```bash
# Test referral parameter stripping
curl -I "https://daily.dscp.team/?ref=test"
# Check if parameter is stripped (WordPress shouldn't see it)

# Test gzip compression
curl -H "Accept-Encoding: gzip" -I https://daily.dscp.team
# Expected: Content-Encoding: gzip

# Test security headers
curl -I https://daily.dscp.team | grep -E "X-Content-Type-Options|X-Frame-Options|Referrer-Policy"
# Expected: Multiple security headers present

# Test static asset caching
curl -I https://daily.dscp.team/wp-content/themes/[theme]/style.css
# Expected: Cache-Control: public, immutable
```

**Status:** ☐ Verified

---

## Phase 3: WordPress Caching

### 3.1 Install WP Super Cache

**Documentation:** `wordpress/CACHING-SETUP.md`

```bash
# Via WP-CLI
docker compose exec wordpress wp plugin install wp-super-cache --activate-network

# Or via WordPress Admin:
# Network Admin → Plugins → Add New → Search "WP Super Cache" → Install → Network Activate
```

**Status:** ☐ Installed | ☐ Network Activated

---

### 3.2 Configure WP Super Cache for daily.dscp.team

**Full instructions:** `CACHING-SETUP.md`

Quick setup checklist:

1. **Navigate to:** https://daily.dscp.team/wp-admin/ → Settings → WP Super Cache

2. **Caching Tab:**
   - ☐ Enable: "Caching On (Recommended)"
   - ☐ Select: "Simple" delivery method
   - ☐ Enable: "Compress pages"
   - ☐ Enable: "Don't cache pages for known users"
   - ☐ Enable: "Cache rebuild"

3. **Advanced Tab:**
   - ☐ Enable: "Enable dynamic caching"
   - ☐ Enable: "Clear all cache files when post/page published"
   - ☐ Set cache timeout: 3600 seconds (1 hour)
   - ☐ Add rejected URLs:
     ```
     /wp-admin/
     /wp-login.php
     ```

4. **Preload Tab:**
   - ☐ Enable: "Preload mode"
   - ☐ Set interval: 600 minutes
   - ☐ Click: "Preload Cache Now"

**Status:** ☐ Configured | ☐ Cache preloaded

---

### 3.3 Verify Caching is Working

```bash
# Test page load time (before cache)
curl -o /dev/null -s -w "Time: %{time_total}s\n" https://daily.dscp.team

# Visit page to generate cache
curl -s https://daily.dscp.team > /dev/null

# Test page load time (after cache)
curl -o /dev/null -s -w "Time: %{time_total}s\n" https://daily.dscp.team
# Expected: Much faster (0.2-0.5s vs 1-2s)

# Check for cache comment in HTML
curl -s https://daily.dscp.team | tail -20 | grep -i cache
# Expected: "Cached page generated by WP-Super-Cache"
```

**Status:** ☐ Cache working | ☐ Performance improved

---

### 3.4 Repeat for Main Site (dscp.team)

If you want caching on the main site as well:

1. **Switch to:** https://dscp.team/wp-admin/
2. **Repeat steps 3.2-3.3** for main site

**Status:** ☐ Configured (optional) | ☐ Verified (optional)

---

## Phase 4: Google Search Console

### 4.1 Submit Sitemaps

**For daily.dscp.team:**

1. Go to: https://search.google.com/search-console
2. Select property: **daily.dscp.team**
3. Navigate to: **Sitemaps** (left menu)
4. Add sitemap: `sitemap_index.xml`
5. Click: **Submit**

**Status:** ☐ Submitted | ☐ Successfully processed

**For dscp.team:** (if applicable)

1. Select property: **dscp.team**
2. Add sitemap: `sitemap_index.xml`
3. Click: **Submit**

**Status:** ☐ Submitted | ☐ Successfully processed

---

### 4.2 Configure URL Parameters (Optional)

**Documentation:** `wordpress/GSC-URL-PARAMETERS.md`

**Note:** This is optional since your canonical tags already work correctly.

If you want to explicitly tell Google to ignore `ref` parameters:

1. Go to: Search Console → **Legacy tools and reports** → **URL Parameters**
2. Add parameter: `ref`
3. Purpose: **Tracks users or traffic**
4. Effect: **No: Doesn't change page content**
5. Crawl setting: **Let Googlebot decide**

**Status:** ☐ Configured (optional) | ☐ Skipped

---

### 4.3 Verify Canonical Tags in GSC

For each problematic ref URL from your original report:

1. **Open URL Inspection:** https://search.google.com/search-console
2. **Inspect:** `https://daily.dscp.team/?ref=aiproductlist.org`
3. **Verify:**
   - Google-selected canonical: `https://daily.dscp.team/`
   - User-declared canonical: `https://daily.dscp.team/`
   - Status: "URL is an alternate version"

**Repeat for:**
- ☐ `?ref=productcool`
- ☐ `?ref=make.rs`
- ☐ `?ref=indietool.io`

**Status:** ☐ All verified correct

---

## Phase 5: Performance Testing

### 5.1 Baseline Performance Metrics

**Before optimizations:**
- Document current performance for comparison

**Tools:**
1. Google PageSpeed Insights: https://pagespeed.web.dev/
2. GTmetrix: https://gtmetrix.com/
3. WebPageTest: https://webpagetest.org/

**Metrics to record:**
- Page load time: _____ seconds
- Time to First Byte (TTFB): _____ ms
- First Contentful Paint (FCP): _____ seconds
- Largest Contentful Paint (LCP): _____ seconds
- PageSpeed Insights score: _____ / 100

**Status:** ☐ Baseline recorded

---

### 5.2 After Optimization Performance Test

**After all optimizations deployed:**

Test with same tools:

**New metrics:**
- Page load time: _____ seconds (Expected: 70-80% improvement)
- Time to First Byte (TTFB): _____ ms (Expected: 85% improvement)
- First Contentful Paint (FCP): _____ seconds (Expected: 60% improvement)
- Largest Contentful Paint (LCP): _____ seconds (Expected: 50% improvement)
- PageSpeed Insights score: _____ / 100 (Expected: +20-30 points)

**Status:** ☐ Tested | ☐ Improvements verified

---

### 5.3 Browser Testing

Test in multiple browsers:

- ☐ **Chrome Desktop:** Page loads correctly, cache working
- ☐ **Firefox Desktop:** Page loads correctly, cache working
- ☐ **Safari Desktop:** Page loads correctly, cache working
- ☐ **Chrome Mobile:** Page loads correctly, responsive
- ☐ **Safari Mobile:** Page loads correctly, responsive

**Check:**
- ☐ All pages load without errors
- ☐ Images load correctly
- ☐ CSS/JS working
- ☐ No console errors (F12 → Console)

**Status:** ☐ All browsers tested

---

## Phase 6: Monitoring Setup

### 6.1 Set Up Monitoring

**Google Search Console:**
- ☐ Email alerts enabled for critical issues
- ☐ Weekly performance summary enabled

**WordPress:**
- ☐ WP Super Cache statistics page bookmarked
- ☐ RankMath SEO Analysis reviewed

**Server:**
- ☐ Document how to check Docker logs: `docker compose logs -f nginx wordpress`
- ☐ Document how to check resource usage: `docker stats`

**Status:** ☐ Monitoring configured

---

### 6.2 Create Maintenance Schedule

**Weekly tasks:**
- ☐ Check GSC for new crawl errors
- ☐ Review cache hit rate in WP Super Cache

**Monthly tasks:**
- ☐ Review GSC coverage report for ref URL count
- ☐ Check PageSpeed Insights score
- ☐ Update WordPress core + plugins
- ☐ Clear cache if needed: Settings → WP Super Cache → Delete Cache

**Quarterly tasks:**
- ☐ Review server resource usage
- ☐ Audit for new performance issues
- ☐ Update nginx configuration if needed

**Status:** ☐ Schedule documented

---

## Phase 7: Final Verification

### 7.1 Complete Feature Verification

Run all verification tests in sequence:

**SEO:**
```bash
# Canonical tags
curl -s https://daily.dscp.team | grep canonical
# ✓ Expected: <link rel="canonical" href="https://daily.dscp.team/" />

# Open Graph tags
curl -s https://daily.dscp.team | grep 'og:' | head -5
# ✓ Expected: Multiple OG tags (og:title, og:description, og:image, etc.)

# Twitter Cards
curl -s https://daily.dscp.team | grep 'twitter:' | head -3
# ✓ Expected: Twitter card tags (twitter:card, twitter:title, etc.)

# robots.txt
curl https://daily.dscp.team/robots.txt | grep -i "disallow.*ref"
# ✓ Expected: Disallow: /*?ref=*

# Sitemap
curl -s https://daily.dscp.team/sitemap_index.xml | head -10
# ✓ Expected: XML sitemap with URLs
```

**Performance:**
```bash
# Gzip compression
curl -H "Accept-Encoding: gzip" -I https://daily.dscp.team | grep "Content-Encoding"
# ✓ Expected: Content-Encoding: gzip

# Cache-Control headers
curl -I https://daily.dscp.team/wp-content/themes/[theme]/style.css | grep "Cache-Control"
# ✓ Expected: Cache-Control: public, immutable

# Page caching
curl -s https://daily.dscp.team | tail -10 | grep -i "super cache"
# ✓ Expected: Comment with cache timestamp

# Security headers
curl -I https://daily.dscp.team | grep -E "X-Content-Type-Options|X-Frame-Options"
# ✓ Expected: Both headers present
```

**Status:** ☐ All verifications passed

---

### 7.2 Social Sharing Tests

Test how your site appears when shared:

**Facebook Sharing Debugger:**
1. Visit: https://developers.facebook.com/tools/debug/
2. Enter: `https://daily.dscp.team`
3. Click: **Debug**

**Expected:**
- ☐ Title correct
- ☐ Description correct
- ☐ Image displays (1200x630px)
- ☐ No errors or warnings

**Twitter Card Validator:**
1. Visit: https://cards-dev.twitter.com/validator
2. Enter: `https://daily.dscp.team`

**Expected:**
- ☐ Card preview displays correctly
- ☐ Title, description, image correct

**Status:** ☐ Social sharing verified

---

### 7.3 Rich Results Test

**Google Rich Results Test:**
1. Visit: https://search.google.com/test/rich-results
2. Enter: `https://daily.dscp.team`
3. Click: **Test URL**

**Expected:**
- ☐ Valid structured data detected
- ☐ No errors
- ☐ Schema types correctly identified (Article, WebPage, etc.)

**Status:** ☐ Rich results verified

---

## Completion Summary

### Implementation Checklist

**Phase 1: SEO Foundation**
- ☐ robots.txt deployed
- ☐ RankMath installed and configured
- ☐ Old Meta Tags Plugin deactivated

**Phase 2: Nginx Optimization**
- ☐ nginx config backed up
- ☐ Updated config deployed
- ☐ nginx restarted successfully
- ☐ Optimizations verified

**Phase 3: WordPress Caching**
- ☐ WP Super Cache installed
- ☐ Caching configured for daily.dscp.team
- ☐ Cache preload completed
- ☐ Caching verified working

**Phase 4: Google Search Console**
- ☐ Sitemaps submitted
- ☐ URL parameters configured (optional)
- ☐ Canonical tags verified in GSC

**Phase 5: Performance Testing**
- ☐ Baseline metrics recorded
- ☐ Post-optimization metrics recorded
- ☐ Performance improvements verified
- ☐ Browser testing completed

**Phase 6: Monitoring**
- ☐ Monitoring tools configured
- ☐ Maintenance schedule created

**Phase 7: Final Verification**
- ☐ All feature tests passed
- ☐ Social sharing verified
- ☐ Rich results verified

---

## Expected Results

### SEO Improvements

**Before:**
- ❌ Google Search Console showing ref parameter issues
- ⚠️ No Open Graph / Twitter Cards
- ⚠️ Limited meta descriptions
- ❌ No robots.txt

**After:**
- ✅ GSC ref parameter issues resolved (over 3-6 months)
- ✅ Complete Open Graph and Twitter Card support
- ✅ Proper meta descriptions on all pages
- ✅ robots.txt with proper directives
- ✅ XML sitemaps submitted to GSC

### Performance Improvements

**Before:**
- Page load: ~1.5-2.0s
- TTFB: ~800-1200ms
- PageSpeed score: ~60-75

**After:**
- Page load: ~0.2-0.5s (70-80% faster)
- TTFB: ~50-150ms (85-90% faster)
- PageSpeed score: ~85-95 (+20-30 points)

---

## Troubleshooting

### If Something Goes Wrong

**Nginx won't start:**
```bash
# Check logs
docker compose logs nginx

# Restore backup
docker compose exec nginx cp /etc/nginx/conf.d/wordpress.conf.backup /etc/nginx/conf.d/wordpress.conf
docker compose restart nginx
```

**Cache not working:**
```bash
# Check WP Super Cache status
docker compose exec wordpress wp cache flush
docker compose exec wordpress wp plugin list | grep super-cache

# Regenerate cache
# Visit: Settings → WP Super Cache → Delete Cache → Preload Cache Now
```

**Canonical tags not appearing:**
```bash
# Verify RankMath is active
docker compose exec wordpress wp plugin list | grep rank-math

# Check RankMath settings
# Visit: Rank Math → Titles & Meta → Misc → Canonical enabled
```

**Site is down:**
```bash
# Check all containers are running
docker compose ps

# Restart all services
docker compose restart

# Check logs
docker compose logs -f
```

---

## Post-Implementation

### Next Steps

1. **Monitor GSC for 1 week:**
   - Check for new errors
   - Verify sitemap processing

2. **Performance monitoring:**
   - Run PageSpeed Insights weekly for 1 month
   - Track improvements

3. **User testing:**
   - Get feedback on page load speeds
   - Test on various devices

4. **Iterate:**
   - Fine-tune cache settings based on traffic patterns
   - Adjust robots.txt if new parameters appear

---

## Support Resources

**Documentation:**
- RankMath: `wordpress/RANKMATH-SETUP.md`
- Caching: `wordpress/CACHING-SETUP.md`
- GSC: `wordpress/GSC-URL-PARAMETERS.md`

**Online Resources:**
- RankMath KB: https://rankmath.com/kb/
- WP Super Cache: https://wordpress.org/plugins/wp-super-cache/
- Google Search Console: https://search.google.com/search-console

**Testing Tools:**
- PageSpeed Insights: https://pagespeed.web.dev/
- Facebook Debugger: https://developers.facebook.com/tools/debug/
- Twitter Validator: https://cards-dev.twitter.com/validator
- Rich Results Test: https://search.google.com/test/rich-results

---

**Total Implementation Time:** ~45-60 minutes
**Cost:** $0
**Expected Impact:** 70-80% performance improvement + SEO issues resolved
**Status:** Ready to implement ✅
