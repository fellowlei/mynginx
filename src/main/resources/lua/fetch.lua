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


--local url = getFetchbackUrl()
--local res = ngx.location.capture("/fetchback_source1",{args = 'name=mark'})

-- test
local res = captureLocation('name=mark');
if res ~= nil then
    ngx.say(res.body)
else
    ngx.say("res is nil")
end



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


local function multi_get_route(paramList)
    if configs:get("fetchback1") < 3 then
        local ok, resps = multi_get("/fetchback_source1", paramList)
        if ok then
            return true, resps;
        else
            ngx.say(configs:get("fetchback1"));
            if configs:get("time2") == nil then
                configs:incr("fetchback1", 1)
                configs:set("time2","time2",10); -- 时间间隔
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







