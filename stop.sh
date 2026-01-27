#!/bin/bash
# 停止 MindGraph 服务器

echo "========================================"
echo "停止 MindGraph 服务器"
echo "========================================"
echo ""

# 查找主进程
MAIN_PID=$(ps aux | grep "[p]ython.*main.py" | awk '{print $2}' | head -n 1)

if [ -z "$MAIN_PID" ]; then
    echo "  ⚠ 未找到运行中的服务器进程"
    echo ""
    
    # 检查端口占用
    PORT_PID=$(lsof -ti :9527 2>/dev/null)
    if [ -n "$PORT_PID" ]; then
        echo "  发现占用 9527 端口的进程: $PORT_PID"
        read -p "  是否终止此进程？(y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            kill $PORT_PID
            echo "  ✓ 已终止进程 $PORT_PID"
        fi
    else
        echo "  ✓ 服务器未运行"
    fi
else
    echo "  找到服务器进程: PID $MAIN_PID"
    echo "  正在停止..."
    
    # 尝试优雅停止
    kill $MAIN_PID
    
    # 等待最多 5 秒
    for i in {1..5}; do
        if ! ps -p $MAIN_PID > /dev/null 2>&1; then
            echo "  ✓ 服务器已停止"
            exit 0
        fi
        sleep 1
    done
    
    # 如果还在运行，强制终止
    if ps -p $MAIN_PID > /dev/null 2>&1; then
        echo "  ⚠ 优雅停止失败，强制终止..."
        kill -9 $MAIN_PID
        sleep 1
        echo "  ✓ 服务器已强制停止"
    fi
fi

# 检查 Celery worker
CELERY_PID=$(ps aux | grep "[c]elery.*worker" | awk '{print $2}' | head -n 1)
if [ -n "$CELERY_PID" ]; then
    echo ""
    echo "  发现 Celery worker: PID $CELERY_PID"
    kill $CELERY_PID 2>/dev/null
    echo "  ✓ Celery worker 已停止"
fi

# 检查 PostgreSQL（如果是应用启动的）
POSTGRES_PID=$(ps aux | grep "[p]ostgres.*mindgraph" | awk '{print $2}' | head -n 1)
if [ -n "$POSTGRES_PID" ]; then
    echo ""
    echo "  发现 PostgreSQL 子进程: PID $POSTGRES_PID"
    echo "  ⚠ PostgreSQL 由应用管理，已随主进程停止"
fi

echo ""
echo "========================================"
echo "停止完成"
echo "========================================"
