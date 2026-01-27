# 停止 MindGraph 服务器 (PowerShell)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "停止 MindGraph 服务器" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 查找占用 9527 端口的进程
$portProcess = Get-NetTCPConnection -LocalPort 9527 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique

if ($portProcess) {
    Write-Host "  找到占用 9527 端口的进程: PID $portProcess" -ForegroundColor Yellow
    
    # 获取进程信息
    $process = Get-Process -Id $portProcess -ErrorAction SilentlyContinue
    if ($process) {
        Write-Host "  进程名称: $($process.ProcessName)" -ForegroundColor Gray
        Write-Host "  命令行: $($process.CommandLine)" -ForegroundColor Gray
    }
    
    Write-Host ""
    $confirm = Read-Host "  是否终止此进程？(y/n)"
    
    if ($confirm -eq "y" -or $confirm -eq "Y") {
        try {
            Stop-Process -Id $portProcess -Force
            Write-Host "  ✓ 服务器已停止" -ForegroundColor Green
        } catch {
            Write-Host "  ✗ 停止失败: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "  已取消" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ✓ 服务器未运行（端口 9527 未被占用）" -ForegroundColor Green
}

# 检查 Python main.py 进程
$pythonProcesses = Get-Process python -ErrorAction SilentlyContinue | Where-Object {
    $_.CommandLine -like "*main.py*"
}

if ($pythonProcesses) {
    Write-Host ""
    Write-Host "  发现 Python 进程:" -ForegroundColor Yellow
    foreach ($proc in $pythonProcesses) {
        Write-Host "    PID $($proc.Id): $($proc.ProcessName)" -ForegroundColor Gray
        try {
            Stop-Process -Id $proc.Id -Force
            Write-Host "    ✓ 已停止 PID $($proc.Id)" -ForegroundColor Green
        } catch {
            Write-Host "    ✗ 停止失败 PID $($proc.Id)" -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "停止完成" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
