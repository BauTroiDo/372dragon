local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_liujinchan = class("osuzhou_liujinchan", script_base)
function osuzhou_liujinchan:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Có một Thí sinh đến Tô Châu ứng thí tên là Nhan Tra Tán, hắn thật thú vị.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return osuzhou_liujinchan
