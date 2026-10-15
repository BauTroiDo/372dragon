local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_wanggui = class("osuzhou_wanggui", script_base)
function osuzhou_wanggui:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Sở đại nhân, lần này tỉ lệ của phối phương so sánh chắc là không sai chứ?")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return osuzhou_wanggui
