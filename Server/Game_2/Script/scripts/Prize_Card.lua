local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ScriptGlobal = require "scripts.ScriptGlobal"
local Prize_Card = class("Prize_Card", script_base)
Prize_Card.script_id = 999911
Prize_Card.g_Item = 
{
    [38008305] = 1,
    [38008308] = 5,
    [38008168] = 20,
    [38008169] = 30,
    [38008170] = 50,
    [38008171] = 80,
    [38008172] = 100,
    [38008173] = 150,
    [38008174] = 200,
    [38008179] = 300,
    [38008180] = 500,
    [38008181] = 1000,
    [38008182] = 2000,
    [38008183] = 3000,
    [38008184] = 5000,
    [38008185] = 100000,
    [38008155] = 500,
}
function Prize_Card:OnDefaultEvent(selfId, bagIndex)
end
function Prize_Card:IsSkillLikeScript(selfId)
    return 1
end
function Prize_Card:CancelImpacts(selfId)
    return 0
end
function Prize_Card:OnConditionCheck(selfId)
    if not self:LuaFnVerifyUsedItem(selfId) then
        return 0
    end
    local itemTblIndex = self:LuaFnGetItemIndexOfUsedItem(selfId)
    if self.g_Item[itemTblIndex] == nil then
        self:Tip(selfId, "Vật phẩm không hợp lệ")
        return 0
    end
	if not ScriptGlobal.is_internal_test then
		if itemTblIndex == 38008155 or itemTblIndex == 38008185 then
			return 0
		end
	end
    --ScriptGlobal.MD_CHANGE_YUANBAO_RATE
    if (self.g_Item[itemTblIndex] * 400 + self:GetBindYuanBao(selfId)) > 2100000000 then
        self:Tip(selfId, "Nguyên bảo đổi vượt hạn, xin đổi ít lại")
        return 0
    end
    return 1
end
function Prize_Card:OnDeplete(selfId)
    if self:LuaFnDepletingUsedItem(selfId) then
        return 1
    end
    return 1
end
function Prize_Card:OnActivateOnce(selfId)
    local itemTblIndex = self:LuaFnGetItemIndexOfUsedItem(selfId)
    local addbindyuanbao = self.g_Item[itemTblIndex] * 400
	--self:CSAddYuanbao(selfId, addyuanbao)
    self:AddBindYuanBao(selfId,addbindyuanbao)
	self:Tip(selfId, "Ngươi đã thành công của đổi" .. addbindyuanbao .. "điểm Nguyên bảo khóa.")
    --local acme_havepoint = self:GetMissionData(selfId, ScriptGlobal.MD_CHANGE_YUANBAO)
	--self:SetMissionData(selfId, ScriptGlobal.MD_CHANGE_YUANBAO, acme_havepoint + addyuanbao)
	--self:CallScriptFunction(888817,"ResetPayReward",selfId,self.g_Item[itemTblIndex],666666,888888)		--666666,888888 此两值不要改动
	--刷新下称号
    --self:CallScriptFunction(888899, "AddPayTitle", selfId)
    return 1
end
function Prize_Card:OnActivateEachTick(selfId)
    return 1
end
function Prize_Card:Tip(selfId, Tip)
    self:BeginEvent(self.script_id)
    self:AddText(Tip)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end
return Prize_Card