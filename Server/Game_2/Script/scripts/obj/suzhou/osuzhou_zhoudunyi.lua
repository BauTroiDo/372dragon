local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_zhoudunyi = class("osuzhou_zhoudunyi", script_base)
function osuzhou_zhoudunyi:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{OBJ_suzhou_0004}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return osuzhou_zhoudunyi
