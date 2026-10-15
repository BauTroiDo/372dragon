local class = require "class"
local define = require "define"
local script_base = require "script_base"
local estudy_lianhualuo = class("estudy_lianhualuo", script_base)
estudy_lianhualuo.script_id = 713531
estudy_lianhualuo.g_MessageStudy = "Nếu ngươi đạt cấp %d và chịu tốn#{_EXCHG%d}thì học được Liên Hoa Lạc. Quyết định học chứ?"
estudy_lianhualuo.g_AbilityID = define.ABILITY_LIANHUALUO
estudy_lianhualuo.g_AbilityName = "Liên Hoa Lạc"
function estudy_lianhualuo:OnDefaultEvent(selfId, targetId, ButtomNum, g_Npc_ScriptId)
    local AbilityLevel = self:QueryHumanAbilityLevel(selfId, self.g_AbilityID)
    if AbilityLevel >= 1 then
        self:BeginEvent(self.script_id)
        self:AddText("Ngươi đã học được" .. self.g_AbilityName .. "Kỹ năng rồi.")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return
    end
    if ButtomNum == 0 then
        local ret, demandMoney, demandExp, limitAbilityExp, limitAbilityExpShow, currentLevelAbilityExpTop, limitLevel, extraMoney, extraExp = self:LuaFnGetAbilityLevelUpConfig2(define.ABILITY_NIANGJIU, 1)
        if ret then
            self:BeginEvent(self.script_id)
            local addText = string.format(self.g_MessageStudy, limitLevel, demandMoney)
            self:AddText(addText)
            self:AddNumText("Ta xác định muốn học", 6, 2)
            self:AddNumText("Ta chỉ đến xem thôi", 8, 3)
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        end
    elseif ButtomNum == 2 then
        local ret, demandMoney, demandExp, limitAbilityExp, limitAbilityExpShow, currentLevelAbilityExpTop, limitLevel, extraMoney, extraExp = self:LuaFnGetAbilityLevelUpConfig2(define.ABILITY_NIANGJIU, 1)
        if ret then
            if self:GetMoney(selfId) + self:GetMoneyJZ(selfId) < demandMoney then
                self:BeginEvent(self.script_id)
                self:AddText("Kim ngân của ngươi không đủ.")
                self:EndEvent()
                self:DispatchMissionTips(selfId)
                return
            end
            if self:GetLevel(selfId) < limitLevel then
                self:BeginEvent(self.script_id)
                self:AddText("Cấp độ của ngươi chưa đủ")
                self:EndEvent()
                self:DispatchMissionTips(selfId)
                return
            end
            if self:GetMenPai(selfId) ~= define.MENPAI_ATTRIBUTE.MATTRIBUTE_GAIBANG then
                self:BeginEvent(self.script_id)
                self:AddText("Ngươi không phải là đệ tử bổn phái, ta không thể dạy ngươi.");
                self:EndEvent()
                self:DispatchEventList(selfId,targetId)
                return
            end
            self:LuaFnCostMoneyWithPriority(selfId, demandMoney)
            self:SetHumanAbilityLevel(selfId, self.g_AbilityID, 10)
            self:BeginEvent(self.script_id)
            self:AddText("Ngươi đã học được" .. self.g_AbilityName .. "Kỹ Năng")
            self:EndEvent()
            self:LuaFnAuditLearnLifeAbility(selfId, self.g_AbilityID)
            self:DispatchEventList(selfId, targetId)
        end
    else
        self:CallScriptFunction(g_Npc_ScriptId, "OnDefaultEvent", selfId, targetId)
    end
end

function estudy_lianhualuo:OnEnumerate(caller, selfId, targetId, bid)
    caller:AddNumTextWithTarget(self.script_id, "Học tập" .. self.g_AbilityName .. "Kỹ Năng", 12, 0)
end

function estudy_lianhualuo:CheckAccept()

end

function estudy_lianhualuo:OnAccept()

end

return estudy_lianhualuo
