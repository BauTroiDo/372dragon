local class = require "class"
local define = require "define"
local script_base = require "script_base"
local suzhou_sign_abilityteacher = class("suzhou_sign_abilityteacher", script_base)
suzhou_sign_abilityteacher.script_id = 500023
suzhou_sign_abilityteacher.g_Signpost = {
    { ["type"] = 2, ["name"] = "种植大师", ["x"] = 64, ["y"] = 200, ["tip"] = "林和靖",
        ["desc"] = "Ra khỏi Tây Môn Tô Châu, đi về phía nam, qua một cây cầu nhỏ sẽ thấy Đại sư trồng trọt Lâm Hòa Tĩnh (64, 200). Nhấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy của.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "采矿大师", ["x"] = 259, ["y"] = 132, ["tip"] = "张小河",
        ["desc"] = "Đại sư khai khoáng Trương Tiểu Hà (259, 132) ở trong tiệm binh khí phía đông thành. Nhấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy của.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "采药大师", ["x"] = 106, ["y"] = 109, ["tip"] = "王审芝",
        ["desc"] = "Đại sư hái thuốc Vương Thẩm Chi (106, 109) ở Tây Thị. Nhấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy của.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "钓鱼大师", ["x"] = 238, ["y"] = 77, ["tip"] = "蒋平",
        ["desc"] = "Đại Sư Câu Cá Tưởng Bình (238, 77) ở bến tàu góc đông bắc thành. Nhấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy của.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "工艺大师", ["x"] = 109, ["y"] = 130, ["tip"] = "曾三省",
        ["desc"] = "Bậc thầy chế tạo. Tằng Tam Tỉnh (109, 130) ở Tây Thị. Nhấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy của.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "缝纫大师", ["x"] = 211, ["y"] = 90, ["tip"] = "余化龙",
        ["desc"] = "Đại sư may vá Dư Hóa Long (211,90) ở khu vực gần bến tàu của Bắc Thị. Nhấn phím TAB, trên bản đồ sẽ có ký hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "铸造大师", ["x"] = 251, ["y"] = 151, ["tip"] = "薛烛",
        ["desc"] = "Đại sư đúc luyện Tiết Chúc (251,151) ở trong tiệm binh khí phía đông thành. Nhấn phím TAB, trên bản đồ sẽ có ký hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "烹饪大师", ["x"] = 189, ["y"] = 173, ["tip"] = "智化",
        ["desc"] = "Đại sư trù nghệ Trí Hóa (189,173) ở trước cửa khách sạn phía nam Trạng Nguyên Trường. Nhấn phím TAB, trên bản đồ sẽ có ký hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Trùng Cấu Phối Phương", ["x"] = 96, ["y"] = 127, ["tip"] = "小高",
        ["desc"] = "#GTrùng Cấu Phối Phương:#W Vì một vài nguyên nhân bất khả kháng khiến người chơi đã học được các loại phối phương #GChế Tác Nguyên Liệu#W, phối phương Bánh Bao, phối phương Nguyên liệu nấu ăn Sơ/Trung/Cao cấp, phối phương Tấc Gang Bên Trời#W bị mất, có thể đến #GTô Châu#W của #GTiểu Cao(96,127)#W mua lại #GTrùng Cấu Phối Phương#W, giá bán #Gthống nhất là 1 bạc#W.",
        ["eventId"] = -1 }
    , { ["type"] = 2, ["name"] = "Chế Tác Nguyên Liệu tửu quán", ["x"] = -1, ["y"] = -1, ["tip"] = "",
    ["desc"] = "#{CLJG_20071204}", ["eventId"] = -1 }
}
function suzhou_sign_abilityteacher:OnEnumerate(caller, selfId, targetId, arg, index)
    for i, signpost in pairs(self.g_Signpost) do
        caller:AddNumTextWithTarget(self.script_id, signpost["name"], -1, i)
    end
end

function suzhou_sign_abilityteacher:OnDefaultEvent(selfId, targetId, arg, index)
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

return suzhou_sign_abilityteacher
