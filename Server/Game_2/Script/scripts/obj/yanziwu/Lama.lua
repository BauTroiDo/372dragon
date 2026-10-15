local class = require "class"
local define = require "define"
local script_base = require "script_base"
local Lama = class("Lama", script_base)
Lama.g_KillMonsCount_Qincheng = 20
Lama.g_KillMonsCount_Qinjia = 21
Lama.g_KillMonsCount_Lama = 22
function Lama:OnDie(selfId, killerId)
    local nCount = self:LuaFnGetCopySceneData_Param(self.g_KillMonsCount_Lama)
    if nCount < 0 then nCount = 0 end
    self:LuaFnSetCopySceneData_Param(self.g_KillMonsCount_Lama, nCount + 1)
end

return Lama
