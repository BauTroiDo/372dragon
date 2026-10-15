local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ScriptGlobal = require "scripts.ScriptGlobal"
local eThousandsOfWishes = class("eThousandsOfWishes", script_base)
eThousandsOfWishes.script_id = 808131
eThousandsOfWishes.g_Position_X = 186
eThousandsOfWishes.g_Position_Z = 182
eThousandsOfWishes.g_SceneID = 1
eThousandsOfWishes.g_AccomplishNPC_Name = "梁道士"
eThousandsOfWishes.g_MissionId = 1161
eThousandsOfWishes.g_Name = "梁道士"
eThousandsOfWishes.g_ItemId = 30505255
eThousandsOfWishes.g_MissionKind = 12
eThousandsOfWishes.g_MissionLevel = 10000
eThousandsOfWishes.g_IfMissionElite = 0
eThousandsOfWishes.g_IsMissionOkFail = 0
eThousandsOfWishes.g_MissionName = "#{SQXY_09061_4}"
eThousandsOfWishes.g_MissionInfo = "#{SQXY_09061_39}"
eThousandsOfWishes.g_MissionTarget = "#{SQXY_09061_11}"
eThousandsOfWishes.g_ContinueInfo = "#{SQXY_09061_19}"
eThousandsOfWishes.g_MissionComplete = "#{SQXY_09061_36}"
eThousandsOfWishes.g_ItemBonus = { { ["id"] = 20502010, ["num"] = 1 }}
eThousandsOfWishes.g_SignPost = { ["x"] = 157, ["z"] = 188, ["tip"] = "许愿点" }
eThousandsOfWishes.g_SignPost_1 = { ["x"] = 186, ["z"] = 182, ["tip"] = "梁道士" }
eThousandsOfWishes.g_Custom = { { ["id"] = "向许愿树许愿", ["num"] = 1 }}
eThousandsOfWishes.g_TreasureAddress = { { ["scene"] = 4, ["x"] = 157, ["z"] = 185 }}
eThousandsOfWishes.g_Exp = {
	[10] = 1516, [11] = 1596, [12] = 1672, [13] = 1749, [14] = 1829, [15] = 1906, [16] = 1983,
    [17] = 2063, [18] = 2140, [19] = 2220, [20] = 3002, [21] = 3124, [22] = 3250, [23] = 3376, [24] = 3502, [25] = 3625,
    [26] = 3751, [27] = 3877, [28] = 4003, [29] = 4125, [30] = 5137, [31] = 5289, [32] = 5441, [33] = 5589, [34] = 5742,
    [35] = 5894, [36] = 6046, [37] = 6194, [38] = 6346, [39] = 6498, [40] = 9700, [41] = 9922, [42] = 10139,
    [43] = 10361, [44] = 10583, [45] = 10801, [46] = 11022, [47] = 11244, [48] = 11462, [49] = 11684, [50] = 11905,
    [51] = 12123, [52] = 12345, [53] = 12567, [54] = 12789, [55] = 13006, [56] = 13228, [57] = 13450, [58] = 13667,
    [59] = 13889, [60] = 14111, [61] = 14328, [62] = 14550, [63] = 14772, [64] = 14990, [65] = 15211, [66] = 15433,
    [67] = 15651, [68] = 15873, [69] = 16095, [70] = 16316, [71] = 16534, [72] = 16756, [73] = 16978, [74] = 17195,
    [75] = 17417, [76] = 17639, [77] = 17856, [78] = 18078, [79] = 18300, [80] = 18517, [81] = 18739, [82] = 18961,
    [83] = 19183, [84] = 19401, [85] = 19622, [86] = 19844, [87] = 20062, [88] = 20284, [89] = 20505, [90] = 20723,
    [91] = 20945, [92] = 21167, [93] = 21384, [94] = 21606, [95] = 21828, [96] = 22045, [97] = 22267, [98] = 22489,
    [99] = 22711, [100] = 22928, [101] = 23146, [102] = 23368, [103] = 23590, [104] = 23807, [105] = 24029,
    [106] = 24251, [107] = 24468, [108] = 24690, [109] = 24912, [110] = 25129, [111] = 25351, [112] = 25573,
    [113] = 25791, [114] = 26013, [115] = 26234, [116] = 26452, [117] = 26674, [118] = 26896, [119] = 27113,
    [120] = 27335, [121] = 27557, [122] = 27774, [123] = 27996, [124] = 28218, [125] = 28435, [126] = 28657,
    [127] = 28879, [128] = 29101, [129] = 29319, [130] = 29540, [131] = 29762, [132] = 29980, [133] = 30202,
    [134] = 30423, [135] = 30641, [136] = 30863, [137] = 31085, [138] = 31302, [139] = 31524, [140] = 31746,
    [141] = 31963, [142] = 32185, [143] = 32407, [144] = 32625, [145] = 32846, [146] = 33068, [147] = 33286,
    [148] = 33508, [149] = 33729, [150] = 33947 
	}
function eThousandsOfWishes:OnDefaultEvent(selfId, targetId,arg,index)
    if self:GetLevel(selfId) < 30 then
        self:BeginEvent(self.script_id)
        self:AddText(" #{SQXY_09061_8}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if self:IsHaveMission(selfId, self.g_MissionId) then
        self:BeginEvent(self.script_id)
        self:AddText(self.g_ContinueInfo)
        self:EndEvent()
        local bDone = self:CheckSubmit(selfId)
        self:DispatchMissionDemandInfo(selfId, targetId, self.script_id, self.g_MissionId, bDone)
    elseif self:CheckAccept(selfId) > 0 then
        self:BeginEvent(self.script_id)
        self:AddText(self.g_MissionInfo)
        self:EndEvent()
        self:DispatchMissionInfo(selfId, targetId, self.script_id, self.g_MissionId)
    end
end
function eThousandsOfWishes:OnEnumerate(caller, selfId, targetId, arg, index)
    if self:IsHaveMission(selfId, self.g_MissionId) then
        caller:AddNumTextWithTarget(self.script_id,self.g_MissionName, 4, -1)
    else
        caller:AddNumTextWithTarget(self.script_id,self.g_MissionName, 3, -1)
    end
end
function eThousandsOfWishes:CheckAccept(selfId)
    if not self:IsHaveMission(selfId, self.g_MissionId) then
        return 1
    else
        return 0
    end
end
function eThousandsOfWishes:OnAccept(selfId,targetId)
    local nDayCount = self:GetMissionDataEx(selfId,116)
    local sceneId = self:GetSceneID()
    if self:CheckAccept(selfId) <= 0 then
        return
    end
    if nDayCount >= self:GetDayTime() then
        self:MsgBox(selfId,targetId,"#{SQXY_09061_7}")
        return
    end
    SceneNum = self.g_TreasureAddress[1]["scene"]
    X = self.g_TreasureAddress[1]["x"]
    Z = self.g_TreasureAddress[1]["z"]
    local ret1 = self:AddMission(selfId, self.g_MissionId, self.script_id, 0, 0, 1)
    if ret1 then
        local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
        self:SetMissionByIndex(selfId, misIndex, 0, 0)
        self:SetMissionByIndex(selfId, misIndex, 2, SceneNum)
        self:SetMissionByIndex(selfId, misIndex, 3, X)
        self:SetMissionByIndex(selfId, misIndex, 4, Z)
        self:notify_tips(selfId, "#YNhận nhiệm vụ: Một nghìn lẻ một điều ước")
        self:SetMissionDataEx(selfId,117,self:GetDayTime())
        self:Msg2Player(selfId, "@*;flagPOS;" ..sceneId .. ";" .. X .. ";" .. Z .. ";" .. "Điểm Ước Nguyện",define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        self:Msg2Player(selfId, "@*;flashPOS;" ..sceneId .. ";" .. X .. ";" .. Z .. ";" .. "Điểm Ước Nguyện",define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        self:BeginEvent(self.script_id)
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        self:CallScriptFunction(define.SCENE_SCRIPT_ID, "AskTheWay", selfId, self.g_SignPost_1["x"], self.g_SignPost_1["z"],self.g_SignPost_1["tip"])
    else
        self:notify_tips(selfId, "Nhật ký nhiệm vụ của ngươi đầy rồi.")
    end
end
function eThousandsOfWishes:OnAbandon(selfId)
    local res = self:DelMission(selfId, self.g_MissionId)
    local sceneId = self:GetSceneID()
    if res then
        self:Msg2Player(selfId, "@*;flagNPCdel;" ..sceneId.. ";" .. "Điểm Ước Nguyện", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        self:Msg2Player(selfId, "@*;flashNPCdel;" ..sceneId.. ";" .. "Điểm Ước Nguyện", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    end
end
function eThousandsOfWishes:OnContinue(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(self.g_MissionName)
    self:AddText(self.g_MissionComplete)
    for i, item in pairs(self.g_ItemBonus) do
        self:AddItemBonus(item["id"], item["num"])
    end
    self:EndEvent()
    self:DispatchMissionContinueInfo(selfId, targetId, self.script_id, self.g_MissionId)
end
function eThousandsOfWishes:CheckSubmit(selfId)
    local WishesCount = self:GetMissionDataEx(selfId,148)
    if WishesCount >= 5 then
        return 1
    end
    return 0
end
function eThousandsOfWishes:OnSubmit(selfId, targetId, selectRadioId)
    if self:CheckSubmit(selfId) == 1 then
        self:BeginAddItem()
        for i, item in pairs(self.g_ItemBonus) do
            self:AddItem(item["id"], item["num"])
        end
        local ret = self:EndAddItem(selfId)
        if ret then
            local nLevel = self:GetLevel(selfId)
            local nExp = self.g_Exp[nLevel]
            self:AddExp(selfId, nExp * 50)
            ret = self:DelMission(selfId, self.g_MissionId)
            if ret then
                self:MissionCom(selfId, self.g_MissionId)
                self:AddItemListToHuman(selfId)
                self:notify_tips(selfId, "Hoàn thành nhiệm vụ: Một Ngàn Lẻ Một Ước Nguyện")
                self:SetMissionDataEx(selfId,116,self:GetMissionDataEx(selfId,117))
                self:SetMissionDataEx(selfId,148,0)--交完任务清空本次任务许愿次数
                self:LuaFnAddMissionHuoYueZhi(selfId, 2)
                self:BeginEvent(self.script_id)
                self:AddText("Nhận quả ước nguyện")
                self:EndEvent()
                self:DispatchMissionTips(selfId)
            end
        else
            self:BeginEvent(self.script_id)
            local strText = "Túi hành trang không đủ chỗ"
            self:AddText(strText)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
        end
    end
end
--**********************************
--道具使用
--**********************************
function eThousandsOfWishes:OnUseItem(selfId)
    --如果任务已经完成
    local WishesCount = self:GetMissionDataEx(selfId,148)
    local sceneId = self:GetSceneID()
    local misIndex = self:GetMissionIndexByID(selfId,self.g_MissionId)
    local MissionCondition = self:GetMissionParam(selfId,misIndex,0) --获得任务状态
    local scene = self:GetMissionParam(selfId,misIndex,2)					--获得宝物场景号
    local treasureX = self:GetMissionParam(selfId,misIndex,3)				--获得宝物X坐标
    local treasureZ = self:GetMissionParam(selfId,misIndex,4)				--获得宝物Z坐标	
    if MissionCondition > 0 then
        self:notify_tips(selfId,"Ước xong rồi, đừng phí thời gian nữa, mau đi trả nhiệm vụ!")
        return
    end
    --取得玩家当前坐标
    local PlayerX = self:GetHumanWorldX(selfId)
    local PlayerZ = self:GetHumanWorldZ(selfId)
        --计算玩家与宝藏的距离
    local Distance = math.floor(math.sqrt((treasureX-PlayerX)*(treasureX-PlayerX)+(treasureZ-PlayerZ)*(treasureZ-PlayerZ)))

    if self:CheckAccept(selfId) > 0 then
        self:notify_tips(selfId,"Ước thất bại, xin nhận nhiệm vụ Một nghìn lẻ một điều ước trước.")
        return
    end
    if Distance > 5 then
        self:notify_tips(selfId,"Xin dùng [Nguyện Linh Tuyền] gần cây ước Thái Hồ (157,188), tọa độ hiện cách cây còn"..Distance.."gạo")
    elseif Distance <= 5 then
        if WishesCount < 5 then
            self:DelItem(selfId, self.g_ItemId)
            self:SetMissionDataEx(selfId,148,WishesCount + 1)
            self:SetMissionByIndex(selfId,misIndex,1,self:GetMissionParam(selfId,misIndex,1) + 1) --写入许愿次数
            if self:GetMissionDataEx(selfId,148) == 5 then
                self:notify_tips(selfId,"Ngươi đã ước đủ 5 lần, mau về tìm Lương đạo sĩ trả nhiệm vụ nhận thưởng.")
                self:SetMissionByIndex(selfId,misIndex,0,1)
                self:SetMissionByIndex(selfId,misIndex,1,5) --写入许愿次数
                return
            end
            if self:GetMissionDataEx(selfId,148) < 5 then
                self:notify_tips(selfId,"Ngươi đã hoàn thành thứ"..self:GetMissionDataEx(selfId,148).."lần ước.")
            end
        end
    end
end

function eThousandsOfWishes:OnKillObject(selfId, objdataId)
end
function eThousandsOfWishes:OnEnterArea(selfId, zoneId)
end
function eThousandsOfWishes:OnItemChanged(selfId, itemdataId)
end
function eThousandsOfWishes:MsgBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return eThousandsOfWishes
