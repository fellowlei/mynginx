local route = require "route"
-- test route
local function multi_get_route_test()
    local paramList = {};
    table.insert(paramList, "name=mark")
    table.insert(paramList, "name=mark2")

    local ok, resps = route.multi_get_route(paramList,"/fetchback_source1","/fetchback_source2",true);
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
    local ok, resp = route.single_get_route(param,"/fetchback_source1","/fetchback_source2",true);
    if ok then
        if resp.status == ngx.HTTP_OK then
            ngx.say(resp.body)
        end
    else
        ngx.say("failed");
    end
end

--single_get_route_test();
multi_get_route_test()


