local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local edali_0242 = class("edali_0242", script_base)
edali_0242.script_id = 210242
edali_0242.g_ItemId = {
    30505114, 30505115, 30505116, 30505117, 30505118, 30505119, 30505120
}
edali_0242.g_PetEggId = 30505121
edali_0242.g_Drop_QiXingSuiPian_StartDay = 9045
edali_0242.g_Drop_QiXingSuiPian_EndDay = 9090
edali_0242.g_ExchangePenguinEggStartDay = 9045
edali_0242.g_ExchangePenguinEggEndDay = 9120
function edali_0242:OnDefaultEvent(selfId, targetId, index)
    if self:IsValidPenguinEggExchangeTime() == 0 then
        self:BeginEvent(self.script_id)
        self:AddText("#YĐổi Chim Cánh Cụt")
        self:AddText("    Hoạt động đã hết hạn.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 1 then
        self:BeginEvent(self.script_id)
        self:AddText("#YĐổi Chim Cánh Cụt")
        self:AddText(
            "  Giữa mùa hè oi ả, ngươi có muốn một làn gió mát? Có muốn một ly nước lạnh? Có muốn một chút sảng khoái?")
        self:AddText(
            "  Chỉ cần có đủ bảy mảnh vỡ Thất Tinh, ngươi đều có thể nhận được!")
        self:AddText(
            "  Một vị trưởng lão vô danh, có thể sử dụng những mảnh vỡ này để khiến thế giới Thiên Long Bát Bộ trở nên sảng khoái hơn, và như là phần thưởng, người còn nhờ ta tặng cho người thu thập mảnh vỡ Thất Tinh một món quà sảng khoái nhất!")
        self:AddText("  Một chú chim cánh cụt đáng yêu!")
        self:AddText("  Ngươi xác nhận muốn đổi trứng chim cánh cụt không?")
        self:AddNumText("Xác nhận", 8, 3)
        self:AddNumText("Hủy bỏ", 8, 4)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 4 then
        self:BeginUICommand()
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
        return
    end
    if index == 3 then
        local HaveAllItem = 1
        for i, ItemId in pairs(self.g_ItemId) do
            if self:GetItemCount(selfId, ItemId) < 1 then
                HaveAllItem = 0
            end
        end
        if HaveAllItem == 0 then
            self:BeginEvent(self.script_id)
            self:AddText(
                "    Đổi Trứng Chim Cánh Cụt Yêu cầu mỗi loại một mảnh Kim, Mộc, Thủy, Hỏa, Thổ, Nhật, Nguyệt. Mảnh vỡ trên người quý khách không đủ, nên không thể đổi.")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
            return

        end
        local AllItemCanDelete = 1
        for i, ItemId in pairs(self.g_ItemId) do
            if self:LuaFnGetAvailableItemCount(selfId, ItemId) < 1 then
                AllItemCanDelete = 0
                break
            end
        end

        if AllItemCanDelete == 0 then
            self:BeginEvent(self.script_id)
            self:AddText(
                "    Trừ vật phẩm trên người thất bại, xin kiểm tra xem ngài có khóa vật phẩm hay không, hoặc vật phẩm đang ở Trạng thái giao dịch.")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
            return
        end
        self:BeginAddItem()
        self:AddItem(self.g_PetEggId, 1)
        local ret = self:EndAddItem(selfId)
        local delret = 1
        if ret then
            for i, ItemId in pairs(self.g_ItemId) do
                if not self:LuaFnDelAvailableItem(selfId, ItemId, 1) then
                    delret = 0
                    break
                end
            end
            if delret == 1 then
                self:AddItemListToHuman(selfId)
                local transfer = self:GetItemTransfer(selfId, 0)
                local fmt = "#P #{_INFOUSR%s} sau một phen cố gắng, cuối cùng cũng thu thập đủ các mảnh vỡ tượng trưng cho thất diệu của Kim Tinh, Mộc Tinh, Thủy Tinh, Hỏa Tinh, Thổ Tinh, Nguyệt Lượng, Thái Dương. Để tạ ơn, Cung Thải Vân của Đại Lý đặc biệt tặng cho người này một #{_INFOMSG%s}."
                fmt = gbk.fromutf8(fmt)
                local str = string.format(fmt, gbk.fromutf8(self:GetName(selfId)), transfer)
                self:BroadMsgByChatPipe(selfId, str, 4)
                self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 18, 1000)
                self:BeginUICommand()
                self:EndUICommand()
                self:DispatchUICommand(selfId, 1000)
            end
        end
        return
    end
    if index == 2 then
        self:BeginEvent(self.script_id)
        self:AddText("#YĐổi Chim Cánh Cụt")
        self:AddText("#{duihuanqie_shuoming}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
end

function edali_0242:OnEnumerate(caller, selfId, targetId, arg, index)
    if self:IsValidPenguinEggExchangeTime() == 0 then return end
    caller:AddNumTextWithTarget(self.script_id, "Ta muốn đổi trứng chim cánh cụt", 6, 1)
    caller:AddNumTextWithTarget(self.script_id, "Về việc đổi trứng chim cánh cụt", 0, 2)
end

function edali_0242:CheckAccept(selfId) end

function edali_0242:OnAccept(selfId, targetId) end

function edali_0242:OnAbandon(selfId) end

function edali_0242:CheckSubmit(selfId) end

function edali_0242:OnSubmit(selfId, targetId, selectRadioId) end

function edali_0242:OnEnterZone(selfId, zoneId) end

function edali_0242:IsValidPenguinEggExchangeTime()
    local theDay = self:GetDayTime()
    if theDay < self.g_ExchangePenguinEggStartDay or theDay >
        self.g_ExchangePenguinEggEndDay then return 0 end
    return 1
end

function edali_0242:PickupItem(selfId, itemId, bagidx)
    local transfer = self:GetBagItemTransfer(selfId, bagidx)
    local fmt = "#P #{_INFOUSR%s} đào được một khối quái thạch, lau sạch bùn đất mới phát hiện ra đó là một khối #{_INFOMSG%s}."
    fmt = gbk.fromutf8(fmt)
    local str = string.format(fmt, self:GetName(selfId), transfer)
    self:BroadMsgByChatPipe(selfId, str, 4)
end

function edali_0242:CheckPercentOK(numerator, denominator)
    local roll = math.random(denominator)
    if roll <= numerator then return 1 end
    return 0
end

function edali_0242:IsValidDayToDrop_QiXingSuiPian()
    local DayTime = self:GetDayTime()
    if DayTime < self.g_Drop_QiXingSuiPian_StartDay or DayTime >
        self.g_Drop_QiXingSuiPian_EndDay then return 0 end
    return 1
end

function edali_0242:DropStoneList(LongzhuIndex)
    if 0 == self:IsValidDayToDrop_QiXingSuiPian() then return -1 end
    if 1 == LongzhuIndex then
        local CheckOK = self:CheckPercentOK(667, 100000)
        if 1 == CheckOK then return 30505114 end
    end
    if 2 == LongzhuIndex then
        local CheckOK = self:CheckPercentOK(167, 100000)
        if 1 == CheckOK then return 30505115 end
    end

    if 3 == LongzhuIndex then
        local CheckOK = self:CheckPercentOK(67, 100000)
        if 1 == CheckOK then return 30505116 end
    end
    if 4 == LongzhuIndex then
        local CheckOK = self:CheckPercentOK(37, 100000)
        if 1 == CheckOK then return 30505117 end
    end
    if 5 == LongzhuIndex then
        local CheckOK = self:CheckPercentOK(23, 100000)
        if 1 == CheckOK then return 30505118 end
    end
    if 6 == LongzhuIndex then
        local CheckOK = self:CheckPercentOK(13, 100000)
        if 1 == CheckOK then return 30505119 end
    end
    if 7 == LongzhuIndex then
        local CheckOK = self:CheckPercentOK(7, 100000)
        if 1 == CheckOK then return 30505120 end
    end
    return -1
end

return edali_0242
