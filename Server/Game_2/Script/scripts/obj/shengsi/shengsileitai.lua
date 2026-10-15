local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local shengsileitai = class("shengsileitai", script_base)
local ScriptGlobal = require "scripts.ScriptGlobal"
shengsileitai.script_id = 892009
shengsileitai.g_CopySceneType = ScriptGlobal.FUBEN_GODFIRE
shengsileitai.g_client_res = 546
shengsileitai.g_TickTime = 1
shengsileitai.g_NoUserTime = 10
shengsileitai.g_Fuben_X = 19
shengsileitai.g_Fuben_Z = 33
shengsileitai.g_FuBenTime = 3 * 60 * 60
shengsileitai.g_BOSSList = {
    ["lujunyi_NPC"] = {
        ["DataID"] = 13553,
        ["Title"] = "Thiên Cương Tinh",
        ["posX"] = 44,
        ["posY"] = 23,
        ["Dir"] = 11,
        ["BaseAI"] = 3,
        ["AIScript"] = 0,
        ["ScriptID"] = 760704
    },
    ["lujunyi_BOSS"] = {
        ["DataID"] = 13461,
        ["Title"] = "",
        ["posX"] = 30,
        ["posY"] = 32,
        ["Dir"] = 0,
        ["BaseAI"] = 27,
        ["AIScript"] = 0,
        ["ScriptID"] = 892011
    },
    ["luzhishen_NPC"] = {
        ["DataID"] = 13556,
        ["Title"] = "Thiên Cô Tinh",
        ["posX"] = 44,
        ["posY"] = 27,
        ["Dir"] = 11,
        ["BaseAI"] = 3,
        ["AIScript"] = 0,
        ["ScriptID"] = 760705
    },
    ["luzhishen_BOSS"] = {
        ["DataID"] = 13488,
        ["Title"] = "",
        ["posX"] = 30,
        ["posY"] = 32,
        ["Dir"] = 0,
        ["BaseAI"] = 27,
        ["AIScript"] = 0,
        ["ScriptID"] = 892017
    },
    ["likui_NPC"] = {
        ["DataID"] = 13551,
        ["Title"] = "Thiên Sát Tinh",
        ["posX"] = 44,
        ["posY"] = 31,
        ["Dir"] = 11,
        ["BaseAI"] = 3,
        ["AIScript"] = 0,
        ["ScriptID"] = 760706
    },
    ["likui_BOSS"] = {
        ["DataID"] = 13443,
        ["Title"] = "",
        ["posX"] = 30,
        ["posY"] = 32,
        ["Dir"] = 0,
        ["BaseAI"] = 27,
        ["AIScript"] = 0,
        ["ScriptID"] = 892012
    },
    ["huarong_NPC"] = {
        ["DataID"] = 13560,
        ["Title"] = "Thiên Anh Tinh",
        ["posX"] = 44,
        ["posY"] = 35,
        ["Dir"] = 11,
        ["BaseAI"] = 3,
        ["AIScript"] = 0,
        ["ScriptID"] = 760707
    },
    ["huarong_BOSS"] = {
        ["DataID"] = 13524,
        ["Title"] = "",
        ["posX"] = 30,
        ["posY"] = 32,
        ["Dir"] = 0,
        ["BaseAI"] = 27,
        ["AIScript"] = 0,
        ["ScriptID"] = 892013
    },
    ["songjiang_NPC"] = {
        ["DataID"] = 13550,
        ["Title"] = "Thiên Khôi Tinh",
        ["posX"] = 44,
        ["posY"] = 39,
        ["Dir"] = 11,
        ["BaseAI"] = 3,
        ["AIScript"] = 0,
        ["ScriptID"] = 760708
    },
    ["songjiang_BOSS"] = {
        ["DataID"] = 13434,
        ["Title"] = "",
        ["posX"] = 30,
        ["posY"] = 32,
        ["Dir"] = 0,
        ["BaseAI"] = 27,
        ["AIScript"] = 0,
        ["ScriptID"] = 892016
    },
    ["guansheng_NPC"] = {
        ["DataID"] = 13555,
        ["Title"] = "Thiên Dũng Tinh",
        ["posX"] = 44,
        ["posY"] = 43,
        ["Dir"] = 11,
        ["BaseAI"] = 3,
        ["AIScript"] = 0,
        ["ScriptID"] = 760709
    },
    ["guansheng_BOSS"] = {
        ["DataID"] = 13479,
        ["Title"] = "",
        ["posX"] = 30,
        ["posY"] = 32,
        ["Dir"] = 0,
        ["BaseAI"] = 27,
        ["AIScript"] = 0,
        ["ScriptID"] = 892010
    },
    ["gongsongshen_NPC"] = {
        ["DataID"] = 13554, ["Title"] = "", ["posX"] = 44, ["posY"] = 23,
        ["Dir"] = 11, ["BaseAI"] = 3, ["AIScript"] = 0, ["ScriptID"] = 892014
    },
    ["wuyong_NPC"] = {
        ["DataID"] = 13552, ["Title"] = "", ["posX"] = 44, ["posY"] = 27,
        ["Dir"] = 11, ["BaseAI"] = 3, ["AIScript"] = 0, ["ScriptID"] = 892015
    },
    ["qinming_NPC"] = {
        ["DataID"] = 13559, ["Title"] = "", ["posX"] = 44, ["posY"] = 31,
        ["Dir"] = 11, ["BaseAI"] = 3, ["AIScript"] = 0, ["ScriptID"] = 892018
    },
    ["linchong_NPC"] = {
        ["DataID"] = 13558, ["Title"] = "", ["posX"] = 44, ["posY"] = 35,
        ["Dir"] = 11, ["BaseAI"] = 3, ["AIScript"] = 0, ["ScriptID"] = 892019
    },
    ["huyanzhuo_NPC"] = {
        ["DataID"] = 13557, ["Title"] = "", ["posX"] = 44, ["posY"] = 39,
        ["Dir"] = 11, ["BaseAI"] = 3, ["AIScript"] = 0, ["ScriptID"] = 892020
    },
    ["wusong_NPC"] = {
        ["DataID"] = 13561, ["Title"] = "", ["posX"] = 44, ["posY"] = 43,
        ["Dir"] = 11, ["BaseAI"] = 3, ["AIScript"] = 0, ["ScriptID"] = 892021
    }
}

shengsileitai.g_FightBOSSList = {
    [1] = shengsileitai.g_BOSSList["lujunyi_BOSS"]["DataID"],
    [2] = shengsileitai.g_BOSSList["luzhishen_BOSS"]["DataID"],
    [3] = shengsileitai.g_BOSSList["likui_BOSS"]["DataID"],
    [4] = shengsileitai.g_BOSSList["huarong_BOSS"]["DataID"],
    [5] = shengsileitai.g_BOSSList["songjiang_BOSS"]["DataID"],
    [6] = shengsileitai.g_BOSSList["guansheng_BOSS"]["DataID"],
    [7] = 13474,
    [8] = 13456,
    [9] = 13519,
    [10] = 13510,
    [11] = 13501,
    [12] = 13537
}

shengsileitai.g_StarNpcPool = {
    "lujunyi_NPC", "luzhishen_NPC", "likui_NPC", "huarong_NPC",
    "songjiang_NPC", "guansheng_NPC", "gongsongshen_NPC", "wuyong_NPC",
    "qinming_NPC", "linchong_NPC", "huyanzhuo_NPC", "wusong_NPC"
}

shengsileitai.g_StarNpcSlots = {
    {44, 23}, {44, 27}, {44, 31}, {44, 35}, {44, 39}, {44, 43}
}

shengsileitai.g_BattleFlagTbl = {
    ["lujunyi"] = 8,
    ["luzhishen"] = 9,
    ["likui"] = 10,
    ["huarong"] = 12,
    ["songjiang"] = 52,
    ["guansheng"] = 62
}

shengsileitai.g_IDX_BattleFlag_lujunyi = 8
shengsileitai.g_IDX_BattleFlag_luzhishen = 9
shengsileitai.g_IDX_BattleFlag_likui = 10
shengsileitai.g_IDX_BattleFlag_huarong = 12
shengsileitai.g_IDX_BattleFlag_songjiang = 52
shengsileitai.g_IDX_BattleFlag_guansheng = 62
shengsileitai.g_IDX_FuBenOpenTime = 13
shengsileitai.g_IDX_FuBenLifeStep = 14
shengsileitai.g_IDX_SJZTimerStep = 15
shengsileitai.g_IDX_SJZTimerScriptID = 16
shengsileitai.g_IDX_likuiDieStep = 17
shengsileitai.g_IDX_likuiDieScriptID = 18
shengsileitai.g_IDX_likuiDiePosX = 19
shengsileitai.g_IDX_likuiDiePosY = 20
shengsileitai.g_MinMans = 3
shengsileitai.g_MinLevel = 70
shengsileitai.g_MaxCount = 2
function shengsileitai:OnEventRequest(selfId, targetId, arg, index)
    if index == 1 then
        local ret, msg = self:CheckCanEnter(selfId, targetId)
        if 1 ~= ret then
            self:BeginEvent(self.script_id)
            self:AddText(msg)
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
            return
        end
        self:BeginUICommand()
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
        self:MakeCopyScene(selfId)
        local nam = self:LuaFnGetName(selfId)
        local strText = "#gff00f0Người chơi#gffff00" .. nam .. "#gff00f0dẫn đội vào phụ bản Sinh Tử Lôi Đài, trừ ác dương thiện cho dân Đại Lý."
        strText = gbk.fromutf8(strText)
        self:BroadMsgByChatPipe(selfId, strText, 4)
    end
    if index == 2 then
        self:CallScriptFunction((400900), "TransferFunc",selfId,2,131,79,1)
        return
    end
end

function shengsileitai:OnEnumerate(caller, selfId, targetId, arg, index)
    local sceneId = self:GetSceneID()
    if sceneId == 2 then
        caller:AddNumTextWithTarget(self.script_id, "Sát Tinh", 6, 1)
    else
        caller:AddNumTextWithTarget(self.script_id, "Trở về Đại Lý", 9, 2)
    end
end

function shengsileitai:CheckCanEnter(selfId, targetId)
    if not self:LuaFnHasTeam(selfId) then
        return 0, "#{PMF_20080521_02}"
    end
    if self:GetTeamLeader(selfId) ~= selfId then
        return 0, "#{PMF_20080521_03}"
    end
    if self:GetTeamSize(selfId) < self.g_MinMans then
        return 0, "#{PMF_20080521_04}"
    end
    local NearTeamSize = self:GetNearTeamCount(selfId)
    if self:GetTeamSize(selfId) ~= NearTeamSize then
        return 0, "#{PMF_20080521_05}"
    end
    local Humanlist = {}
    local nHumanNum = 0
    for i = 1, NearTeamSize do
        local PlayerId = self:GetNearTeamMember(selfId, i)
        if self:GetLevel(PlayerId) < self.g_MinLevel then
            Humanlist[nHumanNum] = self:GetName(PlayerId)
            nHumanNum = nHumanNum + 1
        end
    end
    if nHumanNum > 0 then
        local msg = "    Trong đội ngũ của"
        for i = 1, nHumanNum - 1 do
            msg = msg .. Humanlist[i] .. "，"
        end
        msg = msg .. Humanlist[nHumanNum - 1] .. "Không đủ" .. self.g_MinLevel .. "cấp, tốt nhất đừng đi."
        return 0, msg
    end
    nHumanNum = 0
    local CurDayTime = self:GetDayTime()
    for i = 1, NearTeamSize do
        local PlayerId = self:GetNearTeamMember(selfId, i)
        local lastTime = self:GetMissionData(PlayerId, define.MD_ENUM.MD_SHAXING_DAYTIME) 
        local lastDayTime = math.floor(lastTime / 100)
        local lastDayCount = lastTime % 100
        if CurDayTime > lastDayTime then
            lastDayCount = 0
        end
        if lastDayCount >= self.g_MaxCount then
            Humanlist[nHumanNum] = self:GetName(PlayerId)
            nHumanNum = nHumanNum + 1
        end
    end
    if nHumanNum > 0 then
        local msg = "    "
        for i = 0, nHumanNum - 2 do
            msg = msg .. Humanlist[i] .. "，"
        end
        msg = msg .. Humanlist[nHumanNum - 1] .. "Hôm nay ngươi đã tham gia" .. self.g_MaxCount .. "lần phụ bản Sát Tinh rồi, mai hãy tới."
        return 0, msg
    end
    return 1
end

function shengsileitai:MakeCopyScene(selfId)
    local x, z = self:LuaFnGetWorldPos(selfId)
    local leaderguid = self:LuaFnObjId2Guid(selfId)
    local config = {}
    config.navmapname = "shengsileitai.nav"
    config.client_res = self.g_client_res
    config.teamleader = leaderguid
    config.NoUserCloseTime = self.g_NoUserTime * 1000
    config.Timer = self.g_TickTime * 1000
    config.params = {}
    config.params[0] = self.g_CopySceneType
    config.params[1] = self.script_id
    config.params[2] = 0
    config.params[3] = -1
    config.params[4] = x
    config.params[5] = z
    config.params[6] = self:GetTeamId(selfId)
    config.params[7] = 0
    for i = 8, 31 do
        config.params[i] = 0
    end
    config.params[self.g_IDX_BattleFlag_lujunyi]   = 0
    config.params[self.g_IDX_BattleFlag_luzhishen] = 0
    config.params[self.g_IDX_BattleFlag_likui]     = 0
    config.params[self.g_IDX_BattleFlag_huarong]   = 0
    config.params[self.g_IDX_BattleFlag_songjiang] = 0
    config.params[self.g_IDX_BattleFlag_guansheng] = 0
    config.params[self.g_IDX_FuBenOpenTime]        = self:LuaFnGetCurrentTime()
    config.params[self.g_IDX_FuBenLifeStep]        = 0
    config.params[self.g_IDX_SJZTimerStep]         = 0
    config.params[self.g_IDX_SJZTimerScriptID]     = -1
    config.params[self.g_IDX_likuiDieStep]         = 0
    config.params[self.g_IDX_likuiDieScriptID]     = -1
    config.params[self.g_IDX_likuiDiePosX]         = 0
    config.params[self.g_IDX_likuiDiePosY]         = 0
    config.event_area                              = "shengsileitai_area.ini"
    config.monsterfile                             = "shengsileitai_monster.ini"
    config.sn                                      = self:LuaFnGenCopySceneSN()
    local bRetSceneID                              = self:LuaFnCreateCopyScene(config)
    self:BeginEvent(self.script_id)
    if bRetSceneID > 0 then
        self:AddText("Tạo phó bản thành công!")
    else
        self:AddText("Số lượng phó bản đã đạt đến giới hạn, xin hãy thử lại sau!")
    end
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function shengsileitai:OnCopySceneReady(destsceneId)
    local sceneId = self:get_scene_id()
    local sn = self:LuaFnGetCopySceneData_Sn(destsceneId)
    self:LuaFnSetCopySceneData_Param(destsceneId, 3, sceneId)
    local leaderguid = self:LuaFnGetCopySceneData_TeamLeader(destsceneId)
    local leaderObjId = self:LuaFnGuid2ObjId(leaderguid)
    if not self:LuaFnIsCanDoScriptLogic(leaderObjId) then
        return
    end
    local nearteammembercount = self:GetNearTeamCount(leaderObjId)
    local CurDayTime = self:GetDayTime()
    for i = 1, nearteammembercount do
        local PlayerId = self:GetNearTeamMember(leaderObjId, i)
        local lastTime = self:GetMissionData(PlayerId, define.MD_ENUM.MD_SHAXING_DAYTIME)
        local lastDayTime = math.floor(lastTime / 100)
        local lastDayCount = lastTime % 100
        if CurDayTime > lastDayTime then
            lastDayCount = 0
        end
        if lastDayCount >= self.g_MaxCount then
            self:BeginEvent(self.script_id)
            self:AddText("  Hôm nay bạn vượt giới hạn phụ bản, xin mai quay lại.")
            self:EndEvent()
            self:DispatchEventList(leaderObjId, define.INVAILD_ID)
            return
        end
    end
    if not self:LuaFnHasTeam(leaderObjId) then
        self:NewWorld(leaderObjId, destsceneId, sn, self.g_Fuben_X, self.g_Fuben_Z, self.g_client_res)
    else
        nearteammembercount = self:GetNearTeamCount(leaderObjId)
        local mems = {}
        for i = 1, nearteammembercount do
            mems[i] = self:GetNearTeamMember(leaderObjId, i)
            self:NewWorld(mems[i], destsceneId, sn, self.g_Fuben_X, self.g_Fuben_Z, self.g_client_res)
        end
    end
end

function shengsileitai:OnCopySceneTimer()
    self:TickFubenLife()
    self:TickSJZTimer()
    self:TicklikuiDieTimer()
end

function shengsileitai:OnPlayerEnter(selfId)
    self:SetPlayerDefaultReliveInfo(selfId, 0.1, 0.1, 0, self.g_Fuben_X, self.g_Fuben_Z)
    local lastTime = self:GetMissionData(selfId, define.MD_ENUM.MD_SHAXING_DAYTIME)
    local lastDayTime = math.floor(lastTime / 100)
    local lastDayCount = lastTime % 100
    local CurDayTime = self:GetDayTime()
    if CurDayTime > lastDayTime then
        lastDayTime = CurDayTime
        lastDayCount = 0
    end
    if lastDayCount >= self.g_MaxCount then
        self:notify_tips(selfId,"  Hôm nay bạn vượt giới hạn phụ bản, xin mai quay lại.")
        self:KickOut(selfId)
        return
    end
    self:LuaFnAddSweepPointByID(selfId, 8, 1)
    lastDayCount = lastDayCount + 1
    lastTime = lastDayTime * 100 + lastDayCount
    self:SetMissionData(selfId, define.MD_ENUM.MD_SHAXING_DAYTIME, lastTime)
    self:LuaFnAddMissionHuoYueZhi(selfId, 15)
end

function shengsileitai:OnHumanDie(selfId, killerId)
end

function shengsileitai:KickOut(objId)
    local oldsceneId = self:LuaFnGetCopySceneData_Param(3)
    local x = self:LuaFnGetCopySceneData_Param(4)
    local z = self:LuaFnGetCopySceneData_Param(5)
    if self:LuaFnIsObjValid(objId) then
        self:NewWorld(objId, oldsceneId, nil, x, z)
    end
end

function shengsileitai:TipAllHuman(Str)
    local nHumanNum = self:LuaFnGetCopyScene_HumanCount()
    for i = 1, nHumanNum do
        local PlayerId = self:LuaFnGetCopyScene_HumanObjId(i)
        if self:LuaFnIsObjValid(PlayerId) and self:LuaFnIsCanDoScriptLogic(PlayerId) then
            self:BeginEvent(self.script_id)
            self:AddText(Str)
            self:EndEvent()
            self:DispatchMissionTips(PlayerId)
        end
    end
end

function shengsileitai:TickFubenLife()
    local openTime = self:LuaFnGetCopySceneData_Param(self.g_IDX_FuBenOpenTime)
    local leftTime = openTime + self.g_FuBenTime - self:LuaFnGetCurrentTime()
    local lifeStep = self:LuaFnGetCopySceneData_Param(self.g_IDX_FuBenLifeStep)
    if lifeStep == 15 then
        self:LuaFnSetCopySceneData_Param(self.g_IDX_FuBenLifeStep, 16)
        local nHumanNum = self:LuaFnGetCopyScene_HumanCount()
        local oldSceneId = self:LuaFnGetCopySceneData_Param(3)
        local oldX = self:LuaFnGetCopySceneData_Param(4)
        local oldZ = self:LuaFnGetCopySceneData_Param(5)
        for i = 1, nHumanNum do
            local PlayerId = self:LuaFnGetCopyScene_HumanObjId(i)
            if self:LuaFnIsObjValid(PlayerId) and self:LuaFnIsCanDoScriptLogic(PlayerId) then
                self:NewWorld(PlayerId, oldSceneId, nil, oldX, oldZ)
            end
        end
        return
    end
    if lifeStep == 14 then
        self:LuaFnSetCopySceneData_Param(self.g_IDX_FuBenLifeStep, 15)
        self:TipAllHuman("Phó bản sẽ đóng sau 1 giây.")
        return
    end
    if lifeStep == 13 then
        self:LuaFnSetCopySceneData_Param(self.g_IDX_FuBenLifeStep, 14)
        self:TipAllHuman("Phó bản sẽ đóng sau 2 giây.")
        return
    end
    if lifeStep == 12 then
        self:LuaFnSetCopySceneData_Param(self.g_IDX_FuBenLifeStep, 13)
        self:TipAllHuman("Phó bản sẽ đóng sau 3 giây.")
        return
    end
    if lifeStep == 11 then
        self:LuaFnSetCopySceneData_Param(self.g_IDX_FuBenLifeStep, 12)
        self:TipAllHuman("Phó bản sẽ đóng sau 4 giây.")
        return
    end
    if lifeStep == 10 then
        self:LuaFnSetCopySceneData_Param(self.g_IDX_FuBenLifeStep, 11)
        self:TipAllHuman("Phó bản sẽ đóng sau 5 giây.")
        return
    end
    if leftTime <= 10 and lifeStep == 9 then
        self:LuaFnSetCopySceneData_Param(self.g_IDX_FuBenLifeStep, 10)
        self:TipAllHuman("Phó bản sẽ đóng sau 10 giây.")
        return
    end
    if leftTime <= 30 and lifeStep == 8 then
        self:LuaFnSetCopySceneData_Param(self.g_IDX_FuBenLifeStep, 9)
        self:TipAllHuman("Phó bản sẽ đóng sau 30 giây.")
        return
    end
    if leftTime <= 60 and lifeStep == 7 then
        self:LuaFnSetCopySceneData_Param(self.g_IDX_FuBenLifeStep, 8)
        self:TipAllHuman("Phó bản sẽ đóng sau 1 phút.")
        return
    end
    if leftTime <= 120 and lifeStep == 6 then
        self:LuaFnSetCopySceneData_Param(self.g_IDX_FuBenLifeStep, 7)
        self:TipAllHuman("Phó bản sẽ đóng sau 2 phút.")
        return
    end
    if leftTime <= 180 and lifeStep == 5 then
        self:LuaFnSetCopySceneData_Param(self.g_IDX_FuBenLifeStep, 6)
        self:TipAllHuman("Phó bản sẽ đóng sau 3 phút.")
        return
    end
    if leftTime <= 300 and lifeStep == 4 then
        self:LuaFnSetCopySceneData_Param(self.g_IDX_FuBenLifeStep, 5)
        self:TipAllHuman("Phó bản sẽ đóng sau 5 phút.")
        return
    end
    if leftTime <= 900 and lifeStep == 3 then
        self:LuaFnSetCopySceneData_Param(self.g_IDX_FuBenLifeStep, 4)
        self:TipAllHuman("Phó bản sẽ đóng sau 15 phút.")
        return
    end
    if leftTime <= 1800 and lifeStep == 2 then
        self:LuaFnSetCopySceneData_Param(self.g_IDX_FuBenLifeStep, 3)
        self:TipAllHuman("Phó bản sẽ đóng sau 30 phút.")
        return
    end
    if leftTime <= 3600 and lifeStep == 1 then
        self:LuaFnSetCopySceneData_Param(self.g_IDX_FuBenLifeStep, 2)
        self:TipAllHuman("Phó bản sẽ đóng sau 60 phút.")
        return
    end
    if lifeStep == 0 then
        local pool = {}
        for i, name in ipairs(self.g_StarNpcPool) do
            pool[i] = name
        end
        for i = 1, #self.g_StarNpcSlots do
            local selected = math.random(i, #pool)
            pool[i], pool[selected] = pool[selected], pool[i]
            local slot = self.g_StarNpcSlots[i]
            local MstId = self:CreateBOSS(pool[i], slot[1], slot[2])
            self:SetUnitReputationID(MstId, MstId, 0)
            self:SetUnitCampID(MstId, 8)
        end
        self:LuaFnSetCopySceneData_Param(self.g_IDX_FuBenLifeStep, 1)
        return
    end
end

function shengsileitai:TickSJZTimer()
    local step = self:LuaFnGetCopySceneData_Param(self.g_IDX_SJZTimerStep)
    if step <= 0 then
        return
    end
    local scriptID = self:LuaFnGetCopySceneData_Param(self.g_IDX_SJZTimerScriptID)
    self:CallScriptFunction(scriptID, "OnSJZTimer", step)
    step = step - 1
    if step <= 0 then
        self:LuaFnSetCopySceneData_Param(self.g_IDX_SJZTimerStep, 0)
        self:LuaFnSetCopySceneData_Param(self.g_IDX_SJZTimerScriptID, -1)
    else
        self:LuaFnSetCopySceneData_Param(self.g_IDX_SJZTimerStep, step)
    end
end

function shengsileitai:OpenSJZTimer(allstep, ScriptID)
    self:LuaFnSetCopySceneData_Param(self.g_IDX_SJZTimerStep, allstep)
    self:LuaFnSetCopySceneData_Param(self.g_IDX_SJZTimerScriptID, ScriptID)
end

function shengsileitai:IsSJZTimerRunning()
    local step = self:LuaFnGetCopySceneData_Param(self.g_IDX_SJZTimerStep)
    if step > 0 then
        return 1
    else
        return 0
    end
end

function shengsileitai:TicklikuiDieTimer()
    local step = self:LuaFnGetCopySceneData_Param(self.g_IDX_likuiDieStep)
    if step <= 0 then
        return
    end
    local scriptID = self:LuaFnGetCopySceneData_Param(self.g_IDX_likuiDieScriptID)
    local posX = self:LuaFnGetCopySceneData_Param(self.g_IDX_likuiDiePosX)
    local posY = self:LuaFnGetCopySceneData_Param(self.g_IDX_likuiDiePosY)
    self:CallScriptFunction(scriptID, "OnlujunyiDieTimer", step, posX, posY)
    step = step - 1
    if step <= 0 then
        self:LuaFnSetCopySceneData_Param(self.g_IDX_likuiDieStep, 0)
        self:LuaFnSetCopySceneData_Param(self.g_IDX_likuiDieScriptID, -1)
        self:LuaFnSetCopySceneData_Param(self.g_IDX_likuiDiePosX, 0)
        self:LuaFnSetCopySceneData_Param(self.g_IDX_likuiDiePosY, 0)
    else
        self:LuaFnSetCopySceneData_Param(self.g_IDX_likuiDieStep, step)
    end
end

function shengsileitai:OpenlikuiDieTimer(allstep, ScriptID, posX, posY)
    self:LuaFnSetCopySceneData_Param(self.g_IDX_likuiDieStep, allstep)
    self:LuaFnSetCopySceneData_Param(self.g_IDX_likuiDieScriptID, ScriptID)
    self:LuaFnSetCopySceneData_Param(self.g_IDX_likuiDiePosX, posX)
    self:LuaFnSetCopySceneData_Param(self.g_IDX_likuiDiePosY, posY)
end


function shengsileitai:CreateBOSS(name, x, y)
    local BOSSData = self.g_BOSSList[name]
    if not BOSSData then
        return
    end
    local posX
    local posY
    if x ~= -1 and y ~= -1 then
        posX = x
        posY = y
    else
        posX = BOSSData["posX"]
        posY = BOSSData["posY"]
    end
    local MstId =
        self:LuaFnCreateMonster(
            BOSSData["DataID"],
            posX,
            posY,
            BOSSData["BaseAI"],
            BOSSData["AIScript"],
            BOSSData["ScriptID"]
        )
    self:SetObjDir(MstId, BOSSData["Dir"])
    self:SetMonsterFightWithNpcFlag(MstId, 0)
    if string.sub(name, -4) == "_NPC" then
        self:SetUnitCampID(MstId, 8)
    end
    if BOSSData["Title"] ~= "" then
        self:SetCharacterTitle(MstId, BOSSData["Title"])
    end
    self:LuaFnSendSpecificImpactToUnit(MstId, MstId, MstId, 152, 0)
    self:AuditPMFCreateBoss(BOSSData["DataID"])
    return MstId
end

function shengsileitai:DeleteBOSS(name)
    local BOSSData = self.g_BOSSList[name]
    if not BOSSData then
        return
    end
    local nMonsterNum = self:GetMonsterCount()
    for i = 1, nMonsterNum do
        local MonsterId = self:GetMonsterObjID(i)
        if BOSSData["DataID"] == self:GetMonsterDataID(MonsterId) then
            self:LuaFnSendSpecificImpactToUnit(MonsterId, MonsterId, MonsterId, 152, 0)
            self:SetCharacterDieTime(MonsterId, 500)
        end
    end
end

function shengsileitai:FindBOSS(name)
    local BOSSData = self.g_BOSSList[name]
    if not BOSSData then
        return -1
    end
    local nMonsterNum = self:GetMonsterCount()
    for i = 1, nMonsterNum do
        local MonsterId = self:GetMonsterObjID(i)
        if BOSSData["DataID"] == self:GetMonsterDataID(MonsterId) then
            return MonsterId
        end
    end
    return -1
end

function shengsileitai:CheckHaveBOSS()
    local BossList = {}
    local nBossNum = 0
    local nMonsterNum = self:GetMonsterCount()
    for i = 1, nMonsterNum do
        local MonsterId = self:GetMonsterObjID(i)
        if self:LuaFnIsCharacterLiving(MonsterId) then
            local DataID = self:GetMonsterDataID(MonsterId)
            for j, dataId in pairs(self.g_FightBOSSList) do
                if DataID == dataId then
                    BossList[nBossNum] = self:GetName(MonsterId)
                    nBossNum = nBossNum + 1
                end
            end
        end
    end
    if nBossNum > 0 then
        local msg = "Đang cùng"
        for i = 0, nBossNum - 2 do
            msg = msg .. BossList[i] .. "，"
        end
        msg = msg .. BossList[nBossNum - 1] .. "Trong Chiến đấu"
        return 1, msg
    end
    return 0
end

function shengsileitai:GetBossBattleFlag(bossName)
    local idx = self.g_BattleFlagTbl[bossName]
    return self:LuaFnGetCopySceneData_Param(idx)
end

function shengsileitai:SetBossBattleFlag(bossName, bCan)
    local idx = self.g_BattleFlagTbl[bossName]
    self:LuaFnSetCopySceneData_Param(idx, bCan)
end

function shengsileitai:CalSweepData(selfId)
    local lastTime = self:GetMissionData(selfId, define.MD_ENUM.MD_SHAXING_DAYTIME)
    local lastDayTime = math.floor(lastTime / 100)
    local lastDayCount = lastTime % 100
    local CurDayTime = self:GetDayTime()
    if CurDayTime > lastDayTime then
        lastDayTime = CurDayTime
        lastDayCount = 0
    end
    lastDayCount = lastDayCount + 1
    lastTime = lastDayTime * 100 + lastDayCount
    self:SetMissionData(selfId, define.MD_ENUM.MD_SHAXING_DAYTIME, lastTime)
end
return shengsileitai
