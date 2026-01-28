<script setup lang="ts">
/**
 * CircleMapOverlay - Draws the outermost boundary circle for circle maps
 * Uses layout (centerX, centerY, outerCircleR) so the circle is always concentric
 * with topic and context nodes. Rendered in flow coordinates via viewport transform.
 */
import { computed } from 'vue'

import { useVueFlow } from '@vue-flow/core'

import { useDiagramStore } from '@/stores'
import { calculateCircleMapLayout } from '@/stores/specLoader/utils'

const { viewport: vueFlowViewport, getViewport, getNodes } = useVueFlow()
const diagramStore = useDiagramStore()

const viewport = computed(() => {
  if (vueFlowViewport.value) return vueFlowViewport.value
  return getViewport()
})

const isCircleMap = computed(() => diagramStore.type === 'circle_map')

const layout = computed(() => {
  if (!isCircleMap.value) return null
  const nodes = getNodes.value
  const topicNode = nodes.find((n) => n.id === 'topic')
  const contextNodes = nodes
    .filter((n) => n.id.startsWith('context-'))
    .sort((a, b) => {
      const i = parseInt(a.id.replace(/^context-/, ''), 10)
      const j = parseInt(b.id.replace(/^context-/, ''), 10)
      return i - j
    })
  const topicText = (topicNode?.data?.label as string) ?? ''
  const contextTexts = contextNodes.map((n) => (n.data?.label as string) ?? '')
  return calculateCircleMapLayout(contextTexts.length, contextTexts, topicText)
})

const strokeColor = '#666666'
const strokeWidth = 2
// Path radius so outer edge of stroke sits at outerCircleR (stroke centered on path)
const circleR = computed(() =>
  layout.value ? layout.value.outerCircleR - strokeWidth : 0
)
</script>

<template>
  <svg
    v-if="isCircleMap && layout"
    class="circle-map-overlay absolute inset-0 w-full h-full pointer-events-none"
    style="z-index: -1"
  >
    <g :transform="`translate(${viewport.x}, ${viewport.y}) scale(${viewport.zoom})`">
      <circle
        :cx="layout!.centerX"
        :cy="layout!.centerY"
        :r="circleR"
        fill="none"
        :stroke="strokeColor"
        :stroke-width="strokeWidth"
      />
    </g>
  </svg>
</template>

<style scoped>
.circle-map-overlay {
  overflow: visible;
}
</style>
