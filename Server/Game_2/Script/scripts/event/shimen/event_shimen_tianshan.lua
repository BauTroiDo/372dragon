local class = require "class"
local define = require "define"
local script_base = require "script_base"
local event_shimen_tianshan = class("event_shimen_tianshan", script_base)
event_shimen_tianshan.script_id = 229006
event_shimen_tianshan.g_Position_X = 95.0380
event_shimen_tianshan.g_Position_Z = 60.9364
event_shimen_tianshan.g_SceneID = 17
event_shimen_tianshan.g_AccomplishNPC_Name = "符敏仪"
event_shimen_tianshan.g_Name = "符敏仪"
event_shimen_tianshan.g_MissionId = 1100
event_shimen_tianshan.g_MissionKind = 28
event_shimen_tianshan.g_MissionLevel = 10000
event_shimen_tianshan.g_IfMissionElite = 0
event_shimen_tianshan.g_IsMissionOkFail = 0
event_shimen_tianshan.g_MissionName = "Sư môn nhiệm vụ"
event_shimen_tianshan.g_MissionInfo = ""
event_shimen_tianshan.g_MissionTarget = "%f"
event_shimen_tianshan.g_ContinueInfo = "Làm tốt lắm!"
event_shimen_tianshan.g_MissionComplete =
    "Chuyện ta giao cho ngươi đã làm xong chưa?"
event_shimen_tianshan.g_MissionRound = 17
event_shimen_tianshan.g_DoubleExp = 48
event_shimen_tianshan.g_AccomplishCircumstance = 1
event_shimen_tianshan.g_ShimenTypeIndex = 1
event_shimen_tianshan.g_Parameter_Kill_AllRandom = {
    {["id"] = 7, ["numa"] = 3, ["numb"] = 3, ["bytenuma"] = 0, ["bytenumb"] = 1}
}
event_shimen_tianshan.g_Parameter_Item_IDRandom = {{["id"] = 6, ["num"] = 5}}
event_shimen_tianshan.g_NpcIdIndicator = {
    {["key"] = 2, ["npcIdIndex"] = 5}, {["key"] = 9, ["npcIdIndex"] = 7}
}
event_shimen_tianshan.g_FormatList = {
    "Lâu rồi không gặp %n, ta rất nhớ nhung. %s này là chút lòng thành của ta, xin ngươi hãy mang nó đi giúp ta nhé.#r  #e00f000Mẹo:#e000000#r  Ngươi Có thể sử dụng tại Linh Thứu Cung tìm #RÔ Lão Đại#W#{_INFOAIM90,120,17,Ô Lão Đại}, nhờ hắn đưa ngươi đến các thành thị lớn.#B#r  Sau khi đưa đồ xong, xin đến chỗ người phát nhiệm vụ sư môn #WPhù Mẫn Nghi#{_INFOAIM95,60,17,Phù Mẫn Nghi} để trả nhiệm vụ.#r#{SMRW_090206_01}",
    "%i của ta đâu rồi? Nếu ngươi có thể giúp ta tìm lại, ta nhất định không bạc đãi ngươi đâu.#r  #e00f000Mẹo:#e000000#r  Ngươi Có thể sử dụng tại Linh Thứu Cung tìm #RÔ Lão Đại#W#{_INFOAIM90,120,17,Ô Lão Đại}, nhờ hắn đưa ngươi đến các thành thị lớn.#r#{SMRW_090206_01}",
    "%n làm việc xấu, ta rất muốn đi dạy dỗ hắn một trận, tiếc là không có thời gian, ngươi có thể làm giúp ta được không?#r  #e00f000Mẹo:#e000000#r  Ngươi Có thể sử dụng tại Linh Thứu Cung tìm #RÔ Lão Đại#W#{_INFOAIM90,120,17,Ô Lão Đại}, nhờ hắn đưa ngươi đến các thành thị lớn.#r#{SMRW_090206_01}",
    "Xin ngươi hãy tại Thiên Sơn tìm %s, đem %s rót vào trong đó.#r  #e00f000Mẹo:#e000000#r  Khi ngươi đến gần Băng Hỗ yêu cầu rót Thánh Thủy của, ngươi có thể ấn #gfff0f0Alt+A#g000000 để mở túi đồ, nhấn vào trang #gfff0f0\"Nhiệm Vụ\"#g000000 để mở túi đồ nhiệm vụ, nhấp chuột phải vào #gfff0f0Thánh Thủy#g000000, là có thể hoàn thành việc rót.#r#{SMRW_090206_01}",
    "Xin tìm %s, hắn sẽ dẫn ngươi khiêu chiến %s.#r  #e00f000Mẹo:#e000000#r  Cúc Kiếm tỷ tỷ ở ngay Linh Thứu Cung#{_INFOAIM101,44,17,Cúc Kiếm}.#r#{SMRW_090206_01}",
    "Xin ngươi giúp ta bắt một con %p.#B#r  #e00f000Mẹo:#e000000#r  #G#WLạc Dương#W thành của #GVân Hàm Nhi#{_INFOAIM183,155,0,Vân Hàm Nhi} có thể đưa ngươi đến #GHuyền Vũ Đảo#, mà #GHuyền Vũ Đảo# có một con đường nhỏ thông đến Thánh Thú Sơn. Ngươi Có thể sử dụng tại #GHuyền Vũ Đảo# hoặc Thánh Thú Sơn bắt #GTrân thú# ta yêu cầu.#r#{SMRW_090206_01}",
    "Thỉnh ngươi tại #YThiên Sơn#W tứ xứ nhìn xem, giúp ta tìm đến 5 cái %s. #r #e00f000Mẹo:#e000000#r Ngươi #YCó thể sử dụng tại#W màn hình bên phải phía trên #Ycủa#W bản đồ nhỏ tìm được điểm chỉ thị #Ymàu vàng#. #r#{SMRW_090206_01}",
    "Hãy mang một %i đến cho %s đi, xong việc rồi, ta sẽ thưởng cho ngươi!#r  #e00f000Mẹo nhỏ：#e000000#r  Thạch Tẩu đang ở Linh Thứu Cung#{_INFOAIM123,67,17,Thạch tẩu}.#r  Lô Vũ Đình tỷ tỷ đang ở Linh Thứu Cung#{_INFOAIM45,69,17,Lô Vũ Đình}.#r  Nhậm Phi Hồng tỷ tỷ đang ở Linh Thứu Cung#{_INFOAIM39,71,17,Nhậm Phi Hồng}.#B#r  Sau khi giao xong đồ, hãy đến chỗ người phát nhiệm vụ sư môn #WPhù Mẫn Nghi#{_INFOAIM95,60,17,Phù Mẫn Nghi} để trả nhiệm vụ.#r#{SMRW_090206_01}",
    "Đi tiêu diệt %s %s %n cái.#r#{SMRW_090206_01}"
}
event_shimen_tianshan.g_StrForePart = 4
event_shimen_tianshan.g_ShimenPet_Index = 1
event_shimen_tianshan.g_StrList = {
    "Nước Thiên Trì", "Nước Sương Đá", "Nước Suối Lạnh", "Nước Băng Tan", "Huyền Băng Hỗ",
    "Hàn Băng Hỗ", "Toái Băng Hỗ", "Nham Băng Hỗ", "菊剑", "Chiết Mai Phong Phó bản",
    "Nho khô", "Hoa Tuyết Liên", "Dưa Hami", "石嫂", "芦雨亭", "任飞虹",
    "Sài Miêu Hoang Dã", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"
}
event_shimen_tianshan.g_SubMissionTypeEnum = {
    ["XunWu"] = 1,
    ["SongXin"] = 2,
    ["DingDianYinDao"] = 3,
    ["FuBenZhanDou"] = 4,
    ["BuZhuo"] = 5,
    ["ShouJi"] = 6,
    ["KaiGuang"] = 7,
    ["otherMenpaiFuben"] = 8,
    ["killMonster"] = 9
}
event_shimen_tianshan.g_DingDianYinDaoList = {
    {
        ["menpai"] = define.MENPAI_ATTRIBUTE.MATTRIBUTE_TIANSHAN,
        ["itemId"] = 40003038,
        ["itemName"] = "Nước Thiên Trì",
        ["scene"] = 17,
        ["AreaName"] = "Huyền Băng Hỗ",
        ["subAreaName"] = "Huyền Băng Hỗ",
        ["posx1"] = 54,
        ["posz1"] = 31,
        ["posx2"] = 67,
        ["posz2"] = 45
    }, {
        ["menpai"] = define.MENPAI_ATTRIBUTE.MATTRIBUTE_TIANSHAN,
        ["itemId"] = 40003039,
        ["itemName"] = "Nước Sương Đá",
        ["scene"] = 17,
        ["AreaName"] = "Hàn Băng Hỗ",
        ["subAreaName"] = "Hàn Băng Hỗ",
        ["posx1"] = 70,
        ["posz1"] = 57,
        ["posx2"] = 77,
        ["posz2"] = 69
    }, {
        ["menpai"] = define.MENPAI_ATTRIBUTE.MATTRIBUTE_TIANSHAN,
        ["itemId"] = 40003040,
        ["itemName"] = "Nước Suối Lạnh",
        ["scene"] = 17,
        ["AreaName"] = "Toái Băng Hỗ",
        ["subAreaName"] = "Toái Băng Hỗ",
        ["posx1"] = 117,
        ["posz1"] = 85,
        ["posx2"] = 130,
        ["posz2"] = 96
    }, {
        ["menpai"] = define.MENPAI_ATTRIBUTE.MATTRIBUTE_TIANSHAN,
        ["itemId"] = 40003041,
        ["itemName"] = "Nước Băng Tan",
        ["scene"] = 17,
        ["AreaName"] = "Nham Băng Hỗ",
        ["subAreaName"] = "Nham Băng Hỗ",
        ["posx1"] = 123,
        ["posz1"] = 46,
        ["posx2"] = 135,
        ["posz2"] = 57
    }
}
event_shimen_tianshan.g_FuBen_List = {
    {
        ["menpai"] = define.MENPAI_ATTRIBUTE.MATTRIBUTE_TIANSHAN,
        ["NpcName"] = "菊剑",
        ["scene"] = 17,
        ["posx"] = 99,
        ["posz"] = 45,
        ["FubenName"] = "Chiết Mai Phong Phó bản"
    }
}
event_shimen_tianshan.g_ShouJiList = {
    {
        ["menpai"] = define.MENPAI_ATTRIBUTE.MATTRIBUTE_TIANSHAN,
        ["scene"] = 17,
        ["itemId"] = 40003042,
        ["itemName"] = "Nho khô"
    }, {
        ["menpai"] = define.MENPAI_ATTRIBUTE.MATTRIBUTE_TIANSHAN,
        ["scene"] = 17,
        ["itemId"] = 40003043,
        ["itemName"] = "Hoa Tuyết Liên"
    }, {
        ["menpai"] = define.MENPAI_ATTRIBUTE.MATTRIBUTE_TIANSHAN,
        ["scene"] = 17,
        ["itemId"] = 40003044,
        ["itemName"] = "Dưa Hami"
    }
}
event_shimen_tianshan.g_AbilityNpcList = {
    {
        ["menpai"] = define.MENPAI_ATTRIBUTE.MATTRIBUTE_TIANSHAN,
        ["npcList"] = {
            {["name"] = "石嫂", ["scene"] = 17, ["x"] = 123, ["z"] = 67},
            {["name"] = "芦雨亭", ["scene"] = 17, ["x"] = 45, ["z"] = 69},
            {["name"] = "任飞虹", ["scene"] = 17, ["x"] = 39, ["z"] = 71}
        }
    }
}
event_shimen_tianshan.g_PetList = {
    {["petDataId"] = 3000, ["petName"] = "Sài Miêu Hoang Dã", ["takeLevel"] = 10}
}
event_shimen_tianshan.g_MenpaiYiWuList = {
    {
        ["menpainame"] = "少林",
        ["menpai"] = define.MENPAI_ATTRIBUTE.MATTRIBUTE_SHAOLIN,
        ["itemName"] = "Độ điệp của Đệ tử Thiếu Lâm",
        ["scene"] = 9,
        ["itemId"] = 40004306
    }, {
        ["menpainame"] = "天龙",
        ["menpai"] = define.MENPAI_ATTRIBUTE.MATTRIBUTE_DALI,
        ["itemName"] = "Ấn chương của đệ tử Thiên Long",
        ["scene"] = 13,
        ["itemId"] = 40004312
    }, {
        ["menpainame"] = "Nga Mi",
        ["menpai"] = define.MENPAI_ATTRIBUTE.MATTRIBUTE_EMEI,
        ["itemName"] = "Kiếm tuệ của đệ tử Nga My",
        ["scene"] = 15,
        ["itemId"] = 40004310
    }, {
        ["menpainame"] = "丐帮",
        ["menpai"] = define.MENPAI_ATTRIBUTE.MATTRIBUTE_GAIBANG,
        ["itemName"] = "Túi vải của Đệ tử Cái Bang",
        ["scene"] = 10,
        ["itemId"] = 40004307
    }, {
        ["menpainame"] = "明教",
        ["menpai"] = define.MENPAI_ATTRIBUTE.MATTRIBUTE_MINGJIAO,
        ["itemName"] = "Hỏa lệnh của Đệ tử Minh Giáo",
        ["scene"] = 11,
        ["itemId"] = 40004308
    }, {
        ["menpainame"] = "天山",
        ["menpai"] = define.MENPAI_ATTRIBUTE.MATTRIBUTE_TIANSHAN,
        ["itemName"] = "Băng bài của đệ tử Thiên Sơn",
        ["scene"] = 17,
        ["itemId"] = 40004314
    }, {
        ["menpainame"] = "武当",
        ["menpai"] = define.MENPAI_ATTRIBUTE.MATTRIBUTE_WUDANG,
        ["itemName"] = "Phất trần của Đệ tử Võ Đang",
        ["scene"] = 12,
        ["itemId"] = 40004309
    }, {
        ["menpainame"] = "逍遥",
        ["menpai"] = define.MENPAI_ATTRIBUTE.MATTRIBUTE_XIAOYAO,
        ["itemName"] = "Tiêu chí của đệ tử Tiêu Dao",
        ["scene"] = 14,
        ["itemId"] = 40004313
    }, {
        ["menpainame"] = "星宿",
        ["menpai"] = define.MENPAI_ATTRIBUTE.MATTRIBUTE_XINGXIU,
        ["itemName"] = "Cổ mẫn của đệ tử Tinh Túc",
        ["scene"] = 16,
        ["itemId"] = 40004311
    }
}
event_shimen_tianshan.g_RateOfDropYiWuTable = {
    {["playerLevel"] = 20, ["dropRate"] = 30},
    {["playerLevel"] = 30, ["dropRate"] = 30},
    {["playerLevel"] = 40, ["dropRate"] = 25},
    {["playerLevel"] = 50, ["dropRate"] = 25},
    {["playerLevel"] = 60, ["dropRate"] = 25},
    {["playerLevel"] = 70, ["dropRate"] = 20},
    {["playerLevel"] = 80, ["dropRate"] = 20},
    {["playerLevel"] = 90, ["dropRate"] = 20},
    {["playerLevel"] = 100, ["dropRate"] = 20},
    {["playerLevel"] = 110, ["dropRate"] = 20},
    {["playerLevel"] = 120, ["dropRate"] = 20},
    {["playerLevel"] = 130, ["dropRate"] = 20},
    {["playerLevel"] = 140, ["dropRate"] = 20},
    {["playerLevel"] = 150, ["dropRate"] = 20}
}
event_shimen_tianshan.g_DemandKillcountTable = {
    {["levelBegin"] = 10, ["levelEnd"] = 19, ["killcount"] = 20},
    {["levelBegin"] = 20, ["levelEnd"] = 39, ["killcount"] = 25},
    {["levelBegin"] = 40, ["levelEnd"] = 59, ["killcount"] = 30},
    {["levelBegin"] = 60, ["levelEnd"] = 79, ["killcount"] = 35},
    {["levelBegin"] = 80, ["levelEnd"] = 99, ["killcount"] = 40},
    {["levelBegin"] = 100, ["levelEnd"] = 109, ["killcount"] = 45},
    {["levelBegin"] = 110, ["levelEnd"] = 119, ["killcount"] = 50},
    {["levelBegin"] = 120, ["levelEnd"] = 150, ["killcount"] = 55}
}
function event_shimen_tianshan:GetMenpaiYiWuInfo(selfId)
    for i, v in pairs(self.g_MenpaiYiWuList) do
        if v["menpai"] == self:GetMenPai(selfId) then
            return v["menpainame"]
        end
    end
end
function event_shimen_tianshan:GetRateOfDropYiWu(selfId)
    local playerLevel = self:GetLevel(selfId)
    for i, v in pairs(self.g_RateOfDropYiWuTable) do
        if v["playerLevel"] >= playerLevel and playerLevel < v["playerLevel"] then
            return v["dropRate"]
        end
    end
end
function event_shimen_tianshan:GetDemandKillCount(selfId)
    local playerLevel = self:GetLevel(selfId)
    for i, v in pairs(self.g_DemandKillcountTable) do
        if playerLevel >= v["levelBegin"] and playerLevel <= v["levelEnd"] then
            return v["killcount"]
        end
    end
end
function event_shimen_tianshan:KillMonster_Accept(selfId)
    local nMonsterId, strMonsterName, strMonsterScene, nScene, nPosX, nPosZ,
          strDesc, nSex, level
    local playerLevel = self:GetLevel(selfId)
    for i = 1, 100 do
        nMonsterId, strMonsterName, strMonsterScene, nScene, nPosX, nPosZ, strDesc, nSex, level = self:GetOneMissionNpc(43)
        if self:abs(level - playerLevel) < 3 then break end
        if i == 100 then
            self:SongXin_Accept(selfId)
            return
        end
    end
    local bAdd = self:AddMission(selfId, self.g_MissionId, self.script_id, 1, 0,
                                 1)
    if not bAdd then return end
    local killcount = self:GetDemandKillCount(selfId)
    local countpart1 = self:GetStrIndexByStrValue(
                           self:tostring(math.floor(killcount / 10)))
    local countpart2 = self:GetStrIndexByStrValue(
                           self:tostring(math.floor(math.mod(killcount, 10))))
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    self:SetMissionByIndex(selfId, misIndex, 0, 0)
    self:SetMissionByIndex(selfId, misIndex, 1,
                           self.g_SubMissionTypeEnum["killMonster"])
    self:SetMissionParamByIndexEx(selfId, misIndex, 3, 0, killcount)
    self:SetMissionParamByIndexEx(selfId, misIndex, 3, 1, 0)
    self:SetMissionByIndex(selfId, misIndex, self.g_StrForePart, 8)
    self:SetMissionByIndex(selfId, misIndex, self.g_StrForePart + 1, countpart1)
    self:SetMissionByIndex(selfId, misIndex, self.g_StrForePart + 2, countpart2)
    self:SetMissionByIndex(selfId, misIndex, self.g_StrForePart + 3, nMonsterId)
    self:Msg2Player(selfId, "#YTiếp nhận nhiệm vụ: Sư môn nhiệm vụ",
                    define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    self:CallScriptFunction(888888, "AskThePos", selfId, nScene, nPosX, nPosZ,
                            strMonsterName)
    local strMissionTarget = string.format(
                                 "Gần đây %s khu vực của %s thường xuyên quấy nhiễu dân cư xung quanh, đặc mệnh ngươi đi trừng trị chúng.",
                                 strMonsterScene, strMonsterName)
    self:AddText(strMissionTarget)
end
function event_shimen_tianshan:GetStrIndexByStrValue(stringV)
    for i, v in pairs(self.g_StrList) do
        if v == stringV then return i - 1 end
    end
    local strText = string.format("Phải đăng ký %s vào StrList", stringV)
    return 0
end
function event_shimen_tianshan:GetItemDetailInfo(itemId)
    local itemId, itemName, itemDesc = self:GetItemInfoByItemId(itemId)
    if itemId == -1 then
        local strText = string.format(
                            "Vật phẩm %s không thấy trong 'MissionItem_HashTable.txt'!!",
                            itemName)
        self:PrintStr(strText)
    end
    return itemId
end
function event_shimen_tianshan:GetMissionItemIndex(selfId)
    local nPlayerLevel = self:GetLevel(selfId)
    if nPlayerLevel >= 10 and nPlayerLevel < 20 then
        return 0
    elseif nPlayerLevel >= 20 and nPlayerLevel < 30 then
        return 1
    elseif nPlayerLevel >= 30 and nPlayerLevel < 40 then
        return 2
    elseif nPlayerLevel >= 40 and nPlayerLevel < 60 then
        return 3
    elseif nPlayerLevel >= 60 and nPlayerLevel < 80 then
        return 4
    elseif nPlayerLevel >= 80 and nPlayerLevel < 100 then
        return 5
    elseif nPlayerLevel >= 100 and nPlayerLevel < 120 then
        return 167
    elseif nPlayerLevel >= 100 then
        return 168
    end
end
function event_shimen_tianshan:GetShiMenPhaseByPlayerLevel(selfId)
    local nPlayerLevel = self:GetLevel(selfId)
    if nPlayerLevel >= 10 and nPlayerLevel < 20 then
        return 0
    elseif nPlayerLevel >= 20 and nPlayerLevel < 40 then
        return 1
    elseif nPlayerLevel >= 40 and nPlayerLevel < 60 then
        return 2
    elseif nPlayerLevel >= 60 and nPlayerLevel < 80 then
        return 3
    elseif nPlayerLevel >= 80 and nPlayerLevel < 100 then
        return 4
    elseif nPlayerLevel >= 100 and nPlayerLevel < 120 then
        return 243
    elseif nPlayerLevel >= 120 then
        return 244
    end
end
function event_shimen_tianshan:RandomSubMission(selfId)
    local nRet = 1 + self:LuaFnGetHumanShimenRandom(selfId)
    if nRet then
        if nRet <= 4 then
            self:XunWu_Accept(selfId)
        elseif nRet <= 5 then
            self:SongXin_Accept(selfId)
        elseif nRet <= 6 then
            self:ShouJi_Accept(selfId)
        elseif nRet <= 7 then
            self:SongXin_Accept(selfId)
        elseif nRet <= 8 then
            self:DingDianYinDao_Accept(selfId)
        elseif nRet <= 12 then
            self:FuBenZhanDou_Accept(selfId)
        elseif nRet <= 16 then
            self:BuZhuo_Accept(selfId)
        else
            return -1
        end
    else
        return -1
    end
end
function event_shimen_tianshan:DoSomethingByPlayerLevel(selfId)
    self:CallScriptFunction(229000, "DoSomethingByPlayerLevel", selfId,
                            self.script_id)
end
function event_shimen_tianshan:XunWu_Accept(selfId)
    local bAdd = self:AddMission(selfId, self.g_MissionId, self.script_id, 0, 0,
                                 1)
    if not bAdd then return end
    local nitemId, strItemName, strItemDesc =
        self:GetOneMissionItem(self:GetMissionItemIndex(selfId))
    self:Msg2Player(selfId, "#YTiếp nhận nhiệm vụ: Sư môn nhiệm vụ",
                    define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    self:SetMissionByIndex(selfId, misIndex, 0, 0)
    self:SetMissionByIndex(selfId, misIndex, 1,
                           self.g_SubMissionTypeEnum["XunWu"])
    self:SetMissionByIndex(selfId, misIndex, self.g_StrForePart, 1)
    self:SetMissionByIndex(selfId, misIndex, self.g_StrForePart + 1, nitemId)
    local strMissionTarget = string.format(
                                 "%s của ta đâu rồi? Nếu ngươi có thể giúp ta tìm lại, ta nhất định không bạc đãi ngươi.",
                                 strItemName)
    self:AddText(strMissionTarget)
    local bHaveItem = self:HaveItem(selfId, nitemId)
    if bHaveItem == 1 then
        self:SetMissionByIndex(selfId, misIndex, 0, 1)
        self:ResetMissionEvent(selfId, self.g_MissionId, 2)
    end
end
function event_shimen_tianshan:SongXin_Accept(selfId)
    local roll = math.random(3)
    local letterItemId = self.g_ShouJiList[roll]["itemId"]
    self:BeginAddItem()
    self:AddItem(letterItemId, 1)
    local bAdd = self:EndAddItem(selfId)
    if not bAdd then return end
    bAdd = self:AddMission(selfId, self.g_MissionId, self.script_id, 0, 0, 0)
    if not bAdd then return end
    self:AddItemListToHuman(selfId)
    self:SetMissionEvent(selfId, self.g_MissionId, 4)
    local nPhase = self:GetShiMenPhaseByPlayerLevel(selfId)
    local nNpcId, strNpcName, strNpcScene, nSceneId, nPosX, nPosZ, strNPCDesc =
        self:GetOneMissionNpc(nPhase)
    self:Msg2Player(selfId, "#YTiếp nhận nhiệm vụ: Sư môn nhiệm vụ",
                    define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    self:CallScriptFunction(888888, "AskTheWay", selfId, nSceneId, nPosX, nPosZ,
                            strNpcName)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    self:SetMissionByIndex(selfId, misIndex, 0, 0)
    self:SetMissionByIndex(selfId, misIndex, 1,
                           self.g_SubMissionTypeEnum["SongXin"])
    self:SetMissionByIndex(selfId, misIndex, self.g_StrForePart, 0)
    self:SetMissionByIndex(selfId, misIndex, self.g_StrForePart + 1, nNpcId)
    local ListIndex = self:GetStrIndexByStrValue(
                          self.g_ShouJiList[roll]["itemName"])
    self:SetMissionByIndex(selfId, misIndex, self.g_StrForePart + 2, ListIndex)
    self:SetMissionByIndex(selfId, misIndex, self.g_StrForePart + 3,
                           letterItemId)
    local strMissionTarget = string.format(
                                 "Đã lâu không gặp %s%s, xin ngươi giúp ta đưa cái %s này cho hắn.",
                                 strNpcScene, strNpcName,
                                 self.g_ShouJiList[roll]["itemName"])
    self:AddText(strMissionTarget)
end
function event_shimen_tianshan:DingDianYinDao_Accept(selfId)
    local playerMenpai = self:GetMenPai(selfId)
    local a = {}
    local index = 1
    for i, v in pairs(self.g_DingDianYinDaoList) do
        if v["menpai"] == playerMenpai then
            a[index] = i
            index = index + 1
        end
    end
    local ct = #(a)
    if ct <= 0 then return 0 end
    local ret = math.random(ct)
    self:BeginAddItem()
    self:AddItem(self.g_DingDianYinDaoList[a[ret]]["itemId"], 1)
    local bAdd = self:EndAddItem(selfId)
    if not bAdd then return end
    bAdd = self:AddMission(selfId, self.g_MissionId, self.script_id, 0, 0, 0)
    if not bAdd then return end
    self:AddItemListToHuman(selfId)
    self:Msg2Player(selfId, "#YNgươi nhận được một" ..
                        self.g_DingDianYinDaoList[a[ret]]["itemName"],
                    define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    local strIndex_Area = self:GetStrIndexByStrValue(
                              self.g_DingDianYinDaoList[a[ret]]["AreaName"])
    local strIndex_Item = self:GetStrIndexByStrValue(
                              self.g_DingDianYinDaoList[a[ret]]["itemName"])
    local x1 = self.g_DingDianYinDaoList[a[ret]]["posx1"]
    local x2 = self.g_DingDianYinDaoList[a[ret]]["posx2"]
    local z1 = self.g_DingDianYinDaoList[a[ret]]["posz1"]
    local z2 = self.g_DingDianYinDaoList[a[ret]]["posz2"]
    local scene = self.g_DingDianYinDaoList[a[ret]]["scene"]
    local tip = self.g_DingDianYinDaoList[a[ret]]["AreaName"]
    local x = x1 + (x2 - x1) / 2
    local z = z1 + (z2 - z1) / 2
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    self:SetMissionByIndex(selfId, misIndex, 0, 0)
    self:SetMissionByIndex(selfId, misIndex, 1,
                           self.g_SubMissionTypeEnum["DingDianYinDao"])
    self:SetMissionByIndex(selfId, misIndex, 2, a[ret])
    self:SetMissionByIndex(selfId, misIndex, self.g_StrForePart, 3)
    self:SetMissionByIndex(selfId, misIndex, self.g_StrForePart + 1,
                           strIndex_Area)
    self:SetMissionByIndex(selfId, misIndex, self.g_StrForePart + 2,
                           strIndex_Item)
    self:Msg2Player(selfId, "#YTiếp nhận nhiệm vụ: Sư môn nhiệm vụ",
                    define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    self:CallScriptFunction(888888, "AskThePos", selfId, scene, x, z, tip)
    local strMissionTarget = string.format(
                                 "Xin ngươi ở Thiên Sơn tìm được %s, đem %s rót vào trong đó.",
                                 self.g_DingDianYinDaoList[a[ret]]["AreaName"],
                                 self.g_DingDianYinDaoList[a[ret]]["itemName"])
    self:AddText(strMissionTarget)
end
function event_shimen_tianshan:FuBenZhanDou_Accept(selfId)
    local playerMenpai = self:GetMenPai(selfId)
    if playerMenpai == MP_WUMENPAI then return 0 end
    local npcName, fubenName, nSceneId, posx, posz
    for i, v in pairs(self.g_FuBen_List) do
        if v["menpai"] == self:GetMenPai(selfId) then
            npcName = v["NpcName"]
            fubenName = v["FubenName"]
            nSceneId = v["scene"]
            posx = v["posx"]
            posz = v["posz"]
            break
        end
    end
    local bAdd = self:AddMission(selfId, self.g_MissionId, self.script_id, 0, 0,
                                 0)
    if not bAdd then return end
    local nFormatIndex = self:GetMissionCacheData(selfId, 0)
    local i = self:GetMissionCacheData(selfId, 2)
    local NpcNameIndex = self:GetStrIndexByStrValue(npcName)
    local FubenNameIndex = self:GetStrIndexByStrValue(fubenName)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    self:SetMissionByIndex(selfId, misIndex, 0, 0)
    self:SetMissionByIndex(selfId, misIndex, 1,
                           self.g_SubMissionTypeEnum["FuBenZhanDou"])
    self:SetMissionByIndex(selfId, misIndex, self.g_StrForePart, 4)
    self:SetMissionByIndex(selfId, misIndex, self.g_StrForePart + 1,
                           NpcNameIndex)
    self:SetMissionByIndex(selfId, misIndex, self.g_StrForePart + 2,
                           FubenNameIndex)
    self:Msg2Player(selfId, "#YTiếp nhận nhiệm vụ: Sư môn nhiệm vụ",
                    define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    self:CallScriptFunction(888888, "AskTheWay", selfId, nSceneId, posx, posz,
                            npcName)
    local strMissionTarget = string.format(
                                 "Mời ngươi đi tìm %s, hắn sẽ dẫn ngươi đi khiêu chiến %s.",
                                 npcName, fubenName)
    self:AddText(strMissionTarget)
end
function event_shimen_tianshan:BuZhuo_Accept(selfId)
    local playerLevel = self:GetLevel(selfId)
    local petId, petName, petDesc, takeLevel
    local petHashIndex = self:CallScriptFunction(229000, "GetMissionPetIndex",
                                                 selfId)
    for i = 1, 100 do
        petId = self:GetOneMissionPet(petHashIndex)
        takeLevel = self:GetPetTakeLevel(petId)
        if playerLevel > takeLevel then break end
        if i == 100 then self:SongXin_Accept(selfId) end
    end
    local bAdd = self:AddMission(selfId, self.g_MissionId, self.script_id, 0, 0,
                                 0)
    if not bAdd then return end
    self:SetMissionEvent(selfId, self.g_MissionId, 3)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    self:SetMissionByIndex(selfId, misIndex, 0, 0)
    self:SetMissionByIndex(selfId, misIndex, 1,
                           self.g_SubMissionTypeEnum["BuZhuo"])
    self:SetMissionByIndex(selfId, misIndex, self.g_StrForePart, 5)
    self:SetMissionByIndex(selfId, misIndex, self.g_StrForePart + 1, petId)
    self:Msg2Player(selfId, "#YTiếp nhận nhiệm vụ: Sư môn nhiệm vụ",
                    define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    local strMissionTarget = string.format("Mời ngươi giúp ta bắt một con %s.",
                                           petName)
    self:AddText(strMissionTarget)
    for i = 0, 6 do
        local petDataId = self:LuaFnGetPet_DataID(selfId, i)
        if petDataId == petId then
            self:SetMissionByIndex(selfId, misIndex, 0, 1)
            self:ResetMissionEvent(selfId, self.g_MissionId, 3)
            break
        end
    end
end
function event_shimen_tianshan:ShouJi_Accept(selfId)
    local playerMenpai = self:GetMenPai(selfId)
    if playerMenpai == MP_WUMENPAI then return 0 end
    local a = {}
    local index = 1
    for i, v in pairs(self.g_ShouJiList) do
        if v["menpai"] == playerMenpai then
            a[index] = i
            index = index + 1
        end
    end
    local ct = #(a)
    if ct <= 0 then return 0 end
    local ret = math.random(ct)
    local bAdd = self:AddMission(selfId, self.g_MissionId, self.script_id, 0, 0,
                                 1)
    if not bAdd then return end
    local itemNameIndex = self:GetStrIndexByStrValue(
                              self.g_ShouJiList[a[ret]]["itemName"])
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    self:SetMissionByIndex(selfId, misIndex, 0, 0)
    self:SetMissionByIndex(selfId, misIndex, 1,
                           self.g_SubMissionTypeEnum["ShouJi"])
    self:SetMissionByIndex(selfId, misIndex, self.g_StrForePart, 6)
    self:SetMissionByIndex(selfId, misIndex, self.g_StrForePart + 1,
                           itemNameIndex)
    self:SetMissionByIndex(selfId, misIndex, self.g_StrForePart + 2,
                           self.g_ShouJiList[a[ret]]["itemId"])
    self:Msg2Player(selfId, "#YTiếp nhận nhiệm vụ: Sư môn nhiệm vụ",
                    define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    local strMissionTarget = string.format("Mời ngươi giúp ta kiếm 5 cái %s.",
                                           self.g_ShouJiList[a[ret]]["itemName"])
    self:AddText(strMissionTarget)
end
function event_shimen_tianshan:Ability_Accept(selfId)
    local strNpcName, scene, x, z
    for i, v in pairs(self.g_AbilityNpcList) do
        if v["menpai"] == self:GetMenPai(selfId) then
            local ct = #(v["npcList"])
            local index = math.random(ct)
            strNpcName = v["npcList"][index]["name"]
            scene = v["npcList"][index]["scene"]
            x = v["npcList"][index]["x"]
            z = v["npcList"][index]["z"]
        end
    end
    local strNpcIndex = self:GetStrIndexByStrValue(strNpcName)
    local itemId, itemName = self:GetMenpaiItem(selfId)
    local bAdd = self:AddMission(selfId, self.g_MissionId, self.script_id, 0, 0,
                                 0)
    if not bAdd then return end
    self:SetMissionEvent(selfId, self.g_MissionId, 2)
    self:SetMissionEvent(selfId, self.g_MissionId, 4)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    self:SetMissionByIndex(selfId, misIndex, 0, 0)
    self:SetMissionByIndex(selfId, misIndex, 1,
                           self.g_SubMissionTypeEnum["KaiGuang"])
    self:SetMissionByIndex(selfId, misIndex, self.g_StrForePart, 7)
    self:SetMissionByIndex(selfId, misIndex, self.g_StrForePart + 1, strNpcIndex)
    self:SetMissionByIndex(selfId, misIndex, self.g_StrForePart + 2, itemId)
    self:Msg2Player(selfId, "#YTiếp nhận nhiệm vụ: Sư môn nhiệm vụ",
                    define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    self:CallScriptFunction(888888, "AskTheWay", selfId, scene, x, z, strNpcName)
    local strMissionTarget = string.format(
                                 "Xin hãy đưa cho %s một %s đi, ta sẽ cho ngươi thù lao!",
                                 strNpcName, itemName)
    self:AddText(strMissionTarget)
end
function event_shimen_tianshan:OnDefaultEvent(selfId, targetId)
    if self:IsHaveMission(selfId, self.g_MissionId) then
        if self:GetName(targetId) == self.g_Name then
            self:BeginEvent(self.script_id)
            self:AddText(self.g_MissionName)
            self:AddText("Chuyện ta giao cho ngươi đã làm xong chưa?")
            self:EndEvent()
            bDone = self:CheckSubmit(selfId)
            self:DispatchMissionDemandInfo(selfId, targetId, self.script_id,
                                           self.g_MissionId, bDone)
        else
            local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
            local demandItemId = 0
            local missionType = self:GetMissionParam(selfId, misIndex, 1)
            if missionType == self.g_SubMissionTypeEnum["SongXin"] then
                demandItemId = self:GetMissionParam(selfId, misIndex,
                                                    self.g_StrForePart + 3)
            else
                demandItemId = self:GetMissionParam(selfId, misIndex,
                                                    self.g_StrForePart + 2)
            end
            local _, strDemandItemName, _ = self:GetItemDetailInfo(demandItemId)
            local bHaveItem = self:HaveItem(selfId, demandItemId)
            if bHaveItem == 1 then
                if self:LuaFnGetAvailableItemCount(selfId, demandItemId) >= 1 then
                    self:LuaFnDelAvailableItem(selfId, demandItemId, 1)
                    self:BeginEvent(self.script_id)
                    self:AddText(
                        "Mời ngươi về nói với sư phụ ngươi, ta cũng rất nhớ sư phụ ngươi, cảm ơn sư phụ ngươi đã đưa đồ đến cho ta, đây là thứ ta đang rất cần.")
                    self:EndEvent()
                    self:DispatchEventList(selfId, targetId)
                    self:SetMissionByIndex(selfId, misIndex, 0, 1)
                    self:ResetMissionEvent(selfId, self.g_MissionId, 4)
                    return 1
                else
                    self:BeginEvent(self.script_id)
                    self:AddText("Vật phẩm của ngài hiện tại không khả dụng hoặc đã bị khóa.")
                    self:EndEvent()
                    self:DispatchMissionTips(selfId)
                    return
                end
            else
                self:BeginEvent(self.script_id)
                self:AddText("Đồ ta cần ngươi mang đến chưa?")
                self:EndEvent()
                self:DispatchEventList(selfId, targetId)
                return 1
            end
        end
    elseif self:CheckAccept(selfId) > 0 then
        self:BeginEvent(self.script_id)
        self:AddText(self.g_MissionName)
        self:AddText(self.g_MissionInfo)
        self:AddText("#{M_MUBIAO}#r")
        self:DoSomethingByPlayerLevel(selfId)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
end
function event_shimen_tianshan:OnEnumerate(caller, selfId, targetId, arg, index)
    if self:IsMissionHaveDone(selfId, self.g_MissionId) then
        return
    elseif self:IsHaveMission(selfId, self.g_MissionId) then
        local strNpcName = self.g_Name
        if self:GetName(targetId) == strNpcName then
            caller:AddNumTextWithTarget(self.script_id,self.g_MissionName, 4, -1)
        end
    elseif self:CheckAccept(selfId) > 0 then
        if self:GetName(targetId) == self.g_Name then
            caller:AddNumTextWithTarget(self.script_id,self.g_MissionName, 3, -1)
        end
    end
end
function event_shimen_tianshan:OnAccept(selfId) end
function event_shimen_tianshan:CheckAccept(selfId)
    local nLevel = self:GetLevel(selfId)
    if nLevel < 10 then
        return 0
    else
        local playerMenpai = self:GetMenPai(selfId)
        if playerMenpai ~= define.MENPAI_ATTRIBUTE.MATTRIBUTE_TIANSHAN then
            return 0
        end
    end
    return 1
end
function event_shimen_tianshan:OnAbandon(selfId)
    if self:IsHaveMission(selfId, self.g_MissionId) then
        local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
        local missionType = self:GetMissionParam(selfId, misIndex, 1)
        if missionType == self.g_SubMissionTypeEnum["SongXin"] then
            local missionItem = self:GetMissionParam(selfId, misIndex,
                                                     self.g_StrForePart + 3)
            if self:HaveItem(selfId, missionItem) == 1 then
                if self:LuaFnGetAvailableItemCount(selfId, missionItem) >= 1 then
                    self:LuaFnDelAvailableItem(selfId, missionItem, 1)
                else
                    self:BeginEvent(self.script_id)
                    self:AddText("Vật phẩm của ngài hiện tại không khả dụng hoặc đã bị khóa.")
                    self:EndEvent()
                    self:DispatchMissionTips(selfId)
                    return
                end
            end
        elseif missionType == self.g_SubMissionTypeEnum["DingDianYinDao"] then
            local index = self:GetMissionParam(selfId, misIndex, 2)
            if self:HaveItem(selfId, self.g_DingDianYinDaoList[index]["itemId"]) ==
                1 then
                if self:LuaFnGetAvailableItemCount(selfId,
                                                   self.g_DingDianYinDaoList[index]["itemId"]) >=
                    1 then
                    self:LuaFnDelAvailableItem(selfId,
                                 self.g_DingDianYinDaoList[index]["itemId"], 1)
                else
                    self:BeginEvent(self.script_id)
                    self:AddText("Vật phẩm của ngài hiện tại không khả dụng hoặc đã bị khóa.")
                    self:EndEvent()
                    self:DispatchMissionTips(selfId)
                    return
                end
            end
        elseif missionType == self.g_SubMissionTypeEnum["ShouJi"] then
            local itemId = self:GetMissionParam(selfId, misIndex,
                                                self.g_StrForePart + 2)
            if self:HaveItem(selfId, itemId) == 1 then
                if self:LuaFnGetAvailableItemCount(selfId, itemId) >= 1 then
                    self:LuaFnDelAvailableItem(selfId, itemId, math.min(5, self:LuaFnGetAvailableItemCount(selfId, itemId)))
                else
                    self:BeginEvent(self.script_id)
                    self:AddText("Vật phẩm của ngài hiện tại không khả dụng hoặc đã bị khóa.")
                    self:EndEvent()
                    self:DispatchMissionTips(selfId)
                    return
                end
            end
        end
        self:DelMission(selfId, self.g_MissionId)
        self:SetMissionData(selfId, MD_SHIMEN_HUAN, 0)
    end
    self:CallScriptFunction(500501, "Abandon_Necessary", selfId)
end
function event_shimen_tianshan:OnContinue(selfId, targetId)
    if self:CheckAccept(selfId) > 0 then
        self:BeginEvent(self.script_id)
        self:AddText(self.g_MissionName)
        self:AddText(self.g_MissionComplete)
        self:EndEvent()
        self:DispatchMissionContinueInfo(selfId, targetId, self.script_id,
                                         self.g_MissionId)
    end
end
function event_shimen_tianshan:CheckSubmit(selfId)
    if (not self:IsHaveMission(selfId, self.g_MissionId)) then return 0 end
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    local missionType = self:GetMissionParam(selfId, misIndex, 1)
    if missionType == self.g_SubMissionTypeEnum["XunWu"] then
        local demandItemId = self:GetMissionParam(selfId, misIndex,
                                                  self.g_StrForePart + 1)
        if self:GetItemCount(selfId, demandItemId) <= 0 then return 0 end
        if self:IsEquipItem(demandItemId) == 1 and
            self:IsWhiteEquip(demandItemId) ~= 1 then
            return 2
        else
            return 1
        end
    elseif missionType == self.g_SubMissionTypeEnum["ShouJi"] then
        local demandItemId = self:GetMissionParam(selfId, misIndex,
                                                  self.g_StrForePart + 2)
        if self:GetItemCount(selfId, demandItemId) < 5 then
            return 0
        else
            return 1
        end
    elseif missionType == self.g_SubMissionTypeEnum["BuZhuo"] then
        return 2
    elseif self:GetMissionParam(selfId, misIndex, 0) > 0 then
        return 1
    end
    return 0
end
function event_shimen_tianshan:OnLockedTarget(selfId, objId)
    if self:GetName(objId) == self.g_Name then return 0 end
    if self:IsHaveMission(selfId, self.g_MissionId) then
        local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
        local missionType = self:GetMissionParam(selfId, misIndex, 1)
        local nNpcId, strNpcName, strNpcScene, PosX, PosZ, desc
        if missionType == self.g_SubMissionTypeEnum["KaiGuang"] then
            nNpcIndex = self:GetMissionParam(selfId, misIndex,
                                             self.g_StrForePart + 1)
            strNpcName = self.g_StrList[nNpcIndex + 1]
        else
            nNpcId = self:GetMissionParam(selfId, misIndex,
                                          self.g_StrForePart + 1)
            nNpcId, strNpcName = self:GetNpcInfoByNpcId(nNpcId)
        end
        if self:GetName(objId) == strNpcName then
            self:TAddNumText(self.script_id, self.g_MissionName, 4, -1,
                             self.script_id)
        end
    end
    return 0
end
function event_shimen_tianshan:CheckCondition_UseItem(selfId, targetId, eventId)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    local missionType = self:GetMissionParam(selfId, misIndex, 1)
    if missionType ~= self.g_SubMissionTypeEnum["DingDianYinDao"] then
        return 0
    end
    local index = self:GetMissionParam(selfId, misIndex, 2)
    local targetSceneId = self.g_DingDianYinDaoList[index]["scene"]
    if sceneId ~= targetSceneId then
        self:BeginEvent(self.script_id)
        self:AddText("Dường như không thể thi triển tại cảnh này.")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return 0
    end
    local posx1 = self.g_DingDianYinDaoList[index]["posx1"]
    local posz1 = self.g_DingDianYinDaoList[index]["posz1"]
    local posx2 = self.g_DingDianYinDaoList[index]["posx2"]
    local posz2 = self.g_DingDianYinDaoList[index]["posz2"]
    local PlayerX = self:GetHumanWorldX(selfId)
    local PlayerZ = self:GetHumanWorldZ(selfId)
    if PlayerX >= posx1 and PlayerX < posx2 then
        if PlayerZ >= posz1 and PlayerZ < posz2 then return 1 end
    end
    self:BeginEvent(self.script_id)
    self:AddText("Ngươi phải ở trong khu vực chỉ định mới có thể sử dụng!")
    self:EndEvent()
    self:DispatchMissionTips(selfId)
    return 0
end
function event_shimen_tianshan:Active_UseItem(selfId, param0)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    local missionType = self:GetMissionParam(selfId, misIndex, 1)
    if missionType ~= self.g_SubMissionTypeEnum["DingDianYinDao"] then
        return 0
    end
    local index = self:GetMissionParam(selfId, misIndex, 2)
    if self:LuaFnGetAvailableItemCount(selfId,
                                       self.g_DingDianYinDaoList[index]["itemId"]) >=
        1 then
        self:LuaFnDelAvailableItem(selfId, self.g_DingDianYinDaoList[index]["itemId"], 1)
        self:SetMissionByIndex(selfId, misIndex, 0, 1)
    else
        self:BeginEvent(self.script_id)
        self:AddText("Vật phẩm của ngài hiện tại không khả dụng hoặc đã bị khóa.")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return
    end
end
function event_shimen_tianshan:OnItemChanged(selfId, itemdataId)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    local missionType = self:GetMissionParam(selfId, misIndex, 1)
    if missionType == self.g_SubMissionTypeEnum["XunWu"] then
        local _, strItemName, _ = self:GetItemDetailInfo(itemdataId)
        local demandItemId = self:GetMissionParam(selfId, misIndex,
                                                  self.g_StrForePart + 1)
        local _, strDemandItemName, _ = self:GetItemDetailInfo(demandItemId)
        if strItemName == strDemandItemName then
            self:BeginEvent(self.script_id)
            strText = string.format("Đã nhận được %s.", strItemName)
            self:AddText(strText)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            self:SetMissionByIndex(selfId, misIndex, 0, 1)
            self:ResetMissionEvent(selfId, self.g_MissionId, 2)
        end
    elseif missionType == self.g_SubMissionTypeEnum["KaiGuang"] then
        local _, strItemName, _ = self:GetItemDetailInfo(itemdataId)
        local demandItemId = self:GetMissionParam(selfId, misIndex,
                                                  self.g_StrForePart + 2)
        local _, strDemandItemName, _ = self:GetItemDetailInfo(demandItemId)
        if strItemName == strDemandItemName then
            self:BeginEvent(self.script_id)
            strText = string.format("Đã nhận được %s.", strItemName)
            self:AddText(strText)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            self:ResetMissionEvent(selfId, self.g_MissionId, 2)
        end
    elseif missionType == self.g_SubMissionTypeEnum["ShouJi"] then
        local itemCount = self:GetItemCount(selfId, itemdataId)
        local _, strItemName, _ = self:GetItemDetailInfo(itemdataId)
        local demandItemId = self:GetMissionParam(selfId, misIndex,
                                                  self.g_StrForePart + 2)
        local _, strDemandItemName, _ = self:GetItemDetailInfo(demandItemId)
        if strItemName == strDemandItemName then
            self:BeginEvent(self.script_id)
            local _, strItemName, _ = self:GetItemDetailInfo(itemdataId)
            strText = string.format("Đã nhận được %s%d/5", strItemName, itemCount)
            self:AddText(strText)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            if itemCount >= 5 then
                self:SetMissionByIndex(selfId, misIndex, 0, 1)
                self:ResetMissionEvent(selfId, self.g_MissionId, 2)
            end
        end
    elseif missionType == self.g_SubMissionTypeEnum["killMonster"] then
        local _, _, itemId = self:GetMenpaiYiWuInfo(selfId)
        if itemdataId == itemId then
            self:SetMissionByIndex(selfId, misIndex, 0, 1)
            self:ResetMissionEvent(selfId, self.g_MissionId, 0)
            self:ResetMissionEvent(selfId, self.g_MissionId, 2)
        end
    end
end
function event_shimen_tianshan:OnPetChanged(selfId, petDataId)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    local missionType = self:GetMissionParam(selfId, misIndex, 1)
    if missionType == self.g_SubMissionTypeEnum["BuZhuo"] then
        local demandPetDataId = self:GetMissionParam(selfId, misIndex,
                                                     self.g_StrForePart + 1)
        if petDataId == demandPetDataId then
            self:BeginEvent(self.script_id)
            local strText = string.format("Đã nhận được %s.",
                                          self:GetPetName(petDataId))
            self:AddText(strText)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            self:SetMissionByIndex(selfId, misIndex, 0, 1)
            self:ResetMissionEvent(selfId, self.g_MissionId, 3)
        end
    end
end
function event_shimen_tianshan:OnSubmit(selfId, targetId, selectRadioId)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    if self:CheckSubmit(selfId, selectRadioId) >= 1 then
        local missionType = self:GetMissionParam(selfId, misIndex, 1)
        if missionType == self.g_SubMissionTypeEnum["XunWu"] then
            local demandItemId = self:GetMissionParam(selfId, misIndex,
                                                      self.g_StrForePart + 1)
            if self:LuaFnGetAvailableItemCount(selfId, demandItemId) >= 1 then
                local ret = self:LuaFnDelAvailableItem(selfId, demandItemId, 1)
                if not ret then
                    self:BeginEvent(self.script_id)
                    self:AddText(
                        "Không có đủ vật phẩm cần thiết, không thể nộp nhiệm vụ.")
                    self:EndEvent()
                    self:DispatchMissionTips(selfId)
                    return
                end
            else
                self:BeginEvent(self.script_id)
                self:AddText("Vật phẩm của ngài hiện tại không khả dụng hoặc đã bị khóa.")
                self:EndEvent()
                self:DispatchMissionTips(selfId)
                return
            end
        elseif missionType == self.g_SubMissionTypeEnum["ShouJi"] then
            local demandItemId = self:GetMissionParam(selfId, misIndex,
                                                      self.g_StrForePart + 2)
            if self:LuaFnGetAvailableItemCount(selfId, demandItemId) >= 5 then
                local ret = self:LuaFnDelAvailableItem(selfId, demandItemId, 5)
                if not ret then
                    self:BeginEvent(self.script_id)
                    self:AddText(
                        "Không có đủ vật phẩm cần thiết, không thể nộp nhiệm vụ.")
                    self:EndEvent()
                    self:DispatchMissionTips(selfId)
                    return
                end
            else
                self:BeginEvent(self.script_id)
                self:AddText("Vật phẩm của ngài hiện tại không khả dụng hoặc đã bị khóa.")
                self:EndEvent()
                self:DispatchMissionTips(selfId)
                return
            end
        end
        self:DelMission(selfId, self.g_MissionId)
        local Reward_Append, MissionRound =
            self:CallScriptFunction(500501, "OnSubmit_Necessary", selfId,
                                    targetId)
        if Reward_Append == 2 and MissionRound == 20 then
            self:CallScriptFunction(229010, "AddOtherMenpaiFubenMission",
                                    selfId, self.g_MissionId, targetId)
        end
    end
end
function event_shimen_tianshan:OnMissionCheck(selfId, npcid, scriptId, index1,
                                              index2, index3, petindex)
    if self:CheckSubmit(selfId) < 1 then return 0 end
    self:print(selfId, npcid, scriptId, index1, index2, index3, petindex)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    local missionType = self:GetMissionParam(selfId, misIndex, 1)
    if missionType == self.g_SubMissionTypeEnum["XunWu"] then
        local demandItemId = self:GetMissionParam(selfId, misIndex,
                                                  self.g_StrForePart + 1)
        local _, strDemandItemName, _ = self:GetItemDetailInfo(demandItemId)
        local find = self:CallScriptFunction(500501,
                                             "OnMissionCheck_NecessaryEx",
                                             selfId, index1, index2, index3,
                                             demandItemId)
        if find < 0 then
            self:BeginEvent(self.script_id)
            local strText = string.format(
                                "Sao ngươi chưa lấy được %s đã trở về rồi?",
                                strDemandItemName)
            self:AddText(strText)
            self:AddItemBonus(demandItemId, 1)
            self:EndEvent()
            self:DispatchEventList(selfId, -1)
            return
        end
        local ret = self:EraseItem(selfId, find)
        if ret > 0 then
            self:DelMission(selfId, self.g_MissionId)
            local Reward_Append, MissionRound =
                self:CallScriptFunction(500501, "OnSubmit_Necessary", selfId, -1)
            if Reward_Append == 2 and MissionRound == 20 then
                self:CallScriptFunction(229010, "AddOtherMenpaiFubenMission",
                                        selfId, self.g_MissionId)
            end
        else
            self:BeginEvent(self.script_id)
            local strText = string.format(
                                "Sao ngươi chưa lấy được %s đã trở về rồi?",
                                strDemandItemName)
            self:AddText(strText)
            self:AddItemBonus(demandItemId, 1)
            self:EndEvent()
            self:DispatchEventList(selfId, -1)
        end
    elseif missionType == self.g_SubMissionTypeEnum["BuZhuo"] then
        local demandPetId = self:GetMissionParam(selfId, misIndex,
                                                 self.g_StrForePart + 1)
        local petId = self:LuaFnGetPet_DataID(selfId, petindex)
        if petId == demandPetId then
            if self:LuaFnIsPetAvailable(selfId, petindex) >= 1 then
                self:LuaFnDeletePet(selfId, petindex)
                self:DelMission(selfId, self.g_MissionId)
                local Reward_Append, MissionRound =
                    self:CallScriptFunction(500501, "OnSubmit_Necessary",
                                            selfId, -1)
                if Reward_Append == 2 and MissionRound == 20 then
                    self:CallScriptFunction(229010,
                                            "AddOtherMenpaiFubenMission",
                                            selfId, self.g_MissionId)
                end
            end
        else
            self:BeginEvent(self.script_id)
            self:AddText(
                "Sao ngươi chưa lấy được Trân thú ta cần đã trở về rồi?")
            self:EndEvent()
            self:DispatchEventList(selfId, -1)
        end
    end
end
function event_shimen_tianshan:OnKillObject(selfId, objdataId, objId)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    local nMonsterId = self:GetMissionParam(selfId, misIndex,
                                            self.g_StrForePart + 3)
    local _, strMonsterName = self:GetNpcInfoByNpcId(nMonsterId)
    local monsterName = self:GetMonsterNamebyDataId(objdataId)
    if strMonsterName == monsterName then
        local num = self:GetMonsterOwnerCount(objId)
        for i = 0, num - 1 do
            local humanObjId = self:GetMonsterOwnerID(objId, i)
            if self:IsHaveMission(humanObjId, self.g_MissionId) then
                local misIndex = self:GetMissionIndexByID(humanObjId,
                                                          self.g_MissionId)
                if self:GetMissionParam(humanObjId, misIndex, 1) == self.g_SubMissionTypeEnum["killMonster"]
                    and self:GetMissionParam(humanObjId, misIndex, 0) <= 0 then
                    local demandKillCount =
                        self:GetMissionParamEx(humanObjId, misIndex, 3, 0)
                    local killedCount = self:GetMissionParamEx(humanObjId,
                                                               misIndex, 3, 1)
                    killedCount = killedCount + 1
                    self:SetMissionParamByIndexEx(humanObjId, misIndex, 3, 1,
                                                  killedCount)
                    self:BeginEvent(self.script_id)
                    local str = string.format("Đã tiêu diệt %d/%d%s",
                                              killedCount, demandKillCount,
                                              monsterName)
                    self:AddText(str)
                    self:EndEvent()
                    self:DispatchMissionTips(humanObjId)
                    if killedCount == demandKillCount then
                        self:SetMissionByIndex(humanObjId, misIndex, 0, 1)
                    end
                end
            end
        end
    end
end
function event_shimen_tianshan:HelpFinishOneHuan(selfId, targetId)
    if define.MENPAI_ATTRIBUTE.MATTRIBUTE_TIANSHAN ~= self:GetMenPai(selfId) then
        return
    end
    if (not self:IsHaveMission(selfId, self.g_MissionId)) then return end
    local ret = self:CallScriptFunction(229011,
                                        "CheckAndDepleteHelpFinishMenPaiPoint",
                                        selfId, targetId)
    if ret == 0 then return end
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    local missionType = self:GetMissionParam(selfId, misIndex, 1)
    local itemId = -1
    local itemCount = -1
    if missionType == self.g_SubMissionTypeEnum["SongXin"] then
        itemId = self:GetMissionParam(selfId, misIndex, self.g_StrForePart + 3)
        itemCount = self:LuaFnGetAvailableItemCount(selfId, itemId)
        if itemCount >= 1 then self:LuaFnDelAvailableItem(selfId, itemId, 1) end
    elseif missionType == self.g_SubMissionTypeEnum["DingDianYinDao"] then
        local index = self:GetMissionParam(selfId, misIndex, 2)
        itemId = self.g_DingDianYinDaoList[index]["itemId"]
        itemCount = self:LuaFnGetAvailableItemCount(selfId, itemId)
        if itemCount >= 1 then self:LuaFnDelAvailableItem(selfId, itemId, 1) end
    elseif missionType == self.g_SubMissionTypeEnum["ShouJi"] then
        itemId = self:GetMissionParam(selfId, misIndex, self.g_StrForePart + 2)
        itemCount = self:LuaFnGetAvailableItemCount(selfId, itemId)
        if itemCount > 5 then itemCount = 5 end
        if itemCount > 0 then self:LuaFnDelAvailableItem(selfId, itemId, itemCount) end
    end
    self:DelMission(selfId, self.g_MissionId)
    local Reward_Append, MissionRound = self:CallScriptFunction(500501,
                                                                "OnSubmit_Necessary",
                                                                selfId,
                                                                targetId, 1)
    if Reward_Append == 2 and MissionRound == 20 then
        self:CallScriptFunction(229010, "AddOtherMenpaiFubenMission", selfId,
                                self.g_MissionId, targetId)
    end
end
return require('cys_shimen').install(event_shimen_tianshan)
