local class = require "class"
local define = require "define"
local script_base = require "script_base"
local luoyang_sign_gem = class("luoyang_sign_gem", script_base)
luoyang_sign_gem.script_id = 500012
luoyang_sign_gem.g_Signpost = {
    { ["type"] = 2, ["name"] = "Hợp thành Bảo thạch", ["x"] = 177, ["y"] = 184, ["tip"] = "彭怀玉",
        ["desc"] = "Thợ rèn Bảo thạch Bành Hoài Ngọc (177, 184) ở trong tiệm y phục giữa đường Nam và chợ Đông. Nhấn phím TAB, trên bản đồ sẽ có ký hiệu nhấp nháy.",
        ["eventId"] = -1 }
}
function luoyang_sign_gem:OnEnumerate(caller, selfId, targetId, arg, index)
    for i, signpost in pairs(self.g_Signpost) do
        caller:AddNumTextWithTarget(self.script_id, signpost["name"], -1, i)
    end
end

function luoyang_sign_gem:OnDefaultEvent(selfId, targetId,arg,index)
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

return luoyang_sign_gem
