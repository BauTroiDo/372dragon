-- Mechanical compatibility with converted GL gameplay scripts. No fake
-- gameplay defaults: operations delegate to the real implementation.
local M = {}
function M.install(base)
    function base:SendOResultToPlayer(selfId, result)
        return self:LuaFnSendOResultToPlayer(selfId, result)
    end
    function base:tostring(value) return tostring(value) end
    function base:abs(value) return math.abs(value) end
    function base:format(...) return string.format(...) end
    function base:getn(value) return #value end
    function base:random(...) return math.random(...) end
end
return M
