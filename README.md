# Tarantool

**Tarantool client for Elixir projects**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add tarantool to your list of dependencies in `mix.exs`:

        def deps do
          [{:tarantool, "~> 0.0.2"}]
        end

  2. Ensure tarantool is started before your application:

        def application do
          [applications: [:tarantool]]
        end

## Usage Examples

```elixir
iex(1)> : {:ok, t} = Tarantool.start_link
{:ok, #PID<0.129.0>}

iex(2)>  Tarantool.Api.auth(t, %{password: "111222", username: "amalaev"})
{:ok, %{}}

iex(3)>  Tarantool.Api.select(t, %{space_id: 280, limit: 100, key: [], index_id: nil, iterator: nil, offset: 100})
{:ok, []}

iex(4)> Tarantool.Api.select(t, %{space_id: 280, limit: 100, key: [], index_id: nil, iterator: nil, offset: 0})
{:ok,
 [[272, 1, "_schema", "memtx", 0, %{}, [%{"name" => "key", "type" => "str"}]],
  [280, 1, "_space", "memtx", 0, %{},
   [%{"name" => "id", "type" => "num"}, %{"name" => "owner", "type" => "num"},
    %{"name" => "name", "type" => "str"},
    %{"name" => "engine", "type" => "str"},
    %{"name" => "field_count", "type" => "num"},
    %{"name" => "flags", "type" => "str"},
    %{"name" => "format", "type" => "*"}]],
  [281, 1, "_vspace", "sysview", 0, %{},
   [%{"name" => "id", "type" => "num"}, %{"name" => "owner", "type" => "num"},
    %{"name" => "name", "type" => "str"},
    %{"name" => "engine", "type" => "str"},
    %{"name" => "field_count", "type" => "num"},
    %{"name" => "flags", "type" => "str"},
    %{"name" => "format", "type" => "*"}]],
  [288, 1, "_index", "memtx", 0, %{},
   [%{"name" => "id", "type" => "num"}, %{"name" => "iid", "type" => "num"},
    %{"name" => "name", "type" => "str"}, %{"name" => "type", "type" => "str"},
    %{"name" => "opts", "type" => "array"},
    %{"name" => "parts", "type" => "array"}]],
  [289, 1, "_vindex", "sysview", 0, %{},
   [%{"name" => "id", "type" => "num"}, %{"name" => "iid", "type" => "num"},
    %{"name" => "name", "type" => "str"}, %{"name" => "type", "type" => "str"},
    %{"name" => "opts", "type" => "array"},
    %{"name" => "parts", "type" => "array"}]],
  [296, 1, "_func", "memtx", 0, %{},
   [%{"name" => "id", "type" => "num"}, %{"name" => "owner", "type" => "num"},
    %{"name" => "name", "type" => "str"},
    %{"name" => "setuid", "type" => "num"}]],
  [297, 1, "_vfunc", "sysview", 0, %{},
   [%{"name" => "id", "type" => "num"}, %{"name" => "owner", "type" => "num"},
    %{"name" => "name", "type" => "str"},
    %{"name" => "setuid", "type" => "num"}]],
  [304, 1, "_user", "memtx", 0, %{},
   [%{"name" => "id", "type" => "num"}, %{"name" => "owner", "type" => "num"},
    %{"name" => "name", "type" => "str"}, %{"name" => "type", "type" => "str"},
    %{"name" => "auth", "type" => "*"}]],
  [305, 1, "_vuser", "sysview", 0, %{},
   [%{"name" => "id", "type" => "num"}, %{"name" => "owner", "type" => "num"},
    %{"name" => "name", "type" => "str"}, %{"name" => "type", "type" => "str"},
    %{"name" => "auth", "type" => "*"}]],
  [312, 1, "_priv", "memtx", 0, %{},
   [%{"name" => "grantor", "type" => "num"},
    %{"name" => "grantee", "type" => "num"},
    %{"name" => "object_type", "type" => "str"},
    %{"name" => "object_id", "type" => "num"},
    %{"name" => "privilege", "type" => "num"}]],
  [313, 1, "_vpriv", "sysview", 0, %{},
   [%{"name" => "grantor", "type" => "num"},
    %{"name" => "grantee", "type" => "num"},
    %{"name" => "object_type", "type" => "str"},
    %{"name" => "object_id", "type" => "num"},
    %{"name" => "privilege", "type" => "num"}]],
  [320, 1, "_cluster", "memtx", 0, %{},
   [%{"name" => "id", "type" => "num"}, %{"name" => "uuid", "type" => "str"}]],
  [512, 1, "demo", "memtx", 0, %{}, []], [513, 1, "demo2", "memtx", 0, %{}, []],
  [514, 1, "aaa", "memtx", 0, %{}, []], [515, 4, "test", "memtx", 0, %{}, []],
  [516, 4, "test123", "memtx", 0, %{}, []],
  [517, 4, "test1234", "memtx", 0, %{}, []]]}

iex(5)> Tarantool.Api.ping(t)
{:ok, %{}}
```



