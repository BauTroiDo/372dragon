local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local eexchange_longzhu = class("eexchange_longzhu", script_base)
eexchange_longzhu.script_id = 808058
eexchange_longzhu.g_ExchangeLongzhu_Active = 1
eexchange_longzhu.g_LongpaiId = 30505092
eexchange_longzhu.g_Longpai75Id = 30505907
eexchange_longzhu.g_LongzhuList = {
    30505136, 30505137, 30505138, 30505139, 30505140, 30505141, 30505142
}

function eexchange_longzhu:CheckPercentOK(numerator, denominator)
    local roll = math.random(denominator)
    if roll <= numerator then return 1 end
    return 0
end

function eexchange_longzhu:DropLongzhuList(LongzhuIndex)
    self:CheckRightTime()
    if 1 ~= self.g_ExchangeLongzhu_Active then return -1 end
    if 1 == LongzhuIndex then
        local CheckOK = self:CheckPercentOK(200, 1000000)
        if 1 == CheckOK then return 30505136 end
    end
    if 2 == LongzhuIndex then
        local CheckOK = self:CheckPercentOK(50, 1000000)
        if 1 == CheckOK then return 30505137 end
    end
    if 3 == LongzhuIndex then
        local CheckOK = self:CheckPercentOK(20, 1000000)
        if 1 == CheckOK then return 30505138 end
    end
    if 4 == LongzhuIndex then
        local CheckOK = self:CheckPercentOK(11, 1000000)
        if 1 == CheckOK then return 30505139 end
    end
    if 5 == LongzhuIndex then
        local CheckOK = self:CheckPercentOK(7, 1000000)
        if 1 == CheckOK then return 30505140 end
    end
    if 6 == LongzhuIndex then

        local CheckOK = self:CheckPercentOK(4, 1000000)

        if 1 == CheckOK then return 30505141 end

    end
    if 7 == LongzhuIndex then
        local CheckOK = self:CheckPercentOK(2, 1000000)
        if 1 == CheckOK then return 30505142 end
    end
    return -1
end

function eexchange_longzhu:CheckEnoughItem(selfId, targetId)
    local ListSize = #(self.g_LongzhuList)
    for i = 1, ListSize do
        local ItemCount = self:LuaFnGetAvailableItemCount(selfId, self.g_LongzhuList[i])
        if ItemCount < 1 then return 0 end
    end
    return 1
end

function eexchange_longzhu:DelNeedItem(selfId, targetId)
    local ListSize = #(self.g_LongzhuList)
    for i = 1, ListSize do
        local ret = self:LuaFnDelAvailableItem(selfId, self.g_LongzhuList[i], 1)
        if not ret then return -1 end
    end
    return 1
end

function eexchange_longzhu:AwardItem(selfId, targetId, type)
    local bEnough = self:CheckEnoughItem(selfId, targetId)
    if 0 == bEnough then
        local strNotEnough = "#{EXCHANGE_LONGPAI_TEX01}"
        self:BeginEvent(self.script_id)
        self:AddText(strNotEnough)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    self:BeginAddItem()
    if type == 1 then
        self:AddItem(self.g_LongpaiId, 1)
    elseif type == 2 then
        self:AddItem(self.g_Longpai75Id, 1)
    end
    local Ret = self:EndAddItem(selfId)
    if Ret then
        local bDel = self:DelNeedItem(selfId, targetId)
        if bDel then
            self:AddItemListToHuman(selfId)
            local szItemTransfer = self:GetItemTransfer(selfId, 0)
            local PlayerName = self:GetName(selfId)
            local PlayerInfoName = "#{_INFOUSR" .. PlayerName .. "}"
            local ItemInfo = "#{_INFOMSG" .. szItemTransfer .. "}"
            local strNotice = "#{EXCHANGE_LONGPAI_TEX02}"
            local SysStr = gbk.fromutf8(PlayerInfoName) .. strNotice .. ItemInfo .. "#R。"
            self:BroadMsgByChatPipe(selfId, SysStr, 4)
            self:BeginUICommand()
            self:UICommand_AddInt(targetId)
            self:EndUICommand()
            self:DispatchUICommand(selfId, 1000)
        end
    else
        local strBagFull = "#{EXCHANGE_LONGPAI_TEX03}"
        self:BeginEvent(self.script_id)
        self:AddText(strBagFull)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
end

function eexchange_longzhu:PlayerPickUpLongZhu(selfId, bagidx)
    local szItemTransfer = self:GetBagItemTransfer(selfId, bagidx)
    local PlayerName = self:GetName(selfId)
    PlayerName = gbk.fromutf8(PlayerName)
    local fmt = gbk.fromutf8("#{_INFOUSR%s}#Ptrong lúc nhàn tản đi dạo ở bên ngoài vô tình phát hiện một viên châu hình tròn lấp lánh ánh sáng trong bụi cỏ, sau khi lau chùi mới phát hiện ra lại là #{_INFOMSG%s}.")
    local strNotice = string.format(fmt, PlayerName, szItemTransfer)
    self:BroadMsgByChatPipe(selfId, strNotice, 4)
end

function eexchange_longzhu:OnDefaultEvent(selfId, targetId, index)
    self:CheckRightTime()
    if 1 ~= self.g_ExchangeLongzhu_Active then return end
    local TextNum = index
    if 1 == TextNum then
        local strLongpai = "#{EXCHANGE_LONGPAI_TEX07}"
        local strLongpai75 = "#{EXCHANGE_LONGPAI_TEX08}"
        self:BeginEvent(self.script_id)
        self:AddNumText(strLongpai, 6, 3)
        self:AddNumText(strLongpai75, 6, 4)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif 2 == TextNum then
        local strNotEnough = "#{EXCHANGE_LONGPAI_TEX06}"
        self:BeginEvent(self.script_id)
        self:AddText(strNotEnough)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif 3 == TextNum then
        self:AwardItem(selfId, targetId, 1)
    elseif 4 == TextNum then
        self:AwardItem(selfId, targetId, 2)
    end
end

function eexchange_longzhu:CheckRightTime()
    self.g_ExchangeLongzhu_Active = 1
    return 1
end

function eexchange_longzhu:OnEnumerate(caller, selfId, targetId, arg, index)
    self:CheckRightTime()
    if 1 ~= self.g_ExchangeLongzhu_Active then return end
    local strLongpai = "#{EXCHANGE_LONGPAI_TEX04}"
    local strDesc = "#{EXCHANGE_LONGPAI_TEX05}"
    caller:AddNumTextWithTarget(self.script_id, strLongpai, 6, 1)
    caller:AddNumTextWithTarget(self.script_id, strDesc, 0, 2)
end

function eexchange_longzhu:CheckAccept(selfId) end

function eexchange_longzhu:OnAccept(selfId) end

function eexchange_longzhu:OnAbandon(selfId) end

function eexchange_longzhu:OnContinue(selfId, targetId) end

function eexchange_longzhu:CheckSubmit(selfId) end

function eexchange_longzhu:OnSubmit(selfId, targetId, selectRadioId) end

function eexchange_longzhu:OnKillObject(selfId, objdataId, objId) end

function eexchange_longzhu:OnEnterArea(selfId, zoneId) end

function eexchange_longzhu:OnItemChanged(selfId, itemdataId) end

return eexchange_longzhu
