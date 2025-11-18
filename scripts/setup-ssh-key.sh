#!/bin/bash

###############################################################################
# SSH Key Setup Helper Script
# This script helps you set up SSH key authentication for your Ubuntu server
###############################################################################

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

SERVER_USER="halext"
SERVER_HOST="144.202.52.126"

echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║           SSH KEY AUTHENTICATION SETUP                    ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}This script will help you set up passwordless SSH access to:${NC}"
echo -e "${CYAN}  ${SERVER_USER}@${SERVER_HOST}${NC}"
echo ""
echo -e "${YELLOW}You'll need to enter your server password ONE TIME.${NC}"
echo -e "${YELLOW}After that, all SSH connections will work automatically!${NC}"
echo ""

# Check if SSH key exists
if [ ! -f ~/.ssh/id_rsa.pub ]; then
    echo -e "${RED}❌ No SSH key found at ~/.ssh/id_rsa.pub${NC}"
    echo ""
    echo -e "${BLUE}Would you like to generate a new SSH key? (y/n)${NC}"
    read -r GENERATE_KEY

    if [[ "$GENERATE_KEY" =~ ^[Yy]$ ]]; then
        echo -e "${CYAN}Generating new SSH key...${NC}"
        ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
        echo -e "${GREEN}✅ SSH key generated!${NC}"
    else
        echo -e "${RED}Cannot continue without an SSH key. Exiting.${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✅ Found SSH key at ~/.ssh/id_rsa.pub${NC}"
echo ""

# Display the public key
echo -e "${BLUE}Your public key is:${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
cat ~/.ssh/id_rsa.pub
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo ""

# Method 1: Try ssh-copy-id with SSH_ASKPASS workaround
echo -e "${YELLOW}Attempting Method 1: Using ssh-copy-id...${NC}"
echo -e "${BLUE}Please enter your server password when prompted.${NC}"
echo ""

# Try with sshpass if available
if command -v sshpass &> /dev/null; then
    echo -e "${YELLOW}Using sshpass for authentication...${NC}"
    echo -e "${BLUE}Enter your server password:${NC}"
    read -s SERVER_PASSWORD

    sshpass -p "$SERVER_PASSWORD" ssh-copy-id -o StrictHostKeyChecking=no "${SERVER_USER}@${SERVER_HOST}"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ SSH key successfully copied!${NC}"
        echo ""
        echo -e "${YELLOW}Testing connection...${NC}"
        ssh -o ConnectTimeout=5 "${SERVER_USER}@${SERVER_HOST}" "echo 'Connection test successful!'"

        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ SSH key authentication is working!${NC}"
            echo ""
            echo -e "${CYAN}You can now run the deployment script:${NC}"
            echo -e "${BLUE}  ./scripts/deploy-to-ubuntu.sh${NC}"
            exit 0
        fi
    fi
else
    # Try standard ssh-copy-id
    ssh-copy-id "${SERVER_USER}@${SERVER_HOST}" 2>&1

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ SSH key successfully copied!${NC}"
        echo ""
        echo -e "${YELLOW}Testing connection...${NC}"
        ssh -o ConnectTimeout=5 "${SERVER_USER}@${SERVER_HOST}" "echo 'Connection test successful!'"

        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ SSH key authentication is working!${NC}"
            echo ""
            echo -e "${CYAN}You can now run the deployment script:${NC}"
            echo -e "${BLUE}  ./scripts/deploy-to-ubuntu.sh${NC}"
            exit 0
        fi
    fi
fi

# Method 2: Manual instructions
echo ""
echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Automated setup failed. Let's do it manually (it's easy!)${NC}"
echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${CYAN}STEP 1: Copy your SSH key to clipboard${NC}"
echo -e "${BLUE}Run this command:${NC}"
echo ""
echo -e "${GREEN}  cat ~/.ssh/id_rsa.pub | pbcopy${NC}"
echo ""
echo -e "${YELLOW}(The key is now in your clipboard)${NC}"
echo ""
echo -e "${CYAN}STEP 2: SSH to your server${NC}"
echo -e "${BLUE}Run this command:${NC}"
echo ""
echo -e "${GREEN}  ssh ${SERVER_USER}@${SERVER_HOST}${NC}"
echo ""
echo -e "${YELLOW}Enter your password when prompted.${NC}"
echo ""
echo -e "${CYAN}STEP 3: On the server, run these commands:${NC}"
echo ""
echo -e "${GREEN}  mkdir -p ~/.ssh${NC}"
echo -e "${GREEN}  chmod 700 ~/.ssh${NC}"
echo -e "${GREEN}  nano ~/.ssh/authorized_keys${NC}"
echo ""
echo -e "${YELLOW}In the nano editor:${NC}"
echo -e "  1. Paste your key (Cmd+V or right-click → paste)"
echo -e "  2. Press Ctrl+X to exit"
echo -e "  3. Press Y to save"
echo -e "  4. Press Enter to confirm"
echo ""
echo -e "${CYAN}STEP 4: Set correct permissions${NC}"
echo ""
echo -e "${GREEN}  chmod 600 ~/.ssh/authorized_keys${NC}"
echo -e "${GREEN}  exit${NC}"
echo ""
echo -e "${CYAN}STEP 5: Test it works${NC}"
echo ""
echo -e "${GREEN}  ssh ${SERVER_USER}@${SERVER_HOST} \"echo 'Success!'\"${NC}"
echo ""
echo -e "${YELLOW}If it says 'Success!' without asking for a password, you're done!${NC}"
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}Need help? Here's a quick reference card:${NC}"
echo ""
cat << 'EOF'
┌─────────────────────────────────────────────────────────┐
│  Quick Reference: SSH Key Setup                        │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Mac Terminal → Ubuntu Server                          │
│                                                         │
│  1. cat ~/.ssh/id_rsa.pub | pbcopy                     │
│     (copies key to clipboard)                          │
│                                                         │
│  2. ssh halext@144.202.52.126                          │
│     (login with password)                              │
│                                                         │
│  3. mkdir -p ~/.ssh && chmod 700 ~/.ssh                │
│     (create ssh directory)                             │
│                                                         │
│  4. nano ~/.ssh/authorized_keys                        │
│     (paste key, save with Ctrl+X, Y, Enter)            │
│                                                         │
│  5. chmod 600 ~/.ssh/authorized_keys                   │
│     (set permissions)                                  │
│                                                         │
│  6. exit                                               │
│     (logout)                                           │
│                                                         │
│  7. ssh halext@144.202.52.126 "echo 'Works!'"          │
│     (test - should not ask for password)               │
│                                                         │
└─────────────────────────────────────────────────────────┘
EOF
echo ""
echo -e "${YELLOW}After completing these steps, run:${NC}"
echo -e "${CYAN}  ./scripts/deploy-to-ubuntu.sh${NC}"
echo ""
