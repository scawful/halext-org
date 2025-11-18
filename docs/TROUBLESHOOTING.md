# Halext Org Troubleshooting Guide

## Common Issues and Solutions

### 403 Forbidden Error

**Symptoms:** Browser shows "403 Forbidden" when accessing the site

**Possible Causes:**

#### 1. Nginx Configuration Issues

Check nginx config:
```bash
sudo nginx -t
cat /etc/nginx/sites-enabled/halext-org
```

Ensure the `root` directive points to the correct path:
```nginx
root /srv/halext.org/halext-org/frontend/dist;
```

#### 2. File Permissions

The nginx user (usually `www-data`) needs read access to files:

```bash
# Check current permissions
ls -la /srv/halext.org/halext-org/frontend/dist/

# Fix permissions
sudo chown -R www-data:www-data /srv/halext.org/halext-org/frontend/dist/
sudo chmod -R 755 /srv/halext.org/halext-org/frontend/dist/

# Or allow your user and www-data
sudo chown -R $USER:www-data /srv/halext.org/halext-org/frontend/dist/
sudo chmod -R 755 /srv/halext.org/halext-org/frontend/dist/
```

#### 3. Missing Frontend Build

```bash
# Check if dist exists
ls /srv/halext.org/halext-org/frontend/dist/index.html

# Rebuild frontend
cd /srv/halext.org/halext-org/frontend
npm install
npm run build
```

#### 4. Cloudflare Firewall Rules

If using Cloudflare:
- Check Cloudflare dashboard → Security → WAF
- Look for blocked requests
- Temporarily set security level to "Essentially Off" to test

#### 5. SELinux (if enabled)

```bash
# Check SELinux status
getenforce

# If enforcing, check for denials
sudo ausearch -m avc -ts recent

# Temporarily disable to test
sudo setenforce 0

# Re-enable after testing
sudo setenforce 1
```

### Backend Not Starting

**Check service status:**
```bash
sudo systemctl status halext-api.service
sudo journalctl -u halext-api.service -n 50 --no-pager
```

**Common errors:**

#### Database Connection Failed

```bash
# Check DATABASE_URL in .env
cat /srv/halext.org/halext-org/backend/.env | grep DATABASE_URL

# Test database connection
sudo -u postgres psql -d halext_org -c "SELECT 1;"

# Reset password if needed
sudo -u postgres psql
ALTER USER halext_user WITH PASSWORD 'new_password';
\q

# Update .env with new password
nano /srv/halext.org/halext-org/backend/.env
```

#### Python Import Errors

```bash
# Reinstall dependencies
cd /srv/halext.org/halext-org/backend
source env/bin/activate
pip install -r requirements.txt --force-reinstall
```

#### Port Already in Use

```bash
# Check what's using port 8000
sudo lsof -i :8000
sudo ss -tlnp | grep :8000

# Kill the process if needed
sudo kill <PID>
```

### Frontend Build Fails

```bash
# Clear cache and rebuild
cd /srv/halext.org/halext-org/frontend
rm -rf node_modules dist
npm install
npm run build

# Check for errors
npm run build 2>&1 | tee build.log
```

### OpenWebUI Not Working

```bash
# Check if container is running
docker ps | grep openwebui

# View logs
docker logs open-webui

# Restart container
docker restart open-webui

# Start if not running
docker run -d -p 3000:8080 --name open-webui \
  -v open-webui:/app/backend/data \
  ghcr.io/open-webui/open-webui:main

# Update backend/.env
echo "OPENWEBUI_URL=http://localhost:3000" >> backend/.env
echo "AI_PROVIDER=openwebui" >> backend/.env
```

### Nginx Not Serving API

**Check proxy configuration:**

```nginx
# Should have this in your nginx config
location /api/ {
    proxy_pass http://localhost:8000/api/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host $host;
    proxy_cache_bypass $http_upgrade;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

**Test API directly:**
```bash
# Bypass nginx
curl http://localhost:8000/api/integrations/openwebui

# Through nginx
curl http://localhost/api/integrations/openwebui
```

## Diagnostic Commands

### Full System Check

```bash
# Run the setup script to see all diagnostics
bash scripts/setup-ubuntu.sh

# Or manually:
sudo systemctl status halext-api.service
sudo systemctl status nginx
sudo journalctl -u halext-api.service -n 50
sudo tail -50 /var/log/nginx/error.log
sudo tail -50 /var/log/nginx/access.log
```

### Check All Ports

```bash
sudo ss -tlnp | grep -E ":80|:443|:8000|:3000|:8080|:5432"
```

### Test from Different Locations

```bash
# Local backend
curl http://localhost:8000/api/integrations/openwebui

# Local nginx
curl http://localhost/api/integrations/openwebui

# Public domain (if configured)
curl https://org.halext.org/api/integrations/openwebui

# Check DNS
dig org.halext.org
nslookup org.halext.org
```

### View Real-time Logs

```bash
# Backend logs
sudo journalctl -u halext-api.service -f

# Nginx access log
sudo tail -f /var/log/nginx/access.log

# Nginx error log
sudo tail -f /var/log/nginx/error.log

# All together
sudo tail -f /var/log/nginx/*.log &
sudo journalctl -u halext-api.service -f
```

## Quick Fixes

### Complete Service Restart

```bash
sudo systemctl restart halext-api.service
sudo systemctl restart nginx
sudo systemctl status halext-api.service
sudo systemctl status nginx
```

### Clear and Rebuild Everything

```bash
cd /srv/halext.org/halext-org

# Backend
cd backend
source env/bin/activate
pip install -r requirements.txt --force-reinstall
deactivate

# Frontend
cd ../frontend
rm -rf node_modules dist
npm install
npm run build

# Restart services
sudo systemctl restart halext-api.service
sudo systemctl restart nginx
```

### Reset Database (WARNING: Deletes all data)

```bash
sudo -u postgres psql << 'EOF'
DROP DATABASE IF EXISTS halext_org;
CREATE DATABASE halext_org OWNER halext_user;
\q
EOF

# Tables will be recreated on next backend start
sudo systemctl restart halext-api.service
```

## Getting Help

If you're still stuck:

1. **Run full diagnostics:**
   ```bash
   bash scripts/setup-ubuntu.sh | tee setup-output.log
   ```

2. **Collect logs:**
   ```bash
   sudo journalctl -u halext-api.service -n 100 > backend.log
   sudo tail -100 /var/log/nginx/error.log > nginx-error.log
   sudo tail -100 /var/log/nginx/access.log > nginx-access.log
   ```

3. **Check configuration:**
   ```bash
   cat /etc/nginx/sites-enabled/halext-org > nginx-config.txt
   cat backend/.env | sed 's/password=.*/password=***/' > env-config.txt
   ```

4. Share the output files for debugging
