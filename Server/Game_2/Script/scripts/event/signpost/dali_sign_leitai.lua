local class = require "class"
local define = require "define"
local script_base = require "script_base"
local dali_sign_leitai = class("dali_sign_leitai", script_base)
dali_sign_leitai.script_id = 500048
dali_sign_leitai.g_Signpost = {
    { ["type"] = 2, ["name"] = "武馆馆主", ["x"] = 96, ["y"] = 221, ["tip"] = "凤朝阳",
        ["desc"] = "Lôi đài là nơi để luận bàn võ nghệ, ngươi có thể tìm đến Quán chủ Phượng Triều Dương để tìm hiểu thêm, hắn ở ngay Thượng Võ Đài. Nhấn phím TAB, trên bản đồ sẽ có dấu hiệu nhấp nháy.",
        ["eventId"] = -1 }
}
function dali_sign_leitai:OnEnumerate(caller, selfId, targetId, arg, index)
    for i, signpost in pairs(self.g_Signpost) do
        caller:AddNumTextWithTarget(self.script_id, signpost["name"], -1, i)
    end
end

function dali_sign_leitai:OnDefaultEvent(selfId, targetId,arg,index)
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

return dali_sign_leitai
