import { render, screen, fireEvent } from '@testing-library/react'
import { vi, describe, test, expect, beforeEach } from 'vitest'
import JobShow from '.'
import { useCandidates, useJob, useUpdateCandidates } from '../../hooks'
import { QueryClient, QueryClientProvider } from 'react-query'
import { Candidate } from '../../api'

vi.mock('../../hooks', () => ({
  useCandidates: vi.fn(),
  useJob: vi.fn(),
  useUpdateCandidates: vi.fn(),
}))

describe('JobShow', () => {
  const queryClient = new QueryClient()
  const jobId = '123'
  const mockUpdateCandidates = vi.fn()

  beforeEach(() => {
    vi.clearAllMocks()
    vi.mocked(useJob).mockReturnValue({
      isLoading: false,
      error: undefined,
      job: { id: jobId, name: 'Test Job' },
    })
    vi.mocked(useCandidates).mockReturnValue({
      isLoading: false,
      error: undefined,
      candidates: [
        { id: 1, email: 'candidate1@job.co', status: 'new', position: 0 },
        { id: 2, email: 'candidate2@job.co', status: 'new', position: 1 },
        { id: 3, email: 'candidate3@job.co', status: 'new', position: 2 },
      ],
    })
    vi.mocked(useUpdateCandidates).mockReturnValue({
      updateCandidate: mockUpdateCandidates,
      data: {} as unknown as Candidate,
      isLoading: false,
      error: undefined,
    })

    queryClient.setQueryData = vi.fn()
  })

  test('renders columns and candidates correctly', () => {
    render(
      <QueryClientProvider client={queryClient}>
        <JobShow />
      </QueryClientProvider>
    )

    expect(screen.getByText('Test Job')).toBeInTheDocument()
    expect(screen.getByText('new')).toBeInTheDocument()
    expect(screen.getByText('interview')).toBeInTheDocument()
    expect(screen.getByText('candidate1@job.co')).toBeInTheDocument()
    expect(screen.getByText('candidate2@job.co')).toBeInTheDocument()
  })

  test('handles drag-and-drop updates', async () => {
    render(
      <QueryClientProvider client={queryClient}>
        <JobShow />
      </QueryClientProvider>
    )

    const draggableItem = screen.getByText('candidate1@job.co').closest('[data-rfd-draggable-id]')!
    const droppableArea = screen.getByText('interview')

    fireEvent.dragStart(draggableItem)
    fireEvent.dragEnter(droppableArea)
    fireEvent.dragOver(droppableArea)
    fireEvent.drop(droppableArea)
    fireEvent.dragEnd(draggableItem)

    // Verify the query cache was updated
    expect(queryClient.setQueryData).toHaveBeenCalledWith(['candidates', jobId], expect.anything())

    // Verify that the API call was made with updated data
    expect(mockUpdateCandidates).toHaveBeenCalledWith({
      jobId,
      candidate: {
        id: 1,
        position: 0,
        status: 'interview',
      },
    })
  })
})
