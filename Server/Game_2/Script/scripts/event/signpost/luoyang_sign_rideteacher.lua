local class = require "class"
local define = require "define"
local script_base = require "script_base"
local luoyang_sign_rideteacher = class("luoyang_sign_rideteacher", script_base)
luoyang_sign_rideteacher.script_id = 500010
luoyang_sign_rideteacher.g_Signpost = {
    { ["type"] = 2, ["name"] = "Cỡi", ["x"] = 136, ["y"] = 180, ["tip"] = "田骁鸣",
        ["desc"] = "Tại Dịch trạm giữa Tây Thị và Đại Lộ Phía Nam tìm Điền Kiêu Minh, có thể mua tọa kỵ Sơ Cấp.",
        ["eventId"] = -1 }
}
function luoyang_sign_rideteacher:OnEnumerate(caller, selfId, targetId, arg, index)
    for i, signpost in pairs(self.g_Signpost) do
        caller:AddNumTextWithTarget(self.script_id, signpost["name"], -1, i)
    end
end

function luoyang_sign_rideteacher:OnDefaultEvent(selfId, targetId, arg, index)
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

return luoyang_sign_rideteacher
