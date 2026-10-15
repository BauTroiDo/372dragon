local class = require "class"
local define = require "define"
local script_base = require "script_base"
local suzhou_sign_qianzhuang = class("suzhou_sign_qianzhuang", script_base)
suzhou_sign_qianzhuang.script_id = 500027
suzhou_sign_qianzhuang.g_Signpost = {
    { ["type"] = 2, ["name"] = "王氏钱庄老板", ["x"] = 93, ["y"] = 177, ["tip"] = "王夫人",
        ["desc"] = "Chủ tiệm ngân trang Vương phu nhân (93,177) ở trong tiệm ngân trang phía nam cửa Tây Tô Châu, thủ quỹ của nàng có thể giúp ngươi bảo tồn vật phẩm và tiền bạc. Ấn phím TAB, trên bản đồ sẽ có tiêu ký nhấp nháy của.",
        ["eventId"] = -1 }
}
function suzhou_sign_qianzhuang:OnEnumerate(caller, selfId, targetId, arg, index)
    for i, signpost in pairs(self.g_Signpost) do
        caller:AddNumTextWithTarget(self.script_id, signpost["name"], -1, i)
    end
end

function suzhou_sign_qianzhuang:OnDefaultEvent(selfId, targetId, arg, index)
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

return suzhou_sign_qianzhuang
