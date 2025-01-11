defmodule Wttj.JobsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Wttj.Jobs` context.
  """

  @doc """
  Generate a job.
  """
  def job_fixture(attrs \\ %{}) do
    {:ok, job} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> Wttj.Jobs.create_job()

    job
  end
end
