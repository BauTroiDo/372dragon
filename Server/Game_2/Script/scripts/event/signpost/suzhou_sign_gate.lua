local class = require "class"
local define = require "define"
local script_base = require "script_base"
local suzhou_sign_gate = class("suzhou_sign_gate", script_base)
suzhou_sign_gate.script_id = 500022
suzhou_sign_gate.g_Signpost = {
    { ["type"] = 2, ["name"] = "Cổng Nam", ["x"] = 182, ["y"] = 238, ["tip"] = "Cổng Nam", ["desc"] = "Cửa nam thông đến Tây Hồ.",
        ["eventId"] = -1 }
    , { ["type"] = 2, ["name"] = "Tây Môn", ["x"] = 78, ["y"] = 163, ["tip"] = "Tây Môn", ["desc"] = "Cửa tây thông đến Kính Hồ.",
    ["eventId"] = -1 }
, { ["type"] = 2, ["name"] = "Cửa bắc", ["x"] = 183, ["y"] = 67, ["tip"] = "Cửa bắc", ["desc"] = "Cửa bắc thông đến Thái Hồ.",
    ["eventId"] = -1 }
}
function suzhou_sign_gate:OnEnumerate(caller, selfId, targetId, arg, index)
    for i, signpost in pairs(self.g_Signpost) do
        caller:AddNumTextWithTarget(self.script_id, signpost["name"], -1, i)
    end
end

function suzhou_sign_gate:OnDefaultEvent(selfId, targetId, arg, index)
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

return suzhou_sign_gate
