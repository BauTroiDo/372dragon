local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_340001 = class("item_340001", script_base)
item_340001.script_id = 340001
item_340001.g_Impact1 = 340001
item_340001.g_Impact2 = -1
item_340001.g_Impact_NotTransportList = {5929}

item_340001.g_TalkInfo_NotTransportList = {"#{GodFire_Info_062}"}

function item_340001:OnDefaultEvent(selfId, bagIndex)
end

function item_340001:IsSkillLikeScript(selfId)
    return 1
end

function item_340001:CancelImpacts(selfId)
    return 0
end

function item_340001:OnConditionCheck(selfId)
    if self:IsHaveMission(selfId, 4021) then
        self:BeginEvent(self.script_id)
        local strText = "Thiếu hiệp đang trong Trạng thái Vận Tiêu, không thể sử dụng chức năng truyền tống."
        self:AddText(strText)
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return 0
    end
    if self:GetItemCount(selfId, 40002000) >= 1 then
        self:BeginEvent(self.script_id)
        self:AddText("Ngươi đang có Ngân phiếu, đang chạy thương! Không thể sử dụng chức năng truyền tống.")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return 0
    end
    for i, ImpactId in pairs(self.g_Impact_NotTransportList) do
        if self:LuaFnHaveImpactOfSpecificDataIndex(selfId, ImpactId) then
            self:BeginEvent(self.script_id)
            self:AddText(self.g_TalkInfo_NotTransportList[i])
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            return 0
        end
    end
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    return 1
end

function item_340001:OnDeplete(selfId)
    local Level = self:GetLevel(selfId)
    local MenPai = self:LuaFnGetMenPai(selfId)
    if Level < 10 then
        return 0
    end
    if MenPai == 9 then
        self:BeginEvent(self.script_id)
        local strText = string.format("Chưa gia nhập Môn phái, không thể sử dụng vật phẩm này.")
        self:AddText(strText)
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return 0
    end
    if self:IsHaveMission(selfId, 4021) then
        self:BeginEvent(self.script_id)
        local strText = "Thiếu hiệp đang trong Trạng thái Vận Tiêu, không thể sử dụng chức năng truyền tống."
        self:AddText(strText)
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return 0
    end
    if self:GetItemCount(selfId, 40002000) >= 1 then
        self:BeginEvent(self.script_id)
        self:AddText("Ngươi đang có Ngân phiếu, đang chạy thương! Không thể sử dụng chức năng truyền tống.")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return 0
    end
    for i, ImpactId in pairs(self.g_Impact_NotTransportList) do
        if self:LuaFnHaveImpactOfSpecificDataIndex(selfId, ImpactId) then
            self:BeginEvent(self.script_id)
            self:AddText(self.g_TalkInfo_NotTransportList[i])
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            return 0
        end
    end
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_340001:MenpaiTransfer(selfId)
    local MenPai = self:LuaFnGetMenPai(selfId)
    local TargetScene
    local x
    local z
    if (MenPai >= 0 and MenPai <= 8) then
        if 0 == MenPai then
            TargetScene = 9
            x = 93
            z = 72
        end
        if 1 == MenPai then
            TargetScene = 11
            x = 106
            z = 59
        end
        if 2 == MenPai then
            TargetScene = 10
            x = 91
            z = 100
        end
        if 3 == MenPai then
            TargetScene = 12
            x = 80
            z = 87
        end
        if 4 == MenPai then
            TargetScene = 15
            x = 96
            z = 48
        end
        if 5 == MenPai then
            TargetScene = 16
            x = 86
            z = 73
        end
        if 6 == MenPai then
            TargetScene = 13
            x = 96
            z = 88
        end
        if 7 == MenPai then
            TargetScene = 17
            x = 89
            z = 47
        end
        if 8 == MenPai then
            TargetScene = 14
            x = 122
            z = 141
        end
        local sceneId = self:get_scene_id()
        if sceneId == TargetScene then
            self:SetPos(selfId, x, z)
            return
        end
        self:CallScriptFunction((400900), "TransferFunc", selfId, TargetScene, x, z)
        self:LuaFnAuditItemUseMenPaiZhaoJiLing(selfId, MenPai)
    end
end

function item_340001:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        self:MenpaiTransfer(selfId)
    end
    return 1
end

function item_340001:OnActivateEachTick(selfId)
    return 1
end

return item_340001
