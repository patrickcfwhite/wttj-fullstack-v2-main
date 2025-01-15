defmodule Wttj.Candidates do
  @moduledoc """
  The Candidates context.
  """

  import Ecto.Query, warn: false
  alias Wttj.Repo

  alias Wttj.Candidates.Candidate

  @doc """
  Returns the list of candidates.

  ## Examples

      iex> list_candidates()
      [%Candidate{}, ...]

  """
  def list_candidates(job_id) do
    query = from c in Candidate, where: c.job_id == ^job_id
    Repo.all(query)
  end

  @doc """
  Gets a single candidate.

  Raises `Ecto.NoResultsError` if the Candidate does not exist.

  ## Examples

      iex> get_candidate!(123)
      %Candidate{}

      iex> get_candidate!(456)
      ** (Ecto.NoResultsError)

  """
  def get_candidate!(job_id, id), do: Repo.get_by!(Candidate, id: id, job_id: job_id)

  @doc """
  Creates a candidate.

  ## Examples

      iex> create_candidate(%{field: value})
      {:ok, %Candidate{}}

      iex> create_candidate(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_candidate(attrs \\ %{}) do
    %Candidate{}
    |> Candidate.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a candidate.
  If position or status is changed it will also update any affected candidates requiring reordering of their position.

  ## Examples

      iex> update_candidate(candidate, %{field: new_value})
      {:ok, %Candidate{}}

      iex> update_candidate(candidate, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_candidate(%Candidate{} = candidate, attrs) do
    candidate_changeset = change_candidate(candidate, attrs)

    # Exit early if the changeset is invalid
    if not candidate_changeset.valid? do
      {:error, candidate_changeset}
    end

    if candidate_changeset.changes == %{} do
      {:ok, candidate}
    end

    status_changed = Ecto.Changeset.changed?(candidate_changeset, :status)
    position_changed = Ecto.Changeset.changed?(candidate_changeset, :position)

    # Ensure position and status are included in the changeset if they haven't changed
    candidate_changeset =
      if not position_changed do
        Ecto.Changeset.force_change(candidate_changeset, :position, candidate.position)
      else
        candidate_changeset
      end

    candidate_changeset =
      if not status_changed do
        Ecto.Changeset.force_change(candidate_changeset, :status, candidate.status)
      else
        candidate_changeset
      end

    if status_changed or position_changed do
      case reorder_candidates(candidate, candidate_changeset, status_changed) do
        {:ok, updated_candidate} ->
          {:ok, updated_candidate}

        {:error, error_changeset} ->
          {:error, error_changeset}
      end
    else
      Repo.update(candidate_changeset)
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking candidate changes.

  ## Examples

      iex> change_candidate(candidate)
      %Ecto.Changeset{data: %Candidate{}}

  """
  def change_candidate(%Candidate{} = candidate, attrs \\ %{}) do
    Candidate.changeset(candidate, attrs)
  end

  # Performs update of candidate and depending on change in position/status
  # will also perform reordering and update of any affected candidates
  defp reorder_candidates(
         %Candidate{} = candidate,
         changeset,
         status_changed
       ) do
    Repo.transaction(fn ->
      current_status_candidates =
        from(c in Candidate)
        |> where(
          [c],
          c.job_id == ^candidate.job_id and
            c.status == ^candidate.status and
            c.id != ^candidate.id
        )
        |> order_by([c], asc: c.position)
        |> Repo.all()

      current_status = if status_changed, do: :outgoing, else: :same

      new_status_candidates =
        if status_changed do
          from(c in Candidate)
          |> where(
            [c],
            c.job_id == ^candidate.job_id and
              c.status == ^changeset.changes.status
          )
          |> order_by([c], asc: c.position)
          |> Repo.all()
        else
          []
        end

      normalised_position =
        normalize_position(
          changeset.changes.position,
          if(current_status == :same, do: current_status_candidates, else: new_status_candidates)
        )

      final_changeset =
        changeset
        |> Ecto.Changeset.force_change(:position, normalised_position)

      updated_current_status_candidates =
        update_candidate_positions(
          current_status_candidates,
          candidate,
          final_changeset,
          current_status
        )

      updated_new_status_candidates =
        update_candidate_positions(new_status_candidates, candidate, final_changeset, :incoming)

      case Repo.update(Ecto.Changeset.change(candidate, position: -1)) do
        {:ok, _} ->
          :ok

        {:error, changeset} ->
          Repo.rollback({:error, changeset})
      end

      Repo.insert_all(Candidate, updated_current_status_candidates,
        on_conflict: :replace_all,
        conflict_target: [:id]
      )

      Repo.insert_all(Candidate, updated_new_status_candidates,
        on_conflict: :replace_all,
        conflict_target: [:id]
      )

      case Repo.update(final_changeset) do
        {:ok, updated_candidate} ->
          updated_candidate

        {:error, error_changeset} ->
          Repo.rollback({:error, error_changeset})
      end
    end)
  end

  # Returns affected candidates with updated positions
  # when candidate is only changing position but maintaining the same status
  defp update_candidate_positions(
         static_candidates,
         %Candidate{} = changing_candidate,
         changeset,
         :same
       ) do
    updated_candidates =
      Enum.map(static_candidates, fn static_candidate ->
        cond do
          # Case 1: Moving up
          changeset.changes.position > changing_candidate.position and
            static_candidate.position <= changeset.changes.position and
              static_candidate.position > changing_candidate.position ->
            %Candidate{static_candidate | position: static_candidate.position - 1}

          # Case 2: Moving down
          changeset.changes.position < changing_candidate.position and
            static_candidate.position >= changeset.changes.position and
              static_candidate.position < changing_candidate.position ->
            %Candidate{static_candidate | position: static_candidate.position + 1}

          true ->
            static_candidate
        end
      end)

    map_from_struct(updated_candidates)
  end

  # Returns affected candidates with updated positions when candidate is changing from shared status
  defp update_candidate_positions(
         static_candidates,
         %Candidate{} = changing_candidate,
         _changeset,
         :outgoing
       ) do
    updated_candidates =
      Enum.map(static_candidates, fn static_candidate ->
        if static_candidate.position > changing_candidate.position do
          %Candidate{static_candidate | position: static_candidate.position - 1}
        else
          static_candidate
        end
      end)

    map_from_struct(updated_candidates)
  end

  # Returns affected candidates with updated positions when candidate is joining shared status
  defp update_candidate_positions(
         static_candidates,
         %Candidate{} = _incoming_candidate,
         changeset,
         :incoming
       ) do
    updated_candidates =
      Enum.map(static_candidates, fn static_candidate ->
        if static_candidate.position >= changeset.changes.position do
          %Candidate{static_candidate | position: static_candidate.position + 1}
        else
          static_candidate
        end
      end)

    map_from_struct(updated_candidates)
  end

  # Cap the position to the valid range of 0 to the length of the candidates
  defp normalize_position(position, candidates) do
    cond do
      position < 0 -> 0
      position > length(candidates) -> length(candidates)
      true -> position
    end
  end

  # Converts a list of modified structs into a list of maps, ready for bulk insertion into the repository.
  defp map_from_struct(records) do
    records
    |> Enum.map(fn record ->
      Map.from_struct(record)
      |> Map.drop([:__meta__])
    end)
  end
end
