local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local shiwangzhengduo_box = class("shiwangzhengduo_box", script_base)
-- local gbk = require "wire_charset"
shiwangzhengduo_box.script_id = 999974
shiwangzhengduo_box.needsceneId = 315
shiwangzhengduo_box.needsactId = 396
shiwangzhengduo_box.boxid = 6
shiwangzhengduo_box.playerid = 7
--**********************************
--特殊交互:聚气类成功生效处理
--**********************************
function shiwangzhengduo_box:OnActivateEffectOnce(selfId, activatorId)
	local obj = self.scene:get_obj_by_id(selfId)
	if not obj then
		return 1
	elseif not obj:is_alive() then
		return 1
	end
	local ai = obj:get_ai()
	if ai:get_int_param_by_index(1) ~= self.scene:get_id()
	or ai:get_int_param_by_index(2) ~= self.needsactId then
		self.scene:delete_temp_monster(obj)
		return 1
	end
	local addbuff = ai:get_int_param_by_index(3)
	local bossname = obj:get_name()
	local human = self.scene:get_obj_by_id(activatorId)
	if not human then
		return 1
	end
	local name = human:get_name()
	self.scene:delete_temp_monster(obj)
	self.scene:set_param(self.playerid,activatorId + 1)
	self.scene:set_param(self.boxid,0)
	local psex = self:GetSex(activatorId)
	if psex == 0 then
		addbuff = addbuff + 1
	end
	self:LuaFnSendSpecificImpactToUnit(activatorId, activatorId, activatorId, addbuff, 100);
	self:LuaFnSendSpecificImpactToUnit(activatorId, activatorId, activatorId, addbuff + 2, 100);
	-- local scenename = self:GetSceneName()
	local msg = string.format("#PNgười chơi#B[%s]#Pmở#B%s#Ptừ giờ bị#Gđánh dấu, bị giết dấu#Gbiến mất#P, rơi tại chỗ#Bhộp#P, người mở lại được#Gđánh dấu#P, ai giữ dấu tới#Gkết thúc#Phoạt động nhận thưởng#Gthẻ nạp#Pở sứ giả Lạc Dương.",
	name,bossname)
	self:MonsterTalk(-1,"Tranh đoạt Thi Vương",msg)
	return 1
end

--**********************************
--特殊交互:条件判断
--**********************************
function shiwangzhengduo_box:OnActivateConditionCheck(selfId, activatorId )
	return 1
end
--**********************************
--特殊交互:消耗和扣除处理
--**********************************
function shiwangzhengduo_box:OnActivateDeplete(selfId, activatorId)
	return 1
end

--**********************************
--特殊交互:引导类每时间间隔生效处理
--**********************************
function shiwangzhengduo_box:OnActivateEffectEachTick(selfId, activatorId)
	return 1
end

--**********************************
--特殊交互:交互开始时的特殊处理
--**********************************
function shiwangzhengduo_box:OnActivateActionStart(selfId, activatorId)
	return 1
end

--**********************************
--特殊交互:交互撤消时的特殊处理
--**********************************
function shiwangzhengduo_box:OnActivateCancel(selfId, activatorId)
	return 0
end

--**********************************
--特殊交互:交互中断时的特殊处理
--**********************************
function shiwangzhengduo_box:OnActivateInterrupt(selfId, activatorId)
	return 0
end

return shiwangzhengduo_box