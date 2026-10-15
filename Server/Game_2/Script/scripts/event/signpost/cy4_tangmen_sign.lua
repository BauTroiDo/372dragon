local class = require "class"
local script_base = require "script_base"
local cy4_tangmen_sign = class("cy4_tangmen_sign", script_base)
cy4_tangmen_sign.script_id = 500074
cy4_tangmen_sign.g_Signpost = {
    {["type"] = 2, ["name"] = "Gia nhập Đường Môn", ["x"] = 78, ["y"] = 35, ["tip"] = "Đường Diệc Phong", ["desc"] = "Muốn bái sư hãy tìm Đường Diệc Phong. Ấn TAB, trên bản đồ sẽ có ký hiệu nhấp nháy.", ["eventId"] = -1},
    {["type"] = 2, ["name"] = "Học võ công Đường Môn", ["x"] = 38, ["y"] = 75, ["tip"] = "Đường Nhạc Xung", ["desc"] = "Đường Nhạc Xung truyền dạy tâm pháp, bí tịch và yếu quyết của bổn phái. Ấn TAB để thấy ký hiệu nhấp nháy.", ["eventId"] = -1},
    {["type"] = 2, ["name"] = "Học khinh công Đường Môn", ["x"] = 88, ["y"] = 111, ["tip"] = "Đường Xuân", ["desc"] = "Đường Xuân dạy khinh công độc môn. Ấn TAB để thấy ký hiệu nhấp nháy.", ["eventId"] = -1},
    {["type"] = 2, ["name"] = "Học nghề Biên Nạp Thuật", ["x"] = 40, ["y"] = 142, ["tip"] = "Lão Lão Đường Môn", ["desc"] = "Lão Lão Đường Môn dạy Biên Nạp Thuật và công thức chế tạo. Ấn TAB để thấy ký hiệu nhấp nháy.", ["eventId"] = -1},
    {["type"] = 2, ["name"] = "Học nghề Bách Thảo Thức Biện", ["x"] = 41, ["y"] = 140, ["tip"] = "Đường Nhược Hề", ["desc"] = "Đường Nhược Hề dạy Bách Thảo Thức Biện. Ấn TAB để thấy ký hiệu nhấp nháy.", ["eventId"] = -1},
    {["type"] = 2, ["name"] = "Mua toạ kỵ Đường Môn", ["x"] = 169, ["y"] = 33, ["tip"] = "Đường Tự Cơ", ["desc"] = "Đường Tự Cơ bán toạ kỵ môn phái ba cấp 40/60/80. Ấn TAB để thấy ký hiệu nhấp nháy.", ["eventId"] = -1},
    {["type"] = 2, ["name"] = "Bái kiến chưởng môn", ["x"] = 66, ["y"] = 30, ["tip"] = "Đường Nhạc Thiên", ["desc"] = "Đường Nhạc Thiên là chưởng môn Đường Môn. Ấn TAB để thấy ký hiệu nhấp nháy.", ["eventId"] = -1},
    {["type"] = 2, ["name"] = "Nhiệm vụ sư môn", ["x"] = 100, ["y"] = 64, ["tip"] = "Đường Thanh Thu", ["desc"] = "Đường Thanh Thu phụ trách nhiệm vụ sư môn (hiện chưa mở tại máy chủ này). Ấn TAB để thấy ký hiệu nhấp nháy.", ["eventId"] = -1},
    {["type"] = 2, ["name"] = "Về Đại Lý", ["x"] = 126, ["y"] = 68, ["tip"] = "Đường Dữ Thành", ["desc"] = "Đường Dữ Thành có thể đưa ngươi trở về Đại Lý. Ấn TAB để thấy ký hiệu nhấp nháy.", ["eventId"] = -1},
}

function cy4_tangmen_sign:OnEnumerate(caller, selfId, targetId, arg, index)
    for i, signpost in ipairs(self.g_Signpost) do
        caller:AddNumTextWithTarget(self.script_id, signpost["name"], -1, i)
    end
end

function cy4_tangmen_sign:OnDefaultEvent(selfId, targetId, arg, index)
    local signpost = self.g_Signpost[index]
    if not signpost then return end
    self:CallScriptFunction(888888, "AskTheWay", selfId, self:get_scene_id(), signpost["x"], signpost["y"], signpost["tip"])
    self:BeginEvent(self.script_id)
    self:AddText(signpost["desc"])
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return cy4_tangmen_sign
