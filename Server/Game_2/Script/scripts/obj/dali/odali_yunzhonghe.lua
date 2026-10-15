local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odali_yunzhonghe = class("odali_yunzhonghe", script_base)
function odali_yunzhonghe:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{OBJ_dali_0007}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return odali_yunzhonghe
