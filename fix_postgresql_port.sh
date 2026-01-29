#!/bin/bash
# 修复 PostgreSQL 端口占用问题

echo "========================================"
echo "检查占用 5432 端口的进程"
echo "========================================"

# 检查端口占用
PORT_PID=$(lsof -ti :5432 2>/dev/null)

if [ -z "$PORT_PID" ]; then
    echo "✓ 端口 5432 未被占用"
    exit 0
fi

echo "发现占用 5432 端口的进程: PID $PORT_PID"

# 显示进程信息
echo ""
echo "进程详细信息:"
ps -p $PORT_PID -o pid,ppid,cmd --no-headers 2>/dev/null || echo "无法获取进程信息"

# 检查是否是 PostgreSQL
IS_POSTGRES=$(ps -p $PORT_PID -o cmd --no-headers 2>/dev/null | grep -i postgres)
if [ -n "$IS_POSTGRES" ]; then
    echo ""
    echo "✓ 这是 PostgreSQL 进程，无需处理"
    exit 0
fi

echo ""
echo "这不是 PostgreSQL 进程，可能是之前的应用进程"
echo ""
read -p "是否终止此进程 (PID $PORT_PID)? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "正在终止进程 $PORT_PID..."
    kill -9 $PORT_PID 2>/dev/null
    sleep 1
    
    # 再次检查
    if lsof -ti :5432 >/dev/null 2>&1; then
        echo "✗ 进程仍在运行，尝试强制终止..."
        kill -9 $PORT_PID 2>/dev/null
        sleep 1
    fi
    
    if ! lsof -ti :5432 >/dev/null 2>&1; then
        echo "✓ 端口 5432 已释放"
    else
        echo "✗ 无法释放端口，请手动处理"
        echo "   手动终止: kill -9 $PORT_PID"
    fi
else
    echo "已取消操作"
    echo ""
    echo "如果不想终止此进程，可以使用方案2：修改 PostgreSQL 端口"
    echo "在 .env 文件中添加: POSTGRESQL_PORT=5433"
fi
