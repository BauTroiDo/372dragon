local class = require "class"
local define = require "define"
local script_base = require "script_base"
local murenkuilei = class("murenkuilei", script_base)
murenkuilei.g_KillMonsCount_Qincheng = 20
murenkuilei.g_KillMonsCount_Qinjia = 21
murenkuilei.g_KillMonsCount_Lama = 22
function murenkuilei:OnDie(selfId)
    local nNpcLevel = self:GetLevel(selfId)
    local nBaseLevel = math.floor(nNpcLevel / 10)
    local nBuffId = 10176 + nBaseLevel
    self:LuaFnNpcChat(selfId, 0, "Ta sắp nổ tung rồi!")
    local x, z = self:GetWorldPos(selfId)
    self:LuaFnCreateSpecialObjByDataIndex(selfId, 100, x, z)
    local nMonsterNum = self:GetMonsterCount()
    for i = 1, nMonsterNum do
        local nMonsterId = self:GetMonsterObjID(i)
        local xx, zz = self:GetWorldPos(nMonsterId)
        if (x - xx) * (x - xx) + (z - zz) * (z - zz) < 25 then
            self:LuaFnSendSpecificImpactToUnit(nMonsterId, nMonsterId, nMonsterId, nBuffId, 100)
        end
    end
    local nHumanNum = self:LuaFnGetCopyScene_HumanCount()
    if nHumanNum < 1 then return end
    for i = 1, nHumanNum do
        local PlayerId = self:LuaFnGetCopyScene_HumanObjId(i)
        local xx, zz = self:GetWorldPos(PlayerId)
        if (x - xx) * (x - xx) + (z - zz) * (z - zz) < 25 then
            self:LuaFnSendSpecificImpactToUnit(selfId, selfId, PlayerId, nBuffId, 100)
        end
    end
end

return murenkuilei
