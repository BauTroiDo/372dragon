local class = require "class"
local ScriptGlobal = require "scripts.ScriptGlobal"
local define = require "define"
local script_base = require "script_base"
local hunchen = class("hunchen", script_base)
hunchen.script_id = 331019
function hunchen:OnDefaultEvent(selfId, bagIndex) end

function hunchen:IsSkillLikeScript(selfId)
	return 1;
end

function hunchen:CancelImpacts(selfId) return 0 end

function hunchen:OnConditionCheck(selfId)
    return self:LuaFnVerifyUsedItem(selfId)
end

function hunchen:OnDeplete(selfId)
    return self:LuaFnDepletingUsedItem(selfId)
end

function hunchen:OnActivateOnce(selfId)
    local value = self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_HUNCHEN_POINT)
    value = value + 1
    self:SetMissionDataEx(selfId, ScriptGlobal.MDEX_HUNCHEN_POINT, value)
    self:notify_tips(selfId, string.format("Nhận 1 điểm Hồn Trần, hiện có %d điểm", value))
    return 1
end

function hunchen:OnActivateEachTick(selfId) return 1 end

return hunchen
