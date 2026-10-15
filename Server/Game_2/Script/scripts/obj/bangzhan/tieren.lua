local class = require "class"
local define = require "define"
local script_base = require "script_base"
local tieren = class("tieren", script_base)
tieren.script_id = 402300
function tieren:OnDefaultEvent(selfId, targetId)
    if self:CallScriptFunction(402047, "IsCommonBGuild", selfId) == 1 then
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

function tieren:OnEventRequest(selfId, targetId, arg, index)
    local key = index
    if self:CallScriptFunction(402047, "IsCommonBGuild", selfId) == 0 then
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

return tieren
