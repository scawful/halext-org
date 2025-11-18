#!/bin/bash
#
# OpenWebUI Deployment Script for org.halext.org
#
# This script sets up OpenWebUI with Ollama on an Ubuntu server
# and configures Nginx reverse proxy for /webui/ path
#
# Usage:
#   sudo ./setup-openwebui.sh
#

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOMAIN="${DOMAIN:-org.halext.org}"
OPENWEBUI_PORT=3000
OLLAMA_PORT=11434
INSTALL_DIR="/opt/openwebui"
DATA_DIR="/var/lib/openwebui"

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║              OpenWebUI Setup for Halext Org              ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Error: This script must be run as root${NC}"
  echo "Please run: sudo $0"
  exit 1
fi

echo -e "${YELLOW}Step 1: Installing Docker...${NC}"
if ! command -v docker &> /dev/null; then
    # Install Docker
    apt-get update
    apt-get install -y ca-certificates curl gnupg lsb-release
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    echo -e "${GREEN}✓ Docker installed${NC}"
else
    echo -e "${GREEN}✓ Docker already installed${NC}"
fi

echo -e "${YELLOW}Step 2: Installing Ollama...${NC}"
if ! command -v ollama &> /dev/null; then
    curl -fsSL https://ollama.com/install.sh | sh
    echo -e "${GREEN}✓ Ollama installed${NC}"
else
    echo -e "${GREEN}✓ Ollama already installed${NC}"
fi

# Start Ollama service
systemctl enable ollama
systemctl start ollama
echo -e "${GREEN}✓ Ollama service started${NC}"

echo -e "${YELLOW}Step 3: Pulling default AI models...${NC}"
echo "Pulling llama3.1 (this may take a while)..."
ollama pull llama3.1
echo -e "${GREEN}✓ llama3.1 model downloaded${NC}"

echo "Pulling mistral..."
ollama pull mistral
echo -e "${GREEN}✓ mistral model downloaded${NC}"

echo -e "${YELLOW}Step 4: Setting up OpenWebUI...${NC}"

# Create directories
mkdir -p "$DATA_DIR"
mkdir -p "$INSTALL_DIR"

# Create Docker Compose file
cat > "$INSTALL_DIR/docker-compose.yml" <<EOF
version: '3.8'

services:
  openwebui:
    image: ghcr.io/open-webui/open-webui:main
    container_name: openwebui
    restart: unless-stopped
    ports:
      - "127.0.0.1:${OPENWEBUI_PORT}:8080"
    environment:
      - OLLAMA_BASE_URL=http://host.docker.internal:${OLLAMA_PORT}
      - WEBUI_AUTH=true
      - WEBUI_NAME=Halext Org AI
      - ENABLE_SIGNUP=false
      - DEFAULT_MODELS=llama3.1,mistral
    volumes:
      - ${DATA_DIR}:/app/backend/data
    extra_hosts:
      - "host.docker.internal:host-gateway"
    networks:
      - openwebui

networks:
  openwebui:
    driver: bridge
EOF

# Start OpenWebUI
cd "$INSTALL_DIR"
docker compose up -d
echo -e "${GREEN}✓ OpenWebUI container started${NC}"

# Wait for OpenWebUI to be ready
echo "Waiting for OpenWebUI to start..."
sleep 10
for i in {1..30}; do
    if curl -s http://localhost:${OPENWEBUI_PORT} > /dev/null; then
        echo -e "${GREEN}✓ OpenWebUI is running${NC}"
        break
    fi
    echo -n "."
    sleep 2
done

echo -e "${YELLOW}Step 5: Configuring Nginx reverse proxy...${NC}"

# Install Nginx if not present
if ! command -v nginx &> /dev/null; then
    apt-get install -y nginx
    echo -e "${GREEN}✓ Nginx installed${NC}"
else
    echo -e "${GREEN}✓ Nginx already installed${NC}"
fi

# Create Nginx configuration for OpenWebUI
cat > /etc/nginx/sites-available/openwebui.conf <<EOF
# OpenWebUI reverse proxy configuration
location /webui/ {
    proxy_pass http://127.0.0.1:${OPENWEBUI_PORT}/;
    proxy_http_version 1.1;

    # WebSocket support
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "upgrade";

    # Proxy headers
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Forwarded-Host \$host;
    proxy_set_header X-Forwarded-Port \$server_port;

    # Increase timeouts for AI operations
    proxy_connect_timeout 600s;
    proxy_send_timeout 600s;
    proxy_read_timeout 600s;
    send_timeout 600s;

    # Buffer settings
    proxy_buffering off;
    proxy_request_buffering off;
}

# Static assets referenced with absolute paths
location ~ ^/(?:_app|static)/ {
    proxy_pass http://127.0.0.1:${OPENWEBUI_PORT}\$request_uri;
    proxy_http_version 1.1;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Forwarded-Host \$host;
    proxy_set_header X-Forwarded-Port \$server_port;
    proxy_buffering off;
}

location = /manifest.json {
    proxy_pass http://127.0.0.1:${OPENWEBUI_PORT}/manifest.json;
    proxy_http_version 1.1;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
}

# Ollama API proxy (optional, for direct access)
location /ollama/ {
    proxy_pass http://127.0.0.1:${OLLAMA_PORT}/;
    proxy_http_version 1.1;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;

    # Increase timeouts for model operations
    proxy_connect_timeout 600s;
    proxy_send_timeout 600s;
    proxy_read_timeout 600s;
}
EOF

echo -e "${GREEN}✓ Nginx configuration created${NC}"
echo -e "${YELLOW}Note: Please include this configuration in your main Nginx server block for ${DOMAIN}${NC}"
echo ""
echo "Add this line to your server block in /etc/nginx/sites-available/${DOMAIN}:"
echo -e "${BLUE}    include /etc/nginx/sites-available/openwebui.conf;${NC}"
echo ""

# Test Nginx configuration
nginx -t
echo -e "${GREEN}✓ Nginx configuration is valid${NC}"

echo -e "${YELLOW}Step 6: Setting up systemd service for OpenWebUI...${NC}"

# Create systemd service
cat > /etc/systemd/system/openwebui.service <<EOF
[Unit]
Description=OpenWebUI Container
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=${INSTALL_DIR}
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable openwebui
echo -e "${GREEN}✓ Systemd service created${NC}"

echo -e "${YELLOW}Step 7: Setting up firewall rules...${NC}"
if command -v ufw &> /dev/null; then
    ufw allow ${OLLAMA_PORT}/tcp comment "Ollama"
    echo -e "${GREEN}✓ Firewall rules updated${NC}"
else
    echo -e "${YELLOW}⚠ UFW not found, skipping firewall configuration${NC}"
fi

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                   Setup Complete!                         ║${NC}"
echo -e "${GREEN}╠═══════════════════════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║${NC}                                                           ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}  ${BLUE}OpenWebUI:${NC}     ${YELLOW}http://localhost:${OPENWEBUI_PORT}${NC}              ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}  ${BLUE}Public URL:${NC}    ${YELLOW}https://${DOMAIN}/webui/${NC}         ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}  ${BLUE}Ollama:${NC}        ${YELLOW}http://localhost:${OLLAMA_PORT}${NC}                ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}                                                           ${GREEN}║${NC}"
echo -e "${GREEN}╠═══════════════════════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║${NC}  Next Steps:                                             ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}                                                           ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}  1. Include OpenWebUI config in your main Nginx server   ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}     block for ${DOMAIN}:                                  ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}                                                           ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}     ${BLUE}sudo nano /etc/nginx/sites-available/${DOMAIN}${NC}    ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}                                                           ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}     Add inside the server { } block:                     ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}     ${YELLOW}include /etc/nginx/sites-available/openwebui.conf;${NC}${GREEN}║${NC}"
echo -e "${GREEN}║${NC}                                                           ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}  2. Reload Nginx:                                        ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}     ${BLUE}sudo systemctl reload nginx${NC}                       ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}                                                           ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}  3. Update backend .env with:                            ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}     ${YELLOW}AI_PROVIDER=openwebui${NC}                            ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}     ${YELLOW}OPENWEBUI_URL=http://localhost:${OPENWEBUI_PORT}${NC}        ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}                                                           ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}  4. Access OpenWebUI at:                                 ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}     ${BLUE}https://${DOMAIN}/webui/${NC}                        ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}                                                           ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}  5. Create admin account on first visit                  ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}                                                           ${GREEN}║${NC}"
echo -e "${GREEN}╠═══════════════════════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║${NC}  Installed Models:                                       ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}    • llama3.1                                            ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}    • mistral                                             ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}                                                           ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}  To add more models:                                     ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}    ${BLUE}ollama pull <model-name>${NC}                           ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}                                                           ${GREEN}║${NC}"
echo -e "${GREEN}╠═══════════════════════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║${NC}  Management Commands:                                    ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}                                                           ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}  Start:    ${BLUE}systemctl start openwebui${NC}                   ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}  Stop:     ${BLUE}systemctl stop openwebui${NC}                    ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}  Restart:  ${BLUE}systemctl restart openwebui${NC}                 ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}  Status:   ${BLUE}systemctl status openwebui${NC}                  ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}  Logs:     ${BLUE}docker logs -f openwebui${NC}                    ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}                                                           ${GREEN}║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
