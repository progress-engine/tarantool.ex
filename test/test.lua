box.cfg({listen=3303})
box.schema.user.create('test', {password='t3st', if_not_exists=true})

function test_func_1(p1)
  return {'ok', p1}
end

if not box.space.test then
    local s1 = box.schema.space.create('test', {id = 513, if_not_exists = true})
    local ip = s1:create_index('primary', {type = 'hash', parts = {1, 'NUM'}, if_not_exists = true})
    local iname = s1:create_index('name', {type = 'tree', parts = {2, 'STR'}, if_not_exists = true})
    local irtree = s1:create_index('point', {type = 'rtree', unique=false, parts = {3, 'ARRAY'}, if_not_exists = true})
    local ipname = s1:create_index('id_name', {type = 'tree', parts = {1, 'NUM', 2, 'STR'}})
end

if not box.space.test1 then
    local s2 = box.schema.space.create('test1', {id = 514, if_not_exists = true})
    local ip = s2:create_index('primary', {type = 'hash', parts = {1, 'NUM'}, if_not_exists = true})
end

local s1 = box.space.test
s1:truncate()
s1:insert{1, "hello", {1, 2}, 100}
s1:insert{2, "world", {3, 4}, 200}
local s2 = box.space.test1
s2:truncate()
s2:insert{1, "hello", {1, 2}, 100}
s2:insert{2, "world", {3, 4}, 200}

pcall(function()
box.schema.user.grant('guest', 'read,write,execute', 'universe')
end)
