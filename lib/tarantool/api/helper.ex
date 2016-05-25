defmodule Tarantool.Api.Helper do
  defmacro __using__(_opts) do
    quote do
      import Tarantool.Api.Helper

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
