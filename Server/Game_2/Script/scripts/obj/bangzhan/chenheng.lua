local class = require "class"
local define = require "define"
local script_base = require "script_base"
local chenheng = class("chenheng", script_base)
chenheng.script_id = 402293
chenheng.g_name = "辰衡"
chenheng.g_eventId_yes = 0
chenheng.g_eventId_no = 1
function chenheng:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function chenheng:UpdateEventList(selfId, targetId)
    if self:CallScriptFunction(402047, "IsCommonAGuild", selfId) == 1 then
        self:BeginEvent(self.script_id)
        self:AddText("#{BHXZ_081103_21}")
        self:AddNumText("Xác nhận", 9, self.g_eventId_yes)
        self:AddNumText("Hủy bỏ", 8, self.g_eventId_no)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    else
        self:BeginEvent(self.script_id)
        self:AddText("#{BHXZ_081103_20}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
end

function chenheng:OnEventRequest(selfId, targetId, arg, index)
    local selectEventId = index
    if selectEventId and self:CallScriptFunction(402047, "IsCommonAGuild", selfId) == 1 then
        if selectEventId == self.g_eventId_yes then
            if self:CallScriptFunction(402047, "HaveTankBuff", selfId) == 0 then
                self:CallScriptFunction(402047, "Exit", selfId)
            else
                self:BeginEvent(self.script_id)
                self:AddText("#{BHXZ_081103_77}")
                self:EndEvent()
                self:DispatchEventList(selfId, targetId)
            end
        else
            self:BeginUICommand()
            self:UICommand_AddInt(targetId)
            self:EndUICommand()
            self:DispatchUICommand(selfId, 1000)
        end
    end
end

function chenheng:OnMissionAccept(selfId, targetId, missionScriptId)
end

function chenheng:OnMissionRefuse(selfId, targetId, missionScriptId)
end

return chenheng
