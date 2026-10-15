local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local common_item = class("common_item", script_base)

local g_petList = {}
g_petList[30505907] = {type=1, dataId=22209, level=1}	--珍兽蛋：兔子

function common_item:IsSkillLikeScript()
    return 1
end

function common_item:CancelImpacts()
    return 0
end

function common_item:OnConditionCheck(selfId)
	-- 校验使用的物品
	if not self:LuaFnVerifyUsedItem(selfId )then
		self:notify_tips( selfId, "Đạo cụ chưa mở, không thể sử dụng.")
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
		self:notify_tips( selfId, "Đạo cụ chưa mở, không thể sử dụng.")
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
		self:notify_tips(selfId, "Đạo cụ chưa mở, không thể sử dụng.")
		return 0
	end

	local itemTblIndex = self:LuaFnGetItemIndexOfUsedItem(selfId )
	local petItem = g_petList[itemTblIndex];
	if not petItem then
		self:notify_tips(selfId, "Đạo cụ chưa mở, không thể sử dụng.")
		return 0
	end

	if petItem.type == 1 then
		local ret, petGUID_H, petGUID_L = self:CallScriptFunction(800105, "CreateRMBPetToHuman34534", selfId, petItem.dataId, petItem.level)
		if ret then
			self:OnGivePlayerPet(selfId, petItem.dataId, petGUID_H, petGUID_L, ItemInfo)
		else
			self:notify_tips(selfId, "Đạo cụ chưa mở, không thể sử dụng.")
            return 0
		end
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
	--毛驴公告....
	if petId == 3399 or petId == 8969 or petId == 8979 or petId == 8989 then
		local szPetTrans = self:GetPetTransString(selfId, petGUID_H, petGUID_L )
		local Msg = "#{_INFOUSR%s}#R sử dụng #{_INFOMSG%s}#R nhận được một #{_INFOMSG%s}#R."
		local str = string.format(Msg, player_name, ItemInfo, szPetTrans )
		self:BroadMsgByChatPipe(selfId, str, 4)
		return
	end
	--唐装鼠公告....
	if petId == 8759 or petId == 8789 or petId == 8799  then
		local szPetTrans = self:GetPetTransString(selfId, petGUID_H, petGUID_L )
		local Msg = "#{_INFOUSR%s}#{TZS_16}#{_INFOMSG%s}#{TZS_17}#{_INFOUSR%s}#{TZS_18}"
		local str = string.format( Msg, player_name, szPetTrans, player_name )
		self:BroadMsgByChatPipe(selfId, str, 4)
		return
	end
	--穷奇公告....
	if petId == 22059 then
		local szPetTrans = self:GetPetTransString(selfId, petGUID_H, petGUID_L )
		local Msg = "#{_INFOUSR%s}#{XZS_01}#{_INFOMSG%s}#{XZS_02}#{_INFOMSG%s}#{XZS_03}"
		local str = string.format( Msg, player_name, ItemInfo, szPetTrans )
		self:BroadMsgByChatPipe(selfId, str, 4)
		return
	end
	--小狐仙公告....
	if petId == 22129 then
		local szPetTrans = self:GetPetTransString(selfId, petGUID_H, petGUID_L )
		local Msg = "#{_INFOUSR%s}#{XZS_04}#{_INFOMSG%s}#{XZS_05}#{_INFOMSG%s}#{XZS_06}"
		local str = string.format( Msg, player_name, ItemInfo, szPetTrans )
		self:BroadMsgByChatPipe(selfId, str, 4)
		return
	end
	--鸳鸯公告... zchw
	if (petId == 8889) or (petId == 8899) or (petId == 8909) or (petId == 8919) or (petId == 8929) or(petId == 8939) or (petId == 8949) then
		local szPetTrans = self:GetPetTransString(selfId, petGUID_H, petGUID_L )
		local Msg = "#{_INFOUSR%s}#{XZS_07}#{_INFOMSG%s}#{XZS_08}#{_INFOMSG%s}#{XZS_09}"
		local str = string.format(Msg, player_name, ItemInfo, szPetTrans )
		self:BroadMsgByChatPipe(selfId, str, 4)
		return
	end
	--呆呆牛公告... hzp
	if (petId == 22289) or (petId == 22299) or (petId == 22309) or (petId == 22319) or (petId == 22329) or(petId == 22339) or (petId == 22349) then
		local szPetTrans = self:GetPetTransString(selfId, petGUID_H, petGUID_L )
		local Msg = "#{_INFOUSR%s}#{XZS_04}#{_INFOMSG%s}#{XZS_10}#{_INFOMSG%s}#{XZS_11}"
		local str = string.format( Msg, player_name, ItemInfo, szPetTrans )
		self:BroadMsgByChatPipe(selfId, str, 4)
		return
	end
	--欢乐猪公告... hzp
	if (petId == 8569) or (petId == 8579) or (petId == 8589) or (petId == 8599) or (petId == 8609) or(petId == 8619) or (petId == 8629) then
		local szPetTrans =self: GetPetTransString(selfId, petGUID_H, petGUID_L )
		local Msg = "#{_INFOUSR%s}#{XZS_12}#{_INFOMSG%s}#{XZS_13}#{_INFOMSG%s}#{XZS_14}"
		local str = string.format(Msg, player_name, ItemInfo, szPetTrans )
		self:BroadMsgByChatPipe(selfId, str, 4)
		return
	end
	--比翼鸟公告... hzp
	if (petId == 22219) or (petId == 22229) or (petId == 22239) or (petId == 22249) or (petId == 22259) or(petId == 22269) or (petId == 22279) then
		local szPetTrans = self:GetPetTransString(selfId, petGUID_H, petGUID_L )
		local Msg = "#{_INFOUSR%s}#{XZS_15}#{_INFOMSG%s}#{XZS_16}#{_INFOMSG%s}#{DSSJ_4}"
		local str = string.format(Msg, player_name, ItemInfo, szPetTrans )
		self:BroadMsgByChatPipe(selfId, str, 4)
		return
	end
	local szPetTrans = self:GetPetTransString(selfId, petGUID_H, petGUID_L )
	local Msg = "#{_INFOUSR%s}#{XZS_12}#{_INFOMSG%s}#{XZS_13}#{_INFOMSG%s}#{XZS_14}"
	local str = string.format(Msg, player_name, ItemInfo, szPetTrans )
	self:BroadMsgByChatPipe(selfId, str, 4)
end

return common_item