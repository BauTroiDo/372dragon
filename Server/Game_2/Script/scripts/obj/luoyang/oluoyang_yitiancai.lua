--洛阳NPC
--伊天彩
--普通

local class = require "class"
local script_base = require "script_base"
local oluoyang_yitiancai = class("oluoyang_yitiancai", script_base)

function oluoyang_yitiancai:OnDefaultEvent(selfId, targetId)
	self:BeginEvent( targetId )
		self:AddText("#{SZPR_091023_01}")
		self:AddNumText("#{SZPR_091023_02}", 6, 1)
		self:AddNumText("#{SZPR_091023_03}", 6, 2)
		self:AddNumText("#{SZPR_091023_04}", 6, 4)
        self:AddNumText("#{SZPR_091023_05}", 6, 5)
        self:AddNumText("#{SZPR_091023_06}", 6, 6)
        self:AddNumText("#{SZPR_091023_07}", 6, 7)
        -- self:AddNumText("#{SZPSZY_160314_01}", 6, 9)
        self:AddNumText("#{SZPR_091023_08}", 11, 10)
        self:AddNumText("#{SZPR_091023_09}", 11, 13)
        self:AddNumText("#{SZPSZY_160314_02}", 11, 11)
    self:EndEvent()
    self:DispatchEventList(selfId,targetId)
end

function oluoyang_yitiancai:OnEventRequest(selfId, targetId, arg, index)
    if index == 1 then
        self:BeginUICommand()
            self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 910281)
        return
    end
    if index == 2 then
        self:BeginUICommand()
            self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 910282)
        return
    end
    if index == 4 then
        self:BeginUICommand()
            self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 20091027)
        return
    end
    if index == 5 then
        self:BeginUICommand()
            self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 20091029)
        return
    end
    if index == 6 then
        self:BeginUICommand()
            self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 19860143)
        return
    end
    if index == 7 then
        self:BeginUICommand()
            self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 19851274)
        return
    end
    if index == 9 then
        self:BeginUICommand()
        self:UICommand_AddInt(0)
            self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 3)
        return
    end
end

return oluoyang_yitiancai