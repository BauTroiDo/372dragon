local class = require "class"
local define = require "define"
local script_base = require "script_base"
local dali_sign_buyitem = class("dali_sign_buyitem", script_base)
dali_sign_buyitem.script_id = 500042
dali_sign_buyitem.g_Signpost = {
    { ["type"] = 2, ["name"] = "Tiệm binh khí", ["x"] = 216, ["y"] = 133, ["tip"] = "蒲良",
        ["desc"] = "Tiệm binh khí ở Đại Lộ Phía Đông phía bắc. Nhấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy của.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Tiệm phục sức", ["x"] = 238, ["y"] = 171, ["tip"] = "黄公道",
        ["desc"] = "Tiệm y phục ở Đại Lộ Phía Đông phía nam. Nhấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy của.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Tiệm Trang sức", ["x"] = 248, ["y"] = 171, ["tip"] = "小钗",
        ["desc"] = "Tiệm trang sức ở phía nam Đại Lộ Phía Đông. Nhấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Tiệm Trân thú", ["x"] = 265, ["y"] = 128, ["tip"] = "云飘飘",
        ["desc"] = "Tiệm Trân Thú ở ngay phía bắc Đại Lộ Phía Đông, hướng đông bắc của Dịch trạm. Ấn phím TAB, trên bản đồ sẽ có ký hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Tiệm thuốc", ["x"] = 102, ["y"] = 131, ["tip"] = "卢三七",
        ["desc"] = "Tiệm thuốc nằm ở phía bắc Đại Lộ Phía Tây. Nhấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.", ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Tửu Điếm", ["x"] = 110, ["y"] = 159, ["tip"] = "杜子腾",
        ["desc"] = "Khách điếm ở phía nam Đại Lộ Phía Tây, nơi đó có thể mua được các loại thực phẩm dùng để hồi phục. Nhấn phím TAB, trên bản đồ sẽ có các ký hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Tiệm tạp hóa", ["x"] = 57, ["y"] = 131, ["tip"] = "高升祥",
        ["desc"] = "Tiệm tạp hóa ở bên trong Tây Môn, đi về phía bắc cạnh ruộng đồng. Ấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1 }
}
function dali_sign_buyitem:OnEnumerate(caller, selfId, targetId, arg, index)
    for i, signpost in pairs(self.g_Signpost) do
        caller:AddNumTextWithTarget(self.script_id, signpost["name"], -1, i)
    end
end

function dali_sign_buyitem:OnDefaultEvent(selfId, targetId,arg,index)
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

return dali_sign_buyitem
