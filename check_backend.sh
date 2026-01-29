#!/bin/bash
# 检查后端服务状态

PORT=9527

echo "========================================"
echo "检查后端服务状态 (端口 $PORT)"
echo "========================================"

# 检查端口是否被占用
PID=$(lsof -ti :$PORT 2>/dev/null)

if [ -z "$PID" ]; then
    echo "✗ 端口 $PORT 未被占用 - 后端服务未运行"
    echo ""
    echo "解决方案："
    echo "1. 启动后端服务："
    echo "   cd /mnt/d/MindMate/MindGraph-main"
    echo "   ./start.sh"
    echo ""
    echo "2. 或者使用 Python 直接启动："
    echo "   python -m services.infrastructure.process.server_launcher"
    exit 1
fi

echo "✓ 发现进程占用端口 $PORT: PID $PID"

# 显示进程信息
echo ""
echo "进程详细信息:"
ps -p $PID -o pid,ppid,cmd --no-headers 2>/dev/null || echo "无法获取进程信息"

# 检查是否是 Python/Uvicorn 进程
IS_PYTHON=$(ps -p $PID -o cmd --no-headers 2>/dev/null | grep -iE "python|uvicorn")
if [ -z "$IS_PYTHON" ]; then
    echo ""
    echo "⚠ 警告: 占用端口的进程不是 Python/Uvicorn，可能是其他服务"
fi

# 测试 HTTP 连接
echo ""
echo "测试 HTTP 连接..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$PORT/health 2>/dev/null)

if [ "$HTTP_CODE" = "200" ]; then
    echo "✓ 后端服务正常运行 (HTTP $HTTP_CODE)"
    echo ""
    echo "服务地址:"
    echo "  - API: http://localhost:$PORT"
    echo "  - 健康检查: http://localhost:$PORT/health"
    echo "  - API 文档: http://localhost:$PORT/docs"
elif [ "$HTTP_CODE" = "000" ]; then
    echo "✗ 无法连接到后端服务 (连接被拒绝)"
    echo ""
    echo "可能的原因："
    echo "1. 服务正在启动中，请稍等片刻"
    echo "2. 服务启动失败，请检查日志"
    echo "3. 防火墙阻止了连接"
else
    echo "⚠ 后端服务响应异常 (HTTP $HTTP_CODE)"
    echo "   服务可能正在启动或遇到错误"
fi
