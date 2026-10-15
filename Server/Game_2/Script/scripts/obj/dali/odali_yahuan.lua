local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odali_yahuan = class("odali_yahuan", script_base)
function odali_yahuan:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Ta là một A hoàn")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return odali_yahuan
