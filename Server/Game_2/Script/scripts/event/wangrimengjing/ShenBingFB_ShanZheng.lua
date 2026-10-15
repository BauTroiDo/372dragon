local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ShenBingFB_ShanZheng = class("ShenBingFB_ShanZheng", script_base)
ShenBingFB_ShanZheng.script_id = 801805
ShenBingFB_ShanZheng.g_FuBenScriptId = 801801
ShenBingFB_ShanZheng.g_LimitMembers = 3
function ShenBingFB_ShanZheng:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
        self:AddText("#{SBRC_20230627_124}")
        self:AddNumText("#{SBRC_20230627_125}", 10, 1)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function ShenBingFB_ShanZheng:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function ShenBingFB_ShanZheng:OnEventRequest(selfId, targetId, arg, index)
	local nCurMainStep = self:LuaFnGetCopySceneData_Param(8)
	local SmallNum = self:LuaFnGetCopySceneData_Param(9)
    if index == 1 then
        if self:GetName(targetId) ~= "单正" then
            return
        end
        if self:GetLevel(selfId) < 65 then
            self:notify_tips(selfId,"#{SBRC_20230627_65}")
            return
        end
        if not self:LuaFnHasTeam(selfId) then
			self:notify_tips(selfId,"#{SBRC_20230627_66}")
			self:MsgBox(selfId,targetId,"#{SBRC_20230627_67}")
            return
        end
        if not self:LuaFnIsTeamLeader(selfId) then
			self:notify_tips(selfId,"#{SBRC_20230627_68}")
			self:MsgBox(selfId,targetId,"#{SBRC_20230627_69}")
            return
        end
        if self:GetTeamSize(selfId) < self.g_LimitMembers then
			self:MsgBox(selfId,targetId,"#{SBRC_20230627_71}")
            return
        end
        local NearTeamSize = self:GetNearTeamCount(selfId)
        if self:GetTeamSize(selfId) ~= NearTeamSize then
			self:notify_tips(selfId,"#{SBRC_20230627_70}")
            return
        end
		if nCurMainStep ~= 3 then
			self:notify_tips(selfId,"#{SBRC_20230627_118}")
			self:MsgBox(selfId,targetId,"#{SBRC_20230627_119}")
			return
		end
		local nPosX,nPosZ = self:GetWorldPos(targetId)
		self:CallScriptFunction(801801, "CreateBoss",2,70,63)
        self:LuaFnDeleteMonster(targetId)
        self:BeginUICommand()
        self:EndUICommand()
        self:DispatchUICommand(selfId,1000)
        return
    end
end

return ShenBingFB_ShanZheng
