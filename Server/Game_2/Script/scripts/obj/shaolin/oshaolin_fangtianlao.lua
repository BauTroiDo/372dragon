local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshaolin_fangtianlao = class("oshaolin_fangtianlao", script_base)
oshaolin_fangtianlao.g_MissionId = 1060
oshaolin_fangtianlao.script_id = 009016
function oshaolin_fangtianlao:OnDefaultEvent(selfId, targetId)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    self:BeginEvent(self.script_id)
    self:AddText("  Gần đây ta luôn cảm thấy xương cốt suy yếu.")
    if self:IsHaveMission(selfId, self.g_MissionId) then
        if self:GetMissionParam(selfId, misIndex, 0) < 1 and self:GetMissionParam(selfId, misIndex, 3) == 2 then
            self:AddNumText("Cho ngươi Tráng Cốt Xá Lợi.", 8, 0)
        end
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oshaolin_fangtianlao:OnEventRequest(selfId, targetId, arg, index)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    if index == 0 then
        if self:HaveItemInBag(selfId, 30202022) then
            self:DelItem(selfId, 30202022, 1)
            self:SetMissionByIndex(selfId, misIndex, 0, 1)
            self:BeginEvent(self.script_id)
            self:AddText("Đa tạ ngươi Tráng Cốt Xá Lợi.")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
            self:BeginEvent(self.script_id)
            self:AddText("Nhiệm vụ hoàn thành!")
            self:EndEvent()
            self:DispatchMissionTips(selfId)
        else
            self:BeginEvent(self.script_id)
            self:AddText("Tráng Cốt Xá Lợi? Ở đâu?")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        end
    end
end

return oshaolin_fangtianlao
