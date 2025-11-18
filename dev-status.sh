#!/bin/bash

# Halext Org Development Environment Status Script for macOS
# This script checks the status of development servers

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${PURPLE}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║           Halext Org Development Status                  ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}\n"

# Check backend (port 8000)
echo -e "${BLUE}Backend Server (Port 8000):${NC}"
if lsof -ti:8000 >/dev/null 2>&1; then
    PID=$(lsof -ti:8000)
    echo -e "  Status: ${GREEN}RUNNING${NC}"
    echo -e "  PID: ${YELLOW}$PID${NC}"

    # Try to check API health
    if curl -s http://127.0.0.1:8000/docs > /dev/null 2>&1; then
        echo -e "  Health: ${GREEN}OK${NC}"
        echo -e "  API Docs: ${BLUE}http://127.0.0.1:8000/docs${NC}"
    else
        echo -e "  Health: ${YELLOW}NOT RESPONDING${NC}"
    fi
else
    echo -e "  Status: ${RED}NOT RUNNING${NC}"
fi

echo ""

# Check frontend (port 5173)
echo -e "${BLUE}Frontend Server (Port 5173):${NC}"
if lsof -ti:5173 >/dev/null 2>&1; then
    PID=$(lsof -ti:5173)
    echo -e "  Status: ${GREEN}RUNNING${NC}"
    echo -e "  PID: ${YELLOW}$PID${NC}"

    # Try to check frontend health
    if curl -s http://localhost:5173 > /dev/null 2>&1; then
        echo -e "  Health: ${GREEN}OK${NC}"
        echo -e "  URL: ${BLUE}http://localhost:5173${NC}"
    else
        echo -e "  Health: ${YELLOW}NOT RESPONDING${NC}"
    fi
else
    echo -e "  Status: ${RED}NOT RUNNING${NC}"
fi

echo ""

# Check for log files
echo -e "${BLUE}Log Files:${NC}"
if [ -f "backend-dev.log" ]; then
    BACKEND_SIZE=$(du -h backend-dev.log | cut -f1)
    echo -e "  Backend: ${GREEN}backend-dev.log${NC} (${YELLOW}$BACKEND_SIZE${NC})"
else
    echo -e "  Backend: ${RED}No log file${NC}"
fi

if [ -f "frontend-dev.log" ]; then
    FRONTEND_SIZE=$(du -h frontend-dev.log | cut -f1)
    echo -e "  Frontend: ${GREEN}frontend-dev.log${NC} (${YELLOW}$FRONTEND_SIZE${NC})"
else
    echo -e "  Frontend: ${RED}No log file${NC}"
fi

echo ""

# Check database
echo -e "${BLUE}Database:${NC}"
if [ -f "backend/halext_dev.db" ]; then
    DB_SIZE=$(du -h backend/halext_dev.db | cut -f1)
    echo -e "  SQLite: ${GREEN}backend/halext_dev.db${NC} (${YELLOW}$DB_SIZE${NC})"
else
    echo -e "  SQLite: ${RED}Not found${NC}"
fi

echo ""

# Check virtual environment
echo -e "${BLUE}Virtual Environment:${NC}"
if [ -d "backend/env" ]; then
    PYTHON_VERSION=$(backend/env/bin/python --version 2>&1)
    echo -e "  Status: ${GREEN}EXISTS${NC}"
    echo -e "  Python: ${YELLOW}$PYTHON_VERSION${NC}"
else
    echo -e "  Status: ${RED}NOT FOUND${NC}"
fi

echo ""

# Check node_modules
echo -e "${BLUE}Frontend Dependencies:${NC}"
if [ -d "frontend/node_modules" ]; then
    MODULE_COUNT=$(find frontend/node_modules -maxdepth 1 -type d | wc -l)
    echo -e "  Status: ${GREEN}INSTALLED${NC}"
    echo -e "  Packages: ${YELLOW}$MODULE_COUNT${NC}"
else
    echo -e "  Status: ${RED}NOT INSTALLED${NC}"
fi

echo ""
echo -e "${PURPLE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║  Commands:                                                ║${NC}"
echo -e "${PURPLE}║    ${GREEN}./dev-reload.sh${NC}  - Start both servers                  ${PURPLE}║${NC}"
echo -e "${PURPLE}║    ${YELLOW}./dev-stop.sh${NC}    - Stop all servers                    ${PURPLE}║${NC}"
echo -e "${PURPLE}║    ${BLUE}./dev-status.sh${NC}  - Check server status                 ${PURPLE}║${NC}"
echo -e "${PURPLE}╚═══════════════════════════════════════════════════════════╝${NC}"
