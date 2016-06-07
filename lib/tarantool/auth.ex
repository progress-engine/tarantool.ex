defmodule Tarantool.Auth do
  def scramble(encoded_salt, password) do
    <<salt :: 160, _ :: binary>> = :base64.decode(encoded_salt)
    step1 = :crypto.hash(:sha, password)
    step2 = :crypto.hash(:sha, step1)
    step3 = :crypto.hash(:sha, [<<salt :: 160>>, step2])
    :crypto.exor(step3, step1)
  end
end
