local class = require "class"
local define = require "define"
local script_base = require "script_base"
local luoyang_sign_qianzhuang = class("luoyang_sign_qianzhuang", script_base)
luoyang_sign_qianzhuang.script_id = 500003
luoyang_sign_qianzhuang.g_Signpost = {
    { ["type"] = 2, ["name"] = "tiệm cầm đồ", ["x"] = 95, ["y"] = 152, ["tip"] = "何生财",
        ["desc"] = "Lão bản tiệm cầm đồ Hà Sinh Tài (95, 152) ở trong tiệm cầm đồ phía trong Tây Môn. Ấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Tiền Trang", ["x"] = 80, ["y"] = 152, ["tip"] = "杨熙平",
        ["desc"] = "Chủ tiệm ngân trang Dương Hi Bình (80,152) ở phía trong cửa Tây của ngân trang, tiểu nhị của hắn có thể giúp ngươi cất giữ vật phẩm và kim tệ. Nhấn phím TAB, trên bản đồ sẽ có tiêu chí nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Thương nhân Nguyên bảo", ["x"] = 206, ["y"] = 172, ["tip"] = "金六爷",
        ["desc"] = "Thương nhân Nguyên Bảo Lão Kim (206, 172) ở Đông Thị. Ấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1 }
}
function luoyang_sign_qianzhuang:OnEnumerate(caller, selfId, targetId, arg, index)
    for i, signpost in pairs(self.g_Signpost) do
        caller:AddNumTextWithTarget(self.script_id, signpost["name"], -1, i)
    end
end

function luoyang_sign_qianzhuang:OnDefaultEvent(selfId, targetId,arg,index)
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

return luoyang_sign_qianzhuang
