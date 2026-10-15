local class = require "class"
local define = require "define"
local script_base = require "script_base"
local zhangqi = class("zhangqi", script_base)
zhangqi.script_id = 402296
function zhangqi:OnDefaultEvent(selfId, targetId)
    if self:CallScriptFunction(402047, "IsCommonAGuild", selfId) == 1 then
        self:BeginEvent(self.script_id)
        self:AddText("#{BHXZ_081103_24}")
        self:AddNumText("Ta muốn Sửa chữa Trang bị", 6, 1)
        self:AddNumText("#{INTERFACE_XML_1004}", 6, 2)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    else
        self:BeginEvent(self.script_id)
        self:AddText("#{BHXZ_081103_20}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
end

function zhangqi:OnEventRequest(selfId, targetId, arg, index)
    local key = index
    if self:CallScriptFunction(402047, "IsCommonAGuild", selfId) == 0 then
        return
    end
    if key == 1 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:UICommand_AddInt(-1)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 19810313)
    elseif key == 2 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:UICommand_AddInt(-1)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 101526358)
    end
end

return zhangqi
