<script setup lang="ts">
/**
 * BoundaryNode - Circle map outer boundary ring
 * Non-interactive visual element showing the constraint boundary
 */
import { computed } from 'vue'

import { useTheme } from '@/composables/useTheme'
import type { MindGraphNodeProps } from '@/types'

const props = defineProps<MindGraphNodeProps>()

// Get theme defaults
const { getNodeStyle } = useTheme({
  diagramType: computed(() => props.data.diagramType),
})

const defaultStyle = computed(() => getNodeStyle('boundary'))

// Dimensions: explicit layout values only. Vue Flow measures this node; intrinsic size must match layout.
const width = computed(() => {
  const explicit = (props.data as { boundaryWidth?: number }).boundaryWidth
  if (explicit != null && explicit > 0) return explicit
  const directStyle = props.data.style as { width?: number; height?: number } | undefined
  const originalStyle = props.data.originalNode?.style as
    | { width?: number; height?: number }
    | undefined
  return directStyle?.width ?? originalStyle?.width ?? 400
})

const height = computed(() => {
  const explicit = (props.data as { boundaryHeight?: number }).boundaryHeight
  if (explicit != null && explicit > 0) return explicit
  const directStyle = props.data.style as { width?: number; height?: number } | undefined
  const originalStyle = props.data.originalNode?.style as
    | { width?: number; height?: number }
    | undefined
  return directStyle?.height ?? originalStyle?.height ?? 400
})

const rootStyle = computed(() => ({
  width: `${width.value}px`,
  height: `${height.value}px`,
}))

// Outer circle colors matching old JS bubble-map-renderer.js THEME
// outerCircleStroke: #666666, outerCircleStrokeWidth: 2
const strokeColor = computed(
  () => props.data.style?.borderColor || defaultStyle.value.borderColor || '#666666'
)

const strokeWidth = computed(
  () => props.data.style?.borderWidth || defaultStyle.value.borderWidth || 2
)
</script>

<template>
  <div
    class="boundary-node pointer-events-none flex shrink-0"
    :style="rootStyle"
  >
    <svg
      class="boundary-svg block"
      :width="width"
      :height="height"
      :viewBox="`0 0 ${width} ${height}`"
      preserveAspectRatio="xMidYMid meet"
    >
      <circle
        :cx="width / 2"
        :cy="height / 2"
        :r="width / 2 - strokeWidth"
        fill="none"
        :stroke="strokeColor"
        :stroke-width="strokeWidth"
      />
    </svg>
  </div>
</template>

<style scoped>
.boundary-node {
  overflow: visible;
}

.boundary-svg {
  overflow: visible;
}
</style>
