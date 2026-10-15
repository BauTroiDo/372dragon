local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local efuben_1_zhenlong_huodong = class("efuben_1_zhenlong_huodong", script_base)
efuben_1_zhenlong_huodong.script_id = 401001
efuben_1_zhenlong_huodong.g_client_res = 61
efuben_1_zhenlong_huodong.g_CopySceneName = "珍珑棋局"
efuben_1_zhenlong_huodong.g_beginTime1 = 11 * 60 + 30
efuben_1_zhenlong_huodong.g_endTime1 = 14 * 60 + 30
efuben_1_zhenlong_huodong.g_beginTime2 = 0 * 60 + 30
efuben_1_zhenlong_huodong.g_endTime2 = 24 * 60
efuben_1_zhenlong_huodong.g_CopySceneType = ScriptGlobal.FUBEN_ZHENGLONG
efuben_1_zhenlong_huodong.g_limitMembers = 2
efuben_1_zhenlong_huodong.g_tickDiffTime = 1
efuben_1_zhenlong_huodong.g_closeTickCount = 30
efuben_1_zhenlong_huodong.g_startTickCount = 30
efuben_1_zhenlong_huodong.g_tipsIntervalTickCount = 5
efuben_1_zhenlong_huodong.g_NoUserTime = 300
efuben_1_zhenlong_huodong.g_Fuben_X = 40
efuben_1_zhenlong_huodong.g_Fuben_Z = 40
efuben_1_zhenlong_huodong.g_Relive_X = 45
efuben_1_zhenlong_huodong.g_Relive_Z = 40
efuben_1_zhenlong_huodong.g_Back_X_Ly = 268
efuben_1_zhenlong_huodong.g_Back_Z_Ly = 87
efuben_1_zhenlong_huodong.g_Back_X_Sz = 175
efuben_1_zhenlong_huodong.g_Back_Z_Sz = 145
efuben_1_zhenlong_huodong.g_Back_X_Dl = 275
efuben_1_zhenlong_huodong.g_Back_Z_Dl = 95
efuben_1_zhenlong_huodong.g_aToBInterval = 7 * 1000
efuben_1_zhenlong_huodong.g_bToCInterval = 60 * 1000
efuben_1_zhenlong_huodong.g_MoTypeCount = 20
efuben_1_zhenlong_huodong.g_Black_A = {
    701, 701, 701, 701, 701, 701, 701, 701, 701, 701, 701, 701, 701, 701, 701,
    701, 701, 701, 701, 701
}

efuben_1_zhenlong_huodong.g_Black_B = {
    1780, 1781, 1782, 1783, 1784, 1785, 1786, 1787, 1788, 1789, 31780, 31781,
    31782, 31783, 31784, 31785, 31786, 31787, 31788, 31789
}

efuben_1_zhenlong_huodong.g_Black_C = {
    1800, 1801, 1802, 1803, 1804, 1805, 1806, 1807, 1808, 1809, 31800, 31801,
    31802, 31803, 31804, 31805, 31806, 31807, 31808, 31809
}

efuben_1_zhenlong_huodong.g_Black_XinShou3_B = {
    12010, 12011, 12012, 12013, 12014, 12015, 12016, 12017, 12018, 12019, 42010,
    42011, 42012, 42013, 42014, 42015, 42016, 42017, 42018, 42019
}

efuben_1_zhenlong_huodong.g_Black_XinShou3_C = {
    12030, 12031, 12032, 12033, 12034, 12035, 12036, 12037, 12038, 12039, 42030,
    42031, 42032, 42033, 42034, 42035, 42036, 42037, 42038, 42039
}

efuben_1_zhenlong_huodong.g_Black_XinShou6_B = {
    12060, 12061, 12062, 12063, 12064, 12065, 12066, 12067, 12068, 12069, 42060,
    42061, 42062, 42063, 42064, 42065, 42066, 42067, 42068, 42069
}

efuben_1_zhenlong_huodong.g_Black_XinShou6_C = {
    12080, 12081, 12082, 12083, 12084, 12085, 12086, 12087, 12088, 12089, 42080,
    42081, 42082, 42083, 42084, 42085, 42086, 42087, 42088, 42089
}

efuben_1_zhenlong_huodong.g_White_A = {
    700, 700, 700, 700, 700, 700, 700, 700, 700, 700, 700, 700, 700, 700, 700,
    700, 700, 700, 700, 700
}

efuben_1_zhenlong_huodong.g_White_B = {
    1770, 1771, 1772, 1773, 1774, 1775, 1776, 1777, 1778, 1779, 31770, 31771,
    31772, 31773, 31774, 31775, 31776, 31777, 31778, 31779
}

efuben_1_zhenlong_huodong.g_White_C = {
    1790, 1791, 1792, 1793, 1794, 1795, 1796, 1797, 1798, 1799, 31790, 31791,
    31792, 31793, 31794, 31795, 31796, 31797, 31798, 31799
}

efuben_1_zhenlong_huodong.g_White_XinShou3_B = {
    12000, 12001, 12002, 12003, 12004, 12005, 12006, 12007, 12008, 12009, 42000,
    42001, 42002, 42003, 42004, 42005, 42006, 42007, 42008, 42009
}

efuben_1_zhenlong_huodong.g_White_XinShou3_C = {
    12020, 12021, 12022, 12023, 12024, 12025, 12026, 12027, 12028, 12029, 42020,
    42021, 42022, 42023, 42024, 42025, 42026, 42027, 42028, 42029
}

efuben_1_zhenlong_huodong.g_White_XinShou6_B = {
    12050, 12051, 12052, 12053, 12054, 12055, 12056, 12057, 12058, 12059, 42050,
    42051, 42052, 42053, 42054, 42055, 42056, 42057, 42058, 42059
}

efuben_1_zhenlong_huodong.g_White_XinShou6_C = {
    12070, 12071, 12072, 12073, 12074, 12075, 12076, 12077, 12078, 12079, 42070,
    42071, 42072, 42073, 42074, 42075, 42076, 42077, 42078, 42079
}

efuben_1_zhenlong_huodong.g_LastBoss = {
    1850, 1851, 1852, 1853, 1854, 1855, 1856, 1857, 1858, 1859, 31850, 31851,
    31852, 31853, 31854, 31855, 31856, 31857, 31858, 31859
}

efuben_1_zhenlong_huodong.g_LastBoss_XinShou3 = {
    12040, 12041, 12042, 12043, 12044, 12045, 12046, 12047, 12048, 12049, 42040,
    42041, 42042, 42043, 42044, 42045, 42046, 42047, 42048, 42049
}

efuben_1_zhenlong_huodong.g_LastBoss_XinShou6 = {
    12090, 12091, 12092, 12093, 12094, 12095, 12096, 12097, 12098, 12099, 42090,
    42091, 42092, 42093, 42094, 42095, 42096, 42097, 42098, 42099
}

efuben_1_zhenlong_huodong.g_Nianshous = {
    12200, 12201, 12202, 12203, 12204, 12205, 12206, 12207, 12208, 12209, 12210,
    12211
}

efuben_1_zhenlong_huodong.g_createMonsterIntervalInfoList = {
    {["topPressStep"] = 40, ["intervalTickCount"] = 9},
    {["topPressStep"] = 80, ["intervalTickCount"] = 8},
    {["topPressStep"] = 120, ["intervalTickCount"] = 7},
    {["topPressStep"] = 160, ["intervalTickCount"] = 6},
    {["topPressStep"] = 200, ["intervalTickCount"] = 5}
}

efuben_1_zhenlong_huodong.g_mStepPosListCount = 1
efuben_1_zhenlong_huodong.g_mStepPosListSize = 201
efuben_1_zhenlong_huodong.g_mStepPosLists = {}

efuben_1_zhenlong_huodong.g_mStepPosLists[1] = {
    {["x"] = 55, ["z"] = 39}, {["x"] = 60, ["z"] = 43},
    {["x"] = 57, ["z"] = 43}, {["x"] = 54, ["z"] = 46},
    {["x"] = 64, ["z"] = 39}, {["x"] = 58, ["z"] = 49},
    {["x"] = 64, ["z"] = 45}, {["x"] = 64, ["z"] = 52},
    {["x"] = 66, ["z"] = 49}, {["x"] = 70, ["z"] = 42},
    {["x"] = 69, ["z"] = 37}, {["x"] = 66, ["z"] = 43},
    {["x"] = 72, ["z"] = 46}, {["x"] = 72, ["z"] = 39},
    {["x"] = 79, ["z"] = 42}, {["x"] = 78, ["z"] = 36},
    {["x"] = 75, ["z"] = 42}, {["x"] = 78, ["z"] = 49},
    {["x"] = 82, ["z"] = 45}, {["x"] = 85, ["z"] = 39},
    {["x"] = 88, ["z"] = 49}, {["x"] = 90, ["z"] = 42},
    {["x"] = 90, ["z"] = 37}, {["x"] = 84, ["z"] = 52},
    {["x"] = 90, ["z"] = 55}, {["x"] = 82, ["z"] = 57},
    {["x"] = 87, ["z"] = 61}, {["x"] = 84, ["z"] = 55},
    {["x"] = 87, ["z"] = 57}, {["x"] = 90, ["z"] = 61},
    {["x"] = 81, ["z"] = 67}, {["x"] = 84, ["z"] = 64},
    {["x"] = 87, ["z"] = 67}, {["x"] = 81, ["z"] = 63},
    {["x"] = 90, ["z"] = 70}, {["x"] = 84, ["z"] = 73},
    {["x"] = 88, ["z"] = 70}, {["x"] = 78, ["z"] = 73},
    {["x"] = 45, ["z"] = 81}, {["x"] = 54, ["z"] = 85},
    {["x"] = 39, ["z"] = 87}, {["x"] = 45, ["z"] = 90},
    {["x"] = 39, ["z"] = 79}, {["x"] = 37, ["z"] = 84},
    {["x"] = 37, ["z"] = 91}, {["x"] = 42, ["z"] = 91},
    {["x"] = 45, ["z"] = 85}, {["x"] = 52, ["z"] = 82},
    {["x"] = 51, ["z"] = 90}, {["x"] = 48, ["z"] = 85},
    {["x"] = 43, ["z"] = 87}, {["x"] = 48, ["z"] = 88},
    {["x"] = 54, ["z"] = 91}, {["x"] = 51, ["z"] = 85},
    {["x"] = 49, ["z"] = 79}, {["x"] = 42, ["z"] = 79},
    {["x"] = 39, ["z"] = 84}, {["x"] = 37, ["z"] = 79},
    {["x"] = 42, ["z"] = 81}, {["x"] = 63, ["z"] = 81},
    {["x"] = 66, ["z"] = 88}, {["x"] = 69, ["z"] = 79},
    {["x"] = 69, ["z"] = 85}, {["x"] = 61, ["z"] = 88},
    {["x"] = 57, ["z"] = 81}, {["x"] = 63, ["z"] = 91},
    {["x"] = 70, ["z"] = 90}, {["x"] = 63, ["z"] = 85},
    {["x"] = 66, ["z"] = 81}, {["x"] = 73, ["z"] = 85},
    {["x"] = 76, ["z"] = 90}, {["x"] = 75, ["z"] = 82},
    {["x"] = 72, ["z"] = 88}, {["x"] = 69, ["z"] = 82},
    {["x"] = 75, ["z"] = 79}, {["x"] = 78, ["z"] = 85},
    {["x"] = 84, ["z"] = 82}, {["x"] = 81, ["z"] = 81},
    {["x"] = 84, ["z"] = 88}, {["x"] = 90, ["z"] = 85},
    {["x"] = 88, ["z"] = 79}, {["x"] = 81, ["z"] = 79},
    {["x"] = 78, ["z"] = 82}, {["x"] = 81, ["z"] = 88},
    {["x"] = 88, ["z"] = 91}, {["x"] = 84, ["z"] = 85},
    {["x"] = 81, ["z"] = 91}, {["x"] = 75, ["z"] = 87},
    {["x"] = 81, ["z"] = 85}, {["x"] = 78, ["z"] = 91},
    {["x"] = 87, ["z"] = 85}, {["x"] = 90, ["z"] = 91},
    {["x"] = 84, ["z"] = 91}, {["x"] = 90, ["z"] = 88},
    {["x"] = 88, ["z"] = 82}, {["x"] = 90, ["z"] = 76},
    {["x"] = 84, ["z"] = 79}, {["x"] = 78, ["z"] = 76},
    {["x"] = 81, ["z"] = 70}, {["x"] = 75, ["z"] = 73},
    {["x"] = 72, ["z"] = 79}, {["x"] = 69, ["z"] = 73},
    {["x"] = 66, ["z"] = 78}, {["x"] = 64, ["z"] = 73},
    {["x"] = 69, ["z"] = 76}, {["x"] = 72, ["z"] = 73},
    {["x"] = 75, ["z"] = 76}, {["x"] = 72, ["z"] = 82},
    {["x"] = 46, ["z"] = 64}, {["x"] = 49, ["z"] = 70},
    {["x"] = 40, ["z"] = 70}, {["x"] = 46, ["z"] = 73},
    {["x"] = 43, ["z"] = 67}, {["x"] = 40, ["z"] = 73},
    {["x"] = 45, ["z"] = 70}, {["x"] = 48, ["z"] = 76},
    {["x"] = 54, ["z"] = 73}, {["x"] = 52, ["z"] = 79},
    {["x"] = 45, ["z"] = 76}, {["x"] = 51, ["z"] = 73},
    {["x"] = 54, ["z"] = 78}, {["x"] = 64, ["z"] = 64},
    {["x"] = 70, ["z"] = 67}, {["x"] = 69, ["z"] = 61},
    {["x"] = 67, ["z"] = 69}, {["x"] = 60, ["z"] = 67},
    {["x"] = 57, ["z"] = 73}, {["x"] = 55, ["z"] = 67},
    {["x"] = 61, ["z"] = 70}, {["x"] = 57, ["z"] = 76},
    {["x"] = 63, ["z"] = 78}, {["x"] = 66, ["z"] = 76},
    {["x"] = 61, ["z"] = 73}, {["x"] = 57, ["z"] = 67},
    {["x"] = 64, ["z"] = 70}, {["x"] = 67, ["z"] = 64},
    {["x"] = 70, ["z"] = 70}, {["x"] = 63, ["z"] = 67},
    {["x"] = 69, ["z"] = 64}, {["x"] = 75, ["z"] = 67},
    {["x"] = 81, ["z"] = 73}, {["x"] = 78, ["z"] = 67},
    {["x"] = 72, ["z"] = 69}, {["x"] = 78, ["z"] = 63},
    {["x"] = 84, ["z"] = 67}, {["x"] = 88, ["z"] = 73},
    {["x"] = 81, ["z"] = 76}, {["x"] = 84, ["z"] = 70},
    {["x"] = 87, ["z"] = 76}, {["x"] = 75, ["z"] = 70},
    {["x"] = 87, ["z"] = 88}, {["x"] = 78, ["z"] = 79},
    {["x"] = 73, ["z"] = 76}, {["x"] = 75, ["z"] = 70},
    {["x"] = 75, ["z"] = 63}, {["x"] = 73, ["z"] = 66},
    {["x"] = 78, ["z"] = 70}, {["x"] = 81, ["z"] = 61},
    {["x"] = 72, ["z"] = 63}, {["x"] = 75, ["z"] = 58},
    {["x"] = 81, ["z"] = 54}, {["x"] = 78, ["z"] = 60},
    {["x"] = 75, ["z"] = 52}, {["x"] = 78, ["z"] = 54},
    {["x"] = 72, ["z"] = 57}, {["x"] = 69, ["z"] = 52},
    {["x"] = 66, ["z"] = 58}, {["x"] = 61, ["z"] = 61},
    {["x"] = 58, ["z"] = 55}, {["x"] = 64, ["z"] = 57},
    {["x"] = 67, ["z"] = 51}, {["x"] = 73, ["z"] = 49},
    {["x"] = 76, ["z"] = 55}, {["x"] = 70, ["z"] = 58},
    {["x"] = 64, ["z"] = 61}, {["x"] = 67, ["z"] = 55},
    {["x"] = 61, ["z"] = 52}, {["x"] = 57, ["z"] = 46},
    {["x"] = 64, ["z"] = 48}, {["x"] = 61, ["z"] = 55},
    {["x"] = 58, ["z"] = 60}, {["x"] = 52, ["z"] = 64},
    {["x"] = 55, ["z"] = 58}, {["x"] = 51, ["z"] = 52},
    {["x"] = 48, ["z"] = 57}, {["x"] = 42, ["z"] = 60},
    {["x"] = 37, ["z"] = 57}, {["x"] = 42, ["z"] = 54},
    {["x"] = 39, ["z"] = 60}, {["x"] = 37, ["z"] = 66},
    {["x"] = 42, ["z"] = 63}, {["x"] = 45, ["z"] = 58},
    {["x"] = 48, ["z"] = 52}, {["x"] = 51, ["z"] = 58},
    {["x"] = 54, ["z"] = 52}, {["x"] = 51, ["z"] = 46},
    {["x"] = 45, ["z"] = 52}, {["x"] = 52, ["z"] = 55},
    {["x"] = 49, ["z"] = 63}, {["x"] = 57, ["z"] = 70}, {["x"] = 63, ["z"] = 63}
}

efuben_1_zhenlong_huodong.enumerate = 0
efuben_1_zhenlong_huodong.defaultEvent = 1
efuben_1_zhenlong_huodong.g_Low_Level = 10
efuben_1_zhenlong_huodong.g_Highlvl_Limit = 50
efuben_1_zhenlong_huodong.g_Lowlvl_Limit = {["from"] = 10, ["to"] = 49}

efuben_1_zhenlong_huodong.g_LvLCur = 20
efuben_1_zhenlong_huodong.g_High_GoodBadParam = 5
efuben_1_zhenlong_huodong.g_Low_GoodBadParam = 3
efuben_1_zhenlong_huodong.g_XinShou_Exp_Mod01 = 1.1
efuben_1_zhenlong_huodong.g_XinShou_Exp_Mod02 = 2.2
efuben_1_zhenlong_huodong.g_XinShou_ExpAtu = {
    {
        ["mBengin01"] = 12010,
        ["mEnd01"] = 12019,
        ["mBengin02"] = 42010,
        ["mEnd02"] = 42019,
        ["ExpList"] = {
            262, 528, 857, 1248, 1703, 2218, 2799, 3444, 3943, 4427, 7824, 8509,
            9199, 9885, 10503, 10503, 10503, 10503, 10503, 10503
        }
    }, {
        ["mBengin01"] = 12030,
        ["mEnd01"] = 12039,
        ["mBengin02"] = 42030,
        ["mEnd02"] = 42039,
        ["ExpList"] = {
            105, 211, 342, 499, 681, 887, 1119, 1377, 1577, 1770, 1956, 2127,
            2299, 2471, 2625, 2625, 2625, 2625, 2625, 2625
        }
    }, {
        ["mBengin01"] = 12060,
        ["mEnd01"] = 12069,
        ["mBengin02"] = 42060,
        ["mEnd02"] = 42069,
        ["ExpList"] = {
            262, 528, 857, 1248, 1703, 2218, 2799, 3444, 3943, 4427, 7824, 8509,
            9199, 9885, 10503, 10503, 10503, 10503, 10503, 10503
        }
    }, {
        ["mBengin01"] = 12080,
        ["mEnd01"] = 12089,
        ["mBengin02"] = 42080,
        ["mEnd02"] = 42089,
        ["ExpList"] = {
            105, 211, 342, 499, 681, 887, 1119, 1377, 1577, 1770, 1956, 2127,
            2299, 2471, 2625, 2625, 2625, 2625, 2625, 2625
        }
    }, {
        ["mBengin01"] = 12000,
        ["mEnd01"] = 12009,
        ["mBengin02"] = 42000,
        ["mEnd02"] = 42009,
        ["ExpList"] = {
            262, 528, 857, 1248, 1703, 2218, 2799, 3444, 3943, 4427, 7824, 8509,
            9199, 9885, 10503, 10503, 10503, 10503, 10503, 10503
        }
    }, {
        ["mBengin01"] = 12020,
        ["mEnd01"] = 12029,
        ["mBengin02"] = 42020,
        ["mEnd02"] = 42029,
        ["ExpList"] = {
            105, 211, 342, 499, 681, 887, 1119, 1377, 1577, 1770, 1956, 2127,
            2299, 2471, 2625, 2625, 2625, 2625, 2625, 2625
        }
    }, {
        ["mBengin01"] = 12050,
        ["mEnd01"] = 12059,
        ["mBengin02"] = 42050,
        ["mEnd02"] = 42059,
        ["ExpList"] = {
            262, 528, 857, 1248, 1703, 2218, 2799, 3444, 3943, 4427, 7824, 8509,
            9199, 9885, 10503, 10503, 10503, 10503, 10503, 10503
        }
    }, {
        ["mBengin01"] = 12070,
        ["mEnd01"] = 12079,
        ["mBengin02"] = 42070,
        ["mEnd02"] = 42079,
        ["ExpList"] = {
            105, 211, 342, 499, 681, 887, 1119, 1377, 1577, 1770, 1956, 2127,
            2299, 2471, 2625, 2625, 2625, 2625, 2625, 2625
        }
    }, {
        ["mBengin01"] = 12040,
        ["mEnd01"] = 12049,
        ["mBengin02"] = 42040,
        ["mEnd02"] = 42049,
        ["ExpList"] = {
            5769, 10509, 16278, 23165, 31126, 40115, 50222, 61357, 69944, 78217,
            86133, 93422, 100712, 108002, 111669, 111669, 111669, 111669,
            111669, 111669
        }
    }, {
        ["mBengin01"] = 12090,
        ["mEnd01"] = 12099,
        ["mBengin02"] = 42090,
        ["mEnd02"] = 42099,
        ["ExpList"] = {
            5769, 10509, 16278, 23165, 31126, 40115, 50222, 61357, 69944, 78217,
            86133, 93422, 100712, 108002, 111669, 111669, 111669, 111669,
            111669, 111669
        }
    }
}

efuben_1_zhenlong_huodong.g_DoubleExpList = {
    {["BuffId"] = 60, ["ExpPre"] = 2.75}, {["BuffId"] = 62, ["ExpPre"] = 1.65}
}

efuben_1_zhenlong_huodong.g_ExpTeamPre = 3.2
function efuben_1_zhenlong_huodong:OnDefaultEvent(selfId, targetId)
    self:CheckAndEnterScene(selfId, targetId, self.defaultEvent)
end

function efuben_1_zhenlong_huodong:OnEnumerate(caller, selfId, targetId, arg, index)
    self:CheckAndEnterScene(selfId, targetId, self.enumerate, caller)
end

function efuben_1_zhenlong_huodong:CheckAndEnterScene(selfId, targetId, eventId, caller)
    local strOutmsg = "#{QJXXS_081211_01}"
    local bActive = self:IsActivityOpen()
    if bActive == 0 then
        if self.enumerate == eventId then
            caller:AddText(strOutmsg)
        else
            self:NotifyFailTips(selfId, strOutmsg)
        end
        return
    end
    strOutmsg = "#{ZLQJ_80926_01}"
    if self:LuaFnHasTeam(selfId) == 0 then
        if self.enumerate == eventId then
            caller:AddText(strOutmsg)
        else
            self:NotifyFailTips(selfId, strOutmsg)
        end
        return
    end
    strOutmsg =
        "Ngài không phải đội trưởng, chỉ có đội trưởng mới có thể lựa chọn có tham gia hoạt động hay không."
    if self:LuaFnIsTeamLeader(selfId) == 0 then
        if self.enumerate == eventId then
            caller:AddText(strOutmsg)
        else
            self:NotifyFailTips(selfId, strOutmsg)
        end
        return
    end
    strOutmsg = "Yêu cầu bắt buộc để tham gia Kỳ Cuộc hoạt động" .. self.g_limitMembers ..
                    "Người hoặc" .. self.g_limitMembers ..
                    "Tổ đội từ người trở lên mới có thể tiến vào, số lượng thành viên trong đội của ngài không đủ."
    local teamMemberCount = self:GetTeamMemberCount(selfId)
    if not teamMemberCount or teamMemberCount < 1 then
        if self.enumerate == eventId then
            caller:AddText(strOutmsg)
        else
            self:NotifyFailTips(selfId, strOutmsg)
        end
        return
    end
    local nearMemberCount = self:GetNearTeamCount(selfId)
    strOutmsg = "Có thành viên trong đội không ở gần, xin hãy tập hợp lại rồi tìm ta để tiến nhập hoạt động."
    if not nearMemberCount or teamMemberCount ~= nearMemberCount then
        if self.enumerate == eventId then
            caller:AddText(strOutmsg)
        else
            self:NotifyFailTips(selfId, strOutmsg)
        end
        return
    end
    if self:GetLevel(selfId) < self.g_Low_Level then
        if self.enumerate == eventId then
            caller:AddText("#{QIJU_INFO_03}")
        else
            self:NotifyFailTips(selfId, "#{QIJU_INFO_03}")
        end
        return 0
    end
    local nLowLvlCnt = 0
    for i = 1, nearMemberCount do
        local sceneMemId = self:GetNearTeamCount(selfId, i)
        if sceneMemId and sceneMemId >= 0 then
            if self:GetLevel(sceneMemId) < self.g_Low_Level then
                nLowLvlCnt = nLowLvlCnt + 1
            end
        end
    end
    local memNameList = ""
    local nCountTmp = 1
    for i = 1, nearMemberCount do
        local sceneMemId = self:GetNearTeamCount(selfId, i)
        if sceneMemId and sceneMemId >= 0 then
            if self:GetLevel(sceneMemId) < self.g_Low_Level then
                local memName = self:GetName(sceneMemId)
                if nCountTmp < nLowLvlCnt then
                    memNameList = memNameList .. memName .. "、"
                    nCountTmp = nCountTmp + 1
                else
                    memNameList = memNameList .. memName
                    break
                end
            end
        end
    end
    if nLowLvlCnt > 0 then
        local msgstr = "#{QIJU_INFO_01} " .. memNameList .. " #{QIJU_INFO_02}"
        if self.enumerate == eventId then
            caller:AddText(msgstr)
        else
            self:NotifyFailTips(selfId, msgstr)
        end
        return 0
    end
    local day = self:GetDayTime()
    local memName
    local checkCurDayMsg = "Trong đội ngũ (của"
    local checkCurDaycount = 0
    for i = 1, nearMemberCount do
        local memId = self:GetNearTeamMember(selfId, i)
        local lastDay = self:GetMissionData(memId, define.MD_ENUM.MD_LAST_QIJU_DAY)
        if lastDay == day then
            memName = self:GetName(memId)
            if checkCurDaycount == 0 then
                checkCurDayMsg = checkCurDayMsg .. memName
            else
                checkCurDayMsg = checkCurDayMsg .. "、" .. memName
            end
            checkCurDaycount = checkCurDaycount + 1
        end
    end
    if checkCurDaycount > 0 then
        checkCurDayMsg = checkCurDayMsg ..
                             ") đã hoàn thành Kỳ Cuộc hoạt động này, vì vậy đội của ngài không thể tiến vào."
        if self.enumerate == eventId then
            caller:AddText(checkCurDayMsg)
        else
            self:NotifyFailTips(selfId, checkCurDayMsg)
        end
        return
    end
    if eventId == self.enumerate then
        if self:OnXinShouCount(selfId) > 0 then
            caller:AddText("#{QJ_20080522_01}")
        else
            caller:AddText("#{QJ_20080522_02}")
        end
        caller:AddNumTextWithTarget(self.script_id, self.g_CopySceneName, 10, -1)
    elseif eventId == self.defaultEvent then
        self:BeginEvent(self.script_id)
        self:AddText(
            "#{function_help_063}#r Nếu ngươi có thể thấy hàng chữ này, chứng tỏ mạng của ngươi đã chậm đến mức xưa nay chưa từng có.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        self:MakeCopyScene(selfId, nearMemberCount)
    end
end

function efuben_1_zhenlong_huodong:MakeCopyScene(selfId, nearmembercount)
    local param0 = 4
    local param1 = 3
    local mylevel
    local level0 = 0
    local level1 = 0
    for i = 1, nearmembercount do
        local memId = self:GetNearTeamMember(selfId, i)
        local tempMemlevel = self:GetLevel(memId)
        level0 = level0 + (tempMemlevel ^ param0)
        level1 = level1 + (tempMemlevel ^ param1)
    end
    if level1 == 0 then
        mylevel = 0
    else
        mylevel = level0 / level1
    end
    local leaderguid = self:LuaFnObjId2Guid(selfId)

    local config = {}
	config.navmapname = "zhenlong.nav"					-- 地图是必须选取的，而且必须在Config/SceneInfo.ini里配置好
	config.client_res = self.g_client_res
	config.teamleader = leaderguid
	config.NoUserCloseTime = 0
	config.Timer = self.g_tickDiffTime * 1000
	config.params = {}
	config.params[0] = self.g_CopySceneType
	config.params[1] = self.script_id
	config.params[2] = 0
	config.params[3] = -1
	config.params[4] = 0
	config.params[5] = 0
	config.params[6] = self:GetTeamId( selfId )
	config.params[7] = 0
	config.params[8] = math.random(1, self.g_mStepPosListCount)
	config.params[9] = 0
    config.params[11] = 0
	config.params[12] = 0
    config.params[13] = 0
    local PlayerMaxLevel = self:GetHumanMaxLevelLimit()
    local iniLevel
    if mylevel < 10 then
        iniLevel = 10
    elseif mylevel < PlayerMaxLevel then
        iniLevel = math.floor(mylevel / 10) * 10
    else
        iniLevel = PlayerMaxLevel
    end
    if iniLevel / 10 <= self.g_MoTypeCount then
        config.params[10] = iniLevel / 10
    else
        config.params[10] = self.g_MoTypeCount
    end
    if self:OnXinShouCount(selfId) >= 2 then
        config.params[13] = 2
    elseif self:OnXinShouCount(selfId) > 0 then
        config.params[13] = 1
    end
    config.params[define.CopyScene_LevelGap] = mylevel - iniLevel
    config.monsterfile = "zhenlong_monster_" .. iniLevel .. ".ini"
	config.sn 		 = self:LuaFnGenCopySceneSN()
    local bRetSceneID = self:LuaFnCreateCopyScene(config)
    if bRetSceneID > 0 then
        self:NotifyFailTips(selfId, "Tạo phó bản thành công!")
    else
        self:NotifyFailTips(selfId,
                            "Số lượng phó bản đã đạt đến giới hạn, xin hãy thử lại sau!")
    end
end

function efuben_1_zhenlong_huodong:PlayerExit(selfId)
    if selfId then
        local oldsceneId = self:LuaFnGetCopySceneData_Param(3)
        local membercount = self:LuaFnGetCopyScene_HumanCount()
        local memId
        for i = 1, membercount do
            memId = self:LuaFnGetCopyScene_HumanObjId(i)
            if memId == selfId then
                if oldsceneId == 0 or oldsceneId == 418 or oldsceneId == 419 then
                    self:NewWorld(selfId, 0, nil, self.g_Back_X_Ly, self.g_Back_Z_Ly)
                elseif oldsceneId == 1 or oldsceneId == 518 then
                    self:NewWorld(selfId, 1, nil, self.g_Back_X_Sz, self.g_Back_Z_Sz)
                else
                    self:NewWorld(selfId, 2, nil, self.g_Back_X_Dl, self.g_Back_Z_Dl)
                end
                return
            end
        end
    end
end

function efuben_1_zhenlong_huodong:OnCopySceneReady(destsceneId)
    local sceneId = self:get_scene_id()
    local sn = self:LuaFnGetCopySceneData_Sn(destsceneId)
    self:LuaFnSetCopySceneData_Param(destsceneId, 3, sceneId)
    local leaderguid = self:LuaFnGetCopySceneData_TeamLeader(destsceneId)
    local leaderObjId = self:LuaFnGuid2ObjId(leaderguid)
    local day = self:GetDayTime()
    if not self:LuaFnIsCanDoScriptLogic(leaderObjId) then return end
    local nearMemberCount = self:GetNearTeamCount(leaderObjId)
    for i = 1, nearMemberCount do
        local memId = self:GetNearTeamMember(leaderObjId, i)
        self:SetMissionData(memId, define.MD_ENUM.MD_LAST_QIJU_DAY, day)
        self:NewWorld(memId, destsceneId, sn, self.g_Fuben_X, self.g_Fuben_Z, self.g_client_res)
        self:LuaFnAuditQuest(memId, "珍珑棋局")
    end
end

function efuben_1_zhenlong_huodong:OnPlayerEnter(selfId)
    self:SetPlayerDefaultReliveInfo(selfId, 1, 1, 0, self.g_Fuben_X,self.g_Fuben_Z)
    local teamLeaderFlag = self:LuaFnIsTeamLeader(selfId)
    if teamLeaderFlag then
        self:LuaFnSetTeamExpAllotMode(selfId, 0)
    end
end

function efuben_1_zhenlong_huodong:OnHumanDie(selfId, killerId) end

function efuben_1_zhenlong_huodong:CreateNianshou()
    local iNianshouCreateFlagIndex = 20
    if (1 == self:LuaFnGetCopySceneData_Param(iNianshouCreateFlagIndex)) then
        return
    end
    local iIdx = self:LuaFnGetCopySceneData_Param(10)
    iIdx = math.floor(iIdx)
    if (iIdx > #(self.g_Nianshous)) then
        iIdx = #(self.g_Nianshous)
    end
    local iNianshouID = self.g_Nianshous[iIdx]
    if (nil == iNianshouID) then return end
    local NsPos = {
        {44, 38}, {49, 38}, {39, 43}, {39, 48}, {56, 63}, {51, 67}, {77, 45},
        {86, 43}, {60, 82}, {57, 88}
    }

    for i = 1, 10 do
        local objId = self:LuaFnCreateMonster(iNianshouID, NsPos[i][1], NsPos[i][2], 1, 272, -1)
        local dis = self:LuaFnGetCopySceneData_Param(define.CopyScene_LevelGap)
        local actLevel = dis + iIdx * 10
        self:SetLevel(objId, actLevel)
        self:LuaFnSendSpecificImpactToUnit(objId, objId, objId, 10472, 0)
    end
    self:LuaFnSetCopySceneData_Param(iNianshouCreateFlagIndex, 1)
end

function efuben_1_zhenlong_huodong:OnCopySceneTimer(nowTime)
    local curTickCount = self:LuaFnGetCopySceneData_Param(2)
    if curTickCount == 2 then
        local nHour = self:GetHour()
        local nMinute = self:GetMinute()
        local nCurTempTime = nHour * 60 + nMinute
        local tempTimes
        if nCurTempTime < self.g_endTime1 then
            tempTimes = self.g_endTime1 - nCurTempTime
        else
            tempTimes = self.g_endTime2 - nCurTempTime
        end
        if tempTimes > 0 then
            local tempH = math.floor(tempTimes / 60)
            local tempM = math.floor(tempTimes - tempH * 60)
            local strText = "Phó bản sẽ"
            if tempH > 0 then strText = strText .. tempH .. "Giờ" end
            if tempM > 0 then strText = strText .. tempM .. "Phút" end
            strText = strText .. "đóng sau đó!"
            local membercount = self:LuaFnGetCopyScene_HumanCount()
            for i = 1, membercount do
                local memId = self:LuaFnGetCopyScene_HumanObjId(i)
                if self:LuaFnIsObjValid(memId) and
                    self:LuaFnIsCanDoScriptLogic(memId) then
                    self:NotifyFailTips(memId, strText)
                end
            end
        end
    end
    local leaveFlag = self:LuaFnGetCopySceneData_Param(4)
    if leaveFlag == 1 then
        local closeTickCount = self:LuaFnGetCopySceneData_Param(5)
        if closeTickCount >= self.g_closeTickCount then
            local oldsceneId = self:LuaFnGetCopySceneData_Param(3)
            local membercount = self:LuaFnGetCopyScene_HumanCount()
            for i = 1, membercount do
                local memId = self:LuaFnGetCopyScene_HumanObjId(i)
                if self:LuaFnIsObjValid(memId) and
                    self:LuaFnIsCanDoScriptLogic(memId) then
                    if oldsceneId == 0 or oldsceneId == 418 or oldsceneId == 419 then
                        self:NewWorld(memId, 0, nil, self.g_Back_X_Ly, self.g_Back_Z_Ly)
                    elseif oldsceneId == 1 or oldsceneId == 518 then
                        self:NewWorld(memId, 1, nil, self.g_Back_X_Sz, self.g_Back_Z_Sz)
                    else
                        self:NewWorld(memId, 2, nil, self.g_Back_X_Dl, self.g_Back_Z_Dl)
                    end
                end
            end
        elseif closeTickCount < self.g_closeTickCount then
            if math.floor(closeTickCount) ==
                math.floor(closeTickCount / self.g_tipsIntervalTickCount) *
                math.floor(self.g_tipsIntervalTickCount) then
                local membercount = self:LuaFnGetCopyScene_HumanCount()
                local memId
                local strText = string.format("Ngươi sẽ rời khỏi cảnh sau %d giây!",
                                            (self.g_closeTickCount -
                                                closeTickCount) *
                                                self.g_tickDiffTime)
                for i = 1, membercount do
                    memId = self:LuaFnGetCopyScene_HumanObjId(i)
                    if self:LuaFnIsObjValid(memId) and
                        self:LuaFnIsCanDoScriptLogic(memId) then
                        self:NotifyFailTips(memId, strText)
                    end
                end
            end
        end
        closeTickCount = closeTickCount + 1
        self:LuaFnSetCopySceneData_Param(5, closeTickCount)
    else
        local bActive = self:IsActivityOpen()
        if bActive and bActive == 1 then

        else
            self:LuaFnSetCopySceneData_Param(4, 1)
            return
        end
        if curTickCount < self.g_startTickCount then
            if math.floor(curTickCount) ==
                math.floor(curTickCount / self.g_tipsIntervalTickCount) *
                math.floor(self.g_tipsIntervalTickCount) then
                local memId
                local strText = string.format("Chiến đấu sẽ bắt đầu sau %d giây!",
                                            (self.g_startTickCount -
                                                curTickCount) *
                                                self.g_tickDiffTime)
                local membercount = self:LuaFnGetCopyScene_HumanCount()
                for i = 1, membercount do
                    memId = self:LuaFnGetCopyScene_HumanObjId(i)
                    if self:LuaFnIsObjValid(memId) and
                        self:LuaFnIsCanDoScriptLogic(memId) then
                        self:NotifyFailTips(memId, strText)
                    end
                end
            end
        elseif curTickCount == self.g_startTickCount then
            local memId
            local membercount = self:LuaFnGetCopyScene_HumanCount()
            for i = 1, membercount do
                memId = self:LuaFnGetCopyScene_HumanObjId(i)
                if self:LuaFnIsObjValid(memId) and
                    self:LuaFnIsCanDoScriptLogic(memId) then
                    self:NotifyFailTips(memId, "Chiến đấu bắt đầu rồi!")
                end
            end
        end
        if curTickCount >= self.g_startTickCount then
            local mgroup = self:LuaFnGetCopySceneData_Param(10)
            local xinshoucnt
            if mgroup > self.g_MoTypeCount then
                print("Error! ")
                mgroup = 1
            end
            local Black_A = self.g_Black_A
            local Black_B = self.g_Black_B
            local Black_C = self.g_Black_C
            local White_A = self.g_White_A
            local White_B = self.g_White_B
            local White_C = self.g_White_C
            local LastBoss = self.g_LastBoss
            xinshoucnt = self:LuaFnGetCopySceneData_Param(13)
            if xinshoucnt == 2 then
                Black_B = self.g_Black_XinShou3_B
                Black_C = self.g_Black_XinShou3_C
                White_B = self.g_White_XinShou3_B
                White_C = self.g_White_XinShou3_C
                LastBoss = self.g_LastBoss_XinShou3
            elseif xinshoucnt == 1 then
                Black_B = self.g_Black_XinShou6_B
                Black_C = self.g_Black_XinShou6_C
                White_B = self.g_White_XinShou6_B
                White_C = self.g_White_XinShou6_C
                LastBoss = self.g_LastBoss_XinShou6
            end
            local monsterCount = self:GetMonsterCount()
            for i = 1, monsterCount do
                local monsterObjId = self:GetMonsterObjID(i)
                if self:LuaFnIsCharacterLiving(monsterObjId) then
                    local monstertype = self:GetMonsterDataID(monsterObjId)
                    local monsterLevel = self:GetLevel(monsterObjId)
                    local mcreatetime = self:GetObjCreateTime(monsterObjId)
                    local PosX, PosZ = self:LuaFnGetWorldPos(monsterObjId)
                    PosX = math.floor(PosX)
                    PosZ = math.floor(PosZ)
                    if monstertype == Black_A[mgroup] then
                        if nowTime >= mcreatetime + self.g_aToBInterval then
                            self:LuaFnDeleteMonster(monsterObjId)
                            monsterObjId =
                                self:LuaFnCreateMonster(Black_B[mgroup], PosX,
                                                        PosZ, 7, 0, 401001)
                            if monsterObjId and monsterObjId > -1 then
                                self:SetLevel(monsterObjId, monsterLevel)
                            end
                        end
                    elseif monstertype == Black_B[mgroup] then
                        if nowTime >= mcreatetime + self.g_aToBInterval +
                            self.g_bToCInterval then
                            self:LuaFnDeleteMonster(monsterObjId)
                            monsterObjId =
                                self:LuaFnCreateMonster(Black_C[mgroup], PosX,
                                                        PosZ, 5, 0, 401001)
                            if monsterObjId and monsterObjId > -1 then
                                self:SetLevel(monsterObjId, monsterLevel)
                            end
                        end
                    elseif monstertype == White_A[mgroup] then
                        if nowTime >= mcreatetime + self.g_aToBInterval then
                            self:LuaFnDeleteMonster(monsterObjId)
                            monsterObjId =
                                self:LuaFnCreateMonster(White_B[mgroup], PosX,
                                                        PosZ, 7, 0, 401001)
                            if monsterObjId and monsterObjId > -1 then
                                self:SetLevel(monsterObjId, monsterLevel)
                            end
                        end
                    elseif monstertype == White_B[mgroup] then
                        if nowTime >= mcreatetime + self.g_aToBInterval +
                            self.g_bToCInterval then
                            self:LuaFnDeleteMonster(monsterObjId)
                            monsterObjId =
                                self:LuaFnCreateMonster(White_C[mgroup], PosX,
                                                        PosZ, 5, 0, 401001)
                            if monsterObjId and monsterObjId > -1 then
                                self:SetLevel(monsterObjId, monsterLevel)
                            end
                        end
                    end
                end
            end
            local pressStep = self:LuaFnGetCopySceneData_Param(9)
            if pressStep < self.g_mStepPosListSize then
                local needCreate = 0
                local curKillCount = self:LuaFnGetCopySceneData_Param(11)
                if pressStep == self.g_mStepPosListSize - 1 then
                    if curKillCount == pressStep then
                        needCreate = 1
                    end
                elseif pressStep == 0 then
                    needCreate = 1
                else
                    local createMonsterIntervalTickCount = 0
                    for _, createMonsterIntervalInfo in pairs(
                                                            self.g_createMonsterIntervalInfoList) do
                        if pressStep < createMonsterIntervalInfo["topPressStep"] then
                            createMonsterIntervalTickCount =
                                createMonsterIntervalInfo["intervalTickCount"]
                            break
                        end
                    end
                    local prevCreateMonsterTickCount =
                        self:LuaFnGetCopySceneData_Param(12)
                    if prevCreateMonsterTickCount +
                        createMonsterIntervalTickCount <= curTickCount then
                        needCreate = 1
                    end
                end
                if needCreate == 1 then
                    self:LuaFnSetCopySceneData_Param(12, curTickCount)
                    pressStep = pressStep + 1
                    self:LuaFnSetCopySceneData_Param(9, pressStep)
                    local selectQiPuIndex = self:LuaFnGetCopySceneData_Param(8)
                    local pos = self.g_mStepPosLists[selectQiPuIndex][pressStep]
                    local monsterType
                    local monsterAIType
                    local monsterAIScript
                    local isBoss
                    if pressStep == self.g_mStepPosListSize then
                        monsterType = LastBoss[mgroup]
                        monsterAIType = 14
                        monsterAIScript = 123
                        isBoss = 1
                    else
                        local whiteOrBlack = pressStep % 2
                        if whiteOrBlack == 1 then
                            monsterType = White_B[mgroup]
                        else
                            monsterType = Black_B[mgroup]
                        end
                        monsterAIType = 3
                        monsterAIScript = 0
                        isBoss = 0
                    end
                    if monsterType and monsterType ~= -1 and pos then
                        local newObjId =
                            self:LuaFnCreateMonster(monsterType, pos["x"],
                                                    pos["z"], monsterAIType,
                                                    monsterAIScript, 401001)
                        if newObjId and newObjId > -1 then
                            local LevelGap =
                                self:LuaFnGetCopySceneData_Param(define.CopyScene_LevelGap)
                            local monsterLevel = self:GetLevel(newObjId)
                            monsterLevel = LevelGap + monsterLevel
                            self:SetLevel(newObjId, monsterLevel)
                            if isBoss == 1 then
                                local szName = self:LuaFnGetName(newObjId)
                                if szName == "远古棋魂" then
                                    self:SetCharacterTitle(newObjId,
                                                           "\"Kỳ Vương\"")
                                end
                                local strText = string.format(
                                                    "#R%s: Giác ngộ đi! Các ngươi phải trả giá cho hành vi của mình.",
                                                    self:LuaFnGetName(newObjId))
                                self:MonsterTalk(-1, self.g_CopySceneName,
                                                 strText)
                                local membercount =
                                    self:LuaFnGetCopyScene_HumanCount()
                                local memId
                                for i = 1, membercount do
                                    memId = self:LuaFnGetCopyScene_HumanObjId(i)
                                    self:LuaFnSendSpecificImpactToUnit(memId,
                                                                       newObjId,
                                                                       memId,
                                                                       46, 0)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    curTickCount = curTickCount + 1
    self:LuaFnSetCopySceneData_Param(2, curTickCount)
end

function efuben_1_zhenlong_huodong:NotifyFailTips(selfId, Tip)
    self:BeginEvent(self.script_id)
    self:AddText(Tip)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function efuben_1_zhenlong_huodong:IsActivityOpen()
    local nHour = self:GetHour()
    local nMinute = self:GetMinute()
    local nCurTempTime = nHour * 60 + nMinute
    if nCurTempTime >= self.g_beginTime1 and nCurTempTime < self.g_endTime1 then
        return 1
    end
    if nCurTempTime >= self.g_beginTime2 and nCurTempTime < self.g_endTime2 then
        return 1
    end
    return 0
end

function efuben_1_zhenlong_huodong:OnDie(selfId, killerId)
    local objType = self:GetMonsterDataID(selfId)
    local mgroup = self:LuaFnGetCopySceneData_Param(10)
    local LastBoss = self.g_LastBoss
    local xinshoucnt = self:LuaFnGetCopySceneData_Param(13)
    if xinshoucnt == 2 then
        LastBoss = self.g_LastBoss_XinShou3
    elseif xinshoucnt == 1 then
        LastBoss = self.g_LastBoss_XinShou6
    end
    local playerID = killerId
    local objTypeEx = self:GetCharacterType(killerId)
    if objTypeEx == 3 then playerID = self:GetPetCreator(killerId) end
    if playerID ~= nil and playerID ~= -1 and self:OnXinShouCount(playerID) > 0 then
        local memberId = 0
        local memcount = self:LuaFnGetCopyScene_HumanCount()
        local memlevel = self:GetLevel(playerID)
        local teamLeaderFlag = 0
        teamLeaderFlag = self:LuaFnIsTeamLeader(playerID)
        if memlevel >= self.g_Highlvl_Limit then
            local nStr = ""
            local memgoodbad = self:LuaFnGetHumanGoodBadValue(playerID)
            if teamLeaderFlag == 1 then
                self:LuaFnSetHumanGoodBadValue(playerID, memgoodbad +
                                                   self.g_High_GoodBadParam)
                nStr = string.format("#{QJ_20080522_04}%d#{QJ_20080522_05}",
                                   self.g_High_GoodBadParam)
            else
                self:LuaFnSetHumanGoodBadValue(playerID, memgoodbad +
                                                   self.g_Low_GoodBadParam)
                nStr = string.format("#{QJ_20080522_04}%d#{QJ_20080522_05}",
                                   self.g_Low_GoodBadParam)
            end
            self:Msg2Player(playerID, nStr, define.ENUM_CHAT_TYPE.MSG2PLAYER_PARA)
        end
        for k = 1, memcount do
            memberId = self:LuaFnGetCopyScene_HumanObjId(k)
            local memlvl = self:GetLevel(memberId)
            if memlvl >= self.g_Lowlvl_Limit["from"] and memlvl <=
                self.g_Lowlvl_Limit["to"] then
                local MonsterLevel = self:GetLevel(selfId)
                local levelcur = memlvl - MonsterLevel
                local PlayerExpList = {}

                local ExpParam = self.g_XinShou_Exp_Mod01
                for n, ExpListInfo in pairs(self.g_XinShou_ExpAtu) do
                    if (objType and objType >= ExpListInfo["mBengin01"] and
                        objType <= ExpListInfo["mEnd01"]) or
                        (objType and objType >= ExpListInfo["mBengin02"] and
                            objType <= ExpListInfo["mEnd02"]) then
                        PlayerExpList = ExpListInfo["ExpList"]
                        break
                    end
                end
                local plyLevel = math.floor(memlvl / 10)
                local playerExp01 = 0
                if PlayerExpList and PlayerExpList[plyLevel] > 0 then
                    playerExp01 = PlayerExpList[plyLevel]
                end
                for i, ExpPreList in pairs(self.g_DoubleExpList) do
                    if self:LuaFnHaveImpactOfSpecificDataIndex(memberId,
                                                               ExpPreList["BuffId"]) ==
                        1 then
                        ExpParam = ExpPreList["ExpPre"]
                        break
                    end
                end
                local nFreeHave = self:DEGetFreeTime(memberId)
                local nMoneyHave = self:DEGetMoneyTime(memberId)
                if not self:DEIsLock(memberId) then
                    if nFreeHave > 0 or nMoneyHave > 0 then
                        ExpParam = self.g_XinShou_Exp_Mod02
                    end
                end
                playerExp01 = playerExp01 *
                                  ((1 + (memcount - 1) / self.g_ExpTeamPre) /
                                      memcount)
                local ExpSum = playerExp01 * ExpParam
                if ExpSum > 0 then
                    self:LuaFnAddExp(memberId, math.floor(ExpSum))
                end
            end
        end
    end
    if objType and objType == LastBoss[mgroup] then
        local membercount = self:LuaFnGetCopyScene_HumanCount()
        local memId
        local teamLeaderName
        local firstMemName
        local firstMemId
        for i = 1, membercount do
            memId = self:LuaFnGetCopyScene_HumanObjId(i)
            self:LuaFnAddSalaryPoint(memId, 1, 1)
            self:LuaFnAddMissionHuoYueZhi(memId, 20)
            local teamLeaderFlag = self:LuaFnIsTeamLeader(memId)
            if teamLeaderFlag and teamLeaderFlag == 1 then
                teamLeaderName = self:LuaFnGetName(memId)
            end
            if firstMemName then

            else
                firstMemId = memId
                firstMemName = self:LuaFnGetName(memId)
            end
        end
        if teamLeaderName or firstMemName then
            local bossName = "#{_BOSS26}"
            local winMessage = {}

            if teamLeaderName then
                winMessage[1] = string.format(
                                    "#W#{_INFOUSR%s}#P dẫn đội trong giai đoạn cuối của Trân Lung Kỳ Cuộc, đánh bại #G%s#P, #G%s#P trước khi lâm chung thở dài: Thế sự như Kỳ Cuộc, lần sau ta nhất định cố gắng...",
                                    teamLeaderName, bossName, bossName)
                winMessage[2] = string.format(
                                    "#G%s#P cùng #W#{_INFOUSR%s}#P dẫn dắt đội ngũ của hội chiến Trân Lung Kỳ Cuộc, vì hoa mắt mà tự thêm một mắt dẫn đến tình thế nghịch chuyển mà thua.",
                                    bossName, teamLeaderName)
                winMessage[3] = string.format(
                                    "#W#{_INFOUSR%s}#Pđang cùng #G%s#Pchuyên tâm đối diện Kỳ Cuộc, đồng đội từ phía sau chia ba đường trái, giữa, phải đánh úp về phía #G%s#P, bèn đại thắng Trân Lung Kỳ Cuộc, #G%s#P kia ngậm lệ nói: Các ngươi... các ngươi...",
                                    teamLeaderName, bossName, bossName, bossName)
                winMessage[4] = string.format(
                                    "#W#{_INFOUSR%s}#Pđang tham gia Trân Lung Kỳ Cuộc cùng #G%s#Pđang đối đầu, đồng đội ở phía sau #G%s#P hô to: \"Đại Phi, Tiểu Phi, Hổ, Hổ thượng!\". #G%s#Pcuối cùng vì tâm trí hỗn loạn mà thất bại.",
                                    teamLeaderName, bossName, bossName, bossName)
            elseif firstMemName then
                winMessage[1] = string.format(
                                    "#W#{_INFOUSR%s}#P và những người khác trong giai đoạn cuối củạ Kỳ Cuộc Trân Lung, đã đánh bại #G%s#P, #G%s#P trước khi lâm chung thở dài: Thế sự như Kỳ Cuộc ván mới, lần sau ta nhất định cố gắng...",
                                    firstMemName, bossName, bossName)
                winMessage[2] = string.format(
                                    "#G%s#P cùng #W#{_INFOUSR%s}#P và Đội người hội chiến Trân Lung Kỳ Cuộc, vì hoa mắt tự thêm một nước cờ dẫn đến tình thế đảo ngược mà thua.",
                                    bossName, firstMemName)
            end
            local messageCount = #(winMessage)
            local randIndex = math.random(1, messageCount)
            if winMessage[randIndex] then

            else
                randIndex = 1
            end
            if winMessage[randIndex] then
                self:BroadMsgByChatPipe(firstMemId, gbk.fromutf8(winMessage[randIndex]), 4)
            end
        end
    else
        for iNsIdx = 1, #(self.g_Nianshous) do
            if self.g_Nianshous[iNsIdx] == objType then return end
        end
        local curKillCount = self:LuaFnGetCopySceneData_Param(11)
        curKillCount = curKillCount + 1
        self:LuaFnSetCopySceneData_Param(11, curKillCount)
        local membercount = self:LuaFnGetCopyScene_HumanCount()
        local memId
        local strText = string.format("Ngươi đã tiêu diệt kỳ tử %d/%d", curKillCount,
                                    self.g_mStepPosListSize - 1)
        for i = 1, membercount do
            memId = self:LuaFnGetCopyScene_HumanObjId(i)
            if self:LuaFnIsObjValid(memId) and
                self:LuaFnIsCanDoScriptLogic(memId) then
                self:NotifyFailTips(memId, strText)
            end
        end
    end
end

function efuben_1_zhenlong_huodong:OnXinShouCount(selfId)
    local nHightlvlNum = 0
    local nLowlvlNum = 0
    local nTipToplvl = 0
    local nTipBotlvl = self:GetHumanMaxLevelLimit()
    local nearMemberCount = self:GetNearTeamCount(selfId)
    for i = 1, nearMemberCount do
        local sceneMemId = self:GetNearTeamMember(selfId, i)
        if sceneMemId and sceneMemId >= 0 then
            if self:GetLevel(sceneMemId) >= self.g_Highlvl_Limit then
                nHightlvlNum = nHightlvlNum + 1
            end
            if self:GetLevel(sceneMemId) >= self.g_Lowlvl_Limit["from"] and
                self:GetLevel(sceneMemId) <= self.g_Lowlvl_Limit["to"] then
                nLowlvlNum = nLowlvlNum + 1
            end
            if self:GetLevel(sceneMemId) > nTipToplvl then
                nTipToplvl = self:GetLevel(sceneMemId)
            end
            if self:GetLevel(sceneMemId) < nTipBotlvl then
                nTipBotlvl = self:GetLevel(sceneMemId)
            end
        end
    end
    if nHightlvlNum > 0 and nLowlvlNum > 0 and (nTipToplvl - nTipBotlvl) >=
        self.g_LvLCur then return nLowlvlNum end
    return 0
end

return efuben_1_zhenlong_huodong
