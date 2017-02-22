local service = require "service"
-- test capturelocation
local function testCaptureLocation()
    local ok,res = service.single_get_route('name=mark',"/fetchback_source1","/fetchback_source2");
    if ok then
        ngx.say(res.body)
    else
        ngx.say("res is nil")
    end
end
local function multi_get_route_test()
    local paramList = {};
    table.insert(paramList, "name=mark")
    table.insert(paramList, "name=mark2")

    local ok, resps = service.multi_get_route(paramList,"/fetchback_source1","/fetchback_source2");
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

testCaptureLocation()
--multi_get_route_test();
--ngx.say("hello world");
