defmodule Tarantool.Helper do
  defmacro __using__(_opts) do
    quote do
      import Tarantool.Helper

      def check_params(provided, required, optional) do
        provided = MapSet.new(Map.keys(provided))
        required = MapSet.new(required)
        optional = MapSet.new(optional)
        possible = MapSet.union(required, optional)

        missing = MapSet.difference(required, provided)
          wrong = MapSet.difference(provided, possible)

        cond do
          MapSet.size(missing) > 0 -> {:error, missing_params: MapSet.to_list(missing)}
          MapSet.size(wrong) > 0 -> {:error, wrong_params: MapSet.to_list(wrong)}
          True -> :ok
        end
      end
    end
  end

  defmacro defrequest(request, required \\ [], optional \\ []) do
    quote do
      def unquote(request)(conn, params \\ %{}) do
        case check_params(params, unquote(required), unquote(optional)) do
          :ok ->
            GenServer.call(conn, {unquote(request), params})
          error ->
            error
        end
      end
    end
  end
end

defmodule Tarantool do
  @moduledoc """
  Tarantool client for Elixir
  """

  use Connection
  use Tarantool.Constants
  use Tarantool.Helper

  require Logger

  defrequest :ping
  defrequest :auth, [:username, :password]
  defrequest :select, [:space_id, :limit, :key, :index_id, :offset, :iterator]
  defrequest :insert, [:space_id, :tuple ]
  defrequest :replace, [:space_id, :tuple]
  defrequest :update, [:space_id, :index_id, :key, :tuple]
  defrequest :delete, [:space_id, :index_id, :key]
  defrequest :call, [:function_name, :tuple]
  defrequest :eval, [:expr, :tuple]
  defrequest :upsert, [:space_id, :tuple, :ops]

  def start_link(host \\ 'localhost', port \\ 3301, timeout \\ 5000) do
    Connection.start_link(__MODULE__, {host, port, timeout})
  end

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
    make_payload(code, opts, s)
    |> send_request(sock)

    {:noreply, %{s | sync: s.sync + 1, queue: Map.put(s.queue, s.sync, from)}}
  end

  def handle_call(:close, from, s) do
    {:disconnect, {:close, from}, s}
  end

  @doc false
  def handle_info({:tcp, _, data}, %{sock: socket, tail: tail} = s) do
    s = parse_data(tail <> data, s)

    :inet.setopts(socket, active: :once)
    {:noreply, s}
  end


  def parse_data(data, %{response_size: nil} = s) do
    case MessagePack.unpack_once(data) do
      {:ok, {response_size, rest}} ->
        parse_data(rest, %{s | response_size: response_size})
      {:error, _} ->
        %{s| tail: data}
    end
  end

  def parse_data(data, %{response_size: response_size} = s ) do
    cond do
      byte_size(data) >= response_size ->
        parse_response(data, s)
      true ->
        %{s| tail: data}
    end
  end

  def parse_response(data, s) do
    {:ok, {header, body}} = MessagePack.unpack_once(data)
    {:ok, {body, rest}} = MessagePack.unpack_once(body)

    sync = header[@iproto_keys[:sync]]
    GenServer.reply(s.queue[sync], {:ok, header, body})

    parse_data(rest, %{s| response_size: nil, queue: Map.delete(s.queue, sync)})
  end

  defp make_payload(:auth, %{username: username, password: password}, %{salt: salt} = s) do
    make_payload(:auth, %{username: username, tuple: ["chap-sha1", scramble(salt, password)]}, s)
  end

  defp make_payload(code, opts, s) do
    payload = pack_header(code, s) <> pack_body(opts)
    payload_size(payload) <> payload
  end

  defp pack_header(code, s) do
    %{@iproto_keys[:request_type] => @iproto_codes[code],
      @iproto_keys[:sync] => s.sync}
    |> MessagePack.pack!
  end

  defp send_request(request, sock) do
    :gen_tcp.send(sock, request)
  end

  defp read_greeting(conn) do
    {:ok, response } = :gen_tcp.recv(conn, 128)

    << greeting::512, salt::352, _rest :: binary >> = response

    {:ok, <<greeting::512>>, <<salt::352>>}
  end

  defp pack_body(body) do
    pack_body(Map.keys(body), body, %{}) |> MessagePack.pack!
  end

  defp pack_body([], _body, acc) do
    acc
  end

  defp pack_body([key| rest], body, acc) do
    acc = case body[key] do
      nil -> acc
      _ -> Map.merge(acc, %{@iproto_keys[key] => body[key]})
    end
    pack_body(rest, body, acc)
  end

  defp payload_size(payload) do
    << 0xCE :: 8, byte_size(payload) :: 32-big-unsigned-integer-unit(1) >>
  end

  defp scramble(encoded_salt, password) do
    <<salt :: 160, _ :: binary>> = :base64.decode(encoded_salt)
    step1 = :crypto.hash(:sha, password)
    step2 = :crypto.hash(:sha, step1)
    step3 = :crypto.hash(:sha, [<<salt :: 160>>, step2])
    :crypto.exor(step3, step1)
  end

  defp add_param(map, param_name, value) do
    case value do
      nil -> map
      _ -> Map.merge(map, %{@iproto_keys[param_name] => value})
    end
  end
end
