local configs = ngx.shared.configs;
configs:set("fetchback",1);
local now = ngx.time();
if configs:get("time") ~= nil then
	ngx.say(configs:get("time"));
else
	configs:set("time","60",5);
	ngx.say("set time");
end
