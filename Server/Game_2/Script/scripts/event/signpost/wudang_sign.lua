local class = require "class"
local define = require "define"
local script_base = require "script_base"
local wudang_sign = class("wudang_sign", script_base)
wudang_sign.script_id = 500064
wudang_sign.g_Signpost = {
    { ["type"] = 2, ["name"] = "Bái kiến chưởng môn", ["x"] = 77, ["y"] = 85, ["tip"] = "Chưởng môn",
        ["desc"] = "Chưởng môn đang ở Tử Tiêu Đại Điện, ngươi muốn đi bái kiến người sao? Nhấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1 }
    , { ["type"] = 2, ["name"] = "Gia nhập Võ Đang", ["x"] = 77, ["y"] = 85, ["tip"] = "张玄素",
    ["desc"] = "#{JRMP_090113_01}", ["eventId"] = -1 }
,
    { ["type"] = 2, ["name"] = "Học tập Kỹ năng Chiến đấu Võ Đang", ["x"] = 82, ["y"] = 84, ["tip"] = "Học tập Kỹ năng Chiến đấu Võ Đang",
        ["desc"] = "Tại Tử Tiêu Đại Điện, Du Viễn Sơn có thể chỉ dạy Kỹ năng Võ Đang phái cho ngươi. Hãy nhấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Học tập Kỹ năng sống Võ Đang", ["x"] = 44, ["y"] = 56, ["tip"] = "Học tập Kỹ năng sống Võ Đang",
        ["desc"] = "Hạc Vân đạo nhân có thể dạy ngươi luyện đan, thông qua Thiên Giai là có thể tìm được y. Hãy nhấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Học tập Kỹ năng hổ trợ Võ Đang", ["x"] = 41, ["y"] = 58, ["tip"] = "Học tập Kỹ năng hổ trợ Võ Đang",
        ["desc"] = "Ninh Hư Tản Nhân có thể dạy ngươi đạo pháp, thông qua Thiên Giai là có thể tìm được y. Hãy nhấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Học Kỹ năng Kỵ Thừa phái Võ Đang", ["x"] = 102, ["y"] = 112, ["tip"] = "Học tập Kỹ năng cưỡi",
        ["desc"] = "Trương Quân Tiện ở Nham Nghĩa Điện sẽ dạy ngươi bản lĩnh cưỡi hạc. Nhấn phím TAB, trên bản đồ sẽ có ký hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Mua Tọa kỵ", ["x"] = 101, ["y"] = 115, ["tip"] = "Mua Tọa kỵ",
        ["desc"] = "Ngươi có thể đến chỗ Trương Quân Mộ để mua Tiên Hạc Tọa Kỵ, hắn ở ngay Nham Nghĩa Điện. Nhấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Nhiệm vụ Võ Đang", ["x"] = 78, ["y"] = 92, ["tip"] = "Nhiệm vụ Võ Đang",
        ["desc"] = "Nếu ngươi muốn làm chút việc cho bổn phái, hãy đến trước Tử Tiêu Đại Điện tìm Trương Trung Hành. Hãy nhấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Võ Đang Người truyền tống", ["x"] = 101, ["y"] = 136, ["tip"] = "Võ Đang Người truyền tống",
        ["desc"] = "Mạc Thái Xung ở phía bắc Kiếm Hà Kiều có thể đưa ngươi đến Lạc Dương, Đại Lý, Tô Châu hoặc các Môn phái Khác. Ấn phím TAB, trên bản đồ sẽ có ký hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Linh Tính Phong", ["x"] = 58, ["y"] = 73, ["tip"] = "Linh Tính Phong",
        ["desc"] = "Đại sư huynh Lâm Linh Tố quản lý việc tiến vào Linh Tính Phong, hắn ở giữa Thiên Giai và Tử Tiêu Đại Điện. Ấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Học tập khinh công Võ Đang", ["x"] = 65, ["y"] = 109, ["tip"] = "Người truyền thụ khinh công Võ Đang",
        ["desc"] = "Tĩnh Sơ Tán Nhân ở Tam Thanh Điện có thể truyền thụ khinh công bổn phái cho ngươi. Nhấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1 }
}
function wudang_sign:OnEnumerate(caller, selfId, targetId, arg, index)
    for i, signpost in pairs(self.g_Signpost) do
        caller:AddNumTextWithTarget(self.script_id, signpost["name"], -1, i)
    end
end

function wudang_sign:OnDefaultEvent(selfId, targetId, arg, index)
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

return wudang_sign
