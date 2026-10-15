local class = require "class"
local define = require "define"
local script_base = require "script_base"
local emei_sign = class("emei_sign", script_base)
emei_sign.script_id = 500065
emei_sign.g_Signpost = {
    { ["type"] = 2, ["name"] = "Bái kiến chưởng môn", ["x"] = 96, ["y"] = 73, ["tip"] = "Chưởng môn",
        ["desc"] = "Chưởng môn ở phía bắc Song Kiều, cứ đi thẳng vào trong sẽ thấy người. Nhấn phím TAB, trên bản đồ sẽ có biểu thị nhấp nháy của.",
        ["eventId"] = -1 }
    , { ["type"] = 2, ["name"] = "Gia nhập Nga My", ["x"] = 96, ["y"] = 51, ["tip"] = "李十二娘",
    ["desc"] = "#{JRMP_090113_07}", ["eventId"] = -1 }
,
    { ["type"] = 2, ["name"] = "Học tập Kỹ năng Chiến đấu Nga My", ["x"] = 98, ["y"] = 51, ["tip"] = "Học tập Kỹ năng Chiến đấu Nga My",
        ["desc"] = "Chúng ta đều là hướng Thôi Lục Hoa tỷ tỷ học võ nghệ, nàng ta ở trước Thanh Âm Các. Nhấn phím TAB, trên bản đồ sẽ có biểu thị nhấp nháy của.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Học tập Kỹ năng sống Nga My", ["x"] = 43, ["y"] = 108, ["tip"] = "Học tập Kỹ năng sống Nga My",
        ["desc"] = "Hàn tỷ tỷ sẽ sử dụng Kỹ năng chế phù độc hữu của phái ta, ngươi có thể đến La Phong Tình Vân tìm nàng. Nhấn phím TAB, trên bản đồ sẽ có biểu thị nhấp nháy của.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Học tập Kỹ năng hổ trợ Nga My", ["x"] = 39, ["y"] = 109, ["tip"] = "Học tập Kỹ năng hổ trợ Nga My",
        ["desc"] = "Linh Tâm Thuật là Kỹ năng hổ trợ của chế phù, Hỗ Tam Nương của La Phong Tình Vân sẽ dạy cho ngươi. Nhấn phím TAB, trên bản đồ sẽ có biểu thị nhấp nháy của.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Học kỹ năng kỵ thừa phái Nga My", ["x"] = 141, ["y"] = 51, ["tip"] = "Học tập Kỹ năng cưỡi",
        ["desc"] = "Tiêu Tương Thủy với chiêu Bạch Thủy Thu Phong sẽ dạy ngươi bản lĩnh cưỡi Phượng Hoàng. Nhấn phím TAB, trên bản đồ sẽ có ký hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Mua Tọa kỵ", ["x"] = 145, ["y"] = 53, ["tip"] = "Mua Tọa kỵ",
        ["desc"] = "Nếu muốn mua một con phượng hoàng, hãy đến #YBạch Thủy Thu Phong#W tìm #YTiêu Hương Ngọc#W. Ấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Nhiệm vụ Nga My", ["x"] = 95, ["y"] = 86, ["tip"] = "Nhiệm vụ Nga My",
        ["desc"] = "Tại #YSong Kiều#W, sư huynh #YMạnh Long#W đang tìm người giúp đỡ. Ấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Người truyền tống Nga My", ["x"] = 86, ["y"] = 142, ["tip"] = "Người truyền tống Nga My",
        ["desc"] = "#YPhương Tứ Nương#W ở phía nam #YThính Nguyệt Kiều#W có thể đưa ngươi đến #YLạc Dương#W, #Đại Lý#W, #YTô Châu#W hoặc #KhácMôn phái#W. Ấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Đào Hoa Trận", ["x"] = 96, ["y"] = 73, ["tip"] = "Đào Hoa Trận",
        ["desc"] = "Muốn tiến vào #YĐào Hoa Trận#W, hãy đến phía bắc #YSong Kiều#W tìm chưởng môn. Ấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Học khinh công Nga My", ["x"] = 105, ["y"] = 58, ["tip"] = "Người truyền thụ khinh công Nga My",
        ["desc"] = "Học khinh công bổn phái hãy đến phía bắc #YSong Kiều#W tìm #YTôn Nhị Nương#W. Ấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1 }
}
function emei_sign:OnEnumerate(caller, selfId, targetId, arg, index)
    for i, signpost in pairs(self.g_Signpost) do
        caller:AddNumTextWithTarget(self.script_id, signpost["name"], -1, i)
    end
end

function emei_sign:OnDefaultEvent(selfId, targetId,arg,index)
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

return emei_sign
