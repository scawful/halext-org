#!/bin/bash
# Ubuntu Server Performance Diagnostic Script
# Checks system load, Docker, Ollama, OpenWebUI, and backend services

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}   Halext Org - Ubuntu Server Performance Diagnostic${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Timestamp: $(date)"
echo ""

# ============================================================================
# System Information
# ============================================================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}1. System Information${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo "Hostname: $(hostname)"
echo "Kernel: $(uname -r)"
echo "Uptime: $(uptime -p)"
echo ""

# ============================================================================
# CPU Information
# ============================================================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}2. CPU Information & Load${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

CPUS=$(nproc)
echo "CPU Cores: $CPUS"
echo ""

echo "Load Average:"
uptime | awk -F'load average:' '{print $2}'
echo ""

LOAD_1MIN=$(uptime | awk -F'load average:' '{print $2}' | awk -F, '{print $1}' | tr -d ' ')
LOAD_THRESHOLD=$(echo "$CPUS * 0.7" | bc)

if (( $(echo "$LOAD_1MIN > $LOAD_THRESHOLD" | bc -l) )); then
    echo -e "${RED}⚠️  High load detected! ($LOAD_1MIN on $CPUS cores)${NC}"
else
    echo -e "${GREEN}✅ Load is normal ($LOAD_1MIN on $CPUS cores)${NC}"
fi
echo ""

echo "CPU Usage (top 5 processes):"
ps aux --sort=-%cpu | head -6
echo ""

# ============================================================================
# Memory Information
# ============================================================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}3. Memory Usage${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

free -h
echo ""

MEMORY_PERCENT=$(free | grep Mem | awk '{print ($3/$2) * 100.0}')
if (( $(echo "$MEMORY_PERCENT > 80" | bc -l) )); then
    echo -e "${RED}⚠️  High memory usage: ${MEMORY_PERCENT}%${NC}"
elif (( $(echo "$MEMORY_PERCENT > 60" | bc -l) )); then
    echo -e "${YELLOW}⚠️  Moderate memory usage: ${MEMORY_PERCENT}%${NC}"
else
    echo -e "${GREEN}✅ Memory usage OK: ${MEMORY_PERCENT}%${NC}"
fi
echo ""

echo "Memory Usage (top 5 processes):"
ps aux --sort=-%mem | head -6
echo ""

# ============================================================================
# Disk Usage & I/O
# ============================================================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}4. Disk Usage & I/O${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

df -h / /var/lib/docker 2>/dev/null || df -h /
echo ""

DISK_PERCENT=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$DISK_PERCENT" -gt 80 ]; then
    echo -e "${RED}⚠️  Disk usage critical: ${DISK_PERCENT}%${NC}"
elif [ "$DISK_PERCENT" -gt 60 ]; then
    echo -e "${YELLOW}⚠️  Disk usage high: ${DISK_PERCENT}%${NC}"
else
    echo -e "${GREEN}✅ Disk usage OK: ${DISK_PERCENT}%${NC}"
fi
echo ""

if command -v iostat &> /dev/null; then
    echo "Disk I/O Stats:"
    iostat -x 1 2 | tail -n +4
    echo ""
fi

# ============================================================================
# Docker Status
# ============================================================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}5. Docker Status${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if command -v docker &> /dev/null; then
    echo "Docker Version:"
    docker --version
    echo ""

    echo "Running Containers:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "No containers running"
    echo ""

    echo "Container Resource Usage:"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}" 2>/dev/null || echo "Could not get container stats"
    echo ""

    # Check specific containers
    if docker ps | grep -q openwebui; then
        echo -e "${GREEN}✅ OpenWebUI container is running${NC}"
        echo "OpenWebUI logs (last 10 lines):"
        docker logs openwebui --tail 10 2>&1 | grep -i "error\|warning\|critical" || echo "  No recent errors"
    else
        echo -e "${YELLOW}⚠️  OpenWebUI container not running${NC}"
    fi
    echo ""
else
    echo -e "${YELLOW}⚠️  Docker not installed or not accessible${NC}"
    echo ""
fi

# ============================================================================
# Ollama Status
# ============================================================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}6. Ollama Status${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if command -v ollama &> /dev/null; then
    echo "Ollama Version:"
    ollama --version 2>/dev/null || echo "Could not get version"
    echo ""

    # Check if Ollama is running
    if pgrep -f "ollama serve" > /dev/null; then
        echo -e "${GREEN}✅ Ollama service is running${NC}"

        # Check which models are loaded
        echo ""
        echo "Loaded Models:"
        ollama list 2>/dev/null || echo "Could not list models"
        echo ""

        # Test API
        if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Ollama API responding${NC}"
        else
            echo -e "${RED}❌ Ollama API not responding${NC}"
        fi
        echo ""

        # Ollama process info
        echo "Ollama Process Info:"
        ps aux | grep "ollama serve" | grep -v grep
        echo ""

        # Check Ollama memory usage
        OLLAMA_MEM=$(ps aux | grep "ollama serve" | grep -v grep | awk '{sum+=$6} END {print sum/1024}')
        if [ ! -z "$OLLAMA_MEM" ]; then
            echo "Ollama Memory Usage: ${OLLAMA_MEM} MB"
            if (( $(echo "$OLLAMA_MEM > 1024" | bc -l) )); then
                echo -e "${YELLOW}⚠️  Ollama using significant memory${NC}"
            fi
        fi
        echo ""
    else
        echo -e "${RED}❌ Ollama service not running${NC}"
        echo ""

        # Check systemd service
        if systemctl is-active --quiet ollama 2>/dev/null; then
            echo "Ollama systemd service status:"
            systemctl status ollama --no-pager -l | head -20
        fi
        echo ""
    fi
else
    echo -e "${YELLOW}⚠️  Ollama not installed${NC}"
    echo ""
fi

# ============================================================================
# Halext Backend Status
# ============================================================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}7. Halext Backend Status${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if pgrep -f "uvicorn.*halext" > /dev/null; then
    echo -e "${GREEN}✅ Halext backend is running${NC}"

    echo ""
    echo "Backend Process:"
    ps aux | grep "uvicorn.*halext" | grep -v grep
    echo ""

    # Test API
    if curl -s http://localhost:8000/docs > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Backend API responding${NC}"
    else
        echo -e "${RED}❌ Backend API not responding${NC}"
    fi
    echo ""
else
    echo -e "${RED}❌ Halext backend not running${NC}"

    # Check systemd service
    if systemctl is-active --quiet halext-backend 2>/dev/null; then
        echo "Halext backend systemd service status:"
        systemctl status halext-backend --no-pager -l | head -20
    fi
    echo ""
fi

# ============================================================================
# Network Status
# ============================================================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}8. Network & Connections${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo "Listening Ports:"
ss -tlnp 2>/dev/null | grep LISTEN | grep -E ":(80|443|8000|3000|11434)" || netstat -tlnp 2>/dev/null | grep LISTEN | grep -E ":(80|443|8000|3000|11434)" || echo "Could not check ports"
echo ""

echo "Active Connections (count):"
ss -tan | tail -n +2 | wc -l
echo ""

echo "Network Interface Stats:"
ip -s link 2>/dev/null || ifconfig -s
echo ""

# ============================================================================
# Recent Errors in Logs
# ============================================================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}9. Recent Errors in Logs${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo "System Journal Errors (last 20):"
journalctl -p err -n 20 --no-pager 2>/dev/null || echo "Could not access journal"
echo ""

if [ -f ~/halext-org/backend/backend.log ]; then
    echo "Backend Errors (last 10):"
    tail -100 ~/halext-org/backend/backend.log | grep -i "error\|exception\|critical" | tail -10 || echo "No recent errors"
    echo ""
fi

# ============================================================================
# Nginx Status (if applicable)
# ============================================================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}10. Nginx Status${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if command -v nginx &> /dev/null; then
    if systemctl is-active --quiet nginx 2>/dev/null; then
        echo -e "${GREEN}✅ Nginx is running${NC}"

        # Check nginx worker processes
        echo ""
        echo "Nginx Workers:"
        ps aux | grep nginx | grep -v grep
        echo ""

        # Check error log
        if [ -f /var/log/nginx/error.log ]; then
            echo "Recent Nginx Errors:"
            tail -20 /var/log/nginx/error.log | grep -i "error\|warn" || echo "No recent errors"
        fi
    else
        echo -e "${RED}❌ Nginx not running${NC}"
    fi
else
    echo "Nginx not installed"
fi
echo ""

# ============================================================================
# Summary & Recommendations
# ============================================================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}11. Summary & Recommendations${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Collect issues
ISSUES=()

if (( $(echo "$LOAD_1MIN > $LOAD_THRESHOLD" | bc -l) )); then
    ISSUES+=("High CPU load")
fi

if (( $(echo "$MEMORY_PERCENT > 80" | bc -l) )); then
    ISSUES+=("High memory usage")
fi

if [ "$DISK_PERCENT" -gt 80 ]; then
    ISSUES+=("High disk usage")
fi

if ! pgrep -f "ollama serve" > /dev/null; then
    ISSUES+=("Ollama not running")
fi

if ! pgrep -f "uvicorn.*halext" > /dev/null; then
    ISSUES+=("Backend not running")
fi

if [ ${#ISSUES[@]} -eq 0 ]; then
    echo -e "${GREEN}✅ No major issues detected!${NC}"
    echo ""
    echo "System appears healthy. If experiencing slowness:"
    echo "  1. Check network latency to the server"
    echo "  2. Review recent code changes"
    echo "  3. Monitor over time with: watch -n 5 'docker stats --no-stream'"
else
    echo -e "${YELLOW}⚠️  Issues detected:${NC}"
    for issue in "${ISSUES[@]}"; do
        echo "  • $issue"
    done
    echo ""

    echo -e "${YELLOW}Recommendations:${NC}"

    if (( $(echo "$MEMORY_PERCENT > 80" | bc -l) )); then
        echo "  📌 High Memory:"
        echo "     - Restart Ollama: sudo systemctl restart ollama"
        echo "     - Restart OpenWebUI: docker restart openwebui"
        echo "     - Consider unloading unused models: ollama list"
    fi

    if (( $(echo "$LOAD_1MIN > $LOAD_THRESHOLD" | bc -l) )); then
        echo "  📌 High CPU Load:"
        echo "     - Check if model is being used: docker logs openwebui | tail"
        echo "     - Reduce concurrent requests"
        echo "     - Consider upgrading server resources"
    fi

    if [ "$DISK_PERCENT" -gt 80 ]; then
        echo "  📌 High Disk Usage:"
        echo "     - Clean Docker: docker system prune -a"
        echo "     - Remove old models: ollama rm <model-name>"
        echo "     - Clear logs: sudo journalctl --vacuum-time=7d"
    fi
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}   Diagnostic Complete${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "💡 Tip: Run this script periodically to monitor performance"
echo "💡 Save output: ./ubuntu-diagnose-performance.sh > diagnostic-\$(date +%Y%m%d).txt"
echo ""
