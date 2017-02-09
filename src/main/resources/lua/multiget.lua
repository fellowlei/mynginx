local route = require('route')
local cjson = require('cjson') 
local parser = require "redis.parser"

-- multi redis get
local function multiget(cmdlist)
  local reqs = {}
  for i,req in ipairs(cmdlist) do 
 	local raw_reqs = {}
        for j, req2 in ipairs(req) do
		table.insert(raw_reqs,parser.build_query(req2))
	end
	--ngx.say(req[1][2].." route ".. route.getLocation(req[1][2]));
 	table.insert(reqs,{"/"..route.getLocation(req[1][2]).."?"..#req,{
		body=table.concat(raw_reqs,"")}});
  end
 
  local resps = { ngx.location.capture_multi(reqs) }
  return resps;
end
 -- test multi redis get
local function testMultiGet()
  local cmd1 = {{"set","name1","mark1"},{"get","name1"}}
  local cmd2 = {{"set","name2","mark2"},{"get","name2"}}

  local cmdlist = {}
  table.insert(cmdlist,cmd1)
  table.insert(cmdlist,cmd2)
  
  local keyList = {}
  table.insert(keyList,"name1")
  table.insert(keyList,"name2")
 
  local resps = multiget(cmdlist); 
  for i, resp in ipairs(resps) do
 	if resp.status == 200 and resp.body then
		local replies = parser.parse_replies(resp.body,#cmdlist[i])
		for j,reply in ipairs(replies) do
			ngx.say(keyList[i].."="..reply[1])
		end
	end
  end
end

testMultiGet();
