local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_zongkada = class("oluoyang_zongkada", script_base)
function oluoyang_zongkada:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(
        "  Không khí ở thành Lạc Dương, đặc hơn nhiều so với không khí ở thành La Tá. Thật không quen...")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oluoyang_zongkada
