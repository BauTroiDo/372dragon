local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oxiaoyao_texiaonpc = class("oxiaoyao_texiaonpc", script_base)
oxiaoyao_texiaonpc.script_id = 801009
oxiaoyao_texiaonpc.g_DemoSkills = {}

oxiaoyao_texiaonpc.g_DemoSkills[881] = "Vọng Dương Hưng Thán"
oxiaoyao_texiaonpc.g_DemoSkills[882] = "Trận Bươm Bướm"
oxiaoyao_texiaonpc.g_DemoSkills[883] = "Bát Môn Kim Tỏa"
oxiaoyao_texiaonpc.g_DemoSkills[884] = "Nhất Tự Trường Xà"
oxiaoyao_texiaonpc.g_DemoSkills[885] = "Thái Ất Tam Tài"
oxiaoyao_texiaonpc.g_DemoSkills[886] = "Bát Trận Đồ"
oxiaoyao_texiaonpc.g_DemoSkills[887] = "Hỏa Nhãn Kim Tinh"
oxiaoyao_texiaonpc.g_DemoSkills[888] = "Chúng Diệu Chi Môn"
oxiaoyao_texiaonpc.g_DemoSkills[889] = "Thần Quang Ly Hợp"
oxiaoyao_texiaonpc.g_DemoSkills[890] = "Lăng Ba Vi Bộ"
oxiaoyao_texiaonpc.g_DemoSkills[891] = "Lữ Sương Băng Chí"
oxiaoyao_texiaonpc.g_DemoSkills[892] = "Dục Cầm Cố Túng"
oxiaoyao_texiaonpc.g_DemoSkills[893] = "Thoái Tị Tam Xá"
oxiaoyao_texiaonpc.g_DemoSkills[894] = "Triêu Tam Mộ Tứ"
oxiaoyao_texiaonpc.g_DemoSkills[895] = "Nhất Hô Bá Ứng"
oxiaoyao_texiaonpc.g_eventList = {881, 882, 883, 884, 885, 886, 887, 888, 889, 890, 891, 892, 893, 894, 895}

function oxiaoyao_texiaonpc:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("    Hoan nghênh quang lâm. Xin chọn Kỹ năng muốn xem.")
    for nIdx, nEvent in pairs(self.g_eventList) do
        self:AddNumText(self.g_DemoSkills[nEvent])
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oxiaoyao_texiaonpc:OnEventRequest(selfId, targetId, arg, index)
    self:LuaFnUnitUseSkill(selfId, index, targetId, 1, 0, 0, 0, 0)
end

return oxiaoyao_texiaonpc
