local class = require "class"
local define = require "define"
local script_base = require "script_base"
local dali_sign_teacher = class("dali_sign_teacher", script_base)
dali_sign_teacher.script_id = 500049
dali_sign_teacher.g_Signpost = {
    { ["type"] = 2, ["name"] = "Bái sư", ["x"] = 141, ["y"] = 133, ["tip"] = "聂政",
        ["desc"] = "Người giới thiệu bái sư ở ngay Ngũ Hoa Đàn, nhấn phím TAB, trên bản đồ sẽ có biểu thị nhấp nháy của.",
        ["eventId"] = -1 }
}
function dali_sign_teacher:OnEnumerate(caller, selfId, targetId, arg, index)
    for i, signpost in pairs(self.g_Signpost) do
        caller:AddNumTextWithTarget(self.script_id, signpost["name"], -1, i)
    end
end

function dali_sign_teacher:OnDefaultEvent(selfId, targetId,arg,index)
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

return dali_sign_teacher
