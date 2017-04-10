local parser = require "redis.parser"
local config = ngx.shared.route_config;

local function log(msg)
    --ngx.say(msg .. " |");
    ngx.log(ngx.ERR, msg .. " |")
end

-- 单个请求自动路由组件
-- 如果请求url_master失败10次,自动切换到调用url_backup
-- 过3秒后，自动切换到调用url_master
-- 参数说明
-- param eg: "name=mark&age=18"
-- url_master eg: "/fetchback_source1"
-- url_backup eg: "/fetchback_source2"
-- is_readmaster eg: true or false. default true
-- return eg: if success then return true,resps
--            if failed then return false,resps
local function single_get_route(param, url_master, url_backup, is_readmaster)
    local val = "val";
    local fetchback_source_url_master = url_master; -- 主服务
    local fetchback_source_url_backup = url_backup; -- 备用服务
    local expire_time = 3; -- 3秒重试10次，如果超过10次，调用备用服务。 调用备用服务，超过3秒，再读主服务
    local failed_count = 10; -- 重试次数
    local key_time_back = "key_time_back_" .. url_master -- 10秒后读master的key
    local key_count_fail = "key_count_fail_" .. url_master; -- 失败次数的key
    if is_readmaster == nil then  -- 默认true
        is_readmaster =true;
    end
    -- 调用备用服务时间 == nil and 失败次数 < 3  则调用主服务
    if is_readmaster and config:get(key_time_back) == nil and (config:get(key_count_fail) or 0) < failed_count then -- 失败次数 < 3
    local resp = ngx.location.capture(fetchback_source_url_master, { args = param });
    if resp.status == ngx.HTTP_OK then
        --log("master success|")
        return true, resp;
    else
        local ok, err = config:incr(key_count_fail, 1)
        if not ok and err == "not found" then
            --log("init count|")
            config:add(key_count_fail, 0, expire_time) -- 3秒重试10次
            config:incr(key_count_fail, 1)
        end
        --log(config:get(key_count_fail));
        if config:get(key_count_fail) >= failed_count then --失败次数 >= 10
        config:set(key_time_back, val, expire_time); -- 设置调用备用服务时间
        --log("set time|")
        end
        resp = ngx.location.capture(fetchback_source_url_backup, { args = param });
        if resp.status == ngx.HTTP_OK then
            --log("call back1|")
            return true, resp;
        else
            return false, resp;
        end
    end
    else
        local resp = ngx.location.capture(fetchback_source_url_backup, { args = param });
        if resp.status == ngx.HTTP_OK then
            --log("call back2|")
            return true, resp;
        else
            return false, resp;
        end
    end
end

-- 批量请求回源
-- 参数说明
-- url eg: "/fetchback_source1"
-- paramList eg: {"name=mark&age=18","name=mark2&age=19"}
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
        return false, resps;
    end
end

-- 批量请求自动路由组件
-- 如果请求url_master失败10次,自动切换到调用url_backup
-- 过3秒后，自动切换到调用url_master
-- 参数说明
-- paramList eg: {"name=mark&age=18","name=mark2&age=19"}
-- url_master eg: "/fetchback_source1"
-- url_backup eg: "/fetchback_source2"
-- is_readmaster eg: true or false. default true
-- return eg: if success then return true,resps
--            if failed then return false,resps
local function multi_get_route(paramList, url_master, url_backup, is_readmaster)
    local val = "val";
    local fetchback_source_url_master = url_master;
    local fetchback_source_url_backup = url_backup;
    local expire_time_multi = 3; -- 3秒重试10次，如果超过10次，调用备用服务。 调用备用服务，超过3秒，再读主服务
    local failed_count_multi = 10; -- 重试次数
    local key_time_back_multi = "key_time_back_multi_" .. url_master; --3秒后读master的key
    local key_count_fail_multi = "key_count_fail_multi_" .. url_master; -- 失败次数的key
    if is_readmaster == nil then  -- 默认true
        is_readmaster =true;
    end
    -- 调用备用服务时间 == nil and 失败次数 < 3  则调用主服务
    if is_readmaster and config:get(key_time_back_multi) == nil and (config:get(key_count_fail_multi) or 0) < failed_count_multi then
        local ok, resps = multi_get(fetchback_source_url_master, paramList)
        if ok then
            return true, resps;
        else
            local ok, err = config:incr(key_count_fail_multi, 1);
            if not ok and err == "not found" then
                config:add(key_count_fail_multi, 0, expire_time_multi); -- 3秒重试10次
                config:incr(key_count_fail_multi, 1);
            end
            if config:get(key_count_fail_multi) >= failed_count_multi then --失败次数 >= 10
            config:set(key_time_back_multi, val, expire_time_multi); -- 设置调用备用服务时间
            --ngx.say("set time");
            end
            local ok, resps = multi_get(fetchback_source_url_backup, paramList)
            if ok then
                return true, resps;
            else
                return false, resps;
            end
        end
    else
        local ok, resps = multi_get(fetchback_source_url_backup, paramList)
        if ok then
            return true, resps;
        else
            return false, resps;
        end
    end
end

-- test
local function multi_get_route_test()
    local paramList = {};
    table.insert(paramList, "name=mark")
    table.insert(paramList, "name=mark2")

    local ok, resps = multi_get_route(paramList,"/fetchback_source1","/fetchback_source2",true);
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

-- test
local function single_get_route_test()
    local param = "name=mark&age=18"
    local ok, resp = single_get_route(param,"/fetchback_source1","/fetchback_source2",true);
    if ok then
        if resp.status == ngx.HTTP_OK then
            ngx.say(resp.body)
        end
    else
        ngx.say("failed");
    end
end

-- route location
local function getFetchbackUrl()
    --ngx.say('fetchbackurl')
    local flag = configs:get("fetchback");
    if(1 == flag) then
        return "/fetchback_source2"
    else
        return "/fetchback_source1";
    end
end

-- fetchback route
local function captureLocation(args)
    local res = ngx.location.capture("/fetchback_source1",{args=args});
    if res.status ~= ngx.HTTP_OK then
        --ngx.say("route 2")
        res = ngx.location.capture("/fetchback_source2",{args=args});
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

local route = {
    single_get_route = single_get_route,
    multi_get_route = multi_get_route
}

return route

