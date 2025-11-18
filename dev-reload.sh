#!/bin/bash

# Halext Org Development Environment Reload Script for macOS
# This script starts both frontend and backend development servers

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
FRONTEND_DIR="$SCRIPT_DIR/frontend"
BACKEND_DIR="$SCRIPT_DIR/backend"

# Process tracking
BACKEND_PID=""
FRONTEND_PID=""

# Cleanup function
cleanup() {
    echo -e "\n${YELLOW}Shutting down development servers...${NC}"

    if [ ! -z "$BACKEND_PID" ]; then
        echo -e "${BLUE}Stopping backend (PID: $BACKEND_PID)...${NC}"
        kill $BACKEND_PID 2>/dev/null || true
    fi

    if [ ! -z "$FRONTEND_PID" ]; then
        echo -e "${BLUE}Stopping frontend (PID: $FRONTEND_PID)...${NC}"
        kill $FRONTEND_PID 2>/dev/null || true
    fi

    # Kill any remaining processes on our ports
    lsof -ti:8000 | xargs kill -9 2>/dev/null || true
    lsof -ti:5173 | xargs kill -9 2>/dev/null || true

    echo -e "${GREEN}Cleanup complete!${NC}"
    exit 0
}

# Set up trap to cleanup on script exit
trap cleanup EXIT INT TERM

# Print banner
echo -e "${PURPLE}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║              Halext Org Development Reload                ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check if directories exist
if [ ! -d "$FRONTEND_DIR" ]; then
    echo -e "${RED}Error: Frontend directory not found at $FRONTEND_DIR${NC}"
    exit 1
fi

if [ ! -d "$BACKEND_DIR" ]; then
    echo -e "${RED}Error: Backend directory not found at $BACKEND_DIR${NC}"
    exit 1
fi

# Kill any existing processes on ports 8000 and 5173
echo -e "${YELLOW}Checking for existing services...${NC}"
if lsof -ti:8000 >/dev/null 2>&1; then
    echo -e "${BLUE}Stopping existing backend on port 8000...${NC}"
    lsof -ti:8000 | xargs kill -9 2>/dev/null || true
    sleep 1
fi

if lsof -ti:5173 >/dev/null 2>&1; then
    echo -e "${BLUE}Stopping existing frontend on port 5173...${NC}"
    lsof -ti:5173 | xargs kill -9 2>/dev/null || true
    sleep 1
fi

# Check if backend virtual environment exists
if [ ! -d "$BACKEND_DIR/env" ]; then
    echo -e "${RED}Error: Virtual environment not found at $BACKEND_DIR/env${NC}"
    echo -e "${YELLOW}Creating virtual environment...${NC}"
    cd "$BACKEND_DIR"
    python3 -m venv env
    env/bin/pip install --upgrade pip
    env/bin/pip install -r requirements.txt
    cd "$SCRIPT_DIR"
fi

# Check if frontend node_modules exists
if [ ! -d "$FRONTEND_DIR/node_modules" ]; then
    echo -e "${RED}Error: node_modules not found at $FRONTEND_DIR/node_modules${NC}"
    echo -e "${YELLOW}Installing frontend dependencies...${NC}"
    cd "$FRONTEND_DIR"
    npm install
    cd "$SCRIPT_DIR"
fi

# Start backend server
echo -e "\n${GREEN}Starting backend server...${NC}"
cd "$BACKEND_DIR"
env/bin/uvicorn main:app --host 127.0.0.1 --port 8000 --reload > "$SCRIPT_DIR/backend-dev.log" 2>&1 &
BACKEND_PID=$!
cd "$SCRIPT_DIR"

# Wait for backend to start
echo -e "${BLUE}Waiting for backend to initialize...${NC}"
sleep 3

# Check if backend started successfully
if ! ps -p $BACKEND_PID > /dev/null 2>&1; then
    echo -e "${RED}Failed to start backend server!${NC}"
    echo -e "${YELLOW}Check backend-dev.log for details${NC}"
    cat "$SCRIPT_DIR/backend-dev.log"
    exit 1
fi

# Verify backend is responding
if curl -s http://127.0.0.1:8000/docs > /dev/null; then
    echo -e "${GREEN}✓ Backend server is running${NC}"
else
    echo -e "${YELLOW}⚠ Backend started but not responding yet...${NC}"
fi

# Start frontend server
echo -e "\n${GREEN}Starting frontend server...${NC}"
cd "$FRONTEND_DIR"
npm run dev > "$SCRIPT_DIR/frontend-dev.log" 2>&1 &
FRONTEND_PID=$!
cd "$SCRIPT_DIR"

# Wait for frontend to start
echo -e "${BLUE}Waiting for frontend to initialize...${NC}"
sleep 3

# Check if frontend started successfully
if ! ps -p $FRONTEND_PID > /dev/null 2>&1; then
    echo -e "${RED}Failed to start frontend server!${NC}"
    echo -e "${YELLOW}Check frontend-dev.log for details${NC}"
    cat "$SCRIPT_DIR/frontend-dev.log"
    exit 1
fi

echo -e "${GREEN}✓ Frontend server is running${NC}"

# Display service information
echo -e "\n${PURPLE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║                   Services Running                        ║${NC}"
echo -e "${PURPLE}╠═══════════════════════════════════════════════════════════╣${NC}"
echo -e "${PURPLE}║${NC}                                                           ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC}  ${GREEN}Frontend:${NC}     ${BLUE}http://localhost:5173${NC}                    ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC}  ${GREEN}Backend API:${NC}  ${BLUE}http://127.0.0.1:8000${NC}                    ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC}  ${GREEN}API Docs:${NC}     ${BLUE}http://127.0.0.1:8000/docs${NC}               ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC}                                                           ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC}  ${YELLOW}Frontend PID:${NC} $FRONTEND_PID                                ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC}  ${YELLOW}Backend PID:${NC}  $BACKEND_PID                                ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC}                                                           ${PURPLE}║${NC}"
echo -e "${PURPLE}╠═══════════════════════════════════════════════════════════╣${NC}"
echo -e "${PURPLE}║${NC}  Logs:                                                    ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC}    Frontend: ${BLUE}tail -f $SCRIPT_DIR/frontend-dev.log${NC}${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC}    Backend:  ${BLUE}tail -f $SCRIPT_DIR/backend-dev.log${NC} ${PURPLE}║${NC}"
echo -e "${PURPLE}╚═══════════════════════════════════════════════════════════╝${NC}"

echo -e "\n${GREEN}Press Ctrl+C to stop all servers${NC}\n"

# Wait for both processes
wait $BACKEND_PID $FRONTEND_PID
