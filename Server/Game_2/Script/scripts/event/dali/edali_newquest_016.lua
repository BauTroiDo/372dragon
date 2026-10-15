local class = require "class"
local define = require "define"
local script_base = require "script_base"
local edali_newquest_016 = class("edali_newquest_016", script_base)
local ScriptGlobal = require "scripts.ScriptGlobal"
edali_newquest_016.script_id = 210265
edali_newquest_016.g_NextScriptId = 210277
edali_newquest_016.g_Position_X = 265
edali_newquest_016.g_Position_Z = 129
edali_newquest_016.g_SceneID = 2
edali_newquest_016.g_AccomplishNPC_Name = "云飘飘"
edali_newquest_016.g_MissionId = 1415
edali_newquest_016.g_MissionIdPre = 1414
edali_newquest_016.g_Name = "云飘飘"
edali_newquest_016.g_Entrance_Name = "申情"
edali_newquest_016.g_MissionKind = 13
edali_newquest_016.g_MissionLevel = 7
edali_newquest_016.g_IfMissionElite = 0
edali_newquest_016.g_IsMissionOkFail = 0                 --变量的第0位
edali_newquest_016.g_MissionName = "Bắt Trân thú"
edali_newquest_016.g_MissionInfo = "#{XSRW_100111_35}"   --任务描述
edali_newquest_016.g_MissionTarget = "#{XSRW_100111_91}" --任务目标
edali_newquest_016.g_ContinueInfo = "#{XSRW_100111_81}"  --未完成任务的npc对话
edali_newquest_016.g_MissionComplete = "#{XSRW_100111_36}" --完成任务npc说话的话
edali_newquest_016.g_SignPost = { x = 265, z = 129, tip = "云飘飘" }
edali_newquest_016.g_Custom = { { id = "抓住飘飘鸭", num = 1 } }
edali_newquest_016.g_MoneyJZBonus = 100
edali_newquest_016.g_ExpBonus = 3200
edali_newquest_016.g_client_res = 123
edali_newquest_016.g_PetDataID = 558
edali_newquest_016.g_CopySceneType = ScriptGlobal.FUBEN_MURENXIANG_7 --副本类型，定义在ScriptGlobal.lua里面
edali_newquest_016.g_LimitMembers = 1                                --可以进副本的最小队伍人数
edali_newquest_016.g_TickTime = 5                                    --回调脚本的时钟时间（单位：秒/次）
edali_newquest_016.g_LimitTotalHoldTime = 360                        --副本可以存活的时间（单位：次数）,如果此时间到了，则任务将会失败
edali_newquest_016.g_LimitTimeSuccess = 500                          --副本时间限制（单位：次数），如果此时间到了，任务完成
edali_newquest_016.g_CloseTick = 6                                   --副本关闭前倒计时（单位：次数）
edali_newquest_016.g_NoUserTime = 300                                --副本中没有人后可以继续保存的时间（单位：秒）
edali_newquest_016.g_DeadTrans = 0                                   --死亡转移模式，0：死亡后还可以继续在副本，1：死亡后被强制移出副本
edali_newquest_016.g_Fuben_X = 44                                    --进入副本的位置X
edali_newquest_016.g_Fuben_Z = 54                                    --进入副本的位置Z
edali_newquest_016.g_Back_X = 276                                    --源场景位置X
edali_newquest_016.g_Back_Z = 50                                     --源场景位置Z

function edali_newquest_016:OnDefaultEvent(selfId, targetId, arg, index)
	if self:IsMissionHaveDone(selfId, self.g_MissionId) then
		return
	elseif self:IsHaveMission(selfId, self.g_MissionId) and self:GetName(targetId) == self.g_AccomplishNPC_Name then
		self:BeginEvent(self.script_id)
		self:AddText(self.g_MissionName)
		self:AddText(self.g_ContinueInfo)
		self:EndEvent()
		local bDone = self:CheckSubmit(selfId)
		self:DispatchMissionDemandInfo(selfId, targetId, self.script_id, self.g_MissionId, bDone)
	elseif self:CheckAccept(selfId) > 0 then
		self:BeginEvent(self.script_id)
		self:AddText(self.g_MissionName)
		self:AddText(self.g_MissionInfo)
		self:AddText(self.g_MissionTarget)
		self:AddMoneyBonus(self.g_MoneyJZBonus)
		self:EndEvent()
		self:DispatchMissionInfo(selfId, targetId, self.script_id, self.g_MissionId)
	elseif self:GetName(targetId) == self.g_Entrance_Name and self:IsHaveMission(selfId, self.g_MissionId) then
		self:MakeCopyScene(selfId)
	end
end

function edali_newquest_016:OnEnumerate(caller, selfId, targetId, arg, index)
	if self:IsMissionHaveDone(selfId, self.g_MissionId) then
		return
	elseif self:GetName(targetId) == self.g_AccomplishNPC_Name and self:IsHaveMission(selfId, self.g_MissionId) then
		caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 2, 1)
	elseif self:GetName(targetId) == self.g_Name and not self:IsHaveMission(selfId, self.g_MissionId) then
		caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 1, 1)
	elseif self:GetName(targetId) == self.g_Entrance_Name and self:IsHaveMission(selfId, self.g_MissionId) then
		caller:AddNumTextWithTarget(self.script_id, "Đến Hậu Hoa Viên", 9, 9)
	end
end

function edali_newquest_016:OnPetChanged(selfId, petDataId)
	local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
	if petDataId == self.g_PetDataID then
		self:notify_tips(selfId, string.format("Đã nhận được %s.", self:GetPetName(petDataId)))
		self:notify_tips(selfId, "Bắt Phiêu Phiêu Áp: 1/1")
		self:SetMissionByIndex(selfId, misIndex, 0, 1) --设置任务完成
		self:SetMissionByIndex(selfId, misIndex, 1, 1)
	end
end

function edali_newquest_016:OnAccept(selfId)
	if self:IsMissionHaveDone(selfId, self.g_MissionId) then
		return
	end
	local ret = self:AddMission(selfId, self.g_MissionId, self.script_id, 1, 0, 0)
	if not ret then
		self:notify_tips(selfId, "#YNhật ký nhiệm vụ của ngươi đã đầy")
		return
	end
	self:notify_tips(selfId, "Tiếp nhận nhiệm vụ:#Y" .. self.g_MissionName)
end

function edali_newquest_016:CheckSubmit(selfId)
	local petcount = self:LuaFnGetPetCount(selfId)
	for i = 1, petcount do
		local petdataid = self:LuaFnGetPet_DataID(selfId, i)
		if petdataid == self.g_PetDataID then
			return 1
		end
	end
	return 0
end

function edali_newquest_016:OnAbandon(selfId)
	local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
	local copyscene = self:GetMissionParam(selfId, misIndex, 2)
	local sceneId = self:GetSceneID()
	self:DelMission(selfId, self.g_MissionId)
	if sceneId == copyscene then
		self:CallScriptFunction((400900), "TransferFunc", selfId, 2, self.g_Back_X, self.g_Back_Z)
	end
end

function edali_newquest_016:MakeCopyScene(selfId)
	local mylevel = self:GetLevel(selfId)
	local leaderguid = self:LuaFnObjId2Guid(selfId)
	local config = {}
	config.navmapname = "newbie_2.nav"
	config.client_res = self.g_client_res
	config.teamleader = leaderguid
	config.NoUserCloseTime = self.g_NoUserTime * 1000
	config.Timer = self.g_TickTime * 1000
	config.params = {}
	config.params[0] = self.g_CopySceneType
	config.params[1] = self.script_id
	config.params[2] = 0
	config.params[3] = -1
	config.params[4] = 0
	config.params[5] = 0
	config.params[6] = self:GetTeamId(selfId)
	config.params[7] = 0
	for i = 8, 31 do
		config.params[i] = 0
	end
	config.params[define.CopyScene_LevelGap] = mylevel
	config.eventfile = "newbie_2_area.ini"
	config.monsterfile = "newbie_2_monster.ini"
	config.sn = self:LuaFnGenCopySceneSN()
	local bRetSceneID = self:LuaFnCreateCopyScene(config)
	local text
	if bRetSceneID > 0 then
		text = "Tạo phó bản thành công!"
	else
		text = "Số lượng phó bản đã đạt đến giới hạn, xin hãy thử lại sau!"
	end
	self:notify_tips(selfId, text)
end

function edali_newquest_016:OnContinue(selfId, targetId)
	self:BeginEvent(self.script_id)
	self:AddText(self.g_MissionName)
	self:AddText(self.g_MissionComplete)
	self:AddMoneyBonus(self.g_MoneyJZBonus)
	self:EndEvent()
	self:DispatchMissionContinueInfo(selfId, targetId, self.script_id, self.g_MissionId)
end

function edali_newquest_016:OnSubmit(selfId, targetId)
	if not self:IsHaveMission(selfId, self.g_MissionId) then
		return
	end
	if self:CheckSubmit(selfId) <= 0 then
		return
	end
	if (self.g_MoneyJZBonus > 0) then
		self:AddMoneyJZ(selfId, self.g_MoneyJZBonus)
	end
	if (self.g_ExpBonus > 0) then
		self:LuaFnAddExp(selfId, self.g_ExpBonus)
	end
	local ret = self:DelMission(selfId, self.g_MissionId)
	if ret then
		self:MissionCom(selfId, self.g_MissionId)
		self:notify_tips(selfId, "Hoàn thành nhiệm vụ: bắt trân thú")
		self:CallScriptFunction(self.g_NextScriptId, "OnDefaultEvent", selfId, targetId)
	end
end

function edali_newquest_016:CheckAccept(selfId)
	if not self:IsMissionHaveDone(selfId, self.g_MissionIdPre) then
		return 0
	end
	if self:IsHaveMission(selfId, self.g_MissionId) then
		return 0
	end
	local petcount = self:LuaFnGetPetCount(selfId)
	for i = 1, petcount do
		local petdataid = self:LuaFnGetPet_DataID(selfId, i)
		if petdataid == self.g_PetDataID then
			return 0
		end
	end
	return 1
end

--**********************************
--副本事件
--**********************************
function edali_newquest_016:OnCopySceneReady(destsceneId)
	local leaderguid = self:LuaFnGetCopySceneData_TeamLeader(destsceneId)
	local leaderObjId = self:LuaFnGuid2ObjId(leaderguid)
	if self:LuaFnIsCanDoScriptLogic(leaderObjId) then
		if self:IsHaveMission(leaderObjId, self.g_MissionId) then
			local misIndex = self:GetMissionIndexByID(leaderObjId, self.g_MissionId)
			self:SetMissionByIndex(leaderObjId, misIndex, 2, destsceneId)
			local sn = self:LuaFnGetCopySceneData_Sn(destsceneId)
			self:NewWorld(leaderObjId, destsceneId, sn, self.g_Fuben_X, self.g_Fuben_Z, self.g_client_res)
		else
			self:notify_tips(leaderObjId, "Ngươi hiện chưa nhận nhiệm vụ này")
		end
	end
end

function edali_newquest_016:OnPlayerEnter(selfId)
	if not self:IsHaveMission(selfId, self.g_MissionId) then
		self:notify_tips(selfId, "Ngươi hiện tại chưa tiếp nhiệm vụ này, hãy trở về Đại Lý thành")
		local oldsceneId = selfId:LuaFnGetCopySceneData_Param(3)
		self:NewWorld(selfId, oldsceneId, self.g_Back_X, self.g_Back_Z, 2)
		return
	end
	local sceneId = self:GetSceneID()
	--设置死亡后复活点位置
	self:SetPlayerDefaultReliveInfo(selfId, 1, 1, 0, sceneId, self.g_Fuben_X, self.g_Fuben_Z)
end

function edali_newquest_016:OnHumanDie(selfId, killerId)
end

function edali_newquest_016:OnCopySceneTimer(nowTime)
	local TickCount = self:LuaFnGetCopySceneData_Param(2)
	TickCount = TickCount + 1
	self:LuaFnSetCopySceneData_Param(2, TickCount)
	local leaveFlag = self:LuaFnGetCopySceneData_Param(4)
	if leaveFlag == 1 then
		local leaveTickCount = self:LuaFnGetCopySceneData_Param(5);
		leaveTickCount = leaveTickCount + 1;
		self:LuaFnSetCopySceneData_Param(5, leaveTickCount);
		if leaveTickCount == self.g_CloseTick then
			local oldsceneId = self:LuaFnGetCopySceneData_Param(3)
			local membercount = self:LuaFnGetCopyScene_HumanCount()
			local mems = {}
			for i = 1, membercount do
				mems[i] = self:LuaFnGetCopyScene_HumanObjId(i)
				self:NewWorld(mems[i], oldsceneId, self.g_Back_X, self.g_Back_Z, self.g_client_res)
			end
		elseif leaveTickCount < self.g_CloseTick then
			local oldsceneId = self:LuaFnGetCopySceneData_Param(3)
			local membercount = self:LuaFnGetCopyScene_HumanCount()
			local mems = {}
			local strText = string.format("Ngươi sẽ rời khỏi cảnh sau %d giây!",
				(self.g_CloseTick - leaveTickCount) * self.g_TickTime)
			for i = 1, membercount do
				mems[i] = self:LuaFnGetCopyScene_HumanObjId(i)
				self:BeginEvent(self.script_id)
				self:AddText(strText)
				self:EndEvent()
				self:DispatchMissionTips(mems[i])
			end
		end
	elseif TickCount == self.g_LimitTotalHoldTime then
		local membercount = self:LuaFnGetCopyScene_HumanCount()
		local mems = {}
		for i = 1, membercount do
			mems[i] = self:LuaFnGetCopyScene_HumanObjId(i)
			self:DelMission(mems[i], self.g_MissionId)

			self:BeginEvent(self.script_id)
			self:AddText("Nhiệm vụ thất bại, quá thời gian!")
			self:EndEvent()
			self:DispatchMissionTips(mems[i])
		end
		self:LuaFnSetCopySceneData_Param(4, 1)
	end
end

function edali_newquest_016:OnKillObject(selfId, objdataId, objId)
end

function edali_newquest_016:OnEnterArea(selfId, zoneId)
end

function edali_newquest_016:OnItemChanged(selfId, itemdataId)
end

return edali_newquest_016
