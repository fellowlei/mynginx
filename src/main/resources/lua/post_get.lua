local cjson = require "cjson"

local function http_get()
    local res = ngx.location.capture("/location?name=mark&pass=123");
    ngx.say(cjson.encode(res))
    if res.status == ngx.HTTP_OK and res.body then
        ngx.say(res.body)
    end
end

local function http_get_param()
    local res = ngx.location.capture('/location', {
        method = ngx.HTTP_GET,
        args= "name=mark&pass=123"
    })
    if res.status == ngx.HTTP_OK and res.body then
        ngx.say(res.body)
    end
end


local function http_post()
    -- set header
    ngx.req.set_header("Content-Type", "application/json;charset=utf8");
    ngx.req.set_header("Accept", "application/json");
    local res = ngx.location.capture('/location', {
        method = ngx.HTTP_GET,
        args= "name=mark&pass=123"
    })
    ngx.say(cjson.encode(res))
    if res.status == ngx.HTTP_OK and res.body then
        ngx.say(res.body)
    end
end

http_get()