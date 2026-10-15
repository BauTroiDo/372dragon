local class = require "class"
local define = require "define"
local script_base = require "script_base"
local mantuo_wangshuifeng = class("mantuo_wangshuifeng", script_base)
mantuo_wangshuifeng.script_id = 015052
function mantuo_wangshuifeng:UpdateEventList(selfId, targetId)
    local AbilityLevel = self:QueryHumanAbilityLevel(selfId, 53)
    self:BeginEvent(self.script_id)
    self:AddText("#{MPSD_220622_17}")
    if AbilityLevel < 1 then
        self:AddNumText("#{XMPSH_220628_16}", 12, 0)
    end
    self:AddNumText("#{XMPSH_220628_17}", 12, 1)
    self:AddNumText("#{XMPSH_220628_15}", 11, 100)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function mantuo_wangshuifeng:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function mantuo_wangshuifeng:OnEventRequest(selfId, targetId, arg, index)
    if index == 0 then
        self:BeginEvent(self.script_id)
        self:AddText("#{XMPSH_220628_19}")
        self:AddNumText("#{XMPSH_220628_6}", 6, 2)
        self:AddNumText("#{XMPSH_220628_7}", 8, 3)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
    if index == 1 then
        local AbilityLevel = self:QueryHumanAbilityLevel(selfId, 53)
        if self:GetMenPai(selfId) ~= 10 then
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
            local ret, demandMoney, demandExp, limitAbilityExp, limitAbilityExpShow, currentLevelAbilityExpTop, limitLevel =
            self:LuaFnGetAbilityLevelUpConfig(53, AbilityLevel + 1)
            if ret and ret == 1 then
                self:DispatchAbilityInfo(selfId, targetId, self.g_ScriptId, 53, demandMoney,
                    demandExp, limitAbilityExpShow, limitLevel)
            end
        end
    end
    if index == 2 then
        if self:GetMenPai(selfId) ~= 16 then
            self:MsgBox(selfId, targetId, "#{XMPSH_220628_4}")
            return
        end
        local AbilityLevel = self:QueryHumanAbilityLevel(selfId, 53)
        if AbilityLevel > 0 then
            self:Tips(selfId, "#{XMPSH_220628_10}")
            return
        end
        local ret, demandMoney, demandExp, limitAbilityExp, limitAbilityExpShow, currentLevelAbilityExpTop, limitLevel =
        self:LuaFnGetAbilityLevelUpConfig(53, 1)
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
            self:SetHumanAbilityLevel(selfId, 53, 10)
            self:MsgBox(selfId, targetId, "#{XMPSH_220628_20}")
        end
    end
    if index == 3 then
        self:BeginUICommand()
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
    end
    if index == 100 then
        self:MsgBox(selfId, targetId, "#{XMPSH_220628_34}")
        return
    end
end

function mantuo_wangshuifeng:MsgBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function mantuo_wangshuifeng:Tips(selfId, tip)
    self:BeginEvent(self.script_id)
    self:AddText(tip)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return mantuo_wangshuifeng
