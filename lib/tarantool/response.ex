defmodule Tarantool.Response do
  use Tarantool.Constants

  require Logger

  def parse_data(data, %{response_size: nil} = s) do
    case Msgpax.unpack_slice(data) do
      {:ok, response_size, rest} ->
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
    {:ok, header, body} = Msgpax.unpack_slice(data)
    {:ok, body, rest} = Msgpax.unpack_slice(body)

    sync = header[@iproto_keys[:sync]]
    GenServer.reply(s.queue[sync], make_response(header, body))

    parse_data(rest, %{s| response_size: nil, queue: Map.delete(s.queue, sync)})
  end


  def make_response(%{0 => 0}, %{0x30 => data}), do: {:ok, data}
  def make_response(%{0 => 0}, %{} = data), do: {:ok, data}
  def make_response(%{0 => error_code}, %{0x31 => error_message}), do: {:error, error_code, error_message}
end
