-- utils

local _M = { _VERSION = '0.01' }
-- split string as table
function _M.split(str, sep)
    sep = sep or ","
    local left = 1
    local splitIndex = 1
    local splitArray = {}
    if str then
        while true do
            local right = string.find(str, sep, left)
            if not right then
                splitArray[splitIndex] = string.sub(str, left, string.len(str))
                break
            end
            splitArray[splitIndex] = string.sub(str, left, right - 1)
            left = right + string.len(sep)
            splitIndex = splitIndex + 1
        end
    end
    return splitArray
end

function _M.dumpList(list)
    print("----list dump----")
    for i in  ipairs(list) do
        print(i .. ":" ..list[i])
    end
end

function _M.dumpMap(map)
    print("----map dump----")
    for k,v in pairs(map) do
        print(k ..":"..v)
    end
end

function _M.dumpUrlParam(url)
    local params = split(url,"?")
    local paramList = split(params[2],"&")
    dumpList(paramList)
end

return _M