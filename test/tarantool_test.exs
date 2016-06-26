defmodule TarantoolTest do
  use ExUnit.Case
  doctest Tarantool

  @test_port 3303

  setup_all do
    server = Port.open({:spawn, "tarantool test.lua"},
      [{:cd, "test"}, :binary, :use_stdio, :stderr_to_stdout]
    )
    proc = Port.info(server)[:os_pid]
    IO.puts "server: #{proc}"
    server |> wait_for_output(~r[ready to accept requests])
    on_exit fn ->
      System.cmd("kill",["#{proc}"])
    end
    :ok
  end

  setup do
    {:ok, t} = Tarantool.start_link("localhost", @test_port)
    {:ok, t: t}
  end

  defp wait_for_output(erl_port, pattern) do
    receive do
      {^erl_port, {:data, line}} ->
        unless Regex.match?(pattern, line), do:
          wait_for_output(erl_port, pattern)
    after 5000 ->
      raise "Timeout when waiting for tarantool status"
    end
  end

  test "ping", %{t: t}, do: assert {:ok, %{}} = Tarantool.Api.ping(t)

  test "auth with correct username and password", %{t: t} do
    assert {:ok, %{}} = Tarantool.Api.auth(t, %{username: "test", password: "t3st"})
  end

  test "auth with wrong username", %{t: t} do
    assert {:error, 32813, "User 'wrong' is not found"} =
      Tarantool.Api.auth(t, %{username: "wrong", password: "t3st"})
  end

  test "auth with wrong password", %{t: t} do
    assert {:error, 32815, "Incorrect password supplied for user 'test'"} =
      Tarantool.Api.auth(t, %{username: "test", password: "wrong"})
  end

  test "should select by pk", %{t: t} do
    assert {:ok, [[1, "hello", [1, 2], 100]]} =
      Tarantool.Api.select(t, %{space_id: 513, limit: 100, key: [1], index_id: nil, iterator: nil, offset: 0})
  end

  test "should select by secondary index", %{t: t} do
    assert {:ok, [[1, "hello", [1, 2], 100]] } =
    Tarantool.Api.select(t, %{space_id: 513, limit: 100, key: ["hello"],
      index_id: 1, iterator: nil, offset: 0})
  end

  test "should insert", %{t: t} do
    Tarantool.Api.insert(t, %{space_id: 513, tuple: [3, "wicky", [7,10], 300]})
    assert{:ok, [[3, "wicky", [7,10], 300]]} =
      Tarantool.Api.select(t, %{space_id: 513, limit: 100, key: [3], index_id: nil, iterator: nil, offset: 0})
  end

  test "should update", %{t: t} do
    Tarantool.Api.insert(t, %{space_id: 513, tuple: [4, "for_update", [7,10], 300]})
    Tarantool.Api.update(t, %{space_id: 513, index_id: nil, key: [4], tuple: [["+", 3, 1]] })
    assert {:ok, [[4, "for_update", [7, 10], 301]] } =
      Tarantool.Api.select(t, %{space_id: 513, limit: 100, key: [4],
      index_id: nil, iterator: nil, offset: 0})
  end

end
