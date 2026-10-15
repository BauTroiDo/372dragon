local class = require "class"
local define = require "define"
local script_base = require "script_base"
local luoyang_sign_shanghui = class("luoyang_sign_shanghui", script_base)
luoyang_sign_shanghui.script_id = 500009
luoyang_sign_shanghui.g_Signpost = {
    { ["type"] = 2, ["name"] = "Thương Hội", ["x"] = 230, ["y"] = 156, ["tip"] = "乔复盛",
        ["desc"] = "Tổng Quản Thương Hội Kiều Phục Thịnh (230,156) ở Thương hội phía nam Đại Lộ Phía Đông. Nhấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1 }
}
function luoyang_sign_shanghui:OnEnumerate(caller, selfId, targetId, arg, index)
    for i, signpost in pairs(self.g_Signpost) do
        caller:AddNumTextWithTarget(self.script_id, signpost["name"], -1, i)
    end
end

function luoyang_sign_shanghui:OnDefaultEvent(selfId, targetId, arg, index)
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

return luoyang_sign_shanghui
