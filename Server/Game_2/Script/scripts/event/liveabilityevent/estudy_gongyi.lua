local class = require "class"
local define = require "define"
local script_base = require "script_base"
local estudy_gongyi = class("estudy_gongyi", script_base)
estudy_gongyi.script_id = 713507
estudy_gongyi.g_MessageStudy = "Nếu ngươi đạt cấp %d và chịu bỏ ra #{_EXCHG%d} là có thể học được Công Nghệ Kỹ năng. Ngươi quyết định học chứ?"
estudy_gongyi.g_AbilityID = define.ABILITY_GONGYI
estudy_gongyi.g_AbilityName = "Thủ công"
estudy_gongyi.g_Name1 = "阮星竹"
function estudy_gongyi:OnDefaultEvent(selfId, targetId, ButtomNum, g_Npc_ScriptId, bid)
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
        local ret, demandMoney, demandExp, limitAbilityExp, limitAbilityExpShow, currentLevelAbilityExpTop, limitLevel, extraMoney, extraExp = self:LuaFnGetAbilityLevelUpConfig2(define.ABILITY_GONGYI, 1)
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
        local ret, demandMoney, demandExp, limitAbilityExp, limitAbilityExpShow, currentLevelAbilityExpTop, limitLevel, extraMoney, extraExp = self:LuaFnGetAbilityLevelUpConfig2(define.ABILITY_GONGYI, 1)
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

function estudy_gongyi:OnEnumerate(caller, selfId, targetId, bid)
    if bid then
        local ret =  self:CallScriptFunction(define.CITY_BUILDING_ABILITY_SCRIPT, "OnCityCheck", selfId, self.g_AbilityID, bid, 5)
        if ret > 0 then
            caller:AddNumTextWithTarget(self.script_id, "Học tập" .. self.g_AbilityName .. "Kỹ Năng", 12, 0)
        end
        return
    end
    local ret = self:LuaFnGetAbilityLevelUpConfig(define.ABILITY_GONGYI, 1)
    if ret then
        caller:AddNumTextWithTarget(self.script_id, "Học tập" .. self.g_AbilityName .. "Kỹ Năng", 12, 0)
    end
    return
end

function estudy_gongyi:CheckAccept()

end

function estudy_gongyi:OnAccept()

end

function estudy_gongyi:StudyInCity(selfId, targetId, ButtomNum, g_Npc_ScriptId, bid)
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

return estudy_gongyi
