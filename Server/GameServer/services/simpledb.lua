local skynet = require "skynet"
local DBEnginer = require "dbenginer":getinstance()
local CMD = setmetatable({}, {
    __index = function(_, k)
        local method = DBEnginer[k]
        return function(...) return method(DBEnginer, ...) end
    end
})

skynet.start(function()
    skynet.dispatch("lua", function(_, _, command, ...)
        --skynet.logi("id =", DBEnginer.id, command, table.tostr(...))
        local f = assert(CMD[command], command)
        skynet.ret(skynet.pack(f(...)))
    end)
end)
