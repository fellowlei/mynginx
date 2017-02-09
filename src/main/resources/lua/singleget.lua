local route = require('route')
local cjson = require('cjson') 
local parser = require "redis.parser"

-- single redis get
local function singleget(cmdlist)
 	local raw_reqs = {}
 	for i, req in ipairs(cmdlist) do
     		table.insert(raw_reqs, parser.build_query(req))
 	end

 	local location = "/"..route.getLocation(cmdlist[1][2]).."?";
 	--ngx.say(location);
 	local res = ngx.location.capture(location .. #cmdlist,
     		{ body = table.concat(raw_reqs, "") })
	if res.status == 200 and res.body then
		return res;
	else
		return nil;
	end
end

local function testSingleGet()
	local cmdlist = {{"set","name","mark"},{"get", "name"}}
	local res = singleget(cmdlist)
	if res ~= nil then
 		local replies = parser.parse_replies(res.body, #cmdlist)
 		for i, reply in ipairs(replies) do
     			ngx.say(reply[1])
 		end
	end
end

-- test
testSingleGet();
