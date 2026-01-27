# 检查 npm install 状态

## 🔍 如何判断是否卡住

### 方法 1：检查进程
在**另一个终端窗口**运行：
```bash
ps aux | grep npm
# 或
ps aux | grep node
```

如果看到 npm/node 进程在运行，说明还在安装中。

### 方法 2：检查网络活动
```bash
# 检查网络连接
netstat -an | grep ESTABLISHED | grep -E "443|80"
```

如果有到 npm registry 的连接，说明正在下载。

### 方法 3：检查磁盘活动
```bash
# 检查磁盘 I/O
iostat -x 1
```

如果有磁盘写入活动，说明正在安装。

---

## ⏱️ 正常等待时间

- **首次安装**：5-15 分钟（取决于网络速度）
- **重新安装**：3-10 分钟
- **如果超过 20 分钟**：可能卡住了

---

## 🛠️ 如果确实卡住了

### 方案 1：中断并重试（推荐）

1. **在当前终端按 `Ctrl + C`** 中断安装
2. **清理并重试**：
```bash
# 清理缓存
npm cache clean --force

# 删除 node_modules（如果存在）
rm -rf node_modules package-lock.json

# 使用国内镜像（如果网络慢）
npm install --registry=https://registry.npmmirror.com

# 或使用官方源重试
npm install
```

### 方案 2：使用国内镜像（如果在中国）

```bash
# 设置淘宝镜像
npm config set registry https://registry.npmmirror.com

# 然后重新安装
npm install

# 安装完成后，可以恢复官方源（可选）
npm config set registry https://registry.npmjs.org
```

### 方案 3：使用 yarn（备选）

```bash
# 安装 yarn
npm install -g yarn

# 使用 yarn 安装（通常更快）
yarn install
```

### 方案 4：分步安装

```bash
# 只安装生产依赖
npm install --production

# 然后安装开发依赖
npm install --save-dev
```

---

## 💡 建议操作

1. **先等待 5-10 分钟**（如果网络较慢）
2. **如果超过 15 分钟**，按 `Ctrl + C` 中断
3. **使用国内镜像重试**（如果在中国）
4. **检查网络连接**

---

## 🚨 常见原因

1. **网络慢**：npm registry 连接慢
2. **包冲突**：依赖解析卡住
3. **磁盘空间不足**：检查 `df -h`
4. **权限问题**：检查目录权限
