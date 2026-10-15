local skynet = require "skynet"
local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local FB_cangjinge_FB = class("FB_cangjinge_FB", script_base)
FB_cangjinge_FB.script_id = 402112
FB_cangjinge_FB.g_CopySceneName = "藏经阁"
FB_cangjinge_FB.g_CopySceneType = ScriptGlobal.FUBEN_PORTECT_PET
FB_cangjinge_FB.g_CloseTime = 30 * 60
FB_cangjinge_FB.g_XiaoGuaiCount = 13
FB_cangjinge_FB.g_XiaoGuaiTime = 60
FB_cangjinge_FB.g_CopySceneMap = "cangjingge.nav"
FB_cangjinge_FB.g_client_res = 272
FB_cangjinge_FB.g_Exit = "cangjingge.ini"
FB_cangjinge_FB.g_LimitMembers = 3
FB_cangjinge_FB.g_TickTime = 1
FB_cangjinge_FB.g_LimitTotalHoldTime = 360
FB_cangjinge_FB.g_LimitTimeSuccess = 500
FB_cangjinge_FB.g_CloseTick = 3
FB_cangjinge_FB.g_NoUserTime = 10
FB_cangjinge_FB.g_DeadTrans = 0
FB_cangjinge_FB.g_Fuben_X = 64
FB_cangjinge_FB.g_Fuben_Z = 103
FB_cangjinge_FB.g_Back_X = 264
FB_cangjinge_FB.g_Back_Z = 278
FB_cangjinge_FB.g_Back_SceneId = 18
FB_cangjinge_FB.g_PetSceneId = 18
FB_cangjinge_FB.g_SetpTime = 1
FB_cangjinge_FB.g_SetpWaiteTime_1 = 15
FB_cangjinge_FB.g_SetpWaiteTime_2 = 25
FB_cangjinge_FB.g_SetpWaiteTime_3 = 35
FB_cangjinge_FB.g_SetpWaiteTime_4 = 45
FB_cangjinge_FB.g_SetpWaiteTime_5 = 55
FB_cangjinge_FB.g_SetpWaiteTime_6 = 65
FB_cangjinge_FB.g_SetpWaiteTime_7 = 75
FB_cangjinge_FB.g_SetpWaiteTime_8 = 85
FB_cangjinge_FB.g_MonsterInfo_1 = {["id"] = 113583, ["x"] = 23, ["z"] = 47, ["ai"] = 9, ["ai_f"] = 0, ["p"] = 0}

FB_cangjinge_FB.g_MonsterInfo_2 = {["id"] = 113583, ["x"] = 103, ["z"] = 48, ["ai"] = 9, ["ai_f"] = 0, ["p"] = 1}

FB_cangjinge_FB.g_MonsterInfo_3 = {["id"] = 113574, ["x"] = 23, ["z"] = 47, ["ai"] = 9, ["ai_f"] = 0, ["p"] = 0}

FB_cangjinge_FB.g_MonsterInfo_4 = {["id"] = 113574, ["x"] = 103, ["z"] = 48, ["ai"] = 9, ["ai_f"] = 0, ["p"] = 1}

FB_cangjinge_FB.g_MonsterInfo_5 = {["id"] = 113592, ["x"] = 64, ["z"] = 32, ["ai"] = 9, ["ai_f"] = 234, ["p"] = 0}

FB_cangjinge_FB.g_MonsterAI = {
    {["id"] = 113565, ["ai"] = 3},
    {["id"] = 113566, ["ai"] = 3},
    {["id"] = 113567, ["ai"] = 3},
    {["id"] = 113568, ["ai"] = 3},
    {["id"] = 113569, ["ai"] = 3},
    {["id"] = 113570, ["ai"] = 3},
    {["id"] = 113571, ["ai"] = 3},
    {["id"] = 113572, ["ai"] = 3},
    {["id"] = 113573, ["ai"] = 3}
}

FB_cangjinge_FB.g_MonsterInfo_Count_1 = 10
FB_cangjinge_FB.g_MonsterInfo_Count_2 = 7
FB_cangjinge_FB.g_MonsterInfo_Count_3 = 8
FB_cangjinge_FB.g_MonsterInfo_Count_4 = 5
FB_cangjinge_FB.g_MonsterInfo_Count_5 = 5
FB_cangjinge_FB.g_MonsterInfo_Count_6 = 8
FB_cangjinge_FB.g_MonsterInfo_Count_7 = 20






function FB_cangjinge_FB:OnDefaultEvent(selfId, targetId, arg, index)
	if not self:LuaFnIsActivityMonster(selfId,targetId,true) then return end
    if index == 1010 then
        self:BeginEvent(self.script_id)
        self:AddText(
            "    Bần tăng gần đây qua suy tính và nghe ngóng giang hồ, biết có đám ác tăng nhiều lần xâm nhập Thiếu Lâm muốn đoạt điển tịch võ học. Võ tăng vân du Thiếu Lâm thường tập kết ở#GNhạn Nam#W, rồi về chùa chi viện. Mỗi ngày#G10:45, 16:30, 21:30 và 23:00#Wlà giờ chúng ta tập kết."
        )
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if not self:LuaFnHasTeam(selfId) then
        self:BeginEvent(self.script_id)
        self:AddText("#BTàng Kinh Các")
        self:AddText("   Vào phụ bản cần một đội.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if self:GetTeamSize(selfId) < self.g_LimitMembers then
        self:BeginEvent(self.script_id)
        self:AddText("#BTàng Kinh Các")
        self:AddText("  Vào phụ bản cần một đội.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if self:GetTeamLeader(selfId) ~= selfId then
        self:BeginEvent(self.script_id)
        self:AddText("#BTàng Kinh Các")
        self:AddText("  Vào phụ bản cần một đội.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if self:GetTeamSize(selfId) ~= self:GetNearTeamCount(selfId) then
        self:BeginEvent(self.script_id)
        self:AddText("#BTàng Kinh Các")
        self:AddText("  Vào phụ bản cần một đội.")
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
        self:AddText("#BTàng Kinh Các")
        self:AddText("  Trong đội của ngươi có thành viên (" .. szAllName .. "）dưới cấp 40, không tham gia Tàng Kinh Các được.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if self:MakeCopyScene(selfId, targetId) then
        self:LuaFnDeleteMonster(targetId)
    end
end

function FB_cangjinge_FB:OnEnumerate(caller, selfId, targetId, arg, index)
    caller:AddText(
        "    Bần tăng gần đây qua suy tính và nghe ngóng giang hồ, biết có đám ác tăng nhiều lần xâm nhập Thiếu Lâm muốn đoạt điển tịch võ học. Võ tăng vân du Thiếu Lâm thường tập kết ở#GNhạn Nam#W, rồi về chùa chi viện. Mỗi ngày#G10:45, 16:30, 21:30 và 23:00#Wlà giờ chúng ta tập kết."
    )
    caller:AddNumTextWithTarget(self.script_id, "藏经阁", 10, -1)
    caller:AddNumTextWithTarget(self.script_id, "Về Tàng Kinh Các", 11, 1010)
end

function FB_cangjinge_FB:CheckAccept(selfId)
end

function FB_cangjinge_FB:AskEnterCopyScene(selfId)
end

function FB_cangjinge_FB:OnAccept(selfId, targetId)
end

function FB_cangjinge_FB:AcceptEnterCopyScene(selfId)
end

function FB_cangjinge_FB:MakeCopyScene(selfId, targetId)
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
    local leaderguid = self:LuaFnObjId2Guid(selfId)
    local config = {}
    config.navmapname = "cangjingge.nav"
    config.client_res = self.g_client_res
    config.teamleader = leaderguid
    config.NoUserCloseTime = 100 * 1000
    config.Timer = self.g_TickTime * 1000
    config.params = {}
    config.params[0] = self.g_CopySceneType
    config.params[1] = self.script_id
    config.params[2] = 0
    config.params[3] = -1
    config.params[4] = 0
    config.params[5] = 0
    config.params[6] = self:GetTeamId( selfId )
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
    config.params[8] = math.floor(mylevel)
    config.params[9] = iniLevel
    config.params[10] = self:GetMonsterDataID(targetId)
    local x, z = self:GetWorldPos(selfId)
    config.params[16] = x
    config.params[17] = z
    config.sn 		 = self:LuaFnGenCopySceneSN()
    config.patrolpoint = "cangjingge_patrolpoint.ini"
    local bRetSceneID = self:LuaFnCreateCopyScene(config)
    self:BeginEvent(self.script_id)
    if bRetSceneID > 0 then
        self:AddText("Tạo phó bản thành công!")
    else
        self:AddText("Số lượng phó bản đã đạt đến giới hạn, xin hãy thử lại sau!")
    end
    self:EndEvent()
    self:DispatchMissionTips(selfId)
    return bRetSceneID > 0
end

function FB_cangjinge_FB:OnCopySceneReady(destsceneId)
    local sceneId = self:get_scene_id()
    self:LuaFnSetCopySceneData_Param(destsceneId, 3, sceneId)
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

function FB_cangjinge_FB:GotoScene(ObjId, destsceneId)
    local sn = self:LuaFnGetCopySceneData_Sn(destsceneId)
    self:NewWorld(ObjId, destsceneId, sn, self.g_Fuben_X, self.g_Fuben_Z, self.g_client_res)
end

function FB_cangjinge_FB:OnPlayerEnter(selfId)
    print("FB_cangjinge_FB:OnPlayerEnter", selfId)
    self:SetPlayerDefaultReliveInfo(selfId, 1, 1, 0, self.g_Fuben_X, self.g_Fuben_Z)
    self:SetUnitCampID(selfId, 100)
    self:TipAllHuman("Ác Tăng Trộm Sách tấn công sau 15 giây, chú ý đẩy lùi hết trong 20 phút!")
end

function FB_cangjinge_FB:OnHumanDie(selfId, killerId)
end

function FB_cangjinge_FB:OnAbandon(selfId)
end

function FB_cangjinge_FB:BackToCity(selfId)
end

function FB_cangjinge_FB:OnContinue(selfId, targetId)
end

function FB_cangjinge_FB:CheckSubmit(selfId, selectRadioId)
end

function FB_cangjinge_FB:OnSubmit(selfId, targetId, selectRadioId)
end

function FB_cangjinge_FB:TipAllHuman(Str)
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

function FB_cangjinge_FB:OnKillObject(selfId, objdataId, objId)
end

function FB_cangjinge_FB:OnEnterZone(selfId, zoneId)
end

function FB_cangjinge_FB:OnItemChanged(selfId, itemdataId)
end

function FB_cangjinge_FB:CysAbortSpawn()
    if self:LuaFnGetCopySceneData_Param(21) == -1 then return end
    self:LuaFnSetCopySceneData_Param(21, -1)
    skynet.loge("CYS Cangjingge: instance monster creation failed", self:get_scene_id())
    self:TipAllHuman("Không thể tạo quái phụ bản. Đội được đưa về vị trí cũ; hãy báo GM kiểm tra.")
    local ids = {}
    for i = 1, self:LuaFnGetCopyScene_HumanCount() do
        ids[#ids+1] = self:LuaFnGetCopyScene_HumanObjId(i)
    end
    for _, id in ipairs(ids) do self:KickOut(id) end
end

function FB_cangjinge_FB:OnCopySceneTimer(nowTime)
    if self:LuaFnGetCopySceneData_Param(21) == -1 then return end
    local TickCount = self:LuaFnGetCopySceneData_Param(2)
    TickCount = TickCount + 1
    self:LuaFnSetCopySceneData_Param(2, TickCount)
    local nLastTime = self.g_CloseTime
    local NndTime = self:LuaFnGetCopySceneData_Param(21)
    if TickCount == 1 then
        local nMonterIniID = self:LuaFnGetCopySceneData_Param(9)
        local nMonterID = self:LuaFnGetCopySceneData_Param(10)
        local nRetrievalMonterID
        if nMonterIniID >= 11 then
            nRetrievalMonterID = nMonterID + 8
        else
            nRetrievalMonterID = nMonterID + nMonterIniID - 3
        end
        local nNpcId = self:LuaFnCreateMonster(nRetrievalMonterID, 64, 105, 9, 226, -1)
        if not nNpcId or nNpcId <= 0 then self:CysAbortSpawn(); return end
        self:SetUnitCampID(nNpcId, 100)
        self:SetCharacterTitle(nNpcId, "Cao tăng Thiếu Lâm")
        self:SetMonsterFightWithNpcFlag(nNpcId, 1)
        self:LuaFnSetCopySceneData_Param(15, nNpcId)
    end
    if TickCount == 10 then
        self:TipAllHuman("Ác Tăng Trộm Sách tấn công lần một từ góc trên trái!")
        self:TipAllHuman("30 giây nữa Ác Tăng Trộm Sách tấn công đợt tiếp!")
        self:CreateNpcBOSS(0)
        self:CreateXiaoBOSS(0)
    end
    if TickCount == self.g_XiaoGuaiTime * 2 then
        self:TipAllHuman("Ác Tăng Trộm Sách tấn công lần hai từ góc trên phải!")
        self:TipAllHuman("30 giây nữa Ác Tăng Trộm Sách tấn công đợt tiếp!")
        self:CreateNpcBOSS(1)
        self:CreateXiaoBOSS(1)
    end
    if TickCount == self.g_XiaoGuaiTime * 3 then
        self:TipAllHuman("Ác Tăng Trộm Sách tấn công lần ba từ góc trên trái!")
        self:TipAllHuman("30 giây nữa Ác Tăng Trộm Sách tấn công đợt tiếp!")
        self:CreateNpcBOSS(0)
        self:CreateXiaoBOSS(0)
    end
    if TickCount == self.g_XiaoGuaiTime * 4 then
        self:TipAllHuman("Ác Tăng Trộm Sách tấn công lần bốn từ góc trên phải!")
        self:TipAllHuman("30 giây nữa Ác Tăng Trộm Sách tấn công đợt tiếp!")
        self:CreateNpcBOSS(1)
        self:CreateXiaoBOSS(1)
    end
    if TickCount == self.g_XiaoGuaiTime * 5 then
        self:TipAllHuman("Ác Tăng Trộm Sách tấn công lần năm từ góc trên trái!")
        self:TipAllHuman("30 giây nữa Ác Tăng Trộm Sách tấn công đợt tiếp!")
        self:CreateNpcBOSS(0)
        self:CreateXiaoBOSS(0)
    end
    if TickCount == self.g_XiaoGuaiTime * 6 then
        self:TipAllHuman("Ác Tăng Trộm Sách tấn công lần sáu từ góc trên phải!")
        self:TipAllHuman("30 giây nữa Ác Tăng Trộm Sách tấn công đợt tiếp!")
        self:CreateXiaoBOSS(1)
        self:CreateNpcBOSS(1)
    end
    if TickCount == self.g_XiaoGuaiTime * 7 then
        self:TipAllHuman("Ác Tăng Trộm Sách tấn công lần bảy từ góc trên trái!")
        self:TipAllHuman("30 giây nữa Ác Tăng Trộm Sách tấn công đợt sau!")
        self:CreateNpcBOSS(0)
        self:CreateXiaoBOSS(0)
    end
    if TickCount == self.g_XiaoGuaiTime * 8 then
        self:TipAllHuman("Ác Tăng Trộm Sách tấn công lần tám từ góc trên phải!")
        self:TipAllHuman("30 giây nữa Ác Tăng Trộm Sách tấn công đợt sau!")
        self:CreateNpcBOSS(1)
        self:CreateXiaoBOSS(1)
    end
    if TickCount == self.g_XiaoGuaiTime * 9 then
        self:TipAllHuman("Ác Tăng Trộm Sách tấn công lần chín từ góc trên trái!")
        self:TipAllHuman("30 giây nữa Ác Tăng Trộm Sách tấn công đợt sau!")
        self:CreateNpcBOSS(0)
        self:CreateXiaoBOSS(0)
    end
    if TickCount == self.g_XiaoGuaiTime * 10 then
        self:TipAllHuman("Ác Tăng Trộm Sách tấn công lần mười từ góc trên phải!")
        self:TipAllHuman("30 giây nữa Ác Tăng Trộm Sách tấn công đợt sau!")
        self:CreateNpcBOSS(1)
        self:CreateXiaoBOSS(1)
    end
    if TickCount == self.g_XiaoGuaiTime * 11 then
        self:TipAllHuman("Ác Tăng Trộm Sách tấn công lần mười một từ góc trên trái!")
        self:TipAllHuman("30 giây nữa Ác Tăng Trộm Sách tấn công đợt sau!")
        self:CreateNpcBOSS(0)
        self:CreateXiaoBOSS(0)
    end
    if TickCount == self.g_XiaoGuaiTime * 12 then
        self:TipAllHuman("Ác Tăng Trộm Sách tấn công lần mười hai từ góc trên phải!")
        self:TipAllHuman("30 giây nữa Ác Tăng Trộm Sách tấn công đợt sau!")
        self:CreateNpcBOSS(1)
        self:CreateXiaoBOSS(1)
    end
    if TickCount == self.g_XiaoGuaiTime * 13 then
        self:TipAllHuman("Ác Tăng Trộm Sách tấn công lần mười ba từ góc trên trái!")
        self:TipAllHuman("30 giây nữa đầu sỏ Ác Tăng Bịt Mặt xuất hiện!")
        self:CreateNpcBOSS(0)
        self:CreateXiaoBOSS(0)
    end
    if TickCount == (self.g_XiaoGuaiTime * 13 + 30) then
        local Npc = self.g_MonsterInfo_5
        local nNpcId = self:CreateNpc(Npc["id"], Npc["x"], Npc["z"], Npc["ai"], Npc["ai_f"], 402112,227766)
        if not nNpcId or nNpcId <= 0 then self:CysAbortSpawn(); return end
        self:SetUnitCampID(nNpcId, 101)
        self:SetMonsterFightWithNpcFlag(nNpcId, 1)
        self:SetCharacterTitle(nNpcId, "Diệu Thủ Không Không")
        self:TipAllHuman("Đầu sỏ Ác Tăng Bịt Mặt xuất hiện!!")
        self:LuaFnSetCopySceneData_Param(13, nNpcId)
        local nPlayerNum = self:LuaFnGetCopyScene_HumanCount()
        for i = 1, nPlayerNum do
            local nPlayerId = self:LuaFnGetCopyScene_HumanObjId(i)
            self:LuaFnAddMissionHuoYueZhi(nPlayerId, 19)
        end
    end
    local bOk = 0
    local nNpcId = self:LuaFnGetCopySceneData_Param(15)
    local nMonsterCount = self:GetMonsterCount()
    for i = 1, nMonsterCount do
        local nMontserid = self:GetMonsterObjID(i)
        if nNpcId == nMontserid and self:LuaFnIsCharacterLiving(nMontserid) then
            bOk = 1
        end
    end
    if bOk == 0 then
        self:TipAllHuman("Hộ tăng chết, khiêu chiến thất bại")
        local nHumanNum = self:LuaFnGetCopyScene_HumanCount()
        for i = 1, nHumanNum do
            local nPlayerId = self:LuaFnGetCopyScene_HumanObjId(i)
            self:KickOut(nPlayerId)
        end
    end
    if TickCount >= nLastTime - 20 then
        nNpcId = self:LuaFnGetCopySceneData_Param(15)
        bOk = 0
        nMonsterCount = self:GetMonsterCount()
        for i = 1, nMonsterCount do
            local nMontserid = self:GetMonsterObjID(i)
            if nNpcId == nMontserid and self:LuaFnIsCharacterLiving(nMontserid) then
                bOk = 1
            end
        end
        if bOk == 1 and NndTime == 0 then
            local nHumanNum = self:LuaFnGetCopyScene_HumanCount()
            if nHumanNum < 1 then
                return
            end
            self:TipAllHuman("Khiêu chiến Tàng Kinh Các thành công!")
            self:LuaFnSetCopySceneData_Param(21, 1)
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
            local str = string.format("#GTrong Tàng Kinh Các#P,#{_INFOUSR%s}#Pdẫn quần hào giang hồ phá âm mưu ác tăng trộm tuyệt kỹ Thiếu Lâm, hoàn bích quy Triệu bí kíp bị trộm. Đúng là gương hào kiệt võ lâm!!", szLeaderName)
            str = gbk.fromutf8(str)
            self:BroadMsgByChatPipe(nLeaderId, str, 4)
        end
    end
    if TickCount == nLastTime - 15 then
        self:TipAllHuman("Phó bản sẽ đóng sau 15 giây.")
    end
    if TickCount == nLastTime - 10 then
        self:TipAllHuman("Phó bản sẽ đóng sau 10 giây.")
    end
    if TickCount == nLastTime - 5 then
        self:TipAllHuman("Phó bản sẽ đóng sau 5 giây.")
    end
    if TickCount == nLastTime then
        local nHumanNum = self:LuaFnGetCopyScene_HumanCount()
        for i = 1, nHumanNum do
            local nPlayerId = self:LuaFnGetCopyScene_HumanObjId(i)
            self:KickOut(nPlayerId)
        end
    end
end

function FB_cangjinge_FB:OnDie(objId, killerId)
    if objId ~= self:LuaFnGetCopySceneData_Param(13) then return end
    self:LuaFnSetCopySceneData_Param(2, (self.g_CloseTime - 20))
end

function FB_cangjinge_FB:KickOut(objId)
    local oldsceneId = self:LuaFnGetCopySceneData_Param(3)
    local x = self:LuaFnGetCopySceneData_Param(16)
    local z = self:LuaFnGetCopySceneData_Param(17)
    if self:LuaFnIsObjValid(objId) then
        self:NewWorld(objId, oldsceneId, nil, x, z)
    end
end

function FB_cangjinge_FB:CreateNpcBOSS(fangxiang)

    local Npc = self.g_MonsterInfo_1
    if fangxiang == 1 then
        Npc = self.g_MonsterInfo_2
		local createcount = self:LuaFnGetCopySceneData_Param(24)
		if createcount < 6 then
			createcount = createcount + 1
			self:LuaFnSetCopySceneData_Param(24,createcount)
		else
			return
		end
	else
		local createcount = self:LuaFnGetCopySceneData_Param(25)
		if createcount < 7 then
			createcount = createcount + 1
			self:LuaFnSetCopySceneData_Param(25,createcount)
		else
			return
		end
    end
    for i = 1, self.g_XiaoGuaiCount do
        local nNpcId = self:CreateNpc(Npc["id"], Npc["x"], Npc["z"], Npc["ai"], Npc["ai_f"], -1,227766)
        if nNpcId > 0 then
            self:SetUnitCampID(nNpcId, 101)
            self:SetMonsterFightWithNpcFlag(nNpcId, 1)
            self:SetPatrolId(nNpcId, Npc["p"])
        end
    end
end

function FB_cangjinge_FB:CreateXiaoBOSS(fangxiang)
    if fangxiang == 0 then
		local createcount = self:LuaFnGetCopySceneData_Param(22)
		if createcount < 7 then
			createcount = createcount + 1
			self:LuaFnSetCopySceneData_Param(22,createcount)
		else
			return
		end
        local nMonsterIda = self:CreateNpc(113574, 23, 47, 9, -1, -1, 227766)
        if not nMonsterIda or nMonsterIda <= 0 then self:CysAbortSpawn(); return end
        self:SetUnitCampID(nMonsterIda, 101)
        self:SetMonsterFightWithNpcFlag(nMonsterIda, 1)
        self:SetPatrolId(nMonsterIda, 0)
    else
		local createcount = self:LuaFnGetCopySceneData_Param(23)
		if createcount < 6 then
			createcount = createcount + 1
			self:LuaFnSetCopySceneData_Param(23,createcount)
		else
			return
		end
        local nMonsterIdb = self:CreateNpc(113574, 103, 48, 9, -1, -1, 227766)
        if not nMonsterIdb or nMonsterIdb <= 0 then self:CysAbortSpawn(); return end
        self:SetUnitCampID(nMonsterIdb, 101)
        self:SetMonsterFightWithNpcFlag(nMonsterIdb, 1)
        self:SetPatrolId(nMonsterIdb, 1)
    end
end

function FB_cangjinge_FB:CreateNpc(NpcId, x, y, Ai, AiFile, Script,paramx)
	if paramx ~= 227766 then
		return -1
	end
    local PlayerLevel = self:LuaFnGetCopySceneData_Param(8)
    local ModifyLevel = self:LuaFnGetCopySceneData_Param(9)
    local nNpcId = 0
    if ModifyLevel >= 11 then
        nNpcId = NpcId + 8
    else
        nNpcId = NpcId + ModifyLevel - 3
    end
    local nMonsterId = self:LuaFnCreateMonster(nNpcId, x, y, Ai, AiFile, Script)
    if not nMonsterId or nMonsterId <= 0 then self:CysAbortSpawn(); return -1 end
    self:SetLevel(nMonsterId, math.floor(PlayerLevel))
    return nMonsterId
end

return FB_cangjinge_FB
