# MindGraph 气泡图文字自适应实现说明

> 本文档详细说明 MindGraph 项目中气泡图文字与圆圈大小自适应的实现机制

---

## 📋 概述

MindGraph 项目中的气泡图实现了**完全自适应的文字-圆圈大小匹配机制**，核心原理是：

1. **精确测量文字尺寸**：使用 SVG 的 `getBBox()` 方法获取文字的实际渲染尺寸
2. **计算所需半径**：根据文字的对角线长度计算圆圈所需的最小半径
3. **统一半径策略**：所有属性节点使用统一半径（取最大所需半径），保证视觉一致性

---

## 🔧 核心实现

### 1. 文字尺寸测量函数

**文件位置：** `static/js/renderers/shared-utilities.js`

**函数名：** `getTextRadius(text, fontSize, padding)`

**完整代码：**

```javascript
function getTextRadius(text, fontSize, padding) {
    let textElement = null;
    try {
        // 1. 获取或创建隐藏的测量容器
        const container = getMeasurementContainer();
        
        // 2. 创建临时 SVG 文本元素
        textElement = container
            .append('svg')
            .append('text')
            .attr('font-size', fontSize)
            .text(text);
        
        // 3. 获取文本边界框（Bounding Box）
        const bbox = textElement.node().getBBox();
        
        // 4. 计算半径：对角线长度的一半 + 内边距
        // 公式：radius = sqrt(width² + height²) / 2 + padding
        const radius = Math.ceil(
            Math.sqrt(bbox.width * bbox.width + bbox.height * bbox.height) / 2 
            + (padding || 12)
        );
        
        // 5. 确保最小半径（保证可读性）
        return Math.max(radius, 30); // Minimum radius: 30px
        
    } catch (error) {
        logger.error('SharedUtilities', 'Error calculating text radius', error);
        return 30; // Default fallback
    } finally {
        // 6. 清理临时元素（防止内存泄漏）
        if (textElement) {
            textElement.remove();
        }
    }
}
```

**关键点说明：**

1. **测量容器管理**
   ```javascript
   function getMeasurementContainer() {
       if (!measurementContainer) {
           // 创建隐藏的测量容器
           measurementContainer = d3.select('body')
               .append('div')
               .attr('id', 'measurement-container')
               .style('position', 'absolute')
               .style('visibility', 'hidden')  // 隐藏但存在于DOM中
               .style('pointer-events', 'none'); // 不响应鼠标事件
       }
       return measurementContainer;
   }
   ```

2. **SVG getBBox() 方法**
   - `getBBox()` 返回一个 `SVGRect` 对象，包含：
     - `width`: 文字宽度
     - `height`: 文字高度
     - `x`, `y`: 文字位置
   - 这是**最精确**的文字尺寸测量方法

3. **半径计算公式**
   ```
   半径 = sqrt(宽度² + 高度²) / 2 + 内边距
   ```
   - 使用勾股定理计算文字的对角线长度
   - 除以2得到半径
   - 加上内边距（padding）确保文字不会紧贴圆圈边缘

4. **最小半径限制**
   - 无论文字多短，最小半径都是 30px
   - 保证圆圈的可读性和美观性

---

### 2. 统一半径计算

**文件位置：** `static/js/renderers/bubble-map-renderer.js`

**实现位置：** `renderBubbleMap()` 函数中

**完整代码：**

```javascript
// 计算统一半径 for all attribute nodes
// Handle both string and object attributes (t can be "text" or {text: "text"})
// Use preserved dimensions if available, otherwise calculate
const attributeRadii = spec.attributes.map((t, idx) => {
    // 1. 提取文字内容（支持字符串和对象两种格式）
    const textStr = typeof t === 'object' ? (t.text || '') : (t || '');
    
    // 2. 检查是否有保存的尺寸（用于空节点）
    const nodeKey = `attribute-${idx}`;
    const preservedDims = nodeDimensions[nodeKey];
    
    // 3. 优先级1：如果有保存的半径，使用保存的半径
    if (preservedDims && preservedDims.r) {
        return preservedDims.r;
    }
    
    // 4. 优先级2：如果有保存的宽高，转换为半径
    if (preservedDims && preservedDims.w && preservedDims.h) {
        return Math.max(preservedDims.w, preservedDims.h) / 2;
    }
    
    // 5. 优先级3：根据文字重新计算半径
    return getTextRadius(textStr, THEME.fontAttribute, 10);
});

// 6. 使用最大半径作为统一半径
const uniformAttributeR = Math.max(...attributeRadii, 30);
```

**设计逻辑：**

1. **遍历所有属性节点**
   - 对每个节点计算其所需半径

2. **尺寸优先级**
   - **优先级1**：保存的半径（`_node_dimensions[nodeKey].r`）
     - 适用于：空节点（用户清空文字后）
   - **优先级2**：保存的宽高（转换为半径）
     - 适用于：从其他图表类型转换而来
   - **优先级3**：根据文字重新计算
     - 适用于：正常文字修改

3. **统一半径策略**
   ```javascript
   uniformAttributeR = Math.max(...所有节点所需半径, 30)
   ```
   - 使用**最大**所需半径作为统一半径
   - 确保所有文字都能完整显示
   - 保证视觉统一性

---

### 3. 中心主题节点半径计算

**实现代码：**

```javascript
// Topic radius - use preserved if available
let topicR;
if (nodeDimensions.topic && nodeDimensions.topic.r) {
    // 如果有保存的半径，使用保存的半径
    topicR = nodeDimensions.topic.r;
} else {
    // 否则根据文字计算
    topicR = getTextRadius(spec.topic, THEME.fontTopic, 20);
}
```

**特点：**
- 主题节点使用更大的内边距（20px vs 10px）
- 主题节点使用更大的字体（通常 20px vs 14px）
- 同样支持保存尺寸机制（空节点时）

---

## 🔄 文字修改时的自适应流程

### 完整流程

```
用户修改文字
    ↓
updateNodeText(nodeId, newText)
    ↓
operations.updateNode(spec, nodeId, {text: newText})
    ├─ 检查是否为空节点
    │   ├─ 是 → 保存当前尺寸到 _node_dimensions
    │   └─ 否 → 更新文字内容
    ↓
更新 spec.attributes[index] = newText
    ↓
发出 diagram:node_updated 事件
    ↓
事件监听器触发 renderDiagram()
    ↓
renderBubbleMap(spec)
    ↓
重新计算尺寸
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

### 关键代码位置

**1. 文字更新处理**

**文件：** `static/js/managers/editor/diagram-types/bubble-map-operations.js`

```javascript
updateNode(spec, nodeId, updates) {
    // ... 获取节点信息
    
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
                if (!spec._node_dimensions) {
                    spec._node_dimensions = {};
                }
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
    }
    
    // 发出更新事件
    this.eventBus.emit('diagram:node_updated', {
        diagramType: 'bubble_map',
        nodeId,
        nodeType,
        updates,
        spec
    });
    
    return spec;
}
```

**2. 重新渲染触发**

**文件：** `static/js/editor/interactive-editor.js`

```javascript
// 监听节点更新事件
this.eventBusListeners.nodeUpdated = (data) => {
    if (data.spec) {
        this.currentSpec = data.spec;
        // 触发重新渲染
        this.renderDiagram();
    }
};
this.eventBus.onWithOwner('diagram:node_updated', this.eventBusListeners.nodeUpdated, this.ownerId);
```

**3. 重新计算尺寸**

**文件：** `static/js/renderers/bubble-map-renderer.js`

```javascript
function renderBubbleMap(spec, theme, dimensions) {
    // ... 其他初始化代码
    
    // 检查保存的尺寸
    const nodeDimensions = spec._node_dimensions || {};
    
    // 重新计算每个节点的半径
    const attributeRadii = spec.attributes.map((t, idx) => {
        const textStr = typeof t === 'object' ? (t.text || '') : (t || '');
        const nodeKey = `attribute-${idx}`;
        const preservedDims = nodeDimensions[nodeKey];
        
        // 优先级：保存的半径 > 保存的宽高 > 重新计算
        if (preservedDims && preservedDims.r) {
            return preservedDims.r;
        } else if (preservedDims && preservedDims.w && preservedDims.h) {
            return Math.max(preservedDims.w, preservedDims.h) / 2;
        } else {
            return getTextRadius(textStr, THEME.fontAttribute, 10);
        }
    });
    
    // 统一半径
    const uniformAttributeR = Math.max(...attributeRadii, 30);
    
    // 继续渲染流程...
}
```

---

## 📊 关键参数

| 参数 | 值 | 说明 |
|------|-----|------|
| **主题节点** | | |
| 字体大小 | `THEME.fontTopic` (通常20px) | 中心主题节点字体 |
| 内边距 | 20px | 主题节点内边距 |
| **属性节点** | | |
| 字体大小 | `THEME.fontAttribute` (通常14px) | 属性节点字体 |
| 内边距 | 10px | 属性节点内边距 |
| **统一半径** | | |
| 计算方式 | `Math.max(...所有节点所需半径, 30)` | 取最大值 |
| 最小半径 | 30px | 保证可读性 |

---

## 🎯 设计优势

### 1. 精确测量
- ✅ 使用 SVG `getBBox()` 获取**实际渲染尺寸**
- ✅ 考虑字体、字号、文字内容的所有因素
- ✅ 比估算方法（如字符数 × 字符宽度）更准确

### 2. 视觉统一性
- ✅ 所有属性节点使用**统一半径**
- ✅ 避免因文字长度差异导致的大小不一致
- ✅ 保持整体美观

### 3. 内容完整性
- ✅ 使用最大所需半径确保**所有文字都能完整显示**
- ✅ 不会出现文字被截断的情况

### 4. 布局稳定性
- ✅ 统一大小避免布局混乱
- ✅ 文字修改时自动重新计算
- ✅ 空节点时保存尺寸，保持布局稳定

### 5. 内存安全
- ✅ 及时清理临时测量元素
- ✅ 使用单例模式的测量容器
- ✅ 防止内存泄漏

---

## 💡 实现细节

### 1. 测量容器的单例模式

```javascript
let measurementContainer = null;

function getMeasurementContainer() {
    if (!measurementContainer) {
        // 只在第一次调用时创建
        measurementContainer = d3.select('body')
            .append('div')
            .attr('id', 'measurement-container')
            .style('position', 'absolute')
            .style('visibility', 'hidden')
            .style('pointer-events', 'none');
    }
    return measurementContainer;
}
```

**优势：**
- 避免重复创建DOM元素
- 提高性能
- 统一管理

### 2. 错误处理

```javascript
try {
    // 测量逻辑
} catch (error) {
    logger.error('SharedUtilities', 'Error calculating text radius', error);
    return 30; // 返回默认值
} finally {
    // 确保清理
    if (textElement) {
        textElement.remove();
    }
}
```

**保障：**
- 即使出错也能返回合理值
- 确保临时元素被清理
- 记录错误日志便于调试

### 3. 支持多种数据格式

```javascript
// 支持字符串格式
const textStr1 = typeof attr === 'string' ? attr : '';

// 支持对象格式
const textStr2 = typeof attr === 'object' ? (attr.text || '') : attr;
```

**灵活性：**
- 兼容不同的数据结构
- 向后兼容

---

## 🔍 调试技巧

### 查看测量结果

```javascript
// 在浏览器控制台中
const radius = getTextRadius("测试文字", 14, 10);
console.log('计算得到的半径:', radius);
```

### 查看统一半径计算

```javascript
// 在 renderBubbleMap 函数中添加日志
console.log('[BubbleMap] 各节点所需半径:', attributeRadii);
console.log('[BubbleMap] 统一半径:', uniformAttributeR);
```

### 检查保存的尺寸

```javascript
// 查看 spec._node_dimensions
console.log('保存的节点尺寸:', spec._node_dimensions);
```

---

## 📝 总结

MindGraph 项目中的气泡图文字自适应实现：

1. **核心函数**：`getTextRadius()` - 精确测量文字尺寸并计算所需半径
2. **统一策略**：所有属性节点使用统一半径（取最大值）
3. **智能更新**：文字修改时自动重新计算，空节点时保存尺寸
4. **内存安全**：使用单例容器，及时清理临时元素

这个实现方案**精确、高效、稳定**，能够完美处理各种文字长度和内容变化。
