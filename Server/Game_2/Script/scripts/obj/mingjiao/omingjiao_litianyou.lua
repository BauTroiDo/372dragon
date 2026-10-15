local class = require "class"
local define = require "define"
local script_base = require "script_base"
local omingjiao_litianyou = class("omingjiao_litianyou", script_base)
omingjiao_litianyou.script_id = 011011
function omingjiao_litianyou:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{QXQS_130106_04}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function omingjiao_litianyou:OnEventRequest(selfId, targetId, arg, index)
    if index == 100 then
        self:BeginEvent(self.script_id)
        self:AddText("#{function_help_013}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 40 then
        self:BeginEvent(self.script_id)
        self:AddText("#{XXQS_01}")
        self:AddNumText("là", -1, 0)
        self:AddNumText("không", -1, 999)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 60 then
        self:BeginEvent(self.script_id)
        self:AddText("#{XXQS_02}")
        self:AddNumText("là", -1, 1)
        self:AddNumText("không", -1, 999)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 999 then
        self:BeginUICommand()
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
        return
    end
    local level = self:GetLevel(selfId)
    local skill = index
    if skill == 0 or skill == 1 then
        self:CallScriptFunction((210299), "OnDefaultEvent", selfId, targetId, level, skill)
    end
end

return omingjiao_litianyou
