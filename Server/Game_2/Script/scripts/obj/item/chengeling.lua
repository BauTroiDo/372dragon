local class = require "class"
local define = require "define"
local script_base = require "script_base"
local chengeling = class("chengeling", script_base)
chengeling.script_id = 300021
chengeling.g_event = 229020
function chengeling:OnDefaultEvent(selfId, bagIndex)
    self:CallScriptFunction(self.g_event, "OnUseItem", selfId, bagIndex)
    return 0
end

function chengeling:IsSkillLikeScript(selfId)
    return 0
end

return chengeling
