local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oemei_dizi_2 = class("oemei_dizi_2", script_base)
function oemei_dizi_2:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Ta là đệ tử phái Nga My.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oemei_dizi_2
