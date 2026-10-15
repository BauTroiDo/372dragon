local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_zongkaban = class("oluoyang_zongkaban", script_base)
function oluoyang_zongkaban:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(
        "  Không biết đại hội Cúc Cầu năm nay, bên nào sẽ thắng, thật sự rất mong chờ!")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oluoyang_zongkaban
