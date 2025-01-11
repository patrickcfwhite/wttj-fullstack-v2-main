defmodule WttjWeb.CandidateControllerTest do
  use WttjWeb.ConnCase

  import Wttj.JobsFixtures
  import Wttj.CandidatesFixtures

  alias Wttj.Candidates.Candidate

  @update_attrs %{
    position: 43,
    status: :interview
  }
  @invalid_attrs %{position: nil, status: nil, email: nil}

  setup %{conn: conn} do
    job = job_fixture()
    {:ok, conn: put_req_header(conn, "accept", "application/json"), job: job}
  end

  describe "index" do
    test "lists all candidates", %{conn: conn, job: job} do
      conn = get(conn, ~p"/api/jobs/#{job}/candidates")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "update candidate" do
    setup [:create_candidate]

    test "renders candidate when data is valid", %{
      conn: conn,
      job: job,
      candidate: %Candidate{id: id} = candidate
    } do
      email = unique_user_email()
      attrs = Map.put(@update_attrs, :email, email)
      conn = put(conn, ~p"/api/jobs/#{job}/candidates/#{candidate}", candidate: attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/jobs/#{job}/candidates/#{id}")

      assert %{
               "id" => ^id,
               "email" => ^email,
               "position" => 43,
               "status" => "interview"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, candidate: candidate, job: job} do
      conn = put(conn, ~p"/api/jobs/#{job}/candidates/#{candidate}", candidate: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  defp create_candidate(%{job: job}) do
    candidate = candidate_fixture(%{job_id: job.id})
    %{candidate: candidate}
  end
end
