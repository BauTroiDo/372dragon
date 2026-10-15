local class = require "class"
local script_base = require "script_base"
local cy4_guigu_sign = class("cy4_guigu_sign", script_base)
cy4_guigu_sign.script_id = 500075
cy4_guigu_sign.g_Signpost = {
    {["type"] = 2, ["name"] = "Gia nhập Quỷ Cốc", ["x"] = 99, ["y"] = 56, ["tip"] = "Vương Thiền Nhất", ["desc"] = "Muốn bái sư hãy tìm Vương Thiền Nhất. Ấn TAB, trên bản đồ sẽ có ký hiệu nhấp nháy.", ["eventId"] = -1},
    {["type"] = 2, ["name"] = "Học võ công Quỷ Cốc", ["x"] = 92, ["y"] = 55, ["tip"] = "Lý Kế Long", ["desc"] = "Lý Kế Long truyền dạy tâm pháp, bí tịch và yếu quyết của bổn phái. Ấn TAB để thấy ký hiệu nhấp nháy.", ["eventId"] = -1},
    {["type"] = 2, ["name"] = "Học khinh công Quỷ Cốc", ["x"] = 106, ["y"] = 56, ["tip"] = "Ngô Bành", ["desc"] = "Ngô Bành dạy khinh công độc môn. Ấn TAB để thấy ký hiệu nhấp nháy.", ["eventId"] = -1},
    {["type"] = 2, ["name"] = "Học nghề Quỷ Cốc Phù Lục", ["x"] = 50, ["y"] = 63, ["tip"] = "Trương Di", ["desc"] = "Trương Di dạy Quỷ Cốc Phù Lục và công thức chế tạo. Ấn TAB để thấy ký hiệu nhấp nháy.", ["eventId"] = -1},
    {["type"] = 2, ["name"] = "Học nghề Linh Ngọc Thuật", ["x"] = 48, ["y"] = 61, ["tip"] = "Tiểu Tiên Nhi", ["desc"] = "Tiểu Tiên Nhi dạy Linh Ngọc Thuật. Ấn TAB để thấy ký hiệu nhấp nháy.", ["eventId"] = -1},
    {["type"] = 2, ["name"] = "Mua toạ kỵ Quỷ Cốc", ["x"] = 150, ["y"] = 150, ["tip"] = "Tô Cầm", ["desc"] = "Tô Cầm bán toạ kỵ môn phái ba cấp 40/60/80. Ấn TAB để thấy ký hiệu nhấp nháy.", ["eventId"] = -1},
    {["type"] = 2, ["name"] = "Bái kiến chưởng môn", ["x"] = 96, ["y"] = 52, ["tip"] = "Vũ Hủ Chi", ["desc"] = "Vũ Hủ Chi là chưởng môn Quỷ Cốc. Ấn TAB để thấy ký hiệu nhấp nháy.", ["eventId"] = -1},
    {["type"] = 2, ["name"] = "Nhiệm vụ sư môn", ["x"] = 96, ["y"] = 98, ["tip"] = "Vương Huyền Phong", ["desc"] = "Vương Huyền Phong phụ trách nhiệm vụ sư môn (hiện chưa mở tại máy chủ này). Ấn TAB để thấy ký hiệu nhấp nháy.", ["eventId"] = -1},
    {["type"] = 2, ["name"] = "Về Đại Lý", ["x"] = 89, ["y"] = 149, ["tip"] = "Cửu Nhật Thông", ["desc"] = "Cửu Nhật Thông có thể đưa ngươi trở về Đại Lý. Ấn TAB để thấy ký hiệu nhấp nháy.", ["eventId"] = -1},
}

function cy4_guigu_sign:OnEnumerate(caller, selfId, targetId, arg, index)
    for i, signpost in ipairs(self.g_Signpost) do
        caller:AddNumTextWithTarget(self.script_id, signpost["name"], -1, i)
    end
end

function cy4_guigu_sign:OnDefaultEvent(selfId, targetId, arg, index)
    local signpost = self.g_Signpost[index]
    if not signpost then return end
    self:CallScriptFunction(888888, "AskTheWay", selfId, self:get_scene_id(), signpost["x"], signpost["y"], signpost["tip"])
    self:BeginEvent(self.script_id)
    self:AddText(signpost["desc"])
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return cy4_guigu_sign
