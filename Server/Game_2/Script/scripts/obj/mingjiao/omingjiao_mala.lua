local class = require "class"
local define = require "define"
local script_base = require "script_base"
local omingjiao_mala = class("omingjiao_mala", script_base)
function omingjiao_mala:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Bách Hoa muội muội nói ở Trung Thổ có một tòa Hàn Ngọc tháp, bên trong có rất nhiều truyền thuyết, thật muốn đi xem.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return omingjiao_mala
