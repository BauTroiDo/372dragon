local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_4918 = class("item_4918", script_base)
item_4918.script_id = 334918
item_4918.g_levelRequire = 1
item_4918.g_radiusAE = 3.0
item_4918.g_standFlag = 1
item_4918.g_effectCount = 4
item_4918.g_Impact1 = 34918
item_4918.g_Impact2 = -1
function item_4918:OnDefaultEvent(selfId, bagIndex)
end

function item_4918:IsSkillLikeScript(selfId)
    return 1
end

function item_4918:CancelImpacts(selfId)
    return 0
end

function item_4918:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    local targetId = self:LuaFnGetTargetObjID(selfId)
    if (0 <= targetId) then
        if not self:LuaFnIsFriend(targetId, selfId) then
            self:LuaFnSendOResultToPlayer(selfId, define.OPERATE_RESULT.OR_INVALID_TARGET)
            return 0
        end
        if not self:LuaFnIsFriend(selfId, targetId) then
            self:LuaFnSendOResultToPlayer(selfId, define.OPERATE_RESULT.OR_INVALID_TARGET)
            return 0
        end
        local SelfSex = self:LuaFnGetSex(selfId)
        local TargetSex = self:LuaFnGetSex(targetId)
        if (SelfSex == TargetSex) then
            self:LuaFnSendOResultToPlayer(selfId, define.OPERATE_RESULT.OR_INVALID_TARGET)
            return 0
        end
    end
    return 1
end

function item_4918:OnDeplete(selfId)
    local targetId = self:LuaFnGetTargetObjID(selfId)
    if self:LuaFnGetPropertyBagSpace(selfId) < 1 then
    end
    if self:LuaFnGetPropertyBagSpace(targetId) < 1 then
        self:MsgBox(selfId, "Đối phương không có đủ không gian túi")
        return 0
    end
    local nItemBagIndex = self:GetBagPosByItemSn(selfId, 30509011)
    local szTransfer = self:GetBagItemTransfer(selfId, nItemBagIndex)
    local targetId = self:LuaFnGetTargetObjID(selfId)
    local szNameSelf = self:GetName(selfId)
    local szNameTarget = self:GetName(targetId)
    local randMessage = math.random(3)
    local message
    if randMessage == 1 then
        message =
            string.format(
            "@*;SrvMsg;SCA:#{_INFOUSR%s}#{GiveRose_00}#{_INFOMSG%s}#{GiveRose_01}#{_INFOUSR%s}#{GiveRose_02}",
            szNameSelf,
            szTransfer,
            szNameTarget
        )
    elseif randMessage == 2 then
        message =
            string.format(
            "@*;SrvMsg;SCA:#{_INFOUSR%s}#{GiveRose_03}#{_INFOMSG%s}#{GiveRose_04}#{_INFOUSR%s}#{GiveRose_05}",
            szNameSelf,
            szTransfer,
            szNameTarget
        )
    else
        message =
            string.format(
            "@*;SrvMsg;SCA:#{_INFOUSR%s}#{GiveRose_03}#{_INFOMSG%s}#{GiveRose_06}#{_INFOUSR%s}#{GiveRose_07}",
            szNameSelf,
            szTransfer,
            szNameTarget
        )
    end
    self:AddGlobalCountNews(message)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function item_4918:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact1) then
        local targetId = self:LuaFnGetTargetObjID(selfId)
        if (0 <= targetId) then
            if self:LuaFnIsFriend(targetId, selfId) then
                self:LuaFnSendSpecificImpactToUnit(selfId, selfId, targetId, self.g_Impact1, 0)
                self:LuaFnSendSpecificImpactToUnit(selfId, selfId, targetId, 66, 0)
                local nFriendPoint = self:LuaFnGetFriendPoint(selfId, targetId)
                if nFriendPoint >= 9999 then
                    self:BeginEvent(self.script_id)
                    self:AddText("Độ hảo hữu giữa ngươi và đối phương đã đạt tới giới hạn.")
                    self:EndEvent()
                    self:DispatchMissionTips(selfId)
                else
                    self:BeginEvent(self.script_id)
                    self:AddText("Độ hữu hảo giữa ngươi và đối phương đã tăng 5000")
                    self:EndEvent()
                    self:DispatchMissionTips(selfId)
                end
                local namSelf = self:GetName(selfId)
                local namTarget = self:GetName(targetId)
                self:LuaFnSendSpecificImpactToUnit(targetId, targetId, targetId, 18, 0)
                local acme_SongHua = self:GetMissionData(selfId, define.MD_ENUM.MD_SONGHUA)
                local acme_ShouHua = self:GetMissionData(targetId, define.MD_ENUM.MD_SHOUHUA)
                self:SetMissionData(selfId, define.MD_ENUM.MD_SONGHUA, acme_SongHua + 1)
                self:LuaFnSetAcmeTopList(selfId, 4, acme_SongHua + 1)
                self:SetMissionData(targetId, define.MD_ENUM.MD_SHOUHUA, acme_ShouHua + 1)
                self:LuaFnSetAcmeTopList(targetId, 5, acme_ShouHua + 1)
                local lstBounty = {
                    [0] = {10124021, 228, "Mân Côi Tiên Tử"},
                    [1] = {10124020, 227, "Tình Thánh"}
                }

                local untBounty
                if self:GetSex(selfId) == 0 then
                    untBounty = lstBounty[0]
                else
                    untBounty = lstBounty[1]
                end
                if self:TryRecieveItem(selfId, untBounty[1], 1) >= 0 then
                    self:MsgBox(selfId, "Ngươi nhận được một kiện" .. self:GetItemName(untBounty[1]))
                end
                self:AwardTitle(selfId, 8, untBounty[2])
                self:LuaFnDispatchAllTitle(selfId)
                self:MsgBox(selfId, "Ngươi nhận được [" .. untBounty[3] .. "]danh hiệu.")
                if self:GetSex(targetId) == 0 then
                    untBounty = lstBounty[0]
                else
                    untBounty = lstBounty[1]
                end
                if self:TryRecieveItem(targetId, untBounty[1], 1) >= 0 then
                    self:MsgBox(targetId, "Ngươi nhận được một kiện" .. self:GetItemName(untBounty[1]))
                end
                self:AwardTitle(targetId, 8, untBounty[2])
                self:LuaFnDispatchAllTitle(targetId)
                self:MsgBox(targetId, "Ngươi nhận được [" .. untBounty[3] .. "]danh hiệu.")
            end
        end
    end
    return 1
end

function item_4918:OnActivateEachTick(selfId)
    return 1
end

function item_4918:MsgBox(selfId, Msg)
    if Msg == nil then
        return
    end
    self:BeginEvent(self.script_id)
    self:AddText(Msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return item_4918
