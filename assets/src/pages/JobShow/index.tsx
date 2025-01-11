import { useParams } from 'react-router-dom'
import { useJob, useCandidates } from '../../hooks'
import { Text } from '@welcome-ui/text'
import { Flex } from '@welcome-ui/flex'
import { Box } from '@welcome-ui/box'
import { useMemo } from 'react'
import { Candidate } from '../../api'
import CandidateCard from '../../components/Candidate'
import { Badge } from '@welcome-ui/badge'
import { DragDropContext, Droppable, DropResult } from '@hello-pangea/dnd'

type Statuses = 'new' | 'interview' | 'hired' | 'rejected'
const COLUMNS: Statuses[] = ['new', 'interview', 'hired', 'rejected']

interface SortedCandidates {
  new?: Candidate[]
  interview?: Candidate[]
  hired?: Candidate[]
  rejected?: Candidate[]
}

function JobShow() {
  const { jobId } = useParams()
  const { job } = useJob(jobId)
  const { candidates } = useCandidates(jobId)

  const sortedCandidates = useMemo(() => {
    if (!candidates) return {}

    return candidates.reduce<SortedCandidates>((acc, c: Candidate) => {
      acc[c.status] = [...(acc[c.status] || []), c].sort((a, b) => a.position - b.position)
      return acc
    }, {})
  }, [candidates])

  const handleDraggedCandidate = (result: DropResult) => {
    const { source, destination } = result

    if (!destination) return

    const isSameLocation =
      source.droppableId === destination.droppableId && source.index === destination.index

    if (!isSameLocation) {
      // Implement backend changes
      console.log('update db')
    }
  }

  return (
    <>
      <Box backgroundColor="neutral-70" p={20} alignItems="center">
        <Text variant="h5" color="white" m={0}>
          {job?.name}
        </Text>
      </Box>

      <DragDropContext onDragEnd={handleDraggedCandidate}>
        <Box p={20}>
          <Flex gap={10}>
            {COLUMNS.map(column => (
              <Box
                key={column}
                w={300}
                border={1}
                backgroundColor="white"
                borderColor="neutral-30"
                borderRadius="md"
                overflow="hidden"
              >
                <Flex
                  p={10}
                  borderBottom={1}
                  borderColor="neutral-30"
                  alignItems="center"
                  justify="space-between"
                >
                  <Text color="black" m={0} textTransform="capitalize">
                    {column}
                  </Text>
                  <Badge>{(sortedCandidates[column] || []).length}</Badge>
                </Flex>
                <Droppable key={column} droppableId={column}>
                  {(
                    provided
                    // once functional we can use second provided argument snapshot to update style when dragging
                  ) => (
                    <Flex
                      direction="column"
                      {...provided.droppableProps}
                      ref={provided.innerRef}
                      p={10}
                      pb={0}
                    >
                      {sortedCandidates[column]?.map((candidate, index) => (
                        <CandidateCard index={index} key={candidate.id} candidate={candidate} />
                      ))}
                      {provided.placeholder}
                    </Flex>
                  )}
                </Droppable>
              </Box>
            ))}
          </Flex>
        </Box>
      </DragDropContext>
    </>
  )
}

export default JobShow
