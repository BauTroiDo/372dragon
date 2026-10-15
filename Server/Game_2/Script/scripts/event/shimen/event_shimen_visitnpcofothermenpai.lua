local class = require "class"
local define = require "define"
local script_base = require "script_base"
local event_shimen_visitnpcofothermenpai = class("event_shimen_visitnpcofothermenpai", script_base)
local ScriptGlobal = require "scripts.ScriptGlobal"
event_shimen_visitnpcofothermenpai.script_id = 229010
event_shimen_visitnpcofothermenpai.g_MissionId = 1060
event_shimen_visitnpcofothermenpai.g_MissionKind = 2
event_shimen_visitnpcofothermenpai.g_MissionLevel = 10000
event_shimen_visitnpcofothermenpai.g_IfMissionElite = 0
event_shimen_visitnpcofothermenpai.g_IsMissionOkFail = 0
event_shimen_visitnpcofothermenpai.g_MissionName = "Sư môn nhiệm vụ"
event_shimen_visitnpcofothermenpai.g_MissionInfo = ""
event_shimen_visitnpcofothermenpai.g_MissionTarget =
"Không tệ... ... Ngươi luôn vì sự phát dương quang đại của bản môn mà tận tâm tận lực làm việc, ta lại thưởng thêm cho ngươi một nhiệm vụ nữa. #G%s#W vừa gửi thư bồ câu đến cho ta, nói bọn họ Yêu cầu giúp đỡ, ngươi đi tìm #G%s#W ở #Y%s#W, hắn (cô ta) sẽ an bài nhiệm vụ cho ngươi.#r#{SMRW_090206_01}"
event_shimen_visitnpcofothermenpai.g_ContinueInfo = "Làm tốt lắm!"
event_shimen_visitnpcofothermenpai.g_MissionComplete = "Chuyện ta giao cho ngươi đã làm xong chưa?"
event_shimen_visitnpcofothermenpai.g_MissionRound = 17
event_shimen_visitnpcofothermenpai.g_DoubleExp = 48
event_shimen_visitnpcofothermenpai.g_AccomplishCircumstance = 1
event_shimen_visitnpcofothermenpai.g_StrForePart = 4
event_shimen_visitnpcofothermenpai.g_StrList2 = { "玄澄", "Tháp Lâm Phó bản", "本相", "孟青青", "佛印", "方腊",
    "菊剑", "林灵素", "冯阿三", "红玉", "Tháp Đáy Phó bản", "Đào Hoa Trận Phó bản", "Hầm Rượu Phó bản", "Quang Minh động Phó bản",
    "Chiết Mai Phong Phó bản", "Linh Tính Phong Phó", "Đáy Cốc Phó bản", "Ngũ Thần Động Phó bản", "少林", "天龙", "Nga Mi", "丐帮", "明教",
    "天山", "武当", "逍遥", "星宿","王叠涓","Hạo Nguyệt Châu Phó bản","Hạo Nguyệt Châu" }
event_shimen_visitnpcofothermenpai.g_SubMissionTypeEnum = {
    ["XunWu"] = 1,
    ["SongXin"] = 2,
    ["DingDianYinDao"] = 3,
    ["FuBenZhanDou"] = 4,
    ["BuZhuo"] = 5,
    ["ShouJi"] = 6,
    ["KaiGuang"] = 7,
    ["otherMenpaiFuben"] = 8
}
event_shimen_visitnpcofothermenpai.g_FuBen_List = {
    {
        ["menpainame"] = "少林",
        ["menpai"] = define.MENPAI_ATTRIBUTE.MATTRIBUTE_SHAOLIN,
        ["NpcName"] = "玄澄",
        ["scene"] = 9,
        ["posx"] = 61,
        ["posz"] = 61,
        ["FubenName"] = "Tháp Lâm Phó bản"
    }
    ,
    {
        ["menpainame"] = "天龙",
        ["menpai"] = define.MENPAI_ATTRIBUTE.MATTRIBUTE_DALI,
        ["NpcName"] = "本相",
        ["scene"] = 13,
        ["posx"] = 35,
        ["posz"] = 86,
        ["FubenName"] = "Tháp Đáy Phó bản"
    }
    ,
    {
        ["menpainame"] = "Nga Mi",
        ["menpai"] = define.MENPAI_ATTRIBUTE.MATTRIBUTE_EMEI,
        ["NpcName"] = "孟青青",
        ["scene"] = 15,
        ["posx"] = 96,
        ["posz"] = 73,
        ["FubenName"] = "Đào Hoa Trận Phó bản"
    }
    ,
    {
        ["menpainame"] = "丐帮",
        ["menpai"] = define.MENPAI_ATTRIBUTE.MATTRIBUTE_GAIBANG,
        ["NpcName"] = "佛印",
        ["scene"] = 10,
        ["posx"] = 41,
        ["posz"] = 144,
        ["FubenName"] = "Hầm Rượu Phó bản"
    }
    ,
    {
        ["menpainame"] = "明教",
        ["menpai"] = define.MENPAI_ATTRIBUTE.MATTRIBUTE_MINGJIAO,
        ["NpcName"] = "方腊",
        ["scene"] = 11,
        ["posx"] = 89,
        ["posz"] = 56,
        ["FubenName"] = "Quang Minh động Phó bản"
    }
    ,
    {
        ["menpainame"] = "天山",
        ["menpai"] = define.MENPAI_ATTRIBUTE.MATTRIBUTE_TIANSHAN,
        ["NpcName"] = "菊剑",
        ["scene"] = 17,
        ["posx"] = 99,
        ["posz"] = 45,
        ["FubenName"] = "Chiết Mai Phong Phó bản"
    }
    ,
    {
        ["menpainame"] = "武当",
        ["menpai"] = define.MENPAI_ATTRIBUTE.MATTRIBUTE_WUDANG,
        ["NpcName"] = "林灵素",
        ["scene"] = 12,
        ["posx"] = 58,
        ["posz"] = 73,
        ["FubenName"] = "Linh Tính Phong Phó bản"
    }
    ,
    {
        ["menpainame"] = "逍遥",
        ["menpai"] = define.MENPAI_ATTRIBUTE.MATTRIBUTE_XIAOYAO,
        ["NpcName"] = "冯阿三",
        ["scene"] = 14,
        ["posx"] = 62,
        ["posz"] = 68,
        ["FubenName"] = "Đáy Cốc Phó bản"
    }
    ,
    {
        ["menpainame"] = "星宿",
        ["menpai"] = define.MENPAI_ATTRIBUTE.MATTRIBUTE_XINGXIU,
        ["NpcName"] = "红玉",
        ["scene"] = 16,
        ["posx"] = 128,
        ["posz"] = 78,
        ["FubenName"] = "Ngũ Thần Động Phó bản"
    }
    ,
    {
        ["menpainame"] = "曼陀山庄",
        ["menpai"] = ScriptGlobal.MP_MANTUO,
        ["NpcName"] = "王叠涓",
        ["scene"] = 184,
        ["posx"] = 30,
        ["posz"] = 197,
        ["FubenName"] = "Hạo Nguyệt Châu Phó bản"
    }
}
function event_shimen_visitnpcofothermenpai:GetStrIndexByStrValue(stringV)
    for i, v in pairs(self.g_StrList2) do
        if v == stringV then
            return i - 1
        end
    end
    local strText = string.format("Phải đăng ký %s vào StrList", stringV)
    return 0
end

function event_shimen_visitnpcofothermenpai:GetStrValueByStrIndex(index)
    if index + 1 >= 1 and index + 1 <= #(self.g_StrList2) then
        return self.g_StrList2[index + 1]
    end
    return ""
end

function event_shimen_visitnpcofothermenpai:AddOtherMenpaiFubenMission(selfId, missionId, targetId)
    local index = 1
    local a = {}
    for i, v in pairs(self.g_FuBen_List) do
        if v["menpai"] ~= self:GetMenPai(selfId) then
            a[index] = i
            index    = index + 1
        end
    end
    index = a[math.random(#(a))]
    local menpaiName = self.g_FuBen_List[index]["menpainame"]
    local npcName = self.g_FuBen_List[index]["NpcName"]
    local fubenName = self.g_FuBen_List[index]["FubenName"]
    local nSceneId = self.g_FuBen_List[index]["scene"]
    local posx = self.g_FuBen_List[index]["posx"]
    local posz = self.g_FuBen_List[index]["posz"]
    self:CallScriptFunction(500501, "CheckAccept_Necessary", selfId)
    local bAdd = self:AddMission(selfId, missionId, self.script_id, 0, 0, 0)
    if not bAdd then
        return
    end
    local nFormatIndex = self:GetMissionCacheData(selfId, 0)
    local NpcNameIndex = self:GetStrIndexByStrValue(npcName)
    local MenpaiNameIndex = self:GetStrIndexByStrValue(menpaiName)
    local misIndex = self:GetMissionIndexByID(selfId, missionId)
    self:SetMissionByIndex(selfId, misIndex, 0, 0)
    self:SetMissionByIndex(selfId, misIndex, 1, self.g_SubMissionTypeEnum["otherMenpaiFuben"])
    self:SetMissionByIndex(selfId, misIndex, self.g_StrForePart, MenpaiNameIndex)
    self:SetMissionByIndex(selfId, misIndex, self.g_StrForePart + 1, MenpaiNameIndex)
    self:SetMissionByIndex(selfId, misIndex, self.g_StrForePart + 2, NpcNameIndex)
    self:Msg2Player(selfId, "#YTiếp nhận nhiệm vụ: Sư môn nhiệm vụ", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    self:CallScriptFunction(888888, "AskTheWay", selfId, nSceneId, posx, posz, npcName)
    local strMissionTarget = string.format(
        "Tốt lắm... ... Con luôn tận tâm tận lực vì sự phát dương quang đại của bản môn, ta sẽ thưởng thêm cho con một nhiệm vụ nữa. %s vừa gửi thư bồ câu cho ta, nói rằng họ Yêu cầu giúp đỡ, con hãy đi tìm %s của %s, người đó sẽ an bài nhiệm vụ cho con.",
        menpaiName, menpaiName, npcName)
    self:BeginEvent(self.script_id)
    self:AddText(strMissionTarget)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
    local round = self:GetMissionData(selfId, ScriptGlobal.MD_SHIMEN_HUAN)
    round = round + 1
    if round >= 21 then
        self:SetMissionData(selfId, ScriptGlobal.MD_SHIMEN_HUAN, 1)
    else
        self:SetMissionData(selfId, ScriptGlobal.MD_SHIMEN_HUAN, round)
    end
end

function event_shimen_visitnpcofothermenpai:OnEnumerate(caller, selfId, targetId, arg, index)
    return
end

function event_shimen_visitnpcofothermenpai:OnAbandon(selfId)
    local shimenMissionIdList = { 1080, 1090, 1065, 1070, 1060, 1100, 1075, 1085, 1095,2126 }
    for i, v in pairs(shimenMissionIdList) do
        if self:IsHaveMission(selfId, v) then
            self:DelMission(selfId, v)
            self:SetMissionData(selfId, ScriptGlobal.MD_SHIMEN_HUAN, 0)
            self:CallScriptFunction(500501, "Abandon_Necessary", selfId)
            break
        end
    end
end

return event_shimen_visitnpcofothermenpai
