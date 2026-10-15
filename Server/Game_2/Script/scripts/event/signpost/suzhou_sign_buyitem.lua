local class = require "class"
local define = require "define"
local script_base = require "script_base"
local suzhou_sign_buyitem = class("suzhou_sign_buyitem", script_base)
suzhou_sign_buyitem.script_id = 500021
suzhou_sign_buyitem.g_Signpost = {
    { ["type"] = 2, ["name"] = "Tiệm phục sức", ["x"] = 217, ["y"] = 88, ["tip"] = "左季高",
        ["desc"] = "Chủ tiệm y phục Tả Quý Cao (217,88) ở gần bến tàu phía Bắc thành. Nhấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Tiệm Trang sức", ["x"] = 217, ["y"] = 81, ["tip"] = "左无双",
        ["desc"] = "Chủ tiệm Trang sức Tả Vô Song (217,81) ở gần bến tàu phía bắc thành phố. Nhấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Tiệm Trân thú", ["x"] = 87, ["y"] = 142, ["tip"] = "云霏霏",
        ["desc"] = "Phường chủ Trùng Điểu Phường Vân Phi Phi (87,142) ở Trùng Điểu Phường phía bắc trong Tây Môn. Ấn phím TAB, trên bản đồ sẽ có ký hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Tiệm thuốc", ["x"] = 99, ["y"] = 155, ["tip"] = "胡繁",
        ["desc"] = "Lão bản hiệu thuốc Hồ Phồn (99,155) ở cửa nam chợ Tây. Nhấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Tửu Điếm", ["x"] = 190, ["y"] = 168, ["tip"] = "包世荣",
        ["desc"] = "Lão bản khách điếm Bao Thế Vinh (190,168) ở trước cửa khách điếm phía nam Trạng Nguyên Trường. Ấn phím TAB, trên bản đồ sẽ có ký hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Tiệm tạp hóa", ["x"] = 128, ["y"] = 173, ["tip"] = "孙子羽",
        ["desc"] = "Chủ tiệm tạp hóa Tôn Tử Vũ (128,173) ở phía nam đường Phong Kiều. Ấn phím TAB, trên bản đồ sẽ có ký hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "宝石商人", ["x"] = 110, ["y"] = 133, ["tip"] = "范大成",
        ["desc"] = "Thương nhân đá quý Phạm Đại Thành (110,133) ở phía đông đường Tây Thị. Ấn phím TAB, trên bản đồ sẽ có ký hiệu nhấp nháy.",
        ["eventId"] = -1 }
}
function suzhou_sign_buyitem:OnEnumerate(caller, selfId, targetId, arg, index)
    for i, signpost in pairs(self.g_Signpost) do
        caller:AddNumTextWithTarget(self.script_id, signpost["name"], -1, i)
    end
end

function suzhou_sign_buyitem:OnDefaultEvent(selfId, targetId, arg, index)
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

return suzhou_sign_buyitem
