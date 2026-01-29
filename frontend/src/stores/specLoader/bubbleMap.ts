/**
 * Bubble Map Loader
 *
 * 自适应半径 + 圆形均匀分布 + 力导向优化
 * - 节点 ID：topic / bubble-{index}
 * - 基于文本测量计算 topicR 和统一 attribute 半径
 * - 使用 d3-force 做离线力导向迭代，结果写回 _customPositions
 */
import {
  DEFAULT_BUBBLE_RADIUS,
  DEFAULT_PADDING,
  DEFAULT_TOPIC_RADIUS,
} from '@/composables/diagrams/layoutConfig'
import type { Connection, DiagramNode, Position } from '@/types'
import {
  CONTEXT_FONT_SIZE,
  TOPIC_FONT_SIZE,
  calculateBubbleMapRadius,
} from '@/stores/specLoader/textMeasurement'
import type { SimulationNodeDatum } from 'd3-force'
import {
  forceCenter,
  forceCollide,
  forceManyBody,
  forceSimulation,
  forceX,
  forceY,
} from 'd3-force'

import type { SpecLoaderResult } from './types'

// ---------------------------------------------------------------------------
// 内部类型 & 常量
// ---------------------------------------------------------------------------

interface BubbleMapLayoutMeta {
  centerX: number
  centerY: number
  topicR: number
  uniformAttributeR: number
  childrenRadius: number
}

interface BubbleSimNode extends SimulationNodeDatum {
  id: string
  r: number
  targetX: number
  targetY: number
  x?: number
  y?: number
  vx?: number
  vy?: number
  fx?: number | null
  fy?: number | null
}

const MIN_TOPIC_RADIUS = 35  // 缩小主题节点（从40减少到35）
const MIN_ATTRIBUTE_RADIUS = 30
const TOPIC_PADDING = 20  // 缩小主题节点内边距（从25减少到20）
const ATTRIBUTE_PADDING = 10

// ---------------------------------------------------------------------------
// 文本 → 圆半径 计算（使用 SVG getBBox 精确测量）
// 
// 参考文档 BUBBLE_MAP_TEXT_ADAPTATION.md 和 BUBBLE_MAP_SIZE_CALCULATION.md：
// - 使用 SVG getBBox() 方法精确测量文字宽度和高度
// - 计算半径 = sqrt(宽度² + 高度²) / 2 + 内边距
// - 确保文字一行显示（no-wrap）
// - 确保最小半径（保证可读性）
// ---------------------------------------------------------------------------

function computeCircleRadiusFromText(
  text: string,
  fontSize: number,
  {
    isTopic,
    padding,
    minRadius,
  }: {
    isTopic: boolean
    padding: number
    minRadius: number
  }
): number {
  const baseText = (text || '').trim()
  if (!baseText) {
    return minRadius
  }

  // 使用 SVG getBBox() 方法精确测量（符合文档要求）
  // 导入 calculateBubbleMapRadius 函数
  return calculateBubbleMapRadius(baseText, fontSize, padding, minRadius, isTopic)
}

function computeTopicRadius(topic: string): number {
  // 若无法访问 DOM，computeMinDiameterForNoWrap 内部有 fallback
  return computeCircleRadiusFromText(topic, TOPIC_FONT_SIZE, {
    isTopic: true,
    padding: TOPIC_PADDING,
    minRadius: MIN_TOPIC_RADIUS,
  })
}

function computeAttributeRadii(attributes: string[]): number[] {
  return attributes.map((attr) =>
    computeCircleRadiusFromText(attr, CONTEXT_FONT_SIZE, {
      isTopic: false,
      padding: ATTRIBUTE_PADDING,
      minRadius: MIN_ATTRIBUTE_RADIUS,
    })
  )
}

// ---------------------------------------------------------------------------
// 布局 / 力导向
// ---------------------------------------------------------------------------

/** 中心节点与周围气泡的最小间隙，避免重叠 */
const MIN_GAP_TOPIC_BUBBLE = 15

function calculateChildrenRadius(
  nodeCount: number,
  topicR: number,
  uniformAttributeR: number
): number {
  // 中心到周围气泡中心的距离至少为 topicR + uniformAttributeR + 间隙，确保不重叠
  const minRadiusNoOverlap = topicR + uniformAttributeR + MIN_GAP_TOPIC_BUBBLE

  // 目标距离：topicR + uniformAttributeR + 50，恢复到原来的3/4（比1/2大，但比原来小）
  const targetDistance = Math.max(
    minRadiusNoOverlap,
    (topicR + uniformAttributeR + 50) * 0.75
  )

  // 圆周约束：根据节点数动态调整 childrenRadius，避免过密
  // 使用适中的间距倍数（从原来的2.0-2.1减少到1.5-1.7）
  const spacingMultiplier = nodeCount <= 3 ? 1.5 : nodeCount <= 6 ? 1.6 : 1.7
  const circumferentialMinRadius =
    nodeCount > 0 ? (uniformAttributeR * nodeCount * spacingMultiplier) / (2 * Math.PI) : 0

  // 优先使用 targetDistance，设置一个上限：不超过 targetDistance 的 1.5 倍
  const maxAllowedRadius = targetDistance * 1.5
  const effectiveCircumferentialRadius = Math.min(circumferentialMinRadius, maxAllowedRadius)

  // 最终半径取较大值，且必须 >= minRadiusNoOverlap，保证周围气泡不与中心节点重叠
  return Math.max(
    targetDistance,
    Math.min(effectiveCircumferentialRadius, maxAllowedRadius),
    minRadiusNoOverlap,
    30
  )
}

function buildInitialTargets(
  nodeCount: number,
  centerX: number,
  centerY: number,
  childrenRadius: number,
  topicR: number,
  uniformAttributeR: number
): BubbleSimNode[] {
  const nodes: BubbleSimNode[] = []

  // 中心 topic 节点：target 即中心
  nodes.push({
    id: 'topic',
    r: topicR,
    x: centerX,
    y: centerY,
    targetX: centerX,
    targetY: centerY,
  })

  if (nodeCount === 0) {
    return nodes
  }

  // 属性节点：均匀分布在圆周上，从顶部（-90°）开始
  for (let i = 0; i < nodeCount; i++) {
    const angleDeg = (i * 360) / nodeCount - 90
    const angleRad = (angleDeg * Math.PI) / 180
    const targetX = centerX + childrenRadius * Math.cos(angleRad)
    const targetY = centerY + childrenRadius * Math.sin(angleRad)

    nodes.push({
      id: `bubble-${i}`,
      r: uniformAttributeR,
      x: targetX,
      y: targetY,
      targetX,
      targetY,
    })
  }

  return nodes
}

/**
 * 使用D3力导向算法优化节点位置
 * 
 * 参考提示词推荐的参数：
 * - 排斥力强度：-800（负值表示排斥）
 * - 碰撞缓冲：节点半径 + 5px
 * - 中心吸引强度：0.05（轻微拉向中心）
 * - 目标拉力系数：0.1（拉回目标位置的强度）
 * - 模拟迭代次数：50-300次（根据节点数动态调整）
 */
function runForceSimulation(
  nodes: BubbleSimNode[],
  centerX: number,
  centerY: number,
  iterations: number
): void {
  // 固定中心节点（topic）的位置，不让它移动
  const topicNode = nodes.find((n) => n.id === 'topic')
  if (topicNode) {
    topicNode.fx = centerX
    topicNode.fy = centerY
  }

  const simulation = forceSimulation<BubbleSimNode>(nodes)
    // 1. 排斥力：节点之间相互排斥（适中的强度，保持均匀分布）
    .force('charge', forceManyBody<BubbleSimNode>().strength(-600))
    // 2. 碰撞检测：防止节点重叠（半径 + 5px缓冲，适中的强度）
    .force(
      'collide',
      forceCollide<BubbleSimNode>().radius((d: BubbleSimNode) => d.r + 5).strength(0.8)
    )
    // 3. 中心吸引：轻微拉向中心（降低强度，避免过度拉向中心）
    .force('center', forceCenter(centerX, centerY).strength(0.01))
    // 4. 目标位置拉力：拉回初始圆形分布位置（增强强度，确保节点更接近目标位置，保持均匀分布）
    .force(
      'x',
      forceX<BubbleSimNode>()
        .x((d: BubbleSimNode) => d.targetX)
        .strength(0.5)
    )
    .force(
      'y',
      forceY<BubbleSimNode>()
        .y((d: BubbleSimNode) => d.targetY)
        .strength(0.5)
    )

  simulation.stop()

  // 迭代次数：提示词推荐300次，但根据节点数动态调整（80 + nodeCount * 8）
  // 限制在 50-300 之间以保证性能和效果
  const safeIterations = Math.max(50, Math.min(iterations, 300))
  for (let i = 0; i < safeIterations; i++) {
    simulation.tick()
  }

  // 解除中心节点的固定位置
  if (topicNode) {
    topicNode.fx = null
    topicNode.fy = null
  }

  simulation.stop()
}

// ---------------------------------------------------------------------------
// Loader 主逻辑
// ---------------------------------------------------------------------------

/**
 * Load bubble map spec into diagram nodes and connections
 *
 * @param spec - Bubble map spec with topic and attributes array
 * @returns SpecLoaderResult with nodes and connections + 可选 metadata
 */
export function loadBubbleMapSpec(spec: Record<string, unknown>): SpecLoaderResult {
  if (!spec || typeof spec !== 'object') {
    return { nodes: [], connections: [] }
  }

  const topic = (spec.topic as string) || ''
  const attributes = Array.isArray(spec.attributes) ? (spec.attributes as string[]) : []
  const nodeCount = attributes.length

  // 已保存的自定义位置（来自拖拽），以及上一次布局元数据
  const existingPositions =
    ((spec as { _customPositions?: Record<string, Position> })._customPositions as
      | Record<string, Position>
      | undefined) || {}

  const previousLayout = (spec._bubbleMapLayout || null) as BubbleMapLayoutMeta | null

  // 文本驱动半径（topicR + 每个属性半径 → uniformAttributeR）
  // 总是重新计算 topicR，因为 topic 文本可能已改变
  const topicR = computeTopicRadius(topic)
  const attributeRadii = computeAttributeRadii(attributes)
  let uniformAttributeR =
    attributeRadii.length > 0 ? Math.max(...attributeRadii) : DEFAULT_BUBBLE_RADIUS

  // 若有历史布局信息，且 uniformAttributeR 变化很小（<2px），则沿用旧值，避免频繁轻微晃动
  // 但仅在文本没有明显变化时使用
  if (previousLayout && previousLayout.uniformAttributeR > 0) {
    const diff = Math.abs(previousLayout.uniformAttributeR - uniformAttributeR)
    if (diff < 2) {
      uniformAttributeR = previousLayout.uniformAttributeR
    }
  }

  // childrenRadius / centerX / centerY 计算
  const childrenRadius = calculateChildrenRadius(nodeCount, topicR, uniformAttributeR)
  const padding = DEFAULT_PADDING
  const centerX = childrenRadius + uniformAttributeR + padding
  const centerY = childrenRadius + uniformAttributeR + padding

  // 检测是否需要「重新布局并覆盖 _customPositions」
  let hasCustomPositionsForAll = true
  for (let i = 0; i < nodeCount; i++) {
    const nodeId = `bubble-${i}`
    if (!existingPositions[nodeId]) {
      hasCustomPositionsForAll = false
      break
    }
  }

  const hasAnyCustom = Object.keys(existingPositions).length > 0
  const radiusChangedSignificantly =
    previousLayout && previousLayout.uniformAttributeR
      ? Math.abs(previousLayout.uniformAttributeR - uniformAttributeR) > 2
      : false
  // 中心节点半径变化时也需重算：主题词文字长度变化导致 topicR 变化，中心应重绘、周围气泡距离需调整
  const topicRadiusChangedSignificantly =
    previousLayout && previousLayout.topicR != null
      ? Math.abs(previousLayout.topicR - topicR) > 2
      : false

  const shouldRecalculateLayout =
    !hasAnyCustom ||
    !hasCustomPositionsForAll ||
    radiusChangedSignificantly ||
    topicRadiusChangedSignificantly

  const nodes: DiagramNode[] = []
  const connections: Connection[] = []
  const newPositions: Record<string, Position> = {}

  // -------------------------------------------------------------------------
  // 1) 如果需要重算：构建目标点 + 力导向模拟 → 写回 _customPositions
  // -------------------------------------------------------------------------
  if (shouldRecalculateLayout) {
    const simNodes = buildInitialTargets(
      nodeCount,
      centerX,
      centerY,
      childrenRadius,
      topicR,
      uniformAttributeR
    )

    // 迭代次数随节点数增长，避免大图过慢
    const iterations = 80 + nodeCount * 8
    runForceSimulation(simNodes, centerX, centerY, iterations)

    // 将模拟结果转换为「左上角坐标」，写入 newPositions
    for (const n of simNodes) {
      const cx = typeof n.x === 'number' ? n.x : n.targetX
      const cy = typeof n.y === 'number' ? n.y : n.targetY
      const r = n.r
      newPositions[n.id] = {
        x: Math.round(cx - r),
        y: Math.round(cy - r),
      }
    }
  }

  // -------------------------------------------------------------------------
  // 2) 构建 DiagramNode（topic + attributes）
  // -------------------------------------------------------------------------

  // Topic 节点
  const topicPosition: Position =
    shouldRecalculateLayout && newPositions.topic
      ? newPositions.topic
      : existingPositions.topic || {
          x: Math.round(centerX - topicR),
          y: Math.round(centerY - topicR),
        }

  nodes.push({
    id: 'topic',
    text: topic,
    type: 'topic',
    position: topicPosition,
    style: {
      size: topicR * 2,
    },
  })

  // 属性节点
  for (let i = 0; i < nodeCount; i++) {
    const id = `bubble-${i}`
    const text = attributes[i] ?? ''
    const r = uniformAttributeR

    const position: Position =
      shouldRecalculateLayout && newPositions[id]
        ? newPositions[id]
        : existingPositions[id] ||
          (() => {
            // 极端情况兜底：按圆周均匀分布
            const angleDeg = (i * 360) / nodeCount - 90
            const angleRad = (angleDeg * Math.PI) / 180
            const cx = centerX + childrenRadius * Math.cos(angleRad)
            const cy = centerY + childrenRadius * Math.sin(angleRad)
            return {
              x: Math.round(cx - r),
              y: Math.round(cy - r),
            }
          })()

    nodes.push({
      id,
      text,
      type: 'bubble',
      position,
      style: {
        size: r * 2,
      },
    })

    connections.push({
      id: `edge-topic-bubble-${i}`,
      source: 'topic',
      target: id,
    })
  }

  // -------------------------------------------------------------------------
  // 3) 返回结果 + metadata
  //    - 当需要重算时，将 newPositions 写回 _customPositions
  //    - 同时保存 _bubbleMapLayout 以便后续比较 uniformR / 约束拖拽
  // -------------------------------------------------------------------------

  const metadata: Record<string, unknown> = {}

  if (shouldRecalculateLayout) {
    metadata._customPositions = {
      ...existingPositions,
      ...newPositions,
    }
  } else if (hasAnyCustom) {
    // 不重算时，保留原有自定义位置
    metadata._customPositions = existingPositions
  }

  metadata._bubbleMapLayout = {
    centerX,
    centerY,
    topicR,
    uniformAttributeR,
    childrenRadius,
  } satisfies BubbleMapLayoutMeta

  return { nodes, connections, metadata }
}
