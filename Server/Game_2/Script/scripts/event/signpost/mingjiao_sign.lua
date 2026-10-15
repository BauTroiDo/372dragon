local class = require "class"
local define = require "define"
local script_base = require "script_base"
local mingjiao_sign = class("mingjiao_sign", script_base)
mingjiao_sign.script_id = 500062
mingjiao_sign.g_Signpost = {
    { ["type"] = 2, ["name"] = "Bái kiến Giáo chủ", ["x"] = 98, ["y"] = 52, ["tip"] = "Giáo chủ",
        ["desc"] = "Xin đừng tùy tiện quấy rầy hắn, nếu như ngươi thật sự muốn gặp hắn thì hãy đến Minh Tôn Đàn đi. Nhấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy đó.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Gia nhập Minh Giáo", ["x"] = 108, ["y"] = 56, ["tip"] = "Gia nhập Minh Giáo",
        ["desc"] = "#{JRMP_090113_08}", ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Học tập Kỹ năng Chiến đấu Minh Giáo", ["x"] = 109, ["y"] = 59, ["tip"] = "Học tập Kỹ năng Chiến đấu Minh Giáo",
        ["desc"] = "Để học Kỹ năng Chiến đấu Minh Giáo, hãy đến Minh Tôn Đàn tìm Bàng Vạn Xuân. Ấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Học tập Kỹ năng sống Minh Giáo", ["x"] = 87, ["y"] = 61, ["tip"] = "Học tập Kỹ năng sống Minh Giáo",
        ["desc"] = "Tại Minh Tôn Đàn, Cừu Đạo Nhân có thể dạy cho ngươi Thánh Hỏa Thuật độc quyền của Minh Giáo. Nhấn phím TAB, trên bản đồ sẽ có biểu tượng nhấp nháy chỉ dẫn.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Học tập Kỹ năng hổ trợ của Minh Giáo", ["x"] = 87, ["y"] = 58, ["tip"] = "Học tập Kỹ năng hổ trợ của Minh Giáo",
        ["desc"] = "Tại Minh Tôn Đàn, Phương Thiên Định có thể dạy cho ngươi bí thuật hái lửa độc nhất của Minh Giáo. Ấn phím TAB, trên bản đồ sẽ có những ký hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Học kỹ năng kỵ thừa của Minh Giáo", ["x"] = 66, ["y"] = 118, ["tip"] = "Học tập Kỹ năng cưỡi",
        ["desc"] = "Ở phía bắc kỳ Bạch Kim, Lệ Thiên Hữu có thể dạy ngươi kỵ thừa sư tử. Nhấn phím TAB, trên bản đồ sẽ có tiêu chí nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Mua Tọa kỵ", ["x"] = 64, ["y"] = 115, ["tip"] = "Mua Tọa kỵ",
        ["desc"] = "Ngươi có thể sử dụng tại phía bắc Bạch Kim Kỳ tìm Đặng Nguyên Giác, hướng hắn mua Sư Tử. Ấn phím TAB, trên bản đồ sẽ có ký hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Nhiệm vụ Minh Giáo", ["x"] = 98, ["y"] = 105, ["tip"] = "Nhiệm vụ Minh Giáo",
        ["desc"] = "Lâm Nham của Thánh Hỏa Đài đang tìm người giúp đỡ làm một vài việc trong giáo. Nhấn phím TAB, trên bản đồ sẽ có những ký hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Người truyền tống Minh Giáo", ["x"] = 102, ["y"] = 167, ["tip"] = "Người truyền tống Minh Giáo",
        ["desc"] = "Phương Thất Phật, sứ giả truyền tống Minh Giáo ở cổng lớn, có thể đưa ngươi đến Lạc Dương, Đại Lý, Tô Châu hoặc các Môn phái Khác. Ấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Quang Minh Động", ["x"] = 89, ["y"] = 56, ["tip"] = "Quang Minh Động",
        ["desc"] = "Quang Minh Tả Sứ Phương Lạp của Minh Tôn Đàn có thể đưa ngươi đi khiêu chiến Quang Minh Động. Ấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Học tập Khinh Công Minh Giáo", ["x"] = 133, ["y"] = 137, ["tip"] = "Minh Giáo Khinh Công Truyền Thụ Nhân",
        ["desc"] = "Muốn học khinh công phải tìm Phương Bách Hoa ở phía bắc Thanh Mộc Kỳ. Nhấn phím TAB, trên bản đồ sẽ có ký hiệu nhấp nháy.",
        ["eventId"] = -1 }
}
function mingjiao_sign:OnEnumerate(caller, selfId, targetId, arg, index)
    for i, signpost in pairs(self.g_Signpost) do
        caller:AddNumTextWithTarget(self.script_id, signpost["name"], -1, i)
    end
end

function mingjiao_sign:OnDefaultEvent(selfId, targetId, arg, index)
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

return mingjiao_sign
