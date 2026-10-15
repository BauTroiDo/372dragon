local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oemei_dizi_3 = class("oemei_dizi_3", script_base)
function oemei_dizi_3:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("<Hoa chi chiêu triển, vũ mị động nhân>")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oemei_dizi_3
