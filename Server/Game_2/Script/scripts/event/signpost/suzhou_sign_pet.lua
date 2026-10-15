local class = require "class"
local define = require "define"
local script_base = require "script_base"
local suzhou_sign_pet = class("suzhou_sign_pet", script_base)
suzhou_sign_pet.script_id = 500025
suzhou_sign_pet.g_Signpost = {
    { ["type"] = 2, ["name"] = "虫鸟坊坊主", ["x"] = 87, ["y"] = 142, ["tip"] = "云霏霏",
        ["desc"] = "Phường chủ Trùng Điểu Phường Vân Phi Phi (87,142) ở Trùng Điểu Phường phía bắc trong Tây Môn. Ấn phím TAB, trên bản đồ sẽ có ký hiệu nhấp nháy.",
        ["eventId"] = -1 }
}
function suzhou_sign_pet:OnEnumerate(caller, selfId, targetId, arg, index)
    for i, signpost in pairs(self.g_Signpost) do
        caller:AddNumTextWithTarget(self.script_id, signpost["name"], -1, i)
    end
end

function suzhou_sign_pet:OnDefaultEvent(selfId, targetId, arg, index)
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

return suzhou_sign_pet
