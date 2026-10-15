local class = require "class"
local define = require "define"
local script_base = require "script_base"
local luoyang_sign_yizhan = class("luoyang_sign_yizhan", script_base)
luoyang_sign_yizhan.script_id = 500002
luoyang_sign_yizhan.g_Signpost = {
    { ["type"] = 2, ["name"] = "Dịch trạm", ["x"] = 139, ["y"] = 182, ["tip"] = "吴德昌",
        ["desc"] = "Chủ dịch trạm Ngô Đức Xương (139, 182) ở dịch trạm giữa Nam Đại Nhai và Tây Thị. Ấn phím TAB, trên bản đồ sẽ có ký hiệu nhấp nháy.",
        ["eventId"] = -1 }
    ,
    { ["type"] = 2, ["name"] = "Thương hội Người truyền tống", ["x"] = 230, ["y"] = 129, ["tip"] = "汪旱",
        ["desc"] = "Người truyền tống Uông Hạn (230,129) của Thương hội ở Đại Lộ Phía Đông. Nhấn phím TAB, trên bản đồ sẽ có ký hiệu nhấp nháy.",
        ["eventId"] = -1 }
}
function luoyang_sign_yizhan:OnEnumerate(caller, selfId, targetId, arg, index)
    for i, signpost in pairs(self.g_Signpost) do
        caller:AddNumTextWithTarget(self.script_id, signpost["name"], -1, i)
    end
end

function luoyang_sign_yizhan:OnDefaultEvent(selfId, targetId, arg, index)
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

return luoyang_sign_yizhan
