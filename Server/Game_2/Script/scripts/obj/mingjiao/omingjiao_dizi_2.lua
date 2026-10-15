local class = require "class"
local define = require "define"
local script_base = require "script_base"
local omingjiao_dizi_2 = class("omingjiao_dizi_2", script_base)
function omingjiao_dizi_2:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Ta là Đệ tử Minh Giáo.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return omingjiao_dizi_2
