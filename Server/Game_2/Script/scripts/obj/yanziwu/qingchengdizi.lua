local class = require "class"
local define = require "define"
local script_base = require "script_base"
local qingchengdizi = class("qingchengdizi", script_base)
qingchengdizi.g_KillMonsCount_Qincheng = 20
qingchengdizi.g_KillMonsCount_Qinjia = 21
qingchengdizi.g_KillMonsCount_Lama = 22
function qingchengdizi:OnDie(selfId, killerId)
    local nCount = self:LuaFnGetCopySceneData_Param(self.g_KillMonsCount_Qincheng)
    if nCount < 0 then nCount = 0 end
    self:LuaFnSetCopySceneData_Param(self.g_KillMonsCount_Qincheng, nCount + 1)
end

return qingchengdizi
