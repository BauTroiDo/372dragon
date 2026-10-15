local class = require "class"
local define = require "define"
local script_base = require "script_base"
local fuben_zhenshoujindi_BOSS_1_NPC = class("fuben_zhenshoujindi_BOSS_1_NPC", script_base)
fuben_zhenshoujindi_BOSS_1_NPC.script_id = 893022
fuben_zhenshoujindi_BOSS_1_NPC.g_LimitMembers = 1
function fuben_zhenshoujindi_BOSS_1_NPC:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    local nCurStep = self:LuaFnGetCopySceneData_Param(8)
    if nCurStep == 5 or nCurStep == 6 then
        self:AddText("#{ZSFB_20220105_48}")
        self:AddNumText("#{ZSFB_20220105_49}", 10, 1)
    else
        self:AddText("#{ZSFB_20220105_57}")
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function fuben_zhenshoujindi_BOSS_1_NPC:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function fuben_zhenshoujindi_BOSS_1_NPC:OnEventRequest(selfId, targetId, arg, index)
    if index == 1 then
        if self:GetName(targetId) ~= "云卷舒" then
            return
        end
        if self:GetLevel(selfId) < 65 then
            self:BeginEvent(self.script_id)
            self:AddText("#{ZSFB_20220105_50}")
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            return
        end
        if not self:LuaFnHasTeam(selfId) then
            self:BeginEvent(self.script_id)
            self:AddText("#{ZSFB_20220105_51}")
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            self:BeginEvent(self.script_id)
            self:AddText("#{ZSFB_20220105_52}")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
            return
        end
        if not self:LuaFnIsTeamLeader(selfId) then
            self:BeginEvent(self.script_id)
            self:AddText("#{ZSFB_20220105_53}")
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            self:BeginEvent(self.script_id)
            self:AddText("#{ZSFB_20220105_54}")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
            return
        end
        if self:GetTeamSize(selfId) < self.g_LimitMembers then
            self:BeginEvent(self.script_id)
            self:AddText("#{ZSFB_20220105_55}")
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            self:BeginEvent(self.script_id)
            self:AddText("#{ZSFB_20220105_56}")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
            return
        end
        local NearTeamSize = self:GetNearTeamCount(selfId)
        if self:GetTeamSize(selfId) ~= NearTeamSize then
            self:BeginEvent(self.script_id)
            self:AddText("#{ZSFB_20220105_55}")
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            self:BeginEvent(self.script_id)
            self:AddText("#{ZSFB_20220105_56}")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
            return
        end
        local nCurStep = self:LuaFnGetCopySceneData_Param(8)
        if nCurStep == 5 or nCurStep == 6 then
            self:LuaFnSetCopySceneData_Param(8, 7)
        end
        self:BeginUICommand()
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
        return
    end
end

return fuben_zhenshoujindi_BOSS_1_NPC
