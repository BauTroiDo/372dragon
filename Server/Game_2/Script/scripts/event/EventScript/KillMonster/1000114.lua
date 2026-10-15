local class = require "class"
local define = require "define"
local script_base = require "script_base"
local mission = class("mission", script_base)
mission.script_id = 1000114

function mission:OnDefaultEvent(selfId, targetId, arg, index)
    self:CallScriptFunction(006666, "OnDefaultEvent", selfId, targetId, arg)
end

function mission:OnEnumerate(caller, selfId, targetId)
    self:CallScriptFunction(006666, "OnEnumerate", caller, selfId, targetId, self.script_id)
end

function mission:CheckAccept()
    return 1
end

function mission:OnAccept(selfId, targetId)
    self:CallScriptFunction(006666, "OnAccept", selfId, targetId, self.script_id)
end

function mission:OnContinue(selfId, targetId)
    self:CallScriptFunction(006666, "OnContinue", selfId, targetId, self.script_id)
end

function mission:OnSubmit(selfId, targetId, selectRadioId)
    self:CallScriptFunction(006666, "OnSubmit", selfId, targetId, selectRadioId, self.script_id)
end

function mission:OnKillObject(selfId, objdataId, objId)
    self:CallScriptFunction(006666, "OnKillObject", selfId, objdataId, objId, self.script_id)
end

function mission:OnAbandon(selfId)
    self:CallScriptFunction(006666, "OnAbandon", selfId, self.script_id)
end

return mission