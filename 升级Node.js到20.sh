#!/bin/bash
# 升级 Node.js 到版本 20 的脚本

echo "========================================"
echo "升级 Node.js 到版本 20"
echo "========================================"
echo ""

# 检查当前版本
CURRENT_VERSION=$(node --version 2>/dev/null)
echo "当前 Node.js 版本: ${CURRENT_VERSION:-未安装}"
echo ""

# 检查是否已安装 nvm
if [ -s "$HOME/.nvm/nvm.sh" ]; then
    echo "[方法 1] 使用 nvm 升级（推荐）..."
    source "$HOME/.nvm/nvm.sh"
    
    echo "  安装 Node.js 20..."
    nvm install 20
    nvm use 20
    nvm alias default 20
    
    NEW_VERSION=$(node --version)
    echo "  ✓ 已升级到: $NEW_VERSION"
    
elif command -v nvm &> /dev/null; then
    echo "[方法 1] 使用 nvm 升级..."
    nvm install 20
    nvm use 20
    nvm alias default 20
    
    NEW_VERSION=$(node --version)
    echo "  ✓ 已升级到: $NEW_VERSION"
    
else
    echo "[方法 2] 使用 NodeSource 仓库升级..."
    
    # 检查是否在 WSL/Linux
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "  更新系统包列表..."
        sudo apt update
        
        echo "  添加 NodeSource Node.js 20 仓库..."
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        
        echo "  安装 Node.js 20..."
        sudo apt-get install -y nodejs
        
        NEW_VERSION=$(node --version)
        echo "  ✓ 已升级到: $NEW_VERSION"
        
    else
        echo "  ⚠ 请手动安装 Node.js 20"
        echo "  访问: https://nodejs.org/"
        echo "  下载并安装 Node.js 20 LTS 版本"
        exit 1
    fi
fi

echo ""
echo "========================================"
echo "验证安装..."
echo "========================================"

NODE_VERSION=$(node --version 2>/dev/null)
NPM_VERSION=$(npm --version 2>/dev/null)

if [ -n "$NODE_VERSION" ]; then
    echo "  ✓ Node.js: $NODE_VERSION"
    
    # 检查版本是否符合要求（>= 20）
    MAJOR_VERSION=$(echo $NODE_VERSION | sed 's/v\([0-9]*\).*/\1/')
    if [ "$MAJOR_VERSION" -ge 20 ]; then
        echo "  ✓ 版本符合要求（>= 20）"
    else
        echo "  ⚠ 版本仍然低于 20，请检查安装"
    fi
else
    echo "  ✗ Node.js 未正确安装"
    exit 1
fi

if [ -n "$NPM_VERSION" ]; then
    echo "  ✓ npm: $NPM_VERSION"
fi

echo ""
echo "========================================"
echo "升级完成！"
echo "========================================"
echo ""
echo "现在可以继续构建前端："
echo "  cd frontend"
echo "  npm install"
echo "  npm run build"
echo ""
