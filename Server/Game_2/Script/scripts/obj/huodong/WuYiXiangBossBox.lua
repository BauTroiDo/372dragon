--圣兽山宝箱争夺
--大宝箱NPC交互脚本

--脚本号
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local WuYiXiangBossBox = class("WuYiXiangBossBox", script_base)
WuYiXiangBossBox.script_id = 3000007
--圣兽山宝箱争夺活动脚本
WuYiXiangBossBox.g_ActivityScriptId	= 3000005
--受限buff....
WuYiXiangBossBox.g_LimitiBuff = {
			50,
			112,
			1079,1080,1081,1082,1083,1084,1085,1086,1087,1088,1089,1090,
			1709,1710,1711,1712,1713,1714,1715,1716,1717,1718,1719,1720,
			7084,
			7085,
}


--**********************************
--特殊交互:条件判断
--**********************************
function WuYiXiangBossBox:OnActivateConditionCheck(selfId, activatorId )
	local strText = "Trạng thái hiện tại không thể mở"
	--无敌状态无法开启宝箱....
	if self:LuaFnIsUnbreakable(activatorId) then
		self:BeginEvent(self.script_id)
		self:AddText(strText)
		self:EndEvent()
		self:DispatchMissionTips(activatorId)
		return 0
	end

	--隐身状态无法开启宝箱....
	if self:LuaFnIsConceal(activatorId) then
		self:BeginEvent(self.script_id)
		self:AddText(strText)
		self:EndEvent()
		self:DispatchMissionTips(activatorId)
		return 0
	end

	--受限buff无法开启....
	for i, impactId in pairs(self.g_LimitiBuff) do
		if self:LuaFnHaveImpactOfSpecificDataIndex(activatorId, impactId) then
			self:BeginEvent(self.script_id)
			self:AddText(strText)
            self:EndEvent()
			self:DispatchMissionTips(activatorId)
			return 0
		end
	end

	--检测背包是否有地方....
	if self:LuaFnGetPropertyBagSpace( activatorId ) < 1 then
		self:BeginEvent(self.script_id)
        self:AddText( "Túi hành trang không đủ chỗ" )
		self:EndEvent()
		self:DispatchMissionTips(activatorId)
		return 0
	end

	--检测是否可以开大宝箱....
	local bRet, PlayerName = self:CallScriptFunction(self.g_ActivityScriptId, "CheckOpenBigBox", activatorId, selfId)
	if bRet == -1 then
		self:BeginEvent(self.script_id)
        self:AddText(PlayerName.."Đang mở bảo rương, tạm thời ngài không thể Thao tác");
        self:EndEvent()
		self:DispatchMissionTips(activatorId)
		return 0
	end
	return 1
end

--**********************************
--特殊交互:消耗和扣除处理
--**********************************
function WuYiXiangBossBox:OnActivateDeplete(selfId, activatorId)
	return 1
end

--**********************************
--特殊交互:聚气类成功生效处理
--**********************************
function WuYiXiangBossBox:OnActivateEffectOnce(selfId, activatorId)
	self:CallScriptFunction(self.g_ActivityScriptId, "OnBigBoxOpen", selfId, activatorId)
	return 1
end

--**********************************
--特殊交互:引导类每时间间隔生效处理
--**********************************
function WuYiXiangBossBox:OnActivateEffectEachTick(selfId, activatorId)
	return 1
end

--**********************************
--特殊交互:交互开始时的特殊处理
--**********************************
function WuYiXiangBossBox:OnActivateActionStart(selfId, activatorId)
	return 1
end

--**********************************
--特殊交互:交互撤消时的特殊处理
--**********************************
function WuYiXiangBossBox:OnActivateCancel(selfId, activatorId)
	return 0
end

--**********************************
--特殊交互:交互中断时的特殊处理
--**********************************
function WuYiXiangBossBox:OnActivateInterrupt(selfId, activatorId)
	self:CallScriptFunction(self.g_ActivityScriptId, "OnCancelOpenXXX", selfId, activatorId)
	return 0
end

return WuYiXiangBossBox