local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_zhoubangyan = class("oluoyang_zhoubangyan", script_base)
function oluoyang_zhoubangyan:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(
        "  Nghe lời đồn rằng Sư Sư tiểu thư đã bị đưa vào Đoan Vương phủ, thật không dám tin đây là sự thật.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oluoyang_zhoubangyan
