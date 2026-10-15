local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4831 = class("item_4831", script_base)
item_4831.script_id = 334831
item_4831.g_Impact1 = 34831
item_4831.g_Impact2 = -1
item_4831.g_Yinpiao = 40002000
function item_4831:OnDefaultEvent(selfId, bagIndex)
end

function item_4831:IsSkillLikeScript(selfId)
    return 1
end

function item_4831:CancelImpacts(selfId)
    return 0
end

function item_4831:OnConditionCheck(selfId)
    if self:GetItemCount(selfId, self.g_Yinpiao) >= 1 then
        self:BeginEvent(self.script_id)
        self:AddText("Ngươi đang có Ngân phiếu, đang chạy thương! Không thể sử dụng chức năng truyền tống.")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return
    end
    if self:IsHaveMission(selfId, 4021) then
        self:BeginEvent(self.script_id)
        local strText = "Thiếu hiệp đang trong Trạng thái Vận Tiêu, không thể sử dụng chức năng truyền tống."
        self:AddText(strText)
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return 0
    end
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_4831:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4831:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact1, 0)
    end
    return 1
end

function item_4831:OnActivateEachTick(selfId)
    return 1
end

return item_4831
