local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local edali_0243 = class("edali_0243", script_base)
edali_0243.script_id = 210243
edali_0243.g_ItemId = {
    {["mp"] = 0, ["Item"] = 10124009, ["mpname"] = "Thiếu Lâm phái"},
    {["mp"] = 1, ["Item"] = 10124010, ["mpname"] = "明教"},
    {["mp"] = 2, ["Item"] = 10124011, ["mpname"] = "丐帮"},
    {["mp"] = 4, ["Item"] = 10124012, ["mpname"] = "Nga My phái"},
    {["mp"] = 3, ["Item"] = 10124013, ["mpname"] = "Võ Đang phái"},
    {["mp"] = 5, ["Item"] = 10124014, ["mpname"] = "Tinh Túc phái"},
    {["mp"] = 7, ["Item"] = 10124015, ["mpname"] = "Thiên Sơn phái"},
    {["mp"] = 8, ["Item"] = 10124016, ["mpname"] = "Tiêu Dao phái"},
    {["mp"] = 6, ["Item"] = 10124017, ["mpname"] = "Thiên Long phái"},
    {["mp"] = 9, ["Item"] = 0}
}
edali_0243.g_Stone = {["id"] = 30505122, ["num"] = 20}
edali_0243.g_Stone2 = {["id"] = 30505135, ["num"] = 20}
function edali_0243:OnDefaultEvent(selfId, targetId)
    if index == 1 then
        self:BeginEvent(self.script_id)
        self:AddText("#YNhận Môn phái Cao cấp Thời Trang")
        self:AddText("  Có một vị lữ hành gia từng kinh ngạc phát hiện, trên Ngân Ngải Tuyết Nguyên, một số yêu vật trên thân có thể mang theo #YNhật ký yêu vật#W thần bí. Nếu ngươi có thể giúp hắn tìm 20 quyển #YNhật ký yêu vật#W, liền có thể nhận được một bộ Môn phái Cao cấp Thời Trang mà hắn tặng cho.#r Thế nào, ngươi có muốn đổi không?")
        self:AddNumText("Đổi", 8, 3)
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
        local nMenpai = self:GetMenPai(selfId)
        if nMenpai < 0 or nMenpai > 8 then
            self:BeginEvent(self.script_id)
            self:AddText("  Ngươi còn chưa gia nhập Môn phái nào, chỉ có đệ tử của Cửu Đại Môn phái mới có thể đổi Thời Trang Cao cấp của Môn phái thôi.")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
            return
        end
        local HaveAllItem = 1
        if (self:GetItemCount(selfId, self.g_Stone["id"]) +
            self:GetItemCount(selfId, self.g_Stone2["id"])) <
            self.g_Stone["num"] then HaveAllItem = 0 end
        if HaveAllItem == 0 then
            self:BeginEvent(self.script_id)
            self:AddText("  Ngươi #Yêu cầu# mang 20 quyển #Nhật Ký Quái Vật# mới có thể đổi #Thời Trang# #Cao cấp# #Môn phái#.")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
            return
        end
        local AllItemCanDelete = 1
        local Stone1_Num = self:LuaFnGetAvailableItemCount(selfId, self.g_Stone["id"])
        local Stone2_Num = self:LuaFnGetAvailableItemCount(selfId, self.g_Stone2["id"])
        if Stone1_Num + Stone2_Num < self.g_Stone["num"] then
            AllItemCanDelete = 0
        end
        if AllItemCanDelete == 0 then
            self:BeginEvent(self.script_id)
            self:AddText("    Khấu trừ vật phẩm trên người của ngươi thất bại, xin kiểm tra xem ngươi có khóa vật phẩm không, hoặc vật phẩm đang ở trạng thái giao dịch.")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
            return
        end
        local bagpos = -1
        if Stone1_Num > 0 then
            bagpos = self:GetBagPosByItemSn(selfId, self.g_Stone["id"])
        elseif Stone1_Num == 0 and Stone2_Num > 0 then
            bagpos = self:GetBagPosByItemSn(selfId, self.g_Stone2["id"])
        end
        local GemItemInfo
        if bagpos ~= -1 then
            GemItemInfo = self:GetBagItemTransfer(selfId, bagpos)
        end
        local nItemId = 0
        local nMenpaiName = ""
        for i = 1, 10 do
            if nMenpai == self.g_ItemId[i]["mp"] then
                nItemId = self.g_ItemId[i]["Item"]
                nMenpaiName = self.g_ItemId[i]["mpname"]
            end
        end
        if nItemId == 0 then return end
        self:BeginAddItem()
        self:AddItem(nItemId, 1)
        local ret = self:EndAddItem(selfId)
        local delret = 1
        if ret then
            local DeleteNum = self:LuaFnGetAvailableItemCount(selfId, self.g_Stone["id"])
            if (DeleteNum >= self.g_Stone["num"]) then
                if not self:LuaFnDelAvailableItem(selfId, self.g_Stone["id"], self.g_Stone["num"]) then
                    delret = 0
                end
            elseif (DeleteNum == 0) then
                if not self:LuaFnDelAvailableItem(selfId, self.g_Stone2["id"], self.g_Stone["num"]) then
                    delret = 0
                end
            else
                if not self:LuaFnDelAvailableItem(selfId, self.g_Stone["id"], DeleteNum) then
                    delret = 0
                end
                DeleteNum = self.g_Stone["num"] - DeleteNum
                if not self:LuaFnDelAvailableItem(selfId, self.g_Stone2["id"], DeleteNum) then
                    delret = 0
                end
            end
            if delret == 1 then
                self:AddItemListToHuman(selfId)
                self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 18, 1000)
                self:BeginEvent(self.script_id)
                self:AddText("Ngươi nhận được" .. nMenpaiName .. "của Cao cấp Môn phái Bộ Trang bị một kiện.")
                self:EndEvent()
                self:DispatchMissionTips(selfId)
                local str = ""
                local rand = math.random(3)
                local name = self:GetName(selfId)
                name = gbk.fromutf8(name)
                if rand == 1 then
                    local fmt = gbk.fromutf8("#PTức thì! Trời đất tối sầm, mọi người đều không biết làm sao, thì ra là #{_INFOUSR%s} sử dụng #G20 quyển #{_INFOMSG%s}#P đổi được #G %s Cao cấp Môn phái Thời Trang#P vô cùng tuyệt diệu khiến bao người ngưỡng mộ!")
                    str = string.format(fmt, name, GemItemInfo, nMenpaiName)
                elseif rand == 2 then
                    local fmt = gbk.fromutf8("#PỐi chao! #{_INFOUSR%s} sử dụng #G20 quyển #{_INFOMSG%s}#P đổi được #G %s Cao cấp Môn phái Thời Trang#P, mặc vào thật là chói mắt kinh người!")
                    str = string.format(fmt, name, GemItemInfo, nMenpaiName)
                else
                    local fmt = gbk.fromutf8("#P#{_INFOUSR%s} sử dụng #G20 quyển #{_INFOMSG%s}#P đổi được #G %sThời Trang Cao cấp Môn phái#P! Chúc mừng! Chúc mừng! Chúc mừng hơn nữa!")
                    str = string.format(fmt, name, GemItemInfo, nMenpaiName)
                end
                self:BroadMsgByChatPipe(selfId, str, 4)
                self:BeginUICommand()
                self:EndUICommand()
                self:DispatchUICommand(selfId, 1000)
                return
            end
        end
        return
    end
    if index == 2 then
        self:BeginEvent(self.script_id)
        self:AddText("#{function_help_094}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
end

function edali_0243:OnEnumerate(caller, selfId, targetId, arg, index)
    caller:AddNumTextWithTarget(self.script_id, "Lĩnh Thời Trang Cao cấp Môn phái", 6, 1)
    caller:AddNumTextWithTarget(self.script_id, "Lĩnh tửu quán Thời Trang Cao cấp Môn phái", 0, 2)
end

function edali_0243:CheckAccept(selfId) end

function edali_0243:OnAccept(selfId, targetId) end

function edali_0243:OnAbandon(selfId) end

function edali_0243:CheckSubmit(selfId) end

function edali_0243:OnSubmit(selfId, targetId, selectRadioId) end

function edali_0243:OnEnterZone(selfId, zoneId) end

return edali_0243
