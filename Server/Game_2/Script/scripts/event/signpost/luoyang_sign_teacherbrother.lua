local class = require "class"
local define = require "define"
local script_base = require "script_base"
local luoyang_sign_teacherbrother = class("luoyang_sign_teacherbrother", script_base)
luoyang_sign_teacherbrother.script_id = 500013
luoyang_sign_teacherbrother.g_Signpost = {
    { ["type"] = 2, ["name"] = "Kết nghĩa", ["x"] = 144, ["y"] = 68, ["tip"] = "陈夫之",
        ["desc"] = "Thượng thư bộ Hộ Trần Phu Chi (144, 68) ở trong Tây Kinh Phủ, nếu muốn kết bái hãy tìm đến hắn. Nhấn phím TAB, trên bản đồ sẽ có ký hiệu nhấp nháy.",
        ["eventId"] = -1 }
}
function luoyang_sign_teacherbrother:OnEnumerate(caller, selfId, targetId, arg, index)
    for i, signpost in pairs(self.g_Signpost) do
        caller:AddNumTextWithTarget(self.script_id, signpost["name"], -1, i)
    end
end

function luoyang_sign_teacherbrother:OnDefaultEvent(selfId, targetId, arg, index)
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

return luoyang_sign_teacherbrother
