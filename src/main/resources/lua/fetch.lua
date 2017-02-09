local configs = ngx.shared.configs;
configs:set("fetchback",1);

-- route location
local function getFetchbackUrl()
    --ngx.say('fetchbackurl')
    local flag = configs:get("fetchback");
    if(flag == 1) then
        return "/fetchback_source1"
    else
        return "/fetchback_source2";
    end
end
-- fetchback route
local function captureLocation(args)
	local res = ngx.location.capture("/fetchback_source1",{args=args});
	if res.status ~= ngx.HTTP_OK then
	    ngx.say("route 2")
	    res = ngx.location.capture("/fetchback_source2",{args=args});
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




