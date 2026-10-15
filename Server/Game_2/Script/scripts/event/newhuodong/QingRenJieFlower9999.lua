local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local QingRenJieFlower9999 = class("QingRenJieFlower9999", script_base)
QingRenJieFlower9999.script_id = 892970
-- QingRenJieFlower9999.g_levelRequire = 1
-- QingRenJieFlower9999.g_radiusAE = 3.0
-- QingRenJieFlower9999.g_standFlag = 1
-- QingRenJieFlower9999.g_effectCount = 4
-- QingRenJieFlower9999.g_Impact1 = 34918
-- QingRenJieFlower9999.g_Impact2 = -1
local Needitemid = 38008176
local FlowerCount = 9999
local Additemid = 38002471
local AddCount = 400
local Needui = 1
local Haveimp = 63
local Youhadu = 34918

function QingRenJieFlower9999:OnDefaultEvent(selfId, bagIndex)
end

function QingRenJieFlower9999:IsSkillLikeScript(selfId)
    return 1
end

function QingRenJieFlower9999:CancelImpacts(selfId)
    return 0
end

function QingRenJieFlower9999:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
	if self:GetHumanGameFlag(selfId,"zhu_bo_flag") ~= 0 then
		self:notify_tips(selfId, "Nhân vật bị hạn chế giao dịch không tặng hoa được.")
		return 0
	elseif self:GetHumanGameFlag(selfId,"limit_change") ~= 0 then
		self:notify_tips(selfId, "Nhân vật bị hạn chế giao dịch không tặng hoa được.")
		return 0
	end
    local targetId = self:LuaFnGetTargetObjID(selfId)
    if (0 <= targetId) then
        if not self:LuaFnIsFriend(targetId, selfId) then
            self:LuaFnSendOResultToPlayer(selfId, define.OPERATE_RESULT.OR_INVALID_TARGET)
            return 0
        end
        if not self:LuaFnIsFriend(selfId, targetId) then
            self:LuaFnSendOResultToPlayer(selfId, define.OPERATE_RESULT.OR_INVALID_TARGET)
            return 0
        end
        -- local SelfSex = self:LuaFnGetSex(selfId)
        -- local TargetSex = self:LuaFnGetSex(targetId)
        -- if (SelfSex == TargetSex) then
            -- self:LuaFnSendOResultToPlayer(selfId, define.OPERATE_RESULT.OR_INVALID_TARGET)
            -- return 0
        -- end
		local nItemId = self:LuaFnGetItemIndexOfUsedItem(selfId)
		if nItemId ~= Needitemid then
			return 0
		end
		local curflag,_,uiflat = self:HuaBangCheck(selfId)
		if curflag < 1 or curflag > 3 then
			self:MsgBox(selfId,"Xin dùng khi bảng hoa Valentine mở.")
			return 0
		elseif uiflat ~= Needui then
			self:MsgBox(selfId,"Xin dùng khi bảng hoa Valentine mở.")
			return 0
		end
    end
    return 1
end
function QingRenJieFlower9999:OnDeplete(selfId)
    local targetId = self:LuaFnGetTargetObjID(selfId)
	local nItemId = self:LuaFnGetItemIndexOfUsedItem(selfId)
	if nItemId ~= Needitemid then
		return 0
	end
    if (self:LuaFnDepletingUsedItem(selfId)) then
        return 1
    end
    return 0
end
function QingRenJieFlower9999:OnActivateOnce(selfId)
	if self:GetHumanGameFlag(selfId,"zhu_bo_flag") ~= 0 then
		self:notify_tips(selfId, "Nhân vật bị hạn chế giao dịch không tặng hoa được.")
		return 0
	elseif self:GetHumanGameFlag(selfId,"limit_change") ~= 0 then
		self:notify_tips(selfId, "Nhân vật bị hạn chế giao dịch không tặng hoa được.")
		return 0
	end
	local targetId = self:LuaFnGetTargetObjID(selfId)
	if (0 <= targetId) then
		if self:LuaFnIsFriend(targetId, selfId) then
			local nItemId = self:LuaFnGetItemIndexOfUsedItem(selfId)
			if nItemId ~= Needitemid then
				return 0
			end
			local curflag,_,uiflat = self:HuaBangCheck(selfId)
			if curflag < 1 or curflag > 3 then
				self:MsgBox(selfId,"Xin dùng khi bảng hoa Valentine mở.")
				return 0
			elseif uiflat ~= Needui then
				self:MsgBox(selfId,"Xin dùng khi bảng hoa Valentine mở.")
				return 0
			end
			local nFriendPoint = self:LuaFnGetFriendPoint(selfId, targetId)
			if nFriendPoint >= 9999 then
				self:BeginEvent(self.script_id)
				self:AddText("Độ hảo hữu giữa ngươi và đối phương đã đạt tới giới hạn.")
				self:EndEvent()
				self:DispatchMissionTips(selfId)
			else
				self:LuaFnSendSpecificImpactToUnit(selfId, selfId, targetId, Youhadu, 0)
				self:BeginEvent(self.script_id)
				self:AddText("Độ hữu hảo giữa ngươi và đối phương đã tăng 5000")
				self:EndEvent()
				self:DispatchMissionTips(selfId)
			end
			local szNameSelf = self:GetName(selfId)
			local szNameTarget = self:GetName(targetId)
			self:UpdateHuaBang(selfId,targetId,FlowerCount,ScriptGlobal.MD_QINGRENJIEDAIBI,AddCount)
			-- self:LuaFnSendSpecificImpactToUnit(selfId, selfId, targetId, 18, 0)
			self:ShowObjBuffEffect(selfId,targetId,-1,18)
			if Haveimp ~= -1 then
				-- self:LuaFnSendSpecificImpactToUnit(selfId, selfId, targetId, Haveimp, 0)
				-- self:LuaFnSendSpecificImpactToUnit(targetId, targetId, targetId, 5978, 0)
				-- self:LuaFnSendSpecificImpactToUnit(selfId, selfId, targetId, 18, 0)
			end
			local itemname = self:GetItemName(nItemId)
			self:MsgBox(selfId, string.format("Ngươi tặng %s món %s, nhận được %d cái %s.",
			szNameTarget,itemname,AddCount,self:GetItemName(Additemid)))
			self:MsgBox(targetId, string.format("Ngươi nhận được %s tặng %s.",szNameSelf,itemname))
			local randMessage = math.random(3)
			local message
			if randMessage == 1 then
				message =
					string.format(
					"#{_INFOUSR%s}#{GiveRose_00}[%s]#{GiveRose_01}#{_INFOUSR%s}#{GiveRose_02}",
					szNameSelf,
					itemname,
					szNameTarget
				)
			elseif randMessage == 2 then
				message =
					string.format(
					"#{_INFOUSR%s}#{GiveRose_03}[%s]#{GiveRose_04}#{_INFOUSR%s}#{GiveRose_05}",
					szNameSelf,
					itemname,
					szNameTarget
				)
			else
				message =
					string.format(
					"#{_INFOUSR%s}#{GiveRose_03}[%s]#{GiveRose_06}#{_INFOUSR%s}#{GiveRose_07}",
					szNameSelf,
					itemname,
					szNameTarget
				)
			end
			self:AddGlobalCountNews(message)
			return 1
		end
	end
    return 0
end
function QingRenJieFlower9999:OnActivateEachTick(selfId)
    return 1
end
function QingRenJieFlower9999:MsgBox(selfId, Msg)
    if Msg == nil then
        return
    end
    self:BeginEvent(self.script_id)
    self:AddText(Msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end
return QingRenJieFlower9999
