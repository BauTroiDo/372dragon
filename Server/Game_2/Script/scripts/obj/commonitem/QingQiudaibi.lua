local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local QingQiudaibi = class("QingQiudaibi", script_base)
QingQiudaibi.script_id = 893061
QingQiudaibi.ItemInfo = 
{
	[38002671] = 1,
	[38002672] = 2,
}
function QingQiudaibi:OnDefaultEvent(selfId, bagIndex)
end

function QingQiudaibi:IsSkillLikeScript(selfId)
    return 1
end

function QingQiudaibi:CancelImpacts(selfId)
    return 0
end

function QingQiudaibi:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
	local ItemId = self:LuaFnGetItemIndexOfUsedItem(selfId)
	if not self.ItemInfo[ItemId] then
		return 0
	end
    return 1
end

function QingQiudaibi:OnDeplete(selfId)
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end

function QingQiudaibi:OnActivateOnce(selfId)
	local ItemId = self:LuaFnGetItemIndexOfUsedItem(selfId)
	local daibi = {ScriptGlobal.MDEX_QINGQIU_SHOPLINGYE, ScriptGlobal.MDEX_QINGQIU_SHOPXINYE}
	local Text = {"#{QQSD_220801_29}","#{QQSD_220801_33}"}
	if not self.ItemInfo[ItemId] then
		return 0
	end
	self:SetMissionDataEx(selfId,daibi[self.ItemInfo[ItemId]],self:GetMissionDataEx(selfId,daibi[self.ItemInfo[ItemId]]) + 1)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 149, 0)
	self:notify_tips(selfId,Text[self.ItemInfo[ItemId]])
    return 1
end

function QingQiudaibi:OnActivateEachTick(selfId)
    return 1
end

return QingQiudaibi
