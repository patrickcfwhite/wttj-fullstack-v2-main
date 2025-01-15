import { DroppableStateSnapshot } from '@hello-pangea/dnd'

export const getBackgroundColor = (snapshot: DroppableStateSnapshot): string => {
  // Giving isDraggingOver preference
  if (snapshot.isDraggingOver) {
    return 'rgba(255, 204, 0, 0.25)'
  }

  // If it is the home list but not dragging over
  if (snapshot.draggingFromThisWith) {
    return 'rgba(68, 68, 68, 0.15)'
  }

  // Otherwise use our default background
  return 'white'
}
