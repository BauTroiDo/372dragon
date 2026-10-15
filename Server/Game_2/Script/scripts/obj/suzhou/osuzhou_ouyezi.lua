--苏州NPC
--欧冶子
--普通

local class = require "class"
local script_base = require "script_base"
local osuzhou_ouyezi = class("osuzhou_ouyezi", script_base)
osuzhou_ouyezi.key	=
{
	["inf"]	= 1000,	--制造介绍
	["ln"]	= 1,		--我要学习精炼配方 - 精炼 - 铸造
	["zh"]	= 2,		--我要学习精制配方 - 精制 - 缝纫
	["gn"]	= 3,		--我要学习精工配方 - 精工 - 工艺
	["sh"]	= 4,		--精工配方商店
}
osuzhou_ouyezi.g_ShenBingScriptId = 500503
osuzhou_ouyezi.g_ChongZhuScriptId = 500504
osuzhou_ouyezi.g_Name = "欧冶子"

function osuzhou_ouyezi:OnDefaultEvent(selfId, targetId)
	self:BeginEvent(self.script_id)
        self:AddText( "#{OBJ_suzhou_0020}" )
        --self:AddNumText("血欲神兵", 3, 105 )
        self:AddNumText("Trang bị tư chất giám định", 6, 4)
        self:AddNumText("Trang bị cường hóa", 6, 5)
        self:AddNumText("#GChuyển cường hóa", 6, 6)
		self:AddNumText("Tăng Số lần sửa chữa khả dụng", 6, 8)
        self:AddNumText("Trang bị Khắc Minh", 6, 9)
        self:AddNumText("Trang bị Trừ Minh", 6, 22)
        self:AddNumText("Giám định lại Trang bị tư chất", 6, 19)
        --self:AddNumText("神器铸造", 11, 106)
        --self:AddNumText("装备加强相关介绍", 11, 10)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function osuzhou_ouyezi:OnEventRequest(selfId, targetId, arg, index)
    if index == 10 then
        self:BeginEvent(self.script_id)
            self:AddText( "#{function_help_055}#r" )
            self:AddNumText("Trang bị Khắc Minh tửu quán", 11, 11 )
            self:AddNumText("Cường hóa Trang bị tửu quán", 11, 12)
            self:AddNumText("Trang bị Giám định tư chất tửu quán", 11, 13)
            self:AddNumText("Giám định lại Trang bị tư chất tửu quán", 11, 29)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 11 then
        self:BeginEvent(self.script_id)
            self:AddText( "#{function_help_044}#r" )
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 12 then
        self:BeginEvent(self.script_id)
            self:AddText( "#{function_help_045}#r" )
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 13 then
        self:BeginEvent(self.script_id)
            self:AddText( "#{function_help_046}#r" )
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 14 then
        self:BeginEvent(self.script_id)
            self:AddText( "#{function_help_047}#r" )
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 29 then
        self:BeginEvent(self.script_id)
            self:AddText( "#{function_help_097}#r" )
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 4 then
        self:BeginUICommand()
            self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1001)
        return
    end
    if index == 5 then
        self:BeginUICommand()
            self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1002)
        return
    end
    if index == 6 then
        self:BeginUICommand()
            self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 20130521)
        return
    end
    if index == 7 then
        self:BeginUICommand()
            self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1010)
        return
    end
    if index == 8 then
        self:BeginUICommand()
            self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1004)
        return
    end
    if index == 9 then
        self:BeginUICommand()
            self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1005)
        return
    end
    if index == 22 then
        self:BeginUICommand()
            self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1006)
        return
    end
    if index == 19 then
        self:BeginUICommand()
            self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 112233)
        return
    end
    if index == 105 then
        self:BeginEvent(self.script_id)
        self:AddText("#{XYSB_20070928_001}")
        self:CallScriptFunction(self.g_ShenBingScriptId,"OnEnumerate",self,selfId,targetId)
        self:EndEvent()
        self:DispatchEventList(selfId,targetId)
        return
    end
    if arg == self.g_ShenBingScriptId then
        self:CallScriptFunction(arg,"OnDefaultEvent",selfId,targetId)
        return
    end
end

function osuzhou_ouyezi:OnMissionAccept(selfId,targetId,missionScriptId)
    if missionScriptId == self.g_ShenBingScriptId then
        self:CallScriptFunction(missionScriptId,"CheckAccept",selfId,targetId)
    end
end

function osuzhou_ouyezi:OnMissionCheck(selfId,npcid,scriptId,index1,index2,index3,indexpet)
    if scriptId == self.g_ShenBingScriptId then
        self:CallScriptFunction(scriptId,"OnMissionCheck",selfId,npcid,scriptId,index1,index2,index3,indexpet)
        return
    end
end


function osuzhou_ouyezi:OnMissionContinue(selfId,targetId,missionScriptId)
    if missionScriptId == self.g_ShenBingScriptId then
        self:CallScriptFunction(missionScriptId,"OnContinue",selfId,targetId)
        return
    end
 end

function osuzhou_ouyezi:OnMissionSubmit(selfId,targetId,missionScriptId,selectRadioId)
    if missionScriptId == self.g_ShenBingScriptId then
        self:CallScriptFunction(missionScriptId,"OnSubmit",selfId,targetId,selectRadioId)
        return
    end
end

return osuzhou_ouyezi