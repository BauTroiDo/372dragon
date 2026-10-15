local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ogaibang_texiaonpc = class("ogaibang_texiaonpc", script_base)
ogaibang_texiaonpc.script_id = 801003
ogaibang_texiaonpc.g_DemoSkills = {}

ogaibang_texiaonpc.g_DemoSkills[784] = "Bội Nhiên Hữu Vũ"
ogaibang_texiaonpc.g_DemoSkills[785] = "Ngao Du Đông Hải"
ogaibang_texiaonpc.g_DemoSkills[786] = "Kiến Long Tại Điền"
ogaibang_texiaonpc.g_DemoSkills[787] = "Thần Long Bãi Vĩ"
ogaibang_texiaonpc.g_DemoSkills[788] = "Phi Long Tại Thiên"
ogaibang_texiaonpc.g_DemoSkills[789] = "Kháng Long Hữu Hối"
ogaibang_texiaonpc.g_DemoSkills[790] = "Cách Ngạn Quan Hỏa"
ogaibang_texiaonpc.g_DemoSkills[791] = "Lý Đại Đào Cương"
ogaibang_texiaonpc.g_DemoSkills[792] = "Gạt trời qua biển"
ogaibang_texiaonpc.g_DemoSkills[793] = "Thiên Hạ Vô Cẩu"
ogaibang_texiaonpc.g_DemoSkills[794] = "Bát Cẩu Triều Thiên"
ogaibang_texiaonpc.g_DemoSkills[795] = "Đè Bẹp Lưng Chó"
ogaibang_texiaonpc.g_DemoSkills[796] = "Tiên hạ thủ vi cường"
ogaibang_texiaonpc.g_DemoSkills[797] = "Kim Thiền Thoát Xác"
ogaibang_texiaonpc.g_DemoSkills[798] = "Bão Tàn Thủ Khuyết"
ogaibang_texiaonpc.g_eventList = {784, 785, 786, 787, 788, 789, 790, 791, 792, 793, 794, 795, 796, 797, 798}

function ogaibang_texiaonpc:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("    Hoan nghênh quang lâm. Xin chọn Kỹ năng muốn xem.")
    for nIdx, nEvent in pairs(self.g_eventList) do
        self:AddNumText(self.g_DemoSkills[nEvent])
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function ogaibang_texiaonpc:OnEventRequest(selfId, targetId, arg, index)
    self:LuaFnUnitUseSkill(selfId, index, targetId, 1, 0, 0, 0, 0)
end

return ogaibang_texiaonpc
