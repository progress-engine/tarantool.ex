defmodule Tarantool.Request do
  alias Tarantool.Auth
  use Tarantool.Constants

  def make_payload(:auth, %{username: username, password: password}, %{salt: salt} = s) do
    make_payload(:auth, %{username: username, tuple: ["chap-sha1", Auth.scramble(salt, password)]}, s)
  end

  def make_payload(code, opts, s) do
    payload = pack_header(code, s) <> pack_body(opts)
    payload_size(payload) <> payload
  end

  defp pack_header(code, s) do
    %{@iproto_keys[:request_type] => @iproto_codes[code],
      @iproto_keys[:sync] => s.sync}
    |> MessagePack.pack!
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
end
