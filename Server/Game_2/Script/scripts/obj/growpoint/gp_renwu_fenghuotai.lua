local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local gp_renwu_fenghuotai = class("gp_renwu_fenghuotai", script_base)
gp_renwu_fenghuotai.g_missionId = 552
function gp_renwu_fenghuotai:OnCreate(growPointType, x, y)
    local ItemCount = 0
    self:ItemBoxEnterScene(x, y, growPointType, define.QUALITY_MUST_BE_CHANGE, ItemCount)
end

function gp_renwu_fenghuotai:OnOpen(selfId, targetId)
    if not self:HaveItem(selfId, 40002070) then
        self:BeginEvent(self.script_id)
        local strText = "Cần Hỏa Chiết Tử"
        self:AddText(strText)
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return define.OPERATE_RESULT.OR_NOT_ENOUGH_ITEM
    end
    if self:HaveItem(selfId, 40002069) < 0 then
        self:BeginEvent(self.script_id)
        local strText = "Yêu cầu Lang Phân"
        self:AddText(strText)
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return define.OPERATE_RESULT.OR_NOT_ENOUGH_ITEM
    end
    return define.OPERATE_RESULT.OR_OK
end

function gp_renwu_fenghuotai:OnRecycle(selfId, targetId)
    return 0
end

function gp_renwu_fenghuotai:OnProcOver(selfId, targetId)
    local Ret1 = self:DelItem(selfId, 40002069, 1)
    local Ret2 = self:DelItem(selfId, 40002070, 1)
    if (Ret1 and Ret2 ) then
        local misIndex = self:GetMissionIndexByID(selfId, self.g_missionId)
        self:SetMissionByIndex(selfId, misIndex, 0, 1)
        self:SetMissionByIndex(selfId, misIndex, 1, 1)
        self:BeginEvent(self.script_id)
        local strText = "Xua Đuổi Ong Đen(hoàn thành)"
        self:AddText(strText)
        self:EndEvent()
        self:DispatchMissionTips(selfId)
    end
    return define.OPERATE_RESULT.OR_OK
end

function gp_renwu_fenghuotai:OnTickCreateFinish(growPointType, tickCount)
end

return gp_renwu_fenghuotai
