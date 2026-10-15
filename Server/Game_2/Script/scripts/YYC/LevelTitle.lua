local class = require "class"
local script_base = require "script_base"
local olevel_title = class("olevel_title", script_base)
olevel_title.script_id = 888001

olevel_title.title_config = {
	{level = 30,  title_id = 1288, name = "Khách Đa Tình Trường Ca Kiếm Ảnh"},
	{level = 40,  title_id = 1286, name = "Vừa gặp đã hẹn trọn đời"},
	{level = 50,  title_id = 1375, name = "Hào hiệp sĩ Thiên Long tranh phong"},
	{level = 60,  title_id = 1374, name = "Cưỡi gió bay qua núi biển"},
	{level = 70,  title_id = 1392, name = "Tử Ảnh Lăng Không"},
	{level = 80,  title_id = 1394, name = "Ngàn quân lui bước, uy hiếp tám cõi"},
	{level = 90,  title_id = 1407, name = "Hào Tình Vạn Trượng Tẩu Thiên Nhai"},
	{level = 100, title_id = 1405, name = "Cửu Châu Ngự Phong Vấn Trường Sinh"},
	{level = 105, title_id = 1385, name = "Lăng Tuyệt Tử Cấm·Đứng Đầu Quần Hùng"},
	{level = 110, title_id = 1386, name = "Ác Chiến Tử Cấm·Khôi Kiệt Võ Lâm"},
	{level = 115, title_id = 1387, name = "Hội Chiến Tử Cấm·Giang Hồ Anh Hào"},
	{level = 119, title_id = 1237, name = "Dũng quán bốn bể · Hào kiệt võ lâm"},
}

function olevel_title:OnDefaultEvent(selfId, targetId)
	self:BeginEvent(self.script_id)
	self:AddText("#cFFFF00Đạt cấp chỉ định nhận được danh hiệu tương ứng, xin chọn:")
	for i, cfg in ipairs(self.title_config) do
		self:AddNumText("#cFF6EB4["..cfg.name.."]#P#cffcc00（"..tostring(cfg.level).."cấp nhận）#P", 2, i)
	end
	self:EndEvent()
	self:DispatchEventList(selfId, targetId)
end

function olevel_title:OnEventRequest(selfId, targetId, arg, index)
	local cfg = self.title_config[index]
	if not cfg then
		return
	end
	local level = self:GetLevel(selfId)
	if level < cfg.level then
		self:notify_tips(selfId, tostring(cfg.level).."cấp mới nhận được danh hiệu này.")
		return
	end
	if self:LuaFnHaveAgname(selfId, cfg.title_id) then
		self:notify_tips(selfId, "Đã nhận.")
		return
	end
	self:LuaFnAddNewAgname(selfId, cfg.title_id, false)
	local human = self:get_scene():get_obj_by_id(selfId)
	if human then
		if human.item_flush then
			human:item_flush()
		end
		if human.send_refresh_attrib then
			human:send_refresh_attrib()
		end
	end
	self:notify_tips(selfId, "Lĩnh danh hiệu thành công!")
end

return olevel_title
