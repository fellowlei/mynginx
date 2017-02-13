local parser = require "redis.parser"
local configs = ngx.shared.configs;
local function initConfig()
    if configs:get("fetchback1") == nil then
        configs:set("fetchback1", 0);
    end
end

initConfig();
-- fetchback  auto route
local function captureLocationRoute(args)
    if configs:get("fetchback1") < 3 then
        local res = ngx.location.capture("/fetchback_source1", { args = args });
        if res.status == ngx.HTTP_OK then
            return res;
        else
            ngx.say(configs:get("fetchback1"));
            if configs:get("time2") == nil then
                configs:incr("fetchback1", 1)
                configs:set("time2", "time2", 10); -- 时间间隔
            end
            if configs:get("fetchback1") >= 3 then
                configs:set("time", "time", 5);
                ngx.say("set time");
            end
            res = ngx.location.capture("/fetchback_source2", { args = args });
            if res.status == ngx.HTTP_OK then
                return res;
            else
                return nil;
            end
        end
    else
        if configs:get("time") == nil then
            configs:set("fetchback1", 0);
            ngx.say("clear time");
        end
        local res = ngx.location.capture("/fetchback_source2", { args = args });
        if res.status == ngx.HTTP_OK then
            return res;
        else
            return nil;
        end
    end
end

-- multi get
local function multi_get(url, paramList)
    local reqs = {}
    for i, param in ipairs(paramList) do
        table.insert(reqs, { url, { args = param } });
    end
    local isSuccess = true;
    local resps = { ngx.location.capture_multi(reqs) }
    for i, resp in ipairs(resps) do
        if resp.status ~= ngx.HTTP_OK then
            isSuccess = false;
            break;
            --ngx.say(resp.body)
        end
    end

    if isSuccess then
        return true, resps;
    else
        return false;
    end
end

-- multi get  auto route
local function multi_get_route(paramList)
    if configs:get("fetchback1") < 3 then
        local ok, resps = multi_get("/fetchback_source1", paramList)
        if ok then
            return true, resps;
        else
            ngx.say(configs:get("fetchback1"));
            if configs:get("time2") == nil then
                configs:incr("fetchback1", 1)
                configs:set("time2", "time2", 10); -- 时间间隔
            end
            if configs:get("fetchback1") >= 3 then
                configs:set("time", "time", 5);
                ngx.say("set time");
            end
            local ok, resps = multi_get("/fetchback_source2", paramList)
            if ok then
                return true, resps;
            else
                return false, nil;
            end
        end
    else
        if configs:get("time") == nil then
            configs:set("fetchback1", 0);
            ngx.say("clear time");
        end

        local ok, resps = multi_get("/fetchback_source2", paramList)
        if ok then
            return true, resps;
        else
            return false, nil;
        end
    end
end

-- multi get route test
local function multi_get_route_test()
    local paramList = {};
    table.insert(paramList, "name=mark")
    table.insert(paramList, "name=mark2")

    local ok, resps = multi_get_route(paramList);
    if ok then
        for i, resp in ipairs(resps) do
            if resp.status == ngx.HTTP_OK then
                ngx.say(resp.body)
            end
        end
    else
        ngx.say("failed");
    end
end


-- route location
local function getFetchbackUrl()
    --ngx.say('fetchbackurl')
    local flag = configs:get("fetchback");
    if (1 == flag) then
        return "/fetchback_source2"
    else
        return "/fetchback_source1";
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

-- test capturelocation
local function testCaptureLocation()
    local res = captureLocation('name=mark');
    if res ~= nil then
        ngx.say(res.body)
    else
        ngx.say("res is nil")
    end
end

--upstream fetchback1 {
--    server localhost:8080 weight=1 max_fails=3 fail_timeout=3s;
--keepalive 1024;
--}
--
--upstream fetchback2 {
--    server localhost:8081 weight=1 max_fails=3 fail_timeout=3s;
--keepalive 1024;
--}

--location /fetchback_source1 {
--    proxy_pass http://fetchback1/1.html;
--}
--
--location /fetchback_source2 {
--    proxy_pass http://fetchback2/1.html;
--}
--

-- multi redis get
-- cmdList 格式 {{{"get","name1"}} ,{{"get","name2"}}}
-- route 规则 按cmdlist[*][1][2] 格式 例如 按"name1","name2"分区
local function multiGet(getLocation, cmdlist)
    local reqs = {}
    for i, req in ipairs(cmdlist) do
        local raw_reqs = {}
        for j, req2 in ipairs(req) do
            table.insert(raw_reqs, parser.build_query(req2))
        end
        --ngx.say(req[1][2].." route ".. getLocation(req[1][2]));
        table.insert(reqs, {
            "/" .. getLocation(req[1][2]) .. "?" .. #req, {
                body = table.concat(raw_reqs, "")
            }
        });
    end

    local resps = { ngx.location.capture_multi(reqs) }
    return resps;
end


-- test multi redis get
local function testMultiGet()
    local cmd1 = { { "set", "name1", "mark1" }, { "get", "name1" } }
    local cmd2 = { { "set", "name2", "mark2" }, { "get", "name2" } }

    local cmdlist = {}
    table.insert(cmdlist, cmd1)
    table.insert(cmdlist, cmd2)

    local keylist = {}
    table.insert(keylist, "name1")
    table.insert(keylist, "name2")

    local resps = multiGet(cmdlist);
    for i, resp in ipairs(resps) do
        if resp.status == 200 and resp.body then
            local replies = parser.parse_replies(resp.body, #cmdlist[i])
            for j, reply in ipairs(replies) do
                ngx.say(keylist[i] .. "=" .. reply[1])
            end
        else
            ngx.say("not found")
        end
    end
end

-- single redis get
-- cmdlist 格式 {{"set","name","mark"},{"get","name"}}
-- route 规则 按 cmdlist[1][2] 格式 例如 按"name" 分区
local function singleget(getLocation, cmdlist)
    local raw_reqs = {}
    for i, req in ipairs(cmdlist) do
        table.insert(raw_reqs, parser.build_query(req))
    end

    local res = ngx.location.capture("/" .. getLocation(req[1][2]) .. "?" .. #cmdlist,
        { body = table.concat(raw_reqs, "") })
    if res.status == 200 and res.body then
        return res;
    else
        return nil;
    end
end

-- test single get
local function testSingleGet()
    local cmdlist = { { "set", "name", "mark" }, { "get", "name" } }
    local res = singleget(cmdlist)
    if res ~= nil then
        local replies = parser.parse_replies(res.body, #cmdlist)
        for i, reply in ipairs(replies) do
            ngx.say(reply[1])
        end
    end
end


local service = {
    getFetchbackUrl = getFetchbackUrl,
    captureLocation = captureLocation,
    captureLocationRoute = captureLocationRoute,
    multiGet = multiGet,
    singleget = singleget
}

return service


