local class = require "class"
local define = require "define"
local script_base = require "script_base"
local suzhou_sign_zhuangbeiqianghua = class("suzhou_sign_zhuangbeiqianghua", script_base)
suzhou_sign_zhuangbeiqianghua.script_id = 500028
suzhou_sign_zhuangbeiqianghua.g_Signpost = {
    { ["type"] = 2, ["name"] = "大宗师", ["x"] = 266, ["y"] = 139, ["tip"] = "欧冶子",
        ["desc"] = "Âu Dã Tử (266,139) có thể giúp ngươi cường hóa Trang bị và tiến hành Giám định tư chất cho Trang bị. Ấn phím TAB, trên bản đồ sẽ có tiêu ký nhấp nháy của.",
        ["eventId"] = -1 }
}
function suzhou_sign_zhuangbeiqianghua:OnEnumerate(caller, selfId, targetId, arg, index)
    for i, signpost in pairs(self.g_Signpost) do
        caller:AddNumTextWithTarget(self.script_id, signpost["name"], -1, i)
    end
end

function suzhou_sign_zhuangbeiqianghua:OnDefaultEvent(selfId, targetId, arg, index)
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

return suzhou_sign_zhuangbeiqianghua
