local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ScriptGlobal = require "scripts.ScriptGlobal"
local event_shimen_mantuo = class("event_shimen_mantuo", script_base)
event_shimen_mantuo.script_id = 893259
event_shimen_mantuo.g_Position_X = 129
event_shimen_mantuo.g_Position_Z = 106
event_shimen_mantuo.g_SceneID = 1283
event_shimen_mantuo.g_AccomplishNPC_Name = "王安歌"
event_shimen_mantuo.g_Name = "王安歌"
event_shimen_mantuo.g_MissionId = 2126
event_shimen_mantuo.g_MissionKind = 61
event_shimen_mantuo.g_MissionLevel = 10000
event_shimen_mantuo.g_IfMissionElite = 0
event_shimen_mantuo.g_IsMissionOkFail = 0
event_shimen_mantuo.g_MissionName = "Sư môn nhiệm vụ"
event_shimen_mantuo.g_MissionInfo = ""
event_shimen_mantuo.g_MissionTarget = "%f"
event_shimen_mantuo.g_ContinueInfo = "Làm tốt lắm!"
event_shimen_mantuo.g_MissionComplete = "Chuyện ta giao cho ngươi đã làm xong chưa?"
event_shimen_mantuo.g_MissionRound = 17
event_shimen_mantuo.g_DoubleExp = 48
event_shimen_mantuo.g_AccomplishCircumstance = 1
event_shimen_mantuo.g_ShimenTypeIndex = 1
--由于接口问题只能用这种笨方法实现效果了
event_shimen_mantuo.g_MissionNpcHashTable = 
{
    [1] = {200001,200003,200004,200005,200006,200007,200008,200009,200010,200011,200012,200013,200014,200015,200016,200017,200018,200019,200020,200021,200022,200023,200024,200025,200026,200027,200028,200029,200030,200031,200032,200033,200034,200035,200036,200037,200039,200040,200041,200042,200043,200044,200045,200046,200047,200048,200049,200050,200051,200052,200053,200054,200055,200056,200057,200059,200060,200061,200062,200063,200064,200066,200067,200068,200069,200071,200072,200074,200075,200076,200077,200078,200079,200080,200081,200082,200084,200085,200087,200088,200089,200096,200097,200098,200099,200100,200101,200102,200104,300011,300021,300031,300036,300039,300040,300044,300045,300046,300048,300054,300056,300057},
    [2] = {200001,200003,200004,200005,200006,200007,200008,200009,200010,200011,200012,200013,200014,200015,200016,200017,200018,200019,200020,200021,200022,200023,200024,200025,200026,200027,200028,200029,200030,200031,200032,200033,200034,200035,200036,200037,200039,200040,200041,200042,200043,200044,200045,200046,200047,200048,200049,200050,200051,200052,200053,200054,200055,200056,200057,200059,200060,200061,200062,200063,200064,200066,200067,200068,200069,200071,200072,200074,200075,200076,200077,200078,200079,200080,200081,200082,200084,200085,200087,200088,200089,200096,200097,200098,200099,200100,200101,200102,200104,300001,300002,300003,300004,300005,300006,300007,300008,300009,300010,300011,300012,300013,300014,300015,300016,300017,300018,300019,300020,300021,300022,300023,300024,300025,300026,300027,300028,300029,300030,300031,300033,300034,300036,300037,300038,300039,300040,300041,300042,300043,300044,300045,300046,300047,300048,300049,300050,300051,300052,300053,300054,300055,300056,300057},
    [3] = {200001,200003,200004,200005,200006,200007,200008,200009,200010,200011,200012,200013,200014,200015,200016,200017,200018,200019,200020,200021,200022,200023,200024,200025,200026,200027,200028,200029,200030,200031,200032,200033,200034,200035,200036,200037,200039,200040,200041,200042,200043,200044,200045,200046,200047,200048,200049,200050,200051,200052,200053,200054,200055,200056,200057,200059,200060,200061,200062,200063,200064,200066,200067,200068,200069,200071,200072,200074,200075,200076,200077,200078,200079,200080,200081,200082,200084,200085,200087,200088,200089,200096,200097,200098,200099,200100,200101,200102,200104,200105,200106,300001,300002,300003,300004,300005,300006,300007,300008,300009,300010,300011,300012,300013,300014,300015,300016,300017,300018,300019,300020,300021,300022,300023,300024,300025,300026,300027,300028,300029,300030,300031,300033,300034,300036,300037,300038,300039,300040,300041,300042,300043,300044,300045,300046,300047,300048,300049,300050,300051,300052,300053,300054,300055,300056,300057},
    [4] = {200001,200003,200004,200005,200006,200007,200008,200009,200010,200011,200012,200013,200014,200015,200016,200017,200018,200019,200020,200021,200022,200023,200024,200025,200026,200027,200028,200029,200030,200031,200032,200033,200034,200035,200036,200037,200039,200040,200041,200042,200043,200044,200045,200046,200047,200048,200049,200050,200051,200052,200053,200054,200055,200056,200057,200059,200060,200061,200062,200063,200064,200066,200067,200068,200069,200071,200072,200074,200075,200076,200077,200078,200079,200080,200081,200082,200085,200087,200088,200089,200096,200098,200099,200100,200101,200102,200104,200105,200106,300001,300002,300003,300004,300005,300006,300007,300008,300009,300010,300011,300012,300013,300014,300015,300016,300017,300018,300019,300020,300021,300022,300023,300024,300025,300026,300027,300028,300029,300030,300031,300033,300034,300036,300037,300038,300039,300040,300041,300042,300043,300044,300045,300046,300047,300048,300049,300050,300051,300052,300053,300054,300055,300056,300057,300058,300059},
    [5] = {200006,200007,200011,200012,200013,200014,200015,200016,200017,200023,200047,200085,300001,300002,300003,300011,300012,300013,300015,300016,300017,300018,300027,300043,300049,300061,300081,300096,300111,300113,300114,300115,300116,300117,300118,300119,300120,300121,300122},
}
event_shimen_mantuo.g_Parameter_Kill_AllRandom = {
    { ["id"] = 7, ["numa"] = 3, ["numb"] = 3, ["bytenuma"] = 0, ["bytenumb"] = 1 }
}
event_shimen_mantuo.g_Parameter_Item_IDRandom = { { ["id"] = 6, ["num"] = 5 }
}
event_shimen_mantuo.g_NpcIdIndicator = { { ["key"] = 2, ["npcIdIndex"] = 5 }
, { ["key"] = 9, ["npcIdIndex"] = 7 }
}
event_shimen_mantuo.g_FormatList = {
    "Đã lâu rồi ta không gặp #R%n#W, rất đỗi nhớ thương. Món #G%s#W này là chút tâm ý của ta, xin ngươi hãy mang nó đưa tới.#r  #GMẹo：#W#r  Ngươi có thể ở Mạn Đà Sơn Trang tìm #RU Thảo#W#{_INFOAIM143,159,592,U Thảo}, nhờ nàng đưa ngươi đến các đại thành.#{MTSZSMRW_20220621_26}#r#{MTSZSMRW_20220621_21}",
    "#G%i#W của ta sao lại không thấy nữa? Nếu ngươi có thể giúp ta tìm về, ta sẽ không bạc đãi ngươi đâu.#r  #GMẹo：#W#r   Ngươi Có thể sử dụng tại Mạn Đà Sơn Trang tìm #RU Thảo#W#{_INFOAIM143,159,592,U Thảo}, hãy nhờ nàng đưa ngươi tới các đại thành thị.#{MTSZSMRW_20220621_26}#r#{MTSZSMRW_20220621_21}",
    "#G%n#W làm điều ác, ta vốn muốn ra tay dạy dỗ hắn một phen, tiếc là không có thời gian, ngươi thay ta làm được chứ?#r  #GMẹo：#W#r  Ngươi có thể ở Mạn Đà Sơn Trang tìm #RU Thảo#W#{_INFOAIM143,159,592,U Thảo}, nhờ nàng đưa ngươi đến các đại thành.#{MTSZSMRW_20220621_26}#r#{MTSZSMRW_20220621_21}",
    "Xin hãy sử dụng #Y%s#W, tiến hành gieo giống tại khu vực gần #G%s#W của #G%s#W.#r #GMẹo:#W#r Khi ngươi đến gần địa điểm gieo giống, có thể nhấn #GAlt+A#W để mở túi đồ, nhấp vào trang #G\"Nhiệm Vụ\"#W để mở túi đồ nhiệm vụ, nhấp chuột phải vào #Yhạt giống hoa#W để hoàn thành việc gieo.#r#{MTSZSMRW_20220621_26}#r#{MTSZSMRW_20220621_21}",
    "Hãy đi tìm #R%s#W, hắn sẽ dẫn ngươi đến chỗ đặt #G%s#W của bản phái.#r  #GMẹo：#W#r  Vương Điệp Quyên đang ở Mạn Đà Sơn Trang#{_INFOAIM30,197,592,Vương Điệp Quyên}.#{MTSZSMRW_20220621_26}#r#{MTSZSMRW_20220621_21}",
    "Hãy giúp ta bắt một con #G%p#W về.#B#r  #GMẹo：#W#r  #GU Thảo ở Mạn Đà Sơn Trang#{_INFOAIM143,159,592,U Thảo}#W có thể đưa ngươi đến Huyền Vũ Đảo, mà Huyền Vũ Đảo có một lối nhỏ thông tới Thánh Thú Sơn. Ngươi có thể ở Huyền Vũ Đảo hoặc trên Thánh Thú Sơn bắt Trân thú mà ta cần.#{MTSZSMRW_20220621_26}#r#{MTSZSMRW_20220621_21}",
    "Xin hãy dạo quanh Mạn Đà Sơn Trang, giúp ta tìm 5 cái #G%s#W.#r #GMẹo:#W#r Bạn Có thể sử dụng tại góc trên bên phải màn hình của bản đồ nhỏ để tìm điểm chỉ dẫn màu vàng.#{MTSZSMRW_20220621_26}#r#{MTSZSMRW_20220621_21}",
    "Hãy đưa một #G%i#W cho #R%s#W đi, xong việc ta sẽ thưởng cho ngươi!#r  #GMẹo：#W#r  Mụ mụ Nghiêm đang ở Mạn Đà Sơn Trang#{_INFOAIM228,196,592,Mụ mụ Nghiêm}.#r  Liễu Phù Phong đang ở Mạn Đà Sơn Trang#{_INFOAIM125,195,592,Liễu Phù Phong}.#r  Quan Sơn Nguyệt đang ở Mạn Đà Sơn Trang#{_INFOAIM210,158,592,Quan Sơn Nguyệt}.#{MTSZSMRW_20220621_26}#r#{MTSZSMRW_20220621_21}",
    "Đi tiêu diệt #G%s%s#W cái #G%n#W.#{MTSZSMRW_20220621_26}#r#{MTSZSMRW_20220621_21}" }
event_shimen_mantuo.g_StrForePart = 4
event_shimen_mantuo.g_ShimenPet_Index = 1
event_shimen_mantuo.g_StrList = { "Hạt giống hoa", "Thừa Lộ Đường", "Lưu Phương Điện", "Lang Hoàn Dữ", "Trú Vân Cầm Đài", "王叠涓", "Hạo Nguyệt Châu Phó bản",
    "Hương liệu", "Dầu mỡ Quỳnh Ngọc", "Gỗ đàn", "严妈妈", "柳扶风", "关山月", "Sài Miêu Hoang Dã", "Hoa Điền", "0", "1", "2",
    "3", "4", "5", "6", "7", "8", "9" }
event_shimen_mantuo.g_SubMissionTypeEnum = {
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
event_shimen_mantuo.g_DingDianYinDaoList = {
    {
        ["menpai"] = ScriptGlobal.MP_MANTUO,
        ["itemId"] = 40005048,
        ["itemName"] = "Hạt giống hoa",
        ["scene"] = 184,
        ["AreaName"] = "Thừa Lộ Đường",
        ["subAreaName"] = "Hoa Điền",
        ["posx1"] = 190,
        ["posz1"] = 161,
        ["posx2"] = 206,
        ["posz2"] = 168
    }
    ,
    {
        ["menpai"] = ScriptGlobal.MP_MANTUO,
        ["itemId"] = 40005048,
        ["itemName"] = "Hạt giống hoa",
        ["scene"] = 184,
        ["AreaName"] = "Lưu Phương Điện",
        ["subAreaName"] = "Hoa Điền",
        ["posx1"] = 110,
        ["posz1"] = 164,
        ["posx2"] = 116,
        ["posz2"] = 180
    }
    ,
    {
        ["menpai"] = ScriptGlobal.MP_MANTUO,
        ["itemId"] = 40005048,
        ["itemName"] = "Hạt giống hoa",
        ["scene"] = 184,
        ["AreaName"] = "Lang Hoàn Dữ",
        ["subAreaName"] = "Hoa Điền",
        ["posx1"] = 70,
        ["posz1"] = 25,
        ["posx2"] = 76,
        ["posz2"] = 29
    }
    ,
    {
        ["menpai"] = ScriptGlobal.MP_MANTUO,
        ["itemId"] = 40005048,
        ["itemName"] = "Hạt giống hoa",
        ["scene"] = 184,
        ["AreaName"] = "Trú Vân Cầm Đài",
        ["subAreaName"] = "Hoa Điền",
        ["posx1"] = 184,
        ["posz1"] = 78,
        ["posx2"] = 191,
        ["posz2"] = 90
    }
}
event_shimen_mantuo.g_FuBen_List = {
    {
        ["menpai"] = ScriptGlobal.MP_MANTUO,
        ["NpcName"] = "王叠涓",
        ["scene"] = 184,
        ["posx"] = 30,
        ["posz"] = 197,
        ["FubenName"] = "Hạo Nguyệt Châu Phó bản"
    }
}
event_shimen_mantuo.g_ShouJiList = {
    { ["menpai"] = ScriptGlobal.MP_MANTUO, ["scene"] = 184, ["itemId"] = 40005043, ["itemName"] = "Hương liệu" }
    , { ["menpai"] = ScriptGlobal.MP_MANTUO, ["scene"] = 184, ["itemId"] = 40005044, ["itemName"] = "Dầu mỡ Quỳnh Ngọc" }
, { ["menpai"] = ScriptGlobal.MP_MANTUO, ["scene"] = 184, ["itemId"] = 40005045, ["itemName"] = "Gỗ đàn" }
}
event_shimen_mantuo.g_AbilityNpcList = {
    {
        ["menpai"] = ScriptGlobal.MP_MANTUO,
        ["npcList"] = { { ["name"] = "严妈妈", ["scene"] = 184, ["x"] = 156, ["z"] = 99 }
        , { ["name"] = "柳扶风", ["scene"] = 184, ["x"] = 156, ["z"] = 112 }
        , { ["name"] = "关山月", ["scene"] = 184, ["x"] = 156, ["z"] = 106 }
        }
    }
}
event_shimen_mantuo.g_PetList = { { ["petDataId"] = 3000, ["petName"] = "Sài Miêu Hoang Dã", ["takeLevel"] = 10 }
}
event_shimen_mantuo.g_MenpaiYiWuList = {
    {
        ["menpainame"] = "少林",
        ["menpai"] = ScriptGlobal.MP_SHAOLIN,
        ["itemName"] = "Độ điệp của Đệ tử Thiếu Lâm",
        ["scene"] = 9,
        ["itemId"] = 40004306
    }
    ,
    {
        ["menpainame"] = "天龙",
        ["menpai"] = ScriptGlobal.MP_DALI,
        ["itemName"] = "Ấn chương của đệ tử Thiên Long",
        ["scene"] = 13,
        ["itemId"] = 40004312
    }
    ,
    {
        ["menpainame"] = "Nga Mi",
        ["menpai"] = ScriptGlobal.MP_EMEI,
        ["itemName"] = "Kiếm tuệ của đệ tử Nga My",
        ["scene"] = 15,
        ["itemId"] = 40004310
    }
    ,
    {
        ["menpainame"] = "丐帮",
        ["menpai"] = ScriptGlobal.MP_GAIBANG,
        ["itemName"] = "Túi vải của Đệ tử Cái Bang",
        ["scene"] = 10,
        ["itemId"] = 40004307
    }
    ,
    {
        ["menpainame"] = "明教",
        ["menpai"] = ScriptGlobal.MP_MINGJIAO,
        ["itemName"] = "Hỏa lệnh của Đệ tử Minh Giáo",
        ["scene"] = 11,
        ["itemId"] = 40004308
    }
    ,
    {
        ["menpainame"] = "天山",
        ["menpai"] = ScriptGlobal.MP_TIANSHAN,
        ["itemName"] = "Băng bài của đệ tử Thiên Sơn",
        ["scene"] = 17,
        ["itemId"] = 40004314
    }
    ,
    {
        ["menpainame"] = "武当",
        ["menpai"] = ScriptGlobal.MP_WUDANG,
        ["itemName"] = "Phất trần của Đệ tử Võ Đang",
        ["scene"] = 12,
        ["itemId"] = 40004309
    }
    ,
    {
        ["menpainame"] = "逍遥",
        ["menpai"] = ScriptGlobal.MP_XIAOYAO,
        ["itemName"] = "Tiêu chí của đệ tử Tiêu Dao",
        ["scene"] = 14,
        ["itemId"] = 40004313
    }
    ,
    {
        ["menpainame"] = "星宿",
        ["menpai"] = ScriptGlobal.MP_XINGSU,
        ["itemName"] = "Cổ mẫn của đệ tử Tinh Túc",
        ["scene"] = 16,
        ["itemId"] = 40004311
    }
    ,
    {
        ["menpainame"] = "曼陀山庄",
        ["menpai"] = ScriptGlobal.MP_MANTUO,
        ["itemName"] = "Cổ cầm của đệ tử Mạn Đà Sơn Trang",
        ["scene"] = 184,
        ["itemId"] = 40005046
    }
}
event_shimen_mantuo.g_RateOfDropYiWuTable = { { ["playerLevel"] = 20, ["dropRate"] = 30 }
, { ["playerLevel"] = 30, ["dropRate"] = 30 }
, { ["playerLevel"] = 40, ["dropRate"] = 25 }
, { ["playerLevel"] = 50, ["dropRate"] = 25 }
, { ["playerLevel"] = 60, ["dropRate"] = 25 }
, { ["playerLevel"] = 70, ["dropRate"] = 20 }
, { ["playerLevel"] = 80, ["dropRate"] = 20 }
, { ["playerLevel"] = 90, ["dropRate"] = 20 }
, { ["playerLevel"] = 100, ["dropRate"] = 20 }
, { ["playerLevel"] = 110, ["dropRate"] = 20 }
, { ["playerLevel"] = 120, ["dropRate"] = 20 }
, { ["playerLevel"] = 130, ["dropRate"] = 20 }
, { ["playerLevel"] = 140, ["dropRate"] = 20 }
, { ["playerLevel"] = 150, ["dropRate"] = 20 }
}
event_shimen_mantuo.g_DemandKillcountTable = { { ["levelBegin"] = 10, ["levelEnd"] = 19, ["killcount"] = 20 }
, { ["levelBegin"] = 20, ["levelEnd"] = 39, ["killcount"] = 25 }
, { ["levelBegin"] = 40, ["levelEnd"] = 59, ["killcount"] = 30 }
, { ["levelBegin"] = 60, ["levelEnd"] = 79, ["killcount"] = 35 }
, { ["levelBegin"] = 80, ["levelEnd"] = 99, ["killcount"] = 40 }
, { ["levelBegin"] = 100, ["levelEnd"] = 109, ["killcount"] = 45 }
, { ["levelBegin"] = 110, ["levelEnd"] = 119, ["killcount"] = 50 }
, { ["levelBegin"] = 120, ["levelEnd"] = 150, ["killcount"] = 55 }
}
function event_shimen_mantuo:GetMenpaiYiWuInfo(selfId)
    for i, v in pairs(self.g_MenpaiYiWuList) do
        if v["menpai"] == self:GetMenPai(selfId) then
            return v["menpainame"]
        end
    end
end

function event_shimen_mantuo:GetRateOfDropYiWu(selfId)
    local playerLevel = self:GetLevel(selfId)
    for i, v in pairs(self.g_RateOfDropYiWuTable) do
        if v["playerLevel"] >= playerLevel and playerLevel < v["playerLevel"] then
            return v["dropRate"]
        end
    end
end

function event_shimen_mantuo:GetDemandKillCount(selfId)
    local playerLevel = self:GetLevel(selfId)
    for i, v in pairs(self.g_DemandKillcountTable) do
        if playerLevel >= v["levelBegin"] and playerLevel <= v["levelEnd"] then
            return v["killcount"]
        end
    end
end

function event_shimen_mantuo:KillMonster_Accept(selfId)
    local nMonsterId, strMonsterName, strMonsterScene, nScene, nPosX, nPosZ, strDesc, nSex, level
    local playerLevel = self:GetLevel(selfId)
    local nIndex = math.random(#self.g_MissionNpcHashTable[5])
    for i = 1, 100 do
        nMonsterId, strMonsterName, strMonsterScene, nScene, nPosX, nPosZ, strDesc, nSex, level = self:GetOneMissionNpc(self.g_MissionNpcHashTable[5][nIndex])
        if self:abs(level - playerLevel) < 3 then
            break
        end
        if i == 100 then
            self:SongXin_Accept(selfId)
            return
        end
    end
    local bAdd = self:AddMission(selfId, self.g_MissionId, self.script_id, 1, 0, 1)
    if not bAdd then
        return
    end
    local killcount = self:GetDemandKillCount(selfId)
    local countpart1 = self:GetStrIndexByStrValue(self:tostring(math.floor(killcount / 10)))
    local countpart2 = self:GetStrIndexByStrValue(self:tostring(math.floor(killcount % 10)))
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    self:SetMissionByIndex(selfId, misIndex, 0, 0)
    self:SetMissionByIndex(selfId, misIndex, 1, self.g_SubMissionTypeEnum["killMonster"])
    self:SetMissionParamByIndexEx(selfId, misIndex, 3, 0, killcount)
    self:SetMissionParamByIndexEx(selfId, misIndex, 3, 1, 0)
    self:SetMissionByIndex(selfId, misIndex, self.g_StrForePart, 8)
    self:SetMissionByIndex(selfId, misIndex, self.g_StrForePart + 1, countpart1)
    self:SetMissionByIndex(selfId, misIndex, self.g_StrForePart + 2, countpart2)
    self:SetMissionByIndex(selfId, misIndex, self.g_StrForePart + 3, nMonsterId)
    self:Msg2Player(selfId, "#YTiếp nhận nhiệm vụ: Sư môn nhiệm vụ", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    self:CallScriptFunction(888888, "AskThePos", selfId, nScene, nPosX, nPosZ, strMonsterName)
    local strMissionTarget = string.format("Gần đây %s khu vực của %s thường xuyên quấy nhiễu dân cư xung quanh, đặc mệnh ngươi đi trừng trị chúng.",
        strMonsterScene, strMonsterName)
    self:AddText(strMissionTarget)
end

function event_shimen_mantuo:GetStrIndexByStrValue(stringV)
    for i, v in pairs(self.g_StrList) do
        if v == stringV then
            return i - 1
        end
    end
    local strText = string.format("Phải đăng ký %s vào StrList", stringV)
    return 0
end

function event_shimen_mantuo:GetItemDetailInfo(itemId)
    local itemId, itemName, itemDesc = self:GetItemInfoByItemId(itemId)
    if itemId == -1 then
        local strText = string.format("Vật phẩm %s không thấy trong 'MissionItem_HashTable.txt'!!", itemName)
        self:PrintStr(strText)
    end
    return itemId
end

function event_shimen_mantuo:GetMissionItemIndex(selfId)
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

function event_shimen_mantuo:GetShiMenPhaseByPlayerLevel(selfId)
    local nPlayerLevel = self:GetLevel(selfId)
    if nPlayerLevel >= 10 and nPlayerLevel < 20 then
        return 1
    elseif nPlayerLevel >= 20 and nPlayerLevel < 100 then
        return 2
    elseif nPlayerLevel >= 100 and nPlayerLevel < 120 then
        return 3
    elseif nPlayerLevel >= 120 then
        return 4
    end
end

function event_shimen_mantuo:RandomSubMission(selfId)
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

function event_shimen_mantuo:DoSomethingByPlayerLevel(selfId)
    self:CallScriptFunction(229000, "DoSomethingByPlayerLevel", selfId, self.script_id)
end

function event_shimen_mantuo:XunWu_Accept(selfId)
    local bAdd = self:AddMission(selfId, self.g_MissionId, self.script_id, 0, 0, 1)
    if not bAdd then
        return
    end
    local nitemId, strItemName, strItemDesc = self:GetOneMissionItem(self:GetMissionItemIndex(selfId))
    self:Msg2Player(selfId, "#YTiếp nhận nhiệm vụ: Sư môn nhiệm vụ", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    self:SetMissionByIndex(selfId, misIndex, 0, 0)
    self:SetMissionByIndex(selfId, misIndex, 1, self.g_SubMissionTypeEnum["XunWu"])
    self:SetMissionByIndex(selfId, misIndex, self.g_StrForePart, 1)
    self:SetMissionByIndex(selfId, misIndex, self.g_StrForePart + 1, nitemId)
    local strMissionTarget = string.format("%s của ta đâu rồi? Nếu ngươi có thể giúp ta tìm lại, ta nhất định không bạc đãi ngươi.",
        strItemName)
    self:AddText(strMissionTarget)
    local bHaveItem = self:HaveItemInBag(selfId, nitemId)
    if bHaveItem then
        self:SetMissionByIndex(selfId, misIndex, 0, 1)
        self:ResetMissionEvent(selfId, self.g_MissionId, 2)
    end
end

function event_shimen_mantuo:SongXin_Accept(selfId)
    local roll = math.random(3)
    local shoujiItemId = self.g_ShouJiList[roll]["itemId"]
    self:BeginAddItem()
    self:AddItem(shoujiItemId, 1)
    local bAdd = self:EndAddItem(selfId)
    if not bAdd then
        return
    end
    bAdd = self:AddMission(selfId, self.g_MissionId, self.script_id, 0, 0, 0)
    if not bAdd then
        return
    end
    self:AddItemListToHuman(selfId)
    self:SetMissionEvent(selfId, self.g_MissionId, 4)
    local nPhase = self:GetShiMenPhaseByPlayerLevel(selfId)
    local nIndexData = math.random(#self.g_MissionNpcHashTable[nPhase])
    local nNpcId, strNpcName, strNpcScene, nSceneId, nPosX, nPosZ, strNPCDesc = self:GetOneMissionNpc(self.g_MissionNpcHashTable[nPhase][nIndexData])
    self:Msg2Player(selfId, "#YTiếp nhận nhiệm vụ: Sư môn nhiệm vụ", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    self:CallScriptFunction(888888, "AskTheWay", selfId, nSceneId, nPosX, nPosZ, strNpcName)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    self:SetMissionByIndex(selfId, misIndex, 0, 0)
    self:SetMissionByIndex(selfId, misIndex, 1, self.g_SubMissionTypeEnum["SongXin"])
    self:SetMissionByIndex(selfId, misIndex, self.g_StrForePart, 0)
    self:SetMissionByIndex(selfId, misIndex, self.g_StrForePart + 1, nNpcId)
    local ListIndex = self:GetStrIndexByStrValue(self.g_ShouJiList[roll]["itemName"])
    self:SetMissionByIndex(selfId, misIndex, self.g_StrForePart + 2, ListIndex)
    self:SetMissionByIndex(selfId, misIndex, self.g_StrForePart + 3, shoujiItemId)
    local strMissionTarget = string.format("Đã lâu không gặp %s%s, xin ngươi giúp ta đưa cái %s này cho hắn.", strNpcScene,
        strNpcName, self.g_ShouJiList[roll]["itemName"])
    self:AddText(strMissionTarget)
end

function event_shimen_mantuo:DingDianYinDao_Accept(selfId)
    local playerMenpai = self:GetMenPai(selfId)
    local a = {}
    local index = 1
    for i, v in pairs(self.g_DingDianYinDaoList) do
        if v["menpai"] == playerMenpai then
            a[index] = i
            index    = index + 1
        end
    end
    local ct = #a
    if ct <= 0 then
        return 0
    end
    local ret = math.random(ct)
    self:BeginAddItem()
    self:AddItem(self.g_DingDianYinDaoList[a[ret]]["itemId"], 1)
    local bAdd = self:EndAddItem(selfId)
    if not bAdd then
        return
    end
    bAdd = self:AddMission(selfId, self.g_MissionId, self.script_id, 0, 0, 0)
    if not bAdd then
        return
    end
    self:AddItemListToHuman(selfId)
    self:Msg2Player(selfId, "#YNgươi nhận được một" .. self.g_DingDianYinDaoList[a[ret]]["itemName"],
        define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    local strIndex_Area = self:GetStrIndexByStrValue(self.g_DingDianYinDaoList[a[ret]]["AreaName"])
    local strIndex_Item = self:GetStrIndexByStrValue(self.g_DingDianYinDaoList[a[ret]]["itemName"])
    local strIndex_subArea = self:GetStrIndexByStrValue(self.g_DingDianYinDaoList[a[ret]]["subAreaName"])
    local x1 = self.g_DingDianYinDaoList[a[ret]]["posx1"]
    local x2 = self.g_DingDianYinDaoList[a[ret]]["posx2"]
    local z1 = self.g_DingDianYinDaoList[a[ret]]["posz1"]
    local z2 = self.g_DingDianYinDaoList[a[ret]]["posz2"]
    local scene = self.g_DingDianYinDaoList[a[ret]]["scene"]
    local tip = self.g_DingDianYinDaoList[a[ret]]["AreaName"] .. self.g_DingDianYinDaoList[a[ret]]["subAreaName"]
    local x = x1 + (x2 - x1) / 2
    local z = z1 + (z2 - z1) / 2
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    self:SetMissionByIndex(selfId, misIndex, 0, 0)
    self:SetMissionByIndex(selfId, misIndex, 1, self.g_SubMissionTypeEnum["DingDianYinDao"])
    self:SetMissionByIndex(selfId, misIndex, 2, a[ret])
    self:SetMissionByIndex(selfId, misIndex, self.g_StrForePart, 3)
    self:SetMissionByIndex(selfId, misIndex, self.g_StrForePart + 1, strIndex_Item)
    self:SetMissionByIndex(selfId, misIndex, self.g_StrForePart + 2, strIndex_Area)
    self:SetMissionByIndex(selfId, misIndex, self.g_StrForePart + 3, strIndex_subArea)
    self:Msg2Player(selfId, "#YTiếp nhận nhiệm vụ: Sư môn nhiệm vụ", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    self:CallScriptFunction(888888, "AskThePos", selfId, scene, x, z, tip)
    local strMissionTarget = string.format("Xin tới Mạn Đà Sơn Trang %s tìm %s, dùng %s để gieo trồng.",
        self.g_DingDianYinDaoList[a[ret]]["AreaName"], self.g_DingDianYinDaoList[a[ret]]["subAreaName"],
        self.g_DingDianYinDaoList[a[ret]]["itemName"])
    self:AddText(strMissionTarget)
end

function event_shimen_mantuo:FuBenZhanDou_Accept(selfId)
    local playerMenpai = self:GetMenPai(selfId)
    if playerMenpai == ScriptGlobal.MP_WUMENPAI then
        return 0
    end
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
    local bAdd = self:AddMission(selfId, self.g_MissionId, self.script_id, 0, 0, 1)
    if not bAdd then
        return
    end
    local NpcNameIndex = self:GetStrIndexByStrValue(npcName)
    local FubenNameIndex = self:GetStrIndexByStrValue(fubenName)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    self:SetMissionByIndex(selfId, misIndex, 0, 0)
    self:SetMissionByIndex(selfId, misIndex, 1, self.g_SubMissionTypeEnum["FuBenZhanDou"])
    self:SetMissionByIndex(selfId, misIndex, self.g_StrForePart, 4)
    self:SetMissionByIndex(selfId, misIndex, self.g_StrForePart + 1, NpcNameIndex)
    self:SetMissionByIndex(selfId, misIndex, self.g_StrForePart + 2, FubenNameIndex)
    self:Msg2Player(selfId, "#YTiếp nhận nhiệm vụ: Sư môn nhiệm vụ", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    self:CallScriptFunction(888888, "AskTheWay", selfId, nSceneId, posx, posz, npcName)
    local strMissionTarget = string.format("Mời ngươi đi tìm %s, hắn sẽ dẫn ngươi đi khiêu chiến %s.", npcName, fubenName)
    self:AddText(strMissionTarget)
end

function event_shimen_mantuo:BuZhuo_Accept(selfId)
    local playerLevel = self:GetLevel(selfId)
    local petId, petName, petDesc, takeLevel
    local petHashIndex = self:CallScriptFunction(229000, "GetMissionPetIndex", selfId)
    for i = 1, 100 do
        petId,petName = self:GetOneMissionPet(petHashIndex)
        takeLevel = self:GetPetTakeLevel(petId)
        if playerLevel > takeLevel then
            break
        end
        if i == 100 then
            self:SongXin_Accept(selfId)
        end
    end
    local bAdd = self:AddMission(selfId, self.g_MissionId, self.script_id, 0, 0, 0)
    if not bAdd then
        return
    end
    self:SetMissionEvent(selfId, self.g_MissionId, 3)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    self:SetMissionByIndex(selfId, misIndex, 0, 0)
    self:SetMissionByIndex(selfId, misIndex, 1, self.g_SubMissionTypeEnum["BuZhuo"])
    self:SetMissionByIndex(selfId, misIndex, self.g_StrForePart, 5)
    self:SetMissionByIndex(selfId, misIndex, self.g_StrForePart + 1, petId)
    self:Msg2Player(selfId, "#YTiếp nhận nhiệm vụ: Sư môn nhiệm vụ", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    local strMissionTarget = string.format("Mời ngươi giúp ta bắt một con %s.", petName)
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

function event_shimen_mantuo:ShouJi_Accept(selfId)
    local playerMenpai = self:GetMenPai(selfId)
    if playerMenpai == ScriptGlobal.MP_WUMENPAI then
        return 0
    end
    local a = {}
    local index = 1
    for i, v in pairs(self.g_ShouJiList) do
        if v["menpai"] == playerMenpai then
            a[index] = i
            index    = index + 1
        end
    end
    local ct = #a
    if ct <= 0 then
        return 0
    end
    local ret = math.random(ct)
    local bAdd = self:AddMission(selfId, self.g_MissionId, self.script_id, 0, 0, 1)
    if not bAdd then
        return
    end
    local itemNameIndex = self:GetStrIndexByStrValue(self.g_ShouJiList[a[ret]]["itemName"])
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    self:SetMissionByIndex(selfId, misIndex, 0, 0)
    self:SetMissionByIndex(selfId, misIndex, 1, self.g_SubMissionTypeEnum["ShouJi"])
    self:SetMissionByIndex(selfId, misIndex, self.g_StrForePart, 6)
    self:SetMissionByIndex(selfId, misIndex, self.g_StrForePart + 1, itemNameIndex)
    self:SetMissionByIndex(selfId, misIndex, self.g_StrForePart + 2, self.g_ShouJiList[a[ret]]["itemId"])
    self:Msg2Player(selfId, "#YTiếp nhận nhiệm vụ: Sư môn nhiệm vụ", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    local strMissionTarget = string.format("Mời ngươi giúp ta kiếm 5 cái %s.", self.g_ShouJiList[a[ret]]["itemName"])
    self:AddText(strMissionTarget)
end

function event_shimen_mantuo:Ability_Accept(selfId)
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
    local bAdd = self:AddMission(selfId, self.g_MissionId, self.script_id, 0, 0, 0)
    if not bAdd then
        return
    end
    self:SetMissionEvent(selfId, self.g_MissionId, 2)
    self:SetMissionEvent(selfId, self.g_MissionId, 4)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    self:SetMissionByIndex(selfId, misIndex, 0, 0)
    self:SetMissionByIndex(selfId, misIndex, 1, self.g_SubMissionTypeEnum["KaiGuang"])
    self:SetMissionByIndex(selfId, misIndex, self.g_StrForePart, 7)
    self:SetMissionByIndex(selfId, misIndex, self.g_StrForePart + 1, strNpcIndex)
    self:SetMissionByIndex(selfId, misIndex, self.g_StrForePart + 2, itemId)
    self:Msg2Player(selfId, "#YTiếp nhận nhiệm vụ: Sư môn nhiệm vụ", define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
    self:CallScriptFunction(888888, "AskTheWay", selfId, scene, x, z, strNpcName)
    local strMissionTarget = string.format("Xin hãy đưa cho %s một %s đi, ta sẽ cho ngươi thù lao!", strNpcName, itemName)
    self:AddText(strMissionTarget)
end

function event_shimen_mantuo:OnDefaultEvent(selfId, targetId, arg, index)
    if self:IsHaveMission(selfId, self.g_MissionId) then
        if self:GetName(targetId) == self.g_Name then
            self:BeginEvent(self.script_id)
            self:AddText(self.g_MissionName)
            self:AddText("Chuyện ta giao cho ngươi đã làm xong chưa?")
            self:EndEvent()
            local bDone = self:CheckSubmit(selfId)
            self:DispatchMissionDemandInfo(selfId, targetId, self.script_id, self.g_MissionId, bDone)
        else
            local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
            local demandItemId = 0
            local missionType = self:GetMissionParam(selfId, misIndex, 1)
            if missionType == self.g_SubMissionTypeEnum["SongXin"] then
                demandItemId = self:GetMissionParam(selfId, misIndex, self.g_StrForePart + 3)
            else
                demandItemId = self:GetMissionParam(selfId, misIndex, self.g_StrForePart + 2)
            end
            local bHaveItem = self:HaveItemInBag(selfId, demandItemId)
            if bHaveItem then
                if self:LuaFnGetAvailableItemCount(selfId, demandItemId) >= 1 then
                    self:DelItem(selfId, demandItemId)
                    self:BeginEvent(self.script_id)
                    self:AddText("Mời ngươi về nói với sư phụ ngươi, ta cũng rất nhớ sư phụ ngươi, cảm ơn sư phụ ngươi đã đưa đồ đến cho ta, đây là thứ ta đang rất cần.")
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
function event_shimen_mantuo:Time_Accept(selfId)
    self:AddText("Trong 15 phút ngươi không nhận nhiệm vụ mới được!")
end
function event_shimen_mantuo:MissionCount_Accept(selfId)
    self:AddText("Nhiệm vụ Sư Môn một ngày chỉ có thể làm 60 lần, vẫn nên chậm rãi thôi.")
end
function event_shimen_mantuo:OnEnumerate(caller, selfId, targetId, arg, index)
    if self:IsMissionHaveDone(selfId, self.g_MissionId) then
        return
    elseif self:IsHaveMission(selfId, self.g_MissionId) then
        local strNpcName = self.g_Name
        if self:GetName(targetId) == strNpcName then
            caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 4, -1)
        else
            caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 4, -1)
        end
    elseif self:CheckAccept(selfId) > 0 then
        if self:GetName(targetId) == self.g_Name then
            caller:AddNumTextWithTarget(self.script_id, self.g_MissionName, 3, -1)
        end
    end
end

function event_shimen_mantuo:OnAccept(selfId)
end

function event_shimen_mantuo:CheckAccept(selfId)
    local nLevel = self:GetLevel(selfId)
    if nLevel < 10 then
        return 0
    else
        local playerMenpai = self:GetMenPai(selfId)
        if playerMenpai ~= ScriptGlobal.MP_MANTUO then
            return 0
        end
    end
    return 1
end

function event_shimen_mantuo:OnAbandon(selfId)
    if self:IsHaveMission(selfId, self.g_MissionId) then
        local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
        local missionType = self:GetMissionParam(selfId, misIndex, 1)
        if missionType == self.g_SubMissionTypeEnum["SongXin"] then
            local missionItem = self:GetMissionParam(selfId, misIndex, self.g_StrForePart + 3)
            if self:HaveItemInBag(selfId, missionItem) then
                if self:LuaFnGetAvailableItemCount(selfId, missionItem) >= 1 then
                    self:DelItem(selfId, missionItem)
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
            if self:HaveItemInBag(selfId, self.g_DingDianYinDaoList[index]["itemId"]) then
                if self:LuaFnGetAvailableItemCount(selfId, self.g_DingDianYinDaoList[index]["itemId"]) >= 1 then
                    self:DelItem(selfId, self.g_DingDianYinDaoList[index]["itemId"])
                else
                    self:BeginEvent(self.script_id)
                    self:AddText("Vật phẩm của ngài hiện tại không khả dụng hoặc đã bị khóa.")
                    self:EndEvent()
                    self:DispatchMissionTips(selfId)
                    return
                end
            end
        elseif missionType == self.g_SubMissionTypeEnum["ShouJi"] then
            local itemId = self:GetMissionParam(selfId, misIndex, self.g_StrForePart + 2)
            if self:HaveItemInBag(selfId, itemId) then
                if self:LuaFnGetAvailableItemCount(selfId, itemId) >= 5 then
                    self:LuaFnDelAvailableItem(selfId, itemId, 5)
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
        self:SetMissionData(selfId, ScriptGlobal.MD_SHIMEN_HUAN, 0)
    end
    self:CallScriptFunction(500501, "Abandon_Necessary", selfId)
end

function event_shimen_mantuo:OnContinue(selfId, targetId)
    if self:CheckAccept(selfId) > 0 then
        self:BeginEvent(self.script_id)
        self:AddText(self.g_MissionName)
        self:AddText(self.g_MissionComplete)
        self:EndEvent()
        self:DispatchMissionContinueInfo(selfId, targetId, self.script_id, self.g_MissionId)
    end
end

function event_shimen_mantuo:CheckSubmit(selfId)
    if not self:IsHaveMission(selfId, self.g_MissionId) then
        return 0
    end
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    local missionType = self:GetMissionParam(selfId, misIndex, 1)
    if missionType == self.g_SubMissionTypeEnum["XunWu"] then
        local demandItemId = self:GetMissionParam(selfId, misIndex, self.g_StrForePart + 1)
        if self:GetItemCount(selfId, demandItemId) < 1 then
            return 0
        end
        if self:IsEquipItem(demandItemId) and not self:IsWhiteEquip(demandItemId) then
            return 2
        else
            return 1
        end
    elseif missionType == self.g_SubMissionTypeEnum["ShouJi"] then
        local demandItemId = self:GetMissionParam(selfId, misIndex, self.g_StrForePart + 2)
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

function event_shimen_mantuo:OnLockedTarget(selfId, objId)
    if self:GetName(objId) == self.g_Name then
        return 0
    end
    if self:IsHaveMission(selfId, self.g_MissionId) then
        local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
        local missionType = self:GetMissionParam(selfId, misIndex, 1)
        local nNpcId, strNpcName, strNpcScene, PosX, PosZ, desc
        if missionType == self.g_SubMissionTypeEnum["KaiGuang"] then
            local nNpcIndex = self:GetMissionParam(selfId, misIndex, self.g_StrForePart + 1)
            strNpcName = self.g_StrList[nNpcIndex + 1]
        else
            nNpcId = self:GetMissionParam(selfId, misIndex, self.g_StrForePart + 1)
            nNpcId = self:GetNpcInfoByNpcId(nNpcId)
        end
        if self:GetName(objId) == strNpcName then
            self:TAddNumText(self.script_id, self.g_MissionName, 4, -1, self.script_id)
        end
    end
    return 0
end

function event_shimen_mantuo:CheckCondition_UseItem(selfId, targetId, eventId)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    local missionType = self:GetMissionParam(selfId, misIndex, 1)
    local sceneId = self:GetSceneID()
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
    print("index = ",index)
    local posx1 = self.g_DingDianYinDaoList[index]["posx1"]
    local posz1 = self.g_DingDianYinDaoList[index]["posz1"]
    local posx2 = self.g_DingDianYinDaoList[index]["posx2"]
    local posz2 = self.g_DingDianYinDaoList[index]["posz2"]
    local PlayerX = self:GetHumanWorldX(selfId)
    local PlayerZ = self:GetHumanWorldZ(selfId)
    if PlayerX >= posx1 and PlayerX < posx2 then
        if PlayerZ >= posz1 and PlayerZ < posz2 then
            return 1
        end
    end
    self:BeginEvent(self.script_id)
    self:AddText("Ngươi phải ở trong khu vực chỉ định mới có thể sử dụng!")
    self:EndEvent()
    self:DispatchMissionTips(selfId)
    return 0
end

function event_shimen_mantuo:Active_UseItem(selfId, param0)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    local missionType = self:GetMissionParam(selfId, misIndex, 1)
    if missionType ~= self.g_SubMissionTypeEnum["DingDianYinDao"] then
        return 0
    end
    local index = self:GetMissionParam(selfId, misIndex, 2)
    if self:LuaFnGetAvailableItemCount(selfId, self.g_DingDianYinDaoList[index]["itemId"]) >= 1 then
        self:DelItem(selfId, self.g_DingDianYinDaoList[index]["itemId"])
        self:SetMissionByIndex(selfId, misIndex, 0, 1)
    else
        self:BeginEvent(self.script_id)
        self:AddText("Vật phẩm của ngài hiện tại không khả dụng hoặc đã bị khóa.")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return
    end
end

function event_shimen_mantuo:PickupItem(selfId, itemdataId)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    local missionType = self:GetMissionParam(selfId, misIndex, 1)
    if missionType == self.g_SubMissionTypeEnum["XunWu"] then
        local _, strItemName, _ = self:GetItemDetailInfo(itemdataId)
        local demandItemId = self:GetMissionParam(selfId, misIndex, self.g_StrForePart + 1)
        local _, strDemandItemName, _ = self:GetItemDetailInfo(demandItemId)
        if strItemName == strDemandItemName then
            self:BeginEvent(self.script_id)
            local strText = string.format("Đã nhận được %s.", strItemName)
            self:AddText(strText)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            self:SetMissionByIndex(selfId, misIndex, 0, 1)
            self:ResetMissionEvent(selfId, self.g_MissionId, 2)
        end
    elseif missionType == self.g_SubMissionTypeEnum["KaiGuang"] then
        local _, strItemName, _ = self:GetItemDetailInfo(itemdataId)
        local demandItemId = self:GetMissionParam(selfId, misIndex, self.g_StrForePart + 2)
        local _, strDemandItemName, _ = self:GetItemDetailInfo(demandItemId)
        if strItemName == strDemandItemName then
            self:BeginEvent(self.script_id)
            local strText = string.format("Đã nhận được %s.", strItemName)
            self:AddText(strText)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            self:ResetMissionEvent(selfId, self.g_MissionId, 2)
        end
    elseif missionType == self.g_SubMissionTypeEnum["ShouJi"] then
        local itemCount = self:GetItemCount(selfId, itemdataId)
        local _, strItemName, _ = self:GetItemDetailInfo(itemdataId)
        local demandItemId = self:GetMissionParam(selfId, misIndex, self.g_StrForePart + 2)
        local _, strDemandItemName, _ = self:GetItemDetailInfo(demandItemId)
        if strItemName == strDemandItemName then
            self:BeginEvent(self.script_id)
            local _, strItemName, _ = self:GetItemDetailInfo(itemdataId)
            local strText = string.format("Đã nhận được %s%d/5", strItemName, itemCount)
            self:AddText(strText)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            if itemCount == 5 then
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

function event_shimen_mantuo:OnPetChanged(selfId, petDataId)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    local missionType = self:GetMissionParam(selfId, misIndex, 1)
    if missionType == self.g_SubMissionTypeEnum["BuZhuo"] then
        local demandPetDataId = self:GetMissionParam(selfId, misIndex, self.g_StrForePart + 1)
        if petDataId == demandPetDataId then
            self:BeginEvent(self.script_id)
            local strText = string.format("Đã nhận được %s.", self:GetPetName(petDataId))
            self:AddText(strText)
            self:EndEvent()
            self:DispatchMissionTips(selfId)
            self:SetMissionByIndex(selfId, misIndex, 0, 1)
            self:ResetMissionEvent(selfId, self.g_MissionId, 3)
        end
    end
end

function event_shimen_mantuo:OnSubmit(selfId, targetId, selectRadioId)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    if self:CheckSubmit(selfId) >= 1 then
        local missionType = self:GetMissionParam(selfId, misIndex, 1)
        if missionType == self.g_SubMissionTypeEnum["XunWu"] then
            local demandItemId = self:GetMissionParam(selfId, misIndex, self.g_StrForePart + 1)
            if self:LuaFnGetAvailableItemCount(selfId, demandItemId) >= 1 then
                local ret = self:DelItem(selfId, demandItemId)
                if not ret then
                    self:BeginEvent(self.script_id)
                    self:AddText("Không có đủ vật phẩm cần thiết, không thể nộp nhiệm vụ.")
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
            local demandItemId = self:GetMissionParam(selfId, misIndex, self.g_StrForePart + 2)
            if self:LuaFnGetAvailableItemCount(selfId, demandItemId) >= 5 then
                local ret = self:LuaFnDelAvailableItem(selfId, demandItemId, 5)
                if not ret then
                    self:BeginEvent(self.script_id)
                    self:AddText("Không có đủ vật phẩm cần thiết, không thể nộp nhiệm vụ.")
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
        local Reward_Append, MissionRound = self:CallScriptFunction(500501, "OnSubmit_Necessary", selfId, targetId)
        if Reward_Append == 2 and MissionRound == 20 then
            self:CallScriptFunction(229010, "AddOtherMenpaiFubenMission", selfId, self.g_MissionId, targetId)
        end
    end
end

function event_shimen_mantuo:OnMissionCheck(selfId, npcid, scriptId, index1, index2, index3, petindex)
    if self:CheckSubmit(selfId) < 1 then
        return 0
    end
    petindex = petindex + 1
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    local missionType = self:GetMissionParam(selfId, misIndex, 1)
    if missionType == self.g_SubMissionTypeEnum["XunWu"] then
        local demandItemId = self:GetMissionParam(selfId, misIndex, self.g_StrForePart + 1)
        local _, strDemandItemName, _ = self:GetItemDetailInfo(demandItemId)
        local find = self:CallScriptFunction(500501, "OnMissionCheck_NecessaryEx", selfId, index1, index2, index3,
            demandItemId)
        if find < 0 then
            self:BeginEvent(self.script_id)
            local strText = string.format("Sao ngươi chưa lấy được %s đã trở về rồi?", strDemandItemName)
            self:AddText(strText)
            self:AddItemBonus(demandItemId, 1)
            self:EndEvent()
            self:DispatchEventList(selfId, -1)
            return
        end
        local ret = self:EraseItem(selfId, find)
        if ret then
            self:DelMission(selfId, self.g_MissionId)
            local Reward_Append, MissionRound = self:CallScriptFunction(500501, "OnSubmit_Necessary", selfId, -1)
            if Reward_Append == 2 and MissionRound == 20 then
                self:CallScriptFunction(229010, "AddOtherMenpaiFubenMission", selfId, self.g_MissionId)
            end
        else
            self:BeginEvent(self.script_id)
            local strText = string.format("Sao ngươi chưa lấy được %s đã trở về rồi?", strDemandItemName)
            self:AddText(strText)
            self:AddItemBonus(demandItemId, 1)
            self:EndEvent()
            self:DispatchEventList(selfId, -1)
        end
    elseif missionType == self.g_SubMissionTypeEnum["BuZhuo"] then
        local demandPetId = self:GetMissionParam(selfId, misIndex, self.g_StrForePart + 1)
        local petId = self:LuaFnGetPet_DataID(selfId, petindex)
        if petId == demandPetId then
           if self:LuaFnIsPetAvailable(selfId, petindex) then
                self:LuaFnDeletePet(selfId, petindex)
                self:DelMission(selfId, self.g_MissionId)
                local Reward_Append, MissionRound = self:CallScriptFunction(500501, "OnSubmit_Necessary", selfId, -1)
                if Reward_Append == 2 and MissionRound == 20 then
                    self:CallScriptFunction(229010, "AddOtherMenpaiFubenMission", selfId, self.g_MissionId)
                end
           end
        else
            self:BeginEvent(self.script_id)
            self:AddText("Sao ngươi chưa lấy được Trân thú ta cần đã trở về rồi?")
            self:EndEvent()
            self:DispatchEventList(selfId, -1)
        end
    end
end

function event_shimen_mantuo:OnKillObject(selfId, objdataId, objId)
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    local nMonsterId = self:GetMissionParam(selfId, misIndex, self.g_StrForePart + 3)
    local _, strMonsterName = self:GetNpcInfoByNpcId(nMonsterId)
    local monsterName = self:GetMonsterNamebyDataId(objdataId)
    if strMonsterName == monsterName then
        local num = self:GetMonsterOwnerCount(objId)
        for i = 0, num - 1 do
            local humanObjId = self:GetMonsterOwnerID(objId, i)
            if self:IsHaveMission(humanObjId, self.g_MissionId) then
                local misIndex = self:GetMissionIndexByID(humanObjId, self.g_MissionId)
                if not self:GetMissionParam(humanObjId, misIndex, 0) then
                    local demandKillCount = self:GetMissionParamEx(humanObjId, misIndex, 3, 0)
                    local killedCount = self:GetMissionParamEx(humanObjId, misIndex, 3, 1)
                    killedCount = killedCount + 1
                    self:SetMissionParamByIndexEx(humanObjId, misIndex, 3, 1, killedCount)
                    self:BeginEvent(self.script_id)
                    local str = string.format("Đã tiêu diệt %d/%d%s", killedCount, demandKillCount, monsterName)
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

function event_shimen_mantuo:HelpFinishOneHuan(selfId, targetId)
    if ScriptGlobal.MP_MANTUO ~= self:GetMenPai(selfId) then
        return
    end
    if not self:IsHaveMission(selfId, self.g_MissionId) then
        return
    end
    local ret = self:CallScriptFunction(229011, "CheckAndDepleteHelpFinishMenPaiPoint", selfId, targetId)
    if ret == 0 then
        return
    end
    local misIndex = self:GetMissionIndexByID(selfId, self.g_MissionId)
    local missionType = self:GetMissionParam(selfId, misIndex, 1)
    local itemId = -1
    local itemCount = -1
    if missionType == self.g_SubMissionTypeEnum["SongXin"] then
        itemId = self:GetMissionParam(selfId, misIndex, self.g_StrForePart + 3)
        itemCount = self:LuaFnGetAvailableItemCount(selfId, itemId)
        if itemCount >= 1 then
            self:DelItem(selfId, itemId)
        end
    elseif missionType == self.g_SubMissionTypeEnum["DingDianYinDao"] then
        local index = self:GetMissionParam(selfId, misIndex, 2)
        itemId = self.g_DingDianYinDaoList[index]["itemId"]
        itemCount = self:LuaFnGetAvailableItemCount(selfId, itemId)
        if itemCount >= 1 then
            self:DelItem(selfId, itemId)
        end
    elseif missionType == self.g_SubMissionTypeEnum["ShouJi"] then
        itemId = self:GetMissionParam(selfId, misIndex, self.g_StrForePart + 2)
        itemCount = self:LuaFnGetAvailableItemCount(selfId, itemId)
        if itemCount > 5 then
            itemCount = 5
        end
        if itemCount > 0 then
            self:LuaFnDelAvailableItem(selfId, itemId, itemCount)
        end
    end
    self:DelMission(selfId, self.g_MissionId)
    local Reward_Append, MissionRound = self:CallScriptFunction(500501, "OnSubmit_Necessary", selfId, targetId, 1)
    if Reward_Append == 2 and MissionRound == 20 then
        self:CallScriptFunction(229010, "AddOtherMenpaiFubenMission", selfId, self.g_MissionId, targetId)
    end
end

return event_shimen_mantuo
