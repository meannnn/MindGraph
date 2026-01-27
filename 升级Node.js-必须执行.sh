#!/bin/bash
# 必须升级 Node.js 到版本 20 - 构建失败的根本原因

echo "========================================"
echo "升级 Node.js 到版本 20（必需）"
echo "========================================"
echo ""

CURRENT_VERSION=$(node --version 2>/dev/null)
echo "当前版本: ${CURRENT_VERSION:-未安装}"
echo ""

# 检查是否已安装 nvm
if [ -s "$HOME/.nvm/nvm.sh" ]; then
    echo "[方法 1] 使用 nvm 升级..."
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
    echo "[方法 2] 安装 nvm 并升级 Node.js..."
    
    # 安装 nvm
    echo "  安装 nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    
    # 加载 nvm
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$HOME/.bashrc" ] && source "$HOME/.bashrc" 2>/dev/null || true
    
    # 安装 Node.js 20
    echo "  安装 Node.js 20..."
    nvm install 20
    nvm use 20
    nvm alias default 20
    
    NEW_VERSION=$(node --version)
    echo "  ✓ 已升级到: $NEW_VERSION"
    
    echo ""
    echo "  ⚠ 重要：如果命令未生效，请运行："
    echo "     source ~/.nvm/nvm.sh"
    echo "     或重新打开终端"
fi

echo ""
echo "========================================"
echo "验证安装..."
echo "========================================"

NODE_VERSION=$(node --version 2>/dev/null)
NPM_VERSION=$(npm --version 2>/dev/null)

if [ -n "$NODE_VERSION" ]; then
    echo "  ✓ Node.js: $NODE_VERSION"
    
    # 检查版本是否符合要求
    MAJOR_VERSION=$(echo $NODE_VERSION | sed 's/v\([0-9]*\).*/\1/')
    if [ "$MAJOR_VERSION" -ge 20 ]; then
        echo "  ✓ 版本符合要求（>= 20）"
    else
        echo "  ✗ 版本仍然低于 20，请检查安装"
        exit 1
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
echo "现在需要重新安装前端依赖："
echo "  cd frontend"
echo "  rm -rf node_modules package-lock.json"
echo "  npm install"
echo "  npm run build"
echo ""
