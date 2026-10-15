local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oyannan_shibing = class("oyannan_shibing", script_base)
function oyannan_shibing:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Theo Chủng Thế Hành đại soái, có thể lập công dựng nghiệp; theo Mã Thừa Thiến giám quân, có thể thăng quan phát tài. Nhưng hai việc này luôn cảm thấy thật mâu thuẫn.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oyannan_shibing
