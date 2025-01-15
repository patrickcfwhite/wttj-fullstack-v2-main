import { Candidate, KanbanStatus } from '../api'

export type CardMovement = 'same' | 'incoming' | 'outgoing'

export const reorderCards = (
  candidate: Candidate,
  newIndex: number,
  candidateList: Candidate[],
  movement: CardMovement,
  newStatus?: KanbanStatus
) => {
  return candidateList.map(c => {
    if (movement === 'same') {
      const directionOffset = newIndex > candidate.position ? 'increase' : 'decrease'

      if (c.id === candidate.id) {
        return { ...c, position: newIndex }
      }

      if (directionOffset === 'increase') {
        return c.position > candidate.position && newIndex >= c.position
          ? { ...c, position: c.position - 1 }
          : c
      } else {
        return c.position < candidate.position && newIndex <= c.position
          ? { ...c, position: c.position + 1 }
          : c
      }
    } else if (movement === 'outgoing') {
      return c.position > newIndex ? { ...c, position: c.position - 1 } : c
    } else {
      if (c.id === candidate.id && newStatus) {
        return { ...c, position: newIndex, status: newStatus }
      }
      return c.position >= newIndex ? { ...c, position: c.position + 1 } : c
    }
  })
}
