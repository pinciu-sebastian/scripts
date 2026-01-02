#!/usr/bin/env bash
# --------------------------------------------------------------------
# Lab Health Dashboard
# --------------------------------------------------------------------
# A quick overview of your home lab server status.
# Usage: sudo ./lab-health.sh
# --------------------------------------------------------------------

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

OS="$(uname -s)"

print_header() {
    echo -e "\n${BOLD}${BLUE}=== $1 ===${NC}"
}

check_command() {
    command -v "$1" >/dev/null 2>&1
}

# --- System Stats ---
print_header "System Status"
echo -e "${BOLD}Hostname:${NC} $(hostname)"

# Uptime
if [ "$OS" = "Darwin" ]; then
    echo -e "${BOLD}Uptime:${NC} $(uptime | sed 's/.*up //; s/,.*//')"
else
    echo -e "${BOLD}Uptime:${NC} $(uptime -p)"
fi

# Load Average
echo -e "${BOLD}Load Average:${NC} $(uptime | awk -F'load average:' '{ print $2 }')"

# Memory Usage
echo -e "${BOLD}Memory Usage:${NC}"
if [ "$OS" = "Darwin" ]; then
    # macOS memory usage using top (simplest way to get human readable summary)
    top -l 1 | grep PhysMem | awk '{print "  " $0}'
else
    # Linux memory usage
    free -h | awk 'NR==2{printf "  Total: %s | Used: %s | Free: %s\n", $2, $3, $4}'
fi

# Disk Usage
echo -e "${BOLD}Disk Usage (/):${NC}"
df -h / | awk 'NR==2{printf "  Total: %s | Used: %s (%s) | Available: %s\n", $2, $3, $5, $4}'

# --- Network ---
print_header "Network"
echo -e "${BOLD}IP Addresses:${NC}"
if [ "$OS" = "Darwin" ]; then
    # macOS IP addresses
    ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print "  - " $2}'
else
    # Linux IP addresses
    hostname -I | tr ' ' '\n' | sed 's/^/  - /'
fi

# --- Docker ---
print_header "Docker Status"
if check_command docker; then
    # Check if docker daemon is reachable
    if docker info >/dev/null 2>&1; then
        TOTAL=$(docker ps -a -q | wc -l | xargs)
        RUNNING=$(docker ps -q | wc -l | xargs)
        EXITED=$((TOTAL - RUNNING))
        
        echo -e "  ${GREEN}● Service Active${NC}"
        echo -e "  Containers: ${BOLD}$TOTAL${NC} (Running: ${GREEN}$RUNNING${NC}, Exited: ${YELLOW}$EXITED${NC})"
        
        # List unhealthy containers if any
        UNHEALTHY=$(docker ps --filter health=unhealthy -q | wc -l | xargs)
        if [ "$UNHEALTHY" -gt 0 ]; then
             echo -e "  ${RED}⚠️  Unhealthy Containers: $UNHEALTHY${NC}"
             docker ps --filter health=unhealthy --format "    - {{.Names}}"
        fi
    else
        echo -e "  ${RED}● Service Inactive or Unreachable${NC}"
    fi
else
    echo -e "  ${YELLOW}Docker not installed${NC}"
fi

# --- MicroCeph ---
# MicroCeph is Linux only usually, but we keep the check safe
print_header "MicroCeph Status"
if check_command microceph; then
    STATUS=$(microceph status | grep "Status:" | awk '{print $2}')
    if [ "$STATUS" == "OK" ] || [ "$STATUS" == "HEALTH_OK" ]; then
         echo -e "  ${GREEN}● Cluster Status: OK${NC}"
    else
         echo -e "  Status: $(microceph status | grep "Status:" || echo "Unknown")"
    fi
    
    OSDS=$(microceph status | grep "OSDs:" | awk '{print $2}' || true)
    if [ -n "$OSDS" ]; then
        echo -e "  OSDs: $OSDS"
    fi
else
    echo -e "  ${YELLOW}MicroCeph not installed${NC}"
fi

echo -e "\n"
