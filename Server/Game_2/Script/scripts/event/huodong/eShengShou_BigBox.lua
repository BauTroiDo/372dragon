--圣兽山宝箱争夺
--大宝箱NPC交互脚本

--脚本号
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local eShengShou_BigBox = class("eShengShou_BigBox", script_base)
eShengShou_BigBox.script_id = 808067
--圣兽山宝箱争夺活动脚本
eShengShou_BigBox.g_ActivityScriptId	= 808066
--受限buff....
eShengShou_BigBox.g_LimitiBuff = {
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
function eShengShou_BigBox:OnActivateConditionCheck(selfId, activatorId )
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
	if self:CallScriptFunction(self.g_ActivityScriptId, "CheckOpenBigBox", activatorId,selfId) then
		return 1
	end
	return 0
end

--**********************************
--特殊交互:消耗和扣除处理
--**********************************
function eShengShou_BigBox:OnActivateDeplete(selfId, activatorId)
	return 1
end

--**********************************
--特殊交互:聚气类成功生效处理
--**********************************
function eShengShou_BigBox:OnActivateEffectOnce(selfId, activatorId)
	self:CallScriptFunction(self.g_ActivityScriptId, "OnBigBoxOpen", selfId, activatorId)
	return 1
end

--**********************************
--特殊交互:引导类每时间间隔生效处理
--**********************************
function eShengShou_BigBox:OnActivateEffectEachTick(selfId, activatorId)
	return 1
end

--**********************************
--特殊交互:交互开始时的特殊处理
--**********************************
function eShengShou_BigBox:OnActivateActionStart(selfId, activatorId)
	return 1
end

--**********************************
--特殊交互:交互撤消时的特殊处理
--**********************************
function eShengShou_BigBox:OnActivateCancel(selfId, activatorId)
	return 0
end

--**********************************
--特殊交互:交互中断时的特殊处理
--**********************************
function eShengShou_BigBox:OnActivateInterrupt(selfId, activatorId)
	self:CallScriptFunction(self.g_ActivityScriptId, "OnCancelOpen",selfId)
	return 0
end

function eShengShou_BigBox:OnDie(objId, killerId)
	local scene = self:get_scene()
	local obj = scene:get_obj_by_id(objId)
	if not obj or obj:get_obj_type() ~= "monster" then
		return
	end
	local sceneId = scene:get_id()
	if sceneId == 394 then
		if obj:get_scene_params(define.MONSTER_DATAID) == 5011 then
			local respawn_time = obj:get_scene_params(define.MONSTER_KILLBOX_PROTECT_TIME)
			if respawn_time > 0 then
				local create_index = obj:get_scene_params(define.MONSTER_CREATE_INDEX)
				local curtime = os.time() + respawn_time
				scene:set_param(create_index,curtime)
			end
		end
	end
end

return eShengShou_BigBox