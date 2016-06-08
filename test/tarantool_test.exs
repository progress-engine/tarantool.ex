defmodule TarantoolTest do
  use ExUnit.Case
  doctest Tarantool

  @test_port 3303

  setup_all do
    server = Port.open({:spawn, "tarantool test.lua"},
      [{:cd, "test"}, :binary, :use_stdio, :stderr_to_stdout]
    )
    proc = Port.info(server)[:os_pid]
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

  test "auth with correct username and password", %{t: t}, do: assert {:ok, %{}} = Tarantool.Api.auth(t, %{username: "test", password: "t3st"})
  test "auth with wrong username", %{t: t}, do: assert {:error, 32813, "User 'wrong' is not found"} = Tarantool.Api.auth(t, %{username: "wrong", password: "t3st"})
  test "auth with wrong password", %{t: t}, do: assert {:error, 32815, "Incorrect password supplied for user 'test'"} = Tarantool.Api.auth(t, %{username: "test", password: "wrong"})
end
