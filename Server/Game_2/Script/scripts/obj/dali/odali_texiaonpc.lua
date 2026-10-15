local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odali_texiaonpc = class("odali_texiaonpc", script_base)
odali_texiaonpc.script_id = 801007
odali_texiaonpc.g_DemoSkills = {}

odali_texiaonpc.g_DemoSkills[850] = "Khoái Hoạt Tam"
odali_texiaonpc.g_DemoSkills[851] = "Hồi Phong Phất Liễu"
odali_texiaonpc.g_DemoSkills[852] = "Hữu Thường Vô Thường"
odali_texiaonpc.g_DemoSkills[853] = "Vô Chúng Sinh Tướng"
odali_texiaonpc.g_DemoSkills[854] = "Phi Khô Phi Vinh"
odali_texiaonpc.g_DemoSkills[855] = "Kim Ngọc Mãn Đường"
odali_texiaonpc.g_DemoSkills[856] = "Lập Địa Thành Phật"
odali_texiaonpc.g_DemoSkills[857] = "Đan Phượng Triều Dương"
odali_texiaonpc.g_DemoSkills[858] = "Bạch Câu Quá Khích"
odali_texiaonpc.g_DemoSkills[859] = "Thiếu Trạch Kiếm"
odali_texiaonpc.g_DemoSkills[860] = "Thương Dương Kiếm"
odali_texiaonpc.g_DemoSkills[861] = "Thiếu Thương Kiếm"
odali_texiaonpc.g_DemoSkills[862] = "Bạch Hồng Quán Nhật"
odali_texiaonpc.g_DemoSkills[863] = "Vi Phục Tư Phỏng"
odali_texiaonpc.g_DemoSkills[864] = "Vạn Quốc Lai Triều"
odali_texiaonpc.g_eventList = {850, 851, 852, 853, 854, 855, 856, 857, 858, 859, 860, 861, 862, 863, 864}

function odali_texiaonpc:OnDefaultEvent(selfId, targetId)
    local AbilityLevel = self:QueryHumanAbilityLevel(selfId, define.ABILITY_ZHONGZHI)
    self:BeginEvent(self.script_id)
    self:AddText("    Hoan nghênh quang lâm. Xin chọn Kỹ năng muốn xem.")
    for nIdx, nEvent in pairs(self.g_eventList) do
        self:AddNumText(self.g_DemoSkills[nEvent], 11, -1)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function odali_texiaonpc:OnEventRequest(selfId, targetId, arg, index)
    self:LuaFnUnitUseSkill(selfId, index, targetId, 1, 0, 0, 0, 0)
end

return odali_texiaonpc
