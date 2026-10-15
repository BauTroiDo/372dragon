local class = require "class"
local define = require "define"
local script_base = require "script_base"
local luoyang_sign_moonoldman = class("luoyang_sign_moonoldman", script_base)
luoyang_sign_moonoldman.script_id = 500007
luoyang_sign_moonoldman.g_Signpost = {
    { ["type"] = 2, ["name"] = "Nguyệt Hạ Lão Nhân", ["x"] = 46, ["y"] = 62, ["tip"] = "月老",
        ["desc"] = "Nguyệt Hạ Lão Nhân ở góc Tây Bắc trong thành Lạc Dương. Tân nhân muốn cử hành hôn lễ hãy đến tìm ông ấy. Ấn phím TAB, trên bản đồ sẽ có ký hiệu nhấp nháy.",
        ["eventId"] = -1 }
}
function luoyang_sign_moonoldman:OnEnumerate(caller, selfId, targetId, arg, index)
    for i, signpost in pairs(self.g_Signpost) do
        caller:AddNumTextWithTarget(self.script_id, signpost["name"], -1, i)
    end
end

function luoyang_sign_moonoldman:OnDefaultEvent(selfId, targetId,arg,index)
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

return luoyang_sign_moonoldman
