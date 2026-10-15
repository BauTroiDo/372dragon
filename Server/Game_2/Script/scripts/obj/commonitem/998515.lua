local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local common_item = class("common_item", script_base)
local g_petList = {}
g_petList[30310086] = {type=1, dataId=27711, level=1,AttrType = "con_perception",minAttrData = 2500,maxAttrData = 2650}
g_petList[30310087] = {type=1, dataId=27711, level=1,AttrType = "con_perception",minAttrData = 2350,maxAttrData = 2500}
g_petList[30310088] = {type=1, dataId=27711, level=1,AttrType = "con_perception",minAttrData = 2200,maxAttrData = 2350}


g_petList[30310137] = {type=1, dataId=30261, level=1,AttrType = "con_perception",minAttrData = 2500,maxAttrData = 2650}
g_petList[30310138] = {type=1, dataId=30261, level=1,AttrType = "con_perception",minAttrData = 2350,maxAttrData = 2500}
g_petList[30310139] = {type=1, dataId=30261, level=1,AttrType = "con_perception",minAttrData = 2200,maxAttrData = 2350}


g_petList[30310169] = {type=1, dataId=25991, level=1,AttrType = "con_perception",minAttrData = 2750,maxAttrData = 3150}
g_petList[30310170] = {type=1, dataId=25991, level=1,AttrType = "con_perception",minAttrData = 2400,maxAttrData = 2750}
g_petList[30505113] = {type=1, dataId=6109, level=1,AttrType = "spr_perception",minAttrData = 2100,maxAttrData = 2600}
g_petList[30505289] = {type=1, dataId=6719, level=1,AttrType = "str_perception",minAttrData = 2100,maxAttrData = 2600}
g_petList[30505290] = {type=1, dataId=23609, level=1,AttrType = "con_perception",minAttrData = 2100,maxAttrData = 2600}
g_petList[30505291] = {type=1, dataId=23619, level=1,AttrType = "con_perception",minAttrData = 2100,maxAttrData = 2600}
g_petList[30505292] = {type=1, dataId=23699, level=1,AttrType = "con_perception",minAttrData = 2100,maxAttrData = 2600}
g_petList[30505293] = {type=1, dataId=3153, level=1,AttrType = "str_perception",minAttrData = 2100,maxAttrData = 2600}
g_petList[30505294] = {type=1, dataId=3112, level=1,AttrType = "str_perception",minAttrData = 2000,maxAttrData = 2500}

g_petList[30310187] = {type=1, dataId=30178, level=1,AttrType = "str_perception",minAttrData = 2600,maxAttrData = 4888}	--覆海龙君
g_petList[30310188] = {type=1, dataId=27488, level=1,AttrType = "spr_perception",minAttrData = 2600,maxAttrData = 4888}	--烈兔甜心
g_petList[30310189] = {type=1, dataId=26098, level=1,AttrType = "con_perception",minAttrData = 2600,maxAttrData = 4888}	--六耳猕猴
g_petList[30310168] = {type=1, dataId=25991, level=1,AttrType = "con_perception",minAttrData = 2600,maxAttrData = 4888}	--黑山姥姥·赴冰雪
function common_item:IsSkillLikeScript()
    return 1
end

function common_item:CancelImpacts()
    return 0
end

function common_item:OnConditionCheck(selfId)
	-- 校验使用的物品
	if not self:LuaFnVerifyUsedItem(selfId )then
		self:notify_tips( selfId, "Đạo cụ chưa mở, không dùng được 1.")
		return 0
	end
	local checkCreatePet = self:TryCreatePet(selfId, 1)
	if not checkCreatePet then
		self:notify_tips( selfId, "Ngươi không thể mang thêm Trân thú.")
		return 0
	end
	local itemTblIndex = self:LuaFnGetItemIndexOfUsedItem(selfId)
	local petItem = g_petList[itemTblIndex]
	if not petItem then
		self:notify_tips( selfId, "Đạo cụ chưa mở, không dùng được 2.")
		return 0
	end
	return 1
end

function common_item:OnDeplete(selfId)
    return 1
end

function common_item:OnActivateOnce(selfId)
	--删除前保存Trans....
	local BagIndex = self:LuaFnGetBagIndexOfUsedItem(selfId)
	local ItemInfo = self:GetBagItemTransfer(selfId, BagIndex )

	if not self:LuaFnDepletingUsedItem(selfId ) then
		self:notify_tips(selfId, "Đạo cụ chưa mở, không dùng được 3.")
		return 0
	end

	local itemTblIndex = self:LuaFnGetItemIndexOfUsedItem(selfId )
	local petItem = g_petList[itemTblIndex];
	if not petItem then
		self:notify_tips(selfId, "Đạo cụ chưa mở, không dùng được 4.")
		return 0
	end

	if petItem.type == 1 then
		local ret, petGUID_H, petGUID_L = self:CallScriptFunction(800105, "CreateRMBPetToHuman34534", selfId, petItem.dataId, petItem.level)
		if ret then
			--写入资质
			local dataAttr = math.random(petItem.minAttrData,petItem.maxAttrData)
			self:LuaFnSetPetData(selfId, petGUID_H, petGUID_L, petItem.AttrType, dataAttr)
			self:LuaFnSetPetData(selfId, petGUID_H, petGUID_L, "growth_rate",2.188)
			if petItem.dataId == 3112 or petItem.dataId == 30178 then
				self:LuaFnSetPetData(selfId, petGUID_H, petGUID_L, "ai_type",4) --勇猛
			elseif petItem.dataId == 6719 or petItem.dataId == 23609 or petItem.dataId == 23619 or petItem.dataId == 23699 or petItem.dataId == 3153 or petItem.dataId == 30178 or petItem.dataId == 27488 then
				self:LuaFnSetPetData(selfId, petGUID_H, petGUID_L, "ai_type",math.random(0,4)) --勇猛
			else
				self:LuaFnSetPetData(selfId, petGUID_H, petGUID_L, "ai_type",math.random(1,2))
			end
			
			self:OnGivePlayerPet(selfId, petItem.dataId, petGUID_H, petGUID_L, ItemInfo)
		else
			self:notify_tips(selfId, "Đạo cụ chưa mở, không thể sử dụng.")
            return 0
		end
	elseif petItem.type == 2 then
		local level = self:GetLevel(selfId)
		for _, pet in pairs(petItem.dataIds) do
			if level >= pet.minHumanLevel and level <= pet.maxHumanLevel  then
				local ret, petGUID_Hs, petGUID_Ls = self:CallScriptFunction(800105, "Create2RMBPetToHuman34534", selfId, pet.dataId, petItem.level)
				if ret then
					for i = 1, 2 do
						self:OnGivePlayerPet(selfId, pet.dataId, petGUID_Hs[i], petGUID_Ls[i], ItemInfo )
					end
				else
					self:notify_tips(selfId, "Đạo cụ chưa mở, không thể sử dụng.")
                    return 0
				end
			end
		end
		-- BagIndex
		self:EraseItem(selfId, BagIndex )
	else
	    local ret, petGUID_H, petGUID_L = self:LuaFnCreatePetToHuman(selfId, petItem.dataId, true)
	    if ret then
			self:OnGivePlayerPet(selfId, petItem.dataId, petGUID_H, petGUID_L, ItemInfo )
		end
	end
    return define.USEITEM_RESULT.USEITEM_SUCCESS
end

function common_item:OnGivePlayerPet(selfId, petId, petGUID_H, petGUID_L, ItemInfo )
	local petName = self:GetPetName(petId)
	if petName then
		self:notify_tips(selfId, "Chúc mừng ngài đã thành công nhận được"..petName.."！")
	end
	self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 18, 0)
	local player_name = self:GetName(selfId)
	player_name = gbk.fromutf8(player_name)
	local szPetTrans = self:GetPetTransString(selfId, petGUID_H, petGUID_L )
	local Msg = "#{_INFOUSR%s}#{XZS_12}#{_INFOMSG%s}#{XZS_13}#{_INFOMSG%s}#{XZS_14}"
	local str = string.format(Msg, player_name, ItemInfo, szPetTrans )
	self:BroadMsgByChatPipe(selfId, str, 4)
end

return common_item