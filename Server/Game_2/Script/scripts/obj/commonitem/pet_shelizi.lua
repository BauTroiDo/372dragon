local class = require "class"
local define = require "define"
local script_base = require "script_base"
local pet_shelizi = class("pet_shelizi", script_base)
-- pet_shelizi.script_id = 300077 or 300088

function pet_shelizi:OnDefaultEvent(selfId, bagIndex)
end

function pet_shelizi:IsSkillLikeScript(selfId)
    return 1
end

function pet_shelizi:CancelImpacts(selfId)
    return 0
end

function pet_shelizi:OnConditionCheck(selfId)
    if (1 ~= self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
	local useid = self:LuaFnGetItemIndexOfUsedItem(selfId )
	if useid ~= 30900058 and useid ~= 30900059 then
		return 0
	end
	local phid,plid = self:LuaFnGetCurrentPetGUID(selfId)
	if not phid or not plid then
		self:notify_tips(selfId, "#{ZSKSSJ_081113_18}")
		return 0
	end
    return 1
end

function pet_shelizi:OnDeplete(selfId)
    return 1
end

function pet_shelizi:OnActivateOnce(selfId)
	local useid = self:LuaFnGetItemIndexOfUsedItem(selfId )
	if useid ~= 30900058 and useid ~= 30900059 then
		return 0
	end
	local phid,plid = self:LuaFnGetCurrentPetGUID(selfId)
	if not phid or not plid then
		self:notify_tips(selfId, "#{ZSKSSJ_081113_18}")
		return 0
	end
	local usepos = self:LuaFnGetBagIndexOfUsedItem(selfId)
	if self:LuaFnGetItemTableIndexByIndex(selfId,usepos) ~= useid then
		self:notify_tips(selfId, "Dùng đạo cụ bất thường.")
		return 0
	end
    local value = self:GetBagItemParam(selfId, usepos, 4)
	if value < 1 or value > 30000000 then
		value = 30000000
	end
	local pet = self:LuaFnGetPetObjByGUID(selfId, phid, plid)
	if not pet then
		self:notify_tips(selfId, "Không tìm thấy trân thú.")
		return 0
	end
	local pet_level = pet:get_level()
	if pet_level >= define.PET_LEVEL_NUM then
		self:notify_tips(selfId, "Cấp trân thú đã tối đa.")
		return 0
	end
	local wuxing = pet:get_wuxing()
    local extra_take_level = math.ceil(wuxing / 2) + 5
	local human_level = self:GetLevel(selfId) + extra_take_level
	if pet_level >= human_level then
		local msg = string.format("Trân thú cao hơn chủ %d cấp, không nhận kinh nghiệm được.",extra_take_level)
		self:notify_tips(selfId,msg)
		return 0
	end
	local cur_exp = pet:get_exp()
	local level_can_up = self:GetPetMaxLevelByExp(pet_level,cur_exp + value)
	if not level_can_up then
		self:notify_tips(selfId, "error。")
		return 0
	end
	if level_can_up > pet_level then
		self:BeginUICommand()
		self:UICommand_AddInt(value)
		self:UICommand_AddInt(level_can_up - pet_level)
		self:UICommand_AddInt(pet_level)
		self:UICommand_AddInt(human_level)
		self:UICommand_AddInt(phid)
		self:UICommand_AddInt(plid)
		self:UICommand_AddInt(usepos)
		self:EndUICommand()
		self:DispatchUICommand(selfId,3000771)
	else
		--MessageBox_Self.lua 没找到对应的确认弹窗，不够升一级的就直接使用了，因为UI最少得能升级一级才能显示
		self:UseShelizi(selfId,usepos,-1)
	end
    return 1
end

function pet_shelizi:OnActivateEachTick(selfId)
    return 1
end

function pet_shelizi:UseShelizi(selfId,usepos,up_to_level)
	if not up_to_level then
		return
	end
	local useid = self:LuaFnGetItemTableIndexByIndex(selfId,usepos)
	if useid ~= 30900058 and useid ~= 30900059 then
		self:notify_tips(selfId, "Thứ dùng không phải Xá Lợi Tử.")
		return
	end
	local phid,plid = self:LuaFnGetCurrentPetGUID(selfId)
	if not phid or not plid then
		self:notify_tips(selfId, "#{ZSKSSJ_081113_18}")
		return
	end
    local value = self:GetBagItemParam(selfId, usepos, 4)
	if value < 1 or value > 30000000 then
		value = 30000000
	end
	local pet = self:LuaFnGetPetObjByGUID(selfId, phid, plid)
	if not pet then
		self:notify_tips(selfId, "Không tìm thấy trân thú.")
		return
	end
	local pet_level = pet:get_level()
	if pet_level >= define.PET_LEVEL_NUM then
		self:notify_tips(selfId, "Cấp trân thú đã tối đa.")
		return
	end
	local wuxing = pet:get_wuxing()
    local extra_take_level = math.ceil(wuxing / 2) + 5
	local human_level = self:GetLevel(selfId) + extra_take_level
	if pet_level >= human_level then
		local msg = string.format("Trân thú cao hơn chủ %d cấp, không nhận kinh nghiệm được.",extra_take_level)
		self:notify_tips(selfId,msg)
		return
	end
	local del_exp
	local cur_exp = pet:get_exp()
	if up_to_level ~= -1 then
		if up_to_level <= pet_level then
			self:notify_tips(selfId, "#{SLZSDSJ_090915_13}")
			return
		elseif up_to_level >= define.PET_LEVEL_NUM or up_to_level > human_level then
			self:notify_tips(selfId, "#{SLZSDSJ_090915_14}")
			return
		end
		local need_exp = self:GetPetLevelAllExperience(selfId,up_to_level - 1,2100000000,pet_level)
		if need_exp > cur_exp + value then
			self:notify_tips(selfId, "Kinh nghiệm trong Xá Lợi Tử không đủ, xin nhập cấp lại.")
			return
		end
		del_exp = need_exp - cur_exp
	else
		local level_can_up = self:GetPetMaxLevelByExp(pet_level,cur_exp + value)
		if not level_can_up then
			self:notify_tips(selfId, "error。")
			return
		end
		if level_can_up <= human_level then
			del_exp = value
		else
			local need_exp = self:GetPetLevelAllExperience(selfId,human_level,2100000000,pet_level)
			del_exp = need_exp - cur_exp
		end
	end
	if not del_exp then
		self:notify_tips(selfId, "Lấy kinh nghiệm yêu cầu bất thường.")
		return
	end
	if del_exp >= value then
		self:EraseItem(selfId,usepos)
	else
		value = value - del_exp
		self:SetBagItemParam(selfId, usepos, 4, value, "int", true)
		if self:GetBagItemParam(selfId, usepos, 4) ~= value then
			self:notify_tips(selfId, "Trừ kinh nghiệm Xá Lợi Tử thất bại.")
			return
		end
	end
	pet:add_exp(del_exp)
	local pet_id = pet:get_obj_id()
	pet:show_buff_effect(pet_id,pet_id,-1,0,18)
	self:notify_tips(selfId, "Sử dụng thành công.")
end

return pet_shelizi
