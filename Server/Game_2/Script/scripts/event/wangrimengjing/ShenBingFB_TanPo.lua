local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ShenBingFB_TanPo = class("ShenBingFB_TanPo", script_base)
ShenBingFB_TanPo.script_id = 801806
ShenBingFB_TanPo.g_FuBenScriptId = 801801
ShenBingFB_TanPo.g_LimitMembers = 3
function ShenBingFB_TanPo:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
        self:AddText("#{SBRC_20230627_91}")
        self:AddNumText("#{SBRC_20230627_125}", 10, 1)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function ShenBingFB_TanPo:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function ShenBingFB_TanPo:OnEventRequest(selfId, targetId, arg, index)
	local nCurMainStep = self:LuaFnGetCopySceneData_Param(8)
    if index == 1 then
        if self:GetName(targetId) ~= "谭婆" then
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
		if nCurMainStep ~= 5 then
			self:notify_tips(selfId,"#{SBRC_20230627_120}")
			self:MsgBox(selfId,targetId,"#{SBRC_20230627_121}")
			return
		end
		self:CallScriptFunction(801801, "CreateBoss",3,198,198)
        self:LuaFnDeleteMonster(targetId)
        self:BeginUICommand()
        self:EndUICommand()
        self:DispatchUICommand(selfId,1000)
        return
    end
end

return ShenBingFB_TanPo
