local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ogaibang_jiangguangting = class("ogaibang_jiangguangting", script_base)
ogaibang_jiangguangting.script_id = 010010
function ogaibang_jiangguangting:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{QXQS_130106_05}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function ogaibang_jiangguangting:OnEventRequest(selfId, targetId, arg, index)
    if index == 40 then
        self:BeginEvent(self.script_id)
        self:AddText("#{XXQS_05}")
        self:AddNumText("là", -1, 0)
        self:AddNumText("không", -1, 999)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 60 then
        self:BeginEvent(self.script_id)
        self:AddText("#{XXQS_06}")
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

return ogaibang_jiangguangting
