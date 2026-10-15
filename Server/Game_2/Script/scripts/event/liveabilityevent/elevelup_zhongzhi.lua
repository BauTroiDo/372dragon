local class = require "class"
local define = require "define"
local script_base = require "script_base"
local elevelup_zhongzhi = class("elevelup_zhongzhi", script_base)
elevelup_zhongzhi.script_id = 713570
elevelup_zhongzhi.g_nMaxLevel = 5
elevelup_zhongzhi.g_AbilityID = define.ABILITY_ZHONGZHI
elevelup_zhongzhi.g_AbilityName = "Trồng trọt"
function elevelup_zhongzhi:OnDefaultEvent(selfId, targetId, num, npc_script_id, bid)
    local AbilityLevel = self:QueryHumanAbilityLevel(selfId, self.g_AbilityID)
    if AbilityLevel < 1 then
        self:BeginEvent(self.script_id)
        local strText = "Ngươi còn chưa học được".. self.g_AbilityName.."Kỹ năng!"
        self:AddText(strText)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if bid then
		--检查城市是否处于低维护状态
		if self:CallScriptFunction(define.CITY_BUILDING_ABILITY_SCRIPT, "CheckCityStatus", selfId,targetId) < 0 then
			return
		end
		local ret = self:CallScriptFunction(define.CITY_BUILDING_ABILITY_SCRIPT, "OnCityCheck", selfId, self.g_AbilityID, bid, 2)
		if ret then
			self:CallScriptFunction(define.CITY_BUILDING_ABILITY_SCRIPT, "OnCityAction", selfId, targetId, self.g_AbilityID, bid, 2)
		end
		return
	end
    if AbilityLevel >= self.g_nMaxLevel then
        self:BeginEvent(self.script_id)
        local strText = "Ta chỉ có thể dạy ngươi cấp 1-5 của" .. self.g_AbilityName .. "Kỹ năng, thỉnh đến bang phái học tập Kỹ năng Cao cấp của".. self.g_AbilityName.. "."
        self:AddText(strText)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    else
        local tempAbilityId = self.g_AbilityID
        local tempAbilityLevel = AbilityLevel + 1
        local ret, demandMoney, demandExp, limitAbilityExp, limitAbilityExpShow, currentLevelAbilityExpTop, limitLevel =
            self:LuaFnGetAbilityLevelUpConfig(tempAbilityId, tempAbilityLevel)
        if ret then
            self:DispatchAbilityInfo(selfId, targetId, self.script_id, tempAbilityId, demandMoney, demandExp,
                limitAbilityExpShow, limitLevel)
        end
    end
end

function elevelup_zhongzhi:OnEnumerate(caller, selfId, targetId, arg, index)
    caller:AddNumTextWithTarget(self.script_id, "Thăng cấp".. self.g_AbilityName.. "Kỹ Năng", 12, 1)
end

function elevelup_zhongzhi:CheckAccept(selfId)

end

return elevelup_zhongzhi
