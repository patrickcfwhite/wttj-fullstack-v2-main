defmodule Wttj.CandidatesTest do
  use Wttj.DataCase

  alias Wttj.Candidates
  import Wttj.JobsFixtures

  setup do
    job1 = job_fixture()
    job2 = job_fixture()
    {:ok, job1: job1, job2: job2}
  end

  describe "candidates" do
    alias Wttj.Candidates.Candidate

    import Wttj.CandidatesFixtures

    @invalid_attrs %{position: nil, status: nil, email: nil}

    test "list_candidates/1 returns all candidates for a given job", %{job1: job1, job2: job2} do
      candidate1 = candidate_fixture(%{job_id: job1.id})
      _ = candidate_fixture(%{job_id: job2.id})
      assert Candidates.list_candidates(job1.id) == [candidate1]
    end

    test "create_candidate/1 with valid data creates a candidate", %{job1: job1} do
      email = unique_user_email()
      valid_attrs = %{email: email, position: 3, job_id: job1.id}
      assert {:ok, %Candidate{} = candidate} = Candidates.create_candidate(valid_attrs)
      assert candidate.email == email
      assert {:error, _} = Candidates.create_candidate()
    end

    test "update_candidate/2 with valid data updates the candidate", %{job1: job1} do
      candidate = candidate_fixture(%{job_id: job1.id})
      email = unique_user_email()
      update_attrs = %{position: 43, status: :rejected, email: email}

      assert {:ok, %Candidate{} = candidate} =
               Candidates.update_candidate(candidate, update_attrs)

      # As this is the only candidate the position is normalised
      assert candidate.position == 0
      assert candidate.status == :rejected
      assert candidate.email == email
    end

    test "update_candidate/2 with invalid data returns error changeset", %{job1: job1} do
      candidate = candidate_fixture(%{job_id: job1.id})
      assert {:error, %Ecto.Changeset{}} = Candidates.update_candidate(candidate, @invalid_attrs)
      assert candidate == Candidates.get_candidate!(job1.id, candidate.id)
    end

    test "change_candidate/1 returns a candidate changeset", %{job1: job1} do
      candidate = candidate_fixture(%{job_id: job1.id})
      assert %Ecto.Changeset{} = Candidates.change_candidate(candidate)
    end

    test "update_candidate/2 adjusts all candidate positions when decreasing position", %{
      job1: job1
    } do
      candidate_one = candidate_fixture(%{job_id: job1.id, status: :new, position: 0})
      candidate_two = candidate_fixture(%{job_id: job1.id, status: :new, position: 1})
      candidate_three = candidate_fixture(%{job_id: job1.id, status: :new, position: 2})

      assert {:ok, updated_candidate} =
               Candidates.update_candidate(candidate_three, %{position: 0})

      updated_candidates = job1.id |> Candidates.list_candidates() |> Enum.sort_by(& &1.position)

      assert Enum.at(updated_candidates, 0).id == candidate_three.id
      assert Enum.at(updated_candidates, 1).id == candidate_one.id
      assert Enum.at(updated_candidates, 2).id == candidate_two.id
    end

    test "update_candidate/2 adjusts all candidate positions when increasing position", %{
      job1: job1
    } do
      candidate_one = candidate_fixture(%{job_id: job1.id, status: :new, position: 0})
      candidate_two = candidate_fixture(%{job_id: job1.id, status: :new, position: 1})
      candidate_three = candidate_fixture(%{job_id: job1.id, status: :new, position: 2})

      assert {:ok, updated_candidate} = Candidates.update_candidate(candidate_one, %{position: 2})

      updated_candidates = job1.id |> Candidates.list_candidates() |> Enum.sort_by(& &1.position)

      assert Enum.at(updated_candidates, 0).id == candidate_two.id
      assert Enum.at(updated_candidates, 1).id == candidate_three.id
      assert Enum.at(updated_candidates, 2).id == candidate_one.id
    end

    test "update_candidate/2 adjusts candidate positions when moving to middle", %{job1: job1} do
      candidate_one = candidate_fixture(%{job_id: job1.id, status: :new, position: 0})
      candidate_two = candidate_fixture(%{job_id: job1.id, status: :new, position: 1})
      candidate_three = candidate_fixture(%{job_id: job1.id, status: :new, position: 2})

      assert {:ok, updated_candidate} = Candidates.update_candidate(candidate_one, %{position: 1})

      updated_candidates = job1.id |> Candidates.list_candidates() |> Enum.sort_by(& &1.position)

      assert Enum.at(updated_candidates, 0).id == candidate_two.id
      assert Enum.at(updated_candidates, 1).id == candidate_one.id
      assert Enum.at(updated_candidates, 2).id == candidate_three.id
    end

    test "update_candidate/2 handles change of position in new status group", %{job1: job1} do
      candidate_one = candidate_fixture(%{job_id: job1.id, status: :new, position: 0})
      candidate_two = candidate_fixture(%{job_id: job1.id, status: :interview, position: 0})
      candidate_three = candidate_fixture(%{job_id: job1.id, status: :interview, position: 1})

      assert {:ok, updated_candidate} =
               Candidates.update_candidate(candidate_one, %{position: 1, status: :interview})

      updated_candidates = job1.id |> Candidates.list_candidates() |> Enum.sort_by(& &1.position)

      assert updated_candidate.status == :interview

      assert Enum.at(updated_candidates, 0).id == candidate_two.id
      assert Enum.at(updated_candidates, 1).id == candidate_one.id
      assert Enum.at(updated_candidates, 2).id == candidate_three.id
    end

    test "update_candidate/2 enforces valid position bounding", %{job1: job1} do
      candidate_one = candidate_fixture(%{job_id: job1.id, status: :new, position: 0})
      candidate_two = candidate_fixture(%{job_id: job1.id, status: :new, position: 1})

      candidate_fixture(%{job_id: job1.id, status: :interview, position: 0})
      candidate_fixture(%{job_id: job1.id, status: :interview, position: 1})

      candidate_fixture(%{job_id: job1.id, status: :rejected, position: 0})
      candidate_fixture(%{job_id: job1.id, status: :rejected, position: 1})

      assert {:ok, updated_candidate_one} =
               Candidates.update_candidate(candidate_one, %{status: :interview, position: -10})

      assert updated_candidate_one.position == 0

      assert {:ok, updated_candidate_two} =
               Candidates.update_candidate(candidate_two, %{status: :rejected, position: 20})

      assert updated_candidate_two.position == 2
    end
  end
end
