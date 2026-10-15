local ScriptGlobal = require "scripts.ScriptGlobal"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local common_item = class("common_item", script_base)

function common_item:IsSkillLikeScript()
    return 1
end

function common_item:CancelImpacts()
    return 0
end

function common_item:OnConditionCheck(selfId)
	if not self:LuaFnVerifyUsedItem(selfId) then
		return 0
	end
    local useitemid = self:LuaFnGetItemIndexOfUsedItem(selfId)
    if useitemid == 38000213 then
        return self:CallScriptFunction(998526, "CanActivate", selfId, 0) and 1 or 0
    end
    -- local enddate = self:GetMissionData(selfId, ScriptGlobal.MD_YU_LONG_TIE_END_TIME)
    -- local nowdate = self:GetTime2Day2()
    -- if enddate > nowdate then
        -- self:notify_tips(selfId, "#{HJYK_201223_03}")
        -- return 0
    -- end
	return 1
end

function common_item:OnDeplete(selfId)
    return 1
end

function common_item:OnActivateOnce(selfId)
    local useitemid = self:LuaFnGetItemIndexOfUsedItem(selfId)
	if useitemid == 38000205 or useitemid == 38000221 then
		self:BeginUICommand()
		self:EndUICommand()
		self:DispatchUICommand(selfId, 89266601)
	elseif useitemid == 38000220 then
		self:CallScriptFunction((892666), "OnUseMonthCard2", selfId)
		-- self:BeginUICommand()
		-- self:EndUICommand()
		-- self:DispatchUICommand(selfId, 89266699)
	elseif useitemid == 38000213 then
		return self:CallScriptFunction(998526, "ActiveYueKa", selfId, 2) and 1 or 0
	end
	return 1
end

return common_item
