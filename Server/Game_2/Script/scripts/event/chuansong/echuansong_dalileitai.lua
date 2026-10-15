-- 大理擂台副本传送点
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local echuansong_dalileitai = class("echuansong_dalileitai", script_base)
echuansong_dalileitai.script_id = 400917
echuansong_dalileitai.ChallengeScriptId = 806014

-- 玩家进入传送点
function echuansong_dalileitai:OnEnterArea( sceneId, selfId )
	self:CallScriptFunction(self.ChallengeScriptId, "LeaveScene", sceneId, selfId )
end

-- 玩家停留在传送点
function echuansong_dalileitai:OnTimer( sceneId, selfId )
	return
end

-- 玩家离开传送点
function echuansong_dalileitai:OnLeaveArea( sceneId, selfId )
	return
end
