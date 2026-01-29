#!/bin/bash
# 快速清理占用 9527 端口的进程

PORT=9527

echo "========================================"
echo "清理占用端口 $PORT 的进程"
echo "========================================"

# 查找占用端口的进程
PID=$(lsof -ti :$PORT 2>/dev/null)

if [ -z "$PID" ]; then
    echo "✓ 端口 $PORT 未被占用"
    exit 0
fi

echo "发现占用端口 $PORT 的进程: PID $PID"

# 显示进程信息
echo ""
echo "进程详细信息:"
ps -p $PID -o pid,ppid,cmd --no-headers 2>/dev/null || echo "无法获取进程信息"

echo ""
echo "正在终止进程 $PID..."
kill -9 $PID 2>/dev/null
sleep 1

# 再次检查
if lsof -ti :$PORT >/dev/null 2>&1; then
    echo "✗ 进程仍在运行，尝试强制终止..."
    kill -9 $PID 2>/dev/null
    sleep 1
fi

if ! lsof -ti :$PORT >/dev/null 2>&1; then
    echo "✓ 端口 $PORT 已释放"
else
    echo "✗ 无法释放端口，请手动处理"
    echo "   手动终止: kill -9 $PID"
    exit 1
fi
