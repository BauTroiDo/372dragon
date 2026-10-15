local class = require "class"
local define = require "define"
local script_base = require "script_base"
local otianshan_texiaonpc = class("otianshan_texiaonpc", script_base)
otianshan_texiaonpc.script_id = 801008
otianshan_texiaonpc.g_DemoSkills = {}

otianshan_texiaonpc.g_DemoSkills[865] = "Lạc Mộc Tiêu Tiêu"
otianshan_texiaonpc.g_DemoSkills[866] = "Vọng Mai Chỉ Khát"
otianshan_texiaonpc.g_DemoSkills[867] = "Dương Quan Tam Điệp"
otianshan_texiaonpc.g_DemoSkills[868] = "Dương Phụng Âm Vi"
otianshan_texiaonpc.g_DemoSkills[869] = "Dương Ca Thiên Quân"
otianshan_texiaonpc.g_DemoSkills[870] = "Dương Xuân Bạch Tuyết"
otianshan_texiaonpc.g_DemoSkills[871] = "Đạp Tuyết Vô Ngân"
otianshan_texiaonpc.g_DemoSkills[872] = "Quy Tức Công"
otianshan_texiaonpc.g_DemoSkills[873] = "Môi Vong Xỉ Hàn"
otianshan_texiaonpc.g_DemoSkills[874] = "Thập Diện Mai Phục"
otianshan_texiaonpc.g_DemoSkills[875] = "Việt Tổ Đại Bào"
otianshan_texiaonpc.g_DemoSkills[876] = "Quy Khứ Lai Hề"
otianshan_texiaonpc.g_DemoSkills[877] = "Bằng Hư Ngự Phong"
otianshan_texiaonpc.g_DemoSkills[878] = "Tĩnh Ảnh Trầm Bích"
otianshan_texiaonpc.g_DemoSkills[879] = "Đại Tượng Vô Hình"
otianshan_texiaonpc.g_eventList = {865, 866, 867, 868, 869, 870, 871, 872, 873, 874, 875, 876, 877, 878, 879}

function otianshan_texiaonpc:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("    Hoan nghênh quang lâm. Xin chọn Kỹ năng muốn xem.")
    for nIdx, nEvent in pairs(self.g_eventList) do
        self:AddNumText(self.g_DemoSkills[nEvent])
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function otianshan_texiaonpc:OnEventRequest(selfId, targetId, arg, index)
    self:LuaFnUnitUseSkill(selfId, index, targetId, 1, 0, 0, 0, 0)
end

return otianshan_texiaonpc
