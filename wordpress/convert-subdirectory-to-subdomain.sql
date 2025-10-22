-- WordPress Multisite: Convert Subdirectory to Subdomain Structure
-- This script converts dscp.team/daily to daily.dscp.team
--
-- IMPORTANT:
-- 1. Backup your database before running this!
-- 2. Update wp-config.php FIRST (set SUBDOMAIN_INSTALL to true)
-- 3. Adjust table prefix if yours is different from wp_
-- 4. Adjust blog_id if your daily site is not ID 2

-- =====================================================
-- STEP 1: Check current configuration
-- =====================================================

SELECT 'Current Sites Configuration:' AS '';
SELECT blog_id, site_id, domain, path FROM wp_blogs;

SELECT '\nMain site options:' AS '';
SELECT option_name, option_value FROM wp_options
WHERE option_name IN ('siteurl', 'home');

SELECT '\nDaily site options:' AS '';
SELECT option_name, option_value FROM wp_2_options
WHERE option_name IN ('siteurl', 'home');

-- =====================================================
-- STEP 2: Update wp_blogs table (subdirectory to subdomain)
-- =====================================================

-- Update daily site from /daily/ to subdomain
UPDATE wp_blogs
SET domain = 'daily.dscp.team',
    path = '/'
WHERE path = '/daily/';

-- Verify the change
SELECT 'Updated Sites Configuration:' AS '';
SELECT blog_id, site_id, domain, path FROM wp_blogs;

-- =====================================================
-- STEP 3: Update site options tables
-- =====================================================

-- Update main site URLs (ensure they're correct)
UPDATE wp_options
SET option_value = 'https://dscp.team'
WHERE option_name = 'siteurl';

UPDATE wp_options
SET option_value = 'https://dscp.team'
WHERE option_name = 'home';

-- Update daily site URLs to subdomain
UPDATE wp_2_options
SET option_value = 'https://daily.dscp.team'
WHERE option_name = 'siteurl';

UPDATE wp_2_options
SET option_value = 'https://daily.dscp.team'
WHERE option_name = 'home';

-- =====================================================
-- STEP 4: Update content URLs in posts
-- =====================================================

-- Main site: Replace old domain if migrating from different host
-- UNCOMMENT and adjust if needed:
-- UPDATE wp_posts
-- SET post_content = REPLACE(post_content, 'http://old-domain.com', 'https://dscp.team')
-- WHERE post_content LIKE '%old-domain.com%';

-- Daily site: Replace subdirectory paths with subdomain
UPDATE wp_2_posts
SET post_content = REPLACE(post_content, 'dscp.team/daily/', 'daily.dscp.team/')
WHERE post_content LIKE '%dscp.team/daily/%';

UPDATE wp_2_posts
SET post_content = REPLACE(post_content, 'http://dscp.team/daily', 'https://daily.dscp.team')
WHERE post_content LIKE '%dscp.team/daily%';

UPDATE wp_2_posts
SET post_content = REPLACE(post_content, 'https://dscp.team/daily', 'https://daily.dscp.team')
WHERE post_content LIKE '%dscp.team/daily%';

-- =====================================================
-- STEP 5: Update GUIDs (optional but recommended)
-- =====================================================

-- Main site GUIDs
-- UNCOMMENT if migrating from different domain:
-- UPDATE wp_posts
-- SET guid = REPLACE(guid, 'http://old-domain.com', 'https://dscp.team')
-- WHERE guid LIKE '%old-domain.com%';

-- Daily site GUIDs
UPDATE wp_2_posts
SET guid = REPLACE(guid, 'dscp.team/daily/', 'daily.dscp.team/')
WHERE guid LIKE '%dscp.team/daily/%';

-- =====================================================
-- STEP 6: Update post meta (if any absolute URLs exist)
-- =====================================================

-- Check for URLs in post meta
SELECT meta_key, meta_value FROM wp_2_postmeta
WHERE meta_value LIKE '%dscp.team/daily%'
LIMIT 10;

-- Update post meta
UPDATE wp_2_postmeta
SET meta_value = REPLACE(meta_value, 'dscp.team/daily/', 'daily.dscp.team/')
WHERE meta_value LIKE '%dscp.team/daily/%';

UPDATE wp_2_postmeta
SET meta_value = REPLACE(meta_value, 'http://dscp.team/daily', 'https://daily.dscp.team')
WHERE meta_value LIKE '%dscp.team/daily%';

-- =====================================================
-- STEP 7: Update site metadata
-- =====================================================

-- Update network site meta if needed
UPDATE wp_sitemeta
SET meta_value = 'https://dscp.team'
WHERE meta_key = 'siteurl';

-- =====================================================
-- STEP 8: Update upload paths (if customized)
-- =====================================================

-- Check current upload paths
SELECT blog_id, option_name, option_value FROM wp_2_options
WHERE option_name LIKE '%upload%';

-- Remove /daily from upload path if present
UPDATE wp_2_options
SET option_value = REPLACE(option_value, '/daily', '')
WHERE option_name = 'upload_path' AND option_value LIKE '%/daily%';

-- =====================================================
-- STEP 9: Verify all changes
-- =====================================================

SELECT '\n=== VERIFICATION ===' AS '';

SELECT '\nSites table (should show subdomain):' AS '';
SELECT blog_id, domain, path FROM wp_blogs;

SELECT '\nMain site URLs:' AS '';
SELECT option_name, option_value FROM wp_options
WHERE option_name IN ('siteurl', 'home');

SELECT '\nDaily site URLs:' AS '';
SELECT option_name, option_value FROM wp_2_options
WHERE option_name IN ('siteurl', 'home');

SELECT '\nRemaining /daily references in posts (should be 0):' AS '';
SELECT COUNT(*) as count FROM wp_2_posts
WHERE post_content LIKE '%dscp.team/daily%'
   OR guid LIKE '%dscp.team/daily%';

SELECT '\nRemaining /daily references in postmeta (should be 0):' AS '';
SELECT COUNT(*) as count FROM wp_2_postmeta
WHERE meta_value LIKE '%dscp.team/daily%';

-- =====================================================
-- DONE!
-- =====================================================

SELECT '\n=== CONVERSION COMPLETE ===' AS '';
SELECT 'Remember to:' AS '';
SELECT '1. Update wp-config.php (SUBDOMAIN_INSTALL = true)' AS '';
SELECT '2. Update nginx configuration for both domains' AS '';
SELECT '3. Add DNS records for both dscp.team and daily.dscp.team' AS '';
SELECT '4. Get SSL certificates for both domains' AS '';
SELECT '5. Test both sites thoroughly' AS '';
