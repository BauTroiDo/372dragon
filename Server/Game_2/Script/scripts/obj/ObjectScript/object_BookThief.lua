local class = require "class"
local define = require "define"
local script_base = require "script_base"
local object_BookThief = class("object_BookThief", script_base)
object_BookThief.script_id = 807003
function object_BookThief:OnDefaultEvent(selfId, targetId)
	self:LuaFnIsActivityMonster(selfId,targetId,true)
    local npcLevel = self:GetCharacterLevel(targetId)
    local nearteammembercount = self:GetNearTeamCount(selfId)
    if nearteammembercount < 1 then
        self:BeginEvent(self.script_id)
        self:AddText("#{ZSSFC_090211_07}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    local maxLevel = 0
    for i = 1, nearteammembercount do
        local memberID = self:GetNearTeamMember(selfId, i)
        local memberLevel = self:GetLevel(memberID)
        if memberLevel > maxLevel then maxLevel = memberLevel end
    end
    if maxLevel < npcLevel then
        self:BeginEvent(self.script_id)
        self:AddText("#{ZSSFC_090211_08}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    self:SetUnitReputationID(selfId, targetId, 28)
end

function object_BookThief:OnDie(selfId, killerId) end

return object_BookThief
