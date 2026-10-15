local class = require "class"
local define = require "define"
local script_base = require "script_base"
local dahua = class("dahua", script_base)
local ScriptGlobal = require("scripts.ScriptGlobal")
dahua.script_id = 890364

function dahua:OnOpenDaHuaXiYouActivity(selfId,index1)
    self:BeginUICommand()
    self:UICommand_AddInt(1)
    self:UICommand_AddInt(11)
	self:UICommand_AddInt(11)
	self:UICommand_AddInt(11)
	self:UICommand_AddInt(11)
	self:UICommand_AddInt(11)
	self:UICommand_AddInt(11)
	self:UICommand_AddInt(11)
    self:EndUICommand()
    self:DispatchUICommand(selfId, 89036401)
end

function dahua:OnOpenUI(selfId,index1)
	--MonthPVP_Goto
	if index1 == 1 then
    self:BeginUICommand()
    self:UICommand_AddInt(1)
    self:UICommand_AddInt(11)
	self:UICommand_AddInt(11)
	self:UICommand_AddInt(11)
	self:UICommand_AddInt(11)
	self:UICommand_AddInt(11)
	self:UICommand_AddInt(11)
	self:UICommand_AddInt(11)
    self:EndUICommand()
    self:DispatchUICommand(selfId, 82002301)
	--DaHua_MainStory
	elseif index1 == 3 then
    self:BeginUICommand()
    self:UICommand_AddInt(1)
    self:UICommand_AddInt(1)
	self:UICommand_AddInt(1)
	self:UICommand_AddInt(1)
    self:EndUICommand()
    self:DispatchUICommand(selfId, 99913201)
	--DaHua_DaKa
	elseif index1 == 4 then
    self:BeginUICommand()
    self:EndUICommand()
    self:DispatchUICommand(selfId, 99913702)
	else
		self:NotifySystemMsg(selfId, "Kính xin chờ đợi")
		return
	end
end

function dahua:OnGoTo(selfId,index1)
	--MonthPVP_Goto
	if index1 == 1 then
    self:BeginUICommand()
    self:EndUICommand()
    self:DispatchUICommand(selfId, 82002302)
	elseif index1 == 4 then
    self:BeginUICommand()
    self:EndUICommand()
    self:DispatchUICommand(selfId, 99913703)
	end
	
end

function dahua:OnHelp(selfId,index1)
	--MonthPVP_Goto
    --self:BeginUICommand()
    --self:EndUICommand()
    --self:DispatchUICommand(selfId, 82002302)
end

function dahua:NotifySystemMsg(selfId, tip)
    self:BeginEvent(self.script_id)
    self:AddText(tip)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return dahua
