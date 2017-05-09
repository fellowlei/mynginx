local configs = ngx.shared.configs 		--nginx 参数配置中心
local password = "123"


----------------------------------------------------NEW SWITCH METHOD START----------------------------
local switch_map = {
    read_switch_key = {name="读开关",default="on",value="off"},
    write_switch_key = {name="写开关",default="on",value="off"}
}
-- get value
local function get_value(obj)
    if obj.value ~= nil then
        return obj.value
    end
    if obj.default ~= nil then
        return obj.default
    end
end
-- show all switch
local function show_all_switch()
    local buf = "--------------\r\n"
    for k,v in pairs(switch_map) do
        buf = buf .. k .. ":"..get_value(v).."\r\n"
    end
    buf = buf .. "--------------\r\n"
    return buf
end
-- common switch method : show,open,close
local function do_switch(op,name)
    if nil ~= switch_map[name] then
        local obj = switch_map[name]
        if op == nil or op == "show" then
            get_value(obj)
        elseif op == "open" then
            obj.value ="on"
            return obj.value
        elseif op == "close" then
            obj.value = "off"
            return obj.value
        elseif op == "showall" then
            return show_all_switch()
        end
    else
        return "key:" .. name .. " not exists!"
    end
end

----------------------------------------------------NEW SWITCH METHOD END----------------------------

local methods = {
    do_switch = do_switch;
}
--set_unescape_uri  $key $arg_key;

local method  = ngx.var.method 		--配置处理方法:
local pwd = ngx.var.pwd 		--操作密码
local op = ngx.var.op 			--操作类型
local key = ngx.var.key 		--开关名称

if password == pwd then
    local execute_method=methods[method]
    if execute_method then
        ngx.say(execute_method(op,key))
    else
        ngx.say('no such method')
    end
else
    ngx.say("password wrong")
end


