# MindGraph 快速启动脚本 (PowerShell)
# 适用于 Windows 环境

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "MindGraph 启动脚本" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 检查 Python
Write-Host "[1/6] 检查 Python..." -ForegroundColor Yellow
try {
    $pythonVersion = python --version 2>&1
    Write-Host "  ✓ $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Python 未安装或不在 PATH 中" -ForegroundColor Red
    exit 1
}

# 检查 Node.js
Write-Host "[2/6] 检查 Node.js..." -ForegroundColor Yellow
try {
    $nodeVersion = node --version 2>&1
    Write-Host "  ✓ Node.js $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Node.js 未安装或不在 PATH 中" -ForegroundColor Red
    exit 1
}

# 检查 Redis（通过端口）
Write-Host "[3/6] 检查 Redis..." -ForegroundColor Yellow
$redisRunning = Test-NetConnection -ComputerName localhost -Port 6379 -InformationLevel Quiet -WarningAction SilentlyContinue
if ($redisRunning) {
    Write-Host "  ✓ Redis 正在运行" -ForegroundColor Green
} else {
    Write-Host "  ✗ Redis 未运行" -ForegroundColor Red
    Write-Host "    请在 WSL 中运行: sudo service redis-server start" -ForegroundColor Yellow
    Write-Host "    或使用 Docker: docker run -d -p 6379:6379 redis:7-alpine" -ForegroundColor Yellow
    Write-Host ""
    $continue = Read-Host "是否继续？(y/n)"
    if ($continue -ne "y") {
        exit 1
    }
}

# 检查 Qdrant（通过端口）
Write-Host "[4/6] 检查 Qdrant..." -ForegroundColor Yellow
$qdrantRunning = Test-NetConnection -ComputerName localhost -Port 6333 -InformationLevel Quiet -WarningAction SilentlyContinue
if ($qdrantRunning) {
    Write-Host "  ✓ Qdrant 正在运行" -ForegroundColor Green
} else {
    Write-Host "  ⚠ Qdrant 未运行（知识空间功能需要）" -ForegroundColor Yellow
    Write-Host "    请在 WSL 中运行: qdrant &" -ForegroundColor Yellow
    Write-Host "    或使用 Docker: docker run -d -p 6333:6333 qdrant/qdrant" -ForegroundColor Yellow
    Write-Host ""
}

# 检查前端是否已构建
Write-Host "[5/6] 检查前端构建..." -ForegroundColor Yellow
if (Test-Path "frontend\dist") {
    Write-Host "  ✓ 前端已构建" -ForegroundColor Green
} else {
    Write-Host "  ⚠ 前端未构建，正在构建..." -ForegroundColor Yellow
    Set-Location frontend
    Write-Host "    安装依赖..." -ForegroundColor Gray
    npm install
    Write-Host "    构建前端..." -ForegroundColor Gray
    npm run build
    Set-Location ..
    Write-Host "  ✓ 前端构建完成" -ForegroundColor Green
}

# 检查环境变量
Write-Host "[6/6] 检查环境变量..." -ForegroundColor Yellow
if (Test-Path ".env") {
    $envContent = Get-Content ".env" -Raw
    if ($envContent -match "QWEN_API_KEY\s*=\s*[^\s]+") {
        Write-Host "  ✓ .env 文件已配置" -ForegroundColor Green
    } else {
        Write-Host "  ⚠ QWEN_API_KEY 未配置" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ⚠ .env 文件不存在" -ForegroundColor Yellow
    Write-Host "    请复制 .env.save 到 .env 并配置" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "启动服务器..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "访问地址:" -ForegroundColor Green
Write-Host "  - 编辑器: http://localhost:9527/editor" -ForegroundColor White
Write-Host "  - 管理面板: http://localhost:9527/admin" -ForegroundColor White
Write-Host "  - 健康检查: http://localhost:9527/health" -ForegroundColor White
Write-Host ""
Write-Host "按 Ctrl+C 停止服务器" -ForegroundColor Yellow
Write-Host ""

# 启动服务器
python main.py
