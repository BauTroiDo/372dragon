local class = require "class"
local define = require "define"
local script_base = require "script_base"
local omiaojiang_cunmin = class("omiaojiang_cunmin", script_base)
function omiaojiang_cunmin:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Hôm nay ta uống rượu Hắc Miêu mới pha, cảm giác thật dễ chịu. Tửu nghệ của Cổ đại sư thật khiến người phải than phục!")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return omiaojiang_cunmin
