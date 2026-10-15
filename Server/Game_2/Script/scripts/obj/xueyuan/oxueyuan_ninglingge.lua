local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oxueyuan_ninglingge = class("oxueyuan_ninglingge", script_base)
function oxueyuan_ninglingge:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Ngươi nghe qua truyền thuyết \"được chim cánh cụt ắt được hạnh phúc\" chưa?")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oxueyuan_ninglingge
