-- 珍兽通用功能脚本
--普通
local class = require "class"
local script_base = require "script_base"
local petcommon = class("petcommon", script_base)

-- 珍兽技能学习
function petcommon:PetStudy(selfId, skillId )
	local petGUID_H = self:LuaFnGetHighSectionOfTargetPetGuid(selfId )
	local petGUID_L = self:LuaFnGetLowSectionOfTargetPetGuid(selfId )
	local checkAvailable = self:LuaFnIsPetAvailableByGUIDNoPW(selfId, petGUID_H, petGUID_L)
	if checkAvailable then
		local ret = self:PetStudySkill(selfId, petGUID_H, petGUID_L, skillId )
		if ret then
			--成功的光效
			self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 18, 0)
			return 1
		end
	end
	return 0
end

-- 判断口粮适合珍兽食用
-- nIndex 是正在使用的口粮的背包位置
function petcommon:IsPetCanUseFood(selfId, nIndex )
	local petGUID_H = self:LuaFnGetHighSectionOfTargetPetGuid(selfId )
	local petGUID_L = self:LuaFnGetLowSectionOfTargetPetGuid(selfId )
	local ret = self:LuaFnPetCanUseFood(selfId, petGUID_H, petGUID_L, nIndex )
	if ret then
		return 1
	else
		return 0
	end
end

-- 增加珍兽最大生命值
function petcommon:IncPetMaxHP(selfId, value )
	if value <= 0 then
		return 0
	end
	local petGUID_H = self:LuaFnGetHighSectionOfTargetPetGuid(selfId)
	local petGUID_L = self:LuaFnGetLowSectionOfTargetPetGuid(selfId)
	value = value + self:LuaFnGetPetMaxHP( selfId, petGUID_H, petGUID_L)
	self:LuaFnSetPetMaxHP(selfId, petGUID_H, petGUID_L, value )
	return 1
end

-- 增加珍兽生命值
function petcommon:IncPetHP(selfId, value )
	if value <= 0 then
		return 0
	end
	local petGUID_H = self:LuaFnGetHighSectionOfTargetPetGuid(selfId)
	local petGUID_L = self:LuaFnGetLowSectionOfTargetPetGuid(selfId)

	value = value + self:LuaFnGetPetHP(selfId, petGUID_H, petGUID_L )
	local MaxHP = self:LuaFnGetPetMaxHP(selfId, petGUID_H, petGUID_L )
	if value > MaxHP then
		value = MaxHP
	end
	self:LuaFnSetPetHP(selfId, petGUID_H, petGUID_L, value)
	local ObjId = self:LuaFnGetPetObjIdByGUID(selfId, petGUID_H, petGUID_L)
	if ObjId then
		self:LuaFnSendSpecificImpactToUnit(selfId, selfId, ObjId, 23, 0)
	end
	return 1
end

-- 增加珍兽寿命
function petcommon:IncPetLife(selfId, value )
	if value <= 0 then
		return 0
	end

	local petGUID_H = self:LuaFnGetHighSectionOfTargetPetGuid(selfId)
	local petGUID_L = self:LuaFnGetLowSectionOfTargetPetGuid(selfId)

	value = value + self:LuaFnGetPetLife(selfId, petGUID_H, petGUID_L )

	self:LuaFnSetPetLife(selfId, petGUID_H, petGUID_L, value )
	self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 18, 0);
	return 1
end

-- 增加珍兽快乐度
function petcommon:IncPetHappiness(selfId, value )
	if value <= 0 then
		return 0
	end
	local petGUID_H = self:LuaFnGetHighSectionOfTargetPetGuid(selfId)
	local petGUID_L = self:LuaFnGetLowSectionOfTargetPetGuid(selfId)
	value = value + self:LuaFnGetPetHappiness(selfId, petGUID_H, petGUID_L )
	local MaxHappiness = 100
	if value > MaxHappiness then
		value = MaxHappiness
	end
	self:LuaFnSetPetHappiness(selfId, petGUID_H, petGUID_L, value )
	local ObjId = self:LuaFnGetPetObjIdByGUID(selfId, petGUID_H, petGUID_L )
	if ObjId then
		self:LuaFnSendSpecificImpactToUnit(selfId, selfId, ObjId, 24, 0)
	end
	return 1
end

return petcommon