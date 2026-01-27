#!/bin/bash
# 修复权限问题并重新安装依赖

echo "========================================"
echo "修复权限问题并安装依赖"
echo "========================================"
echo ""

# 检查是否在 frontend 目录
if [ ! -f "package.json" ]; then
    echo "错误：请在 frontend 目录中运行此脚本"
    exit 1
fi

echo "[1/4] 停止可能运行的进程..."
# 查找并停止可能卡住的 npm 进程
pkill -f "npm install" 2>/dev/null || true
sleep 1

echo ""
echo "[2/4] 清理 node_modules（可能需要权限）..."
# 尝试普通删除
rm -rf node_modules package-lock.json 2>/dev/null || true

# 如果失败，使用 sudo（但会改变文件所有者）
if [ -d "node_modules" ]; then
    echo "  需要管理员权限清理..."
    sudo rm -rf node_modules package-lock.json
    # 修复所有者
    sudo chown -R $USER:$USER .
fi
echo "  ✓ 清理完成"

echo ""
echo "[3/4] 修复目录权限..."
# 确保当前用户拥有所有文件
chmod -R u+rw .
echo "  ✓ 权限已修复"

echo ""
echo "[4/4] 清理 npm 缓存并重新安装..."
npm cache clean --force
echo "  ✓ 缓存已清理"

echo ""
echo "开始安装依赖..."
echo "  这可能需要几分钟时间，请耐心等待..."
echo ""

npm install

if [ $? -eq 0 ]; then
    echo ""
    echo "========================================"
    echo "✓ 安装成功！"
    echo "========================================"
    echo ""
    echo "现在可以构建了："
    echo "  npm run build"
else
    echo ""
    echo "========================================"
    echo "✗ 安装失败"
    echo "========================================"
    echo ""
    echo "如果权限问题仍然存在，请尝试："
    echo "  1. 将项目移到 Linux 原生文件系统："
    echo "     cp -r /mnt/d/MindMate/MindGraph-main ~/MindGraph-main"
    echo "  2. 或使用 Windows 的 npm（在 PowerShell 中）"
fi
