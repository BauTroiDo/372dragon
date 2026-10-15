local class = require "class"
local define = require "define"
local script_base = require "script_base"
local luoyang = class("luoyang", script_base)
luoyang.script_id = 500000
luoyang.g_Signpost = {
    {
        ["type"] = 1,
        ["name"] = "Làm thế nào để nhận kinh nghiệm gấp đôi",
        ["eventId"] = 500049,
        ["x"] = 0,
        ["y"] = 0,
        ["tip"] = " ",
        ["desc"] = " "
    }
    , {
    ["type"] = 1,
    ["name"] = "Làm sao gia nhập Môn phái",
    ["eventId"] = 500049,
    ["x"] = 0,
    ["y"] = 0,
    ["tip"] = " ",
    ["desc"] = " "
}
, {
    ["type"] = 1,
    ["name"] = "Mua các loại vật phẩm",
    ["eventId"] = 500001,
    ["x"] = 0,
    ["y"] = 0,
    ["tip"] = " ",
    ["desc"] = " "
}
, { ["type"] = 1, ["name"] = "Dịch trạm", ["eventId"] = 500002, ["x"] = 0, ["y"] = 0, ["tip"] = " ", ["desc"] = " " }
, {
    ["type"] = 1,
    ["name"] = "Tiệm tiền, tiệm cầm đồ, Thương nhân Nguyên Bảo",
    ["eventId"] = 500003,
    ["x"] = 0,
    ["y"] = 0,
    ["tip"] = " ",
    ["desc"] = " "
}
, {
    ["type"] = 1,
    ["name"] = "Ta muốn ra khỏi thành để luyện tập bản lĩnh",
    ["eventId"] = 500004,
    ["x"] = 0,
    ["y"] = 0,
    ["tip"] = " ",
    ["desc"] = " "
}
, {
    ["type"] = 1,
    ["name"] = "Học một vài Kỹ năng sống",
    ["eventId"] = 500005,
    ["x"] = 0,
    ["y"] = 0,
    ["tip"] = " ",
    ["desc"] = " "
}
, { ["type"] = 1, ["name"] = "Nhiệm vụ và Phó bản", ["eventId"] = 500006, ["x"] = 0, ["y"] = 0, ["tip"] = " ", ["desc"] = " " }
, { ["type"] = 1, ["name"] = "Ta muốn kết hôn", ["eventId"] = 500007, ["x"] = 0, ["y"] = 0, ["tip"] = " ", ["desc"] = " " }
, { ["type"] = 1, ["name"] = "Bang phái", ["eventId"] = 500008, ["x"] = 0, ["y"] = 0, ["tip"] = " ", ["desc"] = " " }
, { ["type"] = 1, ["name"] = "Thương Hội", ["eventId"] = 500009, ["x"] = 0, ["y"] = 0, ["tip"] = " ", ["desc"] = " " }
, { ["type"] = 1, ["name"] = "Cỡi", ["eventId"] = 500010, ["x"] = 0, ["y"] = 0, ["tip"] = " ", ["desc"] = " " }
, { ["type"] = 1, ["name"] = "Lôi Đài", ["eventId"] = 500011, ["x"] = 0, ["y"] = 0, ["tip"] = " ", ["desc"] = " " }
, { ["type"] = 1, ["name"] = "Hợp thành Bảo thạch", ["eventId"] = 500012, ["x"] = 0, ["y"] = 0, ["tip"] = " ", ["desc"] = " " }
, { ["type"] = 1, ["name"] = "Kết nghĩa", ["eventId"] = 500013, ["x"] = 0, ["y"] = 0, ["tip"] = " ", ["desc"] = " " }
}
function luoyang:OnEnumerate(caller, selfId, targetId, arg, index)
    for i, signpost in pairs(self.g_Signpost) do
        caller:AddNumTextWithTarget(self.script_id, signpost["name"], -1, i)
    end
end

function luoyang:OnDefaultEvent(selfId, targetId, arg, index)
    local signpost = self.g_Signpost[index]
    local sceneId = self:GetSceneID()
    if index == 1 then
        self:BeginEvent(self.script_id)
        self:AddText(signpost["name"] .. "：")
        self:AddText("Xin đến chỗ Lưu Kiện Minh ở quảng trường Lạc Dương (150,91) lĩnh kinh nghiệm gấp đôi.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        self:CallScriptFunction(888888, "AskTheWay", selfId, sceneId, 150, 91, "刘健明")
        return
    end
    if index == 2 then
        self:BeginEvent(self.script_id)
        self:AddText(signpost["name"] .. "：")
        self:AddText("Hãy đến Dịch trạm ở các thành phố (nhấn Tab để mở bản đồ xem ký tự #GY#W) để truyền tống đến Môn phái mà bạn muốn bái sư. Sau khi đến Môn phái, hãy nhấp vào #GNgười chỉ đường Môn phái#W để hỏi vị trí bái sư. Hoặc nhấn phím Tab để mở bản đồ tìm ký tự #GSư#W.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        self:CallScriptFunction(888888, "AskTheWay", selfId, sceneId, 139, 182, "吴德昌")
        return
    end
    if signpost["type"] == 1 then
        self:BeginEvent(self.script_id)
        self:AddText(signpost["name"] .. "：")
        self:CallScriptFunction(signpost["eventId"], "OnEnumerate", selfId, targetId)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif signpost["type"] == 2 then
        self:CallScriptFunction(888888, "AskTheWay", selfId, sceneId, signpost["x"], signpost["y"], signpost["tip"])
        self:BeginEvent(self.script_id)
        self:AddText(signpost["desc"])
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
end

return luoyang
