local class = require "class"
local define = require "define"
local script_base = require "script_base"
local luoyang_sign_buyitem = class("luoyang_sign_buyitem", script_base)
luoyang_sign_buyitem.script_id = 500001
luoyang_sign_buyitem.g_Signpost = {
    { ["type"] = 2, ["name"] = "Tiệm binh khí", ["x"] = 210, ["y"] = 154, ["tip"] = "王德贵",
        ["desc"] = "Lão bản tiệm binh khí Vương Đức Quý (210, 154) ở trong tiệm binh khí tại Đông Thị. Ấn phím TAB, trên bản đồ sẽ có ký hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "杂货商人", ["x"] = 254, ["y"] = 145, ["tip"] = "芮福祥",
        ["desc"] = "Thương nhân tạp hóa Nhuế Phúc Tường (254, 146) ở bên trong Đông Môn. Nhấn phím TAB, trên bản đồ sẽ có ký hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Tiệm phục sức", ["x"] = 182, ["y"] = 183, ["tip"] = "甄唯思",
        ["desc"] = "Chưởng quỹ tiệm y phục Chân Duy Tư (182, 183) ở tiệm y phục đường Nam Đại. Nhấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Tiệm Trang sức", ["x"] = 178, ["y"] = 177, ["tip"] = "贾作珍",
        ["desc"] = "Chưởng quỹ Giả Tác Trân (178, 177) của tiệm Trang sức ở cửa hàng quần áo đường Nam Đại. Ấn phím TAB, trên bản đồ sẽ có ký hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Tiệm thuốc", ["x"] = 135, ["y"] = 164, ["tip"] = "白萌生",
        ["desc"] = "Chưởng quỹ tiệm thuốc Bạch Manh Sinh (135, 164) ở tiệm thuốc đường Nam. Nhấn phím TAB, trên bản đồ sẽ có ký hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Tửu Điếm", ["x"] = 138, ["y"] = 140, ["tip"] = "范统",
        ["desc"] = "Chưởng quỹ tửu điếm Phạm Thống (138, 140) ở phía nam Đại Lộ Phía Tây. Nhấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "珠宝商人", ["x"] = 63, ["y"] = 147, ["tip"] = "郎夫人",
        ["desc"] = "Thương nhân châu báu Lang phu nhân (63, 147) ở bên trong Tây Môn. Ấn phím TAB, trên bản đồ sẽ có ký hiệu nhấp nháy.",
        ["eventId"] = -1 }
}
function luoyang_sign_buyitem:OnEnumerate(caller, selfId, targetId, arg, index)
    for i, signpost in pairs(self.g_Signpost) do
        caller:AddNumTextWithTarget(self.script_id, signpost["name"], -1, i)
    end
end

function luoyang_sign_buyitem:OnDefaultEvent(selfId, targetId,arg,index)
    local signpost = self.g_Signpost[index]
    if signpost["type"] == 1 then
        self:BeginEvent(self.script_id)
        self:AddText(signpost["name"] .. "：")
        self:CallScriptFunction(signpost["eventId"], "OnEnumerate", selfId, targetId)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif signpost["type"] == 2 then
        self:CallScriptFunction(888888, "AskTheWay", selfId, signpost["x"], signpost["y"], signpost["tip"])
        self:BeginEvent(self.script_id)
        self:AddText(signpost["desc"])
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
end

return luoyang_sign_buyitem
