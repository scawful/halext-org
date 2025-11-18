#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

# Get script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo "============================================"
echo "   Halext Org Ubuntu Setup & Diagnostics"
echo "============================================"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    log_error "Please do not run this script as root. Run as normal user with sudo access."
    exit 1
fi

# ============================================
# 1. SYSTEM DIAGNOSTICS
# ============================================
echo ""
log_info "Step 1: Running System Diagnostics..."
echo "----------------------------------------"

# Check OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    log_info "Operating System: $NAME $VERSION"
else
    log_warning "Cannot detect OS version"
fi

# Check prerequisites
log_info "Checking prerequisites..."

# Node.js
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    log_success "Node.js: $NODE_VERSION"
else
    log_error "Node.js not found"
    log_info "Install with: sudo apt install -y nodejs npm"
    exit 1
fi

# npm
if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm --version)
    log_success "npm: $NPM_VERSION"
else
    log_error "npm not found"
    exit 1
fi

# Python 3
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    log_success "Python: $PYTHON_VERSION"
else
    log_error "Python 3 not found"
    log_info "Install with: sudo apt install -y python3 python3-pip python3-venv"
    exit 1
fi

# Check Python version is 3.8+
PYTHON_MAJOR=$(python3 -c 'import sys; print(sys.version_info.major)')
PYTHON_MINOR=$(python3 -c 'import sys; print(sys.version_info.minor)')
if [ "$PYTHON_MAJOR" -lt 3 ] || ([ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -lt 8 ]); then
    log_error "Python 3.8+ required, found Python $PYTHON_MAJOR.$PYTHON_MINOR"
    exit 1
fi

# PostgreSQL
if command -v psql &> /dev/null; then
    PSQL_VERSION=$(psql --version)
    log_success "PostgreSQL: $PSQL_VERSION"
    PG_RUNNING=$(systemctl is-active postgresql 2>/dev/null || echo "inactive")
    if [ "$PG_RUNNING" = "active" ]; then
        log_success "PostgreSQL service: Running"
    else
        log_warning "PostgreSQL service: Not running"
        log_info "Start with: sudo systemctl start postgresql"
    fi
else
    log_warning "PostgreSQL not found (optional for production)"
fi

# Nginx
if command -v nginx &> /dev/null; then
    NGINX_VERSION=$(nginx -v 2>&1 | cut -d'/' -f2)
    log_success "Nginx: $NGINX_VERSION"
    NGINX_RUNNING=$(systemctl is-active nginx 2>/dev/null || echo "inactive")
    if [ "$NGINX_RUNNING" = "active" ]; then
        log_success "Nginx service: Running"
    else
        log_warning "Nginx service: Not running"
    fi
else
    log_warning "Nginx not found (required for production)"
fi

# ============================================
# 2. BACKEND SETUP
# ============================================
echo ""
log_info "Step 2: Setting up Backend..."
echo "----------------------------------------"

cd "$PROJECT_ROOT/backend"

# Check if .env exists
if [ ! -f ".env" ]; then
    log_warning ".env file not found"
    log_info "Creating .env from template..."

    cat > .env << 'EOF'
# Database Configuration
DATABASE_URL=postgresql://halext_user:password@localhost/halext_org

# Security
SECRET_KEY=your-secret-key-change-this-in-production
ACCESS_CODE=your-access-code-change-this

# AI Configuration (Optional)
AI_PROVIDER=mock
AI_MODEL=llama3.1
# OPENWEBUI_URL=http://localhost:3000
# OPENWEBUI_PUBLIC_URL=https://org.halext.org/webui/
# OLLAMA_URL=http://localhost:11434

# Environment
ENVIRONMENT=production
EOF

    log_warning "Created .env file. IMPORTANT: Edit backend/.env with your actual values!"
    log_warning "Especially: DATABASE_URL, SECRET_KEY, and ACCESS_CODE"
else
    log_success ".env file exists"
fi

# Display current DATABASE_URL (masked)
if [ -f ".env" ]; then
    DB_URL=$(grep "^DATABASE_URL=" .env | cut -d'=' -f2- || echo "not set")
    DB_URL_MASKED=$(echo "$DB_URL" | sed 's/:[^:@]*@/:***@/')
    log_info "DATABASE_URL: $DB_URL_MASKED"
fi

# Create virtual environment
if [ ! -d "env" ]; then
    log_info "Creating Python virtual environment..."
    python3 -m venv env
    log_success "Virtual environment created"
else
    log_success "Virtual environment exists"
fi

# Activate and install dependencies
log_info "Installing Python dependencies..."
source env/bin/activate

if [ -f "requirements.txt" ]; then
    pip install --upgrade pip > /dev/null 2>&1
    pip install -r requirements.txt
    log_success "Python dependencies installed"
else
    log_error "requirements.txt not found"
    exit 1
fi

# Check if database is accessible
log_info "Testing database connection..."
python3 << 'PYEOF'
import os
import sys
from sqlalchemy import create_engine, text

try:
    # Load .env
    if os.path.exists('.env'):
        with open('.env') as f:
            for line in f:
                if line.strip() and not line.startswith('#'):
                    key, value = line.strip().split('=', 1)
                    os.environ[key] = value

    DATABASE_URL = os.getenv("DATABASE_URL", "")

    if not DATABASE_URL:
        print("✗ DATABASE_URL not set in .env")
        sys.exit(1)

    # Mask password in output
    masked_url = DATABASE_URL.split('@')[0].rsplit(':', 1)[0] + ':***@' + DATABASE_URL.split('@')[1] if '@' in DATABASE_URL else DATABASE_URL

    engine = create_engine(DATABASE_URL)
    with engine.connect() as conn:
        result = conn.execute(text("SELECT 1"))
        print("✓ Database connection successful")

        # Check if tables exist
        from sqlalchemy import inspect
        inspector = inspect(engine)
        tables = inspector.get_table_names()
        print(f"✓ Found {len(tables)} tables in database")

        if 'users' not in tables:
            print("⚠ Tables not created yet. Will be created on first run.")

except Exception as e:
    print(f"✗ Database connection failed: {e}")
    print("\nTroubleshooting:")
    print("1. Check DATABASE_URL in backend/.env")
    print("2. Ensure PostgreSQL is running: sudo systemctl start postgresql")
    print("3. Create database: sudo -u postgres createdb halext_org")
    print("4. Create user: sudo -u postgres createuser -P halext_user")
    sys.exit(1)
PYEOF

DB_EXIT=$?
if [ $DB_EXIT -ne 0 ]; then
    log_error "Database setup incomplete. See troubleshooting above."
    exit 1
fi

# ============================================
# 3. FRONTEND SETUP
# ============================================
echo ""
log_info "Step 3: Setting up Frontend..."
echo "----------------------------------------"

cd "$PROJECT_ROOT/frontend"

# Install dependencies
if [ ! -d "node_modules" ]; then
    log_info "Installing npm dependencies (this may take a while)..."
    npm install
    log_success "npm dependencies installed"
else
    log_info "npm dependencies already installed. Run 'npm install' to update."
fi

# Clean dist folder if it exists (handle permission issues)
if [ -d "dist" ]; then
    log_info "Cleaning existing dist folder..."

    # Try to remove normally first
    if rm -rf dist 2>/dev/null; then
        log_success "Removed old dist folder"
    else
        log_warning "Permission denied, using sudo to remove dist folder..."
        sudo rm -rf dist
        log_success "Removed old dist folder with sudo"
    fi
fi

# Build frontend
log_info "Building frontend for production..."
npm run build

if [ -d "dist" ]; then
    DIST_SIZE=$(du -sh dist | cut -f1)
    log_success "Frontend built successfully (size: $DIST_SIZE)"

    # Check index.html exists
    if [ -f "dist/index.html" ]; then
        log_success "dist/index.html exists"
    else
        log_error "dist/index.html missing!"
        exit 1
    fi

    # Set proper permissions for nginx
    log_info "Setting permissions for nginx..."

    # Make current user owner, www-data group
    sudo chown -R $USER:www-data dist/
    # Give read/execute permissions to all
    chmod -R 755 dist/

    log_success "Permissions set: $USER:www-data with 755"
else
    log_error "Frontend build failed - dist/ directory not created"
    exit 1
fi

# ============================================
# 4. CHECK OPENWEBUI
# ============================================
echo ""
log_info "Step 4: Checking OpenWebUI..."
echo "----------------------------------------"

# Check if OpenWebUI is running
OPENWEBUI_RUNNING=false

if command -v docker &> /dev/null; then
    log_success "Docker installed"

    # Check for OpenWebUI container
    if docker ps | grep -q "open-webui\|openwebui"; then
        OPENWEBUI_CONTAINER=$(docker ps --format "{{.Names}}" | grep -i "open-webui\|openwebui" | head -1)
        log_success "OpenWebUI container running: $OPENWEBUI_CONTAINER"
        OPENWEBUI_RUNNING=true

        # Get port
        OPENWEBUI_PORT=$(docker port "$OPENWEBUI_CONTAINER" 2>/dev/null | grep '8080/tcp' | cut -d':' -f2 || echo "unknown")
        log_info "OpenWebUI port: $OPENWEBUI_PORT"
    else
        log_warning "OpenWebUI container not running"
    fi
else
    log_warning "Docker not installed (required for OpenWebUI)"
fi

# Check if OpenWebUI is accessible
if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 2>/dev/null | grep -q "200\|302"; then
    log_success "OpenWebUI accessible on http://localhost:3000"
    OPENWEBUI_RUNNING=true
elif curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 2>/dev/null | grep -q "200\|302"; then
    log_success "OpenWebUI accessible on http://localhost:8080"
    OPENWEBUI_RUNNING=true
fi

if [ "$OPENWEBUI_RUNNING" = false ]; then
    log_warning "OpenWebUI not detected"
    echo ""
    echo "To install OpenWebUI with Docker:"
    echo "  docker run -d -p 3000:8080 --name open-webui \\"
    echo "    -v open-webui:/app/backend/data \\"
    echo "    ghcr.io/open-webui/open-webui:main"
    echo ""
    echo "Then update backend/.env:"
    echo "  OPENWEBUI_URL=http://localhost:3000"
    echo "  OPENWEBUI_PUBLIC_URL=https://org.halext.org/webui/"
    echo "  AI_PROVIDER=openwebui"
fi

# ============================================
# 5. NGINX CONFIGURATION CHECK
# ============================================
echo ""
log_info "Step 5: Checking Nginx Configuration..."
echo "----------------------------------------"

if command -v nginx &> /dev/null; then
    # Test nginx config
    if sudo nginx -t 2>&1 | grep -q "successful"; then
        log_success "Nginx configuration is valid"
    else
        log_error "Nginx configuration has errors"
        sudo nginx -t
    fi

    # Check for halext-org site config
    if [ -f "/etc/nginx/sites-enabled/halext-org" ]; then
        log_success "Nginx site config exists: /etc/nginx/sites-enabled/halext-org"

        # Check for common issues
        log_info "Checking for common nginx issues..."

        # Check root path
        NGINX_ROOT=$(grep -E "^\s*root\s+" /etc/nginx/sites-enabled/halext-org | head -1 | awk '{print $2}' | tr -d ';')
        if [ -n "$NGINX_ROOT" ]; then
            log_info "Nginx root: $NGINX_ROOT"
            if [ -d "$NGINX_ROOT" ]; then
                log_success "Root directory exists"
            else
                log_error "Root directory does not exist: $NGINX_ROOT"
            fi
        fi

        # Check proxy_pass
        if grep -q "proxy_pass.*localhost:8000" /etc/nginx/sites-enabled/halext-org; then
            log_success "API proxy configured"
        else
            log_warning "API proxy_pass not found or not pointing to localhost:8000"
        fi

    else
        log_warning "Nginx site config not found: /etc/nginx/sites-enabled/halext-org"
        echo ""
        echo "Create nginx config with:"
        echo "  sudo nano /etc/nginx/sites-available/halext-org"
        echo "  sudo ln -s /etc/nginx/sites-available/halext-org /etc/nginx/sites-enabled/"
    fi

    # Check nginx error logs
    if [ -f "/var/log/nginx/error.log" ]; then
        RECENT_ERRORS=$(sudo tail -20 /var/log/nginx/error.log | grep -i "error\|forbidden" | wc -l)
        if [ "$RECENT_ERRORS" -gt 0 ]; then
            log_warning "Found $RECENT_ERRORS recent errors in nginx log"
            echo "View with: sudo tail -50 /var/log/nginx/error.log"
        else
            log_success "No recent errors in nginx log"
        fi
    fi
fi

# ============================================
# 6. SERVICE STATUS
# ============================================
echo ""
log_info "Step 6: Checking Services..."
echo "----------------------------------------"

# Check if halext-api service exists
if systemctl list-unit-files | grep -q "halext-api.service"; then
    SERVICE_STATUS=$(systemctl is-active halext-api.service 2>/dev/null || echo "inactive")

    if [ "$SERVICE_STATUS" = "active" ]; then
        log_success "halext-api.service: Running"

        # Check if it's listening
        if ss -tlnp 2>/dev/null | grep -q ":8000"; then
            log_success "Backend listening on port 8000"
        else
            log_warning "Backend not listening on port 8000"
        fi
    else
        log_warning "halext-api.service: $SERVICE_STATUS"
        log_info "Start with: sudo systemctl start halext-api.service"
    fi

    # Show recent logs
    log_info "Recent service logs:"
    sudo journalctl -u halext-api.service -n 5 --no-pager

else
    log_warning "halext-api.service not found"
    echo ""
    echo "Create systemd service:"
    echo "  sudo nano /etc/systemd/system/halext-api.service"
    echo "  sudo systemctl daemon-reload"
    echo "  sudo systemctl enable halext-api.service"
    echo "  sudo systemctl start halext-api.service"
fi

# ============================================
# 7. CONNECTIVITY TESTS
# ============================================
echo ""
log_info "Step 7: Running Connectivity Tests..."
echo "----------------------------------------"

# Test backend locally
log_info "Testing backend on localhost:8000..."
BACKEND_LOCAL=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/api/integrations/openwebui 2>/dev/null || echo "000")

if [ "$BACKEND_LOCAL" = "200" ]; then
    log_success "Backend responding on localhost:8000"
elif [ "$BACKEND_LOCAL" = "000" ]; then
    log_error "Backend not accessible on localhost:8000"
    log_info "Check if service is running: systemctl status halext-api.service"
else
    log_warning "Backend returned HTTP $BACKEND_LOCAL"
fi

# Test nginx locally
if command -v nginx &> /dev/null && [ "$NGINX_RUNNING" = "active" ]; then
    log_info "Testing nginx on localhost:80..."
    NGINX_LOCAL=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/ 2>/dev/null || echo "000")

    if [ "$NGINX_LOCAL" = "200" ]; then
        log_success "Nginx responding on localhost:80"
    elif [ "$NGINX_LOCAL" = "403" ]; then
        log_error "Nginx returning 403 Forbidden"
        echo ""
        echo "Common causes of 403:"
        echo "  1. Incorrect root path in nginx config"
        echo "  2. File permissions on dist/ directory"
        echo "  3. Missing index.html"
        echo "  4. Nginx user cannot read files"
        echo ""
        echo "Check permissions:"
        echo "  ls -la $PROJECT_ROOT/frontend/dist/"
        echo "  sudo chown -R www-data:www-data $PROJECT_ROOT/frontend/dist/"
    else
        log_warning "Nginx returned HTTP $NGINX_LOCAL"
    fi
fi

# ============================================
# 8. FILE PERMISSIONS CHECK
# ============================================
echo ""
log_info "Step 8: Checking File Permissions..."
echo "----------------------------------------"

# Check frontend dist permissions
if [ -d "$PROJECT_ROOT/frontend/dist" ]; then
    DIST_PERMS=$(stat -c "%a" "$PROJECT_ROOT/frontend/dist" 2>/dev/null || stat -f "%p" "$PROJECT_ROOT/frontend/dist" 2>/dev/null | cut -c3-5)
    log_info "frontend/dist permissions: $DIST_PERMS"

    if [ -f "$PROJECT_ROOT/frontend/dist/index.html" ]; then
        INDEX_PERMS=$(stat -c "%a" "$PROJECT_ROOT/frontend/dist/index.html" 2>/dev/null || stat -f "%p" "$PROJECT_ROOT/frontend/dist/index.html" 2>/dev/null | cut -c3-5)
        log_info "frontend/dist/index.html permissions: $INDEX_PERMS"

        # Check if nginx user can read
        if sudo -u www-data test -r "$PROJECT_ROOT/frontend/dist/index.html" 2>/dev/null; then
            log_success "www-data can read index.html"
        else
            log_error "www-data cannot read index.html"
            echo "Fix with: sudo chmod -R 755 $PROJECT_ROOT/frontend/dist"
        fi
    fi
fi

# ============================================
# 9. SUMMARY
# ============================================
echo ""
echo "============================================"
echo "   Setup Summary"
echo "============================================"
echo ""

log_success "Backend setup complete"
log_success "Frontend built successfully"

if [ "$OPENWEBUI_RUNNING" = true ]; then
    log_success "OpenWebUI detected"
else
    log_warning "OpenWebUI not running (optional)"
fi

echo ""
echo "Next Steps:"
echo "----------"
echo "1. Review and edit backend/.env with your actual values"
echo "2. Run database migration:"
echo "   bash scripts/migrate-presets-schema.sh"
echo ""
echo "3. Start/restart services:"
echo "   sudo systemctl restart halext-api.service"
echo "   sudo systemctl restart nginx"
echo ""
echo "4. Check service status:"
echo "   sudo systemctl status halext-api.service"
echo "   sudo systemctl status nginx"
echo ""
echo "5. View logs if issues:"
echo "   sudo journalctl -u halext-api.service -f"
echo "   sudo tail -f /var/log/nginx/error.log"
echo ""
echo "6. Test endpoints:"
echo "   curl http://localhost:8000/api/integrations/openwebui"
echo "   curl http://localhost/"
echo ""

# Save diagnostic report
REPORT_FILE="/tmp/halext-diagnostic-$(date +%Y%m%d-%H%M%S).log"
{
    echo "Halext Org Diagnostic Report"
    echo "Generated: $(date)"
    echo ""
    echo "System:"
    uname -a
    echo ""
    echo "Python Version:"
    python3 --version
    echo ""
    echo "Node Version:"
    node --version
    echo ""
    echo "Services:"
    systemctl status halext-api.service --no-pager 2>&1 || echo "Service not found"
    echo ""
    echo "Ports:"
    ss -tlnp | grep -E ":80|:8000|:3000|:8080"
    echo ""
    echo "Recent Backend Logs:"
    sudo journalctl -u halext-api.service -n 30 --no-pager 2>&1 || echo "No logs"
    echo ""
    echo "Recent Nginx Errors:"
    sudo tail -20 /var/log/nginx/error.log 2>&1 || echo "No nginx logs"
} > "$REPORT_FILE"

log_success "Diagnostic report saved to: $REPORT_FILE"
echo ""
