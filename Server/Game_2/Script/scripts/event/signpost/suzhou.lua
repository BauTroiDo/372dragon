local class = require "class"
local define = require "define"
local script_base = require "script_base"
local suzhou = class("suzhou", script_base)
suzhou.script_id = 500020
suzhou.g_Signpost = {
    { ["type"] = 1, ["name"] = "Làm sao gia nhập Môn phái", ["eventId"] = 500049, ["x"] = 0, ["y"] = 0, ["tip"] = " ",
        ["desc"] = " " }
    ,
    { ["type"] = 2, ["name"] = "Làm thế nào để nhận kinh nghiệm gấp đôi", ["x"] = 164, ["y"] = 80, ["tip"] = "沈澄",
        ["desc"] = "Ngươi có thể đến chỗ Thẩm Trừng (164,80) để lĩnh gấp đôi kinh nghiệm, hắn ở gần khu vực Bắc Môn Tô Châu. Ấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1 }
    , { ["type"] = 1, ["name"] = "Mua các loại vật phẩm", ["eventId"] = 500021, ["x"] = 0, ["y"] = 0, ["tip"] = " ",
    ["desc"] = " " }
, { ["type"] = 1, ["name"] = "Ta muốn ra khỏi thành để luyện tập bản lĩnh", ["eventId"] = 500022, ["x"] = 0, ["y"] = 0, ["tip"] = " ",
    ["desc"] = " " }
, { ["type"] = 1, ["name"] = "Ta muốn học Kỹ năng sống", ["eventId"] = 500023, ["x"] = 0, ["y"] = 0, ["tip"] = " ",
    ["desc"] = " " }
, { ["type"] = 1, ["name"] = "Nhiệm vụ và Phó bản", ["eventId"] = 500024, ["x"] = 0, ["y"] = 0, ["tip"] = " ", ["desc"] = " " }
, { ["type"] = 1, ["name"] = "珍兽", ["eventId"] = 500025, ["x"] = 0, ["y"] = 0, ["tip"] = " ", ["desc"] = " " }
, { ["type"] = 1, ["name"] = "Dịch trạm", ["eventId"] = 500026, ["x"] = 0, ["y"] = 0, ["tip"] = " ", ["desc"] = " " }
, { ["type"] = 1, ["name"] = "Tiền Trang", ["eventId"] = 500027, ["x"] = 0, ["y"] = 0, ["tip"] = " ", ["desc"] = " " }
, { ["type"] = 1, ["name"] = "Trang bị Cường Hóa và Giám Định", ["eventId"] = 500028, ["x"] = 0, ["y"] = 0, ["tip"] = " ",
    ["desc"] = " " }
, { ["type"] = 1, ["name"] = "Loại bỏ sát khí", ["eventId"] = 500029, ["x"] = 0, ["y"] = 0, ["tip"] = " ", ["desc"] = " " }
}
function suzhou:OnEnumerate(caller, selfId, targetId, arg, index)
    for i, signpost in pairs(self.g_Signpost) do
        caller:AddNumTextWithTarget(self.script_id, signpost["name"], -1, i)
    end
end

function suzhou:OnDefaultEvent(selfId, targetId, arg, index)
    local signpost = self.g_Signpost[index]
    if index == 1 then
        self:BeginEvent(self.script_id)
        self:AddText(signpost["name"] .. "：")
        self:AddText("Hãy đến Dịch trạm ở các thành phố (nhấn Tab để mở bản đồ xem ký tự #GY#W) để truyền tống đến Môn phái mà bạn muốn bái sư. Sau khi đến Môn phái, hãy nhấp vào #GNgười chỉ đường Môn phái#W để hỏi vị trí bái sư. Hoặc nhấn phím Tab để mở bản đồ tìm ký tự #GSư#W.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        self:CallScriptFunction(888888, "AskTheWay", selfId, 111, 160, "李乘风")
        return
    end
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

return suzhou
