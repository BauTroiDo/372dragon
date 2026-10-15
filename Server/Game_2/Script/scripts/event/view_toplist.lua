local class = require "class"
local define = require "define"
local script_base = require "script_base"
local view_toplist = class("view_toplist", script_base)

function view_toplist:OnEnumerate(caller, selfId, targetId, bid)
    caller:AddNumTextWithTarget(self.script_id, "#{HSPH_191120_49}", 6, 1)
end

function view_toplist:OnDefaultEvent(selfId, targetId, ButtomNum)
    self:BeginUICommand()
    self:UICommand_AddInt(targetId)
    self:UICommand_AddInt(0)
    self:UICommand_AddInt(27)
    self:EndUICommand()
    self:DispatchUICommand(selfId, 89293001)

    self:BeginUICommand()
    self:UICommand_AddInt(1)
    self:UICommand_AddInt(2)
    self:UICommand_AddInt(0)
    self:UICommand_AddInt(0)
    self:UICommand_AddInt(0)
    self:EndUICommand()
    self:DispatchUICommand(selfId, 89293002)

    self:DispatchXBWRankCharts(selfId, 0)
end

function view_toplist:QueryRankList(selfId, index)
    self:DispatchXBWRankCharts(selfId, index)
end

return view_toplist