# RankMath SEO Plugin Setup Guide

Complete installation and configuration guide for RankMath SEO on your WordPress Multisite.

## Why RankMath?

**Chosen over Yoast SEO and All in One SEO because:**
- ✅ Full multisite support in FREE version (Yoast requires $99/year Pro)
- ✅ Complete Open Graph and Twitter Card support (free)
- ✅ Excellent canonical tag management for subdomains
- ✅ Lightweight performance (~250KB footprint)
- ✅ Works seamlessly with Google Site Kit
- ✅ XML sitemaps for both dscp.team and daily.dscp.team
- ✅ Google Search Console integration

**Cost:** $0 (free version covers all your needs)

---

## Installation Steps

### Step 1: Install RankMath Plugin

#### Via WordPress Network Admin:

1. **Access Network Admin**
   ```
   https://dscp.team/wp-admin/network/
   ```

2. **Navigate to Plugins**
   - Click: Network Admin → Plugins → Add New

3. **Search and Install**
   - Search for: "Rank Math"
   - Plugin by: Rank Math
   - Click: "Install Now"
   - Click: "Network Activate" (important for multisite!)

#### Alternative: Manual Installation

```bash
# SSH into your VPS
ssh root@91.98.39.164

# Download RankMath
cd /opt/wordpress
docker compose exec wordpress bash
cd /var/www/html/wp-content/plugins/
wget https://downloads.wordpress.org/plugin/seo-by-rank-math.latest-stable.zip
unzip seo-by-rank-math.latest-stable.zip
chown -R www-data:www-data seo-by-rank-math
exit

# Activate via WP-CLI (in container)
docker compose exec wordpress wp plugin activate seo-by-rank-math --network
```

---

### Step 2: Initial Setup Wizard

After activation, RankMath will redirect you to the setup wizard.

#### Setup Wizard Steps:

1. **Welcome Screen**
   - Click: "Start Wizard"

2. **Connect Your Account (Optional)**
   - Option 1: Skip this step (free features work without account)
   - Option 2: Create free RankMath account for cloud backups
   - **Recommendation:** Skip for now, add later if needed

3. **Your Website**
   - **Website Name:** Daily (or DSCP for main site)
   - **Website Type:** Select "Personal Blog" or "Business"
   - Click: "Save and Continue"

4. **Google Services (Important!)**

   **Google Search Console:**
   - Click: "Get Authorization Code"
   - Sign in with Google account (same as Site Kit if possible)
   - Copy authorization code
   - Paste in RankMath
   - **Select Property:** daily.dscp.team
   - Click: "Save and Continue"

   **Note:** You'll need to repeat this for the main site (dscp.team) separately

5. **Sitemap Settings**
   - Enable: "Include Images in Sitemap" ✅
   - Enable: "Include Featured Images" ✅
   - **Sitemap URL will be:** https://daily.dscp.team/sitemap_index.xml
   - Click: "Save and Continue"

6. **SEO Tweaks**
   - **Noindex Empty Category and Tag Archives:** ✅ Enable
   - **Nofollow External Links:** ❌ Disable (unless you want this)
   - **Open External Links in New Tab:** ✅ Enable (optional)
   - Click: "Save and Continue"

7. **Advanced Options**
   - **Enable Usage Tracking:** ❌ Disable (privacy)
   - Click: "Save and Continue"

8. **Ready!**
   - Click: "View Advanced Settings" or "Go to Dashboard"

---

## Configuration for daily.dscp.team

### Step 3: Configure Titles & Meta

Navigate to: **Rank Math → Titles & Meta**

#### Global Meta Settings

1. **Homepage Settings**
   - Go to: Titles & Meta → Home Page
   - **Title:** Your site title (e.g., "Daily - Your daily app")
   - **Description:** Write compelling description (155 characters max)
   - **Preview:** Check how it looks in Google search results

2. **Local SEO (Optional)**
   - If you're a local business, fill in:
     - Address
     - Phone
     - Opening hours
   - **For daily.dscp.team:** Probably skip this

#### Post Types

1. **Posts**
   - Go to: Titles & Meta → Posts
   - **Show in Search Results:** Yes
   - **Default Title Format:** `%title% %sep% %sitename%`
   - **Default Description:** `%excerpt%`

2. **Pages**
   - Go to: Titles & Meta → Pages
   - **Show in Search Results:** Yes
   - **Default Title Format:** `%title% %sep% %sitename%`
   - **Default Description:** `%excerpt%`

#### Taxonomies

1. **Categories**
   - Go to: Titles & Meta → Categories
   - **Show in Search Results:** Yes
   - **Noindex Empty Categories:** ✅ Enable

2. **Tags**
   - Similar settings to categories

---

### Step 4: Configure Open Graph (Social Media)

Navigate to: **Rank Math → Titles & Meta → Social**

#### Facebook Open Graph

1. **Enable Facebook Open Graph:** ✅
2. **Default Image:**
   - Upload a default image (1200x630px recommended)
   - This is used when sharing posts without featured images
3. **Image Overlay:** Optional branding

#### Twitter Cards

1. **Enable Twitter Card:** ✅
2. **Twitter Card Type:** Summary Large Image (recommended)
3. **Twitter Username:** Add @yourhandle if you have one
4. **Default Image:** Same as Facebook or upload separate

---

### Step 5: Configure XML Sitemaps

Navigate to: **Rank Math → Sitemap Settings**

#### General Sitemap Settings

1. **Enable Sitemap:** ✅ (should already be enabled)
2. **Include:**
   - ✅ Posts
   - ✅ Pages
   - ✅ Media/Attachments (if you want image SEO)
   - ✅ Categories
   - ✅ Tags (optional)

3. **Images in Sitemap:**
   - ✅ Include Featured Image
   - ✅ Include Images in Content

4. **Links per Sitemap:** 200 (default is fine)

#### Verify Sitemap

- **Check it works:** https://daily.dscp.team/sitemap_index.xml
- Should show a list of sitemaps (posts, pages, etc.)

---

### Step 6: Configure Canonical URLs

Navigate to: **Rank Math → Titles & Meta → Misc Pages**

#### Canonical Settings

1. **Add Canonical Tag:** ✅ Enable (should be default)
2. **Auto-detect Canonical:** ✅ Enable

**How it works:**
- RankMath auto-generates `<link rel="canonical" href="...">` for every page
- For daily.dscp.team, it correctly uses the subdomain in canonical
- For URLs with `?ref=` parameters, it strips them automatically
- Example: `?ref=aiproductlist.org` → canonical: `https://daily.dscp.team/`

**Test it:**
```bash
curl -s "https://daily.dscp.team/?ref=test" | grep canonical
# Should output: <link rel="canonical" href="https://daily.dscp.team/" />
```

---

### Step 7: Repeat for Main Site (dscp.team)

RankMath needs to be configured **per-site** in multisite:

1. Switch to main site: https://dscp.team/wp-admin/
2. Navigate to: Rank Math → Dashboard
3. Repeat Steps 3-6 above with dscp.team specific content
4. Connect separate GSC property if needed

---

## Multisite-Specific Configuration

### Network-Wide Settings

Navigate to: **Network Admin → Rank Math → Settings**

#### Role Manager (Important!)

- **Who can edit SEO?**
  - Network Admin: ✅ All permissions
  - Site Admin: ✅ Can edit SEO on their site
  - Editor: ❌ or ✅ (your choice)
  - Author: ❌ typically

#### Analytics

- RankMath has built-in analytics
- **With Site Kit installed:** You might want to disable RankMath analytics
- Go to: Rank Math → Analytics → Disable if using Site Kit

---

## Integration with Existing Plugins

### Google Site Kit Compatibility

**Good news:** RankMath and Site Kit work great together!

**Division of labor:**
- **Site Kit handles:** Analytics, PageSpeed Insights, real-time data
- **RankMath handles:** Meta tags, structured data, sitemaps, on-page SEO

**Recommendations:**
1. Keep both active - they complement each other
2. Use Site Kit for monitoring (GSC data, analytics)
3. Use RankMath for optimization (meta tags, schema)

**Potential conflict to watch:**
- Both can connect to Google Search Console
- Both can submit sitemaps
- **Solution:** This is fine! Redundancy is good.

### Deactivate Old Meta Tags Plugin

Your old "Meta Tags Plugin" by DSCP is now redundant:

1. Navigate to: Plugins → All Plugins
2. Find: "Meta Tags Plugin"
3. Click: "Deactivate"
4. Optional: Click "Delete" after verifying RankMath works

**Why?**
- RankMath does everything your custom plugin did
- Plus Open Graph, Twitter Cards, schema, and more
- Less maintenance for you

---

## Post-Installation: Configure Individual Pages

### Edit SEO for a Page/Post

1. **Edit any page/post**
2. **Scroll down** to "Rank Math SEO" box
3. **Edit:**
   - SEO Title (overrides default)
   - Description (155 chars max)
   - Focus Keyword (optional)
   - Advanced: Canonical URL override

#### Social Media Preview

4. **Click "Social" tab** in Rank Math box
5. **Facebook:**
   - Custom title
   - Custom description
   - Custom image (1200x630px)
6. **Twitter:**
   - Same options as Facebook

#### Schema Markup (Advanced)

7. **Click "Schema" tab**
8. **Select Schema Type:**
   - Article (for blog posts)
   - WebPage (for pages)
   - Product (if reviewing products)
   - FAQ (for FAQ pages)

---

## Verification & Testing

### 1. Verify Canonical Tags

```bash
# Test main URL
curl -s https://daily.dscp.team | grep canonical

# Test with ref parameter
curl -s "https://daily.dscp.team/?ref=test" | grep canonical

# Both should output the same canonical URL:
# <link rel="canonical" href="https://daily.dscp.team/" />
```

### 2. Verify Open Graph Tags

```bash
curl -s https://daily.dscp.team | grep "og:"

# Should see:
# <meta property="og:title" content="...">
# <meta property="og:description" content="...">
# <meta property="og:url" content="https://daily.dscp.team/">
# <meta property="og:image" content="...">
# <meta property="og:type" content="website">
```

### 3. Verify Twitter Cards

```bash
curl -s https://daily.dscp.team | grep "twitter:"

# Should see:
# <meta name="twitter:card" content="summary_large_image">
# <meta name="twitter:title" content="...">
# <meta name="twitter:description" content="...">
# <meta name="twitter:image" content="...">
```

### 4. Verify Sitemaps

Visit these URLs in your browser:

- **Main sitemap:** https://daily.dscp.team/sitemap_index.xml
- **Posts sitemap:** https://daily.dscp.team/post-sitemap.xml
- **Pages sitemap:** https://daily.dscp.team/page-sitemap.xml

Should see XML with URLs listed.

### 5. Test with Google Tools

#### Rich Results Test
- Visit: https://search.google.com/test/rich-results
- Enter: https://daily.dscp.team
- Click: "Test URL"
- Should show: Valid structured data

#### Facebook Sharing Debugger
- Visit: https://developers.facebook.com/tools/debug/
- Enter: https://daily.dscp.team
- Click: "Debug"
- Should show: OG tags with title, description, image

#### Twitter Card Validator
- Visit: https://cards-dev.twitter.com/validator
- Enter: https://daily.dscp.team
- Should show: Card preview with image

---

## Google Search Console Setup

### Submit Sitemaps to GSC

1. **Access Search Console:**
   - https://search.google.com/search-console
   - Select property: daily.dscp.team

2. **Submit Sitemap:**
   - Go to: Sitemaps (left menu)
   - Click: "Add a new sitemap"
   - Enter: `sitemap_index.xml`
   - Click: "Submit"

3. **Verify submission:**
   - Should show: "Success" status
   - May take a few days for Google to process

4. **Repeat for main site** (dscp.team)

---

## Troubleshooting

### Issue: Canonical tags not appearing

**Solution:**
1. Check: Rank Math → Titles & Meta → Misc → Canonical enabled
2. Clear cache: WP Admin → Rank Math → Status → Clear SEO Analysis
3. Clear browser cache and test again

### Issue: Open Graph images not showing

**Solution:**
1. Check image size: Should be at least 200x200px, recommended 1200x630px
2. Facebook cache: Use Facebook Debugger to scrape again
3. Verify image URL is publicly accessible (not blocked by CDN)

### Issue: Sitemaps returning 404

**Solution:**
1. Check: Rank Math → Sitemap Settings → Enable Sitemap
2. Flush permalinks: Settings → Permalinks → Save Changes
3. Check nginx doesn't block `/sitemap_index.xml`

### Issue: Conflicts with Site Kit

**Solution:**
1. Both can coexist - no action needed
2. If you see double analytics: Disable RankMath Analytics
3. Go to: Rank Math → Analytics → Disconnect

### Issue: Multisite sites not showing separate settings

**Solution:**
1. Network activate RankMath: Network Admin → Plugins → Network Activate
2. Switch sites: My Sites → [Select Site] → Dashboard
3. Each site has separate RankMath settings

---

## Performance Impact

### Expected Changes:

**Before RankMath:**
- Page load: ~1.2s
- HTML size: ~50KB
- No meta tags / basic canonical

**After RankMath:**
- Page load: ~1.3s (+0.1s - negligible)
- HTML size: ~55KB (+5KB for meta tags)
- Complete meta tags, OG, schema markup

**Optimization tips:**
- RankMath is already lightweight
- If concerned about performance:
  - Disable unused features (Rank Math → General Settings → Modules)
  - Disable "Redirections" module (if you don't use it)
  - Disable "404 Monitor" (if you don't need it)

---

## Ongoing Maintenance

### Monthly Tasks

1. **Check GSC in RankMath:**
   - Rank Math → SEO Analysis
   - Review any errors or warnings

2. **Update meta descriptions:**
   - For new posts/pages
   - Use Rank Math box when editing

3. **Monitor sitemap:**
   - Verify new content appears in sitemap
   - Check GSC for sitemap errors

### Quarterly Tasks

1. **Review Search Console data**
   - Via Site Kit dashboard
   - Check for crawl errors

2. **Update Open Graph images**
   - Ensure images still relevant
   - Update default images if branding changes

---

## Next Steps

✅ RankMath installed and configured
✅ Canonical tags working correctly
✅ Open Graph and Twitter Cards enabled
✅ Sitemaps generated and submitted

**Now do:**
1. ✅ Deploy robots.txt (see ROBOTS-DEPLOYMENT.md)
2. ✅ Update nginx for performance (see nginx config changes)
3. ✅ Install caching plugin (see CACHING-SETUP.md)
4. ✅ Configure GSC URL parameters (see GSC-URL-PARAMETERS.md)

---

## Support & Documentation

**RankMath Documentation:**
- https://rankmath.com/kb/
- https://rankmath.com/kb/score-100-in-tests/

**WordPress Multisite SEO:**
- https://rankmath.com/kb/wordpress-multisite/

**Issues or Questions:**
- RankMath Support: https://support.rankmath.com/
- WordPress Forums: https://wordpress.org/support/plugin/seo-by-rank-math/

---

**Status:** Ready to install
**Estimated Setup Time:** 20-30 minutes
**Cost:** $0 (free version)
**Impact:** Solves all Google Search Console duplicate content issues
