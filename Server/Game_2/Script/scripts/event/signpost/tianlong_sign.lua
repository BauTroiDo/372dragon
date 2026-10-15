local class = require "class"
local define = require "define"
local script_base = require "script_base"
local tianlong_sign = class("tianlong_sign", script_base)
tianlong_sign.script_id = 500066
tianlong_sign.g_Signpost = {
    { ["type"] = 2, ["name"] = "Bái kiến Phương Trượng", ["x"] = 96, ["y"] = 66, ["tip"] = "Phương Trượng",
        ["desc"] = "Ngươi muốn bái kiến Bổn Nhân đại sư, y đang ở Đại Hùng Bảo Điện. Ấn phím TAB, trên bản đồ sẽ có tiêu ký nhấp nháy của.",
        ["eventId"] = -1 }
    , { ["type"] = 2, ["name"] = "Gia nhập phái Thiên Long", ["x"] = 96, ["y"] = 66, ["tip"] = "本因",
    ["desc"] = "#{JRMP_090113_06}", ["eventId"] = -1 }
,
    { ["type"] = 2, ["name"] = "Học tập Kỹ năng Chiến đấu phái Thiên Long", ["x"] = 97, ["y"] = 67, ["tip"] = "Học tập Kỹ năng Chiến đấu phái Thiên Long",
        ["desc"] = "Bần đạo ở ngoài cửa Đại Hùng Bảo Điện sẽ dạy ngươi võ công bổn phái. Ấn phím TAB, trên bản đồ sẽ có tiêu ký nhấp nháy của.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Học tập Kỹ năng sống phái Thiên Long", ["x"] = 35, ["y"] = 86, ["tip"] = "Học tập Kỹ năng sống phái Thiên Long",
        ["desc"] = "Không Sơn Thiền Phòng của Bản tướng đại sư có thể dạy ngươi Kỹ năng chế cổ. Ấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy của.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Học tập Kỹ năng hổ trợ Môn phái Thiên Long", ["x"] = 64, ["y"] = 151, ["tip"] = "Học tập Kỹ năng hổ trợ Môn phái Thiên Long",
        ["desc"] = "Thiên Tầm Đài của Bản sâm có thể dạy cho ngươi Kỹ năng Kinh Mạch Bách Quyết. Ấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy của.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Học kỹ năng kỵ thừa của phái Thiên Long", ["x"] = 148, ["y"] = 92, ["tip"] = "Học tập Kỹ năng cưỡi",
        ["desc"] = "Muốn học cưỡi ngựa thì tìm Dương Thanh Ngưu đi, hắn ở chuồng Thiên Mã. Nhấn phím TAB, trên bản đồ sẽ có tiêu chí nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Mua Tọa kỵ", ["x"] = 146, ["y"] = 95, ["tip"] = "Mua Tọa kỵ",
        ["desc"] = "Muốn mua một con ngựa đẹp của? Đến Thiên Mã Ổ tìm Dương Bạch Ngưu. Ấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy của.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Nhiệm vụ Môn phái Thiên Long", ["x"] = 95, ["y"] = 88, ["tip"] = "Nhiệm vụ Môn phái Thiên Long",
        ["desc"] = "Bần phàm đại sư đang Yêu cầu đệ tử Bản phái giúp đỡ, người ở phía nam Đại Hùng Bảo Điện. Ấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy của.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Người truyền tống Môn phái Thiên Long", ["x"] = 99, ["y"] = 120, ["tip"] = "Người truyền tống Môn phái Thiên Long",
        ["desc"] = "Phá Sân ở Sơn Môn có thể đưa ngươi đến Lạc Dương, Đại Lý, Tô Châu hoặc Khác Môn phái. Ấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy của.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Đáy Tháp", ["x"] = 35, ["y"] = 86, ["tip"] = "Đáy Tháp",
        ["desc"] = "Đệ tử Bản phái mới được phép tiến vào Tháp Đáy, tìm Bản tướng đại sư ở Không Sơn Thiền Phòng. Ấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy của.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Học tập khinh công phái Thiên Long", ["x"] = 35, ["y"] = 86, ["tip"] = "天龙派轻功传授人",
        ["desc"] = "Diệu Hương Biệt Viện của Thịnh Như Lan có thể dạy cho ngươi khinh công Bản phái. Ấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy của.",
        ["eventId"] = -1 }
}
function tianlong_sign:OnEnumerate(caller, selfId, targetId, arg, index)
    for i, signpost in pairs(self.g_Signpost) do
        caller:AddNumTextWithTarget(self.script_id, signpost["name"], -1, i)
    end
end

function tianlong_sign:OnDefaultEvent(selfId, targetId, arg, index)
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

return tianlong_sign
