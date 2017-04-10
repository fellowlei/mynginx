local redis = require "resty.redis"
local method = ngx.var.method;
---- redis util
local _M = {_VERSION='0.01' }
function _M.read(key,field)
    local rds, err = redis:new()
    if not rds then
        ngx.log(ngx.ERR, "declare redis error: %s:%s",err)
        return false,tostring(err)
    end
    rds:set_timeout(1000)
    local ok, err = rds:connect("localhost",6379)
    if not ok then
        ngx.log(ngx.ERR, string.format("connect redis error:%s:%s, %s",err))
        return false,tostring(err)
    end
    local val = rds:hget(key,field)
    if val then
        return true,tostring(val)
    end
end

function _M.write(key,field,value)
    local rds, err = redis:new()
    if not rds then
        ngx.log(ngx.ERR, "declare redis error: %s:%s",err)
       return false,tostring(err)
    end
    rds:set_timeout(1000)
    local ok, err = rds:connect("localhost",6379)
    if not ok then
        ngx.log(ngx.ERR, string.format("connect redis error:%s:%s, %s",err))
        return false,tostring(err)
    end
    local result = rds:hset(key,field,value)
    if result then
        return true,tostring(result)
    end
end

function _M.send_file(file)
    if file then
        ngx.log(ngx.ERR,"### send file:" .. tostring(file))
        local f = assert(io.open(file, "r"))
        local result = f:read("*a")

        if not result then
            result = "error happend"
        end
        f:close()
        return result
    end
end

return _M