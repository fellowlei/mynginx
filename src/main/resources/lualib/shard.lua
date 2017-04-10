local mmh2 = require "resty.murmurhash2"

-- redis shard
local redis = { "redis_01", "redis_02" }

local function getLocation(id)
    local hash = mmh2(id .. "");
    local index = hash % #redis;
    local index = index + 1; -- begin 0
    return redis[index];
end

-- test hash
local function get_shard(key)
    local hash = mmh2(key)
    ngx.say(key..": hash result:" .. hash)
end

-- test
local function test()
    for i = 1, 8 do
        local loc = getLocation(i)
        ngx.say(loc)
    end
end

local shared = {
    getLocation = getLocation,
    hashtest = hashtest
}
return shared
