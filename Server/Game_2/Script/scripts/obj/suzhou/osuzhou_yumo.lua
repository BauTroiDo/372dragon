local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_yumo = class("osuzhou_yumo", script_base)
function osuzhou_yumo:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Công tử nhà ta tài cao bát đấu, nhất định sẽ thi đỗ.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return osuzhou_yumo
