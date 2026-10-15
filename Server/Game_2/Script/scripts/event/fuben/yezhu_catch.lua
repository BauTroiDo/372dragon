local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local yezhu_catch = class("yezhu_catch", script_base)
yezhu_catch.script_id = 402105
yezhu_catch.g_CopySceneName = "镇压暴走活动"
yezhu_catch.g_client_res = 231
yezhu_catch.g_CopySceneType = ScriptGlobal.FUBEN_CATCH_PET
yezhu_catch.g_CopySceneMap = "zhenshoulan.nav"
yezhu_catch.g_Exit = "zhenshoulan.ini"
yezhu_catch.g_LimitMembers = 1
yezhu_catch.g_TickTime = 1
yezhu_catch.g_LimitTotalHoldTime = 360
yezhu_catch.g_LimitTimeSuccess = 500
yezhu_catch.g_CloseTick = 3
yezhu_catch.g_NoUserTime = 300
yezhu_catch.g_DeadTrans = 0
yezhu_catch.g_Fuben_X = 36
yezhu_catch.g_Fuben_Z = 97
yezhu_catch.g_Back_X = 141
yezhu_catch.g_Back_Z = 114
yezhu_catch.g_Back_SceneId = 158
yezhu_catch.g_Item = 40004429
yezhu_catch.g_PetSceneId = 158
yezhu_catch.g_MonsterInfo_1 = {["id"] = 3800, ["ai"] = 17, ["aif"] = 207}

yezhu_catch.g_MonsterPos = {
    {["x"] = 65.5176, ["z"] = 79.0207},
    {["x"] = 69.8164, ["z"] = 88.1377},
    {["x"] = 83.8354, ["z"] = 92.4449},
    {["x"] = 77.5097, ["z"] = 74.2288},
    {["x"] = 87.9545, ["z"] = 70.4181},
    {["x"] = 74.7209, ["z"] = 60.9159},
    {["x"] = 60.6836, ["z"] = 56.8568},
    {["x"] = 71.8951, ["z"] = 46.935},
    {["x"] = 86.682, ["z"] = 44.4101},
    {["x"] = 98.8462, ["z"] = 37.5822},
    {["x"] = 60.1058, ["z"] = 35.1054},
    {["x"] = 45.9477, ["z"] = 34.18},
    {["x"] = 25.7361, ["z"] = 43.8625},
    {["x"] = 34.4459, ["z"] = 55.7157},
    {["x"] = 42.0419, ["z"] = 45.9647},
    {["x"] = 48.4925, ["z"] = 58.1778},
    {["x"] = 74.1362, ["z"] = 29.3186},
    {["x"] = 89.6256, ["z"] = 29.2022},
    {["x"] = 56.631, ["z"] = 45.7225},
    {["x"] = 94.1026, ["z"] = 57.7871},
    {["x"] = 97.1927, ["z"] = 90.8149},
    {["x"] = 52.1854, ["z"] = 84.1242},
    {["x"] = 58.4518, ["z"] = 70.0597},
    {["x"] = 66.7249, ["z"] = 100.087},
    {["x"] = 29.7832, ["z"] = 25.596},
    {["x"] = 34.8878, ["z"] = 35.452},
    {["x"] = 80.2963, ["z"] = 37.4068},
    {["x"] = 93.935, ["z"] = 78.0536},
    {["x"] = 83.9264, ["z"] = 54.9693},
    {["x"] = 64.3749, ["z"] = 24.8037}
}

yezhu_catch.g_BossInfo_1 = {["id"] = 3810, ["ai"] = 16, ["aif"] = 208, ["x"] = 73, ["z"] = 50, ["script"] = -1}

yezhu_catch.g_BossInfo_2 = {["id"] = 3820, ["ai"] = 17, ["aif"] = 209, ["x"] = 73, ["z"] = 50, ["script"] = 501000}

yezhu_catch.g_BossRand_2 = 10
function yezhu_catch:OnDefaultEvent(selfId, targetId, index)
	if not self:LuaFnIsActivityMonster(selfId,targetId,true) then return end
    if index == 1010 then
        self:BeginEvent(self.script_id)
        self:AddText("#{YZBZ_20070930_004}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if not self:LuaFnHasTeam(selfId) then
        self:BeginEvent(self.script_id)
        self:AddText("#BTruy bắt Dã Trư Vương")
        self:AddText("  Người đông Cường lực lớn, chúng ta góp đủ nhân thủ rồi hãy xuất phát!#R(Yêu cầu là đội trưởng, và trong đội ít nhất ba người)")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if self:GetTeamSize(selfId) < self.g_LimitMembers then
        self:BeginEvent(self.script_id)
        self:AddText("#BTruy bắt Dã Trư Vương")
        self:AddText("  Người đông Cường lực lớn, chúng ta góp đủ nhân thủ rồi hãy xuất phát!#R(Yêu cầu là đội trưởng, và trong đội ít nhất ba người)")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if self:GetTeamLeader(selfId) ~= selfId then
        self:BeginEvent(self.script_id)
        self:AddText("#BTruy bắt Dã Trư Vương")
        self:AddText("  Người đông Cường lực lớn, chúng ta góp đủ nhân thủ rồi hãy xuất phát!#R(Yêu cầu là đội trưởng, và trong đội ít nhất ba người)")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if self:GetTeamSize(selfId) ~= self:GetNearTeamCount(selfId) then
        self:BeginEvent(self.script_id)
        self:AddText("#BTruy bắt Dã Trư Vương")
        self:AddText("  Người đông Cường lực lớn, chúng ta góp đủ nhân thủ rồi hãy xuất phát!#R(Yêu cầu là đội trưởng, và trong đội ít nhất ba người)")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if self:LuaFnGetAvailableItemCount(selfId, self.g_Item) < 1 then
        self:BeginEvent(self.script_id)
        self:AddText("#BTruy bắt Dã Trư Vương")
        self:AddText("  Muốn tìm được Dã Trư Vương, chúng ta phải có đủ manh mối mới được.#R(Yêu cầu mang theo đạo cụ #Gdấu vết của Dã Trư Vương#R)")
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
        self:AddText("#BTruy bắt Dã Trư Vương")
        self:AddText("  Muốn đánh bại Dã Trư Vương, Cấp độ quá thấp thì không được.#r#RTrong đội của ngài có thành viên (" .. szAllName .. ") Cấp độ không đủ 40.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    local sceneId = self:get_scene():get_id()
    if sceneId == self.g_PetSceneId then
        self:MakeCopyScene(selfId, targetId)
    end
end

function yezhu_catch:OnEnumerate(caller, selfId, targetId, arg, index)
    caller:AddNumTextWithTarget(self.script_id, "Truy bắt Dã Trư Vương", 10, -1)
    caller:AddNumTextWithTarget(self.script_id, "#{YZBZ_20070930_003}", 11, 1010)
end

function yezhu_catch:CheckAccept(selfId)
end

function yezhu_catch:AskEnterCopyScene(selfId)
end

function yezhu_catch:OnAccept(selfId, targetId)
end

function yezhu_catch:AcceptEnterCopyScene(selfId)
end

function yezhu_catch:MakeCopyScene(selfId, targetId)
	if not self:LuaFnIsActivityMonster(selfId,targetId,true) then return end
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
    local config = {}
    local leaderguid = self:LuaFnObjId2Guid(selfId)
    config.navmapname = "zhenshoulan.nav"
    config.eventfile = "zhenshoulan_area.ini"
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
    local nMonterID
    if iniLevel >= 11 then
        nMonterID = self:GetMonsterDataID(targetId) + iniLevel - 10 + 30000
    else
        nMonterID = self:GetMonsterDataID(targetId) + iniLevel
    end
    config.params[10] = nMonterID
    config.sn 		 = self:LuaFnGenCopySceneSN()

    local bRetSceneID = self:LuaFnCreateCopyScene(config)
    if bRetSceneID > 0 then
        if self:IsCaptain(selfId) then
            if not self:DelItem(selfId, self.g_Item, 1) then
                self:LuaFnSetCopySceneData_Param(11, 3)
            end
        end
        self:BeginEvent(self.script_id)
        self:AddText("Tạo phó bản thành công!")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
    else
        self:BeginEvent(self.script_id)
        self:AddText("Số lượng phó bản đã đạt đến giới hạn, xin hãy thử lại sau!")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
    end
end

function yezhu_catch:OnCopySceneReady(destsceneId)
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

function yezhu_catch:GotoScene(ObjId, destsceneId)
    local sn = self:LuaFnGetCopySceneData_Sn(destsceneId)
    self:NewWorld(ObjId, destsceneId, sn, self.g_Fuben_X, self.g_Fuben_Z)
end

function yezhu_catch:OnPlayerEnter(selfId)
end

function yezhu_catch:OnHumanDie(selfId, killerId)
end

function yezhu_catch:OnAbandon(selfId)
end

function yezhu_catch:BackToCity(selfId)
end

function yezhu_catch:OnContinue(selfId, targetId)
end

function yezhu_catch:CheckSubmit(selfId, selectRadioId)
end

function yezhu_catch:OnSubmit(selfId, targetId, selectRadioId)
end

function yezhu_catch:TipAllHuman(Str)
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

function yezhu_catch:OnKillObject(selfId, objdataId, objId)
end

function yezhu_catch:OnDie(objId, killerId)
    local nKillCount = self:LuaFnGetCopySceneData_Param(20)
    if self:GetName(objId) == "尖牙野猪" then
        self:LuaFnSetCopySceneData_Param(20, nKillCount + 1)
        self:TipAllHuman("Đã tiêu diệt Tiêm Nha Dã Trư" .. tostring(nKillCount + 1) .. "/30")
    end
end

function yezhu_catch:OnEnterZone(selfId, zoneId)
end

function yezhu_catch:OnItemChanged(selfId, itemdataId)
end

function yezhu_catch:OnCopySceneTimer(nowTime)
    local nStep = self:LuaFnGetCopySceneData_Param(11)
    if nStep == 0 then
        self:CreateMonster_1()
        self:LuaFnSetCopySceneData_Param(11, 1)
    end
    if nStep == 1 then
        local nCount = self:GetMonsterCount()
        local nHaveMonster = 0
        for i = 1, nCount do
            local nMonterId = self:GetMonsterObjID(i)
            if self:GetName(nMonterId) == "尖牙野猪" then
                nHaveMonster = 1
            end
        end
        if nHaveMonster == 0 then
            self:CreateMonster_2()
            self:LuaFnSetCopySceneData_Param(11, 2)
        end
    end
    if nStep == 2 then
        local nCount = self:GetMonsterCount()
        local nHaveMonster = 0
        for i = 1, nCount do
            local nMonterId = self:GetMonsterObjID(i)
            if
                self:GetName(nMonterId) == "尖牙野猪" or self:GetName(nMonterId) == "尖牙野猪王" or
                    self:GetName(nMonterId) == "狂暴龙"
             then
                nHaveMonster = 1
            end
        end
        if nHaveMonster == 0 then
            self:LuaFnSetCopySceneData_Param(11, 3)
            self:LuaFnSetCopySceneData_Param(13, self:LuaFnGetCurrentTime())
            local nType = self:LuaFnGetCopySceneData_Param(12)
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
            local str
            if nType == 0 then
                str = string.format("#{_INFOUSR%s}#P dẫn dắt quần hùng tiêu diệt Thủ lĩnh #G\"Dã Trư Nông Trại\"#P là #{_BOSS20}#P, nhưng vẫn không thể tìm ra hung thú tà ác kia.", szLeaderName)
            else
                str = string.format("#{_INFOUSR%s}#P dẫn dắt quần hùng tại #GNông Trại Heo Rừng#P tiêu diệt tội khôi họa thủ #{_BOSS21}#P, cuối cùng cũng dẹp yên được phong ba này.", szLeaderName)
            end
            str = gbk.fromutf8(str)
            self:BroadMsgByChatPipe(nLeaderId, str, 4)
            self:TipAllHuman("Phó bản sẽ đóng sau 180 giây.")
        end
    end
    if nStep == 3 then
        local nPreTime = self:LuaFnGetCopySceneData_Param(13)
        if self:LuaFnGetCurrentTime() - nPreTime >= 165 then
            self:TipAllHuman("Phó bản sẽ đóng sau 15 giây.")
            self:LuaFnSetCopySceneData_Param(11, 4)
        end
    end
    if nStep == 4 then
        local nPreTime = self:LuaFnGetCopySceneData_Param(13)
        if self:LuaFnGetCurrentTime() - nPreTime >= 175 then
            self:TipAllHuman("Phó bản sẽ đóng sau 5 giây.")
            self:LuaFnSetCopySceneData_Param(11, 5)
        end
    end
    if nStep == 5 then
        local nPreTime = self:LuaFnGetCopySceneData_Param(13)
        if self:LuaFnGetCurrentTime() - nPreTime >= 30 then
            local nHumanNum = self:LuaFnGetCopyScene_HumanCount()
            if nHumanNum < 1 then
                return
            end
            local PlayerId
            for i = 1, nHumanNum do
                PlayerId = self:LuaFnGetCopyScene_HumanObjId(i)
                self:NewWorld(PlayerId, self.g_Back_SceneId, nil, self.g_Back_X, self.g_Back_Z)
            end
            self:LuaFnSetCopySceneData_Param(11, 7)
        end
    end
end

function yezhu_catch:CreateMonster_1()
    local nInilevel = self:LuaFnGetCopySceneData_Param(9)
    local nMonterID
    if nInilevel >= 11 then
        nMonterID = self.g_MonsterInfo_1["id"] + nInilevel - 11 + 30000
    else
        nMonterID = self.g_MonsterInfo_1["id"] + nInilevel - 1
    end
    for i, Npc in pairs(self.g_MonsterPos) do
            self:LuaFnCreateMonster(
            nMonterID,
            Npc["x"],
            Npc["z"],
            self.g_MonsterInfo_1["ai"],
            self.g_MonsterInfo_1["aif"],
            402105
        )
    end
end

function yezhu_catch:CreateMonster_2()
    local nInilevel = self:LuaFnGetCopySceneData_Param(9)
    local nMonterID
    if nInilevel >= 11 then
        nMonterID = self.g_BossInfo_1["id"] + nInilevel - 11 + 30000
    else
        nMonterID = self.g_BossInfo_1["id"] + nInilevel - 1
    end
    local nNpcId =
        self:LuaFnCreateMonster(
        nMonterID,
        self.g_BossInfo_1["x"],
        self.g_BossInfo_1["z"],
        self.g_BossInfo_1["ai"],
        self.g_BossInfo_1["aif"],
        self.g_BossInfo_1["script"]
    )
    self:SetCharacterTitle(nNpcId, "Vương Nanh Quỷ")
    self:TipAllHuman("Phát hiện ra #YTiêm Nha Dã Trư Vương#W!")
    local nRand = math.random(100)
    if nRand <= self.g_BossRand_2 then
        self:LuaFnSetCopySceneData_Param(12, 1)
        if nInilevel >= 11 then
            nMonterID = self.g_BossInfo_2["id"] + nInilevel - 11 + 30000
        else
            nMonterID = self.g_BossInfo_2["id"] + nInilevel - 1
        end
            self:LuaFnCreateMonster(
            nMonterID,
            self.g_BossInfo_2["x"],
            self.g_BossInfo_2["z"],
            self.g_BossInfo_2["ai"],
            self.g_BossInfo_2["aif"],
            self.g_BossInfo_2["script"]
        )
        self:SetCharacterTitle(nNpcId, "Thiên Niên Thiên Thánh Thú")
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
        local str
        str = string.format("#PĐược #{_INFOUSR%s}#P dẫn dắt, chúng anh hùng tại Thánh Thú Sơn dốc sức chế ngự đàn lợn, thắng lợi trong gang tấc thì đột nhiên nhảy ra một con #{_BOSS21}!", szLeaderName)
        str = gbk.fromutf8(str)
        self:BroadMsgByChatPipe(nLeaderId, str, 4)
    end
end

return yezhu_catch
