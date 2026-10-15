local class = require "class"
local define = require "define"
local script_base = require "script_base"
local Wkbox_998831 = class("Wkbox_998831", script_base)
Wkbox_998831.script_id = 998831
Wkbox_998831.useitems = {
	[38003156] = {ui = 99883101,geveid = 38003158,needyb = 4000,needlevel = 50},
	[38003157] = {ui = 99883102,needlevel = 30,box_idx = {10,15,17,18}},
	[38003158] = {ui = 99883103,needlevel = 30,iszx32 = true},
}

-- 38003157
-- g_Item_List = {10,15,17,18}


function Wkbox_998831:OnDefaultEvent(selfId, bagIndex)
end
function Wkbox_998831:IsSkillLikeScript(selfId)
    return 1
end

function Wkbox_998831:CancelImpacts(selfId)
    return 0
end

function Wkbox_998831:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
	local useid = self:LuaFnGetItemIndexOfUsedItem(selfId )
	if not self.useitems[useid] then
		return 0
	elseif self:GetLevel(selfId) < self.useitems[useid].needlevel then
		local msg = self:ScriptGlobal_Format("#{TYLB_20220809_02}",self.useitems[useid].needlevel)
		self:notify_tips(selfId, msg)
		return 0
	end
	local usepos = self:LuaFnGetBagIndexOfUsedItem(selfId)
	if self:LuaFnGetItemTableIndexByIndex(selfId,usepos) ~= useid then
		return 0
	end
    return 1
end

function Wkbox_998831:OnDeplete(selfId)
    -- if (self:LuaFnDepletingUsedItem(selfId)) then
        -- return 1
    -- end
    return 1
end

function Wkbox_998831:OnActivateOnce(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
	if not human then
		return 0
	end
	local useid = self:LuaFnGetItemIndexOfUsedItem(selfId )
	local open_ui = self.useitems[useid]
	if not open_ui then
		self:notify_tips(selfId, "Đạo cụ không tồn tại..")
		return 0
	elseif self:GetLevel(selfId) < open_ui.needlevel then
		local msg = self:ScriptGlobal_Format("#{TYLB_20220809_02}",open_ui.needlevel)
		self:notify_tips(selfId, msg)
		return 0
	end
	local usepos = self:LuaFnGetBagIndexOfUsedItem(selfId)
	if self:LuaFnGetItemTableIndexByIndex(selfId,usepos) ~= useid then
		return 0
	end
	self:GetDwJinJieZxBoxInfo(selfId)
	local isShowButton = 1				-- 0 = 不显示确定  1 = 显示
	local isClose = 0					-- 0 = 不关闭界面  1 = 关闭界面
	self:BeginUICommand()
	self:UICommand_AddInt(isShowButton)
	self:UICommand_AddInt(isClose)
	self:UICommand_AddInt(usepos)
	self:EndUICommand()
	self:DispatchUICommand(selfId,open_ui.ui)
	
	return 1
end

function Wkbox_998831:OnActivateEachTick(selfId)
    return 1
end

function Wkbox_998831:GiveAward(selfId,index,bagpos)
	if not index or index < 1 then
		return
	end
	if self:LuaFnGetPropertyBagSpace(selfId) < 1 then
		self:notify_tips(selfId, "#{SSPL_241120_4}")
		return
	end
	local itemid = self:LuaFnGetItemTableIndexByIndex(selfId,bagpos)
	local open_ui = self.useitems[itemid]
	if open_ui then
		if open_ui.box_idx then
			index = open_ui.box_idx[index]
			if not index then
				self:notify_tips(selfId, "Khắc văn không tồn tại..")
				return
			end
			index = index + 1
			local zxbox = self:GetDwJinJieZxBoxInfo()
			-- zxbox[i].itemid = conf["ID"]
			-- zxbox[i].name = conf["名称"]
			-- zxbox[i].count = conf["数量"]
			if not zxbox or not zxbox[index] then
				self:notify_tips(selfId, "Khắc văn không tồn tại...")
				return
			end
			self:EraseItem(selfId,bagpos)
			self:TryRecieveItem(selfId,zxbox[index].itemid,true)
			self:GiveItemTip(selfId,zxbox[index].itemid,1,18)
		elseif open_ui.iszx32 then
			index = index - 100
			local zxbox = self:GetDwJinJieZxBoxInfo()
			-- zxbox[i].itemid = conf["ID"]
			-- zxbox[i].name = conf["名称"]
			-- zxbox[i].count = conf["数量"]
			if not zxbox or not zxbox[index] then
				self:notify_tips(selfId, "Khắc văn không tồn tại..")
				return
			end
			self:EraseItem(selfId,bagpos)
			self:TryRecieveItem(selfId,zxbox[index].itemid,true)
			self:GiveItemTip(selfId,zxbox[index].itemid,1,18)
		else
			self:notify_tips(selfId, "Tham số bất thường.")
			return
		end
		local isShowButton = 0				-- 0 = 不显示确定  1 = 显示
		local isClose = 1					-- 0 = 不关闭界面  1 = 关闭界面
		self:BeginUICommand()
		self:UICommand_AddInt(isShowButton)
		self:UICommand_AddInt(isClose)
		self:UICommand_AddInt(bagpos)
		self:EndUICommand()
		self:DispatchUICommand(selfId,open_ui.ui)
	end
end

function Wkbox_998831:GiveGiftBox(selfId,bagpos)
	if self:LuaFnGetPropertyBagSpace(selfId) < 1 then
		self:notify_tips(selfId, "#{SSPL_241120_4}")
		return
	end
	local itemid = self:LuaFnGetItemTableIndexByIndex(selfId,bagpos)
	local open_ui = self.useitems[itemid]
	if not open_ui then
		self:notify_tips(selfId, "Tham số bất thường.")
		return
	elseif self:GetLevel(selfId) < open_ui.needlevel then
		local msg = self:ScriptGlobal_Format("#{TYLB_20220809_02}",open_ui.needlevel)
		self:notify_tips(selfId, msg)
		return
	end
	local giveid = open_ui.geveid
	local needyb = open_ui.needyb
	if not giveid or not needyb then
		self:notify_tips(selfId, "Tham số bất thường..")
		return
	end
	if self:GetYuanBao(selfId) < needyb then
		self:notify_tips(selfId, "#{ZQPM_240402_103}")
		return
	end
	self:EraseItem(selfId,bagpos)
	self:LuaFnCostYuanBao(selfId, needyb)
	self:TryRecieveItem(selfId,giveid,true)
	self:GiveItemTip(selfId,giveid,1,18)
	local isShowButton = 0				-- 0 = 不显示确定  1 = 显示
	local isClose = 1					-- 0 = 不关闭界面  1 = 关闭界面
	self:BeginUICommand()
	self:UICommand_AddInt(isShowButton)
	self:UICommand_AddInt(isClose)
	self:UICommand_AddInt(bagpos)
	self:EndUICommand()
	self:DispatchUICommand(selfId,open_ui.ui)
end




return Wkbox_998831
