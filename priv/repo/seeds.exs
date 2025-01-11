{:ok, job} = Wttj.Jobs.create_job(%{name: "Full Stack Developer"})

candidate =
  Wttj.Candidates.create_candidate(%{job_id: job.id, email: "user1@wttj.co", position: 0})

candidate =
  Wttj.Candidates.create_candidate(%{job_id: job.id, email: "user2@wttj.co", position: 1})

candidate =
  Wttj.Candidates.create_candidate(%{
    job_id: job.id,
    email: "user3@wttj.co",
    position: 0,
    status: :interview
  })

candidate =
  Wttj.Candidates.create_candidate(%{
    job_id: job.id,
    email: "user4@wttj.co",
    position: 0,
    status: :rejected
  })

candidate =
  Wttj.Candidates.create_candidate(%{
    job_id: job.id,
    email: "user5@wttj.co",
    position: 1,
    status: :rejected
  })
