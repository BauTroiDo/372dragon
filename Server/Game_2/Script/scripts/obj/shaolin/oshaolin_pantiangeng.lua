local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshaolin_pantiangeng = class("oshaolin_pantiangeng", script_base)
oshaolin_pantiangeng.g_MissionId = 1060
oshaolin_pantiangeng.script_id = 009015
function oshaolin_pantiangeng:OnDefaultEvent(selfId, targetId)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    self:BeginEvent(self.script_id)
    self:AddText("  Gần đây luôn cảm thấy sức lực không đủ.")
    if self:IsHaveMission(selfId, self.g_MissionId) then
        if self:GetMissionParam(selfId, misIndex, 0) < 1 and self:GetMissionParam(selfId, misIndex, 3) == 1 then
            self:AddNumText("Cho ngươi Đại Lực Xá Lợi.", 8, 0)
        end
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oshaolin_pantiangeng:OnEventRequest(selfId, targetId, arg, index)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    if index == 0 then
        if self:HaveItemInBag(selfId, 30202001) then
            self:DelItem(selfId, 30202001, 1)
            self:SetMissionByIndex(selfId, misIndex, 0, 1)
            self:BeginEvent(self.script_id)
            self:AddText("Đa tạ ngươi Đại Lực Xá Lợi.")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
            self:BeginEvent(self.script_id)
            self:AddText("Nhiệm vụ hoàn thành!")
            self:EndEvent()
            self:DispatchMissionTips(selfId)
        else
            self:BeginEvent(self.script_id)
            self:AddText("Đại Lực Xá Lợi? Ở đâu?")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        end
    end
end

return oshaolin_pantiangeng
