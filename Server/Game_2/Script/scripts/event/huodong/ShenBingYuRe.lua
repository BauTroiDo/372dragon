local gbk = require "wire_charset"
local class = require "class"
local script_base = require "script_base"
local ShenBingYuRe = class("ShenBingYuRe", script_base)
ShenBingYuRe.script_id = 791100

function ShenBingYuRe:OnUIEvent(selfId,arg,arg2)
	--神兵预热界面
	if arg == 4 and arg2 == 0 then
	self:BeginUICommand()
		self:UICommand_AddInt(1)
		self:UICommand_AddInt(selfId)
	self:EndUICommand()
	self:DispatchUICommand(selfId,79110001)
	end
	
end
return ShenBingYuRe