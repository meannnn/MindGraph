#!/bin/bash
# MindGraph 快速启动脚本 (Bash/WSL)
# 适用于 WSL/Linux 环境

echo "========================================"
echo "MindGraph 启动脚本"
echo "========================================"
echo ""

# 检查 Python
echo "[1/7] 检查 Python..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo "  ✓ $PYTHON_VERSION"
    PYTHON_CMD=python3
elif command -v python &> /dev/null; then
    PYTHON_VERSION=$(python --version)
    echo "  ✓ $PYTHON_VERSION"
    PYTHON_CMD=python
else
    echo "  ✗ Python 未安装"
    exit 1
fi

# 检查 Node.js
echo "[2/7] 检查 Node.js..."
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo "  ✓ Node.js $NODE_VERSION"
else
    echo "  ✗ Node.js 未安装"
    exit 1
fi

# 检查并启动 Redis
echo "[3/7] 检查 Redis..."
if redis-cli ping > /dev/null 2>&1; then
    echo "  ✓ Redis 正在运行"
else
    echo "  ⚠ Redis 未运行，正在启动..."
    if command -v systemctl &> /dev/null; then
        sudo systemctl start redis-server 2>/dev/null || sudo service redis-server start
    else
        redis-server --daemonize yes 2>/dev/null || echo "  ✗ 无法启动 Redis，请手动启动"
    fi
    sleep 1
    if redis-cli ping > /dev/null 2>&1; then
        echo "  ✓ Redis 已启动"
    else
        echo "  ✗ Redis 启动失败，请手动启动: sudo service redis-server start"
        read -p "是否继续？(y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
fi

# 检查并启动 Qdrant
echo "[4/7] 检查 Qdrant..."
if curl -s http://localhost:6333/collections > /dev/null 2>&1; then
    echo "  ✓ Qdrant 正在运行"
else
    echo "  ⚠ Qdrant 未运行（知识空间功能需要）"
    if command -v qdrant &> /dev/null; then
        echo "    正在启动 Qdrant..."
        qdrant > /dev/null 2>&1 &
        sleep 2
        if curl -s http://localhost:6333/collections > /dev/null 2>&1; then
            echo "  ✓ Qdrant 已启动"
        else
            echo "  ⚠ Qdrant 启动失败，请手动启动: qdrant &"
        fi
    else
        echo "  ⚠ Qdrant 未安装，请运行: bash scripts/setup/install_dependencies.sh --qdrant-only"
    fi
fi

# 检查 Python 依赖
echo "[5/7] 检查 Python 依赖..."
if $PYTHON_CMD -c "import fastapi" 2>/dev/null; then
    echo "  ✓ Python 依赖已安装"
else
    echo "  ⚠ Python 依赖未安装，正在安装..."
    $PYTHON_CMD -m pip install -r requirements.txt
    echo "  ✓ Python 依赖安装完成"
fi

# 检查前端是否已构建
echo "[6/7] 检查前端构建..."
if [ -d "frontend/dist" ] && [ -f "frontend/dist/index.html" ]; then
    echo "  ✓ 前端已构建"
else
    echo "  ⚠ 前端未构建，正在构建..."
    cd frontend
    
    # 确保 node_modules 存在且依赖完整
    if [ ! -d "node_modules" ] || [ ! -f "node_modules/.bin/tsx" ]; then
        echo "    安装前端依赖..."
        npm install
        # 验证 tsx 是否安装
        if [ ! -f "node_modules/.bin/tsx" ]; then
            echo "    ⚠ tsx 未找到，重新安装..."
            npm install tsx --save-dev
        fi
    fi
    
    echo "    构建前端..."
    # 确保使用本地的 tsx
    if [ -f "node_modules/.bin/tsx" ]; then
        npm run build
    else
        echo "    ✗ 无法构建：tsx 未安装"
        echo "    请手动运行: cd frontend && npm install && npm run build"
        cd ..
        exit 1
    fi
    
    cd ..
    
    # 验证构建结果
    if [ -d "frontend/dist" ] && [ -f "frontend/dist/index.html" ]; then
        echo "  ✓ 前端构建完成"
    else
        echo "  ✗ 前端构建失败，请检查错误信息"
        exit 1
    fi
fi

# 检查环境变量
echo "[7/7] 检查环境变量..."
if [ -f ".env" ]; then
    if grep -q "QWEN_API_KEY" .env && ! grep -q "QWEN_API_KEY=your-" .env; then
        echo "  ✓ .env 文件已配置"
    else
        echo "  ⚠ QWEN_API_KEY 未配置或使用默认值"
    fi
else
    echo "  ⚠ .env 文件不存在"
    if [ -f ".env.save" ]; then
        echo "    从 .env.save 复制..."
        cp .env.save .env
        echo "  ✓ 已创建 .env 文件，请配置 QWEN_API_KEY"
    fi
fi

echo ""
echo "========================================"
echo "启动服务器..."
echo "========================================"
echo ""
echo "访问地址:"
echo "  - 编辑器: http://localhost:9527/editor"
echo "  - 管理面板: http://localhost:9527/admin"
echo "  - 健康检查: http://localhost:9527/health"
echo ""
echo "按 Ctrl+C 停止服务器"
echo ""

# 启动服务器
$PYTHON_CMD main.py
