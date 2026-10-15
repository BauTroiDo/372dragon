local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ScriptGlobal = require "scripts.ScriptGlobal"
local mantuo_qifushi = class("mantuo_qifushi", script_base)
mantuo_qifushi.script_id = 015041
function mantuo_qifushi:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{MPSD_220622_92}")
    self:AddNumText("#{MPSD_220622_93}", 6, 1)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function mantuo_qifushi:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function mantuo_qifushi:OnEventRequest(selfId, targetId, arg, index)
    local nIndex = index
    if nIndex == 1 then
        if self:GetMissionFlag(selfId, ScriptGlobal.MF_TODAYQIFU_FLAG) > 0 then
            self:MsgBox(selfId, "#{MPSD_220622_130}")
            return
        end
        if self:get_scene_id() ~= 435 then
            self:MsgBox(selfId, "#{MPSD_220622_94}")
            return
        end
        if self:LuaFnIsStalling(selfId) == 1 then
            self:MsgBox(selfId, "#{MPSD_220622_100}")
            return
        end
        if self:LuaFnHasTeam(selfId) >= 1 then
            self:MsgBox(selfId, "#{MPSD_220622_99}")
            return
        end
        if self:LuaFnIsRiding(selfId) == 1 then
            self:MsgBox(selfId, "#{MPSD_220622_97}")
            return
        end
        if self:LuaFnIsModelOrMount(selfId) == 1 then
            self:MsgBox(selfId, "#{MPSD_220622_98}")
            return
        end
        self:LuaFnHumanUseSkill(selfId, 899, -1, -1, -1, -1)
        self:MsgBox(selfId, "#{MPSD_220622_101}")
        local nRandom = math.random(1, 5)
        local TextInfo = { "#{MPSD_220622_125}", "#{MPSD_220622_126}", "#{MPSD_220622_127}", "#{MPSD_220622_128}",
            "#{MPSD_220622_129}" }
        self:BroadMsgByChatPipe(selfId, TextInfo[nRandom], 0)
    end
end

function mantuo_qifushi:MsgBox(selfId, str)
    self:BeginEvent(self.script_id)
    self:AddText(str)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return mantuo_qifushi
