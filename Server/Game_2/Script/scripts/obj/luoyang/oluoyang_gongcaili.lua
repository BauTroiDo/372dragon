local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_gongcaili = class("oluoyang_gongcaili", script_base)
oluoyang_gongcaili.script_id = 000132
oluoyang_gongcaili.g_Key = {["chg"] = 1, ["in1"] = 2, ["in2"] = 3, ["bak"] = 4}

oluoyang_gongcaili.g_eventList = {808065}

oluoyang_gongcaili.g_ChangeLst = {
    [1] = {
        ["des"] = "Đổi Mặc Kính Miêu Cấp độ 5",
        ["id"] = 30505109,
        ["key"] = 101,
        ["NeedItm"] = 30008026,
        ["NeedNum"] = 30
    },
    [2] = {
        ["des"] = "Đổi Lưu Hành Miêu Cấp độ 45",
        ["id"] = 30505110,
        ["key"] = 102,
        ["NeedItm"] = 30008026,
        ["NeedNum"] = 40
    },
    [3] = {
        ["des"] = "Đổi lấy Mèo Thời Trang cấp 55",
        ["id"] = 30505111,
        ["key"] = 103,
        ["NeedItm"] = 30008026,
        ["NeedNum"] = 43
    },
    [4] = {
        ["des"] = "Đổi lấy Mèo Thần Tượng cấp 65",
        ["id"] = 30505112,
        ["key"] = 104,
        ["NeedItm"] = 30008026,
        ["NeedNum"] = 46
    },
    [5] = {
        ["des"] = "Đổi lấy Mèo Vô Địch cấp 75",
        ["id"] = 30505113,
        ["key"] = 105,
        ["NeedItm"] = 30008026,
        ["NeedNum"] = 50
    },
    [6] = {
        ["des"] = "Đổi lấy Mèo Cát Tường cấp 85",
        ["id"] = 30505154,
        ["key"] = 106,
        ["NeedItm"] = 30008026,
        ["NeedNum"] = 80
    }
}

function oluoyang_gongcaili:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{ANXIANG_DLG}")
    self:AddNumText("Ta muốn đổi Mặc Kính Miêu", 6, self.g_Key["chg"])
    self:AddNumText("Về việc đổi", 11, self.g_Key["in1"])
    local i, eventId
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oluoyang_gongcaili:OnEventRequest(selfId, targetId, arg, index)
    local key = index
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId)
            return
        end
    end
    if key == self.g_Key["chg"] then
        self:BeginEvent(self.script_id)
        self:AddText("    Ngươi muốn đổi Trân thú mang theo cấp độ gì?")
        for i = 1, #self.g_ChangeLst do
            self:AddNumText(self.g_ChangeLst[i]["des"], 6,
                            self.g_ChangeLst[i]["key"])
        end
        self:AddNumText("Quay lại trang trước", -1, self.g_Key["bak"])
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif key == self.g_Key["in1"] then
        self:MsgBox(selfId, targetId, "#{ANXIANG_CHG}")
    elseif key == self.g_Key["in2"] then
        self:MsgBox(selfId, targetId, "#{ANXIANG_INF}")
    elseif key == self.g_Key["bak"] then
        self:OnDefaultEvent(selfId, targetId)
    else
        for i = 1, #(self.g_ChangeLst) do
            if key == self.g_ChangeLst[i]["key"] then
                self:OnMyChange(selfId, targetId, self.g_ChangeLst[i])
                break
            end
        end
    end
end

function oluoyang_gongcaili:OnMyChange(selfId, targetId, unt)
    if unt == nil then return end
    if self:LuaFnGetAvailableItemCount(selfId, unt["NeedItm"]) < unt["NeedNum"] then
        self:MsgBox(selfId, targetId,
                    "    " .. unt["des"] ..
                        ", Mảnh Vỡ Cổ Vật trên người ngươi không đủ." ..
                        unt["NeedNum"] ..
                        "cái. (Mảnh Vỡ Cổ Vật có thể nhận được thông qua mở Hộp Báu Ám Kim)")
        return
    end
    self:BeginAddItem()
    self:AddItem(unt["id"], 1)
    if self:EndAddItem(selfId) then
        if self:LuaFnDelAvailableItem(selfId, unt["NeedItm"], unt["NeedNum"]) then
            self:AddItemListToHuman(selfId)
        else
            self:MsgBox(selfId, targetId, "    Trừ vật phẩm thất bại!")
            return
        end
    else
        self:MsgBox(selfId, targetId,
                    "    Xin lỗi, túi của ngươi đã đầy, không thể đổi.")
        return
    end
    local BagPos = self:GetBagPosByItemSn(selfId, unt["id"])
    local szTran = self:GetBagItemTransfer(selfId, BagPos)
    local szUser = "#{_INFOUSR" .. self:GetName(selfId) .. "}"
    local szItem = "#{_INFOMSG" .. szTran .. "}"
    local szMsg = string.format( "#W%s#cff99cctrải nghìn cay đắng vì#GLạc Dương (111,163)#YCung Thái Lệ#cff99ccgom đủ#Ymảnh sứ cổ#cff99cc, Cung Thái Lệ dâng %%s để cảm tạ.", szUser)
    szMsg = gbk.fromutf8(szMsg)
    szMsg = string.format(szMsg, szItem)
    self:MsgBox(selfId, targetId, "Bạn đã đổi thành công" ..
                    self:GetItemName(unt["id"]) .. "。")
    self:BroadMsgByChatPipe(selfId, szMsg, 4)
end

function oluoyang_gongcaili:MsgBox(selfId, targetId, str)
    self:BeginEvent(self.script_id)
    self:AddText(str)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oluoyang_gongcaili
