local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_hezhu = class("osuzhou_hezhu", script_base)
function osuzhou_hezhu:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{OBJ_suzhou_0006}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return osuzhou_hezhu
