local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oxihu_songbin = class("oxihu_songbin", script_base)
function oxihu_songbin:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Trương tướng quân dùng binh như thần, thế lực của thủy quái hiện tại càng ngày càng yếu đi rồi.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oxihu_songbin
