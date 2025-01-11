defmodule WttjWeb.CandidateJSON do
  alias Wttj.Candidates.Candidate

  @doc """
  Renders a list of candidates.
  """
  def index(%{candidates: candidates}) do
    %{data: for(candidate <- candidates, do: data(candidate))}
  end

  @doc """
  Renders a single candidate.
  """
  def show(%{candidate: candidate}) do
    %{data: data(candidate)}
  end

  defp data(%Candidate{} = candidate) do
    %{
      id: candidate.id,
      email: candidate.email,
      status: candidate.status,
      position: candidate.position
    }
  end
end
