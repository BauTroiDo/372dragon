local class = require "class"
local define = require "define"
local script_base = require "script_base"
local luoyang_sign_abilityteacher = class("luoyang_sign_abilityteacher", script_base)
luoyang_sign_abilityteacher.script_id = 500005
luoyang_sign_abilityteacher.g_Signpost = {
    { ["type"] = 2, ["name"] = "种植大师", ["x"] = 219, ["y"] = 262, ["tip"] = "刘亦农",
        ["desc"] = "Ra khỏi cửa nam Lạc Dương, trước khi qua cầu rẽ về hướng đông, sẽ tìm thấy Đại sư trồng trọt Lưu Diệc Nông (219, 262) ở khu ruộng. Ấn phím TAB, trên bản đồ sẽ có ký hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "采矿大师", ["x"] = 212, ["y"] = 151, ["tip"] = "薛铜锤",
        ["desc"] = "Đại sư khai khoáng Tiết Đồng Chùy (212, 151) ở trong tiệm binh khí tại Đông Thị. Nhấn phím TAB, trên bản đồ sẽ có ký hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "采药大师", ["x"] = 120, ["y"] = 169, ["tip"] = "严百草",
        ["desc"] = "Đại sư hái thuốc Nghiêm Bách Thảo (120, 169) ở phía đông đường Tây Thị, nhấn phím TAB, trên bản đồ sẽ có ký hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "渔夫", ["x"] = 207, ["y"] = 184, ["tip"] = "姜渔",
        ["desc"] = "Ngư phu Khương Ngư (207, 184) ở Nam Khẩu Đông Thị, nhấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "工艺大师", ["x"] = 60, ["y"] = 146, ["tip"] = "龙三少",
        ["desc"] = "Bậc thầy chế tạo Long Tam Thiếu (60,146) ở bên trong Tây Môn. Nhấn phím TAB, trên bản đồ sẽ có ký hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "缝纫大师", ["x"] = 193, ["y"] = 172, ["tip"] = "符敏之",
        ["desc"] = "Đại sư may vá Phù Mẫn Chi (193, 172) ở Đông Thị. Ấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "铸造大师", ["x"] = 213, ["y"] = 160, ["tip"] = "王德富",
        ["desc"] = "Đại sư đúc luyện Vương Đức Phú (213, 160) ở trong tiệm binh khí tại Đông Thị. Ấn phím TAB, trên bản đồ sẽ có ký hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "烹饪大师", ["x"] = 134, ["y"] = 152, ["tip"] = "李大嘴",
        ["desc"] = "Đại sư trù nghệ Lý Đại Chủy (134, 152) ở trong tửu điếm nơi giao nhau giữa chợ phía Tây và Đại Lộ Phía Tây. Nhấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "制药大师", ["x"] = 138, ["y"] = 164, ["tip"] = "张明景",
        ["desc"] = "Đại sư luyện dược Trương Minh Cảnh (138, 164) ở trong tiệm thuốc giữa Tây Thị và Nam Đại Nhai. Nhấn phím TAB, trên bản đồ sẽ có ký hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Đại sư Dưỡng Sinh Pháp", ["x"] = 132, ["y"] = 156, ["tip"] = "蔷薇",
        ["desc"] = "Đại sư Dưỡng Sinh Tường Vi (132,156) đang ở trong khách sạn, nơi giao nhau giữa Tây Thị và Đại Lộ Phía Tây. Nhấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "药理学大师", ["x"] = 136, ["y"] = 169, ["tip"] = "白颖明",
        ["desc"] = "Đại sư Dược lý học Bạch Dĩnh Minh (136, 169) ở trong tiệm thuốc giữa chợ phía Tây và đường Nam Đại. Nhấn phím TAB, trên bản đồ sẽ có ký hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Trùng Cấu Phối Phương", ["x"] = 141, ["y"] = 133, ["tip"] = "小高",
        ["desc"] = "#GTrùng Cấu Phối Phương:#W Vì một vài nguyên nhân bất khả kháng khiến người chơi đã học được các loại phối phương #GChế Tác Nguyên Liệu#W, phối phương Bánh Bao, phối phương Nguyên liệu nấu ăn Sơ/Trung/Cao cấp, phối phương Tấc Gang Bên Trời#W bị mất, có thể đến #GTô Châu#W của #GTiểu Cao(96,127)#W mua lại #GTrùng Cấu Phối Phương#W, giá bán #Gthống nhất là 1 bạc#W.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Chế Tác Nguyên Liệu tửu quán", ["x"] = 153, ["y"] = 171, ["tip"] = "冯铸铁",
        ["desc"] = "#{CLJG_20071204}", ["eventId"] = -1 }
}
function luoyang_sign_abilityteacher:OnEnumerate(caller, selfId, targetId, arg, index)
    for i, signpost in pairs(self.g_Signpost) do
        caller:AddNumTextWithTarget(self.script_id, signpost["name"], -1, i)
    end
end

function luoyang_sign_abilityteacher:OnDefaultEvent(selfId, targetId,arg,index)
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

return luoyang_sign_abilityteacher
