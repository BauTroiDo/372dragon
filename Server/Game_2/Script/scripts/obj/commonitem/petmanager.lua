local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local petmanger = class("petmanger", script_base)
petmanger.script_id = 335805
petmanger.g_Impact = -1
petmanger.g_UseMax = 4
petmanger.g_UseUnit = {
    [30509500] = 1,
    [30509501] = 2,
    [30509502] = 3,
    [30509503] = 4
}

function petmanger:OnDefaultEvent(selfId, bagIndex)
end

function petmanger:IsSkillLikeScript(selfId)
    return 1
end

function petmanger:CancelImpacts(selfId)
    return 0
end

function petmanger:OnConditionCheck(selfId)
    local bagId = self:LuaFnGetBagIndexOfUsedItem(selfId)
    local numExtra = self.g_UseUnit[self:GetItemTableIndexByIndex(selfId, bagId)]
    if numExtra == nil then
        return 0
    end
    if not self:LuaFnLockCheck(selfId, bagId, 0) then
        self:MsgBox(selfId, "Vật phẩm này đã bị khóa!")
        return 0
    end
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
    if self:GetPetNumExtra(selfId) >= self.g_UseMax then
        self:MsgBox(selfId, "Không gian mang theo Trân Thú của ngươi đã đạt giới hạn, không thể tăng thêm không gian mới.")
        return 0
    end
    local curShouLanLevel = self:GetPetNumExtra(selfId)
    if curShouLanLevel ~= (numExtra - 1) then
        local szMsg = string.format(
            "Chuồng thú hiện tại của ngài đã đạt cấp %d, nếu muốn tăng số lượng Trân Thú mang theo, xin hãy sử dụng chuồng thú cấp %d.",
            curShouLanLevel, curShouLanLevel + 1)
        self:MsgBox(selfId, szMsg)
        return 0
    end
    return 1
end

function petmanger:OnDeplete(selfId)
    return 1
end

function petmanger:OnActivateOnce(selfId)
    if (-1 ~= self.g_Impact) then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact, 0)
    end
    local nBagIndex = self:LuaFnGetBagIndexOfUsedItem(selfId)
    local numExtra = self.g_UseUnit[self:GetItemTableIndexByIndex(selfId, nBagIndex)]
    local szTran = self:GetBagItemTransfer(selfId, nBagIndex)
    local strMsg
    if numExtra ~= nil and self:EraseItem(selfId, nBagIndex) then
        if self:SetPetNumExtra(selfId, numExtra) then
            if numExtra == 1 then
                self:MsgBox(selfId, "Không gian mang theo Trân Thú của ngài đã tăng đến" .. self:GetPetNumMax(selfId) ..
                    ", nếu muốn tăng thêm không gian mang theo Trân Thú, xin hãy sử dụng chuồng thú Cao cấp hơn.")
                 strMsg = string.format(
                    "#W#{_INFOUSR%s}#Hdùng#W#{_INFOMSG%%s}#Hxong,#Hcải thiện rõ chỗ ở của pet,#Hsố pet mang theo được đạt#W%d#Hcon.",
                    self:LuaFnGetName(selfId), self:GetPetNumMax(selfId))
            elseif numExtra == 2 then
                self:MsgBox(selfId, "Không gian mang theo Trân Thú của ngài đã tăng đến" .. self:GetPetNumMax(selfId) ..
                    ", nếu muốn tăng thêm không gian mang theo Trân Thú, xin hãy sử dụng chuồng thú Cao cấp hơn.")
                strMsg = string.format(
                    "#W#{_INFOUSR%s}#Hdùng#W#{_INFOMSG%%s}#Hxong,#Hxây xong nhà pet hai tầng,#Hsố pet mang theo được đạt#W%d#Hcon.",
                    self:LuaFnGetName(selfId), self:GetPetNumMax(selfId))
            elseif numExtra == 3 then
                self:MsgBox(selfId, "Không gian mang theo Trân Thú của ngài đã tăng đến" .. self:GetPetNumMax(selfId) ..
                    ", nếu muốn tăng thêm không gian mang theo Trân Thú, xin hãy sử dụng chuồng thú Cao cấp hơn.")
                strMsg = string.format(
                    "#W#{_INFOUSR%s}#Hdùng#W#{_INFOMSG%%s}#Hxong,#Hbiệt thự pet hoàn thành,#Hsố pet mang theo được đạt#W%d#Hcon.",
                    self:LuaFnGetName(selfId), self:GetPetNumMax(selfId))
            elseif numExtra == 4 then
                self:MsgBox(selfId, "Không gian mang theo Trân Thú của ngài đã tăng đến" .. self:GetPetNumMax(selfId) ..
                    ", số lượng chuồng thú đã đạt đến giới hạn trên.")
                strMsg = string.format(
                    "#W#{_INFOUSR%s}#Hdùng#W#{_INFOMSG%%s}#Hxong,#Hhoàn thành khoanh đất nuôi pet,#Hsố pet mang theo được đạt#W%d#Hcon.",
                    self:LuaFnGetName(selfId), self:GetPetNumMax(selfId))
            end
            strMsg = gbk.fromutf8(strMsg)
            strMsg = string.format(strMsg, szTran)
            self:AddGlobalCountNews(strMsg, true)
        end
    end
    return 1
end

function petmanger:OnActivateEachTick(selfId)
    return 1
end

function petmanger:MsgBox(selfId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return petmanger
