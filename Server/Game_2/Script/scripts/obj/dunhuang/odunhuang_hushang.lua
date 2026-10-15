local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odunhuang_hushang = class("odunhuang_hushang", script_base)

function odunhuang_hushang:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Thiên Tiên muội muội~~")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return odunhuang_hushang
