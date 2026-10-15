local skynet = require "skynet"
local confs = require "cluster_db_conf"
local CMD = {}

local function init()

end


function CMD.get_conf(name)
    return confs[name]
end


skynet.start(function()
    skynet.dispatch("lua", function(_, _, command, ...)
        local f = assert(CMD[command], command)
        skynet.ret(skynet.pack(f(...)))
    end)
    init()
end)