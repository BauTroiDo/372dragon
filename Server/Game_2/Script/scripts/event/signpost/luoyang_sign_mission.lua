local class = require "class"
local define = require "define"
local script_base = require "script_base"
local luoyang_sign_mission = class("luoyang_sign_mission", script_base)
luoyang_sign_mission.script_id = 500006
luoyang_sign_mission.g_Signpost = {
    { ["type"] = 2, ["name"] = "Tào sứ Lạc Dương", ["x"] = 228, ["y"] = 175, ["tip"] = "赵明诚",
        ["desc"] = "Tào sứ Lạc Dương Triệu Minh Thành ở đại viện phía đông cửa nam Đông Thị. Bấm TAB, bản đồ sẽ có dấu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "珍珑棋局", ["x"] = 271, ["y"] = 88, ["tip"] = "王积薪",
        ["desc"] = "Tìm đến Kỳ Thánh Vương Tích Tân (271,88) trong Vương phủ phía Đông Bắc thành Lạc Dương. Nhấn phím TAB, trên bản đồ sẽ có ký hiệu nhấp nháy.",
        ["eventId"] = -1 }
}
function luoyang_sign_mission:OnEnumerate(caller, selfId, targetId, arg, index)
    for i, signpost in pairs(self.g_Signpost) do
        caller:AddNumTextWithTarget(self.script_id, signpost["name"], -1, i)
    end
end

function luoyang_sign_mission:OnDefaultEvent(selfId, targetId,arg,index)
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

return luoyang_sign_mission
