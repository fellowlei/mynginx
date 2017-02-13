local mmh2 = require "resty.murmurhash2"


-- hash test
local function hashtest()
    local hash = mmh2 "test" -- hash contains number 403862830
    ngx.say("hash result:" .. hash)
end

-- redis shard
local redis = { "redis_01", "redis_02" }

local function getLocation(id)
    local hash = mmh2(id .. "");
    local index = hash % #redis;
    local index = index + 1; -- begin 0
    return redis[index];
end

-- test
local function test()
    for i = 1, 8 do
        local loc = getLocation(i)
        ngx.say(loc)
    end
end

local route = {
    getLocation = getLocation,
    hashtest = hashtest
}
return route
