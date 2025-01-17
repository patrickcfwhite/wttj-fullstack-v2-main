type Job = {
  id: string
  name: string
}

export type Candidate = {
  id: number
  email: string
  status: KanbanStatus
  position: number
}

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:4000/api'

export const KANBAN_STATUSES = ['new', 'interview', 'hired', 'rejected'] as const

export type KanbanStatus = (typeof KANBAN_STATUSES)[number]

export const getJobs = async (): Promise<Job[]> => {
  const response = await fetch(`${API_BASE_URL}/jobs`)
  const { data } = await response.json()
  return data
}

export const getJob = async (jobId?: string): Promise<Job | null> => {
  if (!jobId) return null
  const response = await fetch(`${API_BASE_URL}/jobs/${jobId}`)
  const { data } = await response.json()
  return data
}

export const getCandidates = async (jobId?: string): Promise<Candidate[]> => {
  if (!jobId) return []
  const response = await fetch(`${API_BASE_URL}/jobs/${jobId}/candidates`)
  const res = await response.json()
  return res.data
}

export const updateCandidate = async (jobId: string, candidate: Candidate): Promise<Candidate> => {
  console.log({ jobId, candidate })
  const response = await fetch(`${API_BASE_URL}/jobs/${jobId}/candidates/${candidate.id}`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      candidate,
    }),
  })

  const { data } = await response.json()

  return data
}
