-- 珍兽共用脚本接口函数文件
--普通
local class = require "class"
local script_base = require "script_base"
local petcommon = class("petcommon", script_base)

-- beast_trait

function petcommon:CreateRMBPetToHuman34534(selfId, petDataId, level)
	if not selfId or not petDataId then
		return false
	end

	local checkCreatePet = self:TryCreatePet(selfId, 1)
	if not checkCreatePet then
		self:notify_tips(selfId, "Ngươi không thể mang thêm Trân thú.")
		return false
	end

	local ret, petGUID_H, petGUID_L = self:LuaFnCreatePetToHuman(selfId, petDataId, true)
	if not ret or not petGUID_H or not petGUID_L then
		self:notify_tips(selfId, "Ngươi không thể mang theo Trân thú này.")
		return false
	end
	return true, petGUID_H, petGUID_L
end

function petcommon:Create2RMBPetToHuman34534(selfId, petDataId, level)
	if not selfId or not petDataId then
		return false
	end
	local checkCreatePet = self:TryCreatePet(selfId, 2)
	if not checkCreatePet then
		self:notify_tips(selfId, "Ngươi không thể mang thêm Trân thú.")
		return false
	end
	local petGUID_Hs = {}
	local petGUID_Ls = {}
	for i = 1, 2 do
		if i == 1 then
			local ret, petGUID_H, petGUID_L = self:LuaFnCreatePetToHuman(selfId, petDataId, true)
			if not ret or not petGUID_H or not petGUID_L then
				self:notify_tips(selfId, "Ngươi không thể mang theo Trân thú này.")
				return false
			end
			table.insert(petGUID_Hs, petGUID_H)
			table.insert(petGUID_Ls, petGUID_L)
		else
			local ret, petGUID_H, petGUID_L = self:LuaFnCreatePetToHuman(selfId, petDataId, true, nil, petGUID_Ls[1] + 1)
			if not ret or not petGUID_H or not petGUID_L then
				self:notify_tips(selfId, "Ngươi không thể mang theo Trân thú này.")
				return false
			end
			table.insert(petGUID_Hs, petGUID_H)
			table.insert(petGUID_Ls, petGUID_L)
		end
	end
	return true, petGUID_Hs, petGUID_Ls
end

return petcommon