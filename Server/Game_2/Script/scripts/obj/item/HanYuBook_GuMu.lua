local class = require "class"
local define = require "define"
local script_base = require "script_base"
local HanYuBook_GuMu = class("HanYuBook_GuMu", script_base)
HanYuBook_GuMu.script_id = 300066
HanYuBook_GuMu.g_NoRMBBuffID = 5901
HanYuBook_GuMu.g_RMBBuffID = 5902
HanYuBook_GuMu.g_SpouseBuffID = 5704
function HanYuBook_GuMu:OnDefaultEvent(selfId, bagIndex) end

function HanYuBook_GuMu:IsSkillLikeScript(selfId) return 1 end

function HanYuBook_GuMu:CancelImpacts(selfId) return 0 end

function HanYuBook_GuMu:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then return 0 end
    local sceneId = self:GetSceneID()
    if sceneId ~= 194 then
        self:ShowTips(selfId, "Bí quyết này vô hiệu trong cảnh này")
        return 0
    end
    if self:GetLevel(selfId) < 70 then
        self:ShowTips(selfId, "Chưa đủ cấp 70, không dùng được")
        return
    end
    local lastDayTime = self:GetMissionData(selfId, define.MD_ENUM.MD_HANYUBED_USEBOOK_LASTDAY)
    if lastDayTime >= 3 then
        self:ShowTips(selfId,
                      "Hôm nay bạn đã dùng 3 lần Hàn Ngọc Cốc Hành Công Yếu Quyết")
        return 0
    end
    if self:LuaFnHaveImpactOfSpecificDataIndex(selfId, self.g_NoRMBBuffID) then
        self:ShowTips(selfId, "Ngươi đã ở trong trạng thái Tu luyện.")
        return 0
    end
    if self:LuaFnHaveImpactOfSpecificDataIndex(selfId, self.g_RMBBuffID) or self:LuaFnHaveImpactOfSpecificDataIndex(selfId, self.g_SpouseBuffID)then
        self:ShowTips(selfId, "Ngươi đã ở trong trạng thái Tu luyện.")
        return 0
    end
    return 1
end

function HanYuBook_GuMu:OnDeplete(selfId)
    if self:LuaFnDepletingUsedItem(selfId) then return 1 end
    return 0
end

function HanYuBook_GuMu:OnActivateOnce(selfId)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId,
                                       self.g_NoRMBBuffID, 0)
    self:CallScriptFunction(808072, "OnPlayerUseHanYuBook", selfId)
    local CiSHU = self:GetMissionData(selfId, define.MD_ENUM.MD_HANYUBED_USEBOOK_LASTDAY)
    self:SetMissionData(selfId, define.MD_ENUM.MD_HANYUBED_USEBOOK_LASTDAY, CiSHU + 1)
    return 1
end

function HanYuBook_GuMu:OnActivateEachTick(selfId) return 1 end

function HanYuBook_GuMu:ShowTips(selfId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return HanYuBook_GuMu
