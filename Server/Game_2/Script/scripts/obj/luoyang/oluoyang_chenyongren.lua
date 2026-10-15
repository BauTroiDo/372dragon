local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_chenyongren = class("oluoyang_chenyongren", script_base)
oluoyang_chenyongren.script_id = 311001
function oluoyang_chenyongren:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(
        "  Đại hiệp, đã đến Lạc Dương xem hội hoa chưa? Có gặp được Sư Sư cô nương không? Nghe nói mỗi lần hội hoa Sư Sư cô nương đều đến, đáng tiếc, ta bận công vụ nên không có duyên gặp mặt!")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oluoyang_chenyongren:OnDefaultEvent(selfId, targetId) end

return oluoyang_chenyongren
