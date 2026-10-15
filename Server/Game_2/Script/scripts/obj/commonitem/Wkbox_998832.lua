local class = require "class"
local define = require "define"
local script_base = require "script_base"
local Wkbox_998832 = class("Wkbox_998832", script_base)
Wkbox_998832.script_id = 998832
Wkbox_998832.useitems = {
	[38003160] = 3,
	[38003161] = 3,
	[38003163] = 6,
	[38003164] = 9,
	[38003166] = 12,
}

function Wkbox_998832:OnDefaultEvent(selfId, bagIndex)
end
function Wkbox_998832:IsSkillLikeScript(selfId)
    return 1
end

function Wkbox_998832:CancelImpacts(selfId)
    return 0
end

function Wkbox_998832:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
	local useid = self:LuaFnGetItemIndexOfUsedItem(selfId )
	if not self.useitems[useid] then
		return 0
	end
	local usepos = self:LuaFnGetBagIndexOfUsedItem(selfId)
	if self:LuaFnGetItemTableIndexByIndex(selfId,usepos) ~= useid then
		return 0
	end
    return 1
end

function Wkbox_998832:OnDeplete(selfId)
    -- if (self:LuaFnDepletingUsedItem(selfId)) then
        -- return 1
    -- end
    return 1
end

function Wkbox_998832:OnActivateOnce(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
	if not human then
		return 0
	end
	local useid = self:LuaFnGetItemIndexOfUsedItem(selfId )
	local maxcount = self.useitems[useid]
	if not maxcount then
		self:notify_tips(selfId, "Đạo cụ không tồn tại..")
		return 0
	elseif self:GetLevel(selfId) < 30 then
		local msg = self:ScriptGlobal_Format("#{TYLB_20220809_02}",30)
		self:notify_tips(selfId, msg)
		return 0
	end
	local usepos = self:LuaFnGetBagIndexOfUsedItem(selfId)
	if self:LuaFnGetItemTableIndexByIndex(selfId,usepos) ~= useid then
		return 0
	end
	local record_data = self:GetDwJinJieParamEx(selfId,usepos,maxcount)
	if record_data == 1 then
		self:notify_tips(selfId, "Nhân vật không tồn tại.")
		return 0
	elseif record_data == 2 then
		self:notify_tips(selfId, "Đạo cụ không tồn tại.")
		return 0
	elseif record_data == 3 then
		self:notify_tips(selfId, "Đạo cụ bất thường.")
		return 0
	elseif record_data == 4 then
		self:notify_tips(selfId, "Bể tự chọn bất thường.")
		return 0
	end
	local index
	if maxcount == 3 then
		self:BeginUICommand()
		self:UICommand_AddInt(usepos)
		self:UICommand_AddInt(maxcount)
		for i = 1,maxcount do
			index = tostring(i)
			self:UICommand_AddInt(record_data[index])
		end
		self:EndUICommand()
		self:DispatchUICommand(selfId,99883201)
	else
		self:BeginUICommand()
		self:UICommand_AddInt(usepos)
		self:UICommand_AddInt(maxcount)
		for i = 1,maxcount do
			index = tostring(i)
			self:UICommand_AddInt(record_data[index])
		end
		self:EndUICommand()
		self:DispatchUICommand(selfId,99883202)
	
	end
	return 1
end

function Wkbox_998832:OnActivateEachTick(selfId)
    return 1
end

function Wkbox_998832:OnClientGetGift(selfId,bagpos,index)
	if self:LuaFnGetPropertyBagSpace(selfId) < 1 then
		self:notify_tips(selfId, "#{SSPL_241120_4}")
		return 0
	end
	local itemid = self:LuaFnGetItemTableIndexByIndex(selfId,bagpos)
	local maxcount = self.useitems[itemid]
	if not maxcount then
		return
	elseif self:GetLevel(selfId) < 30 then
		local msg = self:ScriptGlobal_Format("#{TYLB_20220809_02}",30)
		self:notify_tips(selfId, msg)
		return 0
	end
	local selectid = self:GetItemParamEx(selfId,bagpos,index)
	if selectid then
		local give_itemid = self:GetDwJinJieZxBoxItem(selfId,selectid)
		if give_itemid then
			local item_name = self:GetItemName(give_itemid)
			if item_name ~= -1 then
				self:EraseItem(selfId, bagpos)
				self:TryRecieveItem(selfId,give_itemid,true)
				local msg = self:ScriptGlobal_Format("#{OBCS_200916_04}",1,item_name)
				self:notify_tips(selfId, msg)
			end
		end
	end
end


return Wkbox_998832
