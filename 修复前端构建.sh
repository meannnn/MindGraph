#!/bin/bash
# 修复前端构建问题

echo "========================================"
echo "修复前端构建"
echo "========================================"
echo ""

cd frontend

echo "[1/3] 清理旧的构建和依赖..."
rm -rf dist node_modules package-lock.json

echo ""
echo "[2/3] 重新安装依赖..."
npm install

echo ""
echo "[3/3] 验证 tsx 是否安装..."
if [ -f "node_modules/.bin/tsx" ]; then
    echo "  ✓ tsx 已安装"
else
    echo "  ✗ tsx 未找到，手动安装..."
    npm install tsx --save-dev
fi

echo ""
echo "[4/4] 构建前端..."
npm run build

echo ""
if [ -d "dist" ] && [ -f "dist/index.html" ]; then
    echo "========================================"
    echo "✓ 前端构建成功！"
    echo "========================================"
    echo ""
    echo "构建输出目录: frontend/dist"
    echo "现在可以运行服务器了: python main.py"
else
    echo "========================================"
    echo "✗ 前端构建失败"
    echo "========================================"
    echo ""
    echo "请检查上面的错误信息"
    exit 1
fi
