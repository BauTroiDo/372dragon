local class = require "class"
local define = require "define"
local script_base = require "script_base"
local luoyang_sign_bang = class("luoyang_sign_bang", script_base)
luoyang_sign_bang.script_id = 500008
luoyang_sign_bang.g_Signpost = {
    { ["type"] = 2, ["name"] = "Bang phái", ["x"] = 140, ["y"] = 95, ["tip"] = "范纯仁", ["desc"] = "Thượng Thư Bộ BinhPhạm Thuần Nhân quản lý các sự vụ như kiến tạo bang phái.",
        ["eventId"] = -1 }
}
function luoyang_sign_bang:OnEnumerate(caller, selfId, targetId, arg, index)
    for i, signpost in pairs(self.g_Signpost) do
        caller:AddNumTextWithTarget(self.script_id, signpost["name"], -1, i)
    end
end

function luoyang_sign_bang:OnDefaultEvent(selfId, targetId,arg,index)
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

return luoyang_sign_bang
