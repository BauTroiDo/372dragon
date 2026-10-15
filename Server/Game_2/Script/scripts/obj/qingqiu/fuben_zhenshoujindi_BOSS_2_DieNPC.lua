local class = require "class"
local define = require "define"
local script_base = require "script_base"
local fuben_zhenshoujindi_BOSS_2_DieNPC = class("fuben_zhenshoujindi_BOSS_2_DieNPC", script_base)
fuben_zhenshoujindi_BOSS_2_DieNPC.script_id = 893035
function fuben_zhenshoujindi_BOSS_2_DieNPC:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{ZSFB_20220105_68}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function fuben_zhenshoujindi_BOSS_2_DieNPC:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

return fuben_zhenshoujindi_BOSS_2_DieNPC
