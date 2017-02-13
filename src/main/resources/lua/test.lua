local service = require "service"
-- test capturelocation
local function testCaptureLocation()
    local res = service.captureLocationRoute('name=mark');
    if res ~= nil then
        ngx.say(res.body)
    else
        ngx.say("res is nil")
    end
end
testCaptureLocation()
--ngx.say("hello world");
