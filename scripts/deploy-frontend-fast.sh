#!/bin/bash

# Fast Frontend Deployment Script
# Builds frontend locally on Mac and deploys to Ubuntu server
# This is MUCH faster than building on the 2GB server

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SERVER_USER="halext"
SERVER_HOST="144.202.52.126"
SERVER_PATH="/var/www/halext"
LOCAL_PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCAL_FRONTEND_DIR="$LOCAL_PROJECT_ROOT/frontend"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Fast Frontend Deployment${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Step 1: Build locally
echo -e "${YELLOW}Step 1: Building frontend locally...${NC}"
cd "$LOCAL_FRONTEND_DIR"

if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}Installing dependencies first...${NC}"
    npm install
fi

echo -e "${YELLOW}Running build (should take 10-30 seconds)...${NC}"
time npm run build

if [ ! -d "dist" ]; then
    echo -e "${RED}❌ Build failed - dist directory not created${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Build completed successfully${NC}"
echo ""

# Step 2: Deploy to server
echo -e "${YELLOW}Step 2: Deploying to Ubuntu server...${NC}"

# Show what will be synced
echo -e "${BLUE}Will sync:${NC}"
echo "  From: $LOCAL_FRONTEND_DIR/dist/"
echo "  To:   $SERVER_USER@$SERVER_HOST:$SERVER_PATH"
echo ""

# Rsync with progress
# Note: --no-perms --no-owner --no-group to avoid permission errors
echo -e "${YELLOW}Syncing files...${NC}"
rsync -avz --delete --progress --no-perms --no-owner --no-group \
    "$LOCAL_FRONTEND_DIR/dist/" \
    "$SERVER_USER@$SERVER_HOST:$SERVER_PATH/"

# Exit code 23 means "partial transfer due to vanished source files or permission errors"
# but files were transferred successfully
if [ $? -eq 0 ] || [ $? -eq 23 ]; then
    echo ""
    echo -e "${GREEN}✅ Deployment completed successfully!${NC}"
    echo ""
    echo -e "${BLUE}Verifying deployment...${NC}"

    # Check if index.html exists on server
    ssh "$SERVER_USER@$SERVER_HOST" "ls -lh $SERVER_PATH/index.html"

    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}🎉 Frontend successfully deployed!${NC}"
        echo ""
        echo -e "${BLUE}Next steps:${NC}"
        echo "  1. Visit https://org.halext.org to verify"
        echo "  2. Clear browser cache if you see old version (Cmd+Shift+R)"
        echo "  3. Check browser console for any errors"
    else
        echo -e "${RED}❌ Verification failed - index.html not found${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ Deployment failed${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
