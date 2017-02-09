local route = require('route')
local mmh2 = require "resty.murmurhash2"
local hash = mmh2(ngx.var.key) -- hash contains number 403862830
ngx.say(ngx.var.key..": hash result:" .. hash)

ngx.say(route.getLocation(ngx.var.key));


