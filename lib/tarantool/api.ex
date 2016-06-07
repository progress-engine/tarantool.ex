defmodule Tarantool.Api do
  use Tarantool.Api.Helper

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
end
