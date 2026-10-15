local class = require "class"
local define = require "define"
local script_base = require "script_base"
local xingsu_sign = class("xingsu_sign", script_base)
xingsu_sign.script_id = 500067
xingsu_sign.g_Signpost = {
    { ["type"] = 2, ["name"] = "Bái kiến chưởng môn", ["x"] = 142, ["y"] = 55, ["tip"] = "Chưởng môn",
        ["desc"] = "Tinh Túc Lão Tiên, đức xứng trời đất, uy chấn hoàn vũ, xưa nay vô so. Lão Tiên ở Thần Mộc Đỉnh, đi bái kiến người phải cẩn thận, cẩn thận người chế thành dược lâu tử. Ấn phím TAB, trên bản đồ sẽ có tiêu thức nhấp nháy.",
        ["eventId"] = -1 }
    , { ["type"] = 2, ["name"] = "Gia nhập phái Tinh Túc", ["x"] = 95, ["y"] = 75, ["tip"] = "韩世忠",
    ["desc"] = "#{JRMP_090113_02}", ["eventId"] = -1 }
,
    { ["type"] = 2, ["name"] = "Học tập Kỹ năng Chiến đấu phái Tinh Túc", ["x"] = 87, ["y"] = 70, ["tip"] = "Học tập Kỹ năng Chiến đấu phái Tinh Túc",
        ["desc"] = "Hãy tìm Thi Sư Toàn ở Vạn Tiên Cung để học võ công Tinh Túc phái. Hãy nhấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Học Kỹ năng sống Tinh Túc phái", ["x"] = 101, ["y"] = 87, ["tip"] = "Học Kỹ năng sống Tinh Túc phái",
        ["desc"] = "Gia nhập Tinh Túc sao có thể không biết chế độc, mau đến Doanh Châu Điện tìm Trác Tinh Tử. Nhấn phím TAB, trên bản đồ sẽ có biểu tượng nhấp nháy chỉ dẫn.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Học Kỹ năng hổ trợ Tinh Túc phái", ["x"] = 101, ["y"] = 89, ["tip"] = "Học Kỹ năng hổ trợ Tinh Túc phái",
        ["desc"] = "Sư Hống Tử ở Dĩnh Châu Điện có thể dạy cho ngươi dẫn trùng thuật. Ấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Học Kỹ năng Kỵ Thừa phái Tinh Túc", ["x"] = 94, ["y"] = 46, ["tip"] = "Học tập Kỹ năng cưỡi",
        ["desc"] = "Phá Quân Tử ở Nhật Nguyệt Cung có thể dạy ngươi cưỡi trâu cày. Yên tâm đi, trên người trâu cày không có độc. Nhấn phím TAB, trên bản đồ sẽ có ký hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Mua Tọa kỵ", ["x"] = 97, ["y"] = 46, ["tip"] = "Mua Tọa kỵ",
        ["desc"] = "Nếu muốn có một con li ngưu Tọa kỵ thì đến Nhật Nguyệt Cung tìm Thiên Ưng Tử, đưa ít tiền y sẽ không chịu đâu, cẩn thận y cho ngươi một con trâu có độc đó. Hãy nhấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Nhiệm vụ Tinh Túc phái", ["x"] = 96, ["y"] = 92, ["tip"] = "Nhiệm vụ Tinh Túc phái",
        ["desc"] = "Người phát nhiệm vụ ở giữa Phương Trượng Điện và Doanh Châu Điện, hắn đang yêu cầu người giúp đỡ đó. Ấn phím TAB, trên bản đồ sẽ có ký hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "星宿派传送人", ["x"] = 99, ["y"] = 150, ["tip"] = "星宿派传送人",
        ["desc"] = "Thiên Lang Tử ở ngoài cùng phía nam cổng có thể đưa ngươi đến Lạc Dương, Đại Lý, Tô Châu hoặc các Môn phái Khác. Nhấn phím TAB, trên bản đồ sẽ có các ký hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Ngũ Thần Động", ["x"] = 128, ["y"] = 78, ["tip"] = "Ngũ Thần Động",
        ["desc"] = "Hồng Ngọc sư muội ở Bồng Lai Điện, Hồng Ngọc sư muội ở Bồng Lai Điện... Hồng Ngọc sư muội... Hì hì, hì hì... Ồ, đúng rồi, đến Ngũ Thần Động tìm nàng ấy là được. Hãy nhấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Học tập khinh công phái Tinh Túc", ["x"] = 90, ["y"] = 88, ["tip"] = "星宿派轻功传授人",
        ["desc"] = "Xuất Trần Tử ở trước cửa Phương Trượng có thể dạy cho ngươi khinh công bổn phái. Ấn phím TAB, trên bản đồ sẽ có tiêu thức nhấp nháy.",
        ["eventId"] = -1 }
}
function xingsu_sign:OnEnumerate(caller, selfId, targetId, arg, index)
    for i, signpost in pairs(self.g_Signpost) do
        caller:AddNumTextWithTarget(self.script_id, signpost["name"], -1, i)
    end
end

function xingsu_sign:OnDefaultEvent(selfId, targetId, arg, index)
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

return xingsu_sign
