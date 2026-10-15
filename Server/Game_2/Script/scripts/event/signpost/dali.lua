local class = require "class"
local define = require "define"
local script_base = require "script_base"
local dali = class("dali", script_base)
dali.script_id = 500040
dali.g_Signpost = {
    { ["type"] = 1, ["name"] = "Làm sao gia nhập Môn phái", ["eventId"] = 500049, ["x"] = 0, ["y"] = 0, ["tip"] = " ",
        ["desc"] = " " }
    , { ["type"] = 1, ["name"] = "Cửu đại Môn phái Người truyền tống", ["eventId"] = 500041, ["x"] = 0, ["y"] = 0, ["tip"] = " ",
    ["desc"] = " " }
, { ["type"] = 1, ["name"] = "Mua các loại vật phẩm", ["eventId"] = 500042, ["x"] = 0, ["y"] = 0, ["tip"] = " ",
    ["desc"] = " " }
, { ["type"] = 1, ["name"] = "Dịch trạm", ["eventId"] = 500043, ["x"] = 0, ["y"] = 0, ["tip"] = " ", ["desc"] = " " }
, { ["type"] = 1, ["name"] = "Tiệm cầm đồ, ngân hàng", ["eventId"] = 500044, ["x"] = 0, ["y"] = 0, ["tip"] = " ", ["desc"] = " " }
, { ["type"] = 1, ["name"] = "Ta muốn ra khỏi thành để luyện tập bản lĩnh", ["eventId"] = 500045, ["x"] = 0, ["y"] = 0, ["tip"] = " ",
    ["desc"] = " " }
, { ["type"] = 1, ["name"] = "Học một vài Kỹ năng sống", ["eventId"] = 500046, ["x"] = 0, ["y"] = 0, ["tip"] = " ",
    ["desc"] = " " }
, { ["type"] = 1, ["name"] = "Nhiệm vụ và Phó bản", ["eventId"] = 500047, ["x"] = 0, ["y"] = 0, ["tip"] = " ", ["desc"] = " " }
, { ["type"] = 1, ["name"] = "Lôi Đài", ["eventId"] = 500048, ["x"] = 0, ["y"] = 0, ["tip"] = " ", ["desc"] = " " }
, { ["type"] = 1, ["name"] = "Bái sư", ["eventId"] = 500049, ["x"] = 0, ["y"] = 0, ["tip"] = " ", ["desc"] = " " }
}
function dali:OnEnumerate(caller, selfId, targetId, arg, index)
    for i, signpost in pairs(self.g_Signpost) do
        caller:AddNumTextWithTarget(self.script_id, signpost["name"], -1, i)
    end
end

function dali:OnDefaultEvent(selfId, targetId,arg,index)
    local signpost = self.g_Signpost[index]
    if index == 1 then
        self:BeginEvent(self.script_id)
        self:AddText(signpost["name"] .. "：")
        self:AddText("Hãy đến Dịch trạm ở các thành phố (nhấn Tab để mở bản đồ xem ký tự #GY#W) để truyền tống đến Môn phái mà bạn muốn bái sư. Sau khi đến Môn phái, hãy nhấp vào #GNgười chỉ đường Môn phái#W để hỏi vị trí bái sư. Hoặc nhấn phím Tab để mở bản đồ tìm ký tự #GSư#W.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        self:CallScriptFunction(888888, "AskTheWay", selfId, 241, 136, "崔逢九")
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

return dali
