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

  ## Examples

      iex> update_candidate(candidate, %{field: new_value})
      {:ok, %Candidate{}}

      iex> update_candidate(candidate, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_candidate(%Candidate{} = candidate, attrs) do
    candidate_changeset = change_candidate(candidate, attrs)

    if candidate_changeset.changes == %{} do
      # No changes, return the existing candidate as is
      {:ok, candidate}
    else
      status_changed = Ecto.Changeset.changed?(candidate_changeset, :status)
      position_changed = Ecto.Changeset.changed?(candidate_changeset, :position)

      if status_changed or position_changed do
        # Ensure position and status are included in the changeset, even if they haven't changed
        candidate_changeset =
          if position_changed == true,
            do: candidate_changeset,
            else: Ecto.Changeset.force_change(candidate_changeset, :position, candidate.position)

        candidate_changeset =
          if status_changed == true,
            do: candidate_changeset,
            else: Ecto.Changeset.force_change(candidate_changeset, :status, candidate.status)

        reorder_candidates(candidate, candidate_changeset, status_changed)
      else
        Repo.update!(candidate_changeset)
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
          c.job_id == ^candidate.job_id and c.status == ^candidate.status and
            c.id != ^candidate.id
        )
        |> order_by([c], asc: c.position)
        |> Repo.all()


      current_status = if status_changed, do: :outgoing, else: :same

      new_status_candidates =
        if status_changed do
          from(c in Candidate)
          |> where([c], c.job_id == ^candidate.job_id and c.status == ^changeset.changes.status)
          |> order_by([c], asc: c.position)
          |> Repo.all()
        else
          []
        end

      updated_current_status_candidates =
        update_candidate_positions(current_status_candidates, candidate, changeset, current_status)

      updated_new_status_candidates =
        update_candidate_positions(new_status_candidates, candidate, changeset, :incoming)

      Repo.update!(Ecto.Changeset.change(candidate, position: -1))

      Repo.insert_all(Candidate, updated_current_status_candidates,
        on_conflict: :replace_all,
        conflict_target: [:id]
      )

      Repo.insert_all(Candidate, updated_new_status_candidates,
        on_conflict: :replace_all,
        conflict_target: [:id]
      )

      normalised_position =
        case current_status do
          :same ->
            if changeset.changes.position > length(current_status_candidates),
              do: length(current_status_candidates),
              else: changeset.changes.position

          :outgoing ->
            if changeset.changes.position > length(new_status_candidates),
              do: length(new_status_candidates),
              else: changeset.changes.position
        end

      final_changeset =
        changeset
        |> Ecto.Changeset.change(position: normalised_position)

      Repo.update!(final_changeset)
    end)
  end

  defp update_candidate_positions(static_candidates, %Candidate{} = changing_candidate, changeset, :same) do
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

  defp map_from_struct(records) do
    records
    |> Enum.map(fn record ->
      Map.from_struct(record)
      |> Map.drop([:__meta__])
    end)
  end
end
