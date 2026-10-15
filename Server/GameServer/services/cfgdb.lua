local skynet = require "skynet"
local class = require "class"
local CfgHelper = require "cfghelper":getinstance()
local CMD = setmetatable({}, {
    __index = function(_, k)
        local method = CfgHelper[k]
        assert(method, k)
        return function(...) return method(CfgHelper, ...) end
    end
})

skynet.start(function()
    skynet.dispatch("lua", function(_, _, command, ...)
        local f = CMD[command]
        if not f then
            skynet.logi("ERROR: [CfgDB] Command not found:", command)
            error(string.format("CfgDB: Unknown command '%s'", command))
        end
        local results = table.pack(pcall(f, ...))
        local ok = results[1]
        if not ok then
            skynet.logi("ERROR: [CfgDB] Command failed:", command, "error:", results[2])
            error(results[2])
        end
        skynet.ret(skynet.pack(table.unpack(results, 2, results.n)))
    end)
end)
