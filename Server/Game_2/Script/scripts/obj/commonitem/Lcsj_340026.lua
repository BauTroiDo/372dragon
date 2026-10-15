local class = require "class"
local define = require "define"
local script_base = require "script_base"
local Lcsj_340026 = class("Lcsj_340026", script_base)
Lcsj_340026.script_id = 340026
Lcsj_340026.useitemid = 38000960

function Lcsj_340026:OnDefaultEvent(selfId, bagIndex)
end
function Lcsj_340026:IsSkillLikeScript(selfId)
    return 1
end

function Lcsj_340026:CancelImpacts(selfId)
    return 0
end

function Lcsj_340026:OnConditionCheck(selfId)
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
		self:notify_tips(selfId, "#{DWJJ_240329_207}")
		return 0
	end
    return 1
end

function Lcsj_340026:OnDeplete(selfId)
    -- if (self:LuaFnDepletingUsedItem(selfId)) then
        -- return 1
    -- end
    return 1
end

function Lcsj_340026:OnActivateOnce(selfId)
	local useid = self:LuaFnGetItemIndexOfUsedItem(selfId )
	if useid ~= self.useitemid then
		return 0
	end
	local usepos = self:LuaFnGetBagIndexOfUsedItem(selfId)
	if self:LuaFnGetItemTableIndexByIndex(selfId,usepos) ~= useid then
		return 0
	end
	if self:LuaFnGetMaterialBagSpace(selfId) < 1 then
		self:notify_tips(selfId, "#{DWJJ_240329_207}")
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
		msg = self:ScriptGlobal_Format("#{DWJJ_240329_206}",subcount)
	else
		self:EraseItem(selfId, usepos)
		msg = self:ScriptGlobal_Format("#{DWJJ_240329_208}",havecount)
	end
	if havecount > 0 then
		self:BeginAddItem()
		self:AddItem(20310174,havecount,true)
		if not self:EndAddItem(selfId) then
			return 0
		end
		self:AddItemListToHuman(selfId)
		self:notify_tips(selfId, msg)
	end
	return 1
end

function Lcsj_340026:OnActivateEachTick(selfId)
    return 1
end

return Lcsj_340026
