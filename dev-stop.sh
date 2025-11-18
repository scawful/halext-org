#!/bin/bash

# Halext Org Development Environment Stop Script for macOS
# This script stops all running development servers

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Stopping Halext Org development servers...${NC}\n"

# Stop processes on port 8000 (backend)
if lsof -ti:8000 >/dev/null 2>&1; then
    echo -e "${BLUE}Stopping backend on port 8000...${NC}"
    lsof -ti:8000 | xargs kill -9 2>/dev/null
    echo -e "${GREEN}✓ Backend stopped${NC}"
else
    echo -e "${YELLOW}No backend process found on port 8000${NC}"
fi

# Stop processes on port 5173 (frontend)
if lsof -ti:5173 >/dev/null 2>&1; then
    echo -e "${BLUE}Stopping frontend on port 5173...${NC}"
    lsof -ti:5173 | xargs kill -9 2>/dev/null
    echo -e "${GREEN}✓ Frontend stopped${NC}"
else
    echo -e "${YELLOW}No frontend process found on port 5173${NC}"
fi

# Kill any remaining uvicorn processes
if pgrep -f "uvicorn main:app" >/dev/null 2>&1; then
    echo -e "${BLUE}Stopping remaining uvicorn processes...${NC}"
    pkill -f "uvicorn main:app"
    echo -e "${GREEN}✓ Uvicorn stopped${NC}"
fi

# Kill any remaining vite processes
if pgrep -f "vite" >/dev/null 2>&1; then
    echo -e "${BLUE}Stopping remaining vite processes...${NC}"
    pkill -f "vite"
    echo -e "${GREEN}✓ Vite stopped${NC}"
fi

echo -e "\n${GREEN}All development servers stopped!${NC}"
