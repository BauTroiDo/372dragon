local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshaolin_texiaonpc = class("oshaolin_texiaonpc", script_base)
oshaolin_texiaonpc.script_id = 801001
oshaolin_texiaonpc.g_DemoSkills = {}

oshaolin_texiaonpc.g_DemoSkills[752] = "Bát Nhã Chưởng"
oshaolin_texiaonpc.g_DemoSkills[753] = "Kim Cang Phục Ma Quyển"
oshaolin_texiaonpc.g_DemoSkills[754] = "Nhất Phách Lưỡng Tán"
oshaolin_texiaonpc.g_DemoSkills[755] = "Vi Đà Xử"
oshaolin_texiaonpc.g_DemoSkills[756] = "Thiết Bố Sam"
oshaolin_texiaonpc.g_DemoSkills[757] = "Vô Tướng Kiếp Chỉ."
oshaolin_texiaonpc.g_DemoSkills[758] = "La Hán Trận"
oshaolin_texiaonpc.g_DemoSkills[759] = "Sư Tử Hống"
oshaolin_texiaonpc.g_DemoSkills[760] = "Từ Hàng Phổ Độ."
oshaolin_texiaonpc.g_DemoSkills[761] = "Lễ Kính Như Lai"
oshaolin_texiaonpc.g_DemoSkills[762] = "Nhất Vi Độ Giang"
oshaolin_texiaonpc.g_DemoSkills[763] = "Khí quán toàn thân"
oshaolin_texiaonpc.g_DemoSkills[764] = "Ma Ha Vô Lượng"
oshaolin_texiaonpc.g_DemoSkills[765] = "Đa La Diệp Chỉ"
oshaolin_texiaonpc.g_DemoSkills[766] = "Kim Chung Tráo"
oshaolin_texiaonpc.g_eventList = {752, 753, 754, 755, 756, 757, 758, 759, 760, 761, 762, 763, 764, 765, 766}

function oshaolin_texiaonpc:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("    Hoan nghênh quang lâm. Xin chọn Kỹ năng muốn xem.")
    for nIdx, nEvent in pairs(self.g_eventList) do
        self:AddNumText(self.g_DemoSkills[nEvent])
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oshaolin_texiaonpc:OnEventRequest(selfId, targetId, arg, index)
    self:LuaFnUnitUseSkill(selfId, index, targetId, 1, 0, 0, 0, 0)
end

return oshaolin_texiaonpc
