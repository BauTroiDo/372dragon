local class = require "class"
local gbk = require "wire_charset"
local define = require "define"
local script_base = require "script_base"
local scene = class("scene", script_base)
local ScriptGlobal = require "scripts.ScriptGlobal"
local configenginer = require "configenginer":getinstance()
-- CYS-RELIVEPT 20/09/2026: LECH CO CHU Y khoi server nen. Ghi ro de dong sau dung doc nham.
--
-- DAY KHONG PHAI SUA HOI QUY. Da do, khong suy: cay skynet GOC
--   /home/ubuntu/Game_2/Script/scripts/scene.lua  va ban clone cua du an TRUNG NHAU TUNG BYTE
--   truoc thay doi nay (md5 6b25b0a0566502efa01ec5b6ebcd06f4, sha256 89179d8d..., 1515 dong).
--   "Ai chet cung roi xuong Dia Phu" LA hanh vi cua server nen. Doi no la QUYET DINH SAN PHAM,
--   nguoi dung quyet dich danh 20/09.
--
-- VI SAO DOI: canh 77/1500/2218 ap impact 59901 (cuoi ham nay) khoa CanAction1/2 va CanMove,
--   thoi han -1, khong mat khi dang xuat. Hai loi thoat tu dong cua chinh no la "bat dau di"
--   va "bat dau hanh dong" - tuc no khoa dung hai cua ra cua no. Client dang phat hanh lai
--   danh roi hai trinh xu ly be buff nen nguoi choi khong THAY icon de chuot phai huy
--   => ket vinh vien. Nhanh `revive` da va phia client; day la tang server.
--
-- CHON CANH 2 (160,150) - bon nguon doc lap, chi tiet o Timeline/handoff/relive-point.md muc 2:
--   1) define.DEFAULT_SCENEID_AND_WORLD_POS (define.lua:2229) - hang so an toan DA CO cua chinh
--      server nay; msgagent.lua:971 va :990 dung no khi canh dang nhap khong dung duoc. Sau thay
--      doi nay, "chet" va "dang nhap hong" dung CHUNG mot noi an toan.
--   2) SceneAttr cua CY 3.71 that, dong id=2 (Dai Ly), cot diem dung = (160,150) - TRUNG TUNG
--      CHU SO voi (1), tu hai nguon khong lien quan gi nhau.
--   3) 085 goc co mot nhanh mac dinh THU HAI tro ve canh 2 (x888888_g_defaultRelive_SceneID_2).
--   4) atk-range 18.2 DA DO cap (canh 2, 160,150): chet -> hoi sinh dung cho.
--
-- KHONG PHAI "khoi phuc 085": 085 chi cho mon phai 9 ve canh 2, con lai van xuong 77; o day
--   nhanh thu hai duoc MO RA CHO MOI NGUOI. Va KHONG biet CY 3.71 lam gi - dich den nam phia
--   server, du an khong giu hien vat server cua CY (handoff muc 3, co bang chung chuoi + sha256).
-- Khong dung (165,169) cua 085: do la toa do ban do Dai Ly DOI 085 (diem dung 160,277), khac
--   ban do dali_new_320 ma canh 2 dang dung.
-- HOAN TAC: doi hai dong duoi ve  local g_defaultRelive_SceneID_1 = 77  va toa do 20, 38 o dong
--   SetPlayerDefaultReliveInfo trong scene:OnScenePlayerEnter.
local g_defaultRelive_SceneID_1 = define.DEFAULT_SCENEID_AND_WORLD_POS.sceneid
local g_defaultRelive_WorldPos_1 = define.DEFAULT_SCENEID_AND_WORLD_POS.world_pos
local g_HanYuBed_SceneId = 194
-- 玩家升级时可以完成的任务
scene.FullLevel_MissionList	=	{}
scene.FullLevel_MissionList[28] = { MissionId = 403, MissionIndex = 500606, LevelLimit = 28, CompleteIdx = 0, RecordIdx = 1, MsgStr = "#{YD_20080421_188}" }
scene.FullLevel_MissionList[30] = { MissionId = 409, MissionIndex = 500602, LevelLimit = 30, CompleteIdx = 0, RecordIdx = 1, MsgStr = "#{YD_20080421_181}" }												-- 任务ID,任务索引号,需求等级,任务完成标志在任务参数第几位,任务跟踪标志在任务参数第几位
scene.FullLevel_MissionList[32] = { MissionId = 412, MissionIndex = 500603, LevelLimit = 32, CompleteIdx = 0, RecordIdx = 1, MsgStr = "#{YD_20080421_183}" }
scene.FullLevel_MissionList[35] = { MissionId = 415, MissionIndex = 500605, LevelLimit = 35, CompleteIdx = 0, RecordIdx = 1, MsgStr = "#{YD_20080421_186}" }
scene.FullLevel_MissionList[38] = { MissionId = 418, MissionIndex = 500608, LevelLimit = 38, CompleteIdx = 0, RecordIdx = 1, MsgStr = "#{YD_20080421_191}" }
scene.FullLevel_MissionList[40] = { MissionId = 428, MissionIndex = 500612, LevelLimit = 40, CompleteIdx = 0, RecordIdx = 1, MsgStr = "#{YD_20080421_196}" }
scene.FullLevel_MissionList[42] = { MissionId = 433, MissionIndex = 500613, LevelLimit = 42, CompleteIdx = 0, RecordIdx = 1, MsgStr = "#{YD_20080421_198}" }
scene.FullLevel_MissionList[45] = { MissionId = 437, MissionIndex = 500614, LevelLimit = 45, CompleteIdx = 0, RecordIdx = 1, MsgStr = "#{YD_20080421_200}" }
scene.FullLevel_MissionList[48] = { MissionId = 476, MissionIndex = 500615, LevelLimit = 48, CompleteIdx = 0, RecordIdx = 1, MsgStr = "#{YD_20080421_202}" }
scene.FullLevel_MissionList[50] = { MissionId = 480, MissionIndex = 500616, LevelLimit = 50, CompleteIdx = 0, RecordIdx = 1, MsgStr = "#{YD_20080421_204}" }

-- 玩家升级时可以自动添加的任务
scene.AutoAccept_MissionList = {}
scene.AutoAccept_MissionList[26] = { MissionId = 400, MissionIndex = 1018700, PreMissionId = 0,   pKill = 0, pArea = 0, pItem = 0, EventId = 4 }
scene.AutoAccept_MissionList[28] = { MissionId = 403, MissionIndex = 500606, PreMissionId = 0, pKill = 0, pArea = 0, pItem = 0, EventId = 0 }			-- 任务ID,任务索引号,前续任务ID,任务类型参数(3),脚本任务时MissionIndex为ScriptId
scene.AutoAccept_MissionList[30] = { MissionId = 409, MissionIndex = 500602, PreMissionId = 0, pKill = 0, pArea = 0, pItem = 0, EventId = 0 }
scene.AutoAccept_MissionList[32] = { MissionId = 412, MissionIndex = 500603, PreMissionId = 0, pKill = 0, pArea = 0, pItem = 0, EventId = 0 }
scene.AutoAccept_MissionList[35] = { MissionId = 415, MissionIndex = 500605, PreMissionId = 0, pKill = 0, pArea = 0, pItem = 0, EventId = 0 }
scene.AutoAccept_MissionList[38] = { MissionId = 418, MissionIndex = 500608, PreMissionId = 0, pKill = 0, pArea = 0, pItem = 0, EventId = 0 }
scene.AutoAccept_MissionList[40] = { MissionId = 428, MissionIndex = 500612, PreMissionId = 0, pKill = 0, pArea = 0, pItem = 0, EventId = 0 }
scene.AutoAccept_MissionList[42] = { MissionId = 433, MissionIndex = 500613, PreMissionId = 0, pKill = 0, pArea = 0, pItem = 0, EventId = 0 }
scene.AutoAccept_MissionList[45] = { MissionId = 437, MissionIndex = 500614, PreMissionId = 0, pKill = 0, pArea = 0, pItem = 0, EventId = 0 }
scene.AutoAccept_MissionList[48] = { MissionId = 476, MissionIndex = 500615, PreMissionId = 0, pKill = 0, pArea = 0, pItem = 0, EventId = 0 }
scene.AutoAccept_MissionList[50] = { MissionId = 480, MissionIndex = 500616, PreMissionId = 0, pKill = 0, pArea = 0, pItem = 0, EventId = 0 }

scene.titleinfo = 
{
    1204,1286,1073,-1,1234,1235,1236
}
scene.menpaititle = 
{
    1096,1108,1117,1099,1102,1105,1111,1120,1114,-1,1219
}
scene.payinfo = 
{
    250000,500000,1500000,2500000,5000000,15000000,25000000
}

function scene:LuaFnGetSceneSafeLevel()
    local sceneid = self.scene:get_id()
    local scene_attr = configenginer:get_config("scene_attr")
	local attr = scene_attr[sceneid]
    return attr and attr.safe_level or 0
end

function scene:OnScenePlayerEnter(selfId)
	local obj = self.scene:get_obj_by_id(selfId)
	if not obj then
		return
	end
    local sceneId = self:GetSceneID()
	if sceneId == 0 then
		self:NotifyCrystalOne(0,true,true)
		if self:GetMissionDataEx(selfId,ScriptGlobal.MDEX_OLD_SCENEID) == 191 then
			self:EmptyPlainWarFlagPos()
		end
	end
	self:SetMissionDataEx(selfId,ScriptGlobal.MDEX_OLD_SCENEID,sceneId)
	
	local wd4 = self:GetMissionData(selfId,define.MD_WDDAO_FOUR_4)
	self:SetMissionData(selfId,define.MD_WDDAO_FOUR_4,0)
	self:SetMissionData(selfId,ScriptGlobal.MD_WDDAO_FOUR_4_Ex1,wd4)
	self:SetMissionData(selfId,ScriptGlobal.MD_WDDAO_FOUR_4_Ex2,wd4)
	
	obj:set_mission_data_by_script_id(ScriptGlobal.MD_DAMAGECURSCENE,sceneId + 1)
	obj:set_mission_data_by_script_id(ScriptGlobal.MD_DAMAGENEEDSCENE,0)
	obj:set_mission_data_by_script_id(ScriptGlobal.MD_DAMAGEOBJID,0)
	obj:set_mission_data_by_script_id(ScriptGlobal.MD_DAMAGEDATA,0)
	local bbtime = obj:get_mission_data_by_script_id(534)
	if os.time() > bbtime then
		obj:set_mission_data_by_script_id(534,0)
	end
	--清理状态
	for i = 3019,3023 do
		obj:impact_cancel_impact_in_specific_data_index(i)
		-- self:LuaFnCancelSpecificImpact(selfId,i)
	end
	--self:LuaFnCancelSpecificImpact(selfId,3019) --清理战旗状态
    self:SetPlayerDefaultReliveInfo(selfId, 1, 1, 0.1, g_defaultRelive_SceneID_1,
        g_defaultRelive_WorldPos_1.x, g_defaultRelive_WorldPos_1.y )
    local nSafeLevel = self:LuaFnGetSceneSafeLevel()
	
	--[[local camp_id = -1
	local camp_scene = ScriptGlobal.TW_INI[sceneId]
	if camp_scene then
		local server_id = self:LuaFnGetServerID(selfId)
		for _,info in ipairs(camp_scene) do
			if info.seerver_id == server_id then
				if info.guild_id then
					local guild = self:GetHumanGuildID(selfId)
					for _,gid in ipairs(info.guild_id) do
						if gid == guild then
							camp_id = info.camp_id
							break
						end
					end
				else
					camp_id = info.camp_id
				end
				break
			end
		end
	end
	self:SetUnitCampID(selfId,camp_id)--]]
	
    -- 玩家进入非安全场景，给个无敌BUFF
    if nSafeLevel == 0 then
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 54, 100 )
    end
	--跨服场景要做特殊处理吧，不然会报错
	if not define.IS_KUAFU_SCENE[sceneId] then
		local warscene = self:LuaFnGetCopySceneData_Param(0,66)
		if warscene > 0 and warscene == sceneId then
			local scriptId = self:LuaFnGetCopySceneData_Param(0,67)
			local scriptName = self:LuaFnGetCopySceneData_Param(0,68)
			if scriptId > 0 and scriptName ~= "" then
				self:CallScriptFunction(scriptId,scriptName,selfId)
			end
		end
		--[[local serverId = self:LuaFnGetServerID(selfId)
		if serverId == 10 then
			self:SetSceneExpRate(1)		--设置场景经验基数 当前配置上*（设置的值+1）   支持负数、小数
		elseif serverId == 11 then
			self:SetSceneExpRate(0)		--设置场景经验基数 当前配置上*（设置的值+1）   支持负数、小数
		else
			if ScriptGlobal.is_internal_test then
				self:SetSceneExpRate(29)
			end
		end--]]
		--self:SetSceneExpRate(29)
		self:SetSceneExpRate(0)		--修复：原值5导致所有普通地图全局6倍经验（结算时+1），改为0即1倍正常经验
	else
		self:SetSceneExpRate(0)
	end

	local nSceneType = self:LuaFnGetSceneType()
	if nSceneType == 1 then
		local copyscenetype = self:LuaFnGetCopySceneData_Param(0)
		local copyscenescript = self:LuaFnGetCopySceneData_Param(1)
		if not self:CheckTimer(0) then
			self:SetTimer(selfId, copyscenescript, "OnCopySceneTimer", 1000)
		end
	end
    if sceneId == g_HanYuBed_SceneId then
		if not self:CheckTimer(0) then
			self:SetTimer(selfId, 808072, "OnSceneTimer",12000)
		end
	end
    if sceneId == 191 then
        print("CheckTimer 191 OnSceneTimer")
		if not self:CheckTimer(0) then
            print("SetTimer 191 OnSceneTimer")
			self:SetTimer(selfId,403005,"OnSceneTimer",1000)
		end
        self:CallScriptFunction((403005), "OnPlayerEnter",selfId)
	elseif sceneId == 313 then
        self:CallScriptFunction((999984), "OnWarScene",selfId)
	elseif sceneId == 315 then
        self:CallScriptFunction((999987), "OnWarScene",selfId)
	--elseif sceneId == 314 then
	elseif sceneId == 490 then
        self:CallScriptFunction((999990), "OnWarScene",selfId)
	elseif sceneId == 814 or sceneId == 818 then
        self:CallScriptFunction((999981), "OnWarScene",selfId)
	end
    if sceneId == 5 then
		if not self:CheckTimer(0) then
			self:SetTimer(selfId,005116,"OnSceneTimer",60000)
		end
	end
	-- if sceneId == 1299 then
		-- if not self:CheckTimer(0) then
			-- self:SetTimer(selfId,3000003,"OnSceneTimer",5000)
		-- end
	-- end
	if sceneId == 1303 then
		if not self:CheckTimer(0) then
			self:SetTimer(selfId,3000003,"OnSceneTimer",5000)
		end
	end
	if sceneId == 181 then
		self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 50074, 0)
	end
	if sceneId == 151 and self:LuaFnGetHumanPKValue(selfId) > 4 then
		self:SetPlayerDefaultReliveInfo(selfId, 0.1, -1,0, 151, 48, 30 )
		return
	end
	-- if sceneId == 413 then
	-- 	self:CallScriptFunction(999861, "OnBattlePlayerEnter", selfId)
	-- end	
    if sceneId == 0 or sceneId == 1316 then
		if not self:CheckTimer(0) then
			self:SetTimer(selfId,900019,"OnSceneTimer", 60000)
		end
	end
	
	self:CallScriptFunction(define.UPDATE_CLIENT_ICON_SRIPTID,"OnPlayerUpdateIconDisplay",selfId)
    self:CallScriptFunction(892666, "OnScenePlayerEnter", selfId)
	self:FixDungeonSweep(selfId)
	self:CheckYuanGongSkillOK(selfId)
	self:CallScriptFunction(891062, "OnScenePlayerEnter", selfId)
	--self:ShowChunJieQianDao(selfId)
	--换场景就清空击杀数
	self:SetMissionDataEx(selfId,714,0)

	-- 地府束缚：进入地府时施加不可移动/不可使用技能的buff（右键可取消）
	for _, sid in ipairs(define.SIWANG) do
		if sceneId == sid then
			self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 59901, 0)
			break
		end
	end
	
end

function scene:ShowChunJieQianDao(selfId)
	self:BeginUICommand()
    self:UICommand_AddInt(1)
	self:UICommand_AddInt(1)
    self:EndUICommand()
    self:DispatchUICommand(selfId,89297502)
end

function scene:FixDungeonSweep(selfId)
	local human = self:get_scene():get_obj_by_id(selfId)
	human.dungeonsweep.sec_kill_data = human.dungeonsweep.sec_kill_data or {}
end

function scene:CheckYuanGongSkillOK(selfId)
	local menpai = self:GetMenPai(selfId)
	local yuangong_skill = define.MENPAI_JINZHAN_YUANGONG_SKILL[menpai]
	if not self:HaveSkill(selfId, yuangong_skill) then
		self:AddSkill(selfId, yuangong_skill)
	end
end

function scene:OnScenePlayerLeave(selfId)
	local sceneId = self:GetSceneID()
	if sceneId == 181 then
		self:LuaFnCancelSpecificImpact(selfId,50074)
	end
end

function scene:OnSceneHumanLevelUp(objId,level)
    --对十年任务的检测
    local misIndex
	if self:IsHaveMission(objId,1424) then
        misIndex = self:GetMissionIndexByID(objId,1424)
        self:SetMissionByIndex(objId,misIndex,1,level)
        if level >= 10 then
            self:SetMissionByIndex(objId,misIndex,0,1)
        end
    end
	if level <= 10 then
        local mission_id = 1424
        if self:IsHaveMission(objId, mission_id) then
            misIndex = self:GetMissionIndexByID(objId, mission_id)
            self:SetMissionByIndex(objId,misIndex,1, level)
        end
    end
	-- 给达到等级要求的玩家添加任务
	self:OnAutoAcceptMission(objId,level)
	-- 给满足完成条件的任务设置任务完成标志
	self:OnSetCompleteMission(objId,level)
	--if level == 70 then
		--if not self:LuaFnHaveAgname(objId, 1277) then
			--self:LuaFnAddNewAgname(objId, 1277)
		--end
	--end
end

function scene:OnAutoAcceptMission(objId,level)
	-- 检测任务接受条件
	if self:OnAcceptCheck(objId,level) > 0 then
		local missioninfo = self.AutoAccept_MissionList[level]
		if missioninfo ~= nil then
			local ret = self:AddMission(objId, missioninfo.MissionId, missioninfo.MissionIndex, missioninfo.pKill, missioninfo.pArea, missioninfo.pItem)	-- kill、area、item
			if ret and missioninfo.EventId ~= 0 then
				self:SetMissionEvent(objId, missioninfo.MissionId, missioninfo.EventId )
			end
		end
	end
end

function scene:OnAcceptCheck(objId,level)
	-- 任务是否已满
	if self:IsMissionFull(objId ) then
		return 0
	end
	local missioninfo = self.AutoAccept_MissionList[level]
	--检测等级
	if not missioninfo then
		return 0
	end
	--已经接过则不符合条件
	if self:IsHaveMission(objId, missioninfo.MissionId ) then
		return 0
	end

	--已经做过则不符合条件
	if self:IsMissionHaveDone(objId, missioninfo.MissionId) then
		return 0
	end

	--检测前续任务
	if missioninfo.PreMissionId > 0 then
		if not self:IsMissionHaveDone(objId, missioninfo.PreMissionId) then
			return 0
		end
	end
	return 1
end
--玩家角色登陆游戏事件, 此事件会在玩家调用x888888_OnScenePlayerEnter事件之后调用
function scene:OnScenePlayerLogin(selfId,nowtime)
	local ShenBingTime = self:LuaFnGetWorldGlobalData(99)
	self:SetMissionData(selfId,534,self:GetMissionData(selfId,534))
	local NowTime = self:GetMissionData(selfId,522)
	local NewTime = self:GetDayTime()
	--每日第一个玩家登录记录今日七情类型全局类
	if ShenBingTime ~= tonumber(NewTime) then
		self:LuaFnSetWorldGlobalData(100,math.random(0,6))
		self:LuaFnSetWorldGlobalData(99,tonumber(NewTime))
	end
	--七日豪礼登陆
	local nSevenDay = self:GetMissionData(selfId,520)
	local Feek800Day = self:GetMissionDataEx(selfId,137)
	if NowTime ~= tonumber(NewTime) then
		if nSevenDay < 7 then
			self:SetMissionData(selfId,520,nSevenDay + 1) --记录登陆天数
		end
		if Feek800Day < 7 then
			self:SetMissionDataEx(selfId,137,Feek800Day + 1) --记录登陆天数
		end
		self:SetMissionData(selfId,522,tonumber(NewTime))
	end
	
	local GongZiTime = self:GetMissionDataEx(selfId,715)
	local NewTime = self:GetTime2Day()
	local ret = self:LuaFnHaveImpactOfSpecificDataIndex(selfId, 159)
	-- 工资卡
	if GongZiTime ~= tonumber(NewTime) then
		if ret then
		self:LuaFnCancelSpecificImpact(selfId,159)
		end
		self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 159, 0);
		self:SetMissionDataEx(selfId, 715, tonumber(NewTime)); 
	end
	
    self:CallScriptFunction(define.UPDATE_CLIENT_ICON_SRIPTID, "GetNewDayRestData", selfId,on_line)
	
	-- self:CallScriptFunction(999999, "ResetUI", selfId)
	--self:CallScriptFunction(892679,"CheckGetFullPrize",selfId)
	--新手七日礼结束
	--七日上方图标
	--self:CallScriptFunction(792012,"CheckGetFullPrize",selfId)
	--临时战令上方图标
	--self:CallScriptFunction(792012,"XiaRiZhanLing",selfId)
	--新手上线倒计时领奖
	--self:CallScriptFunction(889103,"OpenFreshManTime",selfId)
	--添加任务十年 初涉江湖
	if not self:IsMissionHaveDone(selfId,1424) then
		local ret = self:AddMission(selfId,1424,210238,1,0,0)
		if ret then
        local misIndex = self:GetMissionIndexByID(selfId,1424)
        self:SetMissionByIndex(selfId,misIndex,1,self:GetLevel(selfId))
			if self:GetLevel(selfId) >= 10 then
				self:SetMissionByIndex(selfId,misIndex,0,1)
			end
		end
    end
	if not self:IsMissionHaveDone(selfId,1400) then
		local ret = self:AddMission(selfId,1400,210262,1,0,0)
		if ret then
			local misIndex = self:GetMissionIndexByID(selfId,1400)
			self:SetMissionByIndex(selfId,misIndex,0,1)
			self:SetMissionByIndex(selfId,misIndex,1,1)
		end
    end
	-- -- local myname = self:GetName(selfId)
	-- local myname = self:GetName(selfId)
	-- local guid = self:LuaFnGetGUID(selfId)
	-- local namelen = string.len(myname)
	-- -- self:SceneBroadcastMsgEx("namelen:"..namelen)
	-- if namelen == 0 then
		-- self:notify_tips(selfId,"角色名异常，你被踢下线了0")
		-- local skynet = require "skynet"
		-- skynet.send(".gamed", "lua", "kick", guid, 0, "maintenance")
		-- return
	-- elseif namelen > 12 then
		-- self:notify_tips(selfId,"角色名异常，你被踢下线了12")
		-- local skynet = require "skynet"
		-- skynet.send(".gamed", "lua", "kick", guid, 0, "maintenance")
		-- return
	-- end
	-- local aid
	-- for i = 1,namelen do
		-- aid = string.byte(myname,i)
		-- if aid then
			-- if aid >= 0 and aid <= 127 then
				-- if not (aid >= 48 and aid <= 57
				-- or aid >= 65 and aid <= 90
				-- or aid >= 97 and aid <= 122) then
					-- self:notify_tips(selfId,"角色名异常，你被踢下线了44")
					-- local skynet = require "skynet"
					-- skynet.send(".gamed", "lua", "kick", guid, 0, "maintenance")
					-- return
				-- end
			-- end
		-- end
	-- end
	-- for i,j in ipairs(define.LIMITSTRING) do
		-- if string.find(myname,j) then
			-- self:notify_tips(selfId,"角色名异常，你被踢下线了99")
			-- local skynet = require "skynet"
			-- skynet.send(".gamed", "lua", "kick", guid, 0, "maintenance")
			-- return
		-- end
	-- end
	-- if ScriptGlobal.is_internal_test then
	-- local msg = "#G当前服务器内测中，可前往#W>#Y洛阳校场#W>#Y活动百晓生#W<#G处可领取免费道具进行体验~"
	-- self:BeginEvent(888888)
	-- self:AddText(msg)
	-- self:EndEvent()
	-- self:DispatchEventList(selfId, selfId)
	-- end
	--local name = self:GetName(selfId)
	--self:LuaFnSendSystemMail(name, [[新功能更新啦！新增夜西湖BOSS活动 新增至尊强化功能 在大理神秘商店处购买相关相关材料  前三天开放强化等级至30级 每过一天+10级 以此类推 祝各位玩家游戏愉快！]])
end
--玩家创建角色后第一次登陆游戏事件, 此事件会在玩家调用x888888_OnScenePlayerEnter事
--件之后、x888888_OnScenePlayerLogin事件之前调用
function scene:OnScenePlayerFirstLogin(selfId,nowtime)
	if self:GetMissionDataEx(selfId,130) > 0 then
		return
	end
	local Beginner_Weapon = {10104000,10101100,10107000,10106000,10105000}
	local randomIndex = math.random(#Beginner_Weapon)
	local randomWeaponId = Beginner_Weapon[randomIndex]
	self:AddMoneyJZ(selfId,28880000)
	--self:AddBindYuanBao(selfId,660000)
	self:CSAddYuanbao(selfId,1000000000)
	self:BeginAddItem()--38008203
	self:AddItem(38008203,1,true)
	self:AddItem(randomWeaponId,1,true)
	self:AddItem(38000958,1,true)
	self:AddItem(20501003,50,true)
	self:AddItem(20502003,50,true)
	self:EndAddItem(selfId)
	self:AddItemListToHuman(selfId)
	if ScriptGlobal.is_internal_test then
		self:BeginAddItem()
		self:EndAddItem(selfId)
		self:AddItemListToHuman(selfId)
	end
	self:SetMissionDataEx(selfId,130,130130)
end


function scene:OnSetCompleteMission(objId,level)
	-- 检测任务完成条件
	if self:OnCompleteCheck(objId,level) > 0 then
		local missioninfo = self.FullLevel_MissionList[level]
		if missioninfo ~= nil then
			local misIndex = self:GetMissionIndexByID(objId,missioninfo.MissionId)
			self:SetMissionByIndex(objId, misIndex, missioninfo.CompleteIdx, 1 )
			self:SetMissionByIndex(objId, misIndex, missioninfo.RecordIdx, 1 )
			self:BeginEvent()
                self:AddText(missioninfo.MsgStr)
			self:EndEvent()
			self:DispatchMissionTips(objId)
		end
	end
end

function scene:OnCompleteCheck(objId,level)
	local missioninfo = self.FullLevel_MissionList[level]
	--检测等级
	if not missioninfo then
		return 0
	end
	if not self:IsHaveMission(objId, missioninfo.MissionId ) then
		return 0
	end
	-- 是否达到需求等级
	local Playerlvl = self:GetLevel(objId)
	if Playerlvl < missioninfo.LevelLimit then
		return 0
	end
	local misIndex = self:GetMissionIndexByID(objId,missioninfo.MissionId)
	-- 检测任务是否完成	
	if self:GetMissionParam(objId, misIndex, missioninfo.CompleteIdx) then
		return 1
	end
	return 0
end

function scene:AskTheWay(...)
    local args = { ... }
    local selfId, sceneNum, x, y, tip
    if #args == 4 then
        selfId, x, y, tip = table.unpack(args)
        sceneNum = self:get_scene_id()
    else
        selfId, sceneNum, x, y, tip = table.unpack(args)
    end
    print("scene:AskTheWay", selfId, sceneNum, x, y, tip)
    self:Msg2Player(selfId, "@*;flagNPC;" .. sceneNum .. ";" .. x .. ";" .. y .. ";" .. tip, define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    self:Msg2Player(selfId, "@*;flashNPC;" .. sceneNum .. ";" .. x .. ";" .. y .. ";" .. tip, define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
end

function scene:AskThePos(...)
    local args = { ... }
    local selfId, sceneNum, x, y, tip
    if #args == 4 then
        selfId, x, y, tip = table.unpack(args)
        sceneNum = self:get_scene_id()
    else
        selfId, sceneNum, x, y, tip = table.unpack(args)
    end
    print("scene:AskThePos", selfId, sceneNum, x, y, tip)
	self:Msg2Player(selfId, "@*;flagPOS;" .. sceneNum .. ";" .. x .. ";" .. y .. ";" .. tip, define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA )
	self:Msg2Player(selfId, "@*;flashPOS;" .. sceneNum .. ";" .. x .. ";" .. y .. ";" .. tip, define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA )
end

function scene:CheckSubmit(selfId, missionId )
	local bHave = self:IsHaveMission(selfId, missionId )
	local bHaveDone = self:IsMissionHaveDone(selfId, missionId )
	-- 没有接
	if not bHave then
		return 0
	end
	-- 已经完成过
	if bHaveDone then
		return 0
	end
	return 1
end

function scene:PlaySoundEffect(selfId, soundId)
    self:BeginUICommand()
    self:UICommand_AddInt(soundId)
    self:EndUICommand()
    self:DispatchUICommand(selfId,1234)
end

--判断是否是帮会主力
function scene:IsGuildVip(Guildpos)
    if (   (Guildpos == 9) 
	    or (Guildpos == 8)
	    or (Guildpos == 7)
	    or (Guildpos == 6)
	    or (Guildpos == 5)
	    or (Guildpos == 4) 
	    or (Guildpos == 3) 
	   )then
        return 1;
		end
		return 0;
end

function scene:OnSceneHumanDie(selfId, killerId)
	-- if selfId == killerId then return end
    local sceneId = self:GetSceneID()
	local SceneType = self:LuaFnGetSceneType()
	if SceneType == 1 then
		local copyscenescript = self:LuaFnGetCopySceneData_Param(1) ; --取得脚本号
		self:CallScriptFunction( copyscenescript, "OnHumanDie",selfId,killerId )
	end
    if sceneId == 191 then
        self:CallScriptFunction(403005,"OnSceneHumanDie",selfId,killerId)
    end
	-- 大乱斗死亡
    -- if sceneId == 413 then
    --     self:CallScriptFunction(999861,"OnSceneHumanDie",selfId,killerId)
    -- end
	--跨服场景要做特殊处理吧，不然会报错
	if not define.IS_KUAFU_SCENE[sceneId] then
		local warscene = self:LuaFnGetCopySceneData_Param(0,66)
		if warscene > 0 and warscene == sceneId then
			local scriptId = self:LuaFnGetCopySceneData_Param(0,67)
			-- local scriptName = self:LuaFnGetCopySceneData_Param(0,68)
			if scriptId > 0 then
				self:CallScriptFunction(scriptId,"OnSceneHumanDie",selfId,killerId)
			end
		end
	end
	
		--连杀提示
	local nTempSceneId = {
		[158] = "Thánh Thú Sơn",
		[420] = "束河古镇",
		[490] = "Băng Tuyết Bất Dạ Thành",
		[715] = "Vĩnh Ninh Thành",
		[1303] = "Tầng bốn Địa Cung Tần Hoàng",
	}
	if nTempSceneId[sceneId] ~= nil then
		local sMessage = ""
		local nDeiMD = self:GetMissionDataEx(selfId,714) --死亡者
		local nKillMD = self:GetMissionDataEx(killerId,714) --击杀者

		local nDeiName = self:GetName(selfId)
		local nKillName = self:GetName(killerId)
		local nGuildName_Dei = self:LuaFnGetGuildName(selfId);
		local nGuildName_Kill = self:LuaFnGetGuildName(killerId)
		local nPosX,nPosY = self:GetWorldPos(killerId)
		
		if nDeiMD > 3 then
			if nGuildName_Dei ~= "" and nGuildName_Kill ~= "" then
				local msg = string.format("#GBang %s#Icó #{_INFOUSR%s} tại#G%s (%d,%d)#Iđối mặt#G#{_INFOUSR%s}#Icủa bang#G%s#Iđang chuỗi giết#G%d#Ingười mà không sợ, tay vung đao chém gục!",
				nGuildName_Kill, nKillName, nTempSceneId[sceneId], nPosX, nPosY, nDeiMD, nGuildName_Dei, nDeiName)
				self:AddGlobalCountNews(msg)
			else
				local msg = string.format("#H%s#Iđối mặt#G%s#Iđang chuỗi giết#cFF0000%d#Ingười mà không hề sợ, tay vung đao chém gục dưới đao!", nKillName, nDeiMD, nDeiName)
				self:AddGlobalCountNews(msg)
			end
		end
		
		if nKillMD >= 2 then
			if nGuildName_Dei ~= "" and nGuildName_Kill ~= "" then
				sMessage = string.format("#GBang %s#Icó #{_INFOUSR%s} tại#G%s (%d,%d)#Isau chuỗi giết#G%d#Ingười lại đánh bại#G#{_INFOUSR%s}#Icủa bang#G%s#I, ai dám tới lấy đầu hắn? Báo thù rửa hận cho %s!",
								  nGuildName_Kill, nKillName, nTempSceneId[sceneId], nPosX, nPosY, nKillMD, nGuildName_Dei, nDeiName, nDeiName)
			else
				sMessage = string.format("#R#{_INFOUSR%s}#Itựa thiên thần nhập thể, không ai cản nổi, tại#G%s#B[%d,%d]#Ichuỗi giết#cFF0000%d#Ingười mà không xây xát!",
								  nKillName, nTempSceneId[sceneId], nPosX, nPosY, nKillMD)
			end
		end

		nKillMD = nKillMD + 1
		self:SetMissionDataEx(killerId,714,nKillMD) --增加击杀者的连击数 死亡者在死亡后传送地府会触发清空连杀数

		-- 广播击杀消息
		if sMessage ~= "" then
			self:AddGlobalCountNews(sMessage)
		end
	end
	
	
	
	--设置杀气达到8进入监狱
	local Vaule = self:LuaFnGetHumanPKValue(killerId)
	-- self:LOGI("KillId = ",self:GetName(killerId))
	-- self:LOGI("selfId = ",self:GetName(selfId))
	-- self:LOGI("KillVaule = ",self:LuaFnGetHumanPKValue(killerId))
	-- self:LOGI("selfVaule = ",self:LuaFnGetHumanPKValue(selfId))
	if Vaule >= 8 then
		self:LuaFnSendSpecificImpactToUnit(killerId,killerId,killerId,42,0)
		self:CallScriptFunction((400900), "TransferFunc", killerId,151,48,30)
	end
	self:OnGuildPvpChatPipe(selfId, killerId)
	

	
end

function scene:OnGuildPvpChatPipe(selfId,killerId)
	-- -- [FIX] 擂台场景过滤：场景 ID 为 92 或 610（擂台PK）时不发帮战公告
	-- local sceneId = self:GetSceneID()
	-- if sceneId == 92 or sceneId == 610 then
	-- 	return
	-- end
	-- -- [FIX] 同帮会过滤：双方帮会相同或任一方无帮会时不发帮战公告
	-- local selfObj = self:get_scene():get_obj_by_id(selfId)
	-- local killerObj = self:get_scene():get_obj_by_id(killerId)
	-- if selfObj == nil or killerObj == nil then
	-- 	return
	-- end
	-- local selfGuildId = selfObj:get_guild_id()
	-- local killerGuildId = killerObj:get_guild_id()
	-- if selfGuildId == define.INVAILD_ID or killerGuildId == define.INVAILD_ID or selfGuildId == killerGuildId then
	-- 	return
	-- end
	--判断击杀玩家和死亡玩家是否拥有帮会。
	local killer = self:get_scene():get_obj_by_id(killerId)
	if killer:get_obj_type() ~= "human" then
		return
	end
	local nSelfGuildPos = self:GetGuildPos(selfId)
	local nKillGuildPos = self:GetGuildPos(killerId)
	if self:IsGuildVip(nSelfGuildPos) > 0 then
		local selfName = self:GetName(selfId);
		local killerName = self:GetName(killerId);
		local guildName_killer = self:LuaFnGetGuildName(killerId);
		local sMessage = string.format(gbk.fromutf8("@*;SrvMsg;GLD:#WChủ lực bổn bang#R%s#Wtrong bang chiến dốc máu chiến đấu, không địch lại bang hội #G%s#Wcủa#R%s#W, anh dũng hi sinh vì bang hội!"), gbk.fromutf8(selfName),gbk.fromutf8(guildName_killer),gbk.fromutf8(killerName));
		if guildName_killer == "" then
			sMessage = string.format(gbk.fromutf8("@*;SrvMsg;GLD:#WChủ lực bổn bang#R%s#Whuyết chiến trong bang chiến, không địch nổi#R%s#W, anh dũng hiến thân vì bang!"), gbk.fromutf8(selfName),gbk.fromutf8(killerName));
		end
		self:BroadMsgByChatPipe(selfId,sMessage,6);
	end
	if self:IsGuildVip(nKillGuildPos) > 0 then
		local sMessage = ""
		local selfName = self:GetName(selfId);
		local guildName_self = self:LuaFnGetGuildName(selfId);
		local killerName = self:GetName(killerId);
		if guildName_self ~= "" then
			sMessage = string.format(gbk.fromutf8("@*;SrvMsg;GLD:#R%s#W đã đại triển thân thủ trong bang chiến, thành công tiêu diệt #G%s#W chủ lực bang hội #R%s#W, bảo vệ vinh dự của bang hội!"), gbk.fromutf8(killerName), gbk.fromutf8(guildName_self), gbk.fromutf8(selfName));
			self:BroadMsgByChatPipe(killerId,sMessage,6);
		end
	end
end

function scene:OnInitScene(...)
    local sceneId = self:get_scene_id()
    if sceneId == 414 then
        self:CallScriptFunction((125020), "OnInitScene", ...)
	end
end


function scene:OnNewDay(selfId)
    self:CallScriptFunction(define.UPDATE_CLIENT_ICON_SRIPTID, "GetNewDayRestData", selfId)
end

function scene:LuaFnDelNewAgname(selfId, del_id)
    local human = self:get_scene():get_obj_by_id(selfId)
    local id_titles = human.id_titles
	for i = #id_titles, 1, -1 do
		local title = id_titles[i]
		if title.id == del_id then
			table.remove(id_titles, i)
			break
		end
	end
    human:update_titles_to_client()
end

function scene:GetFreeObjCount()
	local objs = self.scene.objs
	local free_count = 0
	for i = 1, define.MAX_OBJ_ID do
		if objs[i] == nil then
			free_count = free_count + 1
		end
	end
	local skynet = require "skynet"
	skynet.logi("GetFreeObjCount free_count =", free_count)
end

function scene:LogPetObjStatus()
	local objs = self.scene.objs
	for i = 1, define.MAX_OBJ_ID do
		local obj = objs[i]
		if obj then
			local otype = obj:get_obj_type()
			if otype == "pet" then
				local owner = obj:get_owner()
				if owner and owner:get_obj_type() ~= "human" then
					local skynet = require "skynet"
					skynet.logi("LogPetObjStatus wrong error obj_type =", owner:get_obj_type(), ", error obj_id =", owner:get_obj_id(), ", pet world pos =", table.tostr(obj:get_world_pos()))
				end
			end
		end
	end
end

function scene:DebugMode()
	local skynet = require "skynet"
	_ENV.print = skynet.logi
end

function scene:LogObjStatus()
	local obj_id_status = {}
	local objs = self.scene.objs
	for i = 1, define.MAX_OBJ_ID do
		if objs[i] then
			obj_id_status[i] = true
		end
	end
	local skynet = require "skynet"
	skynet.logi("LogObjStatus obj_id_status =", table.tostr(obj_id_status), ", now_obj_id =", self.scene.now_obj_id)
end

function scene:HotFix_GenObjID()
	local scenecore = self.scene
	scenecore.gen_obj_id = function(core)
		while true do
			core.now_obj_id = core.now_obj_id + 1
			local now = core.now_obj_id
			if now >= define.MAX_OBJ_ID then
				core.now_obj_id = 1
			elseif core.objs[now] == nil then
				return now
			end
		end
	end
end

function scene:HotUpdateClientRes()
	local s = self:get_scene()
	s.client_res = 0
end

function scene:BanPiaoPiaoTuOwners()
	local skynet = require "skynet"
	local objs = self.scene.objs
	for i = 1, define.MAX_OBJ_ID do
		local obj = objs[i]
		if obj and obj:get_obj_type() == "human" then
			local current_pet_guid = obj:get_current_pet_guid()
			local ride_model = obj:get_ride_model()
			local team_id = obj:get_team_id()
			local level = obj:get_level()
			if current_pet_guid ~= define.INVAILD_ID then
				local current_pet = obj:get_pet_bag_container():get_pet_by_guid(current_pet_guid)
				if current_pet then
					local data_index = current_pet:get_data_index()
					if (data_index == 559 or data_index == 3069) and (ride_model == 45 or ride_model == 62) and (level <= 35) then
						local str = skynet.call(".gamed", "lua", "query_roler_account", string.format("%x", obj:get_guid()))
						local _, account = string.match(str, "GUID是(%d+)的玩家的账号是 (.+)")
						self:LOGI("BanPiaoPiaoTuOwners account =", account)
						if account then
							skynet.send(".gamed", "lua", "ban_user", account)
						end
					end
				end
			else
				if (obj:is_moving()) and (ride_model == 45 or ride_model == 62) and level <= 35 then
					local str = skynet.call(".gamed", "lua", "query_roler_account", string.format("%x", obj:get_guid()))
					local _, account = string.match(str, "GUID是(%d+)的玩家的账号是 (.+)")
					self:LOGI("BanPiaoPiaoTuOwners account =", account)
					if account then
						skynet.send(".gamed", "lua", "ban_user", account)
					end
				end
			end
		end
	end
end

function scene:KickAllUsers()
	local skynet = require "skynet"
	local objs = self.scene.objs
	for i = 1, define.MAX_OBJ_ID do
		local obj = objs[i]
		if obj and obj:get_obj_type() == "human" then
			local guid = obj:get_guid()
			skynet.send(".gamed", "lua", "kick", guid, 0, "maintenance")
		end
	end
end

function scene:DaLiRandomScene()
	local skynet = require "skynet"
	local objs = self.scene.objs
	for i = 1, define.MAX_OBJ_ID do
		local obj = objs[i]
		if obj and obj:get_obj_type() == "human" then
			local world_Pos = obj:get_world_pos()
			local to_scene_ids = { 71, 72, 1320, 1321 }
			local to_scene_id = to_scene_ids[math.random(1, #to_scene_ids)]
			self:CallScriptFunction((400900), "TransferFunc", obj:get_obj_id(), to_scene_id, world_Pos.x, world_Pos.y)
		end
	end
end

function scene:HitFix_ask_base_attrib()
	local scenecore = self:get_scene()
	local packet_def = require "game.packet"
	local skynet = require "skynet"
	scenecore.ask_base_attrib = function(self, whos, to)
		skynet.logi("HitFix_ask_base_attrib ok")
		print("ask_base_attrib whos =", whos, ";to =", to)
		local obj = self.objs[whos]
		if obj and obj:is_character_obj() then
			local obj_base_attr = obj:get_base_attribs()
			local ret = packet_def.GCCharBaseAttrib.new()
			if obj:get_obj_type() == "human" then
				ret.m_objID = whos
				ret.m_uFlags = {255, 191, 175, 247, 255, 143, 255, 5, 0, 0, 0, 0, 0, 0}  -- 14 flags for client compatibility
				-- 新增 ornaments 标志和值写入
				ret.m_uFlags[10] = ret.m_uFlags[10] | 0x4
				ret.m_uFlags[10] = ret.m_uFlags[10] | 0x8
				local back_id, back_pos = obj:get_exterior_back_visual_id()
				local head_id, head_pos = obj:get_exterior_head_visual_id()
				ret:set_exterior_back_id(back_id)
				ret:set_exterior_back_pos(back_pos)
				ret:set_exterior_head_id(head_id)
				ret:set_exterior_head_pos(head_pos)
				for k, v in pairs(obj_base_attr) do ret[k] = v end
				ret:set_speed(obj:get_attrib("speed"))
				ret:set_name(obj:get_attrib("name"))
				ret:set_new_player_set(obj:get_attrib("new_player_set"))
				ret:set_server_id(obj:get_attrib("server_id"))
				ret:set_title(obj:get_attrib("title"))
				ret:set_ride_model(obj:get_attrib("ride_model"))
				ret:set_portrait_id(obj:get_attrib("portrait_id"))
				ret:set_model_id(obj:get_attrib("model_id"))
				ret:set_stealth_level(obj:get_attrib("stealth_level"))
				ret:set_hp_percent(math.ceil(obj:get_hp() / obj:get_max_hp()* 100))
				ret:set_mp_percent(math.ceil(obj:get_mp() / obj:get_max_mp()* 100))
				ret:set_rage(obj:get_attrib("rage"))
				ret:set_is_sit(obj:get_attrib("is_sit"))
				ret:set_attack_speed(obj:get_attrib("attack_speed"))
				ret:set_pk_mode(obj:get_attrib("pk_mode"))
				ret:set_reputation(obj:get_attrib("reputation"))
				ret:set_is_in_team(obj:get_attrib("is_in_team"))
				ret:set_is_team_leader(obj:get_attrib("is_team_leader"))
				ret:set_camp_id(obj:get_attrib("camp_id"))
				ret:set_attackers_list(obj:get_attackers():get_list())
				ret:set_pk_declaration_list(obj:get_pk_declaration_list():get_list())
				ret:set_wild_war_guilds(obj:get_wild_war_guilds():get_list())
				ret:set_raid_occipant_guid(obj:get_raid_occipant_guid())  -- 新增 raid_occipant_guid
				local stall_box = obj:get_stall_box()
				ret:set_stall_is_open(stall_box:get_stall_is_open())
				if stall_box:get_stall_is_open() then
					ret:set_stall_name(stall_box:get_stall_name())
				end
				self:send2client(to, ret)
				skynet.timeout(5,function()
					ret = packet_def.GCCharBaseAttrib.new()
					ret.m_objID = whos
					ret:set_pk_value(obj:get_pk_value())
					ret:set_pet_soul_melting_model(obj:get_attrib("pet_soul_melting_model"))
					self:send2client(to, ret)
				end)
			elseif obj:get_obj_type() == "pet" then
				local hp_percent =  math.ceil(obj:get_hp() / obj:get_max_hp() * 100)
				ret.m_objID = whos
				ret.m_uFlags = { 251, 54, 96, 16, 100, 96, 0, 192, 0, 0, 0, 0, 0, 0 }  -- 14 flags for client compatibility
				ret:set_name(obj_base_attr.name)
				ret:set_title(obj_base_attr.title)
				ret:set_current_title(obj_base_attr.current_title)
		
				ret.model = obj:get_model()
				ret.ride_model = define.INVAILD_ID
				ret.hp_percent = hp_percent
				ret.mp_percent = 0
				ret.speed = obj:get_speed()
				ret.data_id = obj:get_data_id()
				ret.level = obj:get_level()
				ret.stealth_level = obj:get_stealth_level()
				ret.attack_speed = 100
				ret.guid = -1
				ret.model_id = -1
				ret.owner_id = obj:get_owner_obj_id()
				ret.rage = 0
				ret.reputation = -1
				ret.rider_model = -1
				ret.unknow_43 = -1
				ret.unknow_50 = 2
				ret.unknow_51 = -1
				ret.pet_soul_item_index = -1
				ret.unknow_62 = 0
				self:send2client(to, ret)
			else
				local hp_percent = math.ceil(obj:get_hp() / obj:get_max_hp() * 100)
				ret.m_objID = whos
				ret.m_uFlags = {255, 119, 48, 16, 100, 0, 0, 48, 0, 0, 0, 0, 0, 0}  -- 14 flags for client compatibility
				ret:set_name(obj_base_attr.name)
				ret:set_title(obj_base_attr.title)
				ret:set_occupant_guid(obj:get_occupant_guid())
				ret:set_team_occipant_guid(obj:get_team_occipant_guid())
				ret:set_raid_occipant_guid(obj:get_raid_occipant_guid())  -- 新增 raid_occipant_guid
				local camp_id = obj:get_camp_id()
				if camp_id <= 15 then
					camp_id = define.INVAILD_ID
				end
				ret:set_camp_id(camp_id)
				ret.model = obj_base_attr.model
				ret.ride_model = define.INVAILD_ID
				ret.speed = obj:get_speed()
				ret.data_id = obj:get_data_id()
				ret.is_sit = -1
				ret.attack_speed = 100
				ret.model_id = -1
				ret.ai_type = obj:get_ai():is_active_attack() and 0 or 1
				ret.owner_id = -1
				ret.guid = obj:get_guid()
				ret.unknow_43 = -1
				ret.reputation = obj:get_reputation()
				ret.level = obj:get_level()
				ret.unknow_56 = 65535
				ret.unknow_57 = 4294967295
				ret.mp_percent = obj:is_npc() and 100 or 0
				ret.hp_percent = hp_percent
				ret.rage = 0
				ret.stealth_level = obj:get_stealth_level()
				ret.occupant_guid = obj:get_occupant_guid()
				self:send2client(to, ret)
			end
		end
	end
end

function scene:HotIfx_exchange_iii()
	local scenecore = self:get_scene()
	local packet_def = require "game.packet"
	local skynet = require "skynet"
	local human_item_logic = require "human_item_logic"
	local item_operator = require "item_operator":getinstance()
	scenecore.char_exchange_ok_III = function(self, who, eo)
		skynet.logi("HotIfx_exchange_iii")
		local obj_me = self:get_obj_by_id(who)
		local my_exchange_box = obj_me:get_exchange_box()
		if not self:exchange_certify_each_other(obj_me) then
			return
		end
		local obj_tar = self:get_obj_by_id(my_exchange_box:get_dest())
		if not self:check_exchange_vaild(obj_me, obj_tar) then
			return
		end
		local tar_exchange_box = obj_tar:get_exchange_box()
		if my_exchange_box:get_status() == my_exchange_box.STATUS.EXCHANGE_WAIT_FOR_CONFIRM then
			my_exchange_box:set_status(my_exchange_box.STATUS.EXCHANGE_CONFIRM_READY)
			if tar_exchange_box:get_status() == my_exchange_box.STATUS.EXCHANGE_CONFIRM_READY then
				local item_list_to_tar = {}
				local item_list_to_me = {}
				local pet_list_to_tar = {}
				local pet_list_to_me = {}
	
				local my_exchange_item_container = my_exchange_box:get_item_container()
				local my_exchange_pet_container = my_exchange_box:get_pet_container()
				local tar_exchange_item_container = tar_exchange_box:get_item_container()
				local tar_exchange_pet_container = tar_exchange_box:get_pet_container()
	
				for i = 0, define.EXCHANGE_BOX_SIZE - 1 do
					do
						local item = my_exchange_item_container:get_item(i)
						if item then
							table.insert(item_list_to_tar, item)
						end
					end
					do
						local item = tar_exchange_item_container:get_item(i)
						if item then
							table.insert(item_list_to_me, item)
						end
					end
				end
				for i = 0, define.EXCHANGE_BOX_SIZE - 1 do
					do
						local pet = my_exchange_pet_container:get_item(i)
						if pet then
							table.insert(pet_list_to_tar, pet)
						end
					end
					do
						local pet = tar_exchange_pet_container:get_item(i)
						if pet then
							table.insert(pet_list_to_me, pet)
						end
					end
				end
				if not human_item_logic:can_recive_exchange_item_list(obj_me, item_list_to_me, pet_list_to_me) then
					local msg = packet_def.GCExchangeError.new()
					msg.error_code = define.EXCHANGE_ERR.ERR_NOT_ENOUGHT_ROOM_SELF
					self:send2client(obj_me, msg)
	
					local msg = packet_def.GCExchangeError.new()
					msg.error_code = define.EXCHANGE_ERR.ERR_NOT_ENOUGHT_ROOM_OTHER
					self:send2client(obj_tar, msg)
					my_exchange_box:reset()
					tar_exchange_box:reset()
					return  
				end
				if not human_item_logic:can_recive_exchange_item_list(obj_tar, item_list_to_tar, pet_list_to_tar) then
					local msg = packet_def.GCExchangeError.new()
					msg.error_code = define.EXCHANGE_ERR.ERR_NOT_ENOUGHT_ROOM_SELF
					self:send2client(obj_tar, msg)
	
					local msg = packet_def.GCExchangeError.new()
					msg.error_code = define.EXCHANGE_ERR.ERR_NOT_ENOUGHT_ROOM_OTHER
					self:send2client(obj_me, msg)
					my_exchange_box:reset()
					tar_exchange_box:reset()
					return
				end
				if my_exchange_box:get_money() > obj_me:get_money() then
					local msg = packet_def.GCExchangeError.new()
					msg.error_code = define.EXCHANGE_ERR.ERR_NOT_ENOUGHT_MONEY_SELF
					self:send2client(obj_me, msg)
	
					local msg = packet_def.GCExchangeError.new()
					msg.error_code = define.EXCHANGE_ERR.ERR_NOT_ENOUGHT_MONEY_OTHER
					self:send2client(obj_tar, msg)
					my_exchange_box:reset()
					tar_exchange_box:reset()
					return
				end
				if tar_exchange_box:get_money() > obj_tar:get_money() then
					local msg = packet_def.GCExchangeError.new()
					msg.error_code = define.EXCHANGE_ERR.ERR_NOT_ENOUGHT_MONEY_SELF
					self:send2client(obj_tar, msg)
	
					local msg = packet_def.GCExchangeError.new()
					msg.error_code = define.EXCHANGE_ERR.ERR_NOT_ENOUGHT_MONEY_OTHER
					self:send2client(obj_me, msg)
					my_exchange_box:reset()
					tar_exchange_box:reset()
					return
				end
				local my_pet_guid = obj_me:get_current_pet_guid()
				local tar_pet_guid = obj_tar:get_current_pet_guid()
				for i = 0, define.EXCHANGE_BOX_SIZE - 1 do
					do
						local pet = my_exchange_pet_container:get_item(i)
						if pet then
							local pet_level = pet:get_level()
							local human_level = obj_tar:get_level()
							if pet_level > human_level then
								local msg = packet_def.GCExchangeError.new()
								msg.error_code = define.EXCHANGE_ERR.ERR_PET_LEVEL_TOO_HIGH
								self:send2client(obj_me, msg)
								self:send2client(obj_tar, msg)
								my_exchange_box:reset()
								tar_exchange_box:reset()
								return
							end
							if pet:get_guid() == my_pet_guid then
								obj_me:recall_pet()
							end
						end
					end
					do
						local pet = tar_exchange_pet_container:get_item(i)
						if pet then
							local pet_level = pet:get_level()
							local human_level = obj_me:get_level()
							if pet_level > human_level then
								local msg = packet_def.GCExchangeError.new()
								msg.error_code = define.EXCHANGE_ERR.ERR_PET_LEVEL_TOO_HIGH
								self:send2client(obj_me, msg)
								self:send2client(obj_tar, msg)
								my_exchange_box:reset()
								tar_exchange_box:reset()
								return
							end
							if pet:get_guid() == tar_pet_guid then
								obj_tar:recall_pet()
							end
						end
					end
				end
				local msg_exchange_succ_to_me = packet_def.GCExchangeSuccessIII.new()
				local msg_exchange_succ_to_tar = packet_def.GCExchangeSuccessIII.new()
				msg_exchange_succ_to_me.guid = obj_tar:get_guid()
				msg_exchange_succ_to_tar.guid = obj_me:get_guid()
				local ex_item_index_in_me = {}
				local ex_item_index_in_tar = {}
				local ex_pet_index_in_me = {}
				local ex_pet_index_in_tar = {}
				local ex_items_in_me = {}
				local ex_pets_in_me = {}
				local ex_items_in_tar = {}
				local ex_pets_in_tar = {}
				local my_prop_bag_container = obj_me:get_prop_bag_container()
				local tar_prop_bag_container = obj_tar:get_prop_bag_container()
				local my_pet_bag_container = obj_me:get_pet_bag_container()
				local tar_pet_bag_container = obj_tar:get_pet_bag_container()
				for i = 0, define.EXCHANGE_BOX_SIZE - 1 do
					do
						local item = my_exchange_item_container:get_item(i)
						if item then
							if item:is_bind() then
								return
							end
							local bag_index = my_prop_bag_container:get_index_by_guid(item:get_guid())
							item:set_in_exchange(false)
							item_operator:unlock_item(my_prop_bag_container, bag_index)
							local empty_index = tar_prop_bag_container:get_empty_item_index(item:get_place_bag())
							my_prop_bag_container:erase_item(bag_index)
							tar_prop_bag_container:set_item(empty_index, item)
							local it = {}
							it.from_type = packet_def.CGExchangeSynchItemII.POS.POS_BAG
							it.from_index = i
							it.to_type = packet_def.CGExchangeSynchItemII.POS.POS_BAG
							it.to_index = empty_index
							table.insert(msg_exchange_succ_to_tar.item_list, it)
							table.insert(ex_items_in_me, item:copy_raw_data())
						end
					end
					do
						local item = tar_exchange_item_container:get_item(i)
						if item then
							if item:is_bind() then
								return
							end
							local bag_index = tar_prop_bag_container:get_index_by_guid(item:get_guid())
							item:set_in_exchange(false)
							item_operator:unlock_item(tar_prop_bag_container, bag_index)
							local empty_index = my_prop_bag_container:get_empty_item_index(item:get_place_bag())
							tar_prop_bag_container:erase_item(bag_index)
							my_prop_bag_container:set_item(empty_index, item)

							local it = {}
							it.from_type = packet_def.CGExchangeSynchItemII.POS.POS_BAG
							it.from_index = i
							it.to_type = packet_def.CGExchangeSynchItemII.POS.POS_BAG
							it.to_index = empty_index
							table.insert(msg_exchange_succ_to_me.item_list, it)
							table.insert(ex_items_in_tar, item:copy_raw_data())
						end
					end
				end
				for i = 0, define.EXCHANGE_BOX_SIZE - 1 do
					do
						local pet = my_exchange_pet_container:get_item(i)
						if pet then
							local bag_index = my_pet_bag_container:get_index_by_pet_guid(pet:get_guid())
							pet:set_in_exchange(false)
							item_operator:unlock_item(my_pet_bag_container, bag_index)
							local empty_index = tar_pet_bag_container:get_empty_item_index()
							my_pet_bag_container:erase_item(bag_index)
							tar_pet_bag_container:set_item(empty_index, pet)

							local it = {}
							it.from_type = packet_def.CGExchangeSynchItemII.POS.POS_PET
							it.from_index = i
							it.to_type = packet_def.CGExchangeSynchItemII.POS.POS_PET
							it.to_index = empty_index
							table.insert(msg_exchange_succ_to_tar.item_list, it)
							table.insert(ex_pets_in_me, pet:copy_raw_data())
						end
					end
					do
						local pet = tar_exchange_pet_container:get_item(i)
						if pet then
							local bag_index = tar_pet_bag_container:get_index_by_pet_guid(pet:get_guid())
							pet:set_in_exchange(false)
							item_operator:unlock_item(tar_pet_bag_container, bag_index)
							local empty_index = my_pet_bag_container:get_empty_item_index()
							tar_pet_bag_container:erase_item(bag_index)
							my_pet_bag_container:set_item(empty_index, pet)

							local it = {}
							it.from_type = packet_def.CGExchangeSynchItemII.POS.POS_PET
							it.from_index = i
							it.to_type = packet_def.CGExchangeSynchItemII.POS.POS_PET
							it.to_index = empty_index
							table.insert(msg_exchange_succ_to_me.item_list, it)
							table.insert(ex_pets_in_tar, pet:copy_raw_data())
						end
					end
				end
				if my_exchange_box:get_money() > 0 and my_exchange_box:get_money() <= obj_me:get_money() then
					obj_me:set_money(obj_me:get_money() - my_exchange_box:get_money(), "Giao dịch thành công - người chơi trừ tiền")
					obj_tar:set_money(obj_tar:get_money() + my_exchange_box:get_money(), "Giao dịch thành công - đối phương cộng tiền")
				end
				if tar_exchange_box:get_money() > 0 and tar_exchange_box:get_money() <= obj_tar:get_money() then
					obj_tar:set_money(obj_tar:get_money() - tar_exchange_box:get_money(), "Giao dịch thành công - người chơi trừ tiền")
					obj_me:set_money(obj_me:get_money() + tar_exchange_box:get_money(), "Giao dịch thành công - đối phương cộng tiền")
				end
				self:send2client(obj_me, msg_exchange_succ_to_me)
				self:send2client(obj_tar, msg_exchange_succ_to_tar)
				my_exchange_box:reset()
				tar_exchange_box:reset()
				self:log_exchange_prop_or_pet("Giao dịch giữa người chơi", "Giao dịch", ex_items_in_me, ex_items_in_tar, ex_pets_in_me, ex_pets_in_tar, obj_me, obj_tar)
			end
		else
			local msg = packet_def.GCExchangeError.new()
			msg.error_code = define.EXCHANGE_ERR.ERR_ILLEGAL
			self:send2client(obj_me, msg)
		end
	end
end

function scene:HotFix_Stall_Buy()
	local scenecore = self:get_scene()
	local packet_def = require "game.packet"
	local skynet = require "skynet"
	local human_item_logic = require "human_item_logic"
	local item_operator = require "item_operator":getinstance()
	local item_guid = require "guid"
	local pet_guid = require "pet_guid"
	scenecore.char_stall_buy = function(self, who, sb)
		skynet.logi("HotFix_Stall_Buy")
		local obj = self.objs[who]
		local stall_human = self.objs[sb.m_objID]
		local stall_box = stall_human:get_stall_box()
		if stall_box:get_stall_status() ~= stall_box.STALL_STATUS.STALL_OPEN then
			local msg = packet_def.GCStallError.new()
			msg.result = msg.STALL_MSG.ERR_ILLEGAL
			self:send2client(obj, msg)
			return
		end
		local msg = packet_def.GCStallBuy.new()
		msg.m_objID = stall_human:get_obj_id()
		local iid = item_guid.new()
		iid:set_guid(sb.item_guid)
		local ex_items_in_me = {}
		local ex_items_in_tar = {}
		local ex_pets_in_me = {}
		local ex_pets_in_tar = {}
		if iid:vaild() then
			local index = stall_box:get_container():get_index_by_guid(iid)
			if index == nil then
				msg = packet_def.GCStallError.new()
				msg.result = msg.STALL_MSG.ERR_NEED_NEW_COPY
				self:send2client(obj, msg)
				return
			end
			if sb.serial < stall_box:get_serial_by_index(index) then
				msg = packet_def.GCStallError.new()
				msg.result = msg.STALL_MSG.ERR_NEED_NEW_COPY
				self:send2client(obj, msg)
				return
			end
			local my_prop_bag_container = obj:get_prop_bag_container()
			local stall_prop_bag_container = stall_human:get_prop_bag_container()
			local bag_index = stall_prop_bag_container:get_index_by_guid(iid)
			if bag_index == define.INVAILD_ID then
				msg = packet_def.GCStallError.new()
				msg.result = msg.STALL_MSG.ERR_ILLEGAL
				self:send2client(obj, msg)
			end
			local item = stall_prop_bag_container:get_item(bag_index)
			if item:is_bind() then
				return
			end
			local item_table_index = item:get_index()
			local item_num = item:get_lay_count()
			local ok = human_item_logic:calc_item_space(obj, item_table_index, item_num, false)
			if not ok then
				msg = packet_def.GCStallError.new()
				msg.result = msg.STALL_MSG.ERR_NOT_ENOUGH_ROOM
				self:send2client(obj, msg)
				return
			end
			local need_money = stall_box:get_price_by_index(index)
			local my_money
			if stall_box:get_is_yuanbao_stall() then
				my_money = obj:get_yuanbao()
			else
				my_money = obj:get_money() 
			end
			if need_money > my_money then
				msg = packet_def.GCStallError.new()
				msg.result = msg.STALL_MSG.ERR_NOT_ENOUGH_MONEY
				self:send2client(obj, msg)
				return
			end
			local dest_index = my_prop_bag_container:get_empty_item_index(item:get_place_bag())
			if dest_index == define.INVAILD_ID then
				msg = packet_def.GCStallError.new()
				msg.result = msg.STALL_MSG.ERR_NOT_ENOUGH_ROOM
				self:send2client(obj, msg)
				return
			end
			local logparam = {}
			item_operator:unlock_item(stall_prop_bag_container, bag_index)
			local result = human_item_logic:move_item_from_container_to_bag_with_index(logparam, obj, stall_prop_bag_container, bag_index, dest_index)
			if result then
				if stall_box:get_is_yuanbao_stall() then
					obj:set_yuanbao(obj:get_yuanbao() - need_money, "Sạp nguyên bảo - phí mua", { item = item and item:copy_raw_data() })
				else
					obj:set_money(obj:get_money() - need_money, "Sạp kim tệ - phí mua", { item = item and item:copy_raw_data() })
				end
				local trade_tax = stall_box:get_trade_tax()
				trade_tax = trade_tax > 100 and 100 or trade_tax
	
				local profit = need_money * (1 - trade_tax / 100)
				profit = math.floor(profit)
				if stall_box:get_is_yuanbao_stall() then
					stall_human:set_yuanbao(stall_human:get_yuanbao() + profit, "Sạp nguyên bảo - bán đạo cụ", { item = item and item:copy_raw_data() })
				else
					stall_human:set_money(stall_human:get_money() + profit, "Sạp kim tệ - bán đạo cụ", { item = item and item:copy_raw_data() })
				end
				stall_box:inc_serial_by_index(index)
				stall_box:set_price_by_index(index, 0)
				stall_box:get_container():erase_item(index)
	
				msg.to_type = 1
				msg.item_guid = sb.item_guid
				msg.pet_guid = sb.pet_guid
				msg.serial = stall_box:get_serial_by_index(index)
				msg.to_index = dest_index
				msg.cost = need_money
				msg.profit = profit
				self:send2client(obj, msg)
				self:send2client(stall_human, msg)
	
				local message
				local author
				if stall_box:get_is_yuanbao_stall() then
					message   = string.format("#{_INFOUSR%s} mua #{_INFOMSG%%s} X %d, tổng tốn %d nguyên bảo", obj:get_name(), item_num, need_money)
					author = "_SYSTEM"
				else
					local Gold	    = (need_money/10000)
					local Silver	= ((need_money%10000)/100)
					local copper	= (need_money%100)
					message   = string.format("#{_INFOUSR%s} mua #{_INFOMSG%%s} X %d, tổng tốn %d kim %d ngân %d đồng", obj:get_name(), item_num, Gold, Silver, copper)
					author = "_SYSTEM"
				end
				local bbs = stall_box:get_bbs()
				local new_id = bbs:new_message_id()
				local transfer = item:get_transfer()
				bbs:add_new_message_by_id(new_id, message, transfer, author)
				table.insert(ex_items_in_me, item:copy_raw_data())
			else
				msg = packet_def.GCStallError.new()
				msg.result = msg.STALL_MSG.ERR_ILLEGAL
				self:send2client(obj, msg)
			end
			self:log_exchange_prop_or_pet("Giao dịch giữa người chơi", "Bày sạp bán", ex_items_in_me, ex_items_in_tar, ex_pets_in_me, ex_pets_in_tar, stall_human, obj)
			return
		end
		local pid = pet_guid.new()
		pid:set(sb.pet_guid.m_uHighSection, sb.pet_guid.m_uLowSection)
		if not pid:is_null() then
			local index = stall_box:get_pet_box_container():get_index_by_pet_guid(pid)
			if index == nil then
				msg = packet_def.GCStallError.new()
				msg.result = msg.STALL_MSG.ERR_NEED_NEW_COPY
				self:send2client(obj, msg)
				return
			end
			if sb.serial < stall_box:get_pet_serial_by_index(index) then
				msg = packet_def.GCStallError.new()
				msg.result = msg.STALL_MSG.ERR_NEED_NEW_COPY
				self:send2client(obj, msg)
				return
			end
			local pet_container = stall_human:get_pet_bag_container()
			local bag_index = pet_container:get_index_by_pet_guid(pid)
			if bag_index == define.INVAILD_ID then
				msg = packet_def.GCStallError.new()
				msg.result = msg.STALL_MSG.ERR_ILLEGAL
				self:send2client(obj, msg)
			end
			local pet = pet_container:get_item(bag_index)
			if pet == nil then
				msg = packet_def.GCStallError.new()
				msg.result = msg.STALL_MSG.ERR_ILLEGAL
				self:send2client(obj, msg)
			end
			local my_pet_container = obj:get_pet_bag_container()
			local dest_index = my_pet_container:get_empty_item_index()
			if dest_index == define.INVAILD_ID then
				msg = packet_def.GCStallError.new()
				msg.result = msg.STALL_MSG.ERR_NOT_ENOUGH_ROOM
				self:send2client(obj, msg)
				return
			end
			local need_money = stall_box:get_pet_price_by_index(index)
			local my_money
			if stall_box:get_is_yuanbao_stall() then
				my_money = obj:get_yuanbao()
			else
				my_money = obj:get_money() 
			end
			if need_money > my_money then
				msg = packet_def.GCStallError.new()
				msg.result = msg.STALL_MSG.ERR_NOT_ENOUGH_MONEY
				self:send2client(obj, msg)
				return
			end
			local logparam = {}
			item_operator:unlock_item(pet_container, bag_index)
			local result = item_operator:move_item(pet_container, bag_index, my_pet_container, dest_index)
			if result then
				if stall_box:get_is_yuanbao_stall() then
					obj:set_yuanbao(obj:get_yuanbao() - need_money, "Sạp nguyên bảo - mua pet", { pet = pet and pet:copy_raw_data() })
				else
					obj:set_money(obj:get_money() - need_money, "Sạp kim tệ - mua pet", { pet = pet and pet:copy_raw_data() })
				end
				local trade_tax = stall_box:get_trade_tax()
				trade_tax = trade_tax > 100 and 100 or trade_tax
	
				local profit = need_money * (1 - trade_tax / 100)
				profit = math.floor(profit)
				if stall_box:get_is_yuanbao_stall() then
					stall_human:set_yuanbao(stall_human:get_yuanbao() + profit, "Sạp nguyên bảo - bán pet", { pet = pet and pet:copy_raw_data() })
				else
					stall_human:set_money(stall_human:get_money() + profit, "Sạp kim tệ - mua pet", { pet = pet and pet:copy_raw_data() })
				end
				stall_box:inc_pet_serial_by_index(index)
				stall_box:set_pet_price_by_index(index, 0)
				stall_box:get_pet_box_container():erase_item(index)
	
				msg.to_type = 3
				msg.item_guid = sb.item_guid
				msg.pet_guid = sb.pet_guid
				msg.serial = stall_box:get_pet_serial_by_index(index)
				msg.to_index = dest_index
				msg.cost = need_money
				msg.profit = profit
				self:send2client(obj, msg)
				self:send2client(stall_human, msg)
	
				local message
				local author
				if stall_box:get_is_yuanbao_stall() then
					message   = string.format("%s mua #{_INFOMSG%%s}, tổng tốn %d nguyên bảo", obj:get_name(), need_money)
					author = "_SYSTEM"
				else
					local Gold	    = (need_money/10000)
					local Silver	= ((need_money%10000)/100)
					local copper	= (need_money%100)
					message   = string.format("%s mua #{_INFOMSG%%s}, tổng tốn %d kim %d ngân %d đồng", obj:get_name(), Gold, Silver, copper)
					author = "_SYSTEM"
				end
				local bbs = stall_box:get_bbs()
				local new_id = bbs:new_message_id()
				local transfer  = pet:get_transfer()
				bbs:add_new_message_by_id(new_id, message, transfer, "_SYSTEM")
				table.insert(ex_pets_in_me, pet:copy_raw_data())
			else
				msg = packet_def.GCStallError.new()
				msg.result = msg.STALL_MSG.ERR_ILLEGAL
				self:send2client(obj, msg)
			end
			self:log_exchange_prop_or_pet("Giao dịch giữa người chơi", "Bày sạp bán", ex_items_in_me, ex_items_in_tar, ex_pets_in_me, ex_pets_in_tar, stall_human, obj)
			return
		end
	end
end

return scene