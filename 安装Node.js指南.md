# Node.js 安装指南

## 📋 当前状态

根据检查，您的 Windows 系统中已安装：
- **Node.js v18.15.0** ✅
- 安装路径：`D:\Program Files\nodejs\`

## 🔍 问题诊断

如果您看到"Node.js 未安装"的错误，可能是以下原因：

1. **在 WSL 中运行**：Windows 的 Node.js 在 WSL 中不可用
2. **环境变量未刷新**：需要重新打开终端
3. **PATH 配置问题**：Node.js 路径未正确添加到 PATH

---

## 🚀 解决方案

### 方案 1：在 WSL 中安装 Node.js（推荐）

如果您在 WSL 中运行项目，需要在 WSL 中安装 Node.js：

#### 方法 A：使用 NodeSource 官方仓库（推荐）

```bash
# 在 WSL 中执行
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# 验证安装
node --version
npm --version
```

#### 方法 B：使用 nvm（Node Version Manager）

```bash
# 安装 nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# 重新加载 shell 配置
source ~/.bashrc

# 安装 Node.js 18
nvm install 18
nvm use 18

# 验证安装
node --version
npm --version
```

#### 方法 C：使用 apt 安装（简单但版本可能较旧）

```bash
# 更新包列表
sudo apt update

# 安装 Node.js 和 npm
sudo apt install nodejs npm -y

# 验证安装
node --version
npm --version

# 如果版本太旧，可以升级到 Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

---

### 方案 2：在 Windows 中验证 Node.js

如果您在 Windows PowerShell 中运行：

```powershell
# 检查 Node.js 版本
node --version

# 检查 npm 版本
npm --version

# 如果命令不存在，检查 PATH
$env:PATH -split ';' | Select-String -Pattern 'node'

# 如果 Node.js 已安装但不在 PATH 中，手动添加到 PATH
# 或者重新安装 Node.js，确保勾选"Add to PATH"选项
```

---

### 方案 3：重新安装 Node.js（Windows）

如果 Windows 中的 Node.js 有问题：

1. **下载 Node.js**
   - 访问：https://nodejs.org/
   - 下载 LTS 版本（推荐 18.x 或更高）
   - 选择 Windows Installer (.msi)

2. **安装步骤**
   - 运行安装程序
   - **重要**：确保勾选 "Add to PATH" 选项
   - 完成安装

3. **验证安装**
   ```powershell
   # 重新打开 PowerShell 或 CMD
   node --version
   npm --version
   ```

---

## ✅ 验证安装

安装完成后，验证 Node.js 和 npm：

```bash
# 检查 Node.js 版本（应该显示 v18.x.x 或更高）
node --version

# 检查 npm 版本
npm --version

# 检查安装路径
which node    # Linux/WSL
where.exe node  # Windows
```

---

## 🔧 常见问题

### 问题 1：命令未找到

**症状**：`node: command not found`

**解决方案**：
```bash
# Linux/WSL：检查是否在 PATH 中
echo $PATH | grep node

# 如果不在，添加到 PATH（临时）
export PATH=$PATH:/usr/bin/node

# 或重新安装 Node.js
```

### 问题 2：版本过旧

**症状**：Node.js 版本低于 18

**解决方案**：
```bash
# 使用 nvm 升级（推荐）
nvm install 18
nvm use 18

# 或使用 NodeSource 仓库升级
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

### 问题 3：npm 未安装

**症状**：`npm: command not found`

**解决方案**：
```bash
# Node.js 18+ 自带 npm，如果缺失，重新安装 Node.js
# 或单独安装 npm（不推荐）
sudo apt install npm -y
```

---

## 📝 安装后步骤

安装 Node.js 后，继续运行项目：

```bash
# 1. 进入前端目录
cd frontend

# 2. 安装依赖
npm install

# 3. 构建前端
npm run build

# 4. 返回项目根目录
cd ..

# 5. 运行服务器
python main.py
```

---

## 🌐 参考资源

- **Node.js 官网**：https://nodejs.org/
- **NodeSource 仓库**：https://github.com/nodesource/distributions
- **nvm 文档**：https://github.com/nvm-sh/nvm
- **npm 文档**：https://docs.npmjs.com/

---

## 💡 推荐配置

对于 MindGraph 项目，推荐：
- **Node.js 版本**：18.x 或更高（LTS）
- **npm 版本**：9.x 或更高（随 Node.js 自动安装）

安装完成后，运行启动脚本：
```bash
# Windows PowerShell
.\start.ps1

# WSL/Linux
chmod +x start.sh
./start.sh
```
