------ lua shard cache start  ------
--lua_shared_dict shared_cache_1 100m;
--lua_shared_dict shared_cache_2 100m;
--lua_shared_dict shared_cache_3 100m;

local function find_cache_shard(key)
    if key ~= nil then
        local shared = string.byte(key,1) % 3
        return ngx.shared['shared_cache_'..shared]
    end
end

local function get(key)
    local cache = find_cache_shard(key);
    return cache:get(key);
end

local function set(key,val)
    local cache = find_cache_shard(key);
    cache:set(key,val,60)
end

------ lua shard cache end ------