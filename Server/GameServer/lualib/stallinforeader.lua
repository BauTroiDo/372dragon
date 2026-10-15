local class = require "class"
local iostream = require "iostream"
local skynet = require "skynet"
local reader = class("reader")

function reader:load(fn)
    local stall_info = {}
    -- Smart routing: absolute/relative paths with "/" pass through directly
    local fullFilName
    if fn:sub(1, 1) == "/" or fn:find("/") then
        fullFilName = fn
    else
        local config_path = skynet.getenv("config_path")
        fullFilName = string.format(config_path, fn)
    end
    local file = assert(io.open(fullFilName, 'r'), 'Error loading file : ' .. fullFilName)
    local istream = iostream.bistream
    local is = istream.new()
    is:attach(file:read("*a"))
    stall_info.ver = is:readint()
    stall_info.width = is:readint()
    stall_info.height = is:readint()
    stall_info.map = {}
    for y = 1, stall_info.height do
        for x = 1, stall_info.width do
            stall_info.map[x] = stall_info.map[x] or {}
            local inf = {}
            inf.can_stall = is:readuchar() == 1
            inf.trade_tax = is:readuchar()
            inf.pos_tax = is:readint()
            inf.ext = is:readuchar()
            stall_info.map[x][y] = inf
            if inf.can_stall then
                print("stall_info =", fullFilName, table.tostr(inf), "x =", x, ";y =", y)
            end
        end
    end
    return stall_info
end

return reader