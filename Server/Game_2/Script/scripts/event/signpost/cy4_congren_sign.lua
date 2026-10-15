local class = require "class"
local script_base = require "script_base"
local cy4_congren_sign = class("cy4_congren_sign", script_base)
cy4_congren_sign.script_id = 500077
cy4_congren_sign.g_Signpost = {
    {["type"] = 2, ["name"] = "Gia nhập Tuyệt Tình Cốc", ["x"] = 258, ["y"] = 168, ["tip"] = "Hành Nghiêm", ["desc"] = "Muốn bái sư hãy tìm Hành Nghiêm. Ấn TAB, trên bản đồ sẽ có ký hiệu nhấp nháy.", ["eventId"] = -1},
    {["type"] = 2, ["name"] = "Học võ công Tuyệt Tình Cốc", ["x"] = 231, ["y"] = 170, ["tip"] = "Vân Kiêu", ["desc"] = "Vân Kiêu truyền dạy tâm pháp, bí tịch và yếu quyết của bổn phái. Ấn TAB để thấy ký hiệu nhấp nháy.", ["eventId"] = -1},
    {["type"] = 2, ["name"] = "Học khinh công Tuyệt Tình Cốc", ["x"] = 281, ["y"] = 170, ["tip"] = "Lăng Xước", ["desc"] = "Lăng Xước dạy khinh công độc môn. Ấn TAB để thấy ký hiệu nhấp nháy.", ["eventId"] = -1},
    {["type"] = 2, ["name"] = "Học nghề Thông Nhận Thuật", ["x"] = 277, ["y"] = 273, ["tip"] = "Vu Chỉ", ["desc"] = "Vu Chỉ dạy Thông Nhận Thuật và công thức chế tạo. Ấn TAB để thấy ký hiệu nhấp nháy.", ["eventId"] = -1},
    {["type"] = 2, ["name"] = "Học nghề Phần Tâm", ["x"] = 283, ["y"] = 270, ["tip"] = "Dĩ Hằng", ["desc"] = "Dĩ Hằng dạy Phần Tâm. Ấn TAB để thấy ký hiệu nhấp nháy.", ["eventId"] = -1},
    {["type"] = 2, ["name"] = "Mua toạ kỵ Tuyệt Tình Cốc", ["x"] = 115, ["y"] = 249, ["tip"] = "Lộ Mạn", ["desc"] = "Lộ Mạn bán toạ kỵ môn phái ba cấp 40/60/80. Ấn TAB để thấy ký hiệu nhấp nháy.", ["eventId"] = -1},
    {["type"] = 2, ["name"] = "Nhiệm vụ sư môn", ["x"] = 245, ["y"] = 191, ["tip"] = "Thất Thúc", ["desc"] = "Thất Thúc phụ trách nhiệm vụ sư môn (hiện chưa mở tại máy chủ này). Ấn TAB để thấy ký hiệu nhấp nháy.", ["eventId"] = -1},
    {["type"] = 2, ["name"] = "Về Đại Lý", ["x"] = 243, ["y"] = 252, ["tip"] = "Cẩn Hành", ["desc"] = "Cẩn Hành có thể đưa ngươi trở về Đại Lý. Ấn TAB để thấy ký hiệu nhấp nháy.", ["eventId"] = -1},
}

function cy4_congren_sign:OnEnumerate(caller, selfId, targetId, arg, index)
    for i, signpost in ipairs(self.g_Signpost) do
        caller:AddNumTextWithTarget(self.script_id, signpost["name"], -1, i)
    end
end

function cy4_congren_sign:OnDefaultEvent(selfId, targetId, arg, index)
    local signpost = self.g_Signpost[index]
    if not signpost then return end
    self:CallScriptFunction(888888, "AskTheWay", selfId, self:get_scene_id(), signpost["x"], signpost["y"], signpost["tip"])
    self:BeginEvent(self.script_id)
    self:AddText(signpost["desc"])
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return cy4_congren_sign
