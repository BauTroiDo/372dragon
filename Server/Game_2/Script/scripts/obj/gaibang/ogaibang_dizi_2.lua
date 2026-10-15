local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ogaibang_dizi_2 = class("ogaibang_dizi_2", script_base)
function ogaibang_dizi_2:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Ta là Đệ tử Cái Bang.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return ogaibang_dizi_2
