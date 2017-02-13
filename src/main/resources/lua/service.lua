local route = require "route"
local parser = require "redis.parser"

local configs = ngx.shared.configs;
configs:set("fetchback", 1);

-- route location
local function getFetchbackUrl()
    --ngx.say('fetchbackurl')
    local flag = configs:get("fetchback");
    if (flag == 1) then
        return "/fetchback_source1"
    else
        return "/fetchback_source2";
    end
end

-- fetchback route
local function captureLocation(args)
    local res = ngx.location.capture("/fetchback_source1", { args = args });
    if res.status ~= ngx.HTTP_OK then
        ngx.say("route 2")
        res = ngx.location.capture("/fetchback_source2", { args = args });
        if res.status ~= ngx.HTTP_OK then
            return nil;
        end
    end
    return res;
end

-- multi redis get
local function multiGet(cmdlist)
    local reqs = {}
    for i, req in ipairs(cmdlist) do
        local raw_reqs = {}
        for j, req2 in ipairs(req) do
            table.insert(raw_reqs, parser.build_query(req2))
        end
        --ngx.say(req[1][2].." route ".. route.getLocation(req[1][2]));
        table.insert(reqs, {
            "/" .. route.getLocation(req[1][2]) .. "?" .. #req, {
                body = table.concat(raw_reqs, "")
            }
        });
    end

    local resps = { ngx.location.capture_multi(reqs) }
    return resps;
end

-- single redis get
local function singleget(cmdlist)
    local raw_reqs = {}
    for i, req in ipairs(cmdlist) do
        table.insert(raw_reqs, parser.build_query(req))
    end

    local location = "/" .. route.getLocation(cmdlist[1][2]) .. "?";
    --ngx.say(location);
    local res = ngx.location.capture(location .. #cmdlist,
        { body = table.concat(raw_reqs, "") })
    if res.status == 200 and res.body then
        return res;
    else
        return nil;
    end
end

