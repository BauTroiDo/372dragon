local class = require "class"
local define = require "define"
local script_base = require "script_base"
local GongLiDan = class("GongLiDan", script_base)
GongLiDan.script_id = 390102
GongLiDan.needitem = 30501361

function GongLiDan:OnDefaultEvent(selfId, bagIndex) end

function GongLiDan:IsSkillLikeScript(selfId) return 1 end

function GongLiDan:CancelImpacts(selfId) return 0 end

function GongLiDan:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then return 0 end
    local nPower = self:GetGongLi(selfId) 
    if nPower >= 10000 then
        self:NotifyTips(selfId, "Công lực hiện đã đầy")
        return 0
    end
    -- 每日次数限制已屏蔽，允许无限使用
    return 1
end

function GongLiDan:OnDeplete(selfId)
    -- if (self:LuaFnDepletingUsedItem(selfId)) then return 1 end
    return 1
end

function GongLiDan:OnActivateOnce(selfId)
	if self:OnConditionCheck(selfId) == 1 then
		local BagIndex = self:LuaFnGetBagIndexOfUsedItem(selfId)
		local nItemId = self:LuaFnGetItemTableIndexByIndex(selfId,BagIndex)
		if nItemId ~= self.needitem then
			return 1
		end
		self:LuaFnDecItemLayCount(selfId, BagIndex, 1)
		local nPower = self:GetGongLi(selfId)
		local nPower_Fin = nPower + 100
		self:SetGongLi(selfId, nPower_Fin)
		self:NotifyTips(selfId, string.format("Dùng thành công, công lực hiện tại: %d", nPower_Fin))
    end
	return 1
end

function GongLiDan:OnActivateEachTick(selfId) return 1 end

function GongLiDan:NotifyTips(selfId, Tip)
    self:BeginEvent(self.script_id)
    self:AddText(Tip)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return GongLiDan
