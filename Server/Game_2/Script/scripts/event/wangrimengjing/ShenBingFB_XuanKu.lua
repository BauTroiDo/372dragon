local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ShenBingFB_XuanKu = class("ShenBingFB_XuanKu", script_base)
ShenBingFB_XuanKu.script_id = 801807
ShenBingFB_XuanKu.g_FuBenScriptId = 801801
ShenBingFB_XuanKu.g_LimitMembers = 3
function ShenBingFB_XuanKu:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
        self:AddText("#{SBRC_20230627_62}")
        self:AddNumText("#{SBRC_20230627_125}", 10, 1)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function ShenBingFB_XuanKu:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function ShenBingFB_XuanKu:OnEventRequest(selfId, targetId, arg, index)
	local nCurMainStep = self:LuaFnGetCopySceneData_Param(8)
    if index == 1 then
        if self:GetName(targetId) ~= "玄苦" then
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
		if nCurMainStep ~= 7 then
			self:notify_tips(selfId,"#{SBRC_20230627_122}")
			self:MsgBox(selfId,targetId,"#{SBRC_20230627_123}")
			return
		end
		self:CallScriptFunction(801801, "CreateBoss",4,203,55)
        self:LuaFnDeleteMonster(targetId)
        self:BeginUICommand()
        self:EndUICommand()
        self:DispatchUICommand(selfId,1000)
        return
    end
end

return ShenBingFB_XuanKu
