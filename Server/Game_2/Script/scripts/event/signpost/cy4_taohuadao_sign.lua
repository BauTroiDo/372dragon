local class = require "class"
local script_base = require "script_base"
local cy4_taohuadao_sign = class("cy4_taohuadao_sign", script_base)
cy4_taohuadao_sign.script_id = 500076
cy4_taohuadao_sign.g_Signpost = {
    {["type"] = 2, ["name"] = "Gia nhập Đào Hoa Đảo", ["x"] = 207, ["y"] = 72, ["tip"] = "Quân Hoàn Châu", ["desc"] = "Muốn bái sư hãy tìm Quân Hoàn Châu. Ấn TAB, trên bản đồ sẽ có ký hiệu nhấp nháy.", ["eventId"] = -1},
    {["type"] = 2, ["name"] = "Học võ công Đào Hoa Đảo", ["x"] = 207, ["y"] = 66, ["tip"] = "Yến Phản", ["desc"] = "Yến Phản truyền dạy tâm pháp, bí tịch và yếu quyết của bổn phái. Ấn TAB để thấy ký hiệu nhấp nháy.", ["eventId"] = -1},
    {["type"] = 2, ["name"] = "Học khinh công Đào Hoa Đảo", ["x"] = 207, ["y"] = 78, ["tip"] = "Tạ Xuân Hàn", ["desc"] = "Tạ Xuân Hàn dạy khinh công độc môn. Ấn TAB để thấy ký hiệu nhấp nháy.", ["eventId"] = -1},
    {["type"] = 2, ["name"] = "Học nghề Cách Vật Chi Thuật", ["x"] = 105, ["y"] = 73, ["tip"] = "Túc Hồi Chi", ["desc"] = "Túc Hồi Chi dạy Cách Vật Chi Thuật và công thức chế tạo. Ấn TAB để thấy ký hiệu nhấp nháy.", ["eventId"] = -1},
    {["type"] = 2, ["name"] = "Học nghề Thông Cảm", ["x"] = 108, ["y"] = 71, ["tip"] = "Lâm Hạ Phong", ["desc"] = "Lâm Hạ Phong dạy Thông Cảm. Ấn TAB để thấy ký hiệu nhấp nháy.", ["eventId"] = -1},
    {["type"] = 2, ["name"] = "Mua toạ kỵ Đào Hoa Đảo", ["x"] = 103, ["y"] = 138, ["tip"] = "Hoàng Trí Tri", ["desc"] = "Hoàng Trí Tri bán toạ kỵ môn phái ba cấp 40/60/80. Ấn TAB để thấy ký hiệu nhấp nháy.", ["eventId"] = -1},
    {["type"] = 2, ["name"] = "Nhiệm vụ sư môn", ["x"] = 160, ["y"] = 72, ["tip"] = "Tiêu Thanh Yết", ["desc"] = "Tiêu Thanh Yết phụ trách nhiệm vụ sư môn (hiện chưa mở tại máy chủ này). Ấn TAB để thấy ký hiệu nhấp nháy.", ["eventId"] = -1},
    {["type"] = 2, ["name"] = "Về Đại Lý", ["x"] = 256, ["y"] = 169, ["tip"] = "Đào Ân", ["desc"] = "Đào Ân có thể đưa ngươi trở về Đại Lý. Ấn TAB để thấy ký hiệu nhấp nháy.", ["eventId"] = -1},
}

function cy4_taohuadao_sign:OnEnumerate(caller, selfId, targetId, arg, index)
    for i, signpost in ipairs(self.g_Signpost) do
        caller:AddNumTextWithTarget(self.script_id, signpost["name"], -1, i)
    end
end

function cy4_taohuadao_sign:OnDefaultEvent(selfId, targetId, arg, index)
    local signpost = self.g_Signpost[index]
    if not signpost then return end
    self:CallScriptFunction(888888, "AskTheWay", selfId, self:get_scene_id(), signpost["x"], signpost["y"], signpost["tip"])
    self:BeginEvent(self.script_id)
    self:AddText(signpost["desc"])
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return cy4_taohuadao_sign
