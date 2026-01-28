# 气泡图尺寸计算详解

> 详细说明 MindGraph 项目中气泡图如何计算节点尺寸（圆圈半径）和布局参数

---

## 📐 尺寸计算流程总览

```
输入：文字内容 + 字体大小 + 内边距
    ↓
步骤1：测量文字实际尺寸（getBBox）
    ↓
步骤2：计算所需半径（勾股定理）
    ↓
步骤3：计算统一半径（取最大值）
    ↓
步骤4：计算布局参数（目标距离、边界等）
```

---

## 🔍 步骤1：文字尺寸测量

### 1.1 创建测量容器

**文件：** `static/js/renderers/shared-utilities.js`

```javascript
let measurementContainer = null;

function getMeasurementContainer() {
    if (!measurementContainer) {
        const body = d3.select('body');
        if (body.empty()) {
            // 如果body不存在，在document中创建
            measurementContainer = d3.select(document.documentElement)
                .append('div')
                .attr('id', 'measurement-container')
                .style('position', 'absolute')
                .style('visibility', 'hidden')      // 隐藏但存在于DOM
                .style('pointer-events', 'none');   // 不响应鼠标事件
        } else {
            measurementContainer = body
                .append('div')
                .attr('id', 'measurement-container')
                .style('position', 'absolute')
                .style('visibility', 'hidden')
                .style('pointer-events', 'none');
        }
    }
    return measurementContainer;
}
```

**关键点：**
- ✅ **单例模式**：只创建一次，重复使用
- ✅ **隐藏容器**：`visibility: hidden` 但仍在DOM中
- ✅ **不影响交互**：`pointer-events: none`

### 1.2 创建临时SVG文本元素

```javascript
function getTextRadius(text, fontSize, padding) {
    let textElement = null;
    try {
        const container = getMeasurementContainer();
        
        // 创建SVG元素
        textElement = container
            .append('svg')           // 创建SVG容器
            .append('text')          // 创建文本元素
            .attr('font-size', fontSize)  // 设置字体大小
            .text(text);              // 设置文字内容
        
        // 获取边界框（Bounding Box）
        const bbox = textElement.node().getBBox();
        
        // ... 继续计算
    } finally {
        // 清理临时元素
        if (textElement) {
            textElement.remove();
        }
    }
}
```

**getBBox() 返回的对象：**
```javascript
{
    width: 120,    // 文字宽度（像素）
    height: 20,    // 文字高度（像素）
    x: 0,          // X坐标
    y: 0           // Y坐标
}
```

---

## 📏 步骤2：计算所需半径

### 2.1 半径计算公式

**文件：** `static/js/renderers/shared-utilities.js`

```javascript
function getTextRadius(text, fontSize, padding) {
    // ... 创建文本元素并获取bbox
    
    // 计算半径：使用勾股定理
    const radius = Math.ceil(
        Math.sqrt(bbox.width * bbox.width + bbox.height * bbox.height) / 2 
        + (padding || 12)
    );
    
    // 确保最小半径
    return Math.max(radius, 30);
}
```

### 2.2 公式详解

**数学公式：**
```
对角线长度 = √(宽度² + 高度²)
半径 = 对角线长度 / 2 + 内边距
最终半径 = max(计算半径, 30)
```

**示例计算：**

假设文字 "测试文字" 的尺寸：
- 宽度：`bbox.width = 80px`
- 高度：`bbox.height = 16px`
- 内边距：`padding = 10px`

计算过程：
```javascript
// 1. 计算对角线长度
const diagonal = Math.sqrt(80 * 80 + 16 * 16);
// diagonal = √(6400 + 256) = √6656 ≈ 81.58px

// 2. 计算半径（对角线的一半）
const baseRadius = diagonal / 2;
// baseRadius = 81.58 / 2 ≈ 40.79px

// 3. 加上内边距
const radius = baseRadius + 10;
// radius = 40.79 + 10 = 50.79px

// 4. 向上取整
const finalRadius = Math.ceil(50.79);
// finalRadius = 51px

// 5. 确保最小半径
return Math.max(51, 30);
// 返回 51px
```

### 2.3 为什么使用对角线？

```
┌─────────────────┐
│                 │
│   测试文字      │  ← 文字内容
│                 │
└─────────────────┘
     ↑
   宽度

对角线 = √(宽度² + 高度²)
半径 = 对角线 / 2

这样可以确保：
- 文字在圆圈内完整显示
- 无论文字是横向还是纵向都能适应
```

---

## 🎯 步骤3：计算统一半径

### 3.1 计算每个节点的所需半径

**文件：** `static/js/renderers/bubble-map-renderer.js`

```javascript
// 计算统一半径 for all attribute nodes
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
```

### 3.2 统一半径策略

```javascript
// 使用最大半径作为统一半径
const uniformAttributeR = Math.max(...attributeRadii, 30);
```

**示例：**

假设有3个属性节点：
- 节点1："短" → 需要半径 35px
- 节点2："这是一个比较长的文字" → 需要半径 55px
- 节点3："中" → 需要半径 32px

计算过程：
```javascript
const attributeRadii = [35, 55, 32];
const uniformAttributeR = Math.max(35, 55, 32, 30);
// uniformAttributeR = 55px
```

**结果：** 所有属性节点都使用 55px 的半径

**设计理由：**
- ✅ **视觉统一**：所有节点大小一致，美观
- ✅ **内容完整**：确保最长文字也能完整显示
- ✅ **布局稳定**：避免因文字长度差异导致布局混乱

---

## 📊 步骤4：计算布局参数

### 4.1 中心主题节点半径

```javascript
// Topic radius - use preserved if available
let topicR;
if (nodeDimensions.topic && nodeDimensions.topic.r) {
    // 如果有保存的半径，使用保存的半径（空节点时）
    topicR = nodeDimensions.topic.r;
} else {
    // 否则根据文字计算
    topicR = getTextRadius(spec.topic, THEME.fontTopic, 20);
}
```

**参数说明：**
- `THEME.fontTopic`: 主题字体大小（通常 20px）
- `padding: 20`: 主题节点内边距（比属性节点大）

### 4.2 目标距离计算

```javascript
// Calculate even distribution around the topic
const targetDistance = topicR + uniformAttributeR + 50;
```

**公式：**
```
目标距离 = 主题半径 + 统一属性半径 + 间距(50px)
```

**示例：**
- 主题半径：`topicR = 50px`
- 统一属性半径：`uniformAttributeR = 35px`
- 间距：`50px`

计算：
```javascript
const targetDistance = 50 + 35 + 50;
// targetDistance = 135px
```

**含义：** 属性节点的中心距离主题中心的距离是 135px

### 4.3 内半径（防止重叠）

```javascript
// Inner radius: prevent nodes from overlapping central topic (donut hole)
const innerRadius = topicR + uniformAttributeR + 20;
```

**公式：**
```
内半径 = 主题半径 + 统一属性半径 + 边距(20px)
```

**示例：**
```javascript
const innerRadius = 50 + 35 + 20;
// innerRadius = 105px
```

**含义：** 属性节点的边缘距离主题边缘至少 20px

### 4.4 外半径（最大边界）

```javascript
const margin = uniformAttributeR * 0.2; // 20% of bubble radius as margin
const fixedOuterRadius = targetDistance + uniformAttributeR + margin;
```

**公式：**
```
边距 = 统一属性半径 × 20%
外半径 = 目标距离 + 统一属性半径 + 边距
```

**示例：**
```javascript
const margin = 35 * 0.2;  // margin = 7px
const fixedOuterRadius = 135 + 35 + 7;
// fixedOuterRadius = 177px
```

**含义：** 属性节点的边缘距离中心最远 177px

---

## 🔄 完整计算流程示例

### 输入数据

```javascript
const spec = {
    topic: "动物",
    attributes: ["有毛", "会叫", "四条腿", "有尾巴"]
};

const THEME = {
    fontTopic: 20,      // 主题字体大小
    fontAttribute: 14  // 属性字体大小
};
```

### 计算过程

**步骤1：计算主题半径**
```javascript
topicR = getTextRadius("动物", 20, 20);
// 假设结果：topicR = 45px
```

**步骤2：计算每个属性节点的所需半径**
```javascript
const attributeRadii = [
    getTextRadius("有毛", 14, 10),    // 假设：35px
    getTextRadius("会叫", 14, 10),    // 假设：32px
    getTextRadius("四条腿", 14, 10),  // 假设：42px
    getTextRadius("有尾巴", 14, 10)   // 假设：38px
];
// attributeRadii = [35, 32, 42, 38]
```

**步骤3：计算统一半径**
```javascript
const uniformAttributeR = Math.max(35, 32, 42, 38, 30);
// uniformAttributeR = 42px
```

**步骤4：计算布局参数**
```javascript
const targetDistance = 45 + 42 + 50;
// targetDistance = 137px

const innerRadius = 45 + 42 + 20;
// innerRadius = 107px

const margin = 42 * 0.2;
// margin = 8.4px

const outerRadius = 137 + 42 + 8.4;
// outerRadius = 187.4px
```

### 最终结果

```javascript
{
    topicR: 45,                    // 主题节点半径
    uniformAttributeR: 42,         // 统一属性节点半径
    targetDistance: 137,          // 目标距离
    innerRadius: 107,             // 内半径
    outerRadius: 187.4            // 外半径
}
```

---

## 📐 尺寸计算优先级

### 优先级顺序

1. **保存的半径** (`_node_dimensions[nodeKey].r`)
   - 适用于：空节点（用户清空文字后）
   - 目的：保持空节点的视觉大小

2. **保存的宽高** (`_node_dimensions[nodeKey].w/h`)
   - 适用于：从其他图表类型转换而来
   - 转换：`radius = max(w, h) / 2`

3. **根据文字重新计算** (`getTextRadius(text)`)
   - 适用于：正常文字修改
   - 方法：测量文字尺寸 + 内边距

### 代码实现

```javascript
const attributeRadii = spec.attributes.map((t, idx) => {
    const textStr = typeof t === 'object' ? (t.text || '') : (t || '');
    const nodeKey = `attribute-${idx}`;
    const preservedDims = nodeDimensions[nodeKey];
    
    // 优先级1：保存的半径
    if (preservedDims && preservedDims.r) {
        return preservedDims.r;
    }
    
    // 优先级2：保存的宽高
    if (preservedDims && preservedDims.w && preservedDims.h) {
        return Math.max(preservedDims.w, preservedDims.h) / 2;
    }
    
    // 优先级3：重新计算
    return getTextRadius(textStr, THEME.fontAttribute, 10);
});
```

---

## 🎨 不同节点的参数

| 节点类型 | 字体大小 | 内边距 | 最小半径 |
|---------|---------|--------|---------|
| **主题节点** | 20px | 20px | 30px |
| **属性节点** | 14px | 10px | 30px |

### 为什么主题节点内边距更大？

- **视觉重要性**：主题节点是中心，需要更突出
- **文字可能更长**：主题文字通常比属性文字长
- **更好的可读性**：更大的内边距让文字更易读

---

## 🔧 关键函数总结

### getTextRadius(text, fontSize, padding)

**功能：** 根据文字内容计算所需的圆圈半径

**参数：**
- `text`: 文字内容（字符串）
- `fontSize`: 字体大小（数字，单位px）
- `padding`: 内边距（数字，单位px，默认12）

**返回值：** 半径（数字，单位px，最小30px）

**实现：**
```javascript
function getTextRadius(text, fontSize, padding) {
    // 1. 创建临时SVG文本元素
    const container = getMeasurementContainer();
    const textElement = container
        .append('svg')
        .append('text')
        .attr('font-size', fontSize)
        .text(text);
    
    // 2. 获取边界框
    const bbox = textElement.node().getBBox();
    
    // 3. 计算半径
    const radius = Math.ceil(
        Math.sqrt(bbox.width * bbox.width + bbox.height * bbox.height) / 2 
        + (padding || 12)
    );
    
    // 4. 清理并返回
    textElement.remove();
    return Math.max(radius, 30);
}
```

---

## 💡 设计要点

### 1. 精确测量
- ✅ 使用 SVG `getBBox()` 获取**实际渲染尺寸**
- ✅ 考虑字体、字号、文字内容的所有因素
- ✅ 比估算方法更准确

### 2. 统一半径策略
- ✅ 所有属性节点使用**统一半径**
- ✅ 使用最大所需半径确保所有文字都能显示
- ✅ 保持视觉统一性

### 3. 最小半径保证
- ✅ 无论文字多短，最小半径都是 30px
- ✅ 保证圆圈的可读性和美观性

### 4. 内存安全
- ✅ 使用单例模式的测量容器
- ✅ 及时清理临时元素
- ✅ 防止内存泄漏

---

## 📝 总结

尺寸计算的完整流程：

1. **文字测量** → 使用 SVG `getBBox()` 获取精确尺寸
2. **半径计算** → 使用勾股定理计算对角线，除以2得到半径
3. **统一半径** → 取所有节点所需半径的最大值
4. **布局参数** → 根据半径计算目标距离、内半径、外半径

这个实现方案**精确、高效、稳定**，能够完美处理各种文字长度和内容变化。
