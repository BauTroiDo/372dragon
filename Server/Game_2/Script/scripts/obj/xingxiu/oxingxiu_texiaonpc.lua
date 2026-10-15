local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oxingxiu_texiaonpc = class("oxingxiu_texiaonpc", script_base)
oxingxiu_texiaonpc.script_id = 801006
oxingxiu_texiaonpc.g_DemoSkills = {}

oxingxiu_texiaonpc.g_DemoSkills[834] = "Liên Châu Hủ Thi Độc"
oxingxiu_texiaonpc.g_DemoSkills[835] = "Thất Tinh Thấu Cốt"
oxingxiu_texiaonpc.g_DemoSkills[836] = "Uống rượu độc giải khát"
oxingxiu_texiaonpc.g_DemoSkills[837] = "Lề mề chậm chạp"
oxingxiu_texiaonpc.g_DemoSkills[838] = "Tiều Đầu Lạn Ngạch"
oxingxiu_texiaonpc.g_DemoSkills[839] = "Di Hoa Tiếp Mộc"
oxingxiu_texiaonpc.g_DemoSkills[840] = "Tiếu Lý Tàng Đao"
oxingxiu_texiaonpc.g_DemoSkills[841] = "Tiếu Khẩu Thường Khai"
oxingxiu_texiaonpc.g_DemoSkills[842] = "Tiếu Ngữ Giải Di"
oxingxiu_texiaonpc.g_DemoSkills[843] = "Hàm Sa Xạ Ảnh"
oxingxiu_texiaonpc.g_DemoSkills[844] = "Tứ Diện Sở Ca"
oxingxiu_texiaonpc.g_DemoSkills[845] = "Đờ đẫn như gà gỗ"
oxingxiu_texiaonpc.g_DemoSkills[846] = "Thủy Yêm Thất Quân"
oxingxiu_texiaonpc.g_DemoSkills[847] = "Hành Thi Tẩu Nhục"
oxingxiu_texiaonpc.g_DemoSkills[848] = "Ác quán mãn doanh"
oxingxiu_texiaonpc.g_eventList = {834, 835, 836, 837, 838, 839, 840, 841, 842, 843, 844, 845, 846, 847, 848}

function oxingxiu_texiaonpc:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("    Hoan nghênh quang lâm. Xin chọn Kỹ năng muốn xem.")
    for nIdx, nEvent in pairs(self.g_eventList) do
        self:AddNumText(self.g_DemoSkills[nEvent])
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oxingxiu_texiaonpc:OnEventRequest(selfId, targetId, arg, index)
    self:LuaFnUnitUseSkill(selfId, index, targetId, 1, 0, 0, 0, 0)
end

return oxingxiu_texiaonpc
