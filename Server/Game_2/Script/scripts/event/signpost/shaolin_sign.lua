local class = require "class"
local define = require "define"
local script_base = require "script_base"
local shaolin_sign = class("shaolin_sign", script_base)
shaolin_sign.script_id = 500061
shaolin_sign.g_Signpost = {
    {
        ["type"] = 2,
        ["name"] = "Bái kiến Phương Trượng",
        ["x"] = 38,
        ["y"] = 98,
        ["tip"] = "Phương Trượng",
        ["desc"] = "Ngươi muốn bái kiến Huyền Từ đại sư, người ở ngay tại Đạt Ma Viện. Ấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1
    },
    {
        ["type"] = 2,
        ["name"] = "Gia nhập Thiếu Lâm phái",
        ["x"] = 89,
        ["y"] = 72,
        ["tip"] = "Thiếu Lâm Giám Tự Huyền Tịch",
        ["desc"] = "#{JRMP_090113_04}",
        ["eventId"] = -1
    },
    {
        ["type"] = 2,
        ["name"] = "Học tập Thiếu Lâm Chiến đấu Kỹ năng",
        ["x"] = 91,
        ["y"] = 71,
        ["tip"] = "Học tập Môn phái Chiến đấu Kỹ năng",
        ["desc"] = "Tuyệt kỹ Thiếu Lâm danh dương thiên hạ, Huyền Nan đại sư có thể chỉ dạy cho ngươi, người ở trước cửa Đại Hùng Bảo Điện. Nhấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1
    },
    {
        ["type"] = 2,
        ["name"] = "Học tập Kỹ năng sống Thiếu Lâm",
        ["x"] = 128,
        ["y"] = 86,
        ["tip"] = "Học tập Kỹ năng sống Môn phái",
        ["desc"] = "Đại sư Huyền Độ có thể dạy cho ngươi Kỹ năng Khai Quang độc nhất vô nhị của Thiếu Lâm, người ở Long Thụ Viện. Nhấn phím TAB, trên bản đồ sẽ có ký hiệu nhấp nháy.",
        ["eventId"] = -1
    },
    {
        ["type"] = 2,
        ["name"] = "Học tập Kỹ năng hổ trợ Thiếu Lâm",
        ["x"] = 135,
        ["y"] = 90,
        ["tip"] = "Học tập Kỹ năng hổ trợ Môn phái",
        ["desc"] = "Huyền Minh đại sư có thể dạy cho ngươi Phật Pháp kỹ năng, ngài ở Long Thụ Viện. Nhấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1
    },
    {
        ["type"] = 2,
        ["name"] = "Học kỹ năng kỵ thừa của Thiếu Lâm",
        ["x"] = 57,
        ["y"] = 88,
        ["tip"] = "Học tập Kỹ năng cưỡi",
        ["desc"] = "Đại sư Huyền Diệt có thể dạy ngươi bản lĩnh kỵ thừa hổ, hắn ở phía nam lầu chuông. Nhấn phím TAB, trên bản đồ sẽ có tiêu chí nhấp nháy.",
        ["eventId"] = -1
    },
    {
        ["type"] = 2,
        ["name"] = "Mua Tọa kỵ",
        ["x"] = 60,
        ["y"] = 82,
        ["tip"] = "Mua Tọa kỵ",
        ["desc"] = "Ngươi có thể đến chỗ Huyền Sinh đại sư để mua hổ, người ở phía nam Chung Lâu. Ấn phím TAB, trên bản đồ sẽ có ký hiệu nhấp nháy.",
        ["eventId"] = -1
    },
    {
        ["type"] = 2,
        ["name"] = "Nhiệm vụ phái Thiếu Lâm",
        ["x"] = 96,
        ["y"] = 89,
        ["tip"] = "Nhiệm vụ Môn phái",
        ["desc"] = "Nếu ngươi muốn tìm vài việc để làm thì hãy tìm sư huynh Tuệ Phương đi, huynh ấy ở phía nam Đại Hùng Bảo Điện. Ấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy đó.",
        ["eventId"] = -1
    },
    {
        ["type"] = 2,
        ["name"] = "少林派传送人",
        ["x"] = 932,
        ["y"] = 131,
        ["tip"] = "Môn phái Người truyền tống",
        ["desc"] = "Sư huynh Tuệ Luân trong sơn môn có thể đưa ngươi đến Lạc Dương, Đại Lý, Tô Châu và các Môn phái khác. Nhấn phím TAB, trên bản đồ sẽ có các ký hiệu nhấp nháy.",
        ["eventId"] = -1
    },
    {
        ["type"] = 2,
        ["name"] = "Tháp Lâm",
        ["x"] = 61,
        ["y"] = 62,
        ["tip"] = "Người Thủ Hộ Tháp Lâm",
        ["desc"] = "Muốn thử thách Tháp Lâm hãy đến lầu chuông tìm Huyền Trừng đại sư. Ấn phím TAB, trên bản đồ sẽ có ký hiệu nhấp nháy.",
        ["eventId"] = -1
    },
    {
        ["type"] = 2,
        ["name"] = "Học Thiếu Lâm khinh công",
        ["x"] = 38,
        ["y"] = 102,
        ["tip"] = "Người truyền thụ Thiếu Lâm khinh công",
        ["desc"] = "Hãy đến Đạt Ma Viện tìm Thải Vân muội muội để học khinh công. Nhấn phím TAB, trên bản đồ sẽ có ký hiệu nhấp nháy.",
        ["eventId"] = -1
    }
}

function shaolin_sign:OnEnumerate(caller, selfId, targetId, arg, index)
    for i, signpost in ipairs(self.g_Signpost) do
        caller:AddNumTextWithTarget(self.script_id, signpost["name"], -1, i)
    end
end

function shaolin_sign:OnDefaultEvent(selfId, targetId, arg, index)
    local signpost = self.g_Signpost[index]
    if signpost["type"] == 1 then
        self:BeginEvent(self.script_id)
        self:AddText(signpost["name"] .. "：")
        self:CallScriptFunction(signpost["eventId"], "OnEnumerate", self, selfId, targetId)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    elseif signpost["type"] == 2 then
        self:CallScriptFunction(888888, "AskTheWay", selfId, self:get_scene_id(), signpost["x"], signpost["y"], signpost["tip"])
        self:BeginEvent(self.script_id)
        self:AddText(signpost["desc"])
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
end

return shaolin_sign
