local class = require "class"
local define = require "define"
local script_base = require "script_base"
local jiantao = class("jiantao", script_base)
jiantao.script_id = 402304
jiantao.g_name = "½£èº"
jiantao.g_eventId_yes = 0
jiantao.g_eventId_no = 1
jiantao.g_Exit_SceneID = 0
jiantao.g_Win_X = 160
jiantao.g_Win_Z = 106
jiantao.g_Fail_X = 61
jiantao.g_Fail_Z = 134
jiantao.g_SheepBuff = 31550
function jiantao:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function jiantao:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{BHXZ_081210_158}")
    self:AddNumText("#{BHXZ_081210_159}", 4, self.g_eventId_yes)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function jiantao:OnEventRequest(selfId, targetId, arg, index)
    local selectEventId = index
    if selectEventId == self.g_eventId_yes then
        if self:LuaFnHaveImpactOfSpecificDataIndex(selfId, self.g_SheepBuff) then
            self:NewWorld(selfId, self.g_Exit_SceneID, nil, self.g_Fail_X, self.g_Fail_Z)
        else
            self:NewWorld(selfId, self.g_Exit_SceneID, nil, self.g_Win_X, self.g_Win_Z)
        end
    else
    end
end

function jiantao:OnMissionAccept(selfId, targetId, missionScriptId)
end

function jiantao:OnMissionRefuse(selfId, targetId, missionScriptId)
end

return jiantao
