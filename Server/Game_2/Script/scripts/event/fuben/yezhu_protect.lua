local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local yezhu_protect = class("yezhu_protect", script_base)
yezhu_protect.script_id = 402102
yezhu_protect.g_Item = 40004426
yezhu_protect.g_CopySceneName = "拯救灵兽"
yezhu_protect.g_CopySceneType = ScriptGlobal.FUBEN_PORTECT_PET
yezhu_protect.g_CopySceneMap = "petisland_2.nav"
yezhu_protect.g_Exit = "petisland_2.ini"
yezhu_protect.g_client_res = 232
yezhu_protect.g_LimitMembers = 1
yezhu_protect.g_TickTime = 1
yezhu_protect.g_LimitTotalHoldTime = 360
yezhu_protect.g_LimitTimeSuccess = 500
yezhu_protect.g_CloseTick = 3
yezhu_protect.g_NoUserTime = 300
yezhu_protect.g_DeadTrans = 0
yezhu_protect.g_Fuben_X = 87
yezhu_protect.g_Fuben_Z = 64
yezhu_protect.g_Back_X = 87
yezhu_protect.g_Back_Z = 64
yezhu_protect.g_Back_SceneId = 158
yezhu_protect.g_PetSceneId = 158
yezhu_protect.g_SetpTime = 10
yezhu_protect.g_SetpWaiteTime_1 = 15
yezhu_protect.g_SetpWaiteTime_2 = 60
yezhu_protect.g_SetpWaiteTime_3 = 120
yezhu_protect.g_SetpWaiteTime_4 = 150
yezhu_protect.g_SetpWaiteTime_5 = 240
yezhu_protect.g_SetpWaiteTime_6 = 180
yezhu_protect.g_SetpWaiteTime_7 = 100
yezhu_protect.g_SetpWaiteTime_8 = 50
yezhu_protect.g_MonsterInfo_1 = {
    {["id"] = 3780, ["num"] = 5, ["x"] = 58, ["z"] = 47, ["ai"] = 22, ["ai_f"] = 205, ["p"] = 0}
}

yezhu_protect.g_MonsterInfo_2 = {
    {["id"] = 3780, ["num"] = 5, ["x"] = 150, ["z"] = 46, ["ai"] = 22, ["ai_f"] = 205, ["p"] = 1},
    {["id"] = 3850, ["num"] = 5, ["x"] = 101, ["z"] = 102, ["ai"] = 22, ["ai_f"] = 257, ["p"] = 2}
}

yezhu_protect.g_MonsterInfo_3 = {
    {["id"] = 3780, ["num"] = 5, ["x"] = 85, ["z"] = 18, ["ai"] = 22, ["ai_f"] = 205, ["p"] = 3},
    {["id"] = 3850, ["num"] = 5, ["x"] = 61, ["z"] = 96, ["ai"] = 22, ["ai_f"] = 257, ["p"] = 4},
    {["id"] = 3860, ["num"] = 5, ["x"] = 150, ["z"] = 46, ["ai"] = 22, ["ai_f"] = 258, ["p"] = 1}
}

yezhu_protect.g_MonsterInfo_4 = {
    {["id"] = 3850, ["num"] = 5, ["x"] = 101, ["z"] = 102, ["ai"] = 22, ["ai_f"] = 257, ["p"] = 2},
    {["id"] = 3780, ["num"] = 5, ["x"] = 58, ["z"] = 47, ["ai"] = 22, ["ai_f"] = 205, ["p"] = 0},
    {["id"] = 3860, ["num"] = 5, ["x"] = 61, ["z"] = 96, ["ai"] = 22, ["ai_f"] = 258, ["p"] = 4},
    {["id"] = 3780, ["num"] = 5, ["x"] = 85, ["z"] = 18, ["ai"] = 22, ["ai_f"] = 205, ["p"] = 3}
}

yezhu_protect.g_MonsterInfo_5 = {
    {["id"] = 3780, ["num"] = 5, ["x"] = 58, ["z"] = 47, ["ai"] = 22, ["ai_f"] = 205, ["p"] = 0},
    {["id"] = 3860, ["num"] = 5, ["x"] = 150, ["z"] = 46, ["ai"] = 22, ["ai_f"] = 258, ["p"] = 1},
    {["id"] = 3850, ["num"] = 5, ["x"] = 101, ["z"] = 102, ["ai"] = 22, ["ai_f"] = 257, ["p"] = 2}
}

yezhu_protect.g_MonsterInfo_6 = {
    {["id"] = 3850, ["num"] = 5, ["x"] = 101, ["z"] = 102, ["ai"] = 22, ["ai_f"] = 257, ["p"] = 2},
    {["id"] = 3780, ["num"] = 5, ["x"] = 85, ["z"] = 18, ["ai"] = 22, ["ai_f"] = 205, ["p"] = 3}
}

yezhu_protect.g_MonsterInfo_7 = {
    {["id"] = 3860, ["num"] = 5, ["x"] = 61, ["z"] = 96, ["ai"] = 22, ["ai_f"] = 258, ["p"] = 4}
}

yezhu_protect.g_MonsterInfo_8 = {
    {["id"] = 3790, ["num"] = 5, ["x"] = 85, ["z"] = 18, ["ai"] = 22, ["ai_f"] = 206, ["p"] = 3}
}

yezhu_protect.g_MonsterAI = {
    {["id"] = 3730, ["ai"] = 200},
    {["id"] = 3740, ["ai"] = 201},
    {["id"] = 3750, ["ai"] = 202},
    {["id"] = 3760, ["ai"] = 203},
    {["id"] = 3770, ["ai"] = 204}
}

yezhu_protect.g_MonsterInfo_Count_1 = 7
yezhu_protect.g_MonsterInfo_Count_2 = 8
yezhu_protect.g_MonsterInfo_Count_3 = 8
yezhu_protect.g_MonsterInfo_Count_4 = 10
yezhu_protect.g_MonsterInfo_Count_5 = 12
yezhu_protect.g_MonsterInfo_Count_6 = 12
yezhu_protect.g_MonsterInfo_Count_7 = 13
function yezhu_protect:OnDefaultEvent(selfId, targetId, index)
	if not self:LuaFnIsActivityMonster(selfId,targetId,true) then return end

    local sceneId = self:get_scene():get_id()
    if sceneId ~= 158 then
        return
    end
    if index == 1010 then
        self:BeginEvent(self.script_id)
        self:AddText("#{YZBZ_20070930_002}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if not self:LuaFnHasTeam(selfId) then
        self:BeginEvent(self.script_id)
        self:AddText("#BSứ Mệnh Giải Cứu Linh Thú")
        self:AddText("   <Linh thú sốt ruột chớp mắt với ngươi ba lần, dường như muốn nói: Không đủ ba Cá nhân, các ngươi đây chẳng phải là uổng công chịu chết sao!>#R(Yêu cầu là đội trưởng, và trong đội ít nhất ba người)")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if self:GetTeamSize(selfId) < 1 then
        self:BeginEvent(self.script_id)
        self:AddText("#BSứ Mệnh Giải Cứu Linh Thú")
        self:AddText("  <Linh thú sốt ruột chớp mắt với ngươi ba lần, dường như muốn nói: Không đủ ba Cá nhân, các ngươi đây chẳng phải là uổng công chịu chết sao!>#R(Yêu cầu là đội trưởng, và trong đội ít nhất ba người)")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if self:GetTeamLeader(selfId) ~= selfId then
        self:BeginEvent(self.script_id)
        self:AddText("#BSứ Mệnh Giải Cứu Linh Thú")
        self:AddText("  <Linh thú sốt ruột chớp mắt với ngươi ba lần, dường như muốn nói: Không đủ ba Cá nhân, các ngươi đây chẳng phải là uổng công chịu chết sao!>#R(Yêu cầu là đội trưởng, và trong đội ít nhất ba người)")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if self:GetTeamSize(selfId) ~= self:GetNearTeamCount(selfId) then
        self:BeginEvent(self.script_id)
        self:AddText("#BSứ Mệnh Giải Cứu Linh Thú")
        self:AddText("  <Linh thú sốt ruột lắc đầu, dường như muốn nói: Các thành viên của ngươi còn chưa đến, mau tập hợp!>")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    local nPlayerNum = self:GetNearTeamCount(selfId)
    local strName = {}

    strName[1] = ""
    strName[2] = ""
    strName[3] = ""
    strName[4] = ""
    strName[5] = ""
    strName[6] = ""
    local ret = 1
    for i = 1, nPlayerNum do
        local nPlayerId = self:GetNearTeamMember(selfId, i)
        if self:GetLevel(nPlayerId) < 40 then
            ret = 0
            strName[i] = self:GetName(nPlayerId)
        end
    end
    local nCount = 0
    if ret == 0 then
        local szAllName = ""
        for i = 1, 6 do
            if strName[i] ~= "" then
                if nCount == 0 then
                    szAllName = strName[i]
                else
                    szAllName = szAllName .. "、" .. strName[i]
                end
                nCount = nCount + 1
            end
        end
        self:BeginEvent(self.script_id)
        self:AddText("#BSứ Mệnh Giải Cứu Linh Thú")
        self:AddText("  Trong đội của ngươi có thành viên (" .. szAllName .. ") Cấp độ thấp hơn cấp 40, không thể tham gia Giải Cứu Linh Thú.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if sceneId == self.g_PetSceneId then
        self:MakeCopyScene(selfId, targetId)
        self:LuaFnDeleteMonster(targetId)
    end
end

function yezhu_protect:OnEnumerate(caller, selfId, targetId, arg, index)
    local sceneId = self:get_scene():get_id()
    if sceneId ~= 158 then
        return
    end
    caller:AddNumTextWithTarget(self.script_id, "拯救灵兽", 10, -1)
    caller:AddNumTextWithTarget(self.script_id, "#{YZBZ_20070930_001}", 11, 1010)
end

function yezhu_protect:CheckAccept(selfId)
end

function yezhu_protect:AskEnterCopyScene(selfId)
end

function yezhu_protect:OnAccept(selfId, targetId)
end

function yezhu_protect:AcceptEnterCopyScene(selfId)
end

function yezhu_protect:MakeCopyScene(selfId, targetId)
	if not self:LuaFnIsActivityMonster(selfId,targetId,true) then return end
    local param0 = 4
    local param1 = 3
    local mylevel = 0
    local memId
    local tempMemlevel = 0
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
    local config = {}
    local leaderguid = self:LuaFnObjId2Guid(selfId)
    config.navmapname = "petisland_2.nav"
    config.patrolpoint = "petisland_2_patrolpoint.ini"
    config.eventfile = "petisland_2_area.ini"
	config.client_res = self.g_client_res
	config.teamleader = leaderguid
	config.NoUserCloseTime = 0
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
    local PlayerMaxLevel = self:GetHumanMaxLevelLimit()
    local iniLevel
    if mylevel < 10 then
        iniLevel = 1
    elseif mylevel < PlayerMaxLevel then
        iniLevel = math.floor(mylevel / 10)
    else
        iniLevel = math.floor(PlayerMaxLevel / 10)
    end
    config.params[8] = mylevel
    config.params[9] = iniLevel
    config.params[10] = self:GetMonsterDataID(targetId)
    local x, z = self:GetWorldPos(selfId)
    config.params[16] = x
    config.params[17] = z
    config.sn 		 = self:LuaFnGenCopySceneSN()
    local bRetSceneID = self:LuaFnCreateCopyScene(config)

    self:BeginEvent(self.script_id)
    if bRetSceneID > 0 then
        self:AddText("Tạo phó bản thành công!")
    else
        self:AddText("Số lượng phó bản đã đạt đến giới hạn, xin hãy thử lại sau!")
    end
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function yezhu_protect:OnCopySceneReady(destsceneId)
    self:LuaFnSetCopySceneData_Param(destsceneId, 3)
    local leaderguid = self:LuaFnGetCopySceneData_TeamLeader(destsceneId)
    local leaderObjId = self:LuaFnGuid2ObjId(leaderguid)
    if not self:LuaFnIsCanDoScriptLogic(leaderObjId) then
        return
    end
    if not self:LuaFnHasTeam(leaderObjId) then
        self:GotoScene(leaderObjId, destsceneId)
    else
        if not self:IsCaptain(leaderObjId) then
            self:GotoScene(leaderObjId, destsceneId)
        else
            local nearteammembercount = self:GetNearTeamCount(leaderObjId)
            local mems = {}
            for i = 1, nearteammembercount do
                mems[i] = self:GetNearTeamMember(leaderObjId, i)
                self:GotoScene(mems[i], destsceneId)
            end
        end
    end
end

function yezhu_protect:GotoScene(ObjId, destsceneId)
    local sn = self:LuaFnGetCopySceneData_Sn(destsceneId)
    self:NewWorld(ObjId, destsceneId, sn, self.g_Fuben_X, self.g_Fuben_Z)
end

function yezhu_protect:OnPlayerEnter(selfId)
    self:SetUnitCampID(selfId, 100)
    self:TipAllHuman("Bạo Tẩu Dã Trư sẽ bắt đầu Tấn công sau 15 giây, hãy chú ý bảo vệ sự an toàn của Linh Thú trong vòng 20 phút!")
end

function yezhu_protect:OnHumanDie(selfId, killerId)
end

function yezhu_protect:OnAbandon(selfId)
end

function yezhu_protect:BackToCity(selfId)
end

function yezhu_protect:OnContinue(selfId, targetId)
end

function yezhu_protect:CheckSubmit(selfId, selectRadioId)
end

function yezhu_protect:OnSubmit(selfId, targetId, selectRadioId)
end

function yezhu_protect:OnDie(objId, killerId)
    self:TipAllHuman("Giải cứu Linh Thú thất bại!")
    self:LuaFnSetCopySceneData_Param(12, 10)
end

function yezhu_protect:TipAllHuman(Str)
    local nHumanNum = self:LuaFnGetCopyScene_HumanCount()
    if nHumanNum < 1 then
        return
    end
    for i = 1, nHumanNum do
        local PlayerId = self:LuaFnGetCopyScene_HumanObjId(i)
        self:BeginEvent(self.script_id)
        self:AddText(Str)
        self:EndEvent()
        self:DispatchMissionTips(PlayerId)
    end
end

function yezhu_protect:OnKillObject(selfId, objdataId, objId)
end

function yezhu_protect:OnEnterZone(selfId, zoneId)
end

function yezhu_protect:OnItemChanged(selfId, itemdataId)
end

function yezhu_protect:OnCopySceneTimer(nowTime)
    local nPreTime = self:LuaFnGetCopySceneData_Param(11)
    local nCurTime = self:LuaFnGetCurrentTime()
    local nStep = self:LuaFnGetCopySceneData_Param(12)
    local nStep_1 = self:LuaFnGetCopySceneData_Param(13)
    local nPreTime_1 = self:LuaFnGetCopySceneData_Param(14)
    local nBeginTime = self:LuaFnGetCopySceneData_Param(21)
    local nBeginTimeFlag = self:LuaFnGetCopySceneData_Param(22)
    if nCurTime - nBeginTime >= 18 * 60 and nBeginTimeFlag == 1 then
        self:TipAllHuman("Hoạt động sẽ kết thúc sau 2 phút, hãy chú ý bảo vệ an toàn cho Linh Thú!")
        self:LuaFnSetCopySceneData_Param(22, 2)
    end
    if nCurTime - nBeginTime >= 19 * 60 and nBeginTimeFlag == 2 then
        self:TipAllHuman("Hoạt động sẽ kết thúc sau 1 phút, hãy chú ý bảo vệ an toàn cho Linh Thú!")
        self:LuaFnSetCopySceneData_Param(22, 3)
    end
    if nCurTime - nBeginTime >= 19 * 60 + 30 and nBeginTimeFlag == 3 then
        self:TipAllHuman("Hoạt động sẽ kết thúc sau 30 giây, hãy chú ý bảo vệ an toàn cho Linh Thú!")
        self:LuaFnSetCopySceneData_Param(22, 4)
    end
    if nStep == 0 then
        local nMonterIniID = self:LuaFnGetCopySceneData_Param(9)
        local nMonterID = self:LuaFnGetCopySceneData_Param(10)
        local nAi = 0
        for i = 1, 5 do
            if self.g_MonsterAI[i]["id"] == nMonterID then
                nAi = self.g_MonsterAI[i]["ai"]
            end
        end
        local nRetrievalMonterID
        if nMonterIniID >= 11 then
            nRetrievalMonterID = nMonterID + nMonterIniID - 11 + 30000
        else
            nRetrievalMonterID = nMonterID + nMonterIniID - 1
        end
        local nNpcId = self:LuaFnCreateMonster(nRetrievalMonterID, 89, 64, 9, nAi, 402102)
        self:SetUnitCampID(nNpcId, 100)
        self:SetCharacterTitle(nNpcId, "Linh Thú")
        self:SetMonsterFightWithNpcFlag(nNpcId, 1)
        self:LuaFnSetCopySceneData_Param(11, nCurTime)
        self:LuaFnSetCopySceneData_Param(12, nStep + 1)
        self:LuaFnSetCopySceneData_Param(21, nCurTime)
        self:LuaFnSetCopySceneData_Param(22, 1)
        self:LuaFnSetCopySceneData_Param(15, nNpcId)
    end
    if nCurTime - nPreTime >= self.g_SetpWaiteTime_1 and nStep == 1 then
        for i, Npc in pairs(self.g_MonsterInfo_1) do
            local nNpcId = self:CreateNpc(Npc["id"], Npc["x"], Npc["z"], Npc["ai"], Npc["ai_f"], -1)
            self:SetUnitCampID(nNpcId, 101)
            self:SetMonsterFightWithNpcFlag(nNpcId, 1)
            self:SetPatrolId(nNpcId, Npc["p"])
        end
        self:TipAllHuman("Dã Trư bắt đầu đợt Tấn công thứ 1! (Còn 6 đợt Tấn công nữa)")
        self:TipAllHuman("60 giây sau Dã Trư sẽ bắt đầu đợt Tấn công tiếp theo!")
        self:LuaFnSetCopySceneData_Param(11, nCurTime)
        self:LuaFnSetCopySceneData_Param(12, nStep + 1)
        self:LuaFnSetCopySceneData_Param(13, 0)
    end
    if (nStep == 2) and (nStep_1 < self.g_MonsterInfo_Count_1 - 1) and (nCurTime - nPreTime_1 >= self.g_SetpTime) then
        for i, Npc in pairs(self.g_MonsterInfo_1) do
            local nNpcId = self:CreateNpc(Npc["id"], Npc["x"], Npc["z"], Npc["ai"], Npc["ai_f"], -1)
            self:SetUnitCampID(nNpcId, 101)
            self:SetMonsterFightWithNpcFlag(nNpcId, 1)
            self:SetPatrolId(nNpcId, Npc["p"])
            self:LuaFnSetCopySceneData_Param(14, nCurTime)
            self:LuaFnSetCopySceneData_Param(13, nStep_1 + 1)
        end
    end
    if nCurTime - nPreTime >= self.g_SetpWaiteTime_2 and nStep == 2 then
        for i, Npc in pairs(self.g_MonsterInfo_2) do
            local nNpcId = self:CreateNpc(Npc["id"], Npc["x"], Npc["z"], Npc["ai"], Npc["ai_f"], -1)
            self:SetUnitCampID(nNpcId, 101)
            self:SetMonsterFightWithNpcFlag(nNpcId, 1)
            self:SetPatrolId(nNpcId, Npc["p"])
        end
        self:TipAllHuman("Lợn rừng bắt đầu đợt Tấn công thứ 2! (Còn 5 đợt Tấn công).")
        self:TipAllHuman("120 giây sau lợn rừng sẽ bắt đầu đợt Tấn công tiếp theo!")
        self:LuaFnSetCopySceneData_Param(11, nCurTime)
        self:LuaFnSetCopySceneData_Param(12, nStep + 1)
        self:LuaFnSetCopySceneData_Param(13, 0)
    end
    if (nStep == 3) and (nStep_1 < self.g_MonsterInfo_Count_2 - 1) and (nCurTime - nPreTime_1 >= self.g_SetpTime) then
        for i, Npc in pairs(self.g_MonsterInfo_2) do
            local nNpcId = self:CreateNpc(Npc["id"], Npc["x"], Npc["z"], Npc["ai"], Npc["ai_f"], -1)
            self:SetUnitCampID(nNpcId, 101)
            self:SetMonsterFightWithNpcFlag(nNpcId, 1)
            self:SetPatrolId(nNpcId, Npc["p"])
            self:LuaFnSetCopySceneData_Param(14, nCurTime)
            self:LuaFnSetCopySceneData_Param(13, nStep_1 + 1)
        end
    end
    if nCurTime - nPreTime >= self.g_SetpWaiteTime_3 and nStep == 3 then
        for i, Npc in pairs(self.g_MonsterInfo_3) do
            local nNpcId = self:CreateNpc(Npc["id"], Npc["x"], Npc["z"], Npc["ai"], Npc["ai_f"], -1)
            self:SetUnitCampID(nNpcId, 101)
            self:SetMonsterFightWithNpcFlag(nNpcId, 1)
            self:SetPatrolId(nNpcId, Npc["p"])
        end
        self:TipAllHuman("Lợn rừng bắt đầu đợt Tấn công thứ 3! (Còn 4 đợt Tấn công).")
        self:TipAllHuman("150 giây sau lợn rừng sẽ bắt đầu đợt Tấn công tiếp theo!")
        self:LuaFnSetCopySceneData_Param(11, nCurTime)
        self:LuaFnSetCopySceneData_Param(12, nStep + 1)
        self:LuaFnSetCopySceneData_Param(13, 0)
    end
    if (nStep == 4) and (nStep_1 < self.g_MonsterInfo_Count_3 - 1) and (nCurTime - nPreTime_1 >= self.g_SetpTime) then
        for i, Npc in pairs(self.g_MonsterInfo_3) do
            local nNpcId = self:CreateNpc(Npc["id"], Npc["x"], Npc["z"], Npc["ai"], Npc["ai_f"], -1)
            self:SetUnitCampID(nNpcId, 101)
            self:SetMonsterFightWithNpcFlag(nNpcId, 1)
            self:SetPatrolId(nNpcId, Npc["p"])
            self:LuaFnSetCopySceneData_Param(14, nCurTime)
            self:LuaFnSetCopySceneData_Param(13, nStep_1 + 1)
        end
    end
    if nCurTime - nPreTime >= self.g_SetpWaiteTime_4 and nStep == 4 then
        for i, Npc in pairs(self.g_MonsterInfo_4) do
            local nNpcId = self:CreateNpc(Npc["id"], Npc["x"], Npc["z"], Npc["ai"], Npc["ai_f"], -1)
            self:SetUnitCampID(nNpcId, 101)
            self:SetMonsterFightWithNpcFlag(nNpcId, 1)
            self:SetPatrolId(nNpcId, Npc["p"])
        end
        self:TipAllHuman("Lợn rừng bắt đầu đợt Tấn công thứ 4! (Còn 3 đợt Tấn công).")
        self:TipAllHuman("240 giây sau lợn rừng sẽ bắt đầu đợt Tấn công tiếp theo!")
        self:LuaFnSetCopySceneData_Param(11, nCurTime)
        self:LuaFnSetCopySceneData_Param(12, nStep + 1)
        self:LuaFnSetCopySceneData_Param(13, 0)
    end
    if (nStep == 5) and (nStep_1 < self.g_MonsterInfo_Count_4 - 1) and (nCurTime - nPreTime_1 >= self.g_SetpTime) then
        for i, Npc in pairs(self.g_MonsterInfo_4) do
            local nNpcId = self:CreateNpc(Npc["id"], Npc["x"], Npc["z"], Npc["ai"], Npc["ai_f"], -1)
            self:SetUnitCampID(nNpcId, 101)
            self:SetMonsterFightWithNpcFlag(nNpcId, 1)
            self:SetPatrolId(nNpcId, Npc["p"])
            self:LuaFnSetCopySceneData_Param(14, nCurTime)
            self:LuaFnSetCopySceneData_Param(13, nStep_1 + 1)
        end
    end
    if nCurTime - nPreTime >= self.g_SetpWaiteTime_5 and nStep == 5 then
        for i, Npc in pairs(self.g_MonsterInfo_5) do
            local nNpcId = self:CreateNpc(Npc["id"], Npc["x"], Npc["z"], Npc["ai"], Npc["ai_f"], -1)
            self:SetUnitCampID(nNpcId, 101)
            self:SetMonsterFightWithNpcFlag(nNpcId, 1)
            self:SetPatrolId(nNpcId, Npc["p"])
        end
        self:TipAllHuman("Lợn rừng bắt đầu đợt Tấn công thứ 5! (Còn 2 đợt Tấn công).")
        self:TipAllHuman("180 giây sau lợn rừng sẽ bắt đầu đợt Tấn công tiếp theo!")
        self:LuaFnSetCopySceneData_Param(11, nCurTime)
        self:LuaFnSetCopySceneData_Param(12, nStep + 1)
        self:LuaFnSetCopySceneData_Param(13, 0)
    end
    if (nStep == 6) and (nStep_1 < self.g_MonsterInfo_Count_5 - 1) and (nCurTime - nPreTime_1 >= self.g_SetpTime) then
        for i, Npc in pairs(self.g_MonsterInfo_5) do
            local nNpcId = self:CreateNpc(Npc["id"], Npc["x"], Npc["z"], Npc["ai"], Npc["ai_f"], -1)
            self:SetUnitCampID(nNpcId, 101)
            self:SetMonsterFightWithNpcFlag(nNpcId, 1)
            self:SetPatrolId(nNpcId, Npc["p"])
            self:LuaFnSetCopySceneData_Param(14, nCurTime)
            self:LuaFnSetCopySceneData_Param(13, nStep_1 + 1)
        end
    end
    if nCurTime - nPreTime >= self.g_SetpWaiteTime_6 and nStep == 6 then
        for i, Npc in pairs(self.g_MonsterInfo_6) do
            local nNpcId = self:CreateNpc(Npc["id"], Npc["x"], Npc["z"], Npc["ai"], Npc["ai_f"], -1)
            self:SetUnitCampID(nNpcId, 101)
            self:SetMonsterFightWithNpcFlag(nNpcId, 1)
            self:SetPatrolId(nNpcId, Npc["p"])
        end
        self:TipAllHuman("Lợn rừng bắt đầu đợt Tấn công thứ 6! (Còn 1 đợt Tấn công).")
        self:TipAllHuman("100 giây sau lợn rừng sẽ bắt đầu đợt Tấn công tiếp theo!")
        self:LuaFnSetCopySceneData_Param(11, nCurTime)
        self:LuaFnSetCopySceneData_Param(12, nStep + 1)
        self:LuaFnSetCopySceneData_Param(13, 0)
    end
    if (nStep == 7) and (nStep_1 < self.g_MonsterInfo_Count_6 - 1) and (nCurTime - nPreTime_1 >= self.g_SetpTime) then
        for i, Npc in pairs(self.g_MonsterInfo_6) do
            local nNpcId = self:CreateNpc(Npc["id"], Npc["x"], Npc["z"], Npc["ai"], Npc["ai_f"], -1)
            self:SetUnitCampID(nNpcId, 101)
            self:SetMonsterFightWithNpcFlag(nNpcId, 1)
            self:SetPatrolId(nNpcId, Npc["p"])
            self:LuaFnSetCopySceneData_Param(14, nCurTime)
            self:LuaFnSetCopySceneData_Param(13, nStep_1 + 1)
        end
    end
    if nCurTime - nPreTime >= self.g_SetpWaiteTime_7 and nStep == 7 then
        for i, Npc in pairs(self.g_MonsterInfo_7) do
            local nNpcId = self:CreateNpc(Npc["id"], Npc["x"], Npc["z"], Npc["ai"], Npc["ai_f"], -1)
            self:SetUnitCampID(nNpcId, 101)
            self:SetMonsterFightWithNpcFlag(nNpcId, 1)
            self:SetPatrolId(nNpcId, Npc["p"])
        end
        self:TipAllHuman("Lợn Rừng Bạo Tẩu bắt đầu đợt Tấn công cuối cùng!")
        self:LuaFnSetCopySceneData_Param(11, nCurTime)
        self:LuaFnSetCopySceneData_Param(12, nStep + 1)
        self:LuaFnSetCopySceneData_Param(13, 0)
    end
    if (nStep == 8) and (nStep_1 < self.g_MonsterInfo_Count_7 - 1) and (nCurTime - nPreTime_1 >= self.g_SetpTime) then
        for i, Npc in pairs(self.g_MonsterInfo_7) do
            local nNpcId = self:CreateNpc(Npc["id"], Npc["x"], Npc["z"], Npc["ai"], Npc["ai_f"], -1)
            self:SetUnitCampID(nNpcId, 101)
            self:SetMonsterFightWithNpcFlag(nNpcId, 1)
            self:SetPatrolId(nNpcId, Npc["p"])
            self:LuaFnSetCopySceneData_Param(14, nCurTime)
            self:LuaFnSetCopySceneData_Param(13, nStep_1 + 1)
        end
    end
    if nCurTime - nPreTime >= self.g_SetpWaiteTime_8 and nStep == 8 then
        for i, Npc in pairs(self.g_MonsterInfo_8) do
            local nNpcId = self:CreateNpc(Npc["id"], Npc["x"], Npc["z"], Npc["ai"], Npc["ai_f"], -1)
            self:SetUnitCampID(nNpcId, 101)
            self:SetMonsterFightWithNpcFlag(nNpcId, 1)
            self:SetCharacterTitle(nNpcId, "Đội trưởng Nanh Vuốt")
            self:SetPatrolId(nNpcId, Npc["p"])
        end
        self:TipAllHuman("Cảnh giác! Lợn Rừng Đầu lĩnh xuất hiện!!")
        self:LuaFnSetCopySceneData_Param(11, nCurTime)
        self:LuaFnSetCopySceneData_Param(12, nStep + 1)
    end
    local nLastTime =
        20 * 60 -
        (self.g_SetpWaiteTime_1 + self.g_SetpWaiteTime_2 + self.g_SetpWaiteTime_3 + self.g_SetpWaiteTime_4 +
            self.g_SetpWaiteTime_5 +
            self.g_SetpWaiteTime_6 +
            self.g_SetpWaiteTime_7 +
            self.g_SetpWaiteTime_8)
    if nCurTime - nPreTime >= nLastTime and nStep == 9 then
        self:LuaFnSetCopySceneData_Param(11, nCurTime)
        self:LuaFnSetCopySceneData_Param(12, nStep + 1)
        local nNpcId = self:LuaFnGetCopySceneData_Param(15)
        local bOk = 0
        local nMonsterCount = self:GetMonsterCount()
        for i = 1, nMonsterCount do
            local nMontserid = self:GetMonsterObjID(i)
            if nNpcId == nMontserid then
                bOk = 1
            end
        end
        if bOk == 1 then
            self:TipAllHuman("Cứu viện Linh thú thành công!")
            local nHumanNum = self:LuaFnGetCopyScene_HumanCount()
            if nHumanNum < 1 then
                return
            end
            local nLeaderId = 0
            for i = 1, nHumanNum do
                local nPlayerId = self:LuaFnGetCopyScene_HumanObjId(i)
                if self:GetTeamLeader(nPlayerId) == nPlayerId then
                    nLeaderId = nPlayerId
                end
            end
            if nLeaderId == 0 then
                return
            end
            local szLeaderName = self:GetName(nLeaderId)
            local str = string.format("#GĐỉnh Thánh Thú Sơn#P, Cái thế anh hùng #{_INFOUSR%s}#P và đồng đội dốc hết sức lực, đánh lui #YThợ Săn Trộm#Pcủa cuộc Tấn công điên cuồng, bảo đảm an toàn cho Linh thú!", szLeaderName)
            str = gbk.fromutf8(str)
            self:BroadMsgByChatPipe(nLeaderId, str, 4)
        end
    end
    if nStep == 10 then
        self:TipAllHuman("Phó bản sẽ đóng sau 30 giây.")
        self:LuaFnSetCopySceneData_Param(11, nCurTime)
        self:LuaFnSetCopySceneData_Param(12, nStep + 1)
    end
    if nCurTime - nPreTime >= 15 and nStep == 11 then
        self:TipAllHuman("Phó bản sẽ đóng sau 15 giây.")
        self:LuaFnSetCopySceneData_Param(11, nCurTime)
        self:LuaFnSetCopySceneData_Param(12, nStep + 1)
    end
    if nCurTime - nPreTime >= 10 and nStep == 12 then
        self:TipAllHuman("Phó bản sẽ đóng sau 5 giây.")
        self:LuaFnSetCopySceneData_Param(11, nCurTime)
        self:LuaFnSetCopySceneData_Param(12, nStep + 1)
    end
    if nCurTime - nPreTime >= 5 and nStep == 13 then
        local nHumanNum = self:LuaFnGetCopyScene_HumanCount()
        for i = 1, nHumanNum do
            local nPlayerId = self:LuaFnGetCopyScene_HumanObjId(i)
            local x = self:LuaFnGetCopySceneData_Param(16)
            local z = self:LuaFnGetCopySceneData_Param(17)
            self:NewWorld(nPlayerId, self.g_Back_SceneId, nil, x, z)
        end
        self:LuaFnSetCopySceneData_Param(11, nCurTime)
        self:LuaFnSetCopySceneData_Param(12, nStep + 1)
    end
end

function yezhu_protect:CreateNpc(NpcId, x, y, Ai, AiFile, Script)
    local PlayerLevel = self:LuaFnGetCopySceneData_Param(8)
    local ModifyLevel = self:LuaFnGetCopySceneData_Param(9)
    local nNpcId
    if ModifyLevel >= 11 then
        nNpcId = NpcId + ModifyLevel - 11 + 30000
    else
        nNpcId = NpcId + ModifyLevel - 1
    end
    local nMonsterId = self:LuaFnCreateMonster(nNpcId, x, y, Ai, AiFile, Script)
    self:SetLevel(nMonsterId, PlayerLevel)
    return nMonsterId
end

return yezhu_protect
