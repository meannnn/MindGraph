# Node.js 版本升级指南

## 🔍 问题诊断

您当前安装的是 **Node.js v18.20.8**，但项目中的以下依赖需要 **Node.js 20 或更高版本**：

- `vite@7.3.1` - 需要 `node ^20.19.0 || >=22.12.0`
- `@vitejs/plugin-vue@6.0.3` - 需要 `node ^20.19.0 || >=22.12.0`
- `@trivago/prettier-plugin-sort-imports@6.0.2` - 需要 `node >= 20`

## 🚀 解决方案

### 方案 1：使用 nvm 升级（推荐，最简单）

nvm (Node Version Manager) 可以轻松管理多个 Node.js 版本。

#### 步骤 1：安装 nvm（如果未安装）

```bash
# 在 WSL 中执行
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

# 重新加载 shell 配置
source ~/.bashrc
# 或者重新打开终端
```

#### 步骤 2：使用 nvm 安装 Node.js 20

```bash
# 安装 Node.js 20 LTS
nvm install 20

# 使用 Node.js 20
nvm use 20

# 设置为默认版本（可选）
nvm alias default 20

# 验证版本
node --version  # 应该显示 v20.x.x
npm --version
```

#### 步骤 3：继续构建前端

```bash
cd frontend
npm install
npm run build
```

---

### 方案 2：使用 NodeSource 仓库升级（直接替换）

如果您不想使用 nvm，可以直接升级系统安装的 Node.js：

```bash
# 在 WSL 中执行

# 1. 移除旧版本（可选，但推荐）
sudo apt remove nodejs npm -y
sudo apt autoremove -y

# 2. 添加 NodeSource Node.js 20 仓库
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -

# 3. 安装 Node.js 20
sudo apt-get install -y nodejs

# 4. 验证安装
node --version  # 应该显示 v20.x.x
npm --version
```

---

### 方案 3：使用自动安装脚本

我已经为您创建了自动安装脚本：

```bash
# 方法 A：使用 nvm（推荐）
chmod +x 安装nvm并升级Node.js.sh
bash 安装nvm并升级Node.js.sh

# 方法 B：直接升级（不使用 nvm）
chmod +x 升级Node.js到20.sh
bash 升级Node.js到20.sh
```

---

## ✅ 验证升级

升级完成后，验证版本：

```bash
# 检查 Node.js 版本（应该 >= 20）
node --version

# 检查 npm 版本
npm --version

# 检查是否满足要求
node -e "console.log(parseInt(process.version.slice(1)) >= 20 ? '✓ 版本符合要求' : '✗ 版本过低')"
```

---

## 🔧 升级后步骤

### 1. 清理旧的 node_modules（推荐）

```bash
cd frontend
rm -rf node_modules package-lock.json
```

### 2. 重新安装依赖

```bash
npm install
```

### 3. 构建前端

```bash
npm run build
```

### 4. 返回项目根目录并运行

```bash
cd ..
python main.py
```

---

## ⚠️ 注意事项

1. **使用 nvm 的优势**：
   - 可以轻松切换不同 Node.js 版本
   - 不会影响系统其他应用
   - 推荐用于开发环境

2. **直接升级的影响**：
   - 会替换系统全局的 Node.js
   - 可能影响其他使用 Node.js 18 的项目
   - 如果其他项目需要 Node.js 18，建议使用 nvm

3. **版本要求**：
   - 最低要求：Node.js 20.19.0
   - 推荐：Node.js 20 LTS 或 22 LTS

---

## 🐛 常见问题

### 问题 1：nvm 命令未找到

**解决方案**：
```bash
# 重新加载配置
source ~/.bashrc

# 或手动加载
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
```

### 问题 2：升级后版本仍然是 18

**解决方案**：
```bash
# 检查当前使用的 Node.js 路径
which node

# 如果使用的是系统安装的，需要：
# 1. 使用 nvm 安装并切换
nvm install 20
nvm use 20

# 2. 或移除旧版本后重新安装
sudo apt remove nodejs npm
# 然后使用 NodeSource 仓库重新安装
```

### 问题 3：npm 警告仍然存在

**解决方案**：
```bash
# 清理缓存
npm cache clean --force

# 删除 node_modules 和 package-lock.json
rm -rf node_modules package-lock.json

# 重新安装
npm install
```

---

## 📝 快速命令参考

```bash
# 使用 nvm 安装 Node.js 20
nvm install 20 && nvm use 20 && nvm alias default 20

# 验证版本
node --version && npm --version

# 清理并重新安装前端依赖
cd frontend && rm -rf node_modules package-lock.json && npm install && npm run build
```

---

## 🎯 推荐流程

1. **安装 nvm**（如果未安装）
2. **使用 nvm 安装 Node.js 20**
3. **清理前端依赖**
4. **重新安装并构建前端**
5. **运行项目**

完成升级后，警告应该消失，前端可以正常构建！
