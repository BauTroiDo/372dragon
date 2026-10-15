local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ShenBingFB_BaiShiJing = class("ShenBingFB_BaiShiJing", script_base)
ShenBingFB_BaiShiJing.script_id = 801804
ShenBingFB_BaiShiJing.g_LimitMembers = 3
function ShenBingFB_BaiShiJing:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
        self:AddText("#{SBRC_20230627_64}")
        self:AddNumText("#{SBRC_20230627_125}", 10, 1)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function ShenBingFB_BaiShiJing:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function ShenBingFB_BaiShiJing:OnEventRequest(selfId, targetId, arg, index)
    if index == 1 then
        if self:GetName(targetId) ~= "白世镜" then
            return
        end
        if self:GetLevel(selfId) < 65 then
            self:notify_tips(selfId,"#{SBRC_20230627_65}")
            return
        end
        if not self:LuaFnHasTeam(selfId) then
			self:notify_tips(selfId,"#{SBRC_20230627_66}")
            return
        end
        if not self:LuaFnIsTeamLeader(selfId) then
			self:notify_tips(selfId,"#{SBRC_20230627_68}")
			self:MsgBox(selfId,targetId,"#{SBRC_20230627_69}")
            return
        end
        if self:GetTeamSize(selfId) < self.g_LimitMembers then
			self:MsgBox(selfId,targetId,"#{SBRC_20230627_67}")
			self:MsgBox(selfId,targetId,"#{SBRC_20230627_71}")
            return
        end
        local NearTeamSize = self:GetNearTeamCount(selfId)
        if self:GetTeamSize(selfId) ~= NearTeamSize then
			self:notify_tips(selfId,"#{SBRC_20230627_70}")
            return
        end
		self:CallScriptFunction(801801, "CreateBoss",1,71,195)
		self:LuaFnDeleteMonster(targetId)
        self:BeginUICommand()
        self:EndUICommand()
        self:DispatchUICommand(selfId,1000)
        return
    end
end

return ShenBingFB_BaiShiJing
