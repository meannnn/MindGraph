#!/bin/bash
# 安装 nvm 并升级 Node.js 到版本 20

echo "========================================"
echo "安装 nvm 并升级 Node.js 到版本 20"
echo "========================================"
echo ""

# 检查是否已安装 nvm
if [ -s "$HOME/.nvm/nvm.sh" ]; then
    echo "✓ nvm 已安装"
    source "$HOME/.nvm/nvm.sh"
else
    echo "[1/4] 安装 nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    
    # 加载 nvm
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$HOME/.bashrc" ] && source "$HOME/.bashrc"
    
    echo "  ✓ nvm 安装完成"
    echo ""
    echo "  ⚠ 请重新打开终端，或运行以下命令加载 nvm："
    echo "     source ~/.nvm/nvm.sh"
    echo ""
    echo "  然后重新运行此脚本"
    exit 0
fi

echo ""
echo "[2/4] 检查当前 Node.js 版本..."
CURRENT_VERSION=$(node --version 2>/dev/null)
if [ -n "$CURRENT_VERSION" ]; then
    echo "  当前版本: $CURRENT_VERSION"
else
    echo "  未安装 Node.js"
fi

echo ""
echo "[3/4] 安装 Node.js 20 LTS..."
nvm install 20
nvm use 20
nvm alias default 20

echo ""
echo "[4/4] 验证安装..."
NEW_VERSION=$(node --version 2>/dev/null)
NPM_VERSION=$(npm --version 2>/dev/null)

if [ -n "$NEW_VERSION" ]; then
    echo "  ✓ Node.js: $NEW_VERSION"
    
    # 检查版本是否符合要求
    MAJOR_VERSION=$(echo $NEW_VERSION | sed 's/v\([0-9]*\).*/\1/')
    if [ "$MAJOR_VERSION" -ge 20 ]; then
        echo "  ✓ 版本符合要求（>= 20）"
    else
        echo "  ⚠ 版本仍然低于 20"
        exit 1
    fi
else
    echo "  ✗ Node.js 安装失败"
    exit 1
fi

if [ -n "$NPM_VERSION" ]; then
    echo "  ✓ npm: $NPM_VERSION"
fi

echo ""
echo "========================================"
echo "安装完成！"
echo "========================================"
echo ""
echo "现在可以继续构建前端："
echo "  cd frontend"
echo "  npm install"
echo "  npm run build"
echo ""
echo "或者运行启动脚本："
echo "  ./start.sh"
echo ""
