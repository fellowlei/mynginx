local route = require('route')
local cjson = require('cjson') 
local parser = require "redis.parser"

 local reqs = {
     {"get", "name"}
 }

 local raw_reqs = {}
 for i, req in ipairs(reqs) do
     table.insert(raw_reqs, parser.build_query(req))
 end

 local location = "/"..route.getLocation(reqs[1][2]).."?";
 ngx.say(location);
 local res = ngx.location.capture(location .. #reqs,
     { body = table.concat(raw_reqs, "") })

 if res.status ~= 200 or not res.body then
     ngx.log(ngx.ERR, "failed to query redis")
     ngx.exit(500)
 end

 local replies = parser.parse_replies(res.body, #reqs)
 for i, reply in ipairs(replies) do
     ngx.say(reply[1])
 end
