import { useQuery, useQueryClient, useMutation } from 'react-query'
import {
  Candidate,
  getCandidates,
  getJob,
  getJobs,
  KanbanStatus,
  KANBAN_STATUSES,
  updateCandidate as updateCandidateApiCall,
} from '../api'
import { assertIsKanbanStatus } from '../utilities/assertIsKanbanStatus'
import { reorderCards } from '../utilities/reorderCards'
import _ from 'lodash'
import { DragUpdate, DropResult } from '@hello-pangea/dnd'
import { useContext, useEffect, useMemo, useState } from 'react'
import { PhoenixContext } from '../providers/PhoenixWebsocketProvider'
import { Channel } from 'phoenix'

export const useJobs = () => {
  const { isLoading, error, data } = useQuery({
    queryKey: ['jobs'],
    queryFn: getJobs,
  })

  return { isLoading, error, jobs: data }
}

export const useJob = (jobId?: string) => {
  const { isLoading, error, data } = useQuery({
    queryKey: ['job', jobId],
    queryFn: () => getJob(jobId),
    enabled: !!jobId,
  })

  return { isLoading, error, job: data }
}

export const useCandidates = (jobId?: string) => {
  const { isLoading, error, data } = useQuery({
    queryKey: ['candidates', jobId],
    queryFn: () => getCandidates(jobId),
    enabled: !!jobId,
  })

  return { isLoading, error, candidates: data }
}

export const useUpdateCandidates = () => {
  const client = useQueryClient()

  const {
    mutate: updateCandidate,
    isLoading,
    error,
    data,
  } = useMutation({
    mutationFn: ({ jobId, candidate }: { jobId: string; candidate: Candidate }) =>
      updateCandidateApiCall(jobId, candidate),
    onSuccess: (_data, { jobId }) => client.invalidateQueries(['candidates', jobId]),
  })

  return { updateCandidate, isLoading, error, data }
}

export const useDragHandlers = ({
  jobId,
  candidates,
  sortedCandidates,
}: {
  jobId?: string
  candidates?: Candidate[]
  sortedCandidates: Record<KanbanStatus, Candidate[]>
}) => {
  const queryClient = useQueryClient()
  const { updateCandidate } = useUpdateCandidates()

  const handleDragUpdate = ({ destination, draggableId }: DragUpdate): void => {
    if (!destination || !jobId) return

    const candidate = candidates?.find(c => c.id === Number(draggableId))
    if (!candidate) return

    const isSameLocation =
      candidate.status === destination.droppableId && candidate.position === destination.index

    if (isSameLocation) return

    const sourceStatus = candidate.status
    const destinationStatus = destination.droppableId

    assertIsKanbanStatus(sourceStatus)
    assertIsKanbanStatus(destinationStatus)

    queryClient.setQueryData<Candidate[]>(['candidates', jobId], existing => {
      const currentCards =
        sourceStatus === destinationStatus
          ? reorderCards(candidate, destination.index, sortedCandidates[sourceStatus], 'same')
          : reorderCards(
              candidate,
              destination.index,
              sortedCandidates[sourceStatus].filter(c => c.id !== candidate.id),
              'outgoing'
            )

      const newCards =
        sourceStatus === destinationStatus
          ? []
          : _.uniqBy(
              reorderCards(
                candidate,
                destination.index,
                [...sortedCandidates[destinationStatus], candidate],
                'incoming',
                destinationStatus
              ),
              'id'
            )

      const nonAffectedCards = (existing ?? []).filter(
        c => ![sourceStatus, destinationStatus].includes(c.status)
      )

      return [...nonAffectedCards, ...currentCards, ...newCards]
    })
  }

  const handleDraggedCandidate = (result: DropResult) => {
    const { destination, draggableId } = result

    if (!jobId || !destination || !candidates) return

    const candidate = candidates.find(c => c.id === Number(draggableId))
    if (!candidate) return

    const destinationStatus = destination.droppableId

    assertIsKanbanStatus(destinationStatus)

    const updatedCandidate = {
      ...candidate,
      position: destination.index,
      status: destinationStatus,
    }

    updateCandidate({ jobId, candidate: updatedCandidate })
  }

  return { handleDragUpdate, handleDraggedCandidate }
}

export const useSortedCandidates = (candidates?: Candidate[]) => {
  return useMemo(() => {
    if (!candidates) return { new: [], rejected: [], hired: [], interview: [] }

    return KANBAN_STATUSES.reduce<Record<KanbanStatus, Candidate[]>>(
      (acc, status) => {
        acc[status] = candidates
          .filter(c => c.status === status)
          .sort((a, b) => a.position - b.position)
        return acc
      },
      { new: [], rejected: [], hired: [], interview: [] }
    )
  }, [candidates])
}

export const useChannel = (channelName: string) => {
  const [channel, setChannel] = useState<Channel>()
  const { websocket } = useContext(PhoenixContext)

  useEffect(() => {
    if (!websocket) return
    const phoenixChannel = websocket.channel(channelName)

    phoenixChannel.join().receive('ok', () => {
      setChannel(phoenixChannel)
    })

    return () => {
      phoenixChannel.leave()
    }
  }, [])

  return [channel]
}
