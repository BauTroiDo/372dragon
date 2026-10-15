local class = require "class"
local script_base = require "script_base"
local shenbing = class("shenbing", script_base)

function shenbing:OpenUI(selfId)
    self:BeginUICommand()
    self:UICommand_AddInt(0)
    self:UICommand_AddInt(0)
    self:UICommand_AddInt(0)
    self:UICommand_AddInt(0)
    self:EndUICommand()
    self:DispatchUICommand(selfId, 89027302)
end

return shenbing