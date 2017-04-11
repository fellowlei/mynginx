local parser = require "redis.parser"
local shard = require "shard"

-- multi redis get
-- cmdList 格式 {{{"get","name1"}} ,{{"get","name2"}}}
-- route 规则 按cmdlist[*][1][2] 格式 例如 按"name1","name2"分区
local function redis_multi_get(cmdlist)
    local reqs = {}
    for i,req in ipairs(cmdlist) do
        local raw_reqs = {}
        for j, req2 in ipairs(req) do
            table.insert(raw_reqs,parser.build_query(req2))
        end
        --ngx.say(req[1][2].." route ".. getLocation(req[1][2]));
        table.insert(reqs,{"/"..shard.getLocation(req[1][2]).."?"..#req,{
            body=table.concat(raw_reqs,"")}});
    end

    local resps = { ngx.location.capture_multi(reqs) }
    return resps;
end


-- test multi redis get
local function test_redis_multi_get()
    local cmd1 = {{"set","name1","mark1"},{"get","name1"}}
    local cmd2 = {{"set","name2","mark2"},{"get","name2"}}

    local cmdlist = {}
    table.insert(cmdlist,cmd1)
    table.insert(cmdlist,cmd2)

    local keylist = {}
    table.insert(keylist,"name1")
    table.insert(keylist,"name2")

    local resps = redis_multi_get(cmdlist);
    for i, resp in ipairs(resps) do
        if resp.status == 200 and resp.body then
            local replies = parser.parse_replies(resp.body,#cmdlist[i])
            for j,reply in ipairs(replies) do
                ngx.say(keylist[i].."="..reply[1])
            end
        else
            ngx.say("not found")
        end
    end
end

-- single redis get
-- cmdlist 格式 {{"set","name","mark"},{"get","name"}}
-- route 规则 按 cmdlist[1][2] 格式 例如 按"name" 分区
local function redis_single_get(cmdlist)
    local raw_reqs = {}
    for i, req in ipairs(cmdlist) do
        table.insert(raw_reqs, parser.build_query(req))
    end

    local res = ngx.location.capture("/"..shard.getLocation(req[1][2]).."?".. #cmdlist,
        { body = table.concat(raw_reqs, "") })
    if res.status == 200 and res.body then
        return res;
    else
        return nil;
    end
end

-- test single get
local function test_redis_single_get()
    local cmdlist = {{"set","name","mark"},{"get", "name"}}
    local res = redis_single_get(cmdlist)
    if res ~= nil then
        local replies = parser.parse_replies(res.body, #cmdlist)
        for i, reply in ipairs(replies) do
            ngx.say(reply[1])
        end
    end
end


local redis_util = {
    redis_multi_get=redis_multi_get,
    redis_single_get=redis_single_get
}

return redis_util

