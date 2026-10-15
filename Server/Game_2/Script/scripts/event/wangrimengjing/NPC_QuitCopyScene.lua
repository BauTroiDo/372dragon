local class = require "class"
local define = require "define"
local script_base = require "script_base"
local NPC_QuitCopyScene = class("NPC_QuitCopyScene", script_base)
NPC_QuitCopyScene.script_id = 801802
NPC_QuitCopyScene.g_FuBenScriptId = 801801
NPC_QuitCopyScene.g_LimitMembers = 1
--SBRC_20230627_189	#G传至单家庄（第二梦境）	
--SBRC_20230627_190	#G传至卫辉城外（第三梦境）	
--SBRC_20230627_191	#G传至少室山寺院（第四梦境）	
--SBRC_20230627_38	传至信阳西郊（第一梦境）	
--SBRC_20230627_39	传至单家庄（第二梦境）	
--SBRC_20230627_40	传至卫辉城外（第三梦境）	
--SBRC_20230627_41	传至少室山寺院（第四梦境）
--SBRC_20230627_37	#W    下一段梦境就在前方，准备好，咱们即刻出发。	
function NPC_QuitCopyScene:UpdateEventList(selfId, targetId)
	local nCurMainStep = self:LuaFnGetCopySceneData_Param(8)
	local NpcGuid = self:LuaFnGetGUID(targetId)
	if self:GetName(targetId) == "梦境萧峰" then
		self:BeginEvent(self.script_id)
			self:AddText("#{SBRC_20230627_159}")
			self:AddNumText("#{SBRC_20230627_42}", 9,103)
		self:EndEvent()
		self:DispatchEventList(selfId, targetId)
		return
	end
    self:BeginEvent(self.script_id)
        self:AddText("#{SBRC_20230627_37}")
		if NpcGuid == 10132461 and nCurMainStep == 3 then
			self:AddNumText("#{SBRC_20230627_189}", 6,1)
		elseif NpcGuid == 10132461 and nCurMainStep == 5 then
			self:AddNumText("#{SBRC_20230627_39}", 6,2)
			self:AddNumText("#{SBRC_20230627_190}", 6,3)
		elseif NpcGuid == 10132461 and nCurMainStep == 7 then
			self:AddNumText("#{SBRC_20230627_39}", 6,4)
			self:AddNumText("#{SBRC_20230627_40}", 6,5)
			self:AddNumText("#{SBRC_20230627_191}", 6,6)


		elseif NpcGuid == 10132462 and nCurMainStep == 5 then
			self:AddNumText("#{SBRC_20230627_38}", 6,7)
			self:AddNumText("#{SBRC_20230627_190}", 6,8)
		elseif NpcGuid == 10132462 and nCurMainStep == 7 then
			self:AddNumText("#{SBRC_20230627_38}", 6,7)
			self:AddNumText("#{SBRC_20230627_40}", 6,5)
			self:AddNumText("#{SBRC_20230627_191}", 6,10)
			
			
		elseif NpcGuid == 10132463 and nCurMainStep == 7 then
			self:AddNumText("#{SBRC_20230627_38}", 6,7)
			self:AddNumText("#{SBRC_20230627_39}", 6,2)
			self:AddNumText("#{SBRC_20230627_40}", 6,5)
			self:AddNumText("#{SBRC_20230627_191}", 6,11)
		end
        self:AddNumText("#{SBRC_20230627_42}", 9, 100)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function NPC_QuitCopyScene:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end
--self:CallScriptFunction(self.g_FuBenScriptId, "BroadCastNpcTalkAllHuman",266)
function NPC_QuitCopyScene:OnEventRequest(selfId, targetId, arg, index)
	if index == 1 then
		self:notify_tips(selfId,"#{SBRC_20230627_45}")
		self:SetPos(selfId,69,109)
		self:DoNpcTalk(selfId,262)
		self:CallScriptFunction(801801,"CreateSmallMonster")
	elseif index == 2 then
		self:SetPos(selfId,69,109)
	elseif index == 3 then
		self:SetPos(selfId,214,173)
	elseif index == 4 then
		self:SetPos(selfId,69,109)
	elseif index == 5 then
		self:SetPos(selfId,214,173)
	elseif index == 6 then
		self:SetPos(selfId,204,88)
	elseif index == 7 then
		self:SetPos(selfId,33,199)
	elseif index == 8 then
		self:notify_tips(selfId,"#{SBRC_20230627_45}")
		self:SetPos(selfId,214,173)
		self:DoNpcTalk(selfId,266)
	elseif index == 10 then
		self:SetPos(selfId,204,88)
	elseif index == 11 then
		self:notify_tips(selfId,"#{SBRC_20230627_45}")
		self:SetPos(selfId,204,88)
		self:DoNpcTalk(selfId,271)
	elseif index == 100 then
    self:BeginEvent(self.script_id)
        self:AddText("#{SBRC_20230627_47}")
        self:AddNumText("#{SBRC_20230627_48}", 6, 101)
		self:AddNumText("#{SBRC_20230627_49}", 6, 102)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
	elseif index == 101 then
		self:CallScriptFunction((400900), "TransferFunc", selfId, 2, 239, 60)
	elseif index == 102 then
        self:BeginUICommand()
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
	elseif index == 103 then
    self:BeginEvent(self.script_id)
        self:AddText("#{SBRC_20230627_160}")
        self:AddNumText("#{SBRC_20230627_48}", 6, 101)
		self:AddNumText("#{SBRC_20230627_49}", 6, 102)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
	end
end

return NPC_QuitCopyScene
