--烹饪技能升级
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local elevelup_zhuzao = class("elevelup_zhuzao", script_base)
elevelup_zhuzao.script_id = 713564
elevelup_zhuzao.g_nMaxLevel = 5
elevelup_zhuzao.g_AbilityID = define.ABILITY_ZHUZAO
elevelup_zhuzao.g_AbilityName = "Đúc"
elevelup_zhuzao.g_Name1 = "耶律大石"

--**********************************
--任务入口函数
--**********************************
function elevelup_zhuzao:OnDefaultEvent(selfId, targetId, nNum, npcScriptId, bid )
	--玩家技能的等级
	local AbilityLevel = self:QueryHumanAbilityLevel(selfId, self.g_AbilityID)
	--玩家加工技能的熟练度
	--任务判断
	--如果是在城市中升级
	if bid then
		local ret = self:CallScriptFunction( define.CITY_BUILDING_ABILITY_SCRIPT, "OnCityCheck", selfId, self.g_AbilityID, bid, 2)
		if ret then
			self:CallScriptFunction(define.CITY_BUILDING_ABILITY_SCRIPT, "OnCityAction", selfId, targetId, self.g_AbilityID, bid, 2)
		end
		return
	end

	--如果还没有学会该生活技能
	if AbilityLevel < 1	then
		self:BeginEvent(self.scirpt_id)
		local strText = "Ngươi còn chưa học được"..self.g_AbilityName.."Kỹ năng!"
		self:AddText(strText)
		self:EndEvent()
		self:DispatchEventList(selfId,targetId)
		return
	end

    local MaxLevel = self.g_nMaxLevel
	if self:GetName(targetId) == self.g_Name1 then
		MaxLevel = 10
	end

	--如果生活技能等级已经超出该npc所能教的范围
	if AbilityLevel >= MaxLevel then
		self:BeginEvent()
        local strText
        if self:GetName(targetId) == self.g_Name1   then
            strText = "Ta chỉ có thể dạy ngươi cấp 1-10 của".. self.g_AbilityName.."Kỹ năng."
        else
            strText = "Ta chỉ có thể dạy ngươi cấp 1-5 của"..elevelup_zhuzao.g_AbilityName.."Kỹ năng, xin hãy đến Băng Hội hoặc tìm #YGia Luật Đại Thạch#G (Lạc Dương#{_INFOAIM118,62,0,Gia Luật Đại Thạch})#W có tạo nghệ tinh xảo hơn để học Cao cấp hơn."..elevelup_zhuzao.g_AbilityName.."."
        end
	    self:AddText(strText)
		self:EndEvent()
		self:DispatchEventList(selfId,targetId)
	else
		local ret, demandMoney, demandExp, limitAbilityExp, limitAbilityExpShow, currentLevelAbilityExpTop, limitLevel, extraMoney, extraExp = self:LuaFnGetAbilityLevelUpConfig(self.g_AbilityID, AbilityLevel + 1)
        if self:GetName(targetId) == self.g_Name1   then
			demandMoney = extraMoney
			demandExp =	extraExp
		end
        if ret then
			self:DispatchAbilityInfo(selfId, targetId,self.script_id, elevelup_zhuzao.g_AbilityID, demandMoney, demandExp, limitAbilityExpShow, limitLevel)
		end
	end
end

--**********************************
--列举事件
--**********************************
function elevelup_zhuzao:OnEnumerate(caller, selfId, targetId, bid )
	if bid then
		local ret = self:CallScriptFunction( define.CITY_BUILDING_ABILITY_SCRIPT, "OnCityCheck", selfId, elevelup_zhuzao.g_AbilityID, bid, 6)
		if ret then
            caller:AddNumTextWithTarget(self.script_id,"Thăng cấp"..elevelup_zhuzao.g_AbilityName.."Kỹ Năng", 12, 1) end
		return
	end
	local ret, demandMoney, demandExp, limitAbilityExp, limitAbilityExpShow, currentLevelAbilityExpTop, limitLevel = self:LuaFnGetAbilityLevelUpConfig(self.g_AbilityID, 1);
	if ret then
		caller:AddNumTextWithTarget(self.script_id,"Thăng cấp"..elevelup_zhuzao.g_AbilityName.."Kỹ Năng", 12, 1)
	end
	return
end

--**********************************
--检测接受条件
--**********************************
function elevelup_zhuzao:CheckAccept(selfId)
end

return elevelup_zhuzao