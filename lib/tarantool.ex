
defmodule Tarantool do
  @moduledoc """
  Tarantool client for Elixir
  """

  use Connection
  use Tarantool.Constants
  alias Tarantool.Request
  alias Tarantool.Response

  require Logger

  def start_link(host \\ 'localhost', port \\ 3301, timeout \\ 5000)
  def start_link(host, port, timeout) when is_binary(host), do: start_link(to_char_list(host), port, timeout)
  def start_link(host, port, timeout), do: Connection.start_link(__MODULE__, {host, port, timeout})

  def close(conn) do
     Connection.call(conn, :close)
  end

  def init({host, port, timeout}) do
    s = %{host: host, port: port, timeout: timeout, sock: nil, salt: nil, sync: 0, queue: %{}, response_size: nil, tail: ""}
    {:connect, :init, s}
  end

  def connect(_, %{sock: nil, host: host, port: port, timeout: timeout} = s) do
    case :gen_tcp.connect(host, port, [active: false, packet: :raw, mode: :binary], timeout) do
      {:ok, sock} ->
        {:ok, _greeting, salt} = read_greeting(sock)
        :ok = :inet.setopts(sock, active: :once)
        {:ok, %{s | sock: sock, salt: salt}}
      {:error, _} ->
        {:backoff, 1000, s}
    end
  end

  def disconnect(info, %{sock: sock} = s) do
    :ok = :gen_tcp.close(sock)
    case info do
      {:close, from} ->
        Connection.reply(from, :ok)
      {:error, :closed} ->
        :error_logger.format("Connection closed~n", [])
      {:error, reason} ->
        reason = :inet.format_error(reason)
        :error_logger.format("Connection error: ~s~n", [reason])
    end
    {:connect, :reconnect, %{s | sock: nil}}
  end

  # Callbacks

  def handle_call(_, _, %{sock: nil} = s) do
    {:reply, {:error, :closed}, s}
  end

  def handle_call({code, opts}, from, %{sock: sock} = s) do
    Request.make_payload(code, opts, s) |> send_request(sock)

    {:noreply, %{s | sync: s.sync + 1, queue: Map.put(s.queue, s.sync, from)}}
  end

  def handle_call(:close, from, s) do
    {:disconnect, {:close, from}, s}
  end

  @doc false
  def handle_info({:tcp, _, data}, %{sock: socket, tail: tail} = s) do
    s = Response.parse_data(tail <> data, s)

    :inet.setopts(socket, active: :once)
    {:noreply, s}
  end

  defp send_request(request, sock) do
    :gen_tcp.send(sock, request)
  end

  defp read_greeting(conn) do
    {:ok, response } = :gen_tcp.recv(conn, 128)

    << greeting::512, salt::352, _rest :: binary >> = response

    {:ok, <<greeting::512>>, <<salt::352>>}
  end
end
