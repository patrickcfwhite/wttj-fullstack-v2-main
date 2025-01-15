import { useParams } from 'react-router-dom'
import { Flex } from '@welcome-ui/flex'
import { Box } from '@welcome-ui/box'
import { Text } from '@welcome-ui/text'
import { DragDropContext } from '@hello-pangea/dnd'
import {
  useJob,
  useCandidates,
  useDragHandlers,
  useSortedCandidates,
  useChannel,
} from '../../hooks'
import { KanbanColumn } from '../../components/KanbanColumn'
import { KANBAN_STATUSES } from '../../api'
import { useEffect } from 'react'
import { useQueryClient } from 'react-query'

function JobShow() {
  const { jobId } = useParams()
  const { job } = useJob(jobId)
  const { candidates } = useCandidates(jobId)
  const sortedCandidates = useSortedCandidates(candidates)
  const queryClient = useQueryClient()
  const [jobCandidatesChannel] = useChannel(`candidate:${jobId}`)
  const { handleDragUpdate, handleDraggedCandidate } = useDragHandlers({
    jobId,
    candidates,
    sortedCandidates,
  })

  useEffect(() => {
    if (!jobCandidatesChannel || !queryClient || !jobId) return

    jobCandidatesChannel.on('candidate_updated', _updatedCandidate => {
      queryClient.invalidateQueries(['candidates', jobId])
    })
    return () => {
      jobCandidatesChannel.off('candidate_updated')
    }
  }, [jobCandidatesChannel, candidates, jobId, queryClient])

  return (
    <>
      <Box backgroundColor="neutral-70" p={20} alignItems="center">
        <Text variant="h5" color="white" m={0}>
          {job?.name}
        </Text>
      </Box>

      <DragDropContext onDragUpdate={handleDragUpdate} onDragEnd={handleDraggedCandidate}>
        <Box p={20}>
          <Flex gap={10} wrap="wrap">
            {KANBAN_STATUSES.map(column => (
              <KanbanColumn key={column} column={column} candidates={sortedCandidates[column]} />
            ))}
          </Flex>
        </Box>
      </DragDropContext>
    </>
  )
}

export default JobShow
