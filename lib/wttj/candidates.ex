defmodule Wttj.Candidates do
  @moduledoc """
  The Candidates context.
  """

  import Ecto.Query, warn: false
  alias Wttj.Repo

  alias Wttj.Candidates.Candidate
  alias WttjWeb.Endpoint

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
    |> case do
      {:ok, candidate} ->
        Endpoint.broadcast("candidate:#{candidate.job_id}", "candidate_created", %{
          candidate: candidate
        })

        {:ok, candidate}

      {:error, changeset} ->
        {:error, changeset}
    end
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
  def update_candidate(%Candidate{} = candidate, attrs, retries \\ 3) do
    try do
      Repo.transaction(fn ->
        changeset = Candidate.changeset(candidate, attrs)

        if not changeset.valid? do
          Repo.rollback(changeset)
        end

        status_changed = Ecto.Changeset.changed?(changeset, :status)
        position_changed = Ecto.Changeset.changed?(changeset, :position)

        # Force position only if status changed but position hasn't
        changeset =
          if status_changed and not position_changed do
            Ecto.Changeset.force_change(changeset, :position, candidate.position)
          else
            changeset
          end

        if not (status_changed or position_changed) do
          case Repo.update(changeset) do
            {:ok, updated_candidate} -> updated_candidate
            {:error, error_changeset} -> Repo.rollback(error_changeset)
          end
        else
          reorder_candidates(candidate, changeset, status_changed)
        end
      end)
      |> case do
        {:ok, updated_candidate} ->
          Endpoint.broadcast("candidate:#{updated_candidate.job_id}", "candidate_updated", %{
            candidate: updated_candidate
          })

          {:ok, updated_candidate}

        {:error, reason} ->
          {:error, reason}
      end
    rescue
      Postgrex.Error ->
        if retries > 0 do
          update_candidate(candidate, attrs, retries - 1)
        else
          {:error, "Failed to update candidate due to repeated deadlocks"}
        end
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
         %Candidate{} = original_candidate,
         changeset,
         status_changed
       ) do
    candidate =
      from(c in Candidate, where: c.id == ^original_candidate.id)
      |> lock("FOR UPDATE")
      |> Repo.one!()

    current_status_candidates =
      from(c in Candidate)
      |> where(
        [c],
        c.job_id == ^candidate.job_id and
          c.status == ^candidate.status and
          c.id != ^candidate.id
      )
      |> order_by([c], asc: c.position)
      |> lock("FOR UPDATE")
      |> Repo.all()

    new_status_candidates =
      if status_changed do
        from(c in Candidate)
        |> where(
          [c],
          c.job_id == ^candidate.job_id and
            c.status == ^changeset.changes.status and
            c.id != ^candidate.id
        )
        |> order_by([c], asc: c.position)
        |> lock("FOR UPDATE")
        |> Repo.all()
      else
        []
      end

    candidates_to_determine_normalized_position =
      if status_changed, do: new_status_candidates, else: current_status_candidates

    normalized_position =
      normalize_position(changeset.changes.position, candidates_to_determine_normalized_position)

    final_changeset =
      changeset
      |> Ecto.Changeset.force_change(:position, normalized_position)

    direction =
      cond do
        status_changed -> :status_changed
        normalized_position < candidate.position -> :down
        true -> :up
      end

    # Reorder candidates based on direction to handle
    reordered_candidates_current =
      case direction do
        :up -> current_status_candidates
        :down -> Enum.sort_by(current_status_candidates, & &1.position, :desc)
        :status_changed -> current_status_candidates
      end

    reordered_candidates_new = Enum.sort_by(new_status_candidates, & &1.position, :desc)

    # Temporarily set the candidate's position to -1
    Repo.update!(Ecto.Changeset.change(candidate, position: -1))

    updated_current_status_candidates =
      update_candidate_positions(
        reordered_candidates_current,
        candidate,
        final_changeset,
        if(status_changed, do: :outgoing, else: :same)
      )

    updated_new_status_candidates =
      if status_changed do
        update_candidate_positions(
          reordered_candidates_new,
          candidate,
          final_changeset,
          :incoming
        )
      else
        []
      end

    bulk_update_candidates(updated_current_status_candidates)
    bulk_update_candidates(updated_new_status_candidates)

    case Repo.update(final_changeset) do
      {:ok, updated_candidate} ->
        updated_candidate

      {:error, error_changeset} ->
        Repo.rollback(error_changeset)
    end
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

  # Converts a list of modified structs into a list of maps, ready for bulk insertion into the repository
  defp map_from_struct(records) do
    records
    |> Enum.map(fn record ->
      Map.from_struct(record)
      |> Map.drop([:__meta__])
    end)
  end

  # Helper function to bulk insert candidates into the repository
  defp bulk_update_candidates(candidates) do
    if candidates != [] do
      case Repo.insert_all(Candidate, candidates,
             on_conflict: :replace_all,
             conflict_target: [:id]
           ) do
        {count, _} when count > 0 ->
          :ok

        {0, _} ->
          Repo.rollback("No rows were updated. Unexpected result in bulk update.")

        unexpected_response ->
          Repo.rollback(
            "Unexpected response from Repo.insert_all: #{inspect(unexpected_response)}"
          )
      end
    else
      :ok
    end
  end
end
