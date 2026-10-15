local class = require "class"
local define = require "define"
local script_base = require "script_base"
local omingjiao_texiaonpc = class("omingjiao_texiaonpc", script_base)
omingjiao_texiaonpc.script_id = 801002
omingjiao_texiaonpc.g_DemoSkills = {}

omingjiao_texiaonpc.g_DemoSkills[768] = "Thôi Tâm Liệt Tỳ"
omingjiao_texiaonpc.g_DemoSkills[769] = "Huyền Âm Chí Dương"
omingjiao_texiaonpc.g_DemoSkills[770] = "Thiên Địa Đồng Thọ"
omingjiao_texiaonpc.g_DemoSkills[771] = "Ngũ Tinh Liên Châu"
omingjiao_texiaonpc.g_DemoSkills[772] = "Hỏa Tinh Xung Nhật"
omingjiao_texiaonpc.g_DemoSkills[773] = "Thất Tinh Lạc Trường Không"
omingjiao_texiaonpc.g_DemoSkills[774] = "Thần Hành Bách Biến"
omingjiao_texiaonpc.g_DemoSkills[775] = "Chỉ Lộc Vi Mã"
omingjiao_texiaonpc.g_DemoSkills[776] = "Thâu Lương Hoán Trụ"
omingjiao_texiaonpc.g_DemoSkills[777] = "Thiên Nộ Vu Nhân"
omingjiao_texiaonpc.g_DemoSkills[778] = "Nộ Phát Xung Quan"
omingjiao_texiaonpc.g_DemoSkills[779] = "Lôi Đình Chi Nộ"
omingjiao_texiaonpc.g_DemoSkills[780] = "Nghĩa phẫn điền ưng"
omingjiao_texiaonpc.g_DemoSkills[781] = "Hậu tích bạc phát"
omingjiao_texiaonpc.g_DemoSkills[782] = "Kim Thạch Câu Phần"
omingjiao_texiaonpc.g_eventList = {768, 769, 770, 771, 772, 773, 774, 775, 776, 777, 778, 779, 780, 781, 782}

function omingjiao_texiaonpc:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("    Hoan nghênh quang lâm. Xin chọn Kỹ năng muốn xem.")
    for nIdx, nEvent in pairs(self.g_eventList) do
        self:AddNumText(self.g_DemoSkills[nEvent])
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function omingjiao_texiaonpc:OnEventRequest(selfId, targetId, arg, index)
    self:LuaFnUnitUseSkill(selfId, index, targetId, 1, 0, 0, 0, 0)
end

return omingjiao_texiaonpc
