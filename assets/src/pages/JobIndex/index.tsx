import { Link as RouterLink } from 'react-router-dom'
import { useJobs } from '../../hooks'
import { Link } from '@welcome-ui/link'

function JobIndex() {
  const { isLoading, jobs } = useJobs()

  if (isLoading) {
    return null
  }

  return (
    <ul>
      {jobs?.map(job => (
        <li>
          <Link as={RouterLink} to={`/jobs/${job.id}`}>
            {job.name}
          </Link>
        </li>
      ))}
    </ul>
  )
}

export default JobIndex
