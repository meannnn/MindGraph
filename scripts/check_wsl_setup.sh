#!/bin/bash
#
# WSL 环境配置检查脚本 | WSL Environment Setup Check Script
# 检查 WSL、Redis 8.4、PostgreSQL 18 是否正确配置
# Check if WSL, Redis 8.4, PostgreSQL 18 are properly configured
#
# Usage: bash scripts/check_wsl_setup.sh
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "================================================"
echo "  MindGraph WSL 环境配置检查"
echo "  MindGraph WSL Environment Setup Check"
echo "================================================"
echo ""

# Check if running in WSL
if [ -f /proc/version ] && grep -qi microsoft /proc/version; then
    echo -e "${GREEN}✓${NC} Running in WSL"
else
    echo -e "${YELLOW}⚠${NC} Not running in WSL (or WSL detection failed)"
    echo "   Please run this script in WSL environment"
fi
echo ""

# Check Redis
echo "检查 Redis 8.4 | Checking Redis 8.4..."
if command -v redis-cli &> /dev/null; then
    REDIS_VERSION=$(redis-cli --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    REDIS_MAJOR=$(echo $REDIS_VERSION | cut -d. -f1)
    REDIS_MINOR=$(echo $REDIS_VERSION | cut -d. -f2)
    
    if [ "$REDIS_MAJOR" -ge 8 ] && [ "$REDIS_MINOR" -ge 4 ]; then
        echo -e "${GREEN}✓${NC} Redis version: $REDIS_VERSION (>= 8.4)"
    else
        echo -e "${RED}✗${NC} Redis version: $REDIS_VERSION (requires >= 8.4)"
        echo "   Please refer to docs/REDIS_SETUP.md for installation"
    fi
    
    # Check if Redis is running
    if redis-cli ping &> /dev/null; then
        echo -e "${GREEN}✓${NC} Redis is running"
    else
        echo -e "${YELLOW}⚠${NC} Redis is not running"
        echo "   Start with: sudo systemctl start redis-server"
    fi
else
    echo -e "${RED}✗${NC} Redis is not installed"
    echo "   Please refer to docs/REDIS_SETUP.md for installation"
fi
echo ""

# Check PostgreSQL
echo "检查 PostgreSQL 18 | Checking PostgreSQL 18..."
if command -v psql &> /dev/null; then
    PSQL_VERSION=$(psql --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1)
    PSQL_MAJOR=$(echo $PSQL_VERSION | cut -d. -f1)
    
    if [ "$PSQL_MAJOR" -ge 18 ]; then
        echo -e "${GREEN}✓${NC} PostgreSQL version: $PSQL_VERSION (>= 18)"
    else
        echo -e "${RED}✗${NC} PostgreSQL version: $PSQL_VERSION (requires >= 18)"
        echo "   Please refer to https://www.postgresql.org/download/linux/ubuntu/"
    fi
    
    # Check PostgreSQL binary path
    if [ -f "/usr/lib/postgresql/18/bin/postgres" ]; then
        echo -e "${GREEN}✓${NC} PostgreSQL 18 binary found"
    else
        echo -e "${YELLOW}⚠${NC} PostgreSQL 18 binary not found at /usr/lib/postgresql/18/bin/postgres"
    fi
    
    # Check if PostgreSQL is running
    if sudo systemctl is-active --quiet postgresql 2>/dev/null; then
        echo -e "${GREEN}✓${NC} PostgreSQL service is running"
    else
        echo -e "${YELLOW}⚠${NC} PostgreSQL service is not running (MindGraph can auto-start it)"
    fi
else
    echo -e "${RED}✗${NC} PostgreSQL is not installed"
    echo "   Please refer to https://www.postgresql.org/download/linux/ubuntu/"
fi
echo ""

# Check Python
echo "检查 Python | Checking Python..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version 2>&1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
    PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d. -f1)
    PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d. -f2)
    
    if [ "$PYTHON_MAJOR" -ge 3 ] && [ "$PYTHON_MINOR" -ge 8 ]; then
        echo -e "${GREEN}✓${NC} Python version: $PYTHON_VERSION (>= 3.8)"
    else
        echo -e "${RED}✗${NC} Python version: $PYTHON_VERSION (requires >= 3.8)"
    fi
else
    echo -e "${RED}✗${NC} Python 3 is not installed"
fi
echo ""

# Check Node.js
echo "检查 Node.js | Checking Node.js..."
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version 2>&1 | grep -oE '[0-9]+' | head -1)
    
    if [ "$NODE_VERSION" -ge 18 ]; then
        echo -e "${GREEN}✓${NC} Node.js version: $(node --version) (>= 18)"
    else
        echo -e "${RED}✗${NC} Node.js version: $(node --version) (requires >= 18)"
    fi
else
    echo -e "${RED}✗${NC} Node.js is not installed"
fi
echo ""

echo "================================================"
echo "检查完成 | Check Complete"
echo "================================================"
echo ""
echo "参考文档 | Reference Documentation:"
echo "  - WSL 配置: docs/WSL_SETUP.md"
echo "  - Redis 安装: docs/REDIS_SETUP.md"
echo "  - PostgreSQL 安装: https://www.postgresql.org/download/linux/ubuntu/"
echo ""
