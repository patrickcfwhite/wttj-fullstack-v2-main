defmodule WttjWeb.CandidateChannelTest do
  use WttjWeb.ChannelCase

  setup do
    {:ok, _, socket} =
      WttjWeb.UserSocket
      |> socket("user_id", %{some: :assign})
      |> subscribe_and_join(WttjWeb.CandidateChannel, "candidate:lobby")

    %{socket: socket}
  end

  test "joins candidates:lobby successfully", %{socket: socket} do
    {:ok, reply, _socket} = subscribe_and_join(socket, "candidate:lobby", %{})
    assert reply == %{}
  end

  test "ping replies with status ok", %{socket: socket} do
    ref = push(socket, "ping", %{"hello" => "there"})
    assert_reply ref, :ok, %{"hello" => "there"}
  end

  test "shout broadcasts to candidate:lobby", %{socket: socket} do
    push(socket, "shout", %{"hello" => "all"})
    assert_broadcast "shout", %{"hello" => "all"}
  end

  test "broadcasts are pushed to the client", %{socket: socket} do
    broadcast_from!(socket, "broadcast", %{"some" => "data"})
    assert_push "broadcast", %{"some" => "data"}
  end

  test "broadcasts new candidate on candidate_created", %{socket: socket} do
    push(socket, "candidate_created", %{candidate: %{id: 1, name: "John Doe"}})

    assert_broadcast("candidate_created", %{candidate: %{"id" => 1, "name" => "John Doe"}})
  end

  test "broadcasts updated candidate on candidate_updated", %{socket: socket} do
    push(socket, "candidate_updated", %{candidate: %{id: 1, name: "John Doe"}})

    assert_broadcast("candidate_updated", %{candidate: %{"id" => 1, "name" => "John Doe"}})
  end
end
