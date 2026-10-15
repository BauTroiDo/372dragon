local gbk = require "wire_charset"
local class = require "class"
local script_base = require "script_base"
local LoverTime = class("LoverTime", script_base)

function LoverTime:ClientAskQingRenJieTopList(selfId)
	self:BeginUICommand()
    self:UICommand_AddInt(1)
    self:UICommand_AddInt(1)
    self:UICommand_AddInt(1)
    self:UICommand_AddInt(0)
    self:UICommand_AddStr("#{QRZM_211119_206*\1\6*\0012}")
    self:EndUICommand()
    self:DispatchUICommand(selfId,892974)
    self:WGCRetQueryQingRenJieTopList(selfId)
end

return LoverTime