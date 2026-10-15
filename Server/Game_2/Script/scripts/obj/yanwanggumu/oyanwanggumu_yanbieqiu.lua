local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oyanwanggumu_yanbieqiu = class("oyanwanggumu_yanbieqiu", script_base)

function oyanwanggumu_yanbieqiu:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(
        "  Dù khi sống là đế vương, sau khi chết cũng chỉ là một nắm đất vàng mà thôi.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oyanwanggumu_yanbieqiu
