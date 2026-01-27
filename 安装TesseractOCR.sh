#!/bin/bash
# 安装 Tesseract OCR（解决 dpkg lock 冲突）

echo "========================================"
echo "安装 Tesseract OCR"
echo "========================================"
echo ""

# 检查是否已有其他 apt 进程
echo "[1/4] 检查 apt 进程..."
if pgrep -x "apt-get" > /dev/null || pgrep -x "apt" > /dev/null || pgrep -x "dpkg" > /dev/null; then
    echo "  ⚠ 检测到其他 apt/dpkg 进程正在运行"
    echo "  等待进程完成..."
    
    # 等待最多 60 秒
    for i in {1..60}; do
        if ! pgrep -x "apt-get" > /dev/null && ! pgrep -x "apt" > /dev/null && ! pgrep -x "dpkg" > /dev/null; then
            echo "  ✓ 其他进程已完成"
            break
        fi
        sleep 1
        echo -n "."
    done
    echo ""
    
    # 再次检查
    if pgrep -x "apt-get" > /dev/null || pgrep -x "apt" > /dev/null || pgrep -x "dpkg" > /dev/null; then
        echo "  ✗ 仍有进程在运行，请手动等待后重试"
        echo "  或运行: sudo killall apt-get apt dpkg"
        exit 1
    fi
fi

# 检查是否已安装
echo "[2/4] 检查 Tesseract OCR..."
if command -v tesseract &> /dev/null; then
    VERSION=$(tesseract --version 2>&1 | head -n 1)
    echo "  ✓ Tesseract 已安装: $VERSION"
    
    # 检查中文语言包
    if tesseract --list-langs 2>&1 | grep -q "chi_sim"; then
        echo "  ✓ 中文语言包已安装"
        echo ""
        echo "Tesseract OCR 已就绪！"
        exit 0
    else
        echo "  ⚠ 中文语言包未安装"
    fi
else
    echo "  ✗ Tesseract OCR 未安装"
fi

# 更新包列表
echo ""
echo "[3/4] 更新包列表..."
sudo apt update

# 安装 Tesseract OCR 和中文语言包
echo ""
echo "[4/4] 安装 Tesseract OCR 和中文语言包..."
sudo apt install -y tesseract-ocr tesseract-ocr-chi-sim

# 验证安装
echo ""
echo "验证安装..."
if command -v tesseract &> /dev/null; then
    VERSION=$(tesseract --version 2>&1 | head -n 1)
    echo "  ✓ Tesseract: $VERSION"
    
    if tesseract --list-langs 2>&1 | grep -q "chi_sim"; then
        echo "  ✓ 中文语言包已安装"
        echo ""
        echo "========================================"
        echo "✓ Tesseract OCR 安装成功！"
        echo "========================================"
    else
        echo "  ⚠ 中文语言包可能未正确安装"
    fi
else
    echo "  ✗ Tesseract OCR 安装失败"
    exit 1
fi
