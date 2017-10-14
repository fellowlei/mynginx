
local _M = {}
local limit_dict = ngx.shared.limit_dict;
function _M.limitBySource(source)
--    ngx.log(ngx.ERR,"limitBySource source:"..source)
    local limit_dict = ngx.shared.limit_dict;
--    local source = ngx.var.arg_source
    local now = tonumber(ngx.time())
--    ngx.update_time()
    local key = source .."_request_sum_"..now;
    ngx.log(ngx.ERR,"limitBySource key:"..key)
    local val = limit_dict:get(source);
    if val == nil then
        return false;
    end
--    ngx.log(ngx.ERR,"limitBySource value:"..val)

    if source then
        local newval, err = limit_dict:incr(key, 1)
        if not newval and err == "not found" then
            limit_dict:add(key, 1,1)
            newval = 1
        end
        if newval > tonumber(val) then
            return true
        end
    end
    return false
end

local function sum_count(now,spend,key)
    local min = now - spend;
    local sum = 0;
    for i = now,min,-1 do
        local subkey = key..i;
        local val = limit_dict:get(subkey);
        if val ~= nil then
            sum = sum + val;
        end
    end
    return sum;
end

function _M.limitBySourceCrossTime(source)
    local now = tonumber(ngx.time())
    local prefix = source .."_request_sum_";
    local key = prefix..now;
    ngx.log(ngx.ERR,"limitBySourceCrossTime key:"..key)
    local val = limit_dict:get(source);
    if val == nil then
        return false;
    end

    if source then
        local count = sum_count(now,3,prefix);
        ngx.log(ngx.ERR,"limitBySourceCrossTime count:"..count)
        if count > tonumber(val) then
            return true
        end
        local newval, err = limit_dict:incr(key, 1)
        if not newval and err == "not found" then
            limit_dict:add(key, 1,3)
            newval = 1
        end
    end
    return false
end

function _M.setLimit(source,val)
    local limit_dict = ngx.shared.limit_dict;
    return limit_dict:set(source,val);
end
function _M.delete(source)
    local limit_dict = ngx.shared.limit_dict;
    limit_dict:set(source,nil);
end

return _M

