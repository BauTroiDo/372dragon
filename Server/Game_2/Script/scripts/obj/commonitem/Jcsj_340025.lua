local class = require "class"
local define = require "define"
local script_base = require "script_base"
local Jcsj_340025 = class("Jcsj_340025", script_base)
Jcsj_340025.script_id = 340025
Jcsj_340025.useitemid = 38000959

function Jcsj_340025:OnDefaultEvent(selfId, bagIndex)
end
function Jcsj_340025:IsSkillLikeScript(selfId)
    return 1
end

function Jcsj_340025:CancelImpacts(selfId)
    return 0
end

function Jcsj_340025:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
	local useid = self:LuaFnGetItemIndexOfUsedItem(selfId )
	if useid ~= self.useitemid then
		return 0
	end
	local usepos = self:LuaFnGetBagIndexOfUsedItem(selfId)
	if self:LuaFnGetItemTableIndexByIndex(selfId,usepos) ~= useid then
		return 0
	end
	if self:LuaFnGetMaterialBagSpace(selfId) < 1 then
		self:notify_tips(selfId, "#{DWCJJ_140606_23}")
		return 0
	end
    return 1
end

function Jcsj_340025:OnDeplete(selfId)
    -- if (self:LuaFnDepletingUsedItem(selfId)) then
        -- return 1
    -- end
    return 1
end

function Jcsj_340025:OnActivateOnce(selfId)
	local useid = self:LuaFnGetItemIndexOfUsedItem(selfId )
	if useid ~= self.useitemid then
		return 0
	end
	local usepos = self:LuaFnGetBagIndexOfUsedItem(selfId)
	if self:LuaFnGetItemTableIndexByIndex(selfId,usepos) ~= useid then
		return 0
	end
	if self:LuaFnGetMaterialBagSpace(selfId) < 1 then
		self:notify_tips(selfId, "#{DWCJJ_140606_23}")
		return 0
	end
	local msg = ""
	local havecount = self:GetBagItemParam(selfId, usepos, 4, "int")
	if havecount > 250 then
		local subcount = havecount - 250
		self:SetBagItemParam(selfId, usepos, 4,subcount, "int")
		if self:GetBagItemParam(selfId, usepos, 4, "int") ~= subcount then
			self:notify_tips(selfId, "error。")
			return 0
		end
		havecount = 250
		msg = self:ScriptGlobal_Format("#{DWCJJ_140606_22}",havecount,subcount)
	else
		self:EraseItem(selfId, usepos)
		msg = self:ScriptGlobal_Format("#{DWCJJ_140606_24}",havecount)
	end
	if havecount > 0 then
		self:BeginAddItem()
		self:AddItem(20310168,havecount,true)
		if not self:EndAddItem(selfId) then
			return 0
		end
		self:AddItemListToHuman(selfId)
		self:notify_tips(selfId, msg)
	end
	return 1
end

function Jcsj_340025:OnActivateEachTick(selfId)
    return 1
end

return Jcsj_340025
