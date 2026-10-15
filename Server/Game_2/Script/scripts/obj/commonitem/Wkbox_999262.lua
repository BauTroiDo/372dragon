local class = require "class"
local define = require "define"
local script_base = require "script_base"
local Wkbox_999262 = class("Wkbox_999262", script_base)
Wkbox_999262.script_id = 999262
Wkbox_999262.useitems = {
	[38003165] = 99926201,
}
function Wkbox_999262:OnDefaultEvent(selfId, bagIndex)
end
function Wkbox_999262:IsSkillLikeScript(selfId)
    return 1
end

function Wkbox_999262:CancelImpacts(selfId)
    return 0
end

function Wkbox_999262:OnConditionCheck(selfId)
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

function Wkbox_999262:OnDeplete(selfId)
    -- if (self:LuaFnDepletingUsedItem(selfId)) then
        -- return 1
    -- end
    return 1
end

function Wkbox_999262:OnActivateOnce(selfId)
    local human = self:get_scene():get_obj_by_id(selfId)
	if not human then
		return 0
	end
	local useid = self:LuaFnGetItemIndexOfUsedItem(selfId )
	local open_ui = self.useitems[useid]
	if not open_ui then
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
	self:GetDwJinJieZxBoxInfo(selfId)
	local isShowButton = 1				-- 0 = 不显示确定  1 = 显示
	local isClose = 0					-- 0 = 不关闭界面  1 = 关闭界面
	self:BeginUICommand()
	self:UICommand_AddInt(isShowButton)
	self:UICommand_AddInt(isClose)
	self:UICommand_AddInt(usepos)
	self:EndUICommand()
	self:DispatchUICommand(selfId,open_ui)
	
	return 1
end

function Wkbox_999262:OnActivateEachTick(selfId)
    return 1
end

function Wkbox_999262:GiveAward(selfId,index,bagpos)
	if not index or index < 1 then
		return
	end
	if self:LuaFnGetPropertyBagSpace(selfId) < 1 then
		self:notify_tips(selfId, "#{SSPL_241120_4}")
		return
	end
	local itemid = self:LuaFnGetItemTableIndexByIndex(selfId,bagpos)
	local open_ui = self.useitems[itemid]
	if not open_ui then
		self:notify_tips(selfId, "Khắc văn không tồn tại.")
		return
	elseif self:GetLevel(selfId) < 30 then
		local msg = self:ScriptGlobal_Format("#{TYLB_20220809_02}",30)
		self:notify_tips(selfId, msg)
		return 0
	end
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
	local isShowButton = 0				-- 0 = 不显示确定  1 = 显示
	local isClose = 1					-- 0 = 不关闭界面  1 = 关闭界面
	self:BeginUICommand()
	self:UICommand_AddInt(isShowButton)
	self:UICommand_AddInt(isClose)
	self:UICommand_AddInt(bagpos)
	self:EndUICommand()
	self:DispatchUICommand(selfId,open_ui)
end


return Wkbox_999262
