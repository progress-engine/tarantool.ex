defmodule Tarantool.Response do
  use Tarantool.Constants

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
    GenServer.reply(s.queue[sync], make_response(header, body))

    parse_data(rest, %{s| response_size: nil, queue: Map.delete(s.queue, sync)})
  end


  def make_response(%{0 => 0}, %{0x30 => data}), do: {:ok, data}
  def make_response(%{0 => 0}, %{} = data), do: {:ok, data}
  def make_response(%{0 => error_code}, %{0x31 => error_message}), do: {:error, error_code, error_message}
end
