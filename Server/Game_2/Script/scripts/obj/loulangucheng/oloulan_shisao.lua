local class = require "class"
local gbk = require "wire_charset"
local define = require "define"
local script_base = require "script_base"
local oloulan_shisao = class("oloulan_shisao", script_base)
oloulan_shisao.script_id = 001157
oloulan_shisao.g_shoptableindex = 184
oloulan_shisao.g_SegmentID = 30505706
oloulan_shisao.g_JewelryID = 30501173
oloulan_shisao.g_FractionSegmentID = 30501172
function oloulan_shisao:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Ta bôn ba thiên hạ, mới thu thập được những công thức này!")
    --self:AddNumText("看看你卖的东西", 7, 0)
    self:AddNumText("#{SJHC_081106_01}", 6, 1)
    self:AddNumText("#{SJHC_081106_02}", 6, 2)
    self:AddNumText("Hàn Ngọc hợp thành", 6, 14)
    self:AddNumText("#{SJHC_081106_03}", 11, 16)
    self:AddNumText("#{SJHC_081106_04}", 11, 17)
    self:AddNumText("Hàn Ngọc hợp thành tửu quán", 11, 15)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oloulan_shisao:OnEventRequest(selfId, targetId,arg,index)
    if index == 0 then
        --self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
    end
    if index == 1 then
        self:BeginEvent(self.script_id)
        self:AddText("#{SJHC_081106_05}")
        self:AddNumText("Xác nhận", 8, 3)
        self:AddNumText("Hủy bỏ", 8, 4)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 2 then
        self:BeginEvent(self.script_id)
        self:AddText("#{SJHC_081106_09}")
        self:AddNumText("Xác nhận", 8, 5)
        self:AddNumText("Hủy bỏ", 8, 4)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 3 then
        self:FractionSegment(selfId, targetId)
        return
    end
    if index == 4 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
        return
    end
    if index == 5 then
        self:ComposeSegment(selfId, targetId)
        return
    end
    if index == 15 then
        self:BeginEvent(self.script_id)
        self:AddText("#{HY_20080602_001}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 14 then
        local nHave = self:LuaFnGetAvailableItemCount(selfId, 20310110)
        if nHave < 5 then
            self:NotifyFailBox(selfId, targetId, "Không đủ đạo cụ cần")
            return
        end
        local a = math.floor(nHave / 5)
        local Isbind = false
        if self:GetBagPosByItemSnAvailableBind(selfId,20310110,true) > -1 then
            Isbind = true
        end
        if self:LuaFnDelAvailableItem(selfId, 20310110, a * 5) then
            for i = 1, a do 
                self:TryRecieveItem(selfId, 20310111, Isbind) 
            end
            self:NotifyFailBox(selfId, targetId, "Hợp thành thành công")
        end
        return
    end
    if index == 16 then
        self:NotifyFailBox(selfId, targetId, "#{SJHC_081106_15}")
        return
    end
    if index == 17 then
        self:NotifyFailBox(selfId, targetId, "#{SJHC_081106_16}")
        return
    end
end

function oloulan_shisao:FractionSegment(selfId, targetId)
    if self:LuaFnGetAvailableItemCount(selfId, self.g_SegmentID) <= 0 then
        self:NotifyFailBox(selfId, targetId, "#{SJHC_081106_06}")
        return
    end
    if self:LuaFnGetAvailableItemCount(selfId, self.g_JewelryID) <= 0 then
        self:NotifyFailBox(selfId, targetId, "#{SJHC_081106_07}")
        return
    end
    if self:LuaFnGetPropertyBagSpace(selfId) < 1 then
        self:NotifyFailBox(selfId, targetId, "    #{STZDY_20080513_23}")
        self:NotifyFailTips(selfId, "#{STZDY_20080513_23}")
        return
    end
    local SegmentInfo = ""
    local JewelryInfo = ""
    local MaxEquipIndex = 100
    for i = 0, MaxEquipIndex - 1 do
        if self:LuaFnGetItemTableIndexByIndex(selfId, i) == self.g_SegmentID then
            SegmentInfo = self:GetBagItemTransfer(selfId, i)
            break
        end
    end 
    for i = 0, MaxEquipIndex - 1 do
        if self:LuaFnGetItemTableIndexByIndex(selfId, i) == self.g_JewelryID then
            JewelryInfo = self:GetBagItemTransfer(selfId, i)
            break
        end
    end
    if not self:LuaFnDelAvailableItem(selfId, self.g_SegmentID, 1) or
       not self:LuaFnDelAvailableItem(selfId, self.g_JewelryID, 1) then
        self:NotifyFailBox(selfId, targetId, "    Trừ vật phẩm thất bại!")
        return
    end
    local FractionSegmentIndex = self:TryRecieveItem(selfId,self.g_FractionSegmentID)
    if FractionSegmentIndex == -1 then
        self:NotifyFailBox(selfId, targetId, "    #{STZDY_20080513_23}")
        return
    end
    local FractionSegmentInfo = self:GetBagItemTransfer(selfId,
                                                        FractionSegmentIndex)
   -- self:AuditSegment(selfId, 1)
    self:NotifyFailBox(selfId, targetId, "#{SJHC_081106_08}")
    local fmt = gbk.fromutf8("#{_INFOUSR%s}#{DSSJ_1}#{_INFOMSG%s}#{DSSJ_2}#{_INFOMSG%s}#{DSSJ_3}#{_INFOMSG%s}#{DSSJ_4}")
    local Name = gbk.fromutf8(self:LuaFnGetName(selfId))
    local message = string.format(
                        fmt,
                        Name, JewelryInfo, SegmentInfo,
                        FractionSegmentInfo)
    self:BroadMsgByChatPipe(selfId, message, 4)
end

function oloulan_shisao:ComposeSegment(selfId, targetId)
    if self:LuaFnGetAvailableItemCount(selfId, self.g_FractionSegmentID) < 5 then
        self:NotifyFailBox(selfId, targetId, "#{SJHC_081106_10}")
        return
    end
    if self:LuaFnGetPropertyBagSpace(selfId) < 1 then
        self:NotifyFailBox(selfId, targetId, "    #{STZDY_20080513_23}")
        self:NotifyFailTips(selfId, "#{STZDY_20080513_23}")
        return
    end
    local FractionSegmentInfo = ""
    --[[local MaxEquipIndex = self:LuaFnGetMaterialStartBagPos(selfId)
   -- for i = 0, MaxEquipIndex - 1 do
        --if self:LuaFnGetItemTableIndexByIndex(selfId, i) ==
           -- self.g_FractionSegmentID then
           -- FractionSegmentInfo = self:GetBagItemTransfer(selfId, i)
           -- break
       -- end
    -- end]]
    if not self:LuaFnDelAvailableItem(selfId, self.g_FractionSegmentID, 5) then
        self:NotifyFailBox(selfId, targetId, "    Trừ vật phẩm thất bại!")
        return
    end
    local BagIndex = self:TryRecieveItem(selfId, self.g_SegmentID)
    if BagIndex == -1 then
        self:NotifyFailBox(selfId, targetId, "    #{STZDY_20080513_23}")
        return
    end
    local ItemInfo = self:GetBagItemTransfer(selfId, BagIndex)
   -- self:AuditSegment(selfId, 2)
    self:NotifyFailBox(selfId, targetId, "#{SJHC_081106_11}")
    local fmt = gbk.fromutf8("#{_INFOUSR%s}#{SJHC_081106_12}mảnh thần tiết cấp 7#{SJHC_081106_13}#{_INFOMSG%s}#{SJHC_081106_14}")
    local Name = gbk.fromutf8(self:LuaFnGetName(selfId))
    local message = string.format(fmt,Name,ItemInfo)
    self:BroadMsgByChatPipe(selfId, message, 4)
end

function oloulan_shisao:NotifyFailBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oloulan_shisao:NotifyFailTips(selfId, Tip)
    self:BeginEvent(self.script_id)
    self:AddText(Tip)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return oloulan_shisao
