local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ScriptGlobal = require "scripts.ScriptGlobal"
local Trade_Token = class("Trade_Token", script_base)

Trade_Token.script_id = 999912
Trade_Token.g_Item = {
    [38008209] = true,
}

function Trade_Token:OnDefaultEvent(selfId, bagIndex)
end

function Trade_Token:IsSkillLikeScript(selfId)
    return 1
end

function Trade_Token:CancelImpacts(selfId)
    return 0
end

function Trade_Token:OnConditionCheck(selfId)
    if not self:LuaFnVerifyUsedItem(selfId) then
        return 0
    end
    local itemTblIndex = self:LuaFnGetItemIndexOfUsedItem(selfId)
    if not self.g_Item[itemTblIndex] then
        self:Tip(selfId, "Vật phẩm không hợp lệ")
        return 0
    end
    -- 检查是否已经激活过交易令
    if self:GetMissionFlag(selfId, ScriptGlobal.MF_TRADE_TOKEN) ~= 0 then
        self:Tip(selfId, "Lệnh giao dịch đã kích hoạt, khỏi dùng lặp")
        return 0
    end
    return 1
end

function Trade_Token:OnDeplete(selfId)
    if self:LuaFnDepletingUsedItem(selfId) then
        return 1
    end
    return 1
end

function Trade_Token:OnActivateOnce(selfId)
    self:SetMissionFlag(selfId, ScriptGlobal.MF_TRADE_TOKEN, 1)
    self:Tip(selfId, "Quyền giao dịch đã mở, giờ bày sạp, mua, thu mua, giao dịch được")
    return 1
end

function Trade_Token:OnActivateEachTick(selfId)
    return 1
end

function Trade_Token:Tip(selfId, Tip)
    self:BeginEvent(self.script_id)
    self:AddText(Tip)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return Trade_Token
