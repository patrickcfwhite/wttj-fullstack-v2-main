import { Card } from '@welcome-ui/card'
import { Candidate } from '../../api'

function CandidateCard({ candidate }: { candidate: Candidate }) {
  return (
    <Card mb={10}>
      <Card.Body>{candidate.email}</Card.Body>
    </Card>
  )
}

export default CandidateCard
