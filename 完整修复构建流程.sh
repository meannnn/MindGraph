#!/bin/bash
# 完整修复构建流程：升级 Node.js + 重新安装依赖 + 构建

echo "========================================"
echo "完整修复构建流程"
echo "========================================"
echo ""

# 步骤 1: 升级 Node.js
echo "[1/4] 检查 Node.js 版本..."
CURRENT_VERSION=$(node --version 2>/dev/null)
MAJOR_VERSION=$(echo $CURRENT_VERSION | sed 's/v\([0-9]*\).*/\1/')

if [ -z "$MAJOR_VERSION" ] || [ "$MAJOR_VERSION" -lt 20 ]; then
    echo "  ⚠ Node.js 版本过低 ($CURRENT_VERSION)，需要升级到 20+"
    echo ""
    echo "  请先运行升级脚本："
    echo "    bash 升级Node.js-必须执行.sh"
    echo ""
    echo "  或手动安装 nvm 并升级："
    echo "    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash"
    echo "    source ~/.nvm/nvm.sh"
    echo "    nvm install 20"
    echo "    nvm use 20"
    echo ""
    exit 1
else
    echo "  ✓ Node.js 版本符合要求: $CURRENT_VERSION"
fi

# 步骤 2: 进入前端目录
echo ""
echo "[2/4] 进入前端目录..."
cd frontend || exit 1
echo "  ✓ 当前目录: $(pwd)"

# 步骤 3: 清理并重新安装依赖
echo ""
echo "[3/4] 清理并重新安装依赖..."
rm -rf node_modules package-lock.json
echo "  ✓ 已清理旧依赖"

npm install
if [ $? -ne 0 ]; then
    echo "  ✗ npm install 失败"
    exit 1
fi
echo "  ✓ 依赖安装完成"

# 步骤 4: 构建
echo ""
echo "[4/4] 构建前端..."
npm run build
if [ $? -ne 0 ]; then
    echo "  ✗ 构建失败"
    exit 1
fi

echo ""
echo "========================================"
echo "✓ 构建成功！"
echo "========================================"
echo ""
echo "构建输出目录: frontend/dist"
echo "现在可以运行服务器了:"
echo "  cd .."
echo "  python main.py"
echo ""
