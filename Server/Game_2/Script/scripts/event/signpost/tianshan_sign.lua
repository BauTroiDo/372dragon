local class = require "class"
local define = require "define"
local script_base = require "script_base"
local tianshan_sign = class("tianshan_sign", script_base)
tianshan_sign.script_id = 500068
tianshan_sign.g_Signpost = {
    { ["type"] = 2, ["name"] = "Bái kiến chưởng môn", ["x"] = 91, ["y"] = 44, ["tip"] = "Chưởng môn",
        ["desc"] = "Chưởng môn nhân không có ở đây, tạm do Mai Kiếm thay mặt xử lý việc thường ngày. Nàng ở Linh Thứu Cung. Ấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy của.",
        ["eventId"] = -1 }
    , { ["type"] = 2, ["name"] = "Gia nhập phái Thiên Sơn", ["x"] = 91, ["y"] = 44, ["tip"] = "梅剑",
    ["desc"] = "#{JRMP_090113_05}", ["eventId"] = -1 }
,
    { ["type"] = 2, ["name"] = "Học tập Kỹ năng Chiến đấu phái Thiên Sơn", ["x"] = 88, ["y"] = 44, ["tip"] = "Học tập Kỹ năng Chiến đấu phái Thiên Sơn",
        ["desc"] = "Lan Kiếm của Linh Thứu Cung có thể dạy cho ngươi võ công của bổn phái. Ấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy của.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Học tập Kỹ năng sống phái Thiên Sơn", ["x"] = 119, ["y"] = 67, ["tip"] = "Học tập Kỹ năng sống phái Thiên Sơn",
        ["desc"] = "Ở phía bắc Toái Băng Hỗ, Bà lão Dư sẽ dạy cho đệ tử bổn phái Huyền Băng Thuật. Ấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy của.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Học tập Kỹ năng hổ trợ phái Thiên Sơn", ["x"] = 123, ["y"] = 67, ["tip"] = "Học tập Kỹ năng hổ trợ phái Thiên Sơn",
        ["desc"] = "Ở phía bắc Toái Băng Hỗ, Thạch tẩu sẽ dạy cho đệ tử bổn phái Thái Băng Thuật. Ấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy của.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Học kỹ năng kỵ thừa của phái Thiên Sơn", ["x"] = 45, ["y"] = 69, ["tip"] = "Học tập Kỹ năng cưỡi",
        ["desc"] = "Ở phía bắc Linh Tuyền, Lô Vũ Đình có thể dạy ngươi bản lĩnh kỵ thừa điêu. Nhấn phím TAB, trên bản đồ sẽ có tiêu chí nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Mua Tọa kỵ", ["x"] = 39, ["y"] = 71, ["tip"] = "Mua Tọa kỵ",
        ["desc"] = "Phía bắc Linh Tuyền, Nhậm Phi Hồng có thể bán cho ngươi Tọa kỵ của bổn phái: Điêu. Ấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy của.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Nhiệm vụ phái Thiên Sơn", ["x"] = 95, ["y"] = 60, ["tip"] = "Nhiệm vụ phái Thiên Sơn",
        ["desc"] = "Phù Mẫn Nghi đang tìm đệ tử bổn phái giúp đỡ, hắn ở ngay dưới tượng Huyền Nữ phía nam Linh Thứu Cung. Nhấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "天山派传送人", ["x"] = 90, ["y"] = 120, ["tip"] = "天山派传送人",
        ["desc"] = "Người truyền tống phái Thiên Sơn Ô Lão Đại có thể đưa ngươi đến Lạc Dương, Đại Lý, Tô Châu hoặc các Môn phái Khác. Ấn phím TAB, trên bản đồ sẽ có các ký hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Chiết Mai Phong", ["x"] = 101, ["y"] = 44, ["tip"] = "Chiết Mai Phong",
        ["desc"] = "Cúc Kiếm là người thủ hộ của Chiết Mai Phong, nàng ở Linh Thứu Cung. Nhấn phím TAB, trên bản đồ sẽ có ký hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Học tập khinh công phái Thiên Sơn", ["x"] = 98, ["y"] = 44, ["tip"] = "天山派轻功传授人",
        ["desc"] = "Để học khinh công Thiên Sơn phái cần tìm Kiếm trúc, nàng ở Linh Thứu Cung. Nhấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1 }
}
function tianshan_sign:OnEnumerate(caller, selfId, targetId, arg, index)
    for i, signpost in pairs(self.g_Signpost) do
        caller:AddNumTextWithTarget(self.script_id, signpost["name"], -1, i)
    end
end

function tianshan_sign:OnDefaultEvent(selfId, targetId, arg, index)
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

return tianshan_sign
