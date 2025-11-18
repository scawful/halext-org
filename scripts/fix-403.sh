#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "========================================"
echo "  Halext Org 403 Forbidden Diagnostic"
echo "========================================"
echo ""

PROJECT_ROOT="/srv/halext.org/halext-org"

# 1. Check if backend is running
echo -e "${BLUE}1. Backend Status${NC}"
echo "-------------------"
if systemctl is-active --quiet halext-api.service; then
    echo -e "${GREEN}✓${NC} Backend service is running"

    # Test backend locally
    BACKEND_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/api/integrations/openwebui 2>/dev/null)
    if [ "$BACKEND_STATUS" = "200" ]; then
        echo -e "${GREEN}✓${NC} Backend responding on localhost:8000 (HTTP $BACKEND_STATUS)"
    else
        echo -e "${RED}✗${NC} Backend not responding properly (HTTP $BACKEND_STATUS)"
    fi
else
    echo -e "${RED}✗${NC} Backend service not running"
    echo "Fix: sudo systemctl start halext-api.service"
fi
echo ""

# 2. Check nginx config
echo -e "${BLUE}2. Nginx Configuration${NC}"
echo "-------------------"

NGINX_SITE="/etc/nginx/sites-enabled/halext-org"

if [ -f "$NGINX_SITE" ]; then
    echo -e "${GREEN}✓${NC} Nginx config exists: $NGINX_SITE"

    # Extract root path
    ROOT_PATH=$(grep -E "^\s*root\s+" "$NGINX_SITE" | head -1 | awk '{print $2}' | tr -d ';')

    if [ -n "$ROOT_PATH" ]; then
        echo -e "${BLUE}  Root path:${NC} $ROOT_PATH"

        if [ -d "$ROOT_PATH" ]; then
            echo -e "${GREEN}✓${NC} Root directory exists"
        else
            echo -e "${RED}✗${NC} Root directory does NOT exist!"
            echo -e "${YELLOW}  Expected:${NC} $ROOT_PATH"
            echo -e "${YELLOW}  Actual frontend dist:${NC} $PROJECT_ROOT/frontend/dist"
        fi
    else
        echo -e "${RED}✗${NC} No 'root' directive found in nginx config"
    fi

    # Check for API proxy
    if grep -q "location /api/" "$NGINX_SITE"; then
        echo -e "${GREEN}✓${NC} API proxy configured"
        PROXY_PASS=$(grep -A5 "location /api/" "$NGINX_SITE" | grep proxy_pass | awk '{print $2}' | tr -d ';')
        echo -e "${BLUE}  Proxy:${NC} $PROXY_PASS"
    else
        echo -e "${RED}✗${NC} No API proxy configuration found"
    fi
else
    echo -e "${RED}✗${NC} Nginx config not found: $NGINX_SITE"
    exit 1
fi
echo ""

# 3. Check frontend files
echo -e "${BLUE}3. Frontend Files${NC}"
echo "-------------------"

DIST_DIR="$PROJECT_ROOT/frontend/dist"

if [ -d "$DIST_DIR" ]; then
    echo -e "${GREEN}✓${NC} Frontend dist directory exists: $DIST_DIR"

    # Check if index.html exists
    if [ -f "$DIST_DIR/index.html" ]; then
        echo -e "${GREEN}✓${NC} index.html exists"

        # Check file size
        INDEX_SIZE=$(stat -f%z "$DIST_DIR/index.html" 2>/dev/null || stat -c%s "$DIST_DIR/index.html" 2>/dev/null)
        echo -e "${BLUE}  Size:${NC} $INDEX_SIZE bytes"

        if [ "$INDEX_SIZE" -lt 100 ]; then
            echo -e "${YELLOW}⚠${NC}  index.html seems too small, might be corrupted"
        fi
    else
        echo -e "${RED}✗${NC} index.html NOT found!"
        echo "Fix: cd $PROJECT_ROOT/frontend && npm run build"
    fi

    # Count files in dist
    FILE_COUNT=$(find "$DIST_DIR" -type f | wc -l)
    echo -e "${BLUE}  Total files:${NC} $FILE_COUNT"
else
    echo -e "${RED}✗${NC} Frontend dist directory does NOT exist!"
    echo "Fix: cd $PROJECT_ROOT/frontend && npm run build"
    exit 1
fi
echo ""

# 4. Check permissions
echo -e "${BLUE}4. File Permissions${NC}"
echo "-------------------"

# Check directory permissions
DIST_PERMS=$(stat -c "%a" "$DIST_DIR" 2>/dev/null || stat -f "%Lp" "$DIST_DIR" 2>/dev/null)
DIST_OWNER=$(stat -c "%U:%G" "$DIST_DIR" 2>/dev/null || stat -f "%Su:%Sg" "$DIST_DIR" 2>/dev/null)

echo -e "${BLUE}  Dist directory:${NC}"
echo -e "    Permissions: $DIST_PERMS"
echo -e "    Owner: $DIST_OWNER"

if [ -f "$DIST_DIR/index.html" ]; then
    INDEX_PERMS=$(stat -c "%a" "$DIST_DIR/index.html" 2>/dev/null || stat -f "%Lp" "$DIST_DIR/index.html" 2>/dev/null)
    INDEX_OWNER=$(stat -c "%U:%G" "$DIST_DIR/index.html" 2>/dev/null || stat -f "%Su:%Sg" "$DIST_DIR/index.html" 2>/dev/null)

    echo -e "${BLUE}  index.html:${NC}"
    echo -e "    Permissions: $INDEX_PERMS"
    echo -e "    Owner: $INDEX_OWNER"
fi

# Test if www-data can read
echo ""
echo -e "${BLUE}  Testing www-data access:${NC}"
if sudo -u www-data test -r "$DIST_DIR/index.html" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} www-data CAN read index.html"
else
    echo -e "${RED}✗${NC} www-data CANNOT read index.html"
    echo -e "${YELLOW}  This is likely your 403 issue!${NC}"
    FIX_NEEDED=true
fi

if sudo -u www-data test -x "$DIST_DIR" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} www-data CAN execute (enter) dist directory"
else
    echo -e "${RED}✗${NC} www-data CANNOT execute (enter) dist directory"
    echo -e "${YELLOW}  This is likely your 403 issue!${NC}"
    FIX_NEEDED=true
fi
echo ""

# 5. Check nginx error logs
echo -e "${BLUE}5. Recent Nginx Errors${NC}"
echo "-------------------"

if [ -f "/var/log/nginx/error.log" ]; then
    RECENT_403=$(sudo grep "403" /var/log/nginx/error.log | tail -5)

    if [ -n "$RECENT_403" ]; then
        echo -e "${RED}Recent 403 errors:${NC}"
        echo "$RECENT_403"
    else
        echo -e "${GREEN}✓${NC} No recent 403 errors in nginx log"
    fi

    echo ""
    echo -e "${BLUE}Last 3 nginx errors:${NC}"
    sudo tail -3 /var/log/nginx/error.log
else
    echo -e "${YELLOW}⚠${NC} Cannot access nginx error log"
fi
echo ""

# 6. Test endpoints
echo -e "${BLUE}6. Endpoint Tests${NC}"
echo "-------------------"

# Test root
ROOT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/ 2>/dev/null)
echo -e "${BLUE}  http://localhost/${NC} → HTTP $ROOT_STATUS"

if [ "$ROOT_STATUS" = "200" ]; then
    echo -e "${GREEN}✓${NC} Nginx serving frontend successfully"
elif [ "$ROOT_STATUS" = "403" ]; then
    echo -e "${RED}✗${NC} 403 Forbidden - permission issue"
else
    echo -e "${YELLOW}⚠${NC} Unexpected status"
fi

# Test API
API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/api/integrations/openwebui 2>/dev/null)
echo -e "${BLUE}  http://localhost/api/...${NC} → HTTP $API_STATUS"

if [ "$API_STATUS" = "200" ]; then
    echo -e "${GREEN}✓${NC} API proxy working"
else
    echo -e "${RED}✗${NC} API proxy not working"
fi
echo ""

# 7. Offer fixes
if [ "$FIX_NEEDED" = true ]; then
    echo "========================================"
    echo -e "${YELLOW}  FIXING PERMISSIONS${NC}"
    echo "========================================"
    echo ""

    read -p "Fix permissions now? (y/n) " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Applying fixes..."

        # Fix ownership and permissions
        sudo chown -R www-data:www-data "$DIST_DIR"
        sudo chmod -R 755 "$DIST_DIR"

        echo -e "${GREEN}✓${NC} Ownership set to www-data:www-data"
        echo -e "${GREEN}✓${NC} Permissions set to 755"

        # Restart nginx
        echo "Restarting nginx..."
        sudo systemctl restart nginx

        echo -e "${GREEN}✓${NC} Nginx restarted"
        echo ""

        # Test again
        sleep 2
        ROOT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/ 2>/dev/null)

        echo -e "${BLUE}Testing again...${NC}"
        echo -e "  http://localhost/ → HTTP $ROOT_STATUS"

        if [ "$ROOT_STATUS" = "200" ]; then
            echo ""
            echo -e "${GREEN}========================================${NC}"
            echo -e "${GREEN}  ✓ SUCCESS! 403 Fixed!${NC}"
            echo -e "${GREEN}========================================${NC}"
            echo ""
            echo "Try accessing https://org.halext.org in your browser now!"
        else
            echo ""
            echo -e "${YELLOW}Still getting HTTP $ROOT_STATUS${NC}"
            echo "There may be another issue. Checking nginx config..."

            # Show current nginx config
            echo ""
            echo "Current nginx config:"
            cat "$NGINX_SITE"
        fi
    fi
else
    echo "========================================"
    echo -e "${YELLOW}  Additional Checks${NC}"
    echo "========================================"
    echo ""

    if [ "$ROOT_STATUS" = "403" ]; then
        echo "Still getting 403, but permissions look OK."
        echo ""
        echo "Possible causes:"
        echo "1. Cloudflare firewall rules"
        echo "2. SELinux is enforcing"
        echo "3. Nginx config issue"
        echo ""

        # Check SELinux
        if command -v getenforce &> /dev/null; then
            SELINUX_STATUS=$(getenforce 2>/dev/null)
            echo "SELinux status: $SELINUX_STATUS"

            if [ "$SELINUX_STATUS" = "Enforcing" ]; then
                echo -e "${YELLOW}⚠${NC} SELinux is enforcing - this might cause 403"
                echo "Try: sudo setenforce 0"
            fi
        fi

        echo ""
        echo "Showing current nginx config:"
        echo "----------------------------"
        cat "$NGINX_SITE"
    fi
fi

echo ""
echo "========================================"
echo "  Summary"
echo "========================================"
echo ""
echo "If still having issues:"
echo "1. Check Cloudflare dashboard for firewall rules"
echo "2. Review nginx config: sudo nano $NGINX_SITE"
echo "3. Check nginx error logs: sudo tail -f /var/log/nginx/error.log"
echo "4. Test from command line: curl -I https://org.halext.org"
echo ""
