/**
 * Shared utilities for spec loaders
 * Contains common layout calculations and type definitions
 */
import {
  DEFAULT_CENTER_X,
  DEFAULT_CENTER_Y,
  DEFAULT_CONTEXT_RADIUS,
  DEFAULT_TOPIC_RADIUS,
} from '@/composables/diagrams/layoutConfig'

import {
  computeContextFontSize as measureContextFontSize,
  computeFontSizeToFitCircle as measureFontSizeToFit,
  computeFontSizeToFitCircleNoWrap as measureFontSizeToFitNoWrap,
  computeMinDiameterForNoWrap,
  computeTopicRadiusForCircleMap,
  CONTEXT_FONT_SIZE,
  TOPIC_FONT_SIZE,
} from './textMeasurement'

/**
 * Circle map layout calculation result
 */
export interface CircleMapLayoutResult {
  centerX: number
  centerY: number
  topicR: number
  uniformContextR: number
  childrenRadius: number
  outerCircleR: number
}

/** Gap between topic and context ring (px). Larger = more space between center and middle layer. */
const CIRCLE_MAP_TOPIC_CONTEXT_GAP = 65
/** Extra edge-to-edge gap between adjacent context circles (px). Second-layer spacing. */
const CIRCLE_MAP_CONTEXT_GAP = 8
/** Margin outside context ring for outer boundary (px). Keeps boundary clear of context circles. */
const CIRCLE_MAP_OUTER_MARGIN = 18
/** Minimum childrenRadius (px). */
const CIRCLE_MAP_MIN_CHILDREN_RADIUS = 130

/**
 * Calculate adaptive circle size based on text length.
 * Used only for topic nodes (with cap applied in loader). Context uses fixed uniform size.
 *
 * @param text - Text content of the node
 * @param isTopic - Whether this is a topic node (larger) or context node
 * @returns Diameter in pixels
 */
export function calculateAdaptiveCircleSize(text: string, isTopic: boolean = false): number {
  if (!text || !text.trim()) {
    return isTopic ? 120 : 70
  }

  const textLength = text.trim().length

  if (isTopic) {
    if (textLength <= 10) return 120
    if (textLength <= 20) return 140
    if (textLength <= 30) return 160
    const estimatedWidth = textLength * 8
    return Math.max(180, Math.min(estimatedWidth + 40, 250))
  } else {
    if (textLength <= 6) return 70
    if (textLength <= 12) return 85
    if (textLength <= 18) return 100
    if (textLength <= 24) return 115
    const estimatedWidth = textLength * 7
    return Math.max(130, Math.min(estimatedWidth + 30, 200))
  }
}

export function computeFontSizeToFitCircle(
  text: string,
  diameterPx: number,
  isTopic: boolean
): number {
  return measureFontSizeToFit(text, diameterPx, isTopic)
}

export function computeFontSizeToFitCircleNoWrap(
  text: string,
  diameterPx: number,
  isTopic: boolean
): number {
  return measureFontSizeToFitNoWrap(text, diameterPx, isTopic)
}

/**
 * DOM-based: uniform context fontSize (min over all texts so longest fits).
 */
export function computeContextFontSize(
  texts: string[],
  uniformContextDiameterPx: number
): number {
  return measureContextFontSize(texts, uniformContextDiameterPx)
}

/**
 * Calculate circle map layout: fixed font, circles from text, ring no-overlap.
 * Center = canvas center; context nodes evenly spaced on a ring (360/n deg).
 * Order: topic first → uniformContextR from texts → childrenRadius → outer circle.
 * Shared by loadCircleMapSpec and recalculateCircleMapLayout.
 */
export function calculateCircleMapLayout(
  nodeCount: number,
  contextTexts: string[] = [],
  topicText: string = ''
): CircleMapLayoutResult {
  const centerX = DEFAULT_CENTER_X
  const centerY = DEFAULT_CENTER_Y

  // (g) Topic: text-adaptive radius = text bounding box diagonal/2 + inner padding, min only (no max)
  const topicRFromText = computeTopicRadiusForCircleMap(topicText || ' ')
  const topicR = Math.max(DEFAULT_TOPIC_RADIUS, topicRFromText)

  // (b) Uniform context R: fixed CONTEXT_FONT_SIZE → min diameter per text → max → radius
  let uniformContextR: number
  if (contextTexts.length === 0) {
    uniformContextR = DEFAULT_CONTEXT_RADIUS
  } else {
    let maxRadius = DEFAULT_CONTEXT_RADIUS
    for (const t of contextTexts) {
      const d = computeMinDiameterForNoWrap(t || ' ', CONTEXT_FONT_SIZE, false)
      maxRadius = Math.max(maxRadius, d / 2)
    }
    uniformContextR = maxRadius
  }

  // (c) Ring radius: no-overlap context–context (with small gap), no-overlap context–topic, minimum.
  // All layers share the same center (centerX, centerY). Slightly lengthen childrenRadius so
  // adjacent second-layer circles have a small edge-to-edge gap.
  const noOverlapContext =
    nodeCount > 0
      ? (uniformContextR + CIRCLE_MAP_CONTEXT_GAP / 2) / Math.sin(Math.PI / nodeCount)
      : 0
  const noOverlapTopic = topicR + uniformContextR + CIRCLE_MAP_TOPIC_CONTEXT_GAP
  const childrenRadius = Math.max(
    noOverlapContext,
    noOverlapTopic,
    CIRCLE_MAP_MIN_CHILDREN_RADIUS
  )

  // (d) Outer circle: just enclose context ring; margin avoids overlap with boundary stroke
  const outerCircleR = childrenRadius + uniformContextR + CIRCLE_MAP_OUTER_MARGIN

  return { centerX, centerY, topicR, uniformContextR, childrenRadius, outerCircleR }
}
