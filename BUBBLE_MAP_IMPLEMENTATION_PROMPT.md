# 气泡图实现提示词 | Bubble Map Implementation Prompt

> 用于在另一个项目中复现气泡图（Bubble Map）的完整技术规格和实现指南

---

## 📋 项目需求概述

实现一个**气泡图（Bubble Map）**可视化组件，具有以下核心特性：

1. **中心主题节点**：固定位置，显示主题文本
2. **属性节点**：围绕中心均匀分布，显示描述性属性
3. **动态布局**：支持任意数量节点，自动调整布局
4. **智能尺寸**：根据文字长度自动计算节点大小
5. **交互支持**：支持节点拖拽和位置保存

---

## 🎯 核心功能规格

### 1. 数据结构

```javascript
// 输入数据结构
const bubbleMapSpec = {
    topic: "中心主题文本",           // 中心节点文本
    attributes: [                    // 属性节点数组
        "属性1",
        "属性2",
        // 或支持对象格式: {text: "属性文本"}
    ],
    _customPositions: {              // 可选：自定义位置
        "attribute_0": {x: 100, y: 200},
        "attribute_1": {x: 300, y: 150}
    },
    _node_dimensions: {              // 可选：保存的节点尺寸
        "topic": {r: 50},
        "attribute-0": {r: 35}
    }
};
```

### 2. 布局算法

#### 2.1 圆形均匀分布算法

**核心公式：**
```javascript
// 1. 计算目标距离（从中心到节点的距离）
const targetDistance = topicR + uniformAttributeR + 50;

// 2. 计算每个节点的角度（从顶部开始，顺时针）
const angle = (index * 360 / nodeCount) - 90; // -90度从顶部开始

// 3. 计算目标位置
const targetX = centerX + targetDistance * Math.cos(angle * Math.PI / 180);
const targetY = centerY + targetDistance * Math.sin(angle * Math.PI / 180);
```

**关键参数：**
- `topicR`: 中心主题节点半径
- `uniformAttributeR`: 所有属性节点的统一半径
- `50`: 节点间距（像素）
- `-90`: 起始角度偏移（从顶部开始）

#### 2.2 力导向布局优化

使用 **D3.js Force Simulation** 进行位置优化：

```javascript
const simulation = d3.forceSimulation([centralNode, ...nodes])
    .force('charge', d3.forceManyBody().strength(-800))      // 排斥力
    .force('collide', d3.forceCollide().radius(d => d.radius + 5))  // 碰撞检测
    .force('center', d3.forceCenter(centerX, centerY))      // 中心吸引
    .force('target', function() {                            // 目标位置拉力
        nodes.forEach(node => {
            if (node.targetX !== undefined && node.fx === undefined) {
                const dx = node.targetX - node.x;
                const dy = node.targetY - node.y;
                node.vx += dx * 0.1;  // 拉力系数 0.1
                node.vy += dy * 0.1;
            }
        });
    })
    .stop();

// 运行模拟（300次迭代）
for (let i = 0; i < 300; ++i) simulation.tick();
```

**力参数说明：**
- `charge.strength(-800)`: 负值表示排斥，绝对值越大排斥越强
- `collide.radius(+5)`: 碰撞检测半径 = 节点半径 + 5px缓冲
- `target` 系数 `0.1`: 拉回目标位置的强度

---

## 📏 节点大小计算

### 3.1 文字尺寸测量

**核心函数：**
```javascript
function getTextRadius(text, fontSize, padding) {
    // 1. 创建临时SVG文本元素（隐藏）
    const container = getMeasurementContainer(); // 创建隐藏容器
    const textElement = container
        .append('svg')
        .append('text')
        .attr('font-size', fontSize)
        .text(text);
    
    // 2. 获取文本边界框
    const bbox = textElement.node().getBBox();
    
    // 3. 计算半径：对角线长度的一半 + 内边距
    const radius = Math.ceil(
        Math.sqrt(bbox.width * bbox.width + bbox.height * bbox.height) / 2 
        + (padding || 12)
    );
    
    // 4. 确保最小半径
    return Math.max(radius, 30); // 最小30px
    
    // 5. 清理临时元素
    textElement.remove();
}
```

**公式说明：**
- 使用勾股定理计算文本对角线长度
- 半径 = 对角线/2 + 内边距
- 确保最小半径为30px

### 3.2 统一半径策略

**所有属性节点使用统一半径：**

```javascript
// 1. 计算每个节点所需半径
const attributeRadii = spec.attributes.map((attr, idx) => {
    const textStr = typeof attr === 'object' ? attr.text : attr;
    return getTextRadius(textStr, fontAttribute, 10);
});

// 2. 使用最大半径作为统一半径
const uniformAttributeR = Math.max(...attributeRadii, 30);
```

**设计理由：**
- 视觉统一性：所有属性节点大小一致
- 布局稳定：避免因文字长度差异导致布局混乱
- 最小保证：至少30px半径

### 3.3 中心主题节点半径

```javascript
const topicR = getTextRadius(spec.topic, fontTopic, 20);
// 注意：主题节点使用更大的内边距(20px)
```

### 3.4 文字与气泡大小自适应机制

#### 3.4.1 自适应计算流程

气泡图实现了**完全自适应的文字-气泡大小匹配机制**：

**步骤1：文字尺寸测量**
```javascript
// 创建临时SVG文本元素进行精确测量
function getTextRadius(text, fontSize, padding) {
    const container = getMeasurementContainer(); // 隐藏的测量容器
    const textElement = container
        .append('svg')
        .append('text')
        .attr('font-size', fontSize)
        .text(text);
    
    // 获取文本边界框（Bounding Box）
    const bbox = textElement.node().getBBox();
    
    // 计算半径：对角线长度的一半 + 内边距
    const radius = Math.ceil(
        Math.sqrt(bbox.width * bbox.width + bbox.height * bbox.height) / 2 
        + padding
    );
    
    // 确保最小半径
    return Math.max(radius, 30);
    
    // 清理临时元素
    textElement.remove();
}
```

**步骤2：统一半径策略**
```javascript
// 计算每个节点所需半径
const attributeRadii = spec.attributes.map((attr, idx) => {
    const textStr = typeof attr === 'object' ? attr.text : attr;
    return getTextRadius(textStr, theme.fontAttribute, 10);
});

// 使用最大半径作为统一半径（保证所有文字都能完整显示）
const uniformAttributeR = Math.max(...attributeRadii, 30);
```

**步骤3：布局参数动态调整**
```javascript
// 目标距离会根据统一半径自动调整
const targetDistance = topicR + uniformAttributeR + 50;

// 边界也会自动扩展
const innerRadius = topicR + uniformAttributeR + 20;
const outerRadius = targetDistance + uniformAttributeR + margin;
```

#### 3.4.2 自适应优势

✅ **自动适应文字长度**：无论文字长短，气泡大小自动调整  
✅ **视觉统一性**：所有属性节点使用统一半径，保持视觉平衡  
✅ **防止文字溢出**：确保最长文字也能完整显示  
✅ **最小尺寸保证**：至少30px半径，保证可读性

---

## 🔄 修改气泡文字时的处理逻辑

### 4.1 文字修改流程概述

当用户修改气泡文字时，系统会执行以下完整流程：

#### 步骤1：文字更新

```javascript
// 用户编辑文字 -> 触发更新
function updateNodeText(nodeId, shapeNode, textNode, newText) {
    // 1. 获取操作管理器
    const operations = getOperationsForDiagramType('bubble_map');
    
    // 2. 调用更新方法
    const updatedSpec = operations.updateNode(currentSpec, nodeId, { 
        text: newText 
    });
    
    // 3. 更新当前规格
    currentSpec = updatedSpec;
}
```

#### 步骤2：尺寸保存逻辑（空节点处理）

```javascript
// 在 updateNode 方法中处理尺寸保存
function updateNode(spec, nodeId, updates) {
    const shapeElement = d3.select(`[data-node-id="${nodeId}"]`);
    const nodeType = shapeElement.attr('data-node-type');
    
    if (nodeType === 'attribute') {
        const arrayIndex = parseInt(shapeElement.attr('data-array-index'));
        
        if (updates.text !== undefined) {
            // 获取当前保存的尺寸（如果存在）
            const preservedWidth = shapeElement.attr('data-preserved-width');
            const preservedHeight = shapeElement.attr('data-preserved-height');
            const preservedRadius = shapeElement.attr('data-preserved-radius');
            
            // 关键逻辑：如果新文字为空，保存当前尺寸
            if ((preservedWidth && preservedHeight || preservedRadius) && updates.text === '') {
                const nodeKey = `attribute-${arrayIndex}`;
                
                // 初始化尺寸存储
                if (!spec._node_dimensions) {
                    spec._node_dimensions = {};
                }
                
                spec._node_dimensions[nodeKey] = {};
                
                // 保存宽度和高度（如果有）
                if (preservedWidth && preservedHeight) {
                    spec._node_dimensions[nodeKey].w = parseFloat(preservedWidth);
                    spec._node_dimensions[nodeKey].h = parseFloat(preservedHeight);
                }
                
                // 保存半径（如果有）
                if (preservedRadius) {
                    spec._node_dimensions[nodeKey].r = parseFloat(preservedRadius);
                }
            }
            
            // 更新文字内容
            spec.attributes[arrayIndex] = updates.text;
        }
    }
    
    // 发出更新事件
    eventBus.emit('diagram:node_updated', {
        diagramType: 'bubble_map',
        nodeId,
        nodeType,
        updates,
        spec
    });
    
    return spec;
}
```

#### 步骤3：触发重新渲染

```javascript
// 事件监听器响应更新事件
eventBus.on('diagram:node_updated', (data) => {
    if (data.spec) {
        currentSpec = data.spec;
        // 触发完整重新渲染
        renderDiagram();
    }
});
```

#### 步骤4：重新计算尺寸

```javascript
// 在 renderBubbleMap 中重新计算尺寸
function renderBubbleMap(spec, theme, dimensions) {
    const nodeDimensions = spec._node_dimensions || {};
    
    // 计算属性节点半径
    const attributeRadii = spec.attributes.map((attr, idx) => {
        const textStr = typeof attr === 'object' ? attr.text : attr;
        const nodeKey = `attribute-${idx}`;
        const preservedDims = nodeDimensions[nodeKey];
        
        // 优先级1：如果有保存的尺寸（空节点），使用保存的尺寸
        if (preservedDims && preservedDims.r) {
            return preservedDims.r;
        }
        
        // 优先级2：如果有保存的宽高，转换为半径
        if (preservedDims && preservedDims.w && preservedDims.h) {
            return Math.max(preservedDims.w, preservedDims.h) / 2;
        }
        
        // 优先级3：根据新文字重新计算半径
        return getTextRadius(textStr, theme.fontAttribute, 10);
    });
    
    // 统一半径
    const uniformAttributeR = Math.max(...attributeRadii, 30);
    
    // 重新计算布局参数
    const targetDistance = topicR + uniformAttributeR + 50;
    // ... 继续渲染流程
}
```

### 4.2 尺寸计算优先级

重新渲染时，尺寸计算的优先级顺序：

1. **保存的半径** (`_node_dimensions[nodeKey].r`)
   - 适用于：空节点（用户清空文字后）
   - 目的：保持空节点的视觉大小

2. **保存的宽高** (`_node_dimensions[nodeKey].w/h`)
   - 适用于：从其他图表类型转换而来
   - 转换：`radius = max(w, h) / 2`

3. **根据文字重新计算** (`getTextRadius(text)`)
   - 适用于：正常文字修改
   - 方法：测量文字尺寸 + 内边距

### 4.3 空节点尺寸保存机制

**设计目的：**
- 当用户清空节点文字时，保持节点的视觉大小
- 避免空节点突然变小，影响布局稳定性

**实现逻辑：**
```javascript
// 在更新节点时检测空节点
if (updates.text === '') {
    // 保存当前尺寸
    const currentRadius = shapeElement.attr('r');
    const currentWidth = shapeElement.attr('width');
    const currentHeight = shapeElement.attr('height');
    
    // 存储到 spec._node_dimensions
    spec._node_dimensions[`attribute-${index}`] = {
        r: parseFloat(currentRadius),
        w: parseFloat(currentWidth),
        h: parseFloat(currentHeight)
    };
}

// 在渲染时使用保存的尺寸
if (text === '' && preservedDims && preservedDims.r) {
    radius = preservedDims.r; // 使用保存的半径
} else {
    radius = getTextRadius(text, fontSize, padding); // 重新计算
}
```

### 4.4 文字修改后的布局调整

**自动布局调整：**

1. **统一半径重新计算**
   ```javascript
   // 修改文字后，重新计算所有节点的所需半径
   const newRadii = spec.attributes.map(attr => 
       getTextRadius(attr, fontSize, padding)
   );
   const newUniformR = Math.max(...newRadii, 30);
   
   // 如果统一半径发生变化，重新计算布局
   if (newUniformR !== oldUniformR) {
       const newTargetDistance = topicR + newUniformR + 50;
       // 重新计算所有节点位置
   }
   ```

2. **力导向模拟优化**
   ```javascript
   // 如果统一半径变化较大，重新运行力导向模拟
   if (Math.abs(newUniformR - oldUniformR) > 5) {
       // 重新创建力导向模拟
       const simulation = d3.forceSimulation(nodes)
           .force('charge', d3.forceManyBody().strength(-800))
           .force('collide', d3.forceCollide().radius(d => d.radius + 5))
           // ... 其他力
       
       // 运行模拟优化位置
       for (let i = 0; i < 300; ++i) simulation.tick();
   }
   ```

3. **保持自定义位置**
   ```javascript
   // 如果节点有自定义位置，保持位置不变
   if (customPositions[nodeId]) {
       // 使用自定义位置，不重新计算
       node.x = customPositions[nodeId].x;
       node.y = customPositions[nodeId].y;
   } else {
       // 重新计算均匀分布位置
       // ... 圆形分布算法
   }
   ```

### 4.5 完整文字修改流程图

```
用户修改文字
    ↓
updateNodeText(nodeId, newText)
    ↓
operations.updateNode(spec, nodeId, {text: newText})
    ↓
检查是否为空节点
    ├─ 是 → 保存当前尺寸到 _node_dimensions
    └─ 否 → 更新文字内容
    ↓
更新 spec.attributes[index] = newText
    ↓
发出 diagram:node_updated 事件
    ↓
事件监听器触发 renderDiagram()
    ↓
renderBubbleMap(spec)
    ↓
重新计算尺寸（优先级：保存尺寸 > 重新计算）
    ├─ 检查 _node_dimensions 中是否有保存的尺寸
    ├─ 有 → 使用保存的尺寸
    └─ 无 → 使用 getTextRadius() 重新计算
    ↓
重新计算统一半径 uniformAttributeR
    ↓
检查统一半径是否变化
    ├─ 变化 → 重新计算布局参数（targetDistance等）
    └─ 未变化 → 保持原有布局
    ↓
重新渲染SVG（更新节点大小和位置）
```

### 4.6 关键代码示例

**完整的文字修改处理函数：**

```javascript
class BubbleMapOperations {
    updateNode(spec, nodeId, updates) {
        const shapeElement = d3.select(`[data-node-id="${nodeId}"]`);
        const nodeType = shapeElement.attr('data-node-type');
        
        // 初始化尺寸存储
        if (!spec._node_dimensions) {
            spec._node_dimensions = {};
        }
        
        if (nodeType === 'attribute') {
            const arrayIndex = parseInt(shapeElement.attr('data-array-index'));
            
            if (updates.text !== undefined) {
                // 获取当前保存的尺寸
                const preservedWidth = shapeElement.attr('data-preserved-width');
                const preservedHeight = shapeElement.attr('data-preserved-height');
                const preservedRadius = shapeElement.attr('data-preserved-radius');
                
                // 空节点：保存尺寸
                if ((preservedWidth && preservedHeight || preservedRadius) && updates.text === '') {
                    const nodeKey = `attribute-${arrayIndex}`;
                    spec._node_dimensions[nodeKey] = {};
                    
                    if (preservedWidth && preservedHeight) {
                        spec._node_dimensions[nodeKey].w = parseFloat(preservedWidth);
                        spec._node_dimensions[nodeKey].h = parseFloat(preservedHeight);
                    }
                    if (preservedRadius) {
                        spec._node_dimensions[nodeKey].r = parseFloat(preservedRadius);
                    }
                }
                
                // 更新文字
                spec.attributes[arrayIndex] = updates.text;
            }
        } else if (nodeType === 'topic') {
            // 中心主题节点类似处理
            if (updates.text !== undefined) {
                // ... 类似的尺寸保存逻辑
                spec.topic = updates.text;
            }
        }
        
        // 发出更新事件（触发重新渲染）
        eventBus.emit('diagram:node_updated', {
            diagramType: 'bubble_map',
            nodeId,
            nodeType,
            updates,
            spec
        });
        
        return spec;
    }
}
```

**渲染时的尺寸计算：**

```javascript
function renderBubbleMap(spec, theme, dimensions) {
    const nodeDimensions = spec._node_dimensions || {};
    
    // 计算每个节点的半径
    const attributeRadii = spec.attributes.map((attr, idx) => {
        const textStr = typeof attr === 'object' ? attr.text : attr;
        const nodeKey = `attribute-${idx}`;
        const preservedDims = nodeDimensions[nodeKey];
        
        // 优先级1：保存的半径（空节点）
        if (preservedDims && preservedDims.r) {
            return preservedDims.r;
        }
        
        // 优先级2：保存的宽高（转换）
        if (preservedDims && preservedDims.w && preservedDims.h) {
            return Math.max(preservedDims.w, preservedDims.h) / 2;
        }
        
        // 优先级3：根据文字重新计算
        return getTextRadius(textStr, theme.fontAttribute, 10);
    });
    
    // 统一半径
    const uniformAttributeR = Math.max(...attributeRadii, 30);
    
    // 继续渲染流程...
}
```

---

## 🎨 位置确定逻辑

### 5.1 初始位置计算

```javascript
// 中心位置
const centerX = canvasWidth / 2;
const centerY = canvasHeight / 2;

// 目标距离
const targetDistance = topicR + uniformAttributeR + 50;

// 每个节点的初始位置
nodes = spec.attributes.map((attr, i) => {
    const angle = (i * 360 / nodeCount) - 90;
    const targetX = centerX + targetDistance * Math.cos(angle * Math.PI / 180);
    const targetY = centerY + targetDistance * Math.sin(angle * Math.PI / 180);
    
    return {
        id: i,
        nodeId: `attribute_${i}`,
        text: typeof attr === 'object' ? attr.text : attr,
        radius: uniformAttributeR,
        targetX: targetX,  // 目标位置
        targetY: targetY,
        x: targetX,        // 当前位置（初始等于目标位置）
        y: targetY
    };
});
```

### 5.2 边界约束

```javascript
// 内半径：防止节点与中心主题重叠
const innerRadius = topicR + uniformAttributeR + 20;

// 外半径：最大边界
const margin = uniformAttributeR * 0.2; // 20%边距
const outerRadius = targetDistance + uniformAttributeR + margin;

// 保存边界信息（用于拖拽约束）
const boundaries = {
    centerX: centerX,
    centerY: centerY,
    innerRadius: innerRadius,
    outerRadius: outerRadius
};
```

### 5.3 自定义位置处理

```javascript
// 检查是否有自定义位置
const customPositions = spec._customPositions || {};
const hasCustomPositions = Object.keys(customPositions).length > 0;

// 检查是否有新节点（没有自定义位置）
let nodesWithCustomPositions = 0;
for (let i = 0; i < nodeCount; i++) {
    const nodeId = `attribute_${i}`;
    if (customPositions[nodeId]) {
        nodesWithCustomPositions++;
    }
}

// 如果有新节点，重新均匀分布所有节点
const shouldRecalculateEvenly = hasCustomPositions && 
                                 nodesWithCustomPositions < nodeCount;

if (shouldRecalculateEvenly) {
    // 清除所有自定义位置，重新计算均匀分布
    // 运行力导向模拟优化位置
}
```

---

## ➕ 增加节点的处理逻辑

### 6.1 检测新节点

```javascript
function detectNewNodes(spec) {
    const nodeCount = spec.attributes.length;
    const customPositions = spec._customPositions || {};
    
    // 统计有自定义位置的节点数
    let nodesWithPositions = 0;
    for (let i = 0; i < nodeCount; i++) {
        const nodeId = `attribute_${i}`;
        if (customPositions[nodeId]) {
            nodesWithPositions++;
        }
    }
    
    // 如果节点数 > 有位置的节点数，说明有新节点
    return {
        hasNewNodes: nodesWithPositions < nodeCount,
        shouldRecalculate: nodesWithPositions < nodeCount
    };
}
```

### 6.2 重新均匀分布

```javascript
if (shouldRecalculateEvenly) {
    // 1. 清除所有旧的自定义位置
    Object.keys(customPositions).forEach(key => {
        if (key.startsWith('attribute_')) {
            delete customPositions[key];
        }
    });
    
    // 2. 重新计算所有节点的均匀位置
    const nodeCount = spec.attributes.length;
    const angleStep = 360 / nodeCount;
    
    spec.attributes.forEach((attr, i) => {
        const angle = (i * angleStep - 90) * Math.PI / 180;
        const x = centerX + targetDistance * Math.cos(angle);
        const y = centerY + targetDistance * Math.sin(angle);
        
        customPositions[`attribute_${i}`] = {x, y};
    });
    
    // 3. 运行力导向模拟优化位置
    for (let i = 0; i < 300; ++i) simulation.tick();
    
    // 4. 保存优化后的位置
    nodes.forEach(node => {
        customPositions[node.nodeId] = {x: node.x, y: node.y};
    });
}
```

---

## 🔢 节点数量过多时的处理

### 7.1 自适应机制

**无硬性上限，通过以下机制自适应：**

1. **力导向模拟自动调整**
   - 排斥力自动推开过近的节点
   - 碰撞检测防止重叠

2. **动态目标距离**
   ```javascript
   // 如果节点过多，可以动态调整目标距离
   const baseDistance = topicR + uniformAttributeR + 50;
   const nodeCount = spec.attributes.length;
   
   // 节点越多，距离越远（可选）
   const targetDistance = baseDistance + Math.min(nodeCount * 2, 100);
   ```

3. **边界约束**
   ```javascript
   // 外半径自动扩展
   const outerRadius = targetDistance + uniformAttributeR + margin;
   ```

### 7.2 性能优化建议

```javascript
// 1. 限制模拟迭代次数（节点多时减少迭代）
const iterations = nodeCount > 20 ? 200 : 300;

// 2. 使用Web Worker进行复杂计算（可选）
// 3. 虚拟化渲染（只渲染可见节点，可选）
```

---

## 🎯 完整实现流程

### 8.1 步骤1：初始化

```javascript
function renderBubbleMap(spec, theme, dimensions) {
    // 1. 验证输入
    if (!spec || !spec.topic || !Array.isArray(spec.attributes)) {
        return; // 错误处理
    }
    
    // 2. 设置画布尺寸
    const baseWidth = dimensions?.width || 700;
    const baseHeight = dimensions?.height || 500;
    const centerX = baseWidth / 2;
    const centerY = baseHeight / 2;
}
```

### 8.2 步骤2：计算节点大小

```javascript
    // 1. 计算中心主题半径
    const topicR = getTextRadius(spec.topic, theme.fontTopic, 20);
    
    // 2. 计算所有属性节点所需半径
    const attributeRadii = spec.attributes.map(attr => {
        const text = typeof attr === 'object' ? attr.text : attr;
        return getTextRadius(text, theme.fontAttribute, 10);
    });
    
    // 3. 统一半径
    const uniformAttributeR = Math.max(...attributeRadii, 30);
```

### 8.3 步骤3：计算布局参数

```javascript
    // 1. 目标距离
    const targetDistance = topicR + uniformAttributeR + 50;
    
    // 2. 边界
    const innerRadius = topicR + uniformAttributeR + 20;
    const margin = uniformAttributeR * 0.2;
    const outerRadius = targetDistance + uniformAttributeR + margin;
    
    // 3. 检测新节点
    const shouldRecalculate = detectNewNodes(spec);
```

### 8.4 步骤4：创建节点数据

```javascript
    const nodes = spec.attributes.map((attr, i) => {
        const nodeId = `attribute_${i}`;
        const customPos = spec._customPositions?.[nodeId];
        
        let targetX, targetY;
        if (customPos && !shouldRecalculate) {
            // 使用自定义位置
            targetX = customPos.x;
            targetY = customPos.y;
        } else {
            // 计算均匀分布位置
            const angle = (i * 360 / spec.attributes.length - 90) * Math.PI / 180;
            targetX = centerX + targetDistance * Math.cos(angle);
            targetY = centerY + targetDistance * Math.sin(angle);
        }
        
        return {
            id: i,
            nodeId: nodeId,
            text: typeof attr === 'object' ? attr.text : attr,
            radius: uniformAttributeR,
            targetX: targetX,
            targetY: targetY,
            x: targetX,
            y: targetY
        };
    });
    
    // 中心节点（固定位置）
    const centralNode = {
        id: 'central',
        text: spec.topic,
        radius: topicR,
        x: centerX,
        y: centerY,
        fx: centerX,  // 固定X
        fy: centerY   // 固定Y
    };
```

### 8.5 步骤5：力导向模拟

```javascript
    const simulation = d3.forceSimulation([centralNode, ...nodes])
        .force('charge', d3.forceManyBody().strength(-800))
        .force('collide', d3.forceCollide().radius(d => d.radius + 5))
        .force('center', d3.forceCenter(centerX, centerY))
        .force('target', function() {
            nodes.forEach(node => {
                if (node.targetX !== undefined && node.fx === undefined) {
                    const dx = node.targetX - node.x;
                    const dy = node.targetY - node.y;
                    node.vx += dx * 0.1;
                    node.vy += dy * 0.1;
                }
            });
        })
        .stop();
    
    // 运行模拟
    if (shouldRecalculate || !hasCustomPositions) {
        for (let i = 0; i < 300; ++i) simulation.tick();
    }
```

### 8.6 步骤6：渲染SVG

```javascript
    // 1. 创建SVG
    const svg = d3.select('#container')
        .append('svg')
        .attr('width', width)
        .attr('height', height)
        .attr('viewBox', `${minX} ${minY} ${width} ${height}`);
    
    // 2. 绘制连接线
    nodes.forEach(node => {
        svg.append('line')
            .attr('x1', centerX)
            .attr('y1', centerY)
            .attr('x2', node.x)
            .attr('y2', node.y)
            .attr('stroke', '#888')
            .attr('stroke-width', 2);
    });
    
    // 3. 绘制中心节点
    svg.append('circle')
        .attr('cx', centerX)
        .attr('cy', centerY)
        .attr('r', topicR)
        .attr('fill', theme.topicFill);
    
    // 4. 绘制属性节点
    nodes.forEach(node => {
        svg.append('circle')
            .attr('cx', node.x)
            .attr('cy', node.y)
            .attr('r', node.radius)
            .attr('fill', theme.attributeFill);
        
        // 添加文本
        svg.append('text')
            .attr('x', node.x)
            .attr('y', node.y)
            .attr('text-anchor', 'middle')
            .attr('dominant-baseline', 'middle')
            .text(node.text);
    });
```

---

## 🔧 技术栈建议

### 必需依赖

- **D3.js v7+**: 用于力导向布局 (`d3-force`)
- **SVG**: 用于渲染图形

### 可选依赖

- **React/Vue/Angular**: 如果需要在框架中使用
- **TypeScript**: 类型安全（推荐）

---

## 📝 关键参数总结

| 参数 | 值 | 说明 |
|------|-----|------|
| `charge.strength` | -800 | 排斥力强度 |
| `collide.radius` | `radius + 5` | 碰撞检测缓冲 |
| `target` 系数 | 0.1 | 目标位置拉力 |
| 模拟迭代次数 | 300 | 力导向迭代次数 |
| 节点间距 | 50px | 基础间距 |
| 内边距（主题） | 20px | 主题节点内边距 |
| 内边距（属性） | 10px | 属性节点内边距 |
| 最小半径 | 30px | 节点最小尺寸 |
| 边界边距 | 20% | 外边界边距 |

---

## 🎨 样式配置

```javascript
const defaultTheme = {
    fontTopic: 20,           // 主题字体大小
    fontAttribute: 14,      // 属性字体大小
    topicFill: '#4A90E2',   // 主题填充色
    topicStroke: '#2E5C8A', // 主题边框色
    attributeFill: '#F5A623', // 属性填充色
    attributeStroke: '#D68910', // 属性边框色
    lineColor: '#888',      // 连接线颜色
    lineWidth: 2,           // 连接线宽度
    background: '#f5f5f5'  // 背景色
};
```

---

## ✅ 实现检查清单

- [ ] 文字尺寸测量函数 (`getTextRadius`)
- [ ] 统一半径计算逻辑
- [ ] 圆形均匀分布算法
- [ ] D3力导向模拟设置
- [ ] 新节点检测逻辑
- [ ] 自定义位置处理
- [ ] 边界约束实现
- [ ] SVG渲染（节点、连线、文本）
- [ ] 拖拽交互支持（可选）
- [ ] 位置保存/恢复（可选）

---

## 🚀 快速开始示例

```javascript
// 1. 准备数据
const spec = {
    topic: "动物",
    attributes: ["有毛", "会叫", "四条腿", "有尾巴"]
};

// 2. 渲染
renderBubbleMap(spec, defaultTheme, {
    width: 800,
    height: 600
});

// 3. 添加节点后自动重新布局
spec.attributes.push("会游泳");
renderBubbleMap(spec, defaultTheme, dimensions); // 自动检测新节点并重新分布
```

---

## 📚 参考实现

基于 **MindGraph** 项目的气泡图实现：
- 文件：`static/js/renderers/bubble-map-renderer.js`
- 工具函数：`static/js/renderers/shared-utilities.js`

---

**提示词使用说明：**

将此文档提供给AI助手（如Cursor、ChatGPT等），可以完整复现气泡图功能。建议按步骤实现，先完成核心布局算法，再添加交互功能。
