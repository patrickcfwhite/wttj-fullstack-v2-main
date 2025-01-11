import { Card } from '@welcome-ui/card'
import { Candidate } from '../../api'
import { Draggable } from '@hello-pangea/dnd'

function CandidateCard({ candidate, index }: { candidate: Candidate; index: number }) {
  return (
    <Draggable index={index} draggableId={candidate.email}>
      {(
        provided
        // once functional we can use second provided argument snapshot to update style when dragging
      ) => (
        <Card
          ref={provided.innerRef}
          {...provided.draggableProps}
          {...provided.dragHandleProps}
          mb={10}
        >
          <Card.Body>{candidate.email}</Card.Body>
        </Card>
      )}
    </Draggable>
  )
}

export default CandidateCard
