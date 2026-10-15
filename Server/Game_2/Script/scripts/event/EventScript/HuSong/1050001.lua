local class = require "class"
local define = require "define"
local script_base = require "script_base"
local mission = class("mission", script_base)
mission.script_id = 1050001

function mission:OnDefaultEvent(selfId, targetId, arg, index)
    self:CallScriptFunction(006671, "OnDefaultEvent", selfId, targetId, arg, index)
end

function mission:OnEnumerate(caller, selfId, targetId)
    self:CallScriptFunction(006671, "OnEnumerate", caller, selfId, targetId, self.script_id)
end

function mission:CheckAccept()
    return 1
end

function mission:OnAccept(selfId, targetId)
    self:CallScriptFunction(006671, "OnAccept", selfId, targetId, self.script_id)
end

function mission:OnContinue(selfId, targetId)
    self:CallScriptFunction(006671, "OnContinue", selfId, targetId, self.script_id)
end

function mission:OnSubmit(selfId, targetId, selectRadioId)
    self:CallScriptFunction(006671, "OnSubmit", selfId, targetId, selectRadioId, self.script_id)
end

function mission:OnLockedTarget(selfId, targetId)
    self:CallScriptFunction(006671, "OnLockedTarget", selfId, targetId, self.script_id)
end

function mission:OnAbandon(selfId)
    self:CallScriptFunction(006671, "OnAbandon", selfId, self.script_id)
end

function mission:OnHumanDie(selfId)
    self:CallScriptFunction(006671, "OnHumanDie", selfId, self.script_id)
end

function mission:OnTimer(selfId)
    self:CallScriptFunction(006671, "OnTimer", selfId, self.script_id)
end

return mission