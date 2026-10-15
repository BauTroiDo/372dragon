local class = require "class"
local define = require "define"
local script_base = require "script_base"
local owudang_qingmingshenlu = class("owudang_qingmingshenlu", script_base)
function owudang_qingmingshenlu:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("<Hạc minh cửu cao, thanh văn vu thiên>")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return owudang_qingmingshenlu
