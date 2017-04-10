------ conmon switch util start 201704
local function openSwitch(key)
    local response
    local succ, err, forcible=configs:set(key,'on')
    if succ then
        response = key ..' open success'
    else
        response = key ..' open fail , because ' .. err
    end
    return response
end

local function closeSwitch(key)
    local response
    local succ, err, forcible=configs:set(key,'off')
    if succ then
        response = key ..' close success'
    else
        response = key ..' close fail , because ' .. err
    end
    return response
end

local function showSwitch(key)
    local response
    local value = configs:get(key)
    if value then
        response = key ..':' .. value
    else
        response = key ..':not set'
    end
    return response
end
local function setSwitch(key,val)
    local response
    local succ, err, forcible=configs:set(key,val)
    if succ then
        response = 'set success: '..key ..':'..val
    else
        response = 'set fail , because ' .. err;
    end
    return response
end
------ conmon switch util end 201704
local switchMethod = {
    openSwitch=openSwitch,
    closeSwitch=closeSwitch,
    showSwitch=showSwitch,
    setSwitch=setSwitch
}
local method = ngx.var.method;
local password = ngx.var.password;

if password == "123" then
    local execMethod = switchMethod[method]
    if execMethod then
        local result = execMethod();
        ngx.say(result);
    else
        ngx.say("no such method")
    end
end