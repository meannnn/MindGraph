#!/bin/bash
# 使用国内镜像加速 npm install

echo "========================================"
echo "使用国内镜像安装依赖"
echo "========================================"
echo ""

# 检查是否在 frontend 目录
if [ ! -f "package.json" ]; then
    echo "错误：请在 frontend 目录中运行此脚本"
    exit 1
fi

echo "[1/3] 清理旧的安装..."
rm -rf node_modules package-lock.json
npm cache clean --force
echo "  ✓ 清理完成"

echo ""
echo "[2/3] 设置淘宝镜像..."
npm config set registry https://registry.npmmirror.com
echo "  ✓ 镜像已设置"

echo ""
echo "[3/3] 开始安装依赖..."
echo "  这可能需要几分钟时间，请耐心等待..."
echo ""

npm install

if [ $? -eq 0 ]; then
    echo ""
    echo "========================================"
    echo "✓ 安装成功！"
    echo "========================================"
    echo ""
    echo "可选：恢复官方源"
    echo "  npm config set registry https://registry.npmjs.org"
else
    echo ""
    echo "========================================"
    echo "✗ 安装失败"
    echo "========================================"
    echo ""
    echo "请检查："
    echo "  1. 网络连接"
    echo "  2. 磁盘空间: df -h"
    echo "  3. 权限问题"
fi
