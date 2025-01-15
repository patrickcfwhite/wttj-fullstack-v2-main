// components/KanbanColumn.tsx
import { Flex } from '@welcome-ui/flex'
import { Box } from '@welcome-ui/box'
import { Text } from '@welcome-ui/text'
import { Badge } from '@welcome-ui/badge'
import { Droppable } from '@hello-pangea/dnd'
import { getBackgroundColor } from '../../utilities/getDragDropStyling'
import { DraggableCard } from '../Candidate'
import { Candidate, KanbanStatus } from '../../api'

interface KanbanColumnProps {
  column: KanbanStatus
  candidates: Candidate[]
}

export const KanbanColumn = ({ column, candidates }: KanbanColumnProps) => (
  <Box
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
      <Badge>{candidates.length}</Badge>
    </Flex>
    <Droppable droppableId={column}>
      {(provided, snapshot) => (
        <Flex
          direction="column"
          {...provided.droppableProps}
          bg={getBackgroundColor(snapshot)}
          style={{ transition: 'background-color 200ms linear' }}
          ref={provided.innerRef}
          p={10}
          pb={0}
          minHeight="100%"
        >
          {candidates.map((candidate, index) => (
            <DraggableCard key={candidate.id} candidate={candidate} index={index} />
          ))}
          {provided.placeholder}
        </Flex>
      )}
    </Droppable>
  </Box>
)
