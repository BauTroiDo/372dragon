local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ScriptGlobal = require "scripts.ScriptGlobal"
local mantuo_guanshanyue = class("mantuo_guanshanyue", script_base)
mantuo_guanshanyue.script_id = 015051
function mantuo_guanshanyue:UpdateEventList(selfId, targetId)
    local AbilityLevel = self:QueryHumanAbilityLevel(selfId, 52)
    self:BeginEvent(self.script_id)
    self:AddText("#{MPSD_220622_15}")
    self:AddNumText("#{XMPSH_220628_1}", 7, 2)
    if AbilityLevel < 1 then
        self:AddNumText("#{XMPSH_220628_2}", 12, 0)
    else
        self:AddNumText("#{XMPSH_220628_3}", 12, 1)
    end
    self:AddNumText("#{XMPSH_220628_35}", 11, 100)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function mantuo_guanshanyue:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function mantuo_guanshanyue:OnEventRequest(selfId, targetId, arg, index)
    if index == 0 then
        self:BeginEvent(self.script_id)
        self:AddText("#{XMPSH_220628_5}")
        self:AddNumText("#{XMPSH_220628_6}", 6, 3)
        self:AddNumText("#{XMPSH_220628_7}", 8, 4)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
    if index == 1 then
        local AbilityLevel = self:QueryHumanAbilityLevel(selfId, 52)
        if self:GetMenPai(selfId) ~= 16 then
            self:MsgBox(selfId, targetId, "#{XMPSH_220628_4}")
            return
        end
        if AbilityLevel < 1 then
            self:MsgBox(selfId, targetId, "#{XMPSH_220628_13}")
            return
        end
        if AbilityLevel >= 10 then
            self:MsgBox(selfId, targetId, "#{XMPSH_220628_14}")
        else
            local NeedLevel = AbilityLevel + 1
            local ret, demandMoney, demandExp, limitAbilityExp, limitAbilityExpShow, currentLevelAbilityExpTop, limitLevel =
                self:LuaFnGetAbilityLevelUpConfig(52, NeedLevel)
            if ret and ret == 1 then
                self:DispatchAbilityInfo(selfId, targetId, self.g_ScriptId, 52, demandMoney, demandExp,
                    limitAbilityExpShow, limitLevel)
            end
        end
    end
    if index == 2 then
        self:DispatchShopItem(selfId, targetId, 217)
    end
    if index == 3 then
        if self:GetMenPai(selfId) ~= 16 then
            self:MsgBox(selfId, targetId, "#{XMPSH_220628_4}")
            return
        end
        local AbilityLevel = self:QueryHumanAbilityLevel(selfId, 52)
        if AbilityLevel > 0 then
            self:Tips(selfId, "#{XMPSH_220628_10}")
            return
        end
        local NeedLevel = 1
        local ret, demandMoney, demandExp, limitAbilityExp, limitAbilityExpShow, currentLevelAbilityExpTop, limitLevel =
            self:LuaFnGetAbilityLevelUpConfig(52, NeedLevel)
        self:Tips(selfId, demandMoney)
        if ret and ret == 1 then
            if self:GetMoney(selfId) + self:GetMoneyJZ(selfId) < demandMoney then
                self:Tips(selfId, "#{XMPSH_220628_8}")
                return
            end
            if self:GetLevel(selfId) < 30 then
                self:Tips(selfId, "#{XMPSH_220628_9}")
                return
            end
            self:LuaFnCostMoneyWithPriority(selfId, demandMoney)
            self:SetHumanAbilityLevel(selfId, 52, 10)
            self:MsgBox(selfId, targetId, "#{XMPSH_220628_11}")
        end
    end
    if index == 4 then
        self:BeginUICommand()
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
    end
    if index == 100 then
        self:MsgBox(selfId, targetId, "#{XMPSH_220628_31}")
        return
    end
end

function mantuo_guanshanyue:MsgBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function mantuo_guanshanyue:Tips(selfId, tip)
    self:BeginEvent(self.script_id)
    self:AddText(tip)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return mantuo_guanshanyue
