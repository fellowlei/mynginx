local configs = ngx.shared.configs;
local cjson = require "cjson"
local on = 1
local off = 0
local function init()
	local obj = {};
	configs:set("switch",{});
end
local function addNew(name)
	--ngx.say(name);
	--ngx.say(configs:get("switch")== nil);
	if configs:get("switch") == nil then
		local tmp = {}
		tmp[name] = name;
		local json = cjson.encode(tmp);
		configs:set("switch",json);
		ngx.say(configs:get("switch"));
		ngx.say("init");
	else
		local json = configs:get("switch");
		local tmp = cjson.decode(json);
		tmp[name] =name;
		json = cjson.encode(tmp);
		configs:set("switch",json);
		ngx.say("add switch ".. name);
	end
end
local function listSwitch()
	if configs:get("switch") == nil then
		ngx.say("empty list");
	else
		local json = configs:get("switch");
		local tmp = cjson.decode(json);
		for k,v in pairs(tmp) do
			--ngx.say(k.."="..v);
			ngx.say(k.."="..configs:get(v).."|");
		end
	end
end
local function setConfig(name,val)
	configs:set(name,val)
	addNew(name);
	ngx.say(name .. " set value " .. val);
end
local function getConfig(name)
	return configs:get(name)
end

local function open(name)
	configs:set(name,on);
	addNew(name);
	ngx.say(name .. " is open");
end

local function close(name)
	configs:set(name,off);
	addNew(name);
	ngx.say(name .. " is close");
end

local function isOpen(name)
	local value = configs:get(name)
	if(value ~= nil and value == on) then
		return true;
	else
		return false;
	end
end

local function access()
	local method = ngx.var.method;
	local name = ngx.var.name;
	local value = ngx.var.value;
	local password = ngx.var.password;
	
	if password ~= "password" then
		ngx.say("invalud password");
		return nil;
	end
	
	if method == "setConfig" then
		setConfig(name,val)
		return;
	elseif method == "getConfig" then
		return getConfig(name);
	elseif method == "open" then
		open(name);
		return;
	elseif method == "close" then
		close(name);
		return;
	elseif method == "list" then
		listSwitch();
		return;
	else
		ngx.say("invalid method");
		return nil;
	end
end

access();
