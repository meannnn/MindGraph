<script setup lang="ts">
/**
 * CircleNode - Circular node for Circle/Bubble Maps; capsule for Double Bubble Map attributes
 * Size and fontSize come from layout (DOM-based); no truncation.
 * Double bubble map uses capsule (pill) shape for attribute nodes; topic stays circle.
 * Supports inline text editing on double-click.
 * Text is centered via grid place-items: center.
 */
import { computed, ref } from 'vue'

import { DOUBLE_BUBBLE_MAX_CAPSULE_HEIGHT } from '@/composables/diagrams/layoutConfig'
import { eventBus } from '@/composables/useEventBus'
import { useTheme } from '@/composables/useTheme'
import { calculateAdaptiveCircleSize } from '@/stores/specLoader/utils'
import type { MindGraphNodeProps } from '@/types'

import InlineEditableText from './InlineEditableText.vue'

const props = defineProps<MindGraphNodeProps>()

const { getNodeStyle } = useTheme({
  diagramType: computed(() => props.data.diagramType),
})

const isTopicNode = computed(() => props.data.nodeType === 'topic')
/** Double bubble map attribute nodes use capsule (pill) shape instead of circle */
const isDoubleBubbleCapsule = computed(
  () => props.data.diagramType === 'double_bubble_map' && !isTopicNode.value
)
const defaultStyle = computed(() => getNodeStyle(isTopicNode.value ? 'topic' : 'context'))

const circleSize = computed(() => {
  if (props.data.style?.size) return props.data.style.size
  const text = props.data.label || ''
  return calculateAdaptiveCircleSize(text, isTopicNode.value)
})

/** Capsule dimensions: 长度随文字，高度有上限 */
const capsuleWidth = computed(() => Math.round(circleSize.value * 1.22))
const capsuleHeight = computed(() =>
  Math.min(Math.round(circleSize.value * 0.56), DOUBLE_BUBBLE_MAX_CAPSULE_HEIGHT)
)

const borderWidth = computed(
  () =>
    props.data.style?.borderWidth ??
    defaultStyle.value.borderWidth ??
    (isTopicNode.value ? 3 : 2)
)

const nodeStyle = computed(() => {
  const base = {
    backgroundColor:
      props.data.style?.backgroundColor ||
      defaultStyle.value.backgroundColor ||
      (isTopicNode.value ? '#1976d2' : '#e3f2fd'),
    borderColor:
      props.data.style?.borderColor ||
      defaultStyle.value.borderColor ||
      (isTopicNode.value ? '#0d47a1' : '#1976d2'),
    color:
      props.data.style?.textColor ||
      defaultStyle.value.textColor ||
      (isTopicNode.value ? '#ffffff' : '#333333'),
    fontSize: `${props.data.style?.fontSize ?? defaultStyle.value.fontSize ?? (isTopicNode.value ? 20 : 14)}px`,
    fontWeight:
      props.data.style?.fontWeight ||
      defaultStyle.value.fontWeight ||
      (isTopicNode.value ? 'bold' : 'normal'),
    borderWidth: `${borderWidth.value}px`,
  }
  if (isDoubleBubbleCapsule.value) {
    return { ...base, width: `${capsuleWidth.value}px`, height: `${capsuleHeight.value}px` }
  }
  return { ...base, width: `${circleSize.value}px`, height: `${circleSize.value}px` }
})

const isEditing = ref(false)

function handleTextSave(newText: string) {
  isEditing.value = false
  eventBus.emit('node:text_updated', { nodeId: props.id, text: newText })
}

function handleEditCancel() {
  isEditing.value = false
}
</script>

<template>
  <div
    class="circle-node circle-node-grid rounded-full border-solid select-none"
    :class="[
      isTopicNode ? 'cursor-default' : 'cursor-grab',
      isTopicNode ? 'topic-circle' : 'context-circle',
      isDoubleBubbleCapsule ? 'circle-node-capsule' : '',
    ]"
    :style="nodeStyle"
  >
    <div class="circle-node-inner">
      <InlineEditableText
        :text="data.label || ''"
        :node-id="id"
        :is-editing="isEditing"
        :max-width="`${Math.max(0, (isDoubleBubbleCapsule ? capsuleWidth : circleSize) - 16 - 2 * borderWidth)}px`"
        text-align="center"
        :text-class="''"
        :no-wrap="data.diagramType === 'circle_map' || data.diagramType === 'bubble_map' || data.diagramType === 'double_bubble_map' ? true : !!data.style?.noWrap"
        :truncate="data.diagramType === 'circle_map' || data.diagramType === 'bubble_map' || data.diagramType === 'double_bubble_map' ? false : undefined"
        @save="handleTextSave"
        @cancel="handleEditCancel"
        @edit-start="isEditing = true"
      />
    </div>
  </div>
</template>

<style scoped>
.circle-node {
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  transition:
    box-shadow 0.2s ease,
    transform 0.2s ease;
  flex-shrink: 0;
  aspect-ratio: 1;
}

/* Double bubble map: capsule (pill) shape, no forced aspect-ratio */
.circle-node-capsule {
  aspect-ratio: auto;
}

/* Grid centering: text exactly at circle center */
.circle-node-grid {
  display: grid;
  place-items: center;
  padding: 0;
  margin: 0;
}

.circle-node-inner {
  display: flex;
  justify-content: center;
  align-items: center;
  width: 100%;
  height: 100%;
  min-width: 0;
  min-height: 0;
  padding: 0;
  margin: 0;
  text-align: center;
}

.context-circle:hover {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  transform: scale(1.02);
}

.context-circle:active {
  cursor: grabbing;
}

.topic-circle {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  z-index: 10;
}

.topic-circle:hover {
  box-shadow: 0 6px 16px rgba(0, 0, 0, 0.2);
}
</style>
