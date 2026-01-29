/**
 * Double Bubble Map Loader
 * Per-type unified radius: measure text → required radius per node (empty uses saved) → max per type → draw with unified radius.
 */
import {
  DEFAULT_COLUMN_SPACING,
  DEFAULT_PADDING,
  DOUBLE_BUBBLE_MAX_CAPSULE_HEIGHT,
} from '@/composables/diagrams/layoutConfig'
import type { Connection, DiagramNode } from '@/types'

import {
  doubleBubbleDiffRequiredRadius,
  doubleBubbleRequiredRadius,
} from './textMeasurement'
import type { SpecLoaderResult } from './types'

/** Saved radii per node (for empty nodes); radii in px. */
export interface DoubleBubbleMapNodeSizes {
  topicLeft?: number
  topicRight?: number
  similarities?: number[]
  leftDifferences?: number[]
  rightDifferences?: number[]
}

/** Capsule: 长度随 radius，高度有上限 */
function capsuleFromRadius(radius: number): { width: number; height: number; diameter: number } {
  const diameter = radius * 2
  const height = Math.min(
    Math.round(diameter * 0.56),
    DOUBLE_BUBBLE_MAX_CAPSULE_HEIGHT
  )
  return {
    width: Math.round(diameter * 1.22),
    height,
    diameter,
  }
}

/**
 * Load double bubble map spec into diagram nodes and connections
 *
 * @param spec - Double bubble map spec with left, right, similarities, and differences
 * @returns SpecLoaderResult with nodes and connections
 */
export function loadDoubleBubbleMapSpec(spec: Record<string, unknown>): SpecLoaderResult {
  const left = (spec.left as string) || (spec.topic1 as string) || ''
  const right = (spec.right as string) || (spec.topic2 as string) || ''
  const similarities = (spec.similarities as string[]) || (spec.shared as string[]) || []
  const leftDifferences =
    (spec.leftDifferences as string[]) ||
    (spec.left_differences as string[]) ||
    (spec.left_unique as string[]) ||
    []
  const rightDifferences =
    (spec.rightDifferences as string[]) ||
    (spec.right_differences as string[]) ||
    (spec.right_unique as string[]) ||
    []

  const saved = (spec._doubleBubbleMapNodeSizes as DoubleBubbleMapNodeSizes | undefined) || {}
  const columnSpacing = DEFAULT_COLUMN_SPACING
  const padding = DEFAULT_PADDING

  // Per-type required radius (empty node uses saved radius)
  const topicLeftR = doubleBubbleRequiredRadius(left, {
    isTopic: true,
    savedRadius: saved.topicLeft,
  })
  const topicRightR = doubleBubbleRequiredRadius(right, {
    isTopic: true,
    savedRadius: saved.topicRight,
  })
  const topicR = Math.max(topicLeftR, topicRightR)

  const simRadii = similarities.map((text, i) =>
    doubleBubbleRequiredRadius(text, {
      isTopic: false,
      savedRadius: saved.similarities?.[i],
    })
  )
  const simR =
    simRadii.length > 0 ? Math.max(...simRadii) : 30

  const leftDiffRadii = leftDifferences.map((text, i) =>
    doubleBubbleDiffRequiredRadius(text, saved.leftDifferences?.[i])
  )
  const rightDiffRadii = rightDifferences.map((text, i) =>
    doubleBubbleDiffRequiredRadius(text, saved.rightDifferences?.[i])
  )
  const leftDiffR = leftDiffRadii.length > 0 ? Math.max(...leftDiffRadii) : 30
  const rightDiffR = rightDiffRadii.length > 0 ? Math.max(...rightDiffRadii) : 30
  /** 左右不同点统一半径，任一侧变化时两侧同步 */
  const diffR = Math.max(leftDiffR, rightDiffR)

  const diffCap = capsuleFromRadius(diffR)
  const maxLeftW = diffCap.width
  const maxRightW = diffCap.width
  const D = simR + 2 * columnSpacing + 2 * topicR
  const requiredWidth = 2 * D + maxLeftW + maxRightW + padding * 2
  const centerX = requiredWidth / 2
  const simX = centerX
  const leftTopicX = centerX - simR - columnSpacing - topicR
  const rightTopicX = centerX + simR + columnSpacing + topicR
  const leftDiffX = centerX - D
  const rightDiffX = centerX + D + maxRightW

  const simCount = similarities.length
  const leftDiffCount = leftDifferences.length
  const rightDiffCount = rightDifferences.length
  const simCapsule = capsuleFromRadius(simR)
  const simVerticalSpacing = simCapsule.height + 12
  const diffVerticalSpacing = diffCap.height + 10
  const simColHeight = simCount > 0 ? (simCount - 1) * simVerticalSpacing + simCapsule.height : 0
  const maxDiffCount = Math.max(leftDiffCount, rightDiffCount)
  const diffColHeight =
    maxDiffCount > 0 ? (maxDiffCount - 1) * diffVerticalSpacing + diffCap.height : 0
  const maxColHeight = Math.max(simColHeight, diffColHeight, topicR * 2)
  const requiredHeight = maxColHeight + padding * 2
  const centerY = requiredHeight / 2

  const nodes: DiagramNode[] = []
  const connections: Connection[] = []

  const topicDiameter = topicR * 2
  nodes.push({
    id: 'left-topic',
    text: left,
    type: 'topic',
    position: { x: leftTopicX - topicR, y: centerY - topicR },
    style: { size: topicDiameter },
  })
  nodes.push({
    id: 'right-topic',
    text: right,
    type: 'topic',
    position: { x: rightTopicX - topicR, y: centerY - topicR },
    style: { size: topicDiameter },
  })

  const simStartY = centerY - simColHeight / 2 + simCapsule.height / 2
  similarities.forEach((sim, index) => {
    const cap = capsuleFromRadius(simR)
    const cy = simStartY + index * simVerticalSpacing
    nodes.push({
      id: `similarity-${index}`,
      text: sim,
      type: 'bubble',
      position: { x: simX - cap.width / 2, y: cy - cap.height / 2 },
      style: { size: simR * 2 },
    })
    connections.push(
      { id: `edge-left-sim-${index}`, source: 'left-topic', target: `similarity-${index}` },
      { id: `edge-right-sim-${index}`, source: 'right-topic', target: `similarity-${index}` }
    )
  })

  const diffStartY = centerY - diffColHeight / 2 + diffCap.height / 2

  leftDifferences.forEach((diff, index) => {
    const cy = diffStartY + index * diffVerticalSpacing
    nodes.push({
      id: `left-diff-${index}`,
      text: diff,
      type: 'bubble',
      position: { x: leftDiffX - maxLeftW, y: cy - diffCap.height / 2 },
      style: { size: diffR * 2 },
    })
    connections.push({
      id: `edge-left-diff-${index}`,
      source: 'left-topic',
      target: `left-diff-${index}`,
    })
  })

  rightDifferences.forEach((diff, index) => {
    const cy = diffStartY + index * diffVerticalSpacing
    nodes.push({
      id: `right-diff-${index}`,
      text: diff,
      type: 'bubble',
      position: { x: rightDiffX - diffCap.width, y: cy - diffCap.height / 2 },
      style: { size: diffR * 2 },
    })
    connections.push({
      id: `edge-right-diff-${index}`,
      source: 'right-topic',
      target: `right-diff-${index}`,
    })
  })

  const nodeSizes: DoubleBubbleMapNodeSizes = {
    topicLeft: topicR,
    topicRight: topicR,
    similarities: similarities.map(() => simR),
    leftDifferences: leftDifferences.map(() => diffR),
    rightDifferences: rightDifferences.map(() => diffR),
  }
  return {
    nodes,
    connections,
    metadata: { _doubleBubbleMapNodeSizes: nodeSizes },
  }
}
