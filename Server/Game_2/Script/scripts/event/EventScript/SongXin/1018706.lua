local class = require "class"
local define = require "define"
local script_base = require "script_base"
local mission = class("mission", script_base)
mission.script_id = 1018706

function mission:OnDefaultEvent(selfId, targetId, arg, index)
    self:CallScriptFunction(006668, "OnDefaultEvent", selfId, targetId, self.script_id)
end

function mission:OnEnumerate(caller, selfId, targetId)
    self:CallScriptFunction(006668, "OnEnumerate", caller, selfId, targetId, self.script_id)
end

function mission:CheckAccept()
    return 1
end

function mission:OnAccept(selfId, targetId)
    self:CallScriptFunction(006668, "OnAccept", selfId, targetId, self.script_id)
end

function mission:OnContinue(selfId, targetId)
    self:CallScriptFunction(006668, "OnContinue", selfId, targetId, self.script_id)
end

function mission:OnSubmit(selfId, targetId, selectRadioId)
    self:CallScriptFunction(006668, "OnSubmit", selfId, targetId, selectRadioId, self.script_id)
end

function mission:OnLockedTarget(selfId, targetId)
    self:CallScriptFunction(006668, "OnLockedTarget", selfId, targetId, self.script_id)
end

function mission:OnAbandon(selfId)
    self:CallScriptFunction(006668, "OnAbandon", selfId, self.script_id)
end

return mission