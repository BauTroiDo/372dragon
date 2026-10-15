local class = require "class"
local define = require "define"
local script_base = require "script_base"
local xiaoyao_sign = class("xiaoyao_sign", script_base)
xiaoyao_sign.script_id = 500069
xiaoyao_sign.g_Signpost = {
    { ["type"] = 2, ["name"] = "Bái kiến chưởng môn", ["x"] = 125, ["y"] = 144, ["tip"] = "Chưởng môn",
        ["desc"] = "Đại lý chưởng môn nhân Tô Tinh Hà ở Thính Hương. Nhấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Gia nhập phái Tiêu Dao", ["x"] = 125, ["y"] = 144, ["tip"] = "苏星河",
        ["desc"] = "#{JRMP_090113_03}", ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Học tập Kỹ năng Chiến đấu phái Tiêu Dao", ["x"] = 125, ["y"] = 142, ["tip"] = "Học tập Kỹ năng Chiến đấu phái Tiêu Dao",
        ["desc"] = "Khang Quảng Lăng có thể truyền thụ võ công bổn phái cho ngươi, hắn ở Thính Hương. Nhấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Học tập Kỹ năng sống phái Tiêu Dao", ["x"] = 62, ["y"] = 68, ["tip"] = "Học tập Kỹ năng sống phái Tiêu Dao",
        ["desc"] = "Phùng A Tam ở Đại Quan có thể truyền thụ cho ngươi Kỳ Môn Độn Giáp Thuật. Nhấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Học tập Kỹ năng hổ trợ phái Tiêu Dao", ["x"] = 53, ["y"] = 150, ["tip"] = "Học tập Kỹ năng hổ trợ phái Tiêu Dao",
        ["desc"] = "Học tập Kỹ năng hổ trợ phái Tiêu Dao Yêu cầu đến Tư Ân tìm Thạch Thanh Lộ. Nhấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Học Kỹ năng Kỵ Thừa phái Tiêu Dao", ["x"] = 53, ["y"] = 56, ["tip"] = "Học tập Kỹ năng cưỡi",
        ["desc"] = "Ngô Lĩnh Quân sẽ dạy ngươi kỹ năng kỵ thừa, hắn đang ở nơi thư phòng. Nhấn phím TAB, trên bản đồ sẽ có ký hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Mua Tọa kỵ", ["x"] = 65, ["y"] = 55, ["tip"] = "Mua Tọa kỵ",
        ["desc"] = "Thần Lộc Quản Lý Viên Cẩu Độc xuất thụ Tọa kỵ, hắn ở bên cạnh thư phòng. Ấn phím TAB, trên bản đồ sẽ có tiêu thức nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Nhiệm vụ phái Tiêu Dao", ["x"] = 120, ["y"] = 153, ["tip"] = "Nhiệm vụ phái Tiêu Dao",
        ["desc"] = "Người phát nhiệm vụ phái Tiêu Dao Tần Quan ở Thính Hương. Ấn phím TAB, trên bản đồ sẽ có tiêu thức nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "逍遥派传送人", ["x"] = 48, ["y"] = 124, ["tip"] = "逍遥派传送人",
        ["desc"] = "Lý Khôi Lỗi phía đông Phượng Hoàng Cầm có thể đưa ngươi đến Lạc Dương, Đại Lý, Tô Châu hoặc các Môn phái Khác. Coi chừng ánh mắt của hắn đó. Ấn phím TAB, trên bản đồ sẽ có tiêu thức nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Đáy vực", ["x"] = 62, ["y"] = 68, ["tip"] = "Đáy vực",
        ["desc"] = "Phùng A Tam ở Đại Quan có thể đưa đệ tử bổn phái đến đáy vực Tiêu Dao. Ấn phím TAB, trên bản đồ sẽ có tiêu thức nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Học tập khinh công phái Tiêu Dao", ["x"] = 54, ["y"] = 149, ["tip"] = "逍遥派轻功传授人",
        ["desc"] = "Muốn học khinh công phái Tiêu Dao phải đến chỗ Tư Ân tìm Thạch Cam Lâm. Ấn phím TAB, trên bản đồ sẽ có tiêu thức nhấp nháy.",
        ["eventId"] = -1 }
}
function xiaoyao_sign:OnEnumerate(caller, selfId, targetId, arg, index)
    for i, signpost in pairs(self.g_Signpost) do
        caller:AddNumTextWithTarget(self.script_id, signpost["name"], -1, i)
    end
end

function xiaoyao_sign:OnDefaultEvent(selfId, targetId, arg, index)
    local signpost = self.g_Signpost[index]
    if signpost["type"] == 1 then
        self:BeginEvent(self.script_id)
        self:AddText(signpost["name"] .. "：")
        self:CallScriptFunction(signpost["eventId"], "OnEnumerate", selfId, targetId)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif signpost["type"] == 2 then
        self:CallScriptFunction(888888, "AskTheWay", selfId, signpost["x"], signpost["y"], signpost["tip"])
        self:BeginEvent(self.script_id)
        self:AddText(signpost["desc"])
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
end

return xiaoyao_sign
