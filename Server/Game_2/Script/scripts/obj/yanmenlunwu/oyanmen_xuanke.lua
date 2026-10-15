local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oyanmen_xuanke = class("oyanmen_xuanke", script_base)
oyanmen_xuanke.ID = {49936,49937,49938,49939,49940,49941}
oyanmen_xuanke.Title = 8
oyanmen_xuanke.script_id = 893140
oyanmen_xuanke.g_FuBenScriptId = 893131
oyanmen_xuanke.g_MonsterAI = 893149
function oyanmen_xuanke:OnDefaultEvent(selfId,targetId)
	self:BeginEvent(self.script_id)
		self:AddText("#{MPCG_191029_384}")
		self:AddNumText("#{MPCG_191029_24}",10,1)
	self:EndEvent()
	self:DispatchEventList(selfId,targetId)
end

function oyanmen_xuanke:OnEventRequest(selfId,targetId,arg,index)
	local PosX,PosY = self:GetWorldPos(targetId)
    local param0 = 4
    local param1 = 3
    local mylevel
    local memId
    local tempMemlevel
    local level0 = 0
    local level1 = 0
    local nearmembercount = self:GetNearTeamCount(selfId)
    for i = 1, nearmembercount do
        memId = self:GetNearTeamMember(selfId, i)
        tempMemlevel = self:GetLevel(memId)
        level0 = level0 + (tempMemlevel ^ param0)
        level1 = level1 + (tempMemlevel ^ param1)
    end
    if level1 == 0 then
        mylevel = 0
    else
        mylevel = level0 / level1
    end
    if nearmembercount == -1 then
        mylevel = self:GetLevel(selfId)
    end
    local PlayerMaxLevel = self:GetHumanMaxLevelLimit()
    local iniLevel
    if mylevel < 10 then
        iniLevel = 1
    elseif mylevel < PlayerMaxLevel then
        iniLevel = math.floor(mylevel / 10)
    else
        iniLevel = math.floor(PlayerMaxLevel / 10)
    end
	if iniLevel > 6 then
		iniLevel = 6
	end
	if index == 1 then
		if not self:IsCaptain(selfId) then
			self:MsgBox(selfId,targetId,"#{MPCG_191029_63}")
			return
		end
        local NearTeamSize = self:GetNearTeamCount(selfId)
        if self:GetTeamSize(selfId) ~= NearTeamSize then
            self:MsgBox(selfId, targetId,"#{MPCG_191029_38}")
            return
        end
		--//这里用于储存部分怪物释放大招时所返回的中心位置。
		self:LuaFnSetCopySceneData_Param(10,PosX)
		self:LuaFnSetCopySceneData_Param(11,PosY)
		self:CallScriptFunction(self.g_FuBenScriptId, "CreateBOSS",self.ID[iniLevel],PosX,PosY,27,0,self.g_MonsterAI,self.Title,mylevel) --创建怪物
		self:CallScriptFunction(self.g_FuBenScriptId, "DeleteBOSS",targetId) --删除NPC
	end
    self:BeginUICommand()
    self:EndUICommand()
    self:DispatchUICommand(selfId,1000)
end

function oyanmen_xuanke:MsgBox(selfId,targetId,str)
	self:BeginEvent(self.script_id)
		self:AddText(str)
		self:EndEvent()
	self:DispatchEventList(selfId,targetId)
end
return oyanmen_xuanke