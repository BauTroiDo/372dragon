local class = require "class"
local define = require "define"
local script_base = require "script_base"
local suzhou_sign_mission = class("suzhou_sign_mission", script_base)
suzhou_sign_mission.script_id = 500024
suzhou_sign_mission.g_Signpost = {
    { ["type"] = 2, ["name"] = "Tào sứ Tô Châu", ["x"] = 234, ["y"] = 78, ["tip"] = "陆士铮",
        ["desc"] = "Tào sứ Tô Châu Lục Sĩ Tranh (234,78) cạnh bến tàu góc đông bắc thành. Bấm TAB, bản đồ sẽ có dấu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "水牢", ["x"] = 243, ["y"] = 215, ["tip"] = "呼延豹",
        ["desc"] = "Hô Diên Báo (243, 215) ở trước phủ nha phía đông nam thành, tìm hắn có thể nhận nhiệm vụ bình phản loạn Thủy Lao. Ấn phím TAB, trên bản đồ sẽ có ký hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Nhiệm vụ Trừng Hung", ["x"] = 127, ["y"] = 133, ["tip"] = "吴玠",
        ["desc"] = "Tô Châu Tổng Bộ Đầu Ngô Giới (127, 133) tại Phố Phong Kiều, hắn đang tìm người giúp hắn trừng trị hung đồ, có khả năng nhận được Tàng Bảo Đồ đó. Nhấn phím TAB, trên bản đồ sẽ có biểu tượng nhấp nháy chỉ dẫn.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Cờ thế", ["x"] = 174, ["y"] = 147, ["tip"] = "张弈国",
        ["desc"] = "Sứ giả sự kiện Cờ Trận Trương Dịch Quốc (174, 147) ở trong Trạng Nguyên Trường. Nhấn phím TAB, trên bản đồ sẽ có ký hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Hoa Sơn Luận Kiếm", ["x"] = 194, ["y"] = 139, ["tip"] = "苏剑岭",
        ["desc"] = "Sứ Giả Hoa Sơn Luận Kiếm Tô Kiếm Lĩnh (194, 139) đang ở trong Trạng Nguyên Tràng. Nhấn phím TAB, trên bản đồ sẽ có ký hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Liên Hoàn Phó Bản", ["x"] = 62, ["y"] = 162, ["tip"] = "钱宏宇",
        ["desc"] = "Hiệu úy Tô Châu Tiền Hoành Vũ (62,162) ở ngoài cửa Tây thành Tô Châu, có thể tìm y lĩnh nhiệm vụ Liên Hoàn Phó Bản. Ấn phím TAB, trên bản đồ sẽ có tiêu ký nhấp nháy của.",
        ["eventId"] = -1 }
}
function suzhou_sign_mission:OnEnumerate(caller, selfId, targetId, arg, index)
    for i, signpost in pairs(self.g_Signpost) do
        caller:AddNumTextWithTarget(self.script_id, signpost["name"], -1, i)
    end
end

function suzhou_sign_mission:OnDefaultEvent(selfId, targetId, arg, index)
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

return suzhou_sign_mission
