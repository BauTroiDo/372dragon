local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshaolin_dizi_4 = class("oshaolin_dizi_4", script_base)
function oshaolin_dizi_4:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Ta là đệ tử Thiếu Lâm phái.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oshaolin_dizi_4
