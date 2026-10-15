local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ejingji_2 = class("ejingji_2", script_base)
ejingji_2.script_id = 125021
ejingji_2.g_StoneId = 30505143
ejingji_2.g_Item_1 = 10421018
ejingji_2.g_Item_2 = 10421019
ejingji_2.g_Item_3 = 10421020
ejingji_2.g_Item_4 = 10421021
ejingji_2.g_Exp = 50000
function ejingji_2:OnEnumerate(caller, selfId, targetId, arg, index)
    caller:AddNumTextWithTarget(targetId,"Đổi #WẤn#W của Minh Chủ bằng #WĐồng#W Yêu Đái của Minh Chủ", 12, 1)
    caller:AddNumTextWithTarget(targetId,"Đổi #WẤn#W của Minh Chủ bằng #WNgân#W Yêu Đái của Minh Chủ", 12, 2)
    caller:AddNumTextWithTarget(targetId,"Đổi #WẤn#W của Minh Chủ bằng #WKim#W Yêu Đái của Minh Chủ", 12, 3)
    caller:AddNumTextWithTarget(targetId,"Nâng cấp thành #WĐồng#W Yêu Đái của Minh Chủ", 6, 7)
    caller:AddNumTextWithTarget(targetId,"Nâng cấp thành #WNgân#W Yêu Đái của Minh Chủ", 6, 4)
    caller:AddNumTextWithTarget(targetId,"Nâng cấp thành Minh Chủ Kim Yêu Đái", 6, 5)
    caller:AddNumTextWithTarget(targetId,"Nâng cấp thành Minh Chủ Thất Bảo Yêu Đái", 6, 6)
end

function ejingji_2:OnDefaultEvent(selfId, targetId, arg, index)
    local Num = index
    if Num == 1 then
        self:BeginEvent(self.script_id)
        self:AddText("#BMinh Chủ Đồng Yêu Đái#W đổi Minh Chủ Chi Ấn")
        self:AddText("  1 Minh Chủ Đồng Yêu Đái có thể đổi 1 Minh Chủ Chi Ấn")
        self:AddNumText("Xác nhận", 8, 10)
        self:AddNumText("Hủy bỏ", 8, 20)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif Num == 2 then
        self:BeginEvent(self.script_id)
        self:AddText("#BMinh Chủ Ngân Yêu Đái#W đổi Minh Chủ Chi Ấn")
        self:AddText("  1 Minh Chủ Ngân Yêu Đái có thể đổi 10 Minh Chủ Chi Ấn")
        self:AddNumText("Xác nhận", 8, 11)
        self:AddNumText("Hủy bỏ", 8, 20)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif Num == 3 then
        self:BeginEvent(self.script_id)
        self:AddText("#BMinh Chủ Kim Yêu Đái#W đổi Minh Chủ Chi Ấn")
        self:AddText("  1 cái Minh Chủ Kim Yêu Đái có thể đổi được 100 cái Minh Chủ Chi Ấn")
        self:AddNumText("Xác nhận", 8, 12)
        self:AddNumText("Hủy bỏ", 8, 20)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif Num == 4 then
        self:BeginEvent(self.script_id)
        self:AddText("#BNâng cấp thành Minh Chủ Ngân Yêu Đái")
        self:AddText("  Thăng cấp thành Minh Chủ Ngân Yêu Đái Yêu cầutiêu hao: #r#G    1 cái Minh Chủ Đồng Yêu Đái#r    9 cái Minh Chủ Chi Ấn#r    Ngươi xác định muốn Thăng cấp không?")
        self:AddNumText("Xác nhận", 8, 13)
        self:AddNumText("Hủy bỏ", 8, 20)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif Num == 5 then
        self:BeginEvent(self.script_id)
        self:AddText("#BNâng cấp thành Minh Chủ Kim Yêu Đái")
        self:AddText("  Thăng cấp thành Minh Chủ Kim Yêu Đái Yêu cầutiêu hao: #r#G    1 cái Minh Chủ Ngân Yêu Đái#r    90 cái Minh Chủ Chi Ấn#r    #{_EXCHG" ..tostring(500000) .. "}#W#r  Ngươi xác định muốn Thăng cấp không?")
        self:AddNumText("Xác nhận", 8, 14)
        self:AddNumText("Hủy bỏ", 8, 20)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif Num == 6 then
        self:BeginEvent(self.script_id)
        self:AddText("#BNâng cấp thành Minh Chủ Thất Bảo Yêu Đái")
        self:AddText("  Thăng cấp thành Minh Chủ Thất Bảo Yêu Đái. Yêu cầu tiêu hao:#r#G 1 cái Minh Chủ Kim Yêu Đái#r 400 cái Minh Chủ Chi Ấn#r #{_EXCHG" ..tostring(1000000) .. "}#W#r  Ngươi xác định muốn Thăng cấp không?")
        self:AddNumText("Xác nhận", 8, 15)
        self:AddNumText("Hủy bỏ", 8, 20)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif Num == 7 then
        self:BeginEvent(self.script_id)
        self:AddText("#BNâng cấp thành Minh Chủ Đồng Yêu Đái")
        self:AddText("  Thăng cấp thành Minh Chủ Đồng Yêu Đái. Yêu cầu tiêu hao:#r#G 40 mảnh Minh Chủ Đồng Yêu Đái#W#r Ngươi xác định muốn thăng cấp không?")
        self:AddNumText("Xác nhận", 8, 16)
        self:AddNumText("Hủy bỏ", 8, 20)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
    if Num == 10 then
        self:ChangeItem(selfId, 1)
    elseif Num == 11 then
        self:ChangeItem(selfId, 2)
    elseif Num == 12 then
        self:ChangeItem(selfId, 3)
    end
    if Num == 13 then
        self:UpdateItem(selfId, 1)
    elseif Num == 14 then
        self:UpdateItem(selfId, 2)
    elseif Num == 15 then
        self:UpdateItem(selfId, 3)
    end
    if Num == 16 then self:StoneToItem(selfId) end
    if Num == 20 then
        self:BeginUICommand()
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
    end
end

function ejingji_2:StoneToItem(selfId)
    self:BeginAddItem()
    self:AddItem(self.g_Item_1, 1)
    local ret = self:EndAddItem(selfId)
    local nStoneId = 40004434
    if ret then
        if self:LuaFnGetAvailableItemCount(selfId, nStoneId) >= 40 then
            self:LuaFnDelAvailableItem(selfId, nStoneId, 40)
            self:AddItemListToHuman(selfId)
            self:DispatchTips(selfId, 1)
            self:LuaFnAuditPlayerBehavior(selfId, "Mảnh vỡ đổi Yêu Đái")
        else
            self:DispatchTips(selfId, 0)
        end
    else
        self:DispatchTips(selfId, -2)
    end
    self:BeginUICommand()
    self:EndUICommand()
    self:DispatchUICommand(selfId, 1000)
end

function ejingji_2:UpdateItem(selfId, nIndex)
    if nIndex == 1 then
        self:BeginAddItem()
        self:AddItem(self.g_Item_2, 1)
        local ret = self:EndAddItem(selfId)
        if ret then
            if self:LuaFnGetAvailableItemCount(selfId, self.g_StoneId) >= 9 and
                self:LuaFnGetAvailableItemCount(selfId, self.g_Item_1) >= 1 then
                self:LuaFnDelAvailableItem(selfId, self.g_StoneId, 9)
                self:LuaFnDelAvailableItem(selfId, self.g_Item_1, 1)
                self:AddItemListToHuman(selfId)
                self:LuaFnAuditPlayerBehavior(selfId, "Yêu Đái Đồng đổi Yêu Đái Bạc")
                self:DispatchTips(selfId, 1)
                return
            end
        end
    elseif nIndex == 2 then
        if self:GetMoney(selfId) + self:GetMoneyJZ(selfId) < 500000 then
            self:DispatchTips(selfId, -1)
            return
        end
        self:BeginAddItem()
        self:AddItem(self.g_Item_3, 1)
        local ret = self:EndAddItem(selfId)
        if ret then
            if self:LuaFnGetAvailableItemCount(selfId, self.g_StoneId) >= 90 and
                self:LuaFnGetAvailableItemCount(selfId, self.g_Item_2) >= 1 then
                self:LuaFnDelAvailableItem(selfId, self.g_StoneId, 90)
                self:LuaFnDelAvailableItem(selfId, self.g_Item_2, 1)
                self:LuaFnCostMoneyWithPriority(selfId, 500000)
                self:AddItemListToHuman(selfId)
                self:LuaFnAuditPlayerBehavior(selfId, "Yêu Đái Bạc đổi Yêu Đái Vàng")
                self:DispatchTips(selfId, 1)
                return
            end
        end
    elseif nIndex == 3 then
        if self:GetMoney(selfId) + self:GetMoneyJZ(selfId) < 1000000 then
            self:DispatchTips(selfId, -1)
            return
        end
        self:BeginAddItem()
        self:AddItem(self.g_Item_4, 1)
        local ret = self:EndAddItem(selfId)
        if ret then
            if self:LuaFnGetAvailableItemCount(selfId, self.g_StoneId) >= 400 and
                self:LuaFnGetAvailableItemCount(selfId, self.g_Item_3) >= 1 then
                self:LuaFnDelAvailableItem(selfId, self.g_StoneId, 400)
                self:LuaFnDelAvailableItem(selfId, self.g_Item_3, 1)
                self:LuaFnCostMoneyWithPriority(selfId, 1000000)
                self:AddItemListToHuman(selfId)
                self:LuaFnAuditPlayerBehavior(selfId, "Yêu Đái Vàng đổi Yêu Đái Thất Bảo")
                self:DispatchTips(selfId, 1)
                local BagPos = self:LuaFnGetItemPosByItemDataID(selfId, self.g_Item_4)
                local szTransferEquip = self:GetItemTransfer(selfId, BagPos)
                local name = self:GetName(selfId)
                name = gbk.fromutf8(name)
                local str = string.format("#PƯ Cửu Liên hô lớn: Anh hùng thiên hạ! Đại anh hùng #{_INFOUSR%s} bao năm huyết chiến trên Phong Thiện Đài, cuối cùng giành được tiêu chí thật của minh chủ võ lâm! #{_INFOMSG%s}!", name, szTransferEquip)
                self:BroadMsgByChatPipe(selfId, str, 4)
                return
            end
        end
    end
    self:DispatchTips(selfId, 0)
end

function ejingji_2:ChangeItem(selfId, nIndex)
    if nIndex == 1 then
        self:BeginAddItem()
        self:AddItem(self.g_StoneId, 1)
        local ret = self:EndAddItem(selfId)
        if ret then
            if self:LuaFnDelAvailableItem(selfId, self.g_Item_1, 1) then
                self:AddItemListToHuman(selfId)
                self:LuaFnAuditPlayerBehavior(selfId, "Đồng Yêu Đái đổi 1 Minh Chủ Ấn")
                self:DispatchTips(selfId, 1)
                return
            end
        end
    elseif nIndex == 2 then
        self:BeginAddItem()
        self:AddItem(self.g_StoneId, 10)
        local ret = self:EndAddItem(selfId)
        if ret then
            if self:LuaFnDelAvailableItem(selfId, self.g_Item_2, 1) then
                self:AddItemListToHuman(selfId)
                self:LuaFnAuditPlayerBehavior(selfId, "Ngân Yêu Đái đổi 10 Minh Chủ Ấn")
                self:DispatchTips(selfId, 1)
                return
            end
        end
    elseif nIndex == 3 then
        self:BeginAddItem()
        self:AddItem(self.g_StoneId, 100)
        local ret = self:EndAddItem(selfId)
        if ret then
            if self:LuaFnDelAvailableItem(selfId, self.g_Item_3, 1) then
                self:AddItemListToHuman(selfId)
                self:LuaFnAuditPlayerBehavior(selfId, "Kim Yêu Đái đổi 100 Minh Chủ Ấn")
                self:DispatchTips(selfId, 1)
                return
            end
        end
    end
    self:DispatchTips(selfId, 0)
    return
end

function ejingji_2:DispatchTips(selfId, bOk)
    if bOk == 0 then
        self:BeginEvent(self.script_id)
        self:AddText("Đổi thất bại, xin kiểm tra vật phẩm có đủ để đổi không.")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
    elseif bOk == -1 then
        self:BeginEvent(self.script_id)
        self:AddText("Kim tiền không đủ")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
    elseif bOk == -2 then
        self:BeginEvent(self.script_id)
        self:AddText("Túi của ngươi không còn chỗ trống.")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
    else
        self:BeginEvent(self.script_id)
        self:AddText("Đổi thành công.")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
    end
    self:BeginUICommand()
    self:EndUICommand()
    self:DispatchUICommand(selfId, 1000)
end

return ejingji_2
