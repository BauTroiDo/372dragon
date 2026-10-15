local class = require "class"
local define = require "define"
local script_base = require "script_base"
local omeiling_yinye = class("omeiling_yinye", script_base)

function omeiling_yinye:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Nghe Hộ Pháp Bụi gai nói một hồi, mới biết mấy chục năm qua đều sống uổng phí. Sau này mọi người theo Hộ Pháp Bụi gai, lên núi đao xuống vạc dầu, đều cam tâm tình nguyện.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return omeiling_yinye
