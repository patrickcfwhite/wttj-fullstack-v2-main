import { KanbanStatus, KANBAN_STATUSES } from '../api/index'

export const isKanbanStatus = (status: string): status is KanbanStatus => {
  return KANBAN_STATUSES.includes(status as KanbanStatus)
}

export function assertIsKanbanStatus(status: string): asserts status is KanbanStatus {
  if (!isKanbanStatus(status)) {
    throw new Error('Unrecognised kanban status')
  }
}
