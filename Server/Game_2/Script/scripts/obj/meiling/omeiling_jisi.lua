local class = require "class"
local define = require "define"
local script_base = require "script_base"
local omeiling_jisi = class("omeiling_jisi", script_base)
function omeiling_jisi:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Nghe nói ở chỗ Tử Vi tỷ tỷ Võ Di Sơn xảy ra không ít chuyện, rất nhiều tỷ muội đều chết rồi... A, ta chỉ biết những điều này.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return omeiling_jisi
