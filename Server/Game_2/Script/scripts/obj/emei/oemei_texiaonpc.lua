local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oemei_texiaonpc = class("oemei_texiaonpc", script_base)
oemei_texiaonpc.script_id = 801005
oemei_texiaonpc.g_DemoSkills = {}

oemei_texiaonpc.g_DemoSkills[816] = "Khuyên Bội Quy Hồn"
oemei_texiaonpc.g_DemoSkills[818] = "Cửu Âm Thần Trảo"
oemei_texiaonpc.g_DemoSkills[819] = "Thái A Đảo Trì"
oemei_texiaonpc.g_DemoSkills[820] = "Phật Quang Phổ Chiếu"
oemei_texiaonpc.g_DemoSkills[821] = "Kim Châm Đáo Kiếp"
oemei_texiaonpc.g_DemoSkills[822] = "Ninh Tĩnh Chi Vũ"
oemei_texiaonpc.g_DemoSkills[823] = "Xung Hư Dưỡng Khí"
oemei_texiaonpc.g_DemoSkills[824] = "Diệu bút sinh hoa"
oemei_texiaonpc.g_DemoSkills[825] = "Khởi Tử Hồi Sinh"
oemei_texiaonpc.g_DemoSkills[826] = "Kinh Mạch Nghịch Hành"
oemei_texiaonpc.g_DemoSkills[827] = "Di Hồn Đại Pháp"
oemei_texiaonpc.g_DemoSkills[828] = "Dịch Cân Đoán Cốt"
oemei_texiaonpc.g_DemoSkills[829] = "Vạn Nhạc Triều Tông"
oemei_texiaonpc.g_DemoSkills[830] = "Diên Niên Ích Thọ"
oemei_texiaonpc.g_DemoSkills[831] = "Sinh Mệnh Chi Tuyền"
oemei_texiaonpc.g_eventList = {816, 818, 819, 820, 821, 822, 823, 824, 825, 826, 827, 828, 829, 830, 831}

function oemei_texiaonpc:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("    Hoan nghênh quang lâm. Xin chọn Kỹ năng muốn xem.")
    for nIdx, nEvent in pairs(self.g_eventList) do
        self:AddNumText(self.g_DemoSkills[nEvent])
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oemei_texiaonpc:OnEventRequest(selfId, targetId, arg, index)
    self:LuaFnUnitUseSkill(selfId, index, targetId, 1, 0, 0, 0, 0)
end

return oemei_texiaonpc
