local class = require "class"
local define = require "define"
local script_base = require "script_base"
local owudang_texiaonpc = class("owudang_texiaonpc", script_base)
owudang_texiaonpc.script_id = 801004
owudang_texiaonpc.g_DemoSkills = {}

owudang_texiaonpc.g_DemoSkills[800] = "Ngọc Nữ Xuyên Toa"
owudang_texiaonpc.g_DemoSkills[801] = "Du Nhận Hữu Dư"
owudang_texiaonpc.g_DemoSkills[802] = "Yến Tử Sao Thủy"
owudang_texiaonpc.g_DemoSkills[803] = "Bạch Hạc Lượng Sí"
owudang_texiaonpc.g_DemoSkills[804] = "Hổ Bão Đầu"
owudang_texiaonpc.g_DemoSkills[805] = "Song Phong Quán Nhĩ"
owudang_texiaonpc.g_DemoSkills[806] = "Tam Khuyên Sáo Nguyệt"
owudang_texiaonpc.g_DemoSkills[807] = "Lãm Tước Vĩ"
owudang_texiaonpc.g_DemoSkills[808] = "Tương Nhu Dĩ Mạt"
owudang_texiaonpc.g_DemoSkills[809] = "Thê Vân Túng"
owudang_texiaonpc.g_DemoSkills[810] = "Dã Mã Phân Tông"
owudang_texiaonpc.g_DemoSkills[811] = "Như Phong Tợ Bế"
owudang_texiaonpc.g_DemoSkills[812] = "Hàn Mai Ánh Tuyết"
owudang_texiaonpc.g_DemoSkills[813] = "Đại Khôi Tinh"
owudang_texiaonpc.g_DemoSkills[814] = "Chân võ Thất Tiệt Trận"
owudang_texiaonpc.g_eventList = {800, 801, 802, 803, 804, 805, 806, 807, 808, 809, 810, 811, 812, 813, 814}

function owudang_texiaonpc:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("    Hoan nghênh quang lâm. Xin chọn Kỹ năng muốn xem.")
    for nIdx, nEvent in pairs(self.g_eventList) do
        self:AddNumText(self.g_DemoSkills[nEvent])
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function owudang_texiaonpc:OnEventRequest(selfId, targetId, arg, index)
    self:LuaFnUnitUseSkill(selfId, index, targetId, 1, 0, 0, 0, 0)
end

return owudang_texiaonpc
