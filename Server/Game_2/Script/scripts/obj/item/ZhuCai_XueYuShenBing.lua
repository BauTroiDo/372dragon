local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ZhuCai_XueYuShenBing = class("ZhuCai_XueYuShenBing", script_base)
ZhuCai_XueYuShenBing.script_id = 335135
ZhuCai_XueYuShenBing.g_CompleteValue = 5
ZhuCai_XueYuShenBing.g_MaxCompleteValue = 95
ZhuCai_XueYuShenBing.g_MaxUseCount = 1
ZhuCai_XueYuShenBing.g_ShenCaiTable = {
    {["sjid"] = 30505700, ["sfid"] = 30505800, ["lrid"] = 30505900, ["cis"] = 20},
    {["sjid"] = 30505701, ["sfid"] = 30505801, ["lrid"] = 30505901, ["cis"] = 10},
    {["sjid"] = 30505702, ["sfid"] = 30505802, ["lrid"] = 30505902, ["cis"] = 7},
    {["sjid"] = 30505703, ["sfid"] = 30505803, ["lrid"] = 30505903, ["cis"] = 5},
    {["sjid"] = 30505704, ["sfid"] = 30505804, ["lrid"] = 30505904, ["cis"] = 5},
    {["sjid"] = 30505705, ["sfid"] = 30505805, ["lrid"] = 30505905, ["cis"] = 5},
    {["sjid"] = 30505706, ["sfid"] = 30505806, ["lrid"] = 30505906, ["cis"] = 5}
}

ZhuCai_XueYuShenBing.g_ShenCaiIndex = 0
ZhuCai_XueYuShenBing.g_Impact_LevelUP = 47
ZhuCai_XueYuShenBing.g_Impact_Complete = 48
ZhuCai_XueYuShenBing.g_XinMang7JiInfo = "Thần Phù Tân Mãng cấp 7"
function ZhuCai_XueYuShenBing:OnDefaultEvent(selfId, bagIndex)
end

function ZhuCai_XueYuShenBing:IsSkillLikeScript(selfId)
    return 1
end

function ZhuCai_XueYuShenBing:OnConditionCheck(selfId)
    local nIndex = self:LuaFnGetBagIndexOfUsedItem(selfId)
    local Item01 = self:LuaFnGetItemTableIndexByIndex(selfId, nIndex)
    for i = 1, 7 do
        if Item01 == self.g_ShenCaiTable[i]["sfid"] then
            self.g_ShenCaiIndex = i
            break
        end
    end
    if Item01 < 30505800 or Item01 > 30505806 then
        local strNotice = "Chỉ có thể dùng Tân Mãng Thần Phù để hợp thành"
        self:ShowMsg(selfId, strNotice)
        return 0
    end
    local sjid = self.g_ShenCaiTable[self.g_ShenCaiIndex]["sjid"]
    local ItemCount = self:LuaFnGetAvailableItemCount(selfId, sjid)
    if ItemCount < 1 then
        local strNotice = "Ngươi cần" .. "#{_ITEM" .. (self.g_ShenCaiTable[self.g_ShenCaiIndex]["sjid"]) .. "}"
        self:ShowMsg(selfId, strNotice)
        return 0
    end
    local bagbegin = self:GetBasicBagStartPos(selfId)
    local bagend = self:GetBasicBagEndPos(selfId)
    local ItemEX
    local sjbagpos = -1
    for i = bagbegin, bagend do
        if self:LuaFnIsItemAvailable(selfId, i) then
            ItemEX = self:LuaFnGetItemTableIndexByIndex(selfId, i)
            if ItemEX == self.g_ShenCaiTable[self.g_ShenCaiIndex]["sjid"] then
                sjbagpos = i
                break
            end
        end
    end
    if sjbagpos == -1 then
        local strNotice = "Ngươi cần" .. "#{_ITEM" .. (self.g_ShenCaiTable[self.g_ShenCaiIndex]["sjid"]) .. "}"
        self:ShowMsg(selfId, strNotice)
        return 0
    end
    return 1
end

function ZhuCai_XueYuShenBing:OnDeplete(selfId)
    return 1
end

function ZhuCai_XueYuShenBing:OnActivateOnce(selfId)
    local sjbagpos = -1
    local begin = self:GetBasicBagStartPos()
    local endpos = self:GetBasicBagEndPos()
    for i = begin, endpos do
        if self:LuaFnIsItemAvailable(selfId, i) then
            local ItemEX = self:LuaFnGetItemTableIndexByIndex(selfId, i)
            if ItemEX == self.g_ShenCaiTable[self.g_ShenCaiIndex]["sjid"] then
                sjbagpos = i
                break
            end
        end
    end
    local Item01 = self:LuaFnGetItemIndexOfUsedItem(selfId)
    local CompleteValue = self:GetBagItemParam(selfId, sjbagpos, 8, "uchar")
    if CompleteValue >= self.g_MaxCompleteValue then
        local FreeSpace = self:LuaFnGetPropertyBagSpace(selfId)
        if (FreeSpace < 1) then
            local strNotice = "Túi của ngài không còn chỗ trống, Yêu cầu thu xếp lại."
            self:ShowMsg(selfId, strNotice)
            return 0
        end
        self:EraseItem(selfId, sjbagpos)
        self:BeginAddItem()
        self:AddItem(self.g_ShenCaiTable[self.g_ShenCaiIndex]["lrid"], 1)
        local ret = self:EndAddItem(selfId)
        if ret then
            local playername = self:GetName(selfId)
            local bagpos01 =
                self:TryRecieveItem(selfId, self.g_ShenCaiTable[self.g_ShenCaiIndex]["lrid"], 1)
            local szItemTransfer = self:GetBagItemTransfer(selfId, bagpos01)
            local strText =
                string.format(
                "@*;SrvMsg;#GẦm ầm, trời sấm chớp giao nhau, chúc mừng #{_INFOUSR%s} trải nghìn cay vạn đắng, lấy được nguyên liệu rèn thần khí tối thượng #{_INFOMSG%%s}! ",
                playername
            )
            strText = gbk.fromutf8(strText)
            strText = string.format(strText, szItemTransfer)
            self:BroadMsgByChatPipe(selfId, strText, 4)
        else
            self:BeginEvent(self.script_id)
            local strText = "Túi đồ hoặc Ô Nguyên liệu không đủ chỗ trống, xin hãy thu xếp rồi quay lại nhận."
            self:AddText(strText)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            return 0
        end
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact_Complete, 0)
    end
    self:LuaFnDelAvailableItem(selfId, Item01, 1)
    if Item01 == 30505800 then
        self.g_CompleteValue = 6
        self.g_MaxCompleteValue = 24
    elseif Item01 == 30505801 then
        self.g_MaxCompleteValue = 49
        self.g_CompleteValue = 6
    elseif Item01 == 30505802 then
        self.g_MaxCompleteValue = 84
        self.g_CompleteValue = 6
    end
    CompleteValue = CompleteValue + self.g_CompleteValue
    self:SetBagItemParam(selfId, sjbagpos, 8, CompleteValue, "uchar")
    self:LuaFnRefreshItemInfo(selfId, sjbagpos)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 18, 0)
    if Item01 == 30505800 then
        CompleteValue = self:GetBagItemParam(selfId, sjbagpos, 8, 2)
        CompleteValue = CompleteValue * 4
    elseif Item01 == 30505801 then
        CompleteValue = CompleteValue * 2
    end
    local strNotice = "Của ngươi" .. "#{_ITEM" .. (self.g_ShenCaiTable[self.g_ShenCaiIndex]["sjid"]) .. "}" .. "Độ hoàn chỉnh tăng 5%, độ sửa hiện là" .. CompleteValue .. "%, tiếp tục cố lên nhé!"
    self:ShowMsg(selfId, strNotice)
    local FreeSpace = self:LuaFnGetPropertyBagSpace(selfId)
    if (FreeSpace < 1) then
        self:BeginEvent(self.script_id)
        self:AddText("Ô vật phẩm hết chỗ, cần dọn!")
        self:EndEvent()
        self:DispatchEventList(selfId)
        return 0
    end
    if Item01 == 30505806 then
        local playername = self:GetName(selfId)
        self.g_XinMang7JiInfo = self:GetItemName(30505806)
        local strText =
            string.format(
            "#{_INFOUSR%s}#{DQSJ_20080512_12}#cFF0000Tân Mãng Thần Phù cấp 7#{DQSJ_20080512_13}",
            playername,
            self:GetItemName(30505806)
        )
        strText = gbk.fromutf8(strText)
        self:BroadMsgByChatPipe(selfId, strText, 4)
    end
    local CheckParam = self:GetBagItemParam(selfId, sjbagpos, 8, "uchar")
    if CheckParam ~= CompleteValue then
        return 0
    end
    strNotice = "Của ngươi" .. "#{_ITEM" .. (self.g_ShenCaiTable[self.g_ShenCaiIndex]["sjid"]) .. "}" .. "Độ hoàn chỉnh tăng 5%"
    self:ShowMsg(selfId, strNotice)
    self:LuaFnRefreshItemInfo(selfId, sjbagpos)
    if CompleteValue > self.g_MaxCompleteValue then
        self:EraseItem(selfId, sjbagpos)
        self:BeginAddItem()
        self:AddItem(self.g_ShenCaiTable[self.g_ShenCaiIndex]["lrid"], 1)
        local ret = self:EndAddItem(selfId)
        if ret then
            self:TryRecieveItem(selfId, self.g_ShenCaiTable[self.g_ShenCaiIndex]["lrid"], 1)
        else
            self:BeginEvent(self.script_id)
            local strText = "Túi đồ hoặc Ô Nguyên liệu không đủ chỗ trống, xin hãy thu xếp rồi quay lại nhận."
            self:AddText(strText)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            return 0
        end
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact_Complete, 0)
    else
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, self.g_Impact_LevelUP, 0)
    end
    return 1
end

function ZhuCai_XueYuShenBing:OnActivateEachTick()
    return 1
end

function ZhuCai_XueYuShenBing:CancelImpacts()
    return 0
end

function ZhuCai_XueYuShenBing:ShowMsg(selfId, strMsg)
    self:BeginEvent(self.script_id)
    self:AddText(strMsg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return ZhuCai_XueYuShenBing
