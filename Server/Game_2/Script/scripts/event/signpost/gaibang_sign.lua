local class = require "class"
local define = require "define"
local script_base = require "script_base"
local gaibang_sign = class("gaibang_sign", script_base)
gaibang_sign.script_id = 500063
gaibang_sign.g_Signpost = {
    { ["type"] = 2, ["name"] = "Gia nhập Cái Bang", ["x"] = 91, ["y"] = 98, ["tip"] = "陈孤雁",
        ["desc"] = "#{JRMP_090113_09}", ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Học Cái Bang Chiến đấu Kỹ năng", ["x"] = 94, ["y"] = 99, ["tip"] = "Học Cái Bang Chiến đấu Kỹ năng",
        ["desc"] = "Hề Tam Kỳ Trưởng Lão có thể dạy cho ngươi Kỹ năng của bổn bang, người ở ngoài cửa tụ nghĩa đường. Ấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Học Cái Bang Kỹ năng sống", ["x"] = 114, ["y"] = 91, ["tip"] = "Học Cái Bang Kỹ năng sống",
        ["desc"] = "Ngô Trường Phong Trưởng Lão ngoài cửa Trung Liệt Đường có thể dạy cho ngươi Kỹ năng Nấu Rượu. Ấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Học Cái Bang Kỹ năng hổ trợ", ["x"] = 131, ["y"] = 83, ["tip"] = "Học Cái Bang Kỹ năng hổ trợ",
        ["desc"] = "Đến Đào Viên đi, Đô Chủ ở ngay đó, ngươi hỏi thử xem người có dạy ngươi Liên Hoa Lạc không. Ấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Học kỹ năng kỵ thừa phái Cái Bang", ["x"] = 38, ["y"] = 89, ["tip"] = "Học tập Kỹ năng cưỡi",
        ["desc"] = "Tưởng Quang Đình ở Tây Sương Phòng có thể dạy ngươi cách cưỡi sói. Nhấn phím TAB, trên bản đồ sẽ có ký hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Mua Tọa kỵ", ["x"] = 54, ["y"] = 86, ["tip"] = "Mua Tọa kỵ",
        ["desc"] = "Mua Tọa kỵ tìm Lý Nhật Việt ở Tây Sương Phòng. Ấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Cái Bang nhiệm vụ", ["x"] = 92, ["y"] = 70, ["tip"] = "Cái Bang nhiệm vụ",
        ["desc"] = "Hồng Thông ở phía sau Tụ Nghĩa Đường, hắn đang tìm người hỗ trợ. Nhấn phím TAB, trên bản đồ sẽ có ký hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "丐帮传送人", ["x"] = 93, ["y"] = 118, ["tip"] = "丐帮传送人",
        ["desc"] = "Trương Toàn Tường ngoài Tụ Nghĩa Đường có thể đưa ngươi đến Lạc Dương, Đại Lý, Tô Châu hoặc Môn phái Khác. Ấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Hầm rượu", ["x"] = 41, ["y"] = 144, ["tip"] = "Hầm rượu",
        ["desc"] = "Hầm rượu có kẻ gây rối, hãy đến Tiểu Đào Viên tìm Phật Ấn dẫn ngươi đi đuổi chúng. Nhấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Học Cái Bang khinh công", ["x"] = 112, ["y"] = 90, ["tip"] = "丐帮轻功传授人",
        ["desc"] = "Ngô Tuyết Kiều ở trước cửa Trung Liệt Đường có thể dạy cho ngươi khinh công của bổn bang. Ấn phím TAB, trên bản đồ sẽ có ký hiệu nhấp nháy.",
        ["eventId"] = -1 }
}
function gaibang_sign:OnEnumerate(caller, selfId, targetId, arg, index)
    for i, signpost in pairs(self.g_Signpost) do
        caller:AddNumTextWithTarget(self.script_id, signpost["name"], -1, i)
    end
end

function gaibang_sign:OnDefaultEvent(selfId, targetId,arg,index)
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

return gaibang_sign
