# 解决 WSL 权限问题

## 🔍 问题原因

在 WSL 中访问 Windows 文件系统（`/mnt/d/`）时，文件权限可能受限，导致 npm 无法重命名/移动文件。

## 🚀 解决方案

### 方案 1：修复权限并重新安装（推荐）

```bash
# 在 frontend 目录中
chmod +x 修复权限并安装.sh
bash 修复权限并安装.sh
```

或手动执行：
```bash
# 1. 清理
sudo rm -rf node_modules package-lock.json

# 2. 修复所有者
sudo chown -R $USER:$USER .

# 3. 修复权限
chmod -R u+rw .

# 4. 清理缓存
npm cache clean --force

# 5. 重新安装
npm install
```

### 方案 2：将项目移到 Linux 原生文件系统（最佳）

这是最彻底的解决方案，避免所有权限问题：

```bash
# 1. 复制项目到 Linux 文件系统
cp -r /mnt/d/MindMate/MindGraph-main ~/MindGraph-main

# 2. 进入新位置
cd ~/MindGraph-main/frontend

# 3. 安装依赖（不会有权限问题）
npm install

# 4. 构建
npm run build

# 5. 运行服务器
cd ..
python main.py
```

**注意**：项目会运行在 `~/MindGraph-main`，而不是 Windows 的 `d:\MindMate\MindGraph-main`

### 方案 3：使用 Windows 的 npm（备选）

在 Windows PowerShell 中：

```powershell
cd d:\MindMate\MindGraph-main\frontend
npm install
npm run build
```

然后在 WSL 中运行后端：
```bash
cd /mnt/d/MindMate/MindGraph-main
python main.py
```

### 方案 4：修复 WSL 挂载选项（高级）

编辑 `/etc/wsl.conf`：

```bash
sudo nano /etc/wsl.conf
```

添加：
```ini
[automount]
options = "metadata,umask=22,fmask=11"
```

然后重启 WSL。

---

## 💡 推荐流程

1. **先尝试方案 1**（修复权限）
2. **如果还是有问题，使用方案 2**（移到 Linux 文件系统）
3. **如果需要在 Windows 和 WSL 之间共享，使用方案 3**（Windows 构建，WSL 运行）

---

## ⚠️ 注意事项

1. **方案 2（移到 Linux 文件系统）**是最稳定的，但项目位置会改变
2. **方案 1（修复权限）**可能需要在每次安装后重复
3. **方案 3（Windows 构建）**需要确保两个环境使用相同的 Node.js 版本
