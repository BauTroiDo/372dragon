local class = require "class"
local define = require "define"
local script_base = require "script_base"
local dali_sign_mission = class("dali_sign_mission", script_base)
dali_sign_mission.script_id = 500047
dali_sign_mission.g_Signpost = {
    { ["type"] = 2, ["name"] = "Tào sứ Đại Lý", ["x"] = 54, ["y"] = 192, ["tip"] = "Tào sứ Đại Lý",
        ["desc"] = "Tào sứ Đại Lý Vương Nhược Vũ ở trong cửa tây, đi về nam là thấy. Bấm TAB mở bản đồ, chỗ ghi chữ Tào chính là đó.",
        ["eventId"] = -1 }
}
function dali_sign_mission:OnEnumerate(caller, selfId, targetId, arg, index)
    for i, signpost in pairs(self.g_Signpost) do
        caller:AddNumTextWithTarget(self.script_id, signpost["name"], -1, i)
    end
end

function dali_sign_mission:OnDefaultEvent(selfId, targetId,arg,index)
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

return dali_sign_mission
