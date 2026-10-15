local class = require "class"
local define = require "define"
local script_base = require "script_base"
local estudy_zhuzao = class("estudy_zhuzao", script_base)
estudy_zhuzao.script_id = 713505
estudy_zhuzao.g_MessageStudy = "Nếu như ngươi đạt tới cấp %d và chịu tốn #{_EXCHG%d} là có thể học được Kỹ năng Chúc Tạo. Ngươi quyết định học chứ?"
estudy_zhuzao.g_AbilityID = define.ABILITY_ZHUZAO
estudy_zhuzao.g_AbilityName = "Đúc"
estudy_zhuzao.g_Name1 = "耶律大石"
function estudy_zhuzao:OnDefaultEvent(selfId, targetId, ButtomNum, g_Npc_ScriptId, bid)
    local AbilityLevel = self:QueryHumanAbilityLevel(selfId, self.g_AbilityID)
    if AbilityLevel >= 1 then
        self:BeginEvent(self.script_id)
        self:AddText("Ngươi đã học được" .. self.g_AbilityName .. "Kỹ năng rồi.")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return
    end
    if bid then
        self:StudyInCity(selfId, targetId, ButtomNum, g_Npc_ScriptId, bid)
        return
    end
    if ButtomNum == 0 then
        local ret, demandMoney, demandExp, limitAbilityExp, limitAbilityExpShow, currentLevelAbilityExpTop, limitLevel, extraMoney, extraExp = self:LuaFnGetAbilityLevelUpConfig2(define.ABILITY_ZHUZAO, 1)
        if ret then
            self:BeginEvent(self.script_id)
            if self:GetName(targetId) == self.g_Name1 then
                demandMoney = extraMoney
            end
            local addText = string.format(self.g_MessageStudy, limitLevel, demandMoney)
            self:AddText(addText)
            self:AddNumText("Ta xác định muốn học", 6, 2)
            self:AddNumText("Ta chỉ đến xem thôi", 8, 3)
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        end
    elseif ButtomNum == 2 then
        local ret, demandMoney, demandExp, limitAbilityExp, limitAbilityExpShow, currentLevelAbilityExpTop, limitLevel, extraMoney, extraExp = self:LuaFnGetAbilityLevelUpConfig2(define.ABILITY_ZHUZAO, 1)
        if ret then
            if self:GetName(targetId) == self.g_Name1 then
                demandMoney = extraMoney
            end
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

function estudy_zhuzao:OnEnumerate(caller, selfId, targetId, bid)
    local AbilityLevel = self:QueryHumanAbilityLevel(selfId, self.g_AbilityID)
    if AbilityLevel >= 1 then
        return
    end
    if bid then
        local ret =  self:CallScriptFunction(define.CITY_BUILDING_ABILITY_SCRIPT, "OnCityCheck", selfId, self.g_AbilityID, bid, 5)
        if ret > 0 then
            caller:AddNumTextWithTarget(self.script_id, "Học tập" .. self.g_AbilityName .. "Kỹ Năng", 12, 0)
        end
        return
    end
    local ret = self:LuaFnGetAbilityLevelUpConfig(define.ABILITY_ZHUZAO, 1)
    if ret then
        caller:AddNumTextWithTarget(self.script_id, "Học tập" .. self.g_AbilityName .. "Kỹ Năng", 12, 0)
    end
    return
end

function estudy_zhuzao:CheckAccept()

end

function estudy_zhuzao:OnAccept()

end

function estudy_zhuzao:StudyInCity(selfId, targetId, ButtomNum, g_Npc_ScriptId, bid)
    if bid then
        if 0 == ButtomNum then
            if self:CallScriptFunction(define.CITY_BUILDING_ABILITY_SCRIPT, "CheckCityStatus", selfId, targetId) < 0 then
                return
            end
            self:BeginEvent(self.script_id)
            local lv, money, con = self:CallScriptFunction(define.CITY_BUILDING_ABILITY_SCRIPT, "OnCityAction", selfId, targetId, self.g_AbilityID, bid,4)
            local studyMsg = string.format("Nếu như ngươi đạt tới cấp %d và bằng lòng tiêu #{_EXCHG%d} và %d điểm cống hiến bang thì có thể học được." .. self.g_AbilityName .. "Kỹ năng. Ngươi quyết định học chứ?", lv, money, con)
            self:AddText(studyMsg)
            self:AddNumText("Ta xác định muốn học", 6, 2)
            self:AddNumText("Ta chỉ đến xem thôi", 8, 3)
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        elseif 2 == ButtomNum then
            local ret = self:CallScriptFunction(define.CITY_BUILDING_ABILITY_SCRIPT, "OnCityCheck", selfId, self.g_AbilityID, bid, 1)
            if ret > 0 then
                self:CallScriptFunction(define.CITY_BUILDING_ABILITY_SCRIPT, "OnCityAction", selfId, targetId, self.g_AbilityID, bid, 1)
            end
        else
            self:CallScriptFunction(g_Npc_ScriptId, "OnDefaultEvent", selfId, targetId)
        end
    end
end

return estudy_zhuzao
