local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local ejingji_1 = class("ejingji_1", script_base)
ejingji_1.script_id = 125020
ejingji_1.g_Position = {
    {["id"] = 1, ["scene"] = 0, ["x"] = 143, ["z"] = 151},
    {["id"] = 2, ["scene"] = 1, ["x"] = 28, ["z"] = 152},
    {["id"] = 3, ["scene"] = 2, ["x"] = 149, ["z"] = 80},
    {["id"] = 4, ["scene"] = 3, ["x"] = 36, ["z"] = 49},
    {["id"] = 5, ["scene"] = 420, ["x"] = 33, ["z"] = 49},
    {["id"] = 6, ["scene"] = 1300, ["x"] = 143, ["z"] = 151},
    {["id"] = 7, ["scene"] = 1301, ["x"] = 143, ["z"] = 151},
    {["id"] = 8, ["scene"] = 1302, ["x"] = 149, ["z"] = 80},
}

ejingji_1.g_BuffPosition = {
    {["id"] = 1, ["x"] = 81, ["z"] = 53, ["preTime"] = 0},
    {["id"] = 2, ["x"] = 81, ["z"] = 146, ["preTime"] = 0},
    {["id"] = 3, ["x"] = 33, ["z"] = 99, ["preTime"] = 0},
    {["id"] = 4, ["x"] = 130, ["z"] = 99, ["preTime"] = 0},
    {["id"] = 5, ["x"] = 107, ["z"] = 74, ["preTime"] = 0},
    {["id"] = 6, ["x"] = 106, ["z"] = 124, ["preTime"] = 0},
    {["id"] = 7, ["x"] = 56, ["z"] = 124, ["preTime"] = 0},
    {["id"] = 8, ["x"] = 56, ["z"] = 73, ["preTime"] = 0}
}

ejingji_1.g_SmallBoxName = {
    "紫色秘笈", "黄色秘笈", "绿色秘笈", "白色秘笈",
    "黑色秘笈", "蓝色秘笈", "红色秘笈"
}

ejingji_1.g_SmallBoxList = {
    {["id"] = 1, ["monId"] = 5004, ["script"] = 125023},
    {["id"] = 2, ["monId"] = 5005, ["script"] = 125023},
    {["id"] = 3, ["monId"] = 5006, ["script"] = 125023},
    {["id"] = 4, ["monId"] = 5007, ["script"] = 125023},
    {["id"] = 5, ["monId"] = 5008, ["script"] = 125023},
    {["id"] = 6, ["monId"] = 5009, ["script"] = 125023},
    {["id"] = 7, ["monId"] = 5010, ["script"] = 125023}
}

ejingji_1.g_StonePosition_1 = {
    {["tp"] = 1, ["x"] = 45, ["z"] = 65}, {["tp"] = 1, ["x"] = 42, ["z"] = 67},
    {["tp"] = 1, ["x"] = 47, ["z"] = 63}, {["tp"] = 1, ["x"] = 52, ["z"] = 87},
    {["tp"] = 1, ["x"] = 63, ["z"] = 84}, {["tp"] = 1, ["x"] = 71, ["z"] = 78},
    {["tp"] = 1, ["x"] = 68, ["z"] = 69}, {["tp"] = 1, ["x"] = 62, ["z"] = 64},
    {["tp"] = 1, ["x"] = 51, ["z"] = 66}, {["tp"] = 1, ["x"] = 71, ["z"] = 74}
}

ejingji_1.g_StonePosition_2 = {
    {["tp"] = 2, ["x"] = 92, ["z"] = 65}, {["tp"] = 2, ["x"] = 96, ["z"] = 70},
    {["tp"] = 2, ["x"] = 94, ["z"] = 76}, {["tp"] = 2, ["x"] = 95, ["z"] = 80},
    {["tp"] = 2, ["x"] = 104, ["z"] = 64},
    {["tp"] = 2, ["x"] = 102, ["z"] = 84},
    {["tp"] = 2, ["x"] = 108, ["z"] = 85},
    {["tp"] = 2, ["x"] = 114, ["z"] = 81},
    {["tp"] = 2, ["x"] = 102, ["z"] = 74}, {["tp"] = 2, ["x"] = 119, ["z"] = 67}
}

ejingji_1.g_StonePosition_3 = {
    {["tp"] = 3, ["x"] = 44, ["z"] = 106},
    {["tp"] = 3, ["x"] = 45, ["z"] = 111},
    {["tp"] = 3, ["x"] = 43, ["z"] = 123},
    {["tp"] = 3, ["x"] = 46, ["z"] = 131},
    {["tp"] = 3, ["x"] = 44, ["z"] = 136},
    {["tp"] = 3, ["x"] = 56, ["z"] = 133},
    {["tp"] = 3, ["x"] = 61, ["z"] = 136},
    {["tp"] = 3, ["x"] = 70, ["z"] = 136},
    {["tp"] = 3, ["x"] = 67, ["z"] = 127}, {["tp"] = 3, ["x"] = 61, ["z"] = 115}

}

ejingji_1.g_StonePosition_4 = {
    {["tp"] = 4, ["x"] = 87, ["z"] = 114},
    {["tp"] = 4, ["x"] = 92, ["z"] = 115},
    {["tp"] = 4, ["x"] = 93, ["z"] = 131},
    {["tp"] = 4, ["x"] = 98, ["z"] = 136},
    {["tp"] = 4, ["x"] = 105, ["z"] = 134},
    {["tp"] = 4, ["x"] = 114, ["z"] = 136},
    {["tp"] = 4, ["x"] = 116, ["z"] = 128},
    {["tp"] = 4, ["x"] = 120, ["z"] = 116},
    {["tp"] = 4, ["x"] = 111, ["z"] = 113},
    {["tp"] = 4, ["x"] = 120, ["z"] = 136}

}

ejingji_1.g_StonePosition_5 = {
    {["tp"] = 5, ["x"] = 147, ["z"] = 135},
    {["tp"] = 5, ["x"] = 152, ["z"] = 124},
    {["tp"] = 5, ["x"] = 151, ["z"] = 110},
    {["tp"] = 5, ["x"] = 146, ["z"] = 100},
    {["tp"] = 5, ["x"] = 151, ["z"] = 88},
    {["tp"] = 5, ["x"] = 133, ["z"] = 67},
    {["tp"] = 5, ["x"] = 128, ["z"] = 54},
    {["tp"] = 5, ["x"] = 110, ["z"] = 47}, {["tp"] = 5, ["x"] = 78, ["z"] = 39},
    {["tp"] = 5, ["x"] = 59, ["z"] = 45}

}
ejingji_1.g_PreCreateBoxTime = -10
ejingji_1.g_IsPreBroad = 0
ejingji_1.g_Step = 0
ejingji_1.g_PreBroadTime = 0
ejingji_1.g_BigBoxPosition = {["x"] = 81, ["z"] = 99}
ejingji_1.g_OutPosition = {["scene"] = 0, ["x"] = 160, ["z"] = 106}
ejingji_1.g_CampList = {}
ejingji_1.g_SameCampMax = 10
ejingji_1.g_GotoProtect = 54
ejingji_1.g_PreCreateSmallBoxTime = 0
ejingji_1.g_BigBoxInfo = {
    ["id"] = 5003,
    ["x"] = 82,
    ["z"] = 100,
    ["ai"] = 3,
    ["aif"] = 0,
    ["script"] = 125022
}

ejingji_1.g_StoneBoxInfo = {
    ["id"] = 5002,
    ["ai"] = 3,
    ["aif"] = 0,
    ["script"] = 125024
}
ejingji_1.g_Yinpiao = 40002000
ejingji_1.g_CaoyunMisId = 4021
ejingji_1.g_PreCreateStoneBox = 0
function ejingji_1:OnInitScene(selfId)
    for i = 1, 500 do self.g_CampList[i] = 0 end
end

function ejingji_1:OnEnumerate(caller, selfId, targetId, arg, index)
    caller:AddNumTextWithTarget(self.script_id, "Tiến vào đấu trường", 9, 1)
    caller:AddNumTextWithTarget(self.script_id, "Thế nào là đấu trường Phong Thiền Đài?", 11, 2)
end

function ejingji_1:OnDefaultEvent(selfId, targetId, arg, index)
    if index == 2 then
        self:BeginEvent(self.script_id)
        self:AddText("#BThế nào là Phong Thiền Đài Tranh Bá")
        self:AddText("#{JINGJI_INFO}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return 0
    end
    if self:LuaFnGetDRideFlag(selfId) then
        self:BeginEvent(self.script_id)
        self:AddText("#BĐấu Trường")
        self:AddText("  Trong Trạng thái cưỡi đôi, không thể tiến vào Đấu Trường.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return 0
    end
    if self:GetLevel(selfId) < 35 then
        self:BeginEvent(self.script_id)
        self:AddText("#BĐấu Trường")
        self:AddText("  Muốn vào Đấu Trường phải đạt trên cấp 35 mới có thể tham gia, tu vi của các hạ còn chưa đủ, đợi đến khi đạt cấp 35 rồi hãy đến tìm ta.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return 0
    end

    if not self:LuaFnHasTeam(selfId) then
        self:BeginEvent(self.script_id)
        self:AddText("#BĐấu Trường")
        self:AddText("  Muốn vào đấu trường thì nhất định phải ở trong một đội.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return 0
    end

    if self:GetItemCount(selfId, self.g_Yinpiao) >= 1 then
        self:BeginEvent(self.script_id)
        self:AddText("  Hiện tại ngươi đang ở Trạng thái hạn chế truyền tống, không thể tiến vào Tung Sơn Phong Thiền Đài.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if self:IsHaveMission(selfId, self.g_CaoyunMisId) then
        self:BeginEvent(self.script_id)
        self:AddText(
            "  Hiện tại ngươi đang ở Trạng thái hạn chế truyền tống, không thể tiến vào Tung Sơn Phong Thiền Đài.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    local nPos_X = 0
    local nPos_Z = 0
    local sceneId = self:GetSceneID()
    for i, pos in pairs(self.g_Position) do
        if pos["scene"] == sceneId then
            nPos_X = pos["x"]
            nPos_Z = pos["z"]
        end
    end
    local nJingjiScnenId = 414
    self:CallScriptFunction((400900), "TransferFunc", selfId, nJingjiScnenId, nPos_X, nPos_Z)
end

function ejingji_1:OnScenePlayerEnter(selfId)
    local nTeamId = self:GetTeamId(selfId)
    local nCampID = nTeamId + 500
    if self:GetSameCampCount(nCampID) >= self.g_SameCampMax then
        if self:LuaFnHaveImpactOfSpecificDataIndex(selfId, self.g_GotoProtect) then
            self:LuaFnCancelSpecificImpact(selfId, self.g_GotoProtect)
        end
        self:CallScriptFunction((400900), "TransferFunc", selfId, self.g_OutPosition["scene"], self.g_OutPosition["x"], self.g_OutPosition["z"])
        return
    end
    if self:LuaFnHasTeam(selfId) then
        self:SetUnitCampID(selfId, nCampID)
    else
        local tempCamp = math.random(449) + 50
        self:SetUnitCampID(selfId, tempCamp)
    end
    local x, z = self:LuaFnGetWorldPos(selfId)
    local v = self.g_Position
    if x ~= v[1]["x"] or z ~= v[1]["z"] and x ~= v[2]["x"] or z ~= v[2]["z"] and
        x ~= v[3]["x"] or z ~= v[3]["z"] and x ~= v[4]["x"] or z ~= v[4]["z"] and
        x ~= v[5]["x"] or z ~= v[5]["z"] and x ~= v[6]["x"] or z ~= v[6]["z"] and
        x ~= v[7]["x"] or z ~= v[7]["z"] and x ~= v[8]["x"] or z ~= v[8]["z"] then
        x = v[1]["x"]
        z = v[1]["z"]
    end
    self:SetPlayerDefaultReliveInfoEx(selfId, 1, 1, 0, x, z, 125020)
end

function ejingji_1:OnRelive(selfId)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 8054, 100)
end

function ejingji_1:OnSceneTimer()
    self:DealNoCampHuman()
    self:RandomBroad()
    local nCurTime = self:GetHour()
    local nMinute = self:GetMinute()
    if (nCurTime == 0 or nCurTime == 10 or nCurTime == 12 or nCurTime == 14 or
        nCurTime == 16 or nCurTime == 18 or nCurTime == 20 or nCurTime == 22) then
        if (nCurTime - self.g_PreCreateBoxTime >= 2 or self.g_PreCreateBoxTime -
            nCurTime >= 2) and self.g_Step == 0 and nMinute >= 45 and nMinute < 50 then
            self.g_PreBroadTime = self:LuaFnGetCurrentTime()
            self.g_IsPreBroad = 0
            self.g_Step = 1
        end
        if self.g_Step == 1 and self:LuaFnGetCurrentTime() - self.g_PreBroadTime >= 60 then
            self.g_PreCreateBoxTime = nCurTime
            self:CreateBigBox()
            self.g_Step = 0
        end
    end
    if (nMinute == 5 or nMinute == 25) and self.g_PreCreateStoneBox ~= nMinute then
        self:CreateStoneBox()
        self.g_PreCreateStoneBox = nMinute
    end
    local nNowTime = self:LuaFnGetCurrentTime()
    if nNowTime - self.g_PreCreateSmallBoxTime >= 30 then
        self:CreateSmallBox()
        self.g_PreCreateSmallBoxTime = nNowTime
    end
end

function ejingji_1:CreateSmallBox()
    local nCount = self:GetMonsterCount()
    for i = 1, nCount do
        local nMonsterId = self:GetMonsterObjID(i)
        local szName = self:GetName(nMonsterId)
        for j = 1, #(self.g_SmallBoxName) do
            if szName == self.g_SmallBoxName[j] then
                self:LuaFnDeleteMonster(nMonsterId)
            end
        end
    end
    for i = 1, #(self.g_BuffPosition) do
        local nRand = math.random(#(self.g_SmallBoxList))
        local nBoxId = self:LuaFnCreateMonster(
                           self.g_SmallBoxList[nRand]["monId"],
                           self.g_BuffPosition[i]["x"],
                           self.g_BuffPosition[i]["z"], 3, 0,
                           self.g_SmallBoxList[nRand]["script"])
        self:SetUnitCampID(nBoxId, 0)
    end
end

function ejingji_1:CreateBigBox()
    local str = "#YVu Cửu Liên#P lớn tiếng: Chư vị anh hùng trong thiên hạ! Rương báu chứa đầy bảo vật và kinh nghiệm đã được đặt tại Phong Thiền Đài! Các vị anh hùng muốn trở thành Minh chủ Ô Lâm, cứ việc đến lấy! Mời tìm đến #GLạc Dương Hạ Hầu Nhân (155, 107), Tô Châu Hạ Toại Lương (186, 129), Đại Lý Bạch Sùng Nghĩa (177, 133)#P, tiến vào Phong Thiền Đài tỷ võ, tranh đoạt Minh chủ Ô Lâm!"
    str = gbk.fromutf8(str)
    self:BroadMsgByChatPipe(0, str, 4)
    local nCount = self:GetMonsterCount()
    local bHaveBox = 0
    for i = 1, nCount do
        local nObjId = self:GetMonsterObjID(i)
        if self:GetName(nObjId) == "宝箱" then bHaveBox = 1 end
    end
    if bHaveBox == 1 then return end
    local v = self.g_BigBoxInfo
    local nBoxId = self:LuaFnCreateMonster(v["id"], v["x"], v["z"], v["ai"], v["aif"], v["script"])
    self:SetUnitCampID(nBoxId, 0)
end

function ejingji_1:CreateStoneBox()
    local nCount = self:GetMonsterCount()
    for i = 1, nCount do
        local nMonsterId = self:GetMonsterObjID(i)
        local szName = self:GetName(nMonsterId)
        if szName == "白色宝箱" then
            self:LuaFnDeleteMonster(nMonsterId)
        end
    end
    local v = self.g_StoneBoxInfo
    local nRand = math.random(#(self.g_StonePosition_1))
    local x = self.g_StonePosition_1[nRand]["x"]
    local z = self.g_StonePosition_1[nRand]["z"]
    local nBoxId = self:LuaFnCreateMonster(v["id"], x, z, v["ai"], v["aif"],  v["script"])
    self:SetUnitCampID(nBoxId, 0)
    nRand = math.random(#(self.g_StonePosition_2))
    x = self.g_StonePosition_2[nRand]["x"]
    z = self.g_StonePosition_2[nRand]["z"]
    nBoxId = self:LuaFnCreateMonster(v["id"], x, z, v["ai"], v["aif"], v["script"])
    self:SetUnitCampID(nBoxId, 0)
    nRand = math.random(#(self.g_StonePosition_3))
    x = self.g_StonePosition_3[nRand]["x"]
    z = self.g_StonePosition_3[nRand]["z"]
    nBoxId = self:LuaFnCreateMonster(v["id"], x, z, v["ai"], v["aif"], v["script"])
    self:SetUnitCampID(nBoxId, 0)
    nRand = math.random(#(self.g_StonePosition_4))
    x = self.g_StonePosition_4[nRand]["x"]
    z = self.g_StonePosition_4[nRand]["z"]
    nBoxId = self:LuaFnCreateMonster(v["id"], x, z, v["ai"], v["aif"], v["script"])
    self:SetUnitCampID(nBoxId, 0)
    nRand = math.random(#(self.g_StonePosition_5))
    x = self.g_StonePosition_5[nRand]["x"]
    z = self.g_StonePosition_5[nRand]["z"]
    nBoxId = self:LuaFnCreateMonster(v["id"], x, z, v["ai"], v["aif"], v["script"])
    self:SetUnitCampID(nBoxId, 0)
end

function ejingji_1:GetSameCampCount(CampId)
    local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
    local nCount = 0
    for i = 1, nHumanCount do
        local nHumanId = self:LuaFnGetCopyScene_HumanObjId(i)
        if CampId == self:GetUnitCampID(nHumanId) then
            nCount = nCount + 1
        end
    end
    return nCount
end

function ejingji_1:DealNoCampHuman()
    local nHumanCount = self:LuaFnGetCopyScene_HumanCount()
    for i = 1, nHumanCount do
        local nHumanId = self:LuaFnGetCopyScene_HumanObjId(i)
        if self:GetUnitCampID(nHumanId) < 500 then
            if self:LuaFnIsObjValid(nHumanId) and self:LuaFnIsCanDoScriptLogic(nHumanId) then
                if self:LuaFnHasTeam(nHumanId)then
                    local nTeamId = self:GetTeamId(nHumanId)
                    local nCampId = nTeamId + 500
                    if self:GetSameCampCount(nCampId) >= 10 then
                        if self:LuaFnHaveImpactOfSpecificDataIndex(nHumanId, self.g_GotoProtect) then
                            self:LuaFnCancelSpecificImpact(nHumanId, self.g_GotoProtect)
                        end
                        self:CallScriptFunction((400900), "TransferFunc", nHumanId, self.g_OutPosition["scene"], self.g_OutPosition["x"], self.g_OutPosition["z"])
                        return
                    else
                        self:SetUnitCampID(nHumanId, nCampId)
                    end
                end
            end
        end
    end
end

function ejingji_1:RandomBroad()
    if math.random(100) == 1 then
        local rand = math.random(3)
        local str
        if rand == 1 then
            str = "#G[Phong Thiền Đài]#YVu Cửu Liên#P quát lớn: Các vị anh hùng! Hãy thể hiện bản lĩnh thật sự của các ngươi đi!"
        elseif rand == 2 then
            str = "#G[Phong Thiền Đài]#YVu Cửu Liên#P hô lớn: Cố lên! Nếu không tín vật sẽ bị người khác cướp mất!"
        elseif rand == 3 then
            str = "#G[Phong Thiền Đài]#YVu Cửu Liên#P hô lớn: Chiến đấu đi! Vì danh vị! Cũng vì phần thưởng!"
        end
        self:CallScriptFunction((200060), "Duibai", "", "", str)
    end
end

function ejingji_1:OnSceneHumanDie(selfId, killerId)
    local nStoneId = 40004434
    local nStoneCount = self:GetItemCount(selfId, nStoneId)
    if nStoneCount >= 1 then
        local ret = self:DelItem(selfId, nStoneId, 1)
        if ret then
            local x, z = self:GetWorldPos(selfId)
            local nBoxId = self:DropBoxEnterScene(x, z)
            self:AddItemToBox(nBoxId, ScriptGlobal.QUALITY_CREATE_BY_BOSS, 1, nStoneId)
        end
    end
end

return ejingji_1
