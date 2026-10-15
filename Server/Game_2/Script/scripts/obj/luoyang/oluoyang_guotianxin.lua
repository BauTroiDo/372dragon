local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_guotianxin = class("oluoyang_guotianxin", script_base)
function oluoyang_guotianxin:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(
        "  Gần đây sẽ có hiện tượng kỳ thú sao Thủy nghịch hành, có thời gian hãy đi xem đi.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oluoyang_guotianxin
