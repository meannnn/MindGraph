#!/bin/bash
# 在 WSL 中安装 Node.js 18.x 的脚本

echo "========================================"
echo "在 WSL 中安装 Node.js"
echo "========================================"
echo ""

# 检查是否在 WSL 中
if [ -z "$WSL_DISTRO_NAME" ] && [ ! -f /proc/version ] || ! grep -q Microsoft /proc/version 2>/dev/null; then
    echo "⚠️  这似乎不是 WSL 环境"
    echo "   如果您在 Windows PowerShell 中，Node.js 应该已经可用"
    echo "   请运行: node --version"
    exit 1
fi

echo "[1/4] 检查当前 Node.js 安装..."
if command -v node &> /dev/null; then
    CURRENT_VERSION=$(node --version)
    echo "  ✓ 已安装: $CURRENT_VERSION"
    read -p "是否要重新安装或升级？(y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "跳过安装"
        exit 0
    fi
else
    echo "  ✗ 未安装 Node.js"
fi

echo ""
echo "[2/4] 更新系统包列表..."
sudo apt update

echo ""
echo "[3/4] 安装 Node.js 18.x (使用 NodeSource 官方仓库)..."
# 下载并运行 NodeSource 安装脚本
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -

# 安装 Node.js
sudo apt-get install -y nodejs

echo ""
echo "[4/4] 验证安装..."
NODE_VERSION=$(node --version 2>/dev/null)
NPM_VERSION=$(npm --version 2>/dev/null)

if [ -n "$NODE_VERSION" ]; then
    echo "  ✓ Node.js: $NODE_VERSION"
else
    echo "  ✗ Node.js 安装失败"
    exit 1
fi

if [ -n "$NPM_VERSION" ]; then
    echo "  ✓ npm: $NPM_VERSION"
else
    echo "  ✗ npm 安装失败"
    exit 1
fi

echo ""
echo "========================================"
echo "安装完成！"
echo "========================================"
echo ""
echo "现在可以运行项目了："
echo "  cd /mnt/d/MindMate/MindGraph-main"
echo "  ./start.sh"
echo ""
