defmodule Wttj.CandidatesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Wttj.Candidates` context.
  """

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"

  @doc """
  Generate a candidate.
  """
  def candidate_fixture(attrs \\ %{}) do
    {:ok, candidate} =
      attrs
      |> Enum.into(%{
        email: unique_user_email(),
        position: 42
      })
      |> Wttj.Candidates.create_candidate()

    candidate
  end
end
