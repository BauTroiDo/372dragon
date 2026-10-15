local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odali_ganbaobao = class("odali_ganbaobao", script_base)
function odali_ganbaobao:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Hừ, kẻ nào làm chuyện đê tiện vô sỉ, kẻ đó chính là đê tiện vô sỉ, đâu cần ta phải mở miệng chửi rủa!")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return odali_ganbaobao
