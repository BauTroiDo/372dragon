local class = require "class"
local define = require "define"
local script_base = require "script_base"
local dali_sign_abilityteacher = class("dali_sign_abilityteacher", script_base)
dali_sign_abilityteacher.script_id = 500046
dali_sign_abilityteacher.g_Signpost = {
    { ["type"] = 2, ["name"] = "种植大师", ["x"] = 277, ["y"] = 167, ["tip"] = "公孙大叔",
        ["desc"] = "Muốn học trồng trọt thì đến phía trong Đông Môn, gần ruộng đồng của Đại thúc Công Tôn, người ấy luôn ở đó. Ấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy của.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "采矿大师", ["x"] = 214, ["y"] = 117, ["tip"] = "童化铁",
        ["desc"] = "Học khai khoáng phải tìm Đồng Hóa Thiết, hắn ta ở phía sau tiệm binh khí, ấn TAB chỗ nào trên bản đồ ghi chữ Thiết chính là.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "采药大师", ["x"] = 99, ["y"] = 133, ["tip"] = "刘寄奴",
        ["desc"] = "Đại sư hái thuốc Lưu Ký Nô ở trong tiệm thuốc phía bắc Đại Lộ Phía Tây. Ấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy của.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "渔夫", ["x"] = 103, ["y"] = 157, ["tip"] = "穆子陵",
        ["desc"] = "Ngư phu Mục Tử Lăng ở phía nam Đại Lộ Phía Tây, cạnh tửu điếm. Ấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy của.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "工艺大师", ["x"] = 207, ["y"] = 195, ["tip"] = "鲁明月",
        ["desc"] = "Bậc thầy chế tạo Lỗ Minh Nguyệt ở phía sau Tiền Trang. Nhấn phím TAB, trên bản đồ sẽ có ký hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "缝纫大师", ["x"] = 240, ["y"] = 171, ["tip"] = "黄绫波",
        ["desc"] = "Đại sư may vá Hoàng Lăng Ba ở phía nam Đại Lộ Phía Đông. Ấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy của.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "铸造大师", ["x"] = 216, ["y"] = 109, ["tip"] = "过三锤",
        ["desc"] = "Đại sư đúc luyện Quá Tam Chùy ở phía sau Binh Khí Phố. Nhấn phím TAB, trên bản đồ sẽ có ký hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "烹饪大师", ["x"] = 117, ["y"] = 157, ["tip"] = "杜子飞",
        ["desc"] = "Đại sư trù nghệ Đỗ Tử Phi ở phía nam Đại Lộ Phía Tây. Ấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy của.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "制药大师", ["x"] = 99, ["y"] = 128, ["tip"] = "傅当归",
        ["desc"] = "Đại sư luyện dược Phó Đương Quy ở Đại Lộ Phía Tây phía bắc. Nhấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy của.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Trùng Cấu Phối Phương", ["x"] = 141, ["y"] = 133, ["tip"] = "小高",
        ["desc"] = "#GTrùng Cấu Phối Phương:#W Vì một vài nguyên nhân bất khả kháng khiến người chơi đã học được các loại phối phương #GChế Tác Nguyên Liệu#W, phối phương Bánh Bao, phối phương Nguyên liệu nấu ăn Sơ/Trung/Cao cấp, phối phương Tấc Gang Bên Trời#W bị mất, có thể đến #GTô Châu#W của #GTiểu Cao(96,127)#W mua lại #GTrùng Cấu Phối Phương#W, giá bán #Gthống nhất là 1 bạc#W.",
        ["eventId"] = -1 }
    , { ["type"] = 2, ["name"] = "Chế Tác Nguyên Liệu tửu quán", ["x"] = -1, ["y"] = -1, ["tip"] = "",
    ["desc"] = "#{CLJG_20071204}", ["eventId"] = -1 }
}
function dali_sign_abilityteacher:OnEnumerate(caller, selfId, targetId, arg, index)
    for i, signpost in pairs(self.g_Signpost) do
        caller:AddNumTextWithTarget(self.script_id, signpost["name"], -1, i)
    end
end

function dali_sign_abilityteacher:OnDefaultEvent(selfId, targetId,arg,index)
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

return dali_sign_abilityteacher
