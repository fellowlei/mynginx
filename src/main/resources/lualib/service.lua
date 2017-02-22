local parser = require "redis.parser"
local configs = ngx.shared.configs;

-- 单个请求自动路由组件
-- 如果请求url_master失败3次,自动切换到调用url_backup
-- 过10秒后，自动切换到调用url_master
-- 参数说明
-- param eg: "name=mark&age=18"
-- url_master eg: "/fetchback_source1"
-- url_backup eg: "/fetchback_source2"
-- return eg: if success then return true,resps
--            if failed then return false,resps
local function single_get_route(param,url_master,url_backup)
    local val = "val";
    local fetchback_source_url_master=url_master; -- 主服务
    local fetchback_source_url_backup=url_backup; -- 备用服务
    local expire_time = 10; -- 10秒重试3次，如果超过3次，调用备用服务。 调用备用服务，超过10秒，再读主服务
    local failed_count = 3;  -- 重试次数
    local key_time_back = "key_time_back_" .. url_master -- 10秒后读master的key
    local key_count_fail = "key_count_fail_" .. url_master; -- 失败次数的key

    -- 调用备用服务时间 == nil and 失败次数 < 3  则调用主服务
    if  configs:get(key_time_back) == nil and (configs:get(key_count_fail) or 0)  < failed_count then  -- 失败次数 < 3
        local resp = ngx.location.capture(fetchback_source_url_master,{args=param});
        if resp.status == ngx.HTTP_OK then
            return true,resp;
        else
            local ok, err = configs:incr(key_count_fail, 1)
	    if not ok then ngx.say(err) end;
            if not ok and err == "not found" then
                configs:add(key_count_fail, 0, expire_time)  -- 10秒重试3次
                configs:incr(key_count_fail, 1)
            end
	    ngx.say(configs:get(key_count_fail));

            if configs:get(key_count_fail) >= failed_count then --失败次数 >= 3
                configs:set(key_time_back,val, expire_time); -- 设置调用备用服务时间
                --ngx.say("set time");
            end
            resp = ngx.location.capture(fetchback_source_url_backup,{args=param});
            if resp.status == ngx.HTTP_OK then
                return true,resp;
            else
                return false,resp;
            end
        end
    else
        local resp = ngx.location.capture(fetchback_source_url_backup,{args=param});
        if resp.status == ngx.HTTP_OK then
            return true,resp;
        else
            return false,resp;
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
        return false,resps;
    end
end

-- 批量请求自动路由组件
-- 如果请求url_master失败3次,自动切换到调用url_backup
-- 过10秒后，自动切换到调用url_master
-- 参数说明
-- paramList eg: {"name=mark&age=18","name=mark2&age=19"}
-- url_master eg: "/fetchback_source1"
-- url_backup eg: "/fetchback_source2"
-- return eg: if success then return true,resps
--            if failed then return false,resps
local function multi_get_route(paramList,url_master,url_backup)
    local val = "val";
    local fetchback_source_url_master=url_master;
    local fetchback_source_url_backup=url_backup;
    local expire_time_multi = 10; -- 10秒重试3次，如果超过3次，调用备用服务。 调用备用服务，超过10秒，再读主服务
    local failed_count_multi = 3; -- 重试次数
    local key_time_back_multi = "key_time_back_multi_".. url_master;  --10秒后读master的key
    local key_count_fail_multi = "key_count_fail_multi_".. url_master;  -- 失败次数的key

    -- 调用备用服务时间 == nil and 失败次数 < 3  则调用主服务
    if configs:get(key_time_back_multi) == nil and (configs:get(key_count_fail_multi) or 0) < failed_count_multi then
        local ok, resps = multi_get(fetchback_source_url_master, paramList)
        if ok then
            return true, resps;
        else
            local ok,err = configs:incr(key_count_fail_multi, 1);
	    if not ok then ngx.say(err) end;
            if not ok and err == "not found" then
                configs:add(key_count_fail_multi,0,expire_time_multi); -- 10秒重试3次
                configs:incr(key_count_fail_multi,1);
            end
            if configs:get(key_count_fail_multi) >= failed_count_multi then --失败次数 >= 3
                configs:set(key_time_back_multi, val, expire_time_multi); -- 设置调用备用服务时间
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

    local ok, resps = multi_get_route(paramList,"/fetchback_source1","/fetchback_source2");
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
    local ok, resp = single_get_route(param,"/fetchback_source1","/fetchback_source2");
    if ok then
        if resp.status == ngx.HTTP_OK then
            ngx.say(resp.body)
        end
    else
        ngx.say("failed");
    end
end
-- fetchback single get route
-- if call url_1 failed 3 times then call url_2
-- after 10 second then call url_1 again
-- args eg: "name=mark&age=18"
-- return eg: if success then return true,res
--            if failed then return false,res
local function single_get_route_two(args)
    local fetchback_source_url_1="/fetchback_source1"; -- fetchback_url_1
    local fetchback_source_url_2="/fetchback_source2"; -- fetchback_url_1
    local fetchback_time_callback = 10; -- 时间间隔
    local fetchback_try_count = 3;  -- try time
    local key_time_pass_fetchback = "key_time_pass_fetchback"
    local key_count_failed_fetchback = "key_count_failed_fetchback";
    local key_time_expired_fetchback ="key_time_expired_fetchback";

    -- init
    if configs:get(key_count_failed_fetchback) == nil then
        configs:set(key_count_failed_fetchback,0);
    end

    if configs:get(key_count_failed_fetchback) < fetchback_try_count then
        local res = ngx.location.capture(fetchback_source_url_1,{args=args});
        if res.status == ngx.HTTP_OK then
            return true,res;
        else
            if configs:get(key_time_pass_fetchback) == nil then
                configs:set(key_time_pass_fetchback,key_time_pass_fetchback,fetchback_time_callback); -- 时间间隔
                configs:set(key_count_failed_fetchback, 0)
            end
            configs:incr(key_count_failed_fetchback, 1)

            --ngx.say(configs:get("fetchback1"));
            if configs:get(key_count_failed_fetchback) >= fetchback_try_count then
                configs:set(key_time_expired_fetchback,key_time_expired_fetchback, fetchback_time_callback); -- 时间间隔
                --ngx.say("set time");
            end
            res = ngx.location.capture(fetchback_source_url_2,{args=args});
            if res.status == ngx.HTTP_OK then
                return true,res;
            else
                return false,res;
            end
        end
    else
        if configs:get(key_time_expired_fetchback) == nil then
            configs:set(key_count_failed_fetchback,0);
            --ngx.say("clear time");
        end
        local res = ngx.location.capture(fetchback_source_url_2,{args=args});
        if res.status == ngx.HTTP_OK then
            return true,res;
        else
            return false,resp;
        end
    end
end

-- fetchback multi get route
-- if call url_1 failed 3 times then call url_2
-- after 10 second then call url_1 again
-- args eg: {"name=mark&age=18","name=mark2&age=19"}
-- return eg: if success then return true,resps
--            if failed then return false,resps
local function multi_get_route_two(paramList)
    local fetchback_source_url_1="/fetchback_source1";
    local fetchback_source_url_2="/fetchback_source2";
    local fetchback_time_callback = 10; -- 时间间隔
    local fetchback_try_count = 3;
    local key_time_pass_fetchback_multi = "key_time_pass_fetchback_multi"
    local key_count_failed_fetchback_multi = "key_count_failed_fetchback_multi";
    local key_time_expired_fetchback_multi ="key_time_expired_fetchback_multi";

    -- init
    if configs:get(key_count_failed_fetchback_multi) == nil then
        configs:set(key_count_failed_fetchback_multi,0);
    end

    if configs:get(key_count_failed_fetchback_multi) < fetchback_try_count then
        local ok, resps = multi_get(fetchback_source_url_1, paramList)
        if ok then
            return true, resps;
        else
            if configs:get(key_time_pass_fetchback_multi) == nil then
                configs:set(key_time_pass_fetchback_multi,key_time_pass_fetchback_multi,fetchback_time_callback); -- 时间间隔
                configs:set(key_count_failed_fetchback_multi, 0)
            end
            configs:incr(key_count_failed_fetchback_multi, 1)
            if configs:get(key_count_failed_fetchback_multi) >= fetchback_try_count then
                configs:set(key_time_expired_fetchback_multi, key_time_expired_fetchback_multi, fetchback_time_callback);
                --ngx.say("set time");
            end
            local ok, resps = multi_get(fetchback_source_url_2, paramList)
            if ok then
                return true, resps;
            else
                return false, resps;
            end
        end
    else
        if configs:get(key_time_expired_fetchback_multi) == nil then
            configs:set(key_count_failed_fetchback_multi, 0);
            --ngx.say("clear time");
        end

        local ok, resps = multi_get(fetchback_source_url_2, paramList)
        if ok then
            return true, resps;
        else
            return false, resps;
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

-- multi redis get
-- cmdList 格式 {{{"get","name1"}} ,{{"get","name2"}}}
-- route 规则 按cmdlist[*][1][2] 格式 例如 按"name1","name2"分区
local function redis_multi_get(getLocation,cmdlist)
    local reqs = {}
    for i,req in ipairs(cmdlist) do
        local raw_reqs = {}
        for j, req2 in ipairs(req) do
            table.insert(raw_reqs,parser.build_query(req2))
        end
        --ngx.say(req[1][2].." route ".. getLocation(req[1][2]));
        table.insert(reqs,{"/"..getLocation(req[1][2]).."?"..#req,{
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

    local resps = multiGet(cmdlist);
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
local function redis_single_get(getLocation,cmdlist)
    local raw_reqs = {}
    for i, req in ipairs(cmdlist) do
        table.insert(raw_reqs, parser.build_query(req))
    end

    local res = ngx.location.capture("/"..getLocation(req[1][2]).."?".. #cmdlist,
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
    local res = singleget(cmdlist)
    if res ~= nil then
        local replies = parser.parse_replies(res.body, #cmdlist)
        for i, reply in ipairs(replies) do
            ngx.say(reply[1])
        end
    end
end


local service = {
    single_get_route=single_get_route,
    multi_get_route=multi_get_route,
    redis_multi_get=redis_multi_get,
    redis_single_get=redis_single_get
}

return service

