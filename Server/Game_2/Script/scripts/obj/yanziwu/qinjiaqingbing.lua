local class = require "class"
local define = require "define"
local script_base = require "script_base"
local qinjiaqingbing = class("qinjiaqingbing", script_base)
qinjiaqingbing.g_KillMonsCount_Qincheng = 20
qinjiaqingbing.g_KillMonsCount_Qinjia = 21
qinjiaqingbing.g_KillMonsCount_Lama = 22
function qinjiaqingbing:OnDie(selfId, killerId)
    local nCount = self:LuaFnGetCopySceneData_Param(self.g_KillMonsCount_Qinjia)
    if nCount < 0 then nCount = 0 end
    self:LuaFnSetCopySceneData_Param(self.g_KillMonsCount_Qinjia, nCount + 1)
end

return qinjiaqingbing
