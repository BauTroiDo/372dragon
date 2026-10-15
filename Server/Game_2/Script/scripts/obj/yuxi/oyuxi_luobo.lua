local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oyuxi_luobo = class("oyuxi_luobo", script_base)

function oyuxi_luobo:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Chào.#r Tên của ta là Củ cải.#r Tên a ba ta là Sầm Mỗ Lạp.#r Tên a má ta là Cổ Lỗ Lạp.#r Tên muội muội ta là A Y Nạp.#r ...#r Xử lý hoàn tất.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oyuxi_luobo
