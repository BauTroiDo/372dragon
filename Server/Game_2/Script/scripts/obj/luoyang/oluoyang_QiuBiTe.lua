local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_QiuBiTe = class("oluoyang_QiuBiTe", script_base)
oluoyang_QiuBiTe.script_id = 000152
oluoyang_QiuBiTe.StartTime = 9040
oluoyang_QiuBiTe.EndTime = 9047
oluoyang_QiuBiTe.g_Gift = 30501166
oluoyang_QiuBiTe.BufferID = 74
oluoyang_QiuBiTe.g_GiftTbl = {30505193, 30505194, 10124130}

function oluoyang_QiuBiTe:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{QRJ_81009_02}")
    local curDayTime = self:GetDayTime()
    if (curDayTime >= self.StartTime and curDayTime < self.EndTime) then
        self:AddNumText("Lĩnh Thần Tình Yêu Chi Tiễn", 6, 0)
        self:AddNumText("Thần Tình Yêu Chi Vẫn đổi phần thưởng", 6, 1)
    end
    self:AddNumText("Về hoạt động Thần Tình Yêu Chi Vẫn", 11, 2)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oluoyang_QiuBiTe:OnEventRequest(selfId, targetId, arg, index)
    if index == 0 then
        self:GiveArrow(selfId, targetId, arg)
    elseif index == 1 then
        self:GiveGift(selfId, targetId, arg)
    elseif index == 2 then
        self:NotifyFailBox(selfId, targetId, "#{QRJ_81009_01}")
    elseif index == 3 then
        self:NotifyFailBox(selfId, targetId, "#{YHJZ_081007_48}")
    end
end

function oluoyang_QiuBiTe:NotifyFailBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oluoyang_QiuBiTe:GiveArrow(selfId, targetId, eventId)
    if self:GetLevel(selfId) < 20 then
        self:NotifyFailBox(selfId, targetId, "#{QRJ_81009_03}")
        return
    end
    local td = self:GetDayTime()
    local LastGetGiftTime = self:GetMissionData(selfId, define.MD_ENUM.MD_QINGRENJIE_ARROWDAY)
    if td <= LastGetGiftTime then
        self:NotifyFailBox(selfId, targetId, "#{QRJ_81009_04}")
        return self:SetMissionData(selfId, define.MD_ENUM.MD_QINGRENJIE_ARROWDAY, td)
    end
    if self:LuaFnGetPropertyBagSpace(selfId) < 1 then
        self:BeginEvent(self.script_id)
        self:AddText("#{QRJ_81009_14}")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
    else
        self:BeginAddItem()
        local nIndex = self:AddItem(self.g_Gift, 1)
        local ret = self:EndAddItem(selfId)
        if ret <= 0 then return end
        self:AddItemListToHuman(selfId)
        self:NotifyFailBox(selfId, targetId, "#{QRJ_81009_24}")
        self:BeginEvent(self.script_id)
        self:AddText("#{QRJ_81009_25}")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        self:SetMissionData(selfId, define.MD_ENUM.MD_QINGRENJIE_ARROWDAY, td)
    end
end

function oluoyang_QiuBiTe:GiveGift(selfId, targetId, eventId)
    if self:LuaFnHasTeam(selfId) == 0 then
        self:NotifyFailBox(selfId, targetId, "#{QRJ_81009_06}")
        return
    end
    if self:LuaFnIsTeamLeader(selfId) == 0 then
        self:NotifyFailBox(selfId, targetId, "#{QRJ_81009_07}")
        return
    end
    if self:GetTeamSize(selfId) ~= 2 then
        self:NotifyFailBox(selfId, targetId, "#{QRJ_81009_08}")
        return
    end
    local nearteammembercount = self:GetNearTeamCount(selfId)
    if nearteammembercount ~= self:LuaFnGetTeamSize(selfId) then
        self:NotifyFailBox(selfId, targetId, "#{QRJ_81009_09}")
        return
    end
    local ID1 = self:GetNearTeamMember(selfId, 0)
    local ID2 = self:GetNearTeamMember(selfId, 1)
    if (self:LuaFnGetSex(ID1) == self:LuaFnGetSex(ID2)) then
        self:NotifyFailBox(selfId, targetId, "#{QRJ_81009_10}")
        return
    end
    local td = self:GetDayTime()
    local LastSelfGiftTime = self:GetMissionData(ID1,253)
    local iCount = 0
    local strName = ""
    if (td <= LastSelfGiftTime) then
        iCount = iCount + 1
        strName = self:LuaFnGetName(ID1)
    end
    LastSelfGiftTime = self:GetMissionData(ID2, 253)
    if (td <= LastSelfGiftTime) then
        iCount = iCount + 1
        strName = self:LuaFnGetName(ID2)
    end
    if (iCount == 1) then
        self:NotifyFailBox(selfId, targetId,
                           "#{QRJ_81009_12}" .. strName .. "#{QRJ_81009_13}")
        return
    end
    if (iCount == 2) then
        self:NotifyFailBox(selfId, targetId, "#{QRJ_81114_1}")
        return
    end
    if (not self:LuaFnHaveImpactOfSpecificDataIndex(ID1, self.BufferID) or not
        self:LuaFnHaveImpactOfSpecificDataIndex(ID2, self.BufferID)) then
        self:NotifyFailBox(selfId, targetId, "#{QRJ_81009_11}")
        return
    end
    if self:LuaFnGetPropertyBagSpace(ID1) < 1 then
        self:BeginEvent(self.script_id)
        self:AddText("#{QRJ_81009_14}")
        self:EndEvent()
        self:DispatchMissionTips(ID1)
        self:BeginEvent(self.script_id)
        self:AddText(self:LuaFnGetName(ID1) .. "#{QRJ_81009_15}")
        self:EndEvent()
        self:DispatchMissionTips(ID2)
        return
    end
    if self:LuaFnGetPropertyBagSpace(ID2) < 1 then
        self:BeginEvent(self.script_id)
        self:AddText("#{QRJ_81009_14}")
        self:EndEvent()
        self:DispatchMissionTips(ID2)
        self:BeginEvent(self.script_id)
        self:AddText(self:LuaFnGetName(ID2) .. "#{QRJ_81009_15}")
        self:EndEvent()
        self:DispatchMissionTips(ID1)
        return
    end
    self:LuaFnCancelSpecificImpact(ID1, self.BufferID)
    self:LuaFnCancelSpecificImpact(ID2, self.BufferID)
    local nGiftIndex = self:RandomGift()
    self:BeginAddItem()
    local nIndex = self:AddItem(self.g_GiftTbl[nGiftIndex], 1)
    local ret = self:EndAddItem(ID1)
    if ret <= 0 then return end
    self:AddItemListToHuman(ID1)
    self:SetMissionData(ID1, 253, td)
    local str = "#{QRJ_81009_26}#{_ITEM" .. self.g_GiftTbl[nGiftIndex] .. "}"
    self:BeginEvent(self.script_id)
    self:AddText(str)
    self:EndEvent()
    self:DispatchMissionTips(ID1)
    if (nGiftIndex == 3) then
        local bagpos = self:GetBagPosByItemSn(ID1, self.g_GiftTbl[nGiftIndex])
        local szTransferEquip = self:GetBagItemTransfer(ID1, bagpos)
        local str = string.format("#{_INFOUSR%s}" ..
                                    "#{QRJ_81009_23}#{_INFOMSG%s}#{QRJ_81009_27}",
                                    gbk.fromutf8(self:LuaFnGetName(ID1)), szTransferEquip)
        self:BroadMsgByChatPipe(ID1, str, 4)
        self:AuditQingRenJieShiZhuang(ID1)
    end
    nGiftIndex = self:RandomGift()
    self:BeginAddItem()
    nIndex = self:AddItem(self.g_GiftTbl[nGiftIndex], 1)
    local ret = self:EndAddItem(ID2)
    if ret <= 0 then return end
    self:AddItemListToHuman(ID2)
    str = "#{QRJ_81009_26}#{_ITEM" .. self.g_GiftTbl[nGiftIndex] .. "}"
    self:BeginEvent(self.script_id)
    self:AddText(str)
    self:EndEvent()
    self:DispatchMissionTips(ID2)
    self:SetMissionData(ID2, 253, td)
    if (nGiftIndex == 3) then
        local bagpos = self:GetBagPosByItemSn(ID2, self.g_GiftTbl[nGiftIndex])
        local szTransferEquip = self:GetBagItemTransfer(ID2, bagpos)
        local str = string.format("#{_INFOUSR%s}" ..
                                    "#{QRJ_81009_23}#{_INFOMSG%s}#{QRJ_81009_27}",
                                gbk.fromutf8(self:LuaFnGetName(ID2)), szTransferEquip)
        self:BroadMsgByChatPipe(ID2, str, 4)
        self:AuditQingRenJieShiZhuang(ID2)
    end
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, ID1, 18, 0)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, ID2, 18, 0)
    self:NotifyFailBox(selfId, targetId, "#{QRJ_81009_16}")
end

function oluoyang_QiuBiTe:RandomGift()
    local nMsgIndex = math.random(1, 100)
    if (nMsgIndex < 49) then
        return 1
    elseif (nMsgIndex < 97) then
        return 2
    end
    return 3
end

return oluoyang_QiuBiTe
