import { Card } from '@welcome-ui/card'
import { Candidate } from '../../api'
import { Draggable } from '@hello-pangea/dnd'

const DraggableContainer = ({
  index,
  draggableId,
  children,
}: {
  index: number
  draggableId: string
  children: React.ReactNode
}) => {
  return (
    <Draggable index={index} draggableId={draggableId}>
      {provided => (
        <div ref={provided.innerRef} {...provided.draggableProps} {...provided.dragHandleProps}>
          {children}
        </div>
      )}
    </Draggable>
  )
}

export const CandidateCard = ({ candidate }: { candidate: Candidate }) => {
  return (
    <Card mb={6}>
      <Card.Body>{candidate.email}</Card.Body>
    </Card>
  )
}

export const DraggableCard = ({ candidate, index }: { candidate: Candidate; index: number }) => {
  return (
    <DraggableContainer index={index} draggableId={`${candidate.id}`}>
      <CandidateCard candidate={candidate} />
    </DraggableContainer>
  )
}
