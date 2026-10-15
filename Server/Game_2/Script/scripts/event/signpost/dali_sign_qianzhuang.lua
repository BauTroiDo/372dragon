local class = require "class"
local define = require "define"
local script_base = require "script_base"
local dali_sign_qianzhuang = class("dali_sign_qianzhuang", script_base)
dali_sign_qianzhuang.script_id = 500044
dali_sign_qianzhuang.g_Signpost = {
    { ["type"] = 2, ["name"] = "Tiền Trang", ["x"] = 211, ["y"] = 172, ["tip"] = "王颖",
        ["desc"] = "Tiền Trang của Vương lão bản ở phía nam Đại Lộ Phía Đông, cách Ngũ Hoa Đàn không xa, nhấn phím TAB, trên bản đồ sẽ có ký hiệu nhấp nháy. Tiểu nhân tiền trang có thể giúp ngươi lưu trữ vật phẩm và tiền tệ.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "tiệm cầm đồ", ["x"] = 81, ["y"] = 162, ["tip"] = "韩永安",
        ["desc"] = "Lão bản tiệm cầm đồ Hàn Vĩnh An ở phía nam Đại Lộ Phía Tây. Nhấn phím TAB, trên bản đồ sẽ có nhãn hiệu nhấp nháy của.",
        ["eventId"] = -1 }
}
function dali_sign_qianzhuang:OnEnumerate(caller, selfId, targetId, arg, index)
    for i, signpost in pairs(self.g_Signpost) do
        caller:AddNumTextWithTarget(self.script_id, signpost["name"], -1, i)
    end
end

function dali_sign_qianzhuang:OnDefaultEvent(selfId, targetId,arg,index)
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

return dali_sign_qianzhuang
