local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local gp_caiji = class("gp_caiji", script_base)
gp_caiji.script_id = 710000
gp_caiji.g_GPInfo = {}

gp_caiji.g_RandNum = 10000
gp_caiji.g_GPInfo[1] = {
    ["abilityId"] = define.ABILITY_CAIKUANG,
    ["name"] = "Đồng Khoáng",
    ["mainId"] = 20103001,
    ["mExtraCountOdds"] = {10000, 5000, 1200, 200, 100},
    ["associatedId"] = {20103013, 20103025, 20103037, 20103049},
    ["aOdds"] = 2500,
    ["aExtraCountOdds"] = {9000, 4000, 3000, 2000, 1000},
    ["rareId"] = -1,
    ["rOdds"] = 100,
    ["needLevel"] = 1
}

gp_caiji.g_GPInfo[2] = {
    ["abilityId"] = define.ABILITY_CAIKUANG,
    ["name"] = "Thiết Khoáng",
    ["mainId"] = 20103002,
    ["mExtraCountOdds"] = {10000, 5000, 1200, 200, 100},
    ["associatedId"] = {20103014, 20103026, 20103038, 20103050},
    ["aOdds"] = 2500,
    ["aExtraCountOdds"] = {9000, 4000, 3000, 2000, 1000},
    ["rareId"] = -1,
    ["rOdds"] = 100,
    ["needLevel"] = 2
}

gp_caiji.g_GPInfo[3] = {
    ["abilityId"] = define.ABILITY_CAIKUANG,
    ["name"] = "Mỏ bạc",
    ["mainId"] = 20103003,
    ["mExtraCountOdds"] = {10000, 5000, 1200, 200, 100},
    ["associatedId"] = {20103015, 20103027, 20103039, 20103051},
    ["aOdds"] = 2500,
    ["aExtraCountOdds"] = {9000, 4000, 3000, 2000, 1000},
    ["rareId"] = -1,
    ["rOdds"] = 100,
    ["needLevel"] = 3
}

gp_caiji.g_GPInfo[4] = {
    ["abilityId"] = define.ABILITY_CAIKUANG,
    ["name"] = "Hàn Thiết quặng",
    ["mainId"] = 20103004,
    ["mExtraCountOdds"] = {10000, 5000, 1200, 200, 100},
    ["associatedId"] = {20103016, 20103028, 20103040, 20103052},
    ["aOdds"] = 2500,
    ["aExtraCountOdds"] = {9000, 4000, 3000, 2000, 1000},
    ["rareId"] = -1,
    ["rOdds"] = 100,
    ["needLevel"] = 4
}

gp_caiji.g_GPInfo[5] = {
    ["abilityId"] = define.ABILITY_CAIKUANG,
    ["name"] = "金矿",
    ["mainId"] = 20103005,
    ["mExtraCountOdds"] = {10000, 5000, 1200, 200, 100},
    ["associatedId"] = {20103017, 20103029, 20103041, 20103053},
    ["aOdds"] = 2500,
    ["aExtraCountOdds"] = {9000, 4000, 3000, 2000, 1000},
    ["rareId"] = -1,
    ["rOdds"] = 100,
    ["needLevel"] = 5
}

gp_caiji.g_GPInfo[6] = {
    ["abilityId"] = define.ABILITY_CAIKUANG,
    ["name"] = "Thanh Đồng quặng",
    ["mainId"] = 20103006,
    ["mExtraCountOdds"] = {10000, 5000, 1200, 200, 100},
    ["associatedId"] = {20103018, 20103030, 20103042, 20103054},
    ["aOdds"] = 2500,
    ["aExtraCountOdds"] = {9000, 4000, 3000, 2000, 1000},
    ["rareId"] = -1,
    ["rOdds"] = 100,
    ["needLevel"] = 6
}

gp_caiji.g_GPInfo[7] = {
    ["abilityId"] = define.ABILITY_CAIKUANG,
    ["name"] = "Mỏ Thủy Tinh",
    ["mainId"] = 20103007,
    ["mExtraCountOdds"] = {10000, 5000, 1200, 200, 100},
    ["associatedId"] = {20103019, 20103031, 20103043, 20103055},
    ["aOdds"] = 2500,
    ["aExtraCountOdds"] = {9000, 4000, 3000, 2000, 1000},
    ["rareId"] = -1,
    ["rOdds"] = 100,
    ["needLevel"] = 7
}

gp_caiji.g_GPInfo[8] = {
    ["abilityId"] = define.ABILITY_CAIKUANG,
    ["name"] = "Mỏ Phỉ Thúy",
    ["mainId"] = 20103008,
    ["mExtraCountOdds"] = {10000, 5000, 1200, 200, 100},
    ["associatedId"] = {20103020, 20103032, 20103044, 20103056},
    ["aOdds"] = 2500,
    ["aExtraCountOdds"] = {9000, 4000, 3000, 2000, 1000},
    ["rareId"] = -1,
    ["rOdds"] = 100,
    ["needLevel"] = 8
}

gp_caiji.g_GPInfo[9] = {
    ["abilityId"] = define.ABILITY_CAIKUANG,
    ["name"] = "Chân võ khoáng",
    ["mainId"] = 20103009,
    ["mExtraCountOdds"] = {10000, 5000, 1200, 200, 100},
    ["associatedId"] = {20103021, 20103033, 20103045, 20103057},
    ["aOdds"] = 2500,
    ["aExtraCountOdds"] = {9000, 4000, 3000, 2000, 1000},
    ["rareId"] = -1,
    ["rOdds"] = 100,
    ["needLevel"] = 9
}

gp_caiji.g_GPInfo[10] = {
    ["abilityId"] = define.ABILITY_CAIKUANG,
    ["name"] = "Long Huyết khoáng",
    ["mainId"] = 20103010,
    ["mExtraCountOdds"] = {10000, 5000, 1200, 200, 100},
    ["associatedId"] = {20103022, 20103034, 20103046, 20103058},
    ["aOdds"] = 2500,
    ["aExtraCountOdds"] = {9000, 4000, 3000, 2000, 1000},
    ["rareId"] = -1,
    ["rOdds"] = 100,
    ["needLevel"] = 10
}

gp_caiji.g_GPInfo[11] = {
    ["abilityId"] = define.ABILITY_CAIKUANG,
    ["name"] = "Phượng Huyết khoáng",
    ["mainId"] = 20103011,
    ["mExtraCountOdds"] = {10000, 5000, 1200, 200, 100},
    ["associatedId"] = {20103023, 20103035, 20103047, 20103059},
    ["aOdds"] = 2500,
    ["aExtraCountOdds"] = {9000, 4000, 3000, 2000, 1000},
    ["rareId"] = -1,
    ["rOdds"] = 100,
    ["needLevel"] = 11
}

gp_caiji.g_GPInfo[12] = {
    ["abilityId"] = define.ABILITY_CAIKUANG,
    ["name"] = "Đá Nữ Oa",
    ["mainId"] = 20103012,
    ["mExtraCountOdds"] = {10000, 5000, 1200, 200, 100},
    ["associatedId"] = {20103024, 20103036, 20103048, 20103060},
    ["aOdds"] = 2500,
    ["aExtraCountOdds"] = {9000, 4000, 3000, 2000, 1000},
    ["rareId"] = -1,
    ["rOdds"] = 100,
    ["needLevel"] = 12
}

gp_caiji.g_GPInfo[13] = {
    ["abilityId"] = define.ABILITY_CAIKUANG,
    ["name"] = "Ngọc Khoáng Côn Sơn",
    ["mainId"] = 20103118,
    ["mExtraCountOdds"] = {10000, 5000, 1200, 200, 100},
    ["associatedId"] = {20103122, 20103126, 20103130, 20103134},
    ["aOdds"] = 2500,
    ["aExtraCountOdds"] = {9000, 4000, 3000, 2000, 1000},
    ["rareId"] = -1,
    ["rOdds"] = 100,
    ["needLevel"] = 9
}

gp_caiji.g_GPInfo[14] = {
    ["abilityId"] = define.ABILITY_CAIKUANG,
    ["name"] = "Khoáng Thạch Chúng Sinh",
    ["mainId"] = 20103119,
    ["mExtraCountOdds"] = {10000, 5000, 1200, 200, 100},
    ["associatedId"] = {20103123, 20103127, 20103131, 20103135},
    ["aOdds"] = 2500,
    ["aExtraCountOdds"] = {9000, 4000, 3000, 2000, 1000},
    ["rareId"] = -1,
    ["rOdds"] = 100,
    ["needLevel"] = 10
}

gp_caiji.g_GPInfo[101] = {
    ["abilityId"] = define.ABILITY_CAIYAO,
    ["name"] = "Bạch Anh",
    ["mainId"] = 20101001,
    ["mExtraCountOdds"] = {10000, 5000, 1200, 200, 100},
    ["associatedId"] = {20304005},
    ["aOdds"] = 2500,
    ["aExtraCountOdds"] = {9000, 4000, 2000, 1000},
    ["rareId"] = -1,
    ["rOdds"] = 100,
    ["needLevel"] = 1
}

gp_caiji.g_GPInfo[102] = {
    ["abilityId"] = define.ABILITY_CAIYAO,
    ["name"] = "Bồ Hoàng",
    ["mainId"] = 20101002,
    ["mExtraCountOdds"] = {10000, 5000, 1200, 200, 100},
    ["associatedId"] = {20304005},
    ["aOdds"] = 2500,
    ["aExtraCountOdds"] = {9000, 4000, 2000, 1000},
    ["rareId"] = -1,
    ["rOdds"] = 100,
    ["needLevel"] = 1
}

gp_caiji.g_GPInfo[103] = {
    ["abilityId"] = define.ABILITY_CAIYAO,
    ["name"] = "Xuyên Bối",
    ["mainId"] = 20101003,
    ["mExtraCountOdds"] = {10000, 5000, 1200, 200, 100},
    ["associatedId"] = {20304006},
    ["aOdds"] = 2500,
    ["aExtraCountOdds"] = {9000, 4000, 2000, 1000},
    ["rareId"] = -1,
    ["rOdds"] = 100,
    ["needLevel"] = 2
}

gp_caiji.g_GPInfo[104] = {
    ["abilityId"] = define.ABILITY_CAIYAO,
    ["name"] = "Nguyên Hồ",
    ["mainId"] = 20101004,
    ["mExtraCountOdds"] = {10000, 5000, 1200, 200, 100},
    ["associatedId"] = {20304006},
    ["aOdds"] = 2500,
    ["aExtraCountOdds"] = {9000, 4000, 2000, 1000},
    ["rareId"] = -1,
    ["rOdds"] = 100,
    ["needLevel"] = 2
}

gp_caiji.g_GPInfo[105] = {
    ["abilityId"] = define.ABILITY_CAIYAO,
    ["name"] = "Tỳ Bà",
    ["mainId"] = 20101005,
    ["mExtraCountOdds"] = {10000, 5000, 1200, 200, 100},
    ["associatedId"] = {20304006},
    ["aOdds"] = 2500,
    ["aExtraCountOdds"] = {9000, 4000, 2000, 1000},
    ["rareId"] = -1,
    ["rOdds"] = 100,
    ["needLevel"] = 3
}

gp_caiji.g_GPInfo[106] = {
    ["abilityId"] = define.ABILITY_CAIYAO,
    ["name"] = "甘草",
    ["mainId"] = 20101006,
    ["mExtraCountOdds"] = {10000, 5000, 1200, 200, 100},
    ["associatedId"] = {20304007},
    ["aOdds"] = 2500,
    ["aExtraCountOdds"] = {9000, 4000, 2000, 1000},
    ["rareId"] = -1,
    ["rOdds"] = 100,
    ["needLevel"] = 3
}

gp_caiji.g_GPInfo[107] = {
    ["abilityId"] = define.ABILITY_CAIYAO,
    ["name"] = "Kim Ngân Hoa",
    ["mainId"] = 20101007,
    ["mExtraCountOdds"] = {10000, 5000, 1200, 200, 100},
    ["associatedId"] = {20304007},
    ["aOdds"] = 2500,
    ["aExtraCountOdds"] = {9000, 4000, 2000, 1000},
    ["rareId"] = -1,
    ["rOdds"] = 100,
    ["needLevel"] = 3
}

gp_caiji.g_GPInfo[108] = {
    ["abilityId"] = define.ABILITY_CAIYAO,
    ["name"] = "Hoàng Cầm",
    ["mainId"] = 20101008,
    ["mExtraCountOdds"] = {10000, 5000, 1200, 200, 100},
    ["associatedId"] = {20304007},
    ["aOdds"] = 2500,
    ["aExtraCountOdds"] = {9000, 4000, 2000, 1000},
    ["rareId"] = -1,
    ["rOdds"] = 100,
    ["needLevel"] = 4
}

gp_caiji.g_GPInfo[109] = {
    ["abilityId"] = define.ABILITY_CAIYAO,
    ["name"] = "Cẩu Kỷ",
    ["mainId"] = 20101009,
    ["mExtraCountOdds"] = {10000, 5000, 1200, 200, 100},
    ["associatedId"] = {20304008},
    ["aOdds"] = 2500,
    ["aExtraCountOdds"] = {9000, 4000, 2000, 1000},
    ["rareId"] = -1,
    ["rOdds"] = 100,
    ["needLevel"] = 4
}

gp_caiji.g_GPInfo[110] = {
    ["abilityId"] = define.ABILITY_CAIYAO,
    ["name"] = "Trầm Hương",
    ["mainId"] = 20101010,
    ["mExtraCountOdds"] = {10000, 5000, 1200, 200, 100},
    ["associatedId"] = {20304008},
    ["aOdds"] = 2500,
    ["aExtraCountOdds"] = {9000, 4000, 2000, 1000},
    ["rareId"] = -1,
    ["rOdds"] = 100,
    ["needLevel"] = 4
}

gp_caiji.g_GPInfo[111] = {
    ["abilityId"] = define.ABILITY_CAIYAO,
    ["name"] = "Đỗ Trọng",
    ["mainId"] = 20101011,
    ["mExtraCountOdds"] = {10000, 5000, 1200, 200, 100},
    ["associatedId"] = {20304008},
    ["aOdds"] = 2500,
    ["aExtraCountOdds"] = {9000, 4000, 2000, 1000},
    ["rareId"] = -1,
    ["rOdds"] = 100,
    ["needLevel"] = 5
}

gp_caiji.g_GPInfo[112] = {
    ["abilityId"] = define.ABILITY_CAIYAO,
    ["name"] = "Thương Truật",
    ["mainId"] = 20101012,
    ["mExtraCountOdds"] = {10000, 5000, 1200, 200, 100},
    ["associatedId"] = {20304009},
    ["aOdds"] = 2500,
    ["aExtraCountOdds"] = {9000, 4000, 2000, 1000},
    ["rareId"] = -1,
    ["rOdds"] = 100,
    ["needLevel"] = 5
}

gp_caiji.g_GPInfo[113] = {
    ["abilityId"] = define.ABILITY_CAIYAO,
    ["name"] = "Phục Linh",
    ["mainId"] = 20101013,
    ["mExtraCountOdds"] = {10000, 5000, 1200, 200, 100},
    ["associatedId"] = {20304009},
    ["aOdds"] = 2500,
    ["aExtraCountOdds"] = {9000, 4000, 2000, 1000},
    ["rareId"] = -1,
    ["rOdds"] = 100,
    ["needLevel"] = 5
}

gp_caiji.g_GPInfo[114] = {
    ["abilityId"] = define.ABILITY_CAIYAO,
    ["name"] = "Phòng Phong",
    ["mainId"] = 20101014,
    ["mExtraCountOdds"] = {10000, 5000, 1200, 200, 100},
    ["associatedId"] = {20304009},
    ["aOdds"] = 2500,
    ["aExtraCountOdds"] = {9000, 4000, 2000, 1000},
    ["rareId"] = -1,
    ["rOdds"] = 100,
    ["needLevel"] = 6
}

gp_caiji.g_GPInfo[115] = {
    ["abilityId"] = define.ABILITY_CAIYAO,
    ["name"] = "Hương Nhu",
    ["mainId"] = 20101015,
    ["mExtraCountOdds"] = {10000, 5000, 1200, 200, 100},
    ["associatedId"] = {20304010},
    ["aOdds"] = 2500,
    ["aExtraCountOdds"] = {9000, 4000, 2000, 1000},
    ["rareId"] = -1,
    ["rOdds"] = 100,
    ["needLevel"] = 6
}

gp_caiji.g_GPInfo[116] = {
    ["abilityId"] = define.ABILITY_CAIYAO,
    ["name"] = "Hoàng Liên",
    ["mainId"] = 20101016,
    ["mExtraCountOdds"] = {10000, 5000, 1200, 200, 100},
    ["associatedId"] = {20304010},
    ["aOdds"] = 2500,
    ["aExtraCountOdds"] = {9000, 4000, 2000, 1000},
    ["rareId"] = -1,
    ["rOdds"] = 100,
    ["needLevel"] = 6
}

gp_caiji.g_GPInfo[117] = {
    ["abilityId"] = define.ABILITY_CAIYAO,
    ["name"] = "Đương Quy",
    ["mainId"] = 20101017,
    ["mExtraCountOdds"] = {10000, 5000, 1200, 200, 100},
    ["associatedId"] = {20304010},
    ["aOdds"] = 2500,
    ["aExtraCountOdds"] = {9000, 4000, 2000, 1000},
    ["rareId"] = -1,
    ["rOdds"] = 100,
    ["needLevel"] = 7
}

gp_caiji.g_GPInfo[118] = {
    ["abilityId"] = define.ABILITY_CAIYAO,
    ["name"] = "Quế Tâm",
    ["mainId"] = 20101018,
    ["mExtraCountOdds"] = {10000, 5000, 1200, 200, 100},
    ["associatedId"] = {20304011},
    ["aOdds"] = 2500,
    ["aExtraCountOdds"] = {9000, 4000, 2000, 1000},
    ["rareId"] = -1,
    ["rOdds"] = 100,
    ["needLevel"] = 7
}

gp_caiji.g_GPInfo[119] = {
    ["abilityId"] = define.ABILITY_CAIYAO,
    ["name"] = "Hương Phụ",
    ["mainId"] = 20101019,
    ["mExtraCountOdds"] = {10000, 5000, 1200, 200, 100},
    ["associatedId"] = {20304011},
    ["aOdds"] = 2500,
    ["aExtraCountOdds"] = {9000, 4000, 2000, 1000},
    ["rareId"] = -1,
    ["rOdds"] = 100,
    ["needLevel"] = 7
}

gp_caiji.g_GPInfo[120] = {
    ["abilityId"] = define.ABILITY_CAIYAO,
    ["name"] = "Hoắc Hương",
    ["mainId"] = 20101020,
    ["mExtraCountOdds"] = {10000, 5000, 1200, 200, 100},
    ["associatedId"] = {20304011},
    ["aOdds"] = 2500,
    ["aExtraCountOdds"] = {9000, 4000, 2000, 1000},
    ["rareId"] = -1,
    ["rOdds"] = 100,
    ["needLevel"] = 8
}

gp_caiji.g_GPInfo[121] = {
    ["abilityId"] = define.ABILITY_CAIYAO,
    ["name"] = "Hồi Thần Thảo",
    ["mainId"] = 20101021,
    ["mExtraCountOdds"] = {10000, 5000, 1200, 200, 100},
    ["associatedId"] = {20304012},
    ["aOdds"] = 2500,
    ["aExtraCountOdds"] = {9000, 4000, 2000, 1000},
    ["rareId"] = -1,
    ["rOdds"] = 100,
    ["needLevel"] = 8
}

gp_caiji.g_GPInfo[122] = {
    ["abilityId"] = define.ABILITY_CAIYAO,
    ["name"] = "Thủ Ô",
    ["mainId"] = 20101022,
    ["mExtraCountOdds"] = {10000, 5000, 1200, 200, 100},
    ["associatedId"] = {20304012},
    ["aOdds"] = 2500,
    ["aExtraCountOdds"] = {9000, 4000, 2000, 1000},
    ["rareId"] = -1,
    ["rOdds"] = 100,
    ["needLevel"] = 8
}

gp_caiji.g_GPInfo[123] = {
    ["abilityId"] = define.ABILITY_CAIYAO,
    ["name"] = "Đông Trùng Hạ Thảo",
    ["mainId"] = 20101023,
    ["mExtraCountOdds"] = {10000, 5000, 1200, 200, 100},
    ["associatedId"] = {20304013},
    ["aOdds"] = 2500,
    ["aExtraCountOdds"] = {9000, 4000, 2000, 1000},
    ["rareId"] = -1,
    ["rOdds"] = 100,
    ["needLevel"] = 9
}

gp_caiji.g_GPInfo[124] = {
    ["abilityId"] = define.ABILITY_CAIYAO,
    ["name"] = "Hạt Long Quỳ",
    ["mainId"] = 20101024,
    ["mExtraCountOdds"] = {10000, 5000, 1200, 200, 100},
    ["associatedId"] = {20304014},
    ["aOdds"] = 2500,
    ["aExtraCountOdds"] = {9000, 4000, 2000, 1000},
    ["rareId"] = -1,
    ["rOdds"] = 100,
    ["needLevel"] = 9
}

gp_caiji.g_GPInfo[125] = {
    ["abilityId"] = define.ABILITY_CAIYAO,
    ["name"] = "Tượng Bối",
    ["mainId"] = 20101025,
    ["mExtraCountOdds"] = {10000, 5000, 1200, 200, 100},
    ["associatedId"] = {20304013, 20304014},
    ["aOdds"] = 2500,
    ["aExtraCountOdds"] = {9000, 4000, 2000, 1000},
    ["rareId"] = -1,
    ["rOdds"] = 100,
    ["needLevel"] = 10
}

gp_caiji.g_GPInfo[126] = {
    ["abilityId"] = define.ABILITY_CAIYAO,
    ["name"] = "Nhân Sâm",
    ["mainId"] = 20101026,
    ["mExtraCountOdds"] = {10000, 5000, 1200, 200, 100},
    ["associatedId"] = {20304013, 20304014},
    ["aOdds"] = 2500,
    ["aExtraCountOdds"] = {9000, 4000, 2000, 1000},
    ["rareId"] = -1,
    ["rOdds"] = 100,
    ["needLevel"] = 10
}

gp_caiji.g_GPInfo[127] = {
    ["abilityId"] = define.ABILITY_CAIYAO,
    ["name"] = "Linh Chi",
    ["mainId"] = 20101027,
    ["mExtraCountOdds"] = {10000, 5000, 1200, 200, 100},
    ["associatedId"] = {20304016},
    ["aOdds"] = 2500,
    ["aExtraCountOdds"] = {9000, 4000, 2000, 1000},
    ["rareId"] = -1,
    ["rOdds"] = 100,
    ["needLevel"] = 11
}

gp_caiji.g_GPInfo[128] = {
    ["abilityId"] = define.ABILITY_CAIYAO,
    ["name"] = "Tuân Thảo",
    ["mainId"] = 20101028,
    ["mExtraCountOdds"] = {10000, 5000, 1200, 200, 100},
    ["associatedId"] = {20304015},
    ["aOdds"] = 2500,
    ["aExtraCountOdds"] = {9000, 4000, 2000, 1000},
    ["rareId"] = -1,
    ["rOdds"] = 100,
    ["needLevel"] = 11
}

gp_caiji.g_GPInfo[129] = {
    ["abilityId"] = define.ABILITY_CAIYAO,
    ["name"] = "Liên Tử",
    ["mainId"] = 20101029,
    ["mExtraCountOdds"] = {10000, 5000, 1200, 200, 100},
    ["associatedId"] = {20304015},
    ["aOdds"] = 2500,
    ["aExtraCountOdds"] = {9000, 4000, 2000, 1000},
    ["rareId"] = -1,
    ["rOdds"] = 100,
    ["needLevel"] = 12
}

gp_caiji.g_GPInfo[130] = {
    ["abilityId"] = define.ABILITY_CAIYAO,
    ["name"] = "Khô Mộc Xuân",
    ["mainId"] = 20101030,
    ["mExtraCountOdds"] = {10000, 5000, 1200, 200, 100},
    ["associatedId"] = {20304016},
    ["aOdds"] = 2500,
    ["aExtraCountOdds"] = {9000, 4000, 2000, 1000},
    ["rareId"] = -1,
    ["rOdds"] = 100,
    ["needLevel"] = 12
}

gp_caiji.g_GPInfo[813] = {
    ["abilityId"] = define.ABILITY_CAIYAO,
    ["name"] = "Long Diên Thảo",
    ["mainId"] = 20101031,
    ["mExtraCountOdds"] = {10000, 5000, 1200, 200, 100},
    ["associatedId"] = {20101032},
    ["aOdds"] = 2500,
    ["aExtraCountOdds"] = {9000, 4000, 2000, 1000},
    ["rareId"] = -1,
    ["rOdds"] = 100,
    ["needLevel"] = 7
}

gp_caiji.g_GPInfo[818] = {
    ["abilityId"] = define.ABILITY_CAIYAO,
    ["name"] = "Vinh Thảo",
    ["mainId"] = 20101050,
    ["mExtraCountOdds"] = {10000, 5000, 1200, 200, 100},
    ["associatedId"] = {20101051},
    ["aOdds"] = 2500,
    ["aExtraCountOdds"] = {9000, 4000, 2000, 1000},
    ["rareId"] = -1,
    ["rOdds"] = 100,
    ["needLevel"] = 7
}

gp_caiji.g_GPInfo[819] = {
    ["abilityId"] = define.ABILITY_CAIYAO,
    ["name"] = "Dao Thảo",
    ["mainId"] = 20101052,
    ["mExtraCountOdds"] = {10000, 5000, 1200, 200, 100},
    ["associatedId"] = {20101053},
    ["aOdds"] = 2500,
    ["aExtraCountOdds"] = {9000, 4000, 2000, 1000},
    ["rareId"] = -1,
    ["rOdds"] = 100,
    ["needLevel"] = 7
}

gp_caiji.g_abilityName = {}

gp_caiji.g_abilityName[define.ABILITY_CAIKUANG] = "Khai khoáng"
gp_caiji.g_abilityName[define.ABILITY_CAIYAO] = "Hái thuốc"
function gp_caiji:OnCreate(growPointType, x, y)
    if x >= 200 then
        return
    end
    if y >= 200 then
        return
    end
    local GPInfo = self.g_GPInfo[growPointType]
    if not GPInfo then
        return
    end
    local itemBox = self:ItemBoxEnterScene(x, y, growPointType, define.QUALITY_MUST_BE_CHANGE, 1, GPInfo["mainId"])
    local odds = math.random(self.g_RandNum)
    local i
    for i = 1, #(GPInfo["mExtraCountOdds"]) do
        if odds <= GPInfo["mExtraCountOdds"][i] then
            self:AddItemToBox(itemBox, define.QUALITY_MUST_BE_CHANGE, 1, GPInfo["mainId"])
        else
            break
        end
    end
    local aItemCount = #(GPInfo["associatedId"])
    if aItemCount > 0 then
        odds = math.random(self.g_RandNum)
        if odds <= GPInfo["aOdds"] then
            local aItem = GPInfo["associatedId"][math.random(aItemCount)]
            self:AddItemToBox(itemBox, define.QUALITY_MUST_BE_CHANGE, 1, aItem)
            odds = math.random(self.g_RandNum)
            for i = 1, #(GPInfo["aExtraCountOdds"]) do
                if odds <= GPInfo["aExtraCountOdds"][i] then
                    self:AddItemToBox(itemBox, define.QUALITY_MUST_BE_CHANGE, 1, aItem)
                else
                    break
                end
            end
        end
    end
    if GPInfo["rareId"] ~= -1 then
        odds = math.random(self.g_RandNum)
        if odds <= GPInfo["rOdds"] then
            self:AddItemToBox(itemBox, define.QUALITY_MUST_BE_CHANGE, 1, GPInfo["rareId"])
        end
    end
    local ExchangeStoneScriptID = 210242
    for i = 1, 7 do
        local Item = self:CallScriptFunction(ExchangeStoneScriptID, "DropStoneList", i)
        if Item > 0 then
            self:AddItemToBox(itemBox, define.QUALITY_MUST_BE_CHANGE, 1, Item)
        end
    end
    local ExchangeLongzhuScriptID = 808058
    for i = 1, 7 do
        local Item = self:CallScriptFunction(ExchangeLongzhuScriptID, "DropLongzhuList", i)
        if Item > 0 then
            self:AddItemToBox(itemBox, define.QUALITY_MUST_BE_CHANGE, 1, Item)
        end
    end
end

function gp_caiji:OnOpen(selfId, targetId)
    local growPointType = self:LuaFnGetItemBoxGrowPointType(targetId)
    local GPInfo = self.g_GPInfo[growPointType]
    if not GPInfo then
        return define.OPERATE_RESULT.OR_INVALID_TARGET
    end
    local AbilityLevel = self:QueryHumanAbilityLevel(selfId, GPInfo["abilityId"])
    if AbilityLevel < GPInfo["needLevel"] then
        self:NotifyFailTips(
            selfId,
            "Cần" ..
                self.g_abilityName[GPInfo["abilityId"]] ..
                    "Kỹ Năng " .. GPInfo["needLevel"] .. " Cấp, hiện tại " .. AbilityLevel .. " cấp"
        )
        return define.OPERATE_RESULT.OR_NO_LEVEL
    end
    local energyCost =
        self:CallScriptFunction(
        define.ABILITYLOGIC_ID,
        "CalcEnergyCostCaiJi",
        selfId,
        GPInfo["abilityId"],
        GPInfo["needLevel"]
    )
    if self:GetHumanEnergy(selfId) < energyCost then
        return define.OPERATE_RESULT.OR_NOT_ENOUGH_ENERGY
    end
    return define.OPERATE_RESULT.OR_OK
end

function gp_caiji:OnProcOver(selfId, targetId)
    local growPointType = self:LuaFnGetItemBoxGrowPointType(targetId)
    local GPInfo = self.g_GPInfo[growPointType]
    if not GPInfo then
        return define.OPERATE_RESULT.OR_INVALID_TARGET
    end
    self:CallScriptFunction(define.ABILITYLOGIC_ID, "EnergyCostCaiJi", selfId, GPInfo["abilityId"], GPInfo["needLevel"])
    return define.OPERATE_RESULT.OR_OK
end

function gp_caiji:OnRecycle(selfId, targetId)
    local growPointType = self:LuaFnGetItemBoxGrowPointType(targetId)
    local GPInfo = self.g_GPInfo[growPointType]
    if not GPInfo then
        return 1
    end
    self:LuaFnAuditAbility(selfId, GPInfo["abilityId"], -1, -1)
    self:CallScriptFunction(define.ABILITYLOGIC_ID, "GainExperience", selfId, GPInfo["abilityId"], GPInfo["needLevel"])
    return 1
end

function gp_caiji:NotifyFailTips(selfId, Tip)
    self:BeginEvent(self.script_id)
    self:AddText(Tip)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function gp_caiji:OnTickCreateFinish(growPointType, tickCount)
end

return gp_caiji
