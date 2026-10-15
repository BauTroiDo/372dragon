local class = require "class"
local define = require "define"
local script_base = require "script_base"
local luoyang_sign_pkmanage = class("luoyang_sign_pkmanage", script_base)
luoyang_sign_pkmanage.script_id = 500011
luoyang_sign_pkmanage.g_Signpost = {
    { ["type"] = 2, ["name"] = "Lạc Dương Giáo Trường", ["x"] = 89, ["y"] = 173, ["tip"] = "Lạc Dương Giáo Trường",
        ["desc"] = "Nếu muốn so tài võ nghệ, hãy đến Lạc Dương giáo trường. Nhấp chuột phải vào đối thủ và chọn khiêu chiến.", ["eventId"] = -1 }
}
function luoyang_sign_pkmanage:OnEnumerate(caller, selfId, targetId, arg, index)
    for i, signpost in pairs(self.g_Signpost) do
        caller:AddNumTextWithTarget(self.script_id, signpost["name"], -1, i)
    end
end

function luoyang_sign_pkmanage:OnDefaultEvent(selfId, targetId,arg,index)
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

return luoyang_sign_pkmanage
