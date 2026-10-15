local class = require "class"
local define = require "define"
local script_base = require "script_base"
local hukai = class("hukai", script_base)
hukai.script_id = 402297
hukai.g_name = "胡凯"
hukai.g_eventId_yes = 0
hukai.g_eventId_no = 1
function hukai:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function hukai:UpdateEventList(selfId, targetId)
    if self:CallScriptFunction(402047, "IsCommonBGuild", selfId) == 1 then
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

function hukai:OnEventRequest(selfId, targetId, arg, index)
    local selectEventId = index
    if selectEventId and self:CallScriptFunction(402047, "IsCommonBGuild", selfId) == 1 then
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

function hukai:OnMissionAccept(selfId, targetId, missionScriptId)
end

function hukai:OnMissionRefuse(selfId, targetId, missionScriptId)
end

return hukai
