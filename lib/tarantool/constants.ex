defmodule Tarantool.Constants do
  defmacro __using__(_opts) do
    quote do
      use Bitwise

      @iproto_keys [
        request_type: 0x00,
        sync: 0x01,
        server_id: 0x02,
        lsn: 0x03,
        timestamp: 0x04,
        schema_id: 0x05,
        space_id: 0x10,
        index_id: 0x11,
        limit: 0x12,
        offset: 0x13,
        iterator: 0x14,
        index_base: 0x15,
        key: 0x20,
        tuple: 0x21,
        function_name: 0x22,
        username: 0x23,
        server_uuid: 0x24,
        cluster_uuid: 0x25,
        vclock: 0x26,
        expr: 0x27,
        ops: 0x28,
        data: 0x30,
        error: 0x31
      ]

      @iproto_codes [
        ok: 0,
        select: 1,
        insert: 2,
        replace: 3,
        update: 4,
        delete: 5,
        call: 6,
        auth: 7,
        eval: 8,
        upsert: 9,
        ping: 64,
        join: 65,
        subscribe: 66,
        error: bsl(1, 15)
      ]

      @system_spaces [
        id_min: 256,
        schema: 272,
        space: 280,
        vspace: 281,
        index: 288,
        vindex: 289,
        func: 296,
        vfunc: 297,
        user: 304,
        vuser: 305,
        priv: 312,
        vpriv: 313,
        cluster: 320,
        id_max: 511,
        id_nil: 2147483647
      ]
    end
  end
end
