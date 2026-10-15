local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local forge_shenbing = class("forge_shenbing", script_base)
forge_shenbing.script_id = 888815

-- function forge_shenbing:UpdateEventList(selfId, targetId)
    -- self:BeginEvent(self.script_id)
    -- self:AddText("#{SBFW_20230707_255}")
    -- self:AddNumText("#{SBFW_20230707_26}", 6, 1)
    -- self:EndEvent()
    -- self:DispatchEventList(selfId, targetId)
-- end
-- function forge_shenbing:OnDefaultEvent(selfId, targetId)
    -- self:UpdateEventList(selfId, targetId)
-- end

-- function forge_shenbing:OnEventRequest(selfId, targetId, arg, index)
	-- if index == 1 then
        -- self:BeginUICommand()
        -- self:UICommand_AddInt(targetId)
        -- self:EndUICommand()
        -- self:DispatchUICommand(selfId, 88881205)
	-- end
-- end
function forge_shenbing:ShenBingSelectSkill(selfId,targetId,g_ShenBing_BagIndex,g_Sel_Skill_Index_1,g_Sel_Skill_Index_2)
	if self:FixLegacyShenBinData(selfId,g_ShenBing_BagIndex) then
        self:notify_tips(selfId, "Thần binh có dữ liệu cũ, đã tự sửa, xin thao tác lại là được.")
        return
    end
	if not self:CheckHnmanLevel(selfId) then
		return
	elseif not g_Sel_Skill_Index_1 or g_Sel_Skill_Index_1 < 0 or g_Sel_Skill_Index_1 > 3 then
		self:notify_tips(selfId, "left error")
		return
	elseif not g_Sel_Skill_Index_2 or g_Sel_Skill_Index_2 < 0 or g_Sel_Skill_Index_2 > 3 then
		self:notify_tips(selfId, "right error")
		return
	end
	local skill_1,skill_2 = self:CheckShenBinSkillSelect(selfId, g_ShenBing_BagIndex, g_Sel_Skill_Index_1 + 1,g_Sel_Skill_Index_2 + 1)
	if not skill_1 then
		return
	end
	self:SetShenBinSkillSelect(selfId, g_ShenBing_BagIndex, skill_1,skill_2)
    self:notify_tips(selfId, "#{SBFW_20230707_153}")
	self:ShowObjBuffEffect(selfId,selfId,-1,18)
end
function forge_shenbing:ShenBingSkillUp(selfId,targetId,g_ShenBing_BagIndex,g_CurSel,box_flag)
	if self:FixLegacyShenBinData(selfId,g_ShenBing_BagIndex) then
        self:notify_tips(selfId, "Thần binh có dữ liệu cũ, đã tự sửa, xin thao tác lại là được.")
        return
    end
	if not g_CurSel or g_CurSel < 1 or g_CurSel > 5 then
        self:notify_tips(selfId, "#{SBFW_20230707_169}")
        return
    end
	if not self:CheckHnmanLevel(selfId) then
		return
	end
	local new_id,old_id,level,needitem,needitem_count,needmoney = self:GetShenBinSkillUpgradeRequirement (selfId, g_ShenBing_BagIndex, g_CurSel)
	if not new_id then
		return
	end
    if self:GetMoneyJZ(selfId) + self:GetMoney(selfId) < needmoney then
        self:notify_tips(selfId, "Xin lỗi, kim tiền trên người ngươi không đủ, không thể tiếp tục")
        return
    end
	if self:LuaFnGetAvailableItemCount(selfId,needitem) < needitem_count then
		local msg = string.format("Trong túi %s không đủ %d cái hoặc đã khóa.",self:GetItemName(needitem),needitem_count)
		self:notify_tips(selfId,msg)
		return
	end
	self:LuaFnDelAvailableItem(selfId,needitem,needitem_count)
    self:LuaFnCostMoneyWithPriority(selfId,needmoney)
	self:SetShenBinSkillUpgrade (selfId, g_ShenBing_BagIndex, g_CurSel, old_id, new_id)
    self:notify_tips(selfId, "#{SBFW_20230707_174}")
	self:ShowObjBuffEffect(selfId,selfId,-1,18)
end


function forge_shenbing:ShenBingUnlockSkill(selfId,targetId,g_ShenBing_BagIndex,g_CurSel,box_flag)
	if self:FixLegacyShenBinData(selfId,g_ShenBing_BagIndex) then
        self:notify_tips(selfId, "Thần binh có dữ liệu cũ, đã tự sửa, xin thao tác lại là được.")
        return
    end
	if not g_CurSel or g_CurSel < 0 or g_CurSel > 2 then
        self:notify_tips(selfId, "#{SBFW_20230707_158}")
        return
    end
	if not self:CheckHnmanLevel(selfId) then
		return
	end
	g_CurSel = g_CurSel + 1
	local qiqing_lv = self:CheckShenBinSkillUnlock(selfId, g_ShenBing_BagIndex, g_CurSel)
	if not qiqing_lv then
		return
	end
	local need_tbl = {5,10,15}
	if qiqing_lv < need_tbl[g_CurSel] then
		local msg = string.format("Cấp chú tình không đủ %d.",need_tbl[g_CurSel])
		self:notify_tips(selfId,msg)
		return
	end
	need_tbl = {38002969,38002970,38002971}
	local needitem = need_tbl[g_CurSel]
	if self:LuaFnGetAvailableItemCount(selfId,needitem) < 1 then
		self:notify_tips(selfId,"#{SBFW_20230707_159}")
		return
	end
	self:LuaFnDelAvailableItem(selfId,needitem,1)
	self:SetShenBinSkillUnlock(selfId, g_ShenBing_BagIndex, g_CurSel)
    self:notify_tips(selfId, "#{SBFW_20230707_160}")
	self:ShowObjBuffEffect(selfId,selfId,-1,18)
end
function forge_shenbing:CheckHnmanLevel(selfId)
	if self:GetLevel(selfId) < 65 then
		self:notify_tips(selfId, "#{SBFW_20230707_46}")
		return
	end
	return true
end
return forge_shenbing
