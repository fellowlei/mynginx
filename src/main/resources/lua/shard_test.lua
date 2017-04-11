local shard = require "shard"
local parser = require "redis.parser"
-- single redis get
local function singleget(cmdlist)
    local raw_reqs = {}
    for i, req in ipairs(cmdlist) do
        table.insert(raw_reqs, parser.build_query(req))
    end

    local location = "/" .. shard.getLocation(cmdlist[1][2]) .. "?";
    local res = ngx.location.capture(location .. #cmdlist,
        { body = table.concat(raw_reqs, "") })
    if res.status == 200 and res.body then
        return res;
    else
        return nil;
    end
end

-- multi redis get
local function multiGet(cmdlist)
    local reqs = {}
    for i, req in ipairs(cmdlist) do
        local raw_reqs = {}
        for j, req2 in ipairs(req) do
            table.insert(raw_reqs, parser.build_query(req2))
        end
        table.insert(reqs, {
            "/" .. shard.getLocation(req[1][2]) .. "?" .. #req, {
                body = table.concat(raw_reqs, "")
            }
        });
    end

    local resps = { ngx.location.capture_multi(reqs) }
    return resps;
end



