local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ScriptGlobal = require "scripts.ScriptGlobal"
local osuzhou_liangshicheng = class("osuzhou_liangshicheng", script_base)
osuzhou_liangshicheng.script_id = 001067
osuzhou_liangshicheng.g_eventList = {1018716,1018717}

--所有兑换内容全部集中在这个组里
osuzhou_liangshicheng.g_ItemDataInfo =
{ 
    [1] = { ["needItem"] = 20309010, ["needItemNum"] = 6, ["nPrizeItem"] = 10413007, ["nPrizeItemNum"] = 1 },
    [2] = { ["needItem"] = 20309010, ["needItemNum"] = 6, ["nPrizeItem"] = 10421007, ["nPrizeItemNum"] = 1 },
    [3] = { ["needItem"] = 20309010, ["needItemNum"] = 6, ["nPrizeItem"] = 10412007, ["nPrizeItemNum"] = 1 },
    [4] = { ["needItem"] = 20309010, ["needItemNum"] = 6, ["nPrizeItem"] = 10411007, ["nPrizeItemNum"] = 1 },
    [5] = { ["needItem"] = 20309010, ["needItemNum"] = 6, ["nPrizeItem"] = 10413001, ["nPrizeItemNum"] = 1 },
    [6] = { ["needItem"] = 20309010, ["needItemNum"] = 6, ["nPrizeItem"] = 10421001, ["nPrizeItemNum"] = 1 },
    [7] = { ["needItem"] = 20309010, ["needItemNum"] = 6, ["nPrizeItem"] = 10412001, ["nPrizeItemNum"] = 1 },
    [8] = { ["needItem"] = 20309010, ["needItemNum"] = 6, ["nPrizeItem"] = 10411001, ["nPrizeItemNum"] = 1 },
    [9] = { ["needItem"] = 20309011, ["needItemNum"] = 8, ["nPrizeItem"] = 10413008, ["nPrizeItemNum"] = 1 },
    [10] = { ["needItem"] = 20309011, ["needItemNum"] = 8, ["nPrizeItem"] = 10421008, ["nPrizeItemNum"] = 1 },
    [11] = { ["needItem"] = 20309011, ["needItemNum"] = 8, ["nPrizeItem"] = 10412008, ["nPrizeItemNum"] = 1 },
    [12] = { ["needItem"] = 20309011, ["needItemNum"] = 8, ["nPrizeItem"] = 10411008, ["nPrizeItemNum"] = 1 },
    [13] = { ["needItem"] = 20309011, ["needItemNum"] = 8, ["nPrizeItem"] = 10413002, ["nPrizeItemNum"] = 1 },
    [14] = { ["needItem"] = 20309011, ["needItemNum"] = 8, ["nPrizeItem"] = 10421002, ["nPrizeItemNum"] = 1 },
    [15] = { ["needItem"] = 20309011, ["needItemNum"] = 8, ["nPrizeItem"] = 10412002, ["nPrizeItemNum"] = 1 },
    [16] = { ["needItem"] = 20309011, ["needItemNum"] = 8, ["nPrizeItem"] = 10411002, ["nPrizeItemNum"] = 1 },
    [17] = { ["needItem"] = 20309012, ["needItemNum"] = 10, ["nPrizeItem"] = 10413009, ["nPrizeItemNum"] = 1 },
    [18] = { ["needItem"] = 20309012, ["needItemNum"] = 10, ["nPrizeItem"] = 10421009, ["nPrizeItemNum"] = 1 },
    [19] = { ["needItem"] = 20309012, ["needItemNum"] = 10, ["nPrizeItem"] = 10412009, ["nPrizeItemNum"] = 1 },
    [20] = { ["needItem"] = 20309012, ["needItemNum"] = 10, ["nPrizeItem"] = 10411009, ["nPrizeItemNum"] = 1 },
    [21] = { ["needItem"] = 20309012, ["needItemNum"] = 10, ["nPrizeItem"] = 10414024, ["nPrizeItemNum"] = 1 },
    [22] = { ["needItem"] = 20309012, ["needItemNum"] = 10, ["nPrizeItem"] = 10413003, ["nPrizeItemNum"] = 1 },
    [23] = { ["needItem"] = 20309012, ["needItemNum"] = 10, ["nPrizeItem"] = 10421003, ["nPrizeItemNum"] = 1 },
    [24] = { ["needItem"] = 20309012, ["needItemNum"] = 10, ["nPrizeItem"] = 10412003, ["nPrizeItemNum"] = 1 },
    [25] = { ["needItem"] = 20309012, ["needItemNum"] = 10, ["nPrizeItem"] = 10411003, ["nPrizeItemNum"] = 1 },
    [26] = { ["needItem"] = 20309012, ["needItemNum"] = 10, ["nPrizeItem"] = 10414020, ["nPrizeItemNum"] = 1 },
    [27] = { ["needItem"] = 20309013, ["needItemNum"] = 12, ["nPrizeItem"] = 10413010, ["nPrizeItemNum"] = 1 },
    [28] = { ["needItem"] = 20309013, ["needItemNum"] = 12, ["nPrizeItem"] = 10421010, ["nPrizeItemNum"] = 1 },
    [29] = { ["needItem"] = 20309013, ["needItemNum"] = 12, ["nPrizeItem"] = 10412010, ["nPrizeItemNum"] = 1 },
    [30] = { ["needItem"] = 20309013, ["needItemNum"] = 12, ["nPrizeItem"] = 10411010, ["nPrizeItemNum"] = 1 },
    [31] = { ["needItem"] = 20309013, ["needItemNum"] = 12, ["nPrizeItem"] = 10414025, ["nPrizeItemNum"] = 1 },
    [32] = { ["needItem"] = 20309013, ["needItemNum"] = 12, ["nPrizeItem"] = 10413004, ["nPrizeItemNum"] = 1 },
    [33] = { ["needItem"] = 20309013, ["needItemNum"] = 12, ["nPrizeItem"] = 10421004, ["nPrizeItemNum"] = 1 },
    [34] = { ["needItem"] = 20309013, ["needItemNum"] = 12, ["nPrizeItem"] = 10412004, ["nPrizeItemNum"] = 1 },
    [35] = { ["needItem"] = 20309013, ["needItemNum"] = 12, ["nPrizeItem"] = 10411004, ["nPrizeItemNum"] = 1 },
    [36] = { ["needItem"] = 20309013, ["needItemNum"] = 12, ["nPrizeItem"] = 10414021, ["nPrizeItemNum"] = 1 },
    [37] = { ["needItem"] = 20309014, ["needItemNum"] = 14, ["nPrizeItem"] = 10413011, ["nPrizeItemNum"] = 1 },
    [38] = { ["needItem"] = 20309014, ["needItemNum"] = 14, ["nPrizeItem"] = 10421011, ["nPrizeItemNum"] = 1 },
    [39] = { ["needItem"] = 20309014, ["needItemNum"] = 14, ["nPrizeItem"] = 10412011, ["nPrizeItemNum"] = 1 },
    [40] = { ["needItem"] = 20309014, ["needItemNum"] = 14, ["nPrizeItem"] = 10411011, ["nPrizeItemNum"] = 1 },
    [41] = { ["needItem"] = 20309014, ["needItemNum"] = 14, ["nPrizeItem"] = 10414026, ["nPrizeItemNum"] = 1 },
    [42] = { ["needItem"] = 20309014, ["needItemNum"] = 14, ["nPrizeItem"] = 10415018, ["nPrizeItemNum"] = 1 },
    [43] = { ["needItem"] = 20309014, ["needItemNum"] = 14, ["nPrizeItem"] = 10413005, ["nPrizeItemNum"] = 1 },
    [44] = { ["needItem"] = 20309014, ["needItemNum"] = 14, ["nPrizeItem"] = 10421005, ["nPrizeItemNum"] = 1 },
    [45] = { ["needItem"] = 20309014, ["needItemNum"] = 14, ["nPrizeItem"] = 10412005, ["nPrizeItemNum"] = 1 },
    [46] = { ["needItem"] = 20309014, ["needItemNum"] = 14, ["nPrizeItem"] = 10411005, ["nPrizeItemNum"] = 1 },
    [47] = { ["needItem"] = 20309014, ["needItemNum"] = 14, ["nPrizeItem"] = 10414022, ["nPrizeItemNum"] = 1 },
    [48] = { ["needItem"] = 20309014, ["needItemNum"] = 14, ["nPrizeItem"] = 10415016, ["nPrizeItemNum"] = 1 },
    [49] = { ["needItem"] = 20309015, ["needItemNum"] = 16, ["nPrizeItem"] = 10413012, ["nPrizeItemNum"] = 1 },
    [50] = { ["needItem"] = 20309015, ["needItemNum"] = 16, ["nPrizeItem"] = 10421012, ["nPrizeItemNum"] = 1 },
    [51] = { ["needItem"] = 20309015, ["needItemNum"] = 16, ["nPrizeItem"] = 10412012, ["nPrizeItemNum"] = 1 },
    [52] = { ["needItem"] = 20309015, ["needItemNum"] = 16, ["nPrizeItem"] = 10411012, ["nPrizeItemNum"] = 1 },
    [53] = { ["needItem"] = 20309015, ["needItemNum"] = 16, ["nPrizeItem"] = 10414027, ["nPrizeItemNum"] = 1 },
    [54] = { ["needItem"] = 20309015, ["needItemNum"] = 16, ["nPrizeItem"] = 10415019, ["nPrizeItemNum"] = 1 },
    [55] = { ["needItem"] = 20309015, ["needItemNum"] = 16, ["nPrizeItem"] = 10413006, ["nPrizeItemNum"] = 1 },
    [56] = { ["needItem"] = 20309015, ["needItemNum"] = 16, ["nPrizeItem"] = 10421006, ["nPrizeItemNum"] = 1 },
    [57] = { ["needItem"] = 20309015, ["needItemNum"] = 16, ["nPrizeItem"] = 10412006, ["nPrizeItemNum"] = 1 },
    [58] = { ["needItem"] = 20309015, ["needItemNum"] = 16, ["nPrizeItem"] = 10411006, ["nPrizeItemNum"] = 1 },
    [59] = { ["needItem"] = 20309015, ["needItemNum"] = 16, ["nPrizeItem"] = 10414023, ["nPrizeItemNum"] = 1 },
    [60] = { ["needItem"] = 20309015, ["needItemNum"] = 16, ["nPrizeItem"] = 10415017, ["nPrizeItemNum"] = 1 },
    [61] = { ["needItem"] = 20309016, ["needItemNum"] = 32, ["nPrizeItem"] = 10413017, ["nPrizeItemNum"] = 1 },
    [62] = { ["needItem"] = 20309016, ["needItemNum"] = 32, ["nPrizeItem"] = 10421014, ["nPrizeItemNum"] = 1 },
    [63] = { ["needItem"] = 20309016, ["needItemNum"] = 32, ["nPrizeItem"] = 10412017, ["nPrizeItemNum"] = 1 },
    [64] = { ["needItem"] = 20309016, ["needItemNum"] = 32, ["nPrizeItem"] = 10411014, ["nPrizeItemNum"] = 1 },
    [65] = { ["needItem"] = 20309016, ["needItemNum"] = 32, ["nPrizeItem"] = 10414028, ["nPrizeItemNum"] = 1 },
    [66] = { ["needItem"] = 20309016, ["needItemNum"] = 32, ["nPrizeItem"] = 10415020, ["nPrizeItemNum"] = 1 },
    [67] = { ["needItem"] = 20309016, ["needItemNum"] = 32, ["nPrizeItem"] = 10413018, ["nPrizeItemNum"] = 1 },
    [68] = { ["needItem"] = 20309016, ["needItemNum"] = 32, ["nPrizeItem"] = 10421015, ["nPrizeItemNum"] = 1 },
    [69] = { ["needItem"] = 20309016, ["needItemNum"] = 32, ["nPrizeItem"] = 10412018, ["nPrizeItemNum"] = 1 },
    [70] = { ["needItem"] = 20309016, ["needItemNum"] = 32, ["nPrizeItem"] = 10411015, ["nPrizeItemNum"] = 1 },
    [71] = { ["needItem"] = 20309016, ["needItemNum"] = 32, ["nPrizeItem"] = 10414029, ["nPrizeItemNum"] = 1 },
    [72] = { ["needItem"] = 20309016, ["needItemNum"] = 48, ["nPrizeItem"] = 10415021, ["nPrizeItemNum"] = 1 },
    [73] = { ["needItem"] = 20309017, ["needItemNum"] = 48, ["nPrizeItem"] = 10413019, ["nPrizeItemNum"] = 1 },
    [74] = { ["needItem"] = 20309017, ["needItemNum"] = 48, ["nPrizeItem"] = 10421016, ["nPrizeItemNum"] = 1 },
    [75] = { ["needItem"] = 20309017, ["needItemNum"] = 48, ["nPrizeItem"] = 10412019, ["nPrizeItemNum"] = 1 },
    [76] = { ["needItem"] = 20309017, ["needItemNum"] = 48, ["nPrizeItem"] = 10411016, ["nPrizeItemNum"] = 1 },
    [77] = { ["needItem"] = 20309017, ["needItemNum"] = 48, ["nPrizeItem"] = 10414030, ["nPrizeItemNum"] = 1 },
    [78] = { ["needItem"] = 20309017, ["needItemNum"] = 48, ["nPrizeItem"] = 10415022, ["nPrizeItemNum"] = 1 },
    [79] = { ["needItem"] = 20309017, ["needItemNum"] = 48, ["nPrizeItem"] = 10413020, ["nPrizeItemNum"] = 1 },
    [80] = { ["needItem"] = 20309017, ["needItemNum"] = 48, ["nPrizeItem"] = 10421017, ["nPrizeItemNum"] = 1 },
    [81] = { ["needItem"] = 20309017, ["needItemNum"] = 48, ["nPrizeItem"] = 10412020, ["nPrizeItemNum"] = 1 },
    [82] = { ["needItem"] = 20309017, ["needItemNum"] = 48, ["nPrizeItem"] = 10411017, ["nPrizeItemNum"] = 1 },
    [83] = { ["needItem"] = 20309017, ["needItemNum"] = 48, ["nPrizeItem"] = 10414031, ["nPrizeItemNum"] = 1 },
    [84] = { ["needItem"] = 20309017, ["needItemNum"] = 48, ["nPrizeItem"] = 10415023, ["nPrizeItemNum"] = 1 },
    [85] = { ["needItem"] = 20310101, ["needItemNum"] = 1, ["nPrizeItem"] = 10422150, ["nPrizeItemNum"] = 1 },
    [86] = { ["needItem"] = 20310102, ["needItemNum"] = 1, ["nPrizeItem"] = 10423026, ["nPrizeItemNum"] = 1 },
    [87] = { ["needItem"] = 20310224, ["needItemNum"] = 40, ["nPrizeItem"] = 10420088, ["nPrizeItemNum"] = 1 },
	[88] = { ["needItem"] = 20310220, ["needItemNum"] = 40, ["nPrizeItem"] = 10413102, ["nPrizeItemNum"] = 1 },
}
osuzhou_liangshicheng.MenPaiEquipInfo = 
{
    [1] = {{10513001,10514001},{10520002,10521002,10522002},{10514003,10522003}},
    [2] = {{10521011,10522011},{10510012,10511012,10512012},{10520013,10523013}},
    [3] = {{10511021,10512021},{10513022,10514022,10515022},{10510023,10522023}},
    [4] = {{10513031,10514031},{10520032,10521032,10522032},{10514033,10522033}},
    [5] = {{10521041,10520041},{10510042,10511042,10512042},{10510043,10523043}},
    [6] = {{10511051,10512051},{10513052,10514052,10515052},{10510053,10522053}},
    [7] = {{10510081,10511081},{10513082,10514082,10515082},{10512083,10522083}},
    [8] = {{10513061,10514061},{10520062,10521062,10522062},{10512063,10514063}},
    [9] = {{10521071,10522071},{10510072,10511072,10512072},{10510073,10523073}},
    [11] = {{10521119,10522119},{10510118,10511119,10512118},{10510119,10523119}},
}
osuzhou_liangshicheng.BiaoQiEquipInfo = 
{
    [1] = {{10400076,10402076,10404073,10405072},{10410128,10410132},{10415045,10415049},{10413087,10413091},{10412084,10412088},{10414045,10414049},{10421078,10421082},{10411088,10411092},{10420080,10420084},{10422141,10422145},{10423050,10423054}},
    [2] = {{10400077,10402077,10404074,10405073},{10410129,10410133},{10415046,10415050},{10413088,10413092},{10412085,10412089},{10414046,10414050},{10421079,10421083},{10411089,10411093},{10420081,10420085},{10422142,10422146},{10423051,10423055}},
    [3] = {{10400078,10402078,10404075,10405074},{10410130,10410134},{10415047,10415051},{10413089,10413093},{10412086,10412090},{10414047,10414051},{10421080,10421084},{10411090,10411094},{10420082,10420086},{10422143,10422147},{10423052,10423056}},
    [4] = {{10400079,10402079,10404076,10405075},{10410131,10410135},{10415048,10415052},{10413090,10413094},{10412087,10412091},{10414048,10414052},{10421081,10421085},{10411091,10411095},{10420083,10420087},{10422144,10422148},{10423053,10423057}},
}
osuzhou_liangshicheng.change_title = {
	{needitem = {38008160,38008161},needcount = 5000,titleid = 1234,titleflag = -1,titlename = "Tranh bá giang hồ · Hiệp giả thượng võ"},
	{needitem = {38008160,38008161},needcount = 10000,titleid = 1235,titleflag = -1,titlename = "Tranh bá giang hồ · Tinh anh bách chiến"},
	{needitem = {38008160,38008161},needcount = 20000,titleid = 1372,titleflag = -1,titlename = "Cùng Người Chung Hẹn Trường An"},
}

-- 低级称号兑换配置：50个称号凭证(20310218绑定/非绑定)
osuzhou_liangshicheng.low_title_exchange = {
	{needitem = {20310219, 20310218}, needcount = 50, titleid = 1345, titlename = "Kiến Long tại thiên"},
	{needitem = {20310219, 20310218}, needcount = 50, titleid = 1360, titlename = "Nguyện được một lòng người"},
	{needitem = {20310219, 20310218}, needcount = 50, titleid = 1084, titlename = "Ca Giả Hoa Hồng"},
	{needitem = {20310219, 20310218}, needcount = 50, titleid = 1215, titlename = "Canh Lậu Chưa Dứt Một Lòng Người"},
	{needitem = {20310219, 20310218}, needcount = 50, titleid = 1250, titlename = "Tình Chung Một Dạ"},
	{needitem = {20310219, 20310218}, needcount = 50, titleid = 1281, titlename = "Sơn hải cùng ký duyên đồng tâm"},
	{needitem = {20310219, 20310218}, needcount = 50, titleid = 1273, titlename = "Thanh khí tương thông có linh tê"},
	{needitem = {20310219, 20310218}, needcount = 50, titleid = 1272, titlename = "Phù cổ tương ứng gặp tri âm"},
	{needitem = {20310219, 20310218}, needcount = 50, titleid = 1275, titlename = "Kiếm múa, hoa tình rơi"},
	{needitem = {20310219, 20310218}, needcount = 50, titleid = 1287, titlename = "Đào Hoa Tiên tiếng cười xuân phong"},
}

-- 高级称号兑换配置：100个称号凭证(20310218绑定/非绑定)
osuzhou_liangshicheng.high_title_exchange = {
	{needitem = {20310219, 20310218}, needcount = 100, titleid = 1346, titlename = "Kiếm Chỉ Thương Sơn Đi Bốn Phương"},
	{needitem = {20310219, 20310218}, needcount = 100, titleid = 1347, titlename = "Kiếm trảm hung sát trấn ngũ diệu"},
	{needitem = {20310219, 20310218}, needcount = 100, titleid = 1348, titlename = "Kiếm diệt tà yêu quét lục hợp"},
	{needitem = {20310219, 20310218}, needcount = 100, titleid = 1406, titlename = "Vấn Đỉnh Thương Sơn Tự Thành Phong"},
	{needitem = {20310219, 20310218}, needcount = 100, titleid = 1372, titlename = "Cùng ngươi chung bước tới Trường An"},
	{needitem = {20310219, 20310218}, needcount = 100, titleid = 1316, titlename = "Vi Quang Chi Tinh Minh Tinh Đạt Nhân"},
}
--进阶配置
osuzhou_liangshicheng.up_level_ini = {
	-- {
		-- --id 双id就填双id  单id 第二个填0   至多配置 4 种需求道具
		-- name = "重楼戒",
		-- need = {
			-- {id = {10422016,0},num = 1},		--第一个位置默认放源装备  材料或要扣除的相同的装备放后面
		-- },
		-- award_id = 10422016,
		-- award_count = 1,
	-- },
	-- {
		-- --id 双id就填双id  单id 第二个填0   至多配置 4 种需求道具
		-- name = "重楼玉",
		-- need = {
			-- {id = {10423024,0},num = 1},		--第一个位置默认放源装备  材料或要扣除的相同的装备放后面
		-- },
		-- award_id = 10423024,
		-- award_count = 1,
	-- },
	-- {
		-- --id 双id就填双id  单id 第二个填0   至多配置 4 种需求道具
		-- name = "重楼链",
		-- need = {
			-- {id = {10420088,0},num = 1},		--第一个位置默认放源装备  材料或要扣除的相同的装备放后面
		-- },
		-- award_id = 10420088,
		-- award_count = 1,
	-- },

	{
		--id 双id就填双id  单id 第二个填0   至多配置 4 种需求道具
		name = "Chuỗi Chân Trùng Lâu",
		need = {
			{id = {10420088,0},num = 1},		--第一个位置默认放源装备  材料或要扣除的相同的装备放后面
			{id = {20310228,0},num = 255},
		},
		award_id = 10420089,
		award_count = 1,
	},
	{
		--id 双id就填双id  单id 第二个填0   至多配置 4 种需求道具
		name = "Ngọc Chân Trùng Lâu",
		need = {
			{id = {10423026,10423024},num = 1},		--第一个位置默认放源装备  材料或要扣除的相同的装备放后面
			{id = {20310228,0},num = 255},
		},
		award_id = 10423025,
		award_count = 1,
	},
	{
		--id 双id就填双id  单id 第二个填0   至多配置 4 种需求道具
		name = "Nhẫn Chân Trùng Lâu",
		need = {
			{id = {10422150,10422016},num = 1},		--第一个位置默认放源装备  材料或要扣除的相同的装备放后面
			{id = {20310228,0},num = 255},
		},
		award_id = 10422149,
		award_count = 1,
	},
	-- {
		-- --id 双id就填双id  单id 第二个填0   至多配置 4 种需求道具
		-- name = "真重楼肩",
		-- need = {
			-- {id = {10415055,0},num = 1},		--第一个位置默认放源装备  材料或要扣除的相同的装备放后面
			-- {id = {20310228,0},num = 255},
		-- },
		-- award_id = 10415056,
		-- award_count = 1,
	-- },
	-- {
		-- --id 双id就填双id  单id 第二个填0   至多配置 4 种需求道具
		-- name = "真重楼甲",
		-- need = {
			-- {id = {10413102,0},num = 1},		--第一个位置默认放源装备  材料或要扣除的相同的装备放后面
			-- {id = {20310228,0},num = 255},
		-- },
		-- award_id = 10413104,
		-- award_count = 1,
	-- },
	-- {
		-- --id 双id就填双id  单id 第二个填0   至多配置 4 种需求道具
		-- name = "真重楼带",
		-- need = {
			-- {id = {10421087,0},num = 1},		--第一个位置默认放源装备  材料或要扣除的相同的装备放后面
			-- {id = {20310228,0},num = 255},
		-- },
		-- award_id = 10421088,
		-- award_count = 1,
	-- },
	-- {
		-- --id 双id就填双id  单id 第二个填0   至多配置 4 种需求道具
		-- name = "高级兔耳朵",
		-- need = {
			-- {id = {10410033,0},num = 1},		--第一个位置默认放源装备  材料或要扣除的相同的装备放后面
			-- {id = {20310226,20310227},num = 255},
		-- },
		-- award_id = 10410034,
		-- award_count = 1,
	-- },
}
--兑换配置
osuzhou_liangshicheng.change_item_ini = {
	--id 双id就填双id  单id 第二个填0   至多配置 4 种需求道具
--[[	{
		name = "重楼甲",
		need = {
			{id = {20310220,20310221},num = 20},
		},
		award_id = 10413102,
		award_count = 1,
	},
	{
		name = "重楼肩",
		need = {
			{id = {20310222,20310223},num = 255},
		},
		award_id = 10415055,
		award_count = 1,
	},
	{
		name = "重楼·召",
		need = {
			{id = {20310229,0},num = 255},
		},
		award_id = 10422155,
		award_count = 1,
	},
	{
		name = "重楼·归",
		need = {
			{id = {20310229,0},num = 255},
		},
		award_id = 10423064,
		award_count = 1,
	},--]]
	-- {
		-- name = "重楼带",
		-- need = {
			-- {id = {20310230,20310231},num = 255},
		-- },
		-- award_id = 10421087,
		-- award_count = 1,
	-- },
	-- {
		-- name = "兔耳朵",
		-- need = {
			-- {id = {20310216,20310217},num = 255},
		-- },
		-- award_id = 10410033,
		-- award_count = 1,
	-- },
	{
		name = "Danh hiệu thuộc tính: Sơ hội tiện dĩ hứa bình sinh",
		need = {
			{id = {20310218,20310219},num = 388},
		},
		award_id = 1286,
		award_count = 1,
	},
	{
		name = "Danh hiệu thuộc tính: Phù cổ tương ứng hội tri âm",
		need = {
			{id = {20310218,20310219},num = 888},
		},
		award_id = 1272,
		award_count = 1,
	},
	{
		name = "Danh hiệu thuộc tính: Ngự Phong Đằng Sơn Hải",
		need = {
			{id = {20310218,20310219},num = 1288},
		},
		award_id = 1374,
		award_count = 1,
	},
	{
		name = "Danh hiệu thuộc tính: Mộng khởi Thiên Long cùng người tương tụ",
		need = {
			{id = {20310218,20310219},num = 1888},
		},
		award_id = 1309,
		award_count = 1,
	},
}

--重洗需求材料 双ID写两个 单ID need_chongxi_itemb = 0
osuzhou_liangshicheng.need_chongxi_itema = 38008183
osuzhou_liangshicheng.need_chongxi_itemb = 0
osuzhou_liangshicheng.need_chongxi_item_count = 1
--开放重洗的装备ID
osuzhou_liangshicheng.open_chongxi_equipid = {
	--[10420089] = true,

}


function osuzhou_liangshicheng:EquipJinJie(selfId,index,...)
	local up_level_ini = self.up_level_ini[index]
	if not up_level_ini then
		self:notify_tips(selfId,"Chọn bất thường.")
		return
	end
	local bag_pos = { ... }
	local max_count = #up_level_ini.need
	if max_count ~= #bag_pos then
		self:notify_tips(selfId,"Vị trí túi bất thường.")
		return
	end
	for i,j in ipairs(bag_pos) do
		if j == -1 then
			local msg = string.format("Vị trí [%d] xin đặt #{_ITEMINFO%d}.",i,up_level_ini.need.id[1])
			self:notify_tips(selfId,msg)
			return
		end
		for k,l in ipairs(bag_pos) do
			if i ~= k and j == l then
				local msg = string.format("Nguyên liệu đặt vị trí [%d] xung đột vị trí túi với [%d].",i,k)
				self:notify_tips(selfId,msg)
				return
			end
		end
	end
	local ret = self:LuaFnCheckRefreshEquipID_Attr(selfId,bag_pos[1],up_level_ini.award_id)
	if ret == 0 then
		local eqbind = self:GetBagItemIsBind(selfId,bag_pos[1])
		-- local isbind = eqbind
		local id,count1,count2,costnum,id1,id2
		for i,info in ipairs(up_level_ini.need) do
			if i > 1 then
				id = self:LuaFnGetItemTableIndexByIndex(selfId,bag_pos[i])
				id1 = info.id[1]
				id2 = info.id[2]
				if id == 0 then
					local msg = string.format("Nguyên liệu đặt ở vị trí [%d] không khớp.",i)
					self:notify_tips(selfId,msg)
					return
				elseif id ~= id1 and id ~= id2 then
					local msg = string.format("Nguyên liệu đặt ở vị trí [%d] không khớp.",i)
					self:notify_tips(selfId,msg)
					return
				end
				count1 = self:LuaFnGetAvailableItemCount(selfId,id1)
				if id2 > 0 and id2 ~= id1 then
					count2 = self:LuaFnGetAvailableItemCount(selfId,id2)
				else
					count2 = 0
				end
				if count1 + count2 < info.num then
					local msg = string.format("#{_ITEMINFO%d} không đủ %d cái.",id1,info.num)
					self:notify_tips(selfId,msg)
					return
				end
				-- if not isbind then
					-- isbind = self:GetBagItemIsBind(selfId,bag_pos[i])
				-- end
			end
		end
		for i = 2,max_count do
			id1 = up_level_ini.need[i].id[1]
			id2 = up_level_ini.need[i].id[2]
			costnum = up_level_ini.need[i].num
			if id1 >= 20000000 then
				count1 = self:GetBagItemLayCount(selfId,bag_pos[i])
				if costnum <= count1 then
					self:LuaFnDecItemLayCount(selfId,bag_pos[i],costnum)
					costnum = 0
				else
					self:LuaFnDecItemLayCount(selfId,bag_pos[i],count1)
					costnum = costnum - count1
				end
				
				if costnum > 0 then
					count1 = self:LuaFnGetAvailableItemCount(selfId,id1)
					if id2 > 0 and id2 ~= id1 then
						count2 = self:LuaFnGetAvailableItemCount(selfId,id2)
					else
						count2 = 0
					end
					if count2 >= costnum then
						self:LuaFnDelAvailableItem(selfId,id2,costnum)
						-- isbind = true
					else
						if count2 > 0 then
							self:LuaFnDelAvailableItem(selfId,id2,count2)
							costnum = costnum - count2
							-- isbind = true
						end
						self:LuaFnDelAvailableItem(selfId,id1,costnum)
					end
				end
			else
				self:EraseItem(selfId,bag_pos[i])
				costnum = costnum - 1
				if costnum > 0 then
					for j = 0,99 do
						if j ~= bag_pos[1] then
							id = self:LuaFnGetItemTableIndexByIndex(selfId,j)
							if id ~= 0 then
								if id == id1 or id == id2 then
									self:EraseItem(selfId,j)
									costnum = costnum - 1
									if costnum == 0 then
										break
									end
								end
							end
						end
					end
					if costnum > 0 then
						local msg = string.format("#{_ITEMINFO%d} trừ thất bại.",id)
						self:notify_tips(selfId,msg)
						return
					end
				end
			end
		end
		-- if isbind and not eqbind then
			-- self:LuaFnItemBind(selfId,bag_pos[1])
		-- end
		if not eqbind then
			self:LuaFnItemBind(selfId,bag_pos[1])
		end
		ret = self:LuaFnRefreshEquipID_Attr(selfId,bag_pos[1],up_level_ini.award_id)
		if ret == 0 then
			self:GiveItemTip(selfId,up_level_ini.award_id,1,18)
		end
		self:BeginUICommand()
		self:EndUICommand()
		self:DispatchUICommand(selfId,615052022)
	elseif ret == 1 then
		self:notify_tips(selfId,"Đối tượng bất thường.")
	elseif ret == 2 then
		self:notify_tips(selfId,"Xin đặt trang bị gốc vào.")
	elseif ret == 3 then
		self:notify_tips(selfId,"Trang bị gốc không tồn tại.")
	elseif ret == 4 then
		self:notify_tips(selfId,"Trang bị đích không tồn tại.")
	elseif ret == 5 then
		self:notify_tips(selfId,"Trang bị gốc và đích khác loại.")
	else
		self:notify_tips(selfId,"Lỗi không xác định.")
	end
end
function osuzhou_liangshicheng:EquipJinJieNoUI(selfId, pos)
	local up_level_ini = self.up_level_ini[pos]
	if not up_level_ini then
		self:notify_tips(selfId, "Chọn bất thường.")
		return
	end
	-- 自动搜索背包找源装备
	local equip_bag_pos = -1
	local need_equip_id1 = up_level_ini.need[1].id[1]
	local need_equip_id2 = up_level_ini.need[1].id[2]
	for i = 0, 99 do
		local item_id = self:LuaFnGetItemTableIndexByIndex(selfId, i)
		if item_id == need_equip_id1 or (need_equip_id2 > 0 and item_id == need_equip_id2) then
			equip_bag_pos = i
			break
		end
	end
	if equip_bag_pos == -1 then
		local src_name = self:GetItemName(need_equip_id1)
		self:notify_tips(selfId, string.format("Túi không thấy %s, tiến giai %s cần trang bị đó.", src_name, up_level_ini.name))
		return
	end
	-- 检查是否可以进阶
	local ret = self:LuaFnCheckRefreshEquipID_Attr(selfId, equip_bag_pos, up_level_ini.award_id)
	if ret == 0 then
		local eqbind = self:GetBagItemIsBind(selfId, equip_bag_pos)
		local max_count = #up_level_ini.need
		local id, count1, count2, costnum, id1, id2
		-- 检查并扣除材料（need[2+]）
		for i = 2, max_count do
			local info = up_level_ini.need[i]
			id1 = info.id[1]
			id2 = info.id[2]
			count1 = self:LuaFnGetAvailableItemCount(selfId, id1)
			if id2 > 0 and id2 ~= id1 then
				count2 = self:LuaFnGetAvailableItemCount(selfId, id2)
			else
				count2 = 0
			end
			if count1 + count2 < info.num then
				local msg = string.format("#{_ITEMINFO%d} không đủ %d cái.", id1, info.num)
				self:notify_tips(selfId, msg)
				return
			end
		end
		for i = 2, max_count do
			id1 = up_level_ini.need[i].id[1]
			id2 = up_level_ini.need[i].id[2]
			costnum = up_level_ini.need[i].num
			if id1 >= 20000000 then
				-- 可叠加材料，自动从背包中扣除
				count1 = self:LuaFnGetAvailableItemCount(selfId, id1)
				if id2 > 0 and id2 ~= id1 then
					count2 = self:LuaFnGetAvailableItemCount(selfId, id2)
				else
					count2 = 0
				end
				if count1 >= costnum then
					self:LuaFnDelAvailableItem(selfId, id1, costnum)
				elseif count1 > 0 then
					self:LuaFnDelAvailableItem(selfId, id1, count1)
					costnum = costnum - count1
					self:LuaFnDelAvailableItem(selfId, id2, costnum)
				else
					self:LuaFnDelAvailableItem(selfId, id2, costnum)
				end
			else
				-- 装备类材料，逐格搜索背包扣除
				local removed = 0
				for j = 0, 99 do
					if j ~= equip_bag_pos then
						id = self:LuaFnGetItemTableIndexByIndex(selfId, j)
						if id ~= 0 and (id == id1 or id == id2) then
							self:EraseItem(selfId, j)
							removed = removed + 1
							if removed >= costnum then
								break
							end
						end
					end
				end
				if removed < costnum then
					local msg = string.format("#{_ITEMINFO%d} trừ thất bại.", id1)
					self:notify_tips(selfId, msg)
					return
				end
			end
		end
		if not eqbind then
			self:LuaFnItemBind(selfId, equip_bag_pos)
		end
		ret = self:LuaFnRefreshEquipID_Attr(selfId, equip_bag_pos, up_level_ini.award_id)
		if ret == 0 then
			self:GiveItemTip(selfId, up_level_ini.award_id, 1, 18)
		end
	elseif ret == 1 then
		self:notify_tips(selfId, "Đối tượng bất thường.")
	elseif ret == 2 then
		self:notify_tips(selfId, "Xin đặt trang bị gốc vào.")
	elseif ret == 3 then
		self:notify_tips(selfId, "Trang bị gốc không tồn tại.")
	elseif ret == 4 then
		self:notify_tips(selfId, "Trang bị đích không tồn tại.")
	elseif ret == 5 then
		self:notify_tips(selfId, "Trang bị gốc và đích khác loại.")
	else
		self:notify_tips(selfId, "Lỗi không xác định.")
	end
end
function osuzhou_liangshicheng:ItemChange(selfId,index,...)
	local change_item_ini = self.change_item_ini[index]
	if not change_item_ini then
		self:notify_tips(selfId,"Chọn bất thường.")
		return
	end
	local bag_pos = { ... }
	local max_count = #change_item_ini.need
	if max_count ~= #bag_pos then
		self:notify_tips(selfId,"Vị trí túi bất thường.")
		return
	end
	for i,j in ipairs(bag_pos) do
		if j == -1 then
			local msg = string.format("Vị trí [%d] xin đặt #{_ITEMINFO%d}.",i,change_item_ini.need.id[1])
			self:notify_tips(selfId,msg)
			return
		end
		for k,l in ipairs(bag_pos) do
			if i ~= k and j == l then
				local msg = string.format("Nguyên liệu đặt vị trí [%d] xung đột vị trí túi với [%d].",i,k)
				self:notify_tips(selfId,msg)
				return
			end
		end
	end
	-- local isbind = false
	local id,count1,count2,costnum,id1,id2
	for i,info in ipairs(change_item_ini.need) do
		id = self:LuaFnGetItemTableIndexByIndex(selfId,bag_pos[i])
		id1 = info.id[1]
		id2 = info.id[2]
		if id == 0 then
			local msg = string.format("Nguyên liệu đặt ở vị trí [%d] không khớp.",i)
			self:notify_tips(selfId,msg)
			return
		elseif id ~= id1 and id ~= id2 then
			local msg = string.format("Nguyên liệu đặt ở vị trí [%d] không khớp.",i)
			self:notify_tips(selfId,msg)
			return
		end
		count1 = self:LuaFnGetAvailableItemCount(selfId,id1)
		if id2 > 0 and id2 ~= id1 then
			count2 = self:LuaFnGetAvailableItemCount(selfId,id2)
		else
			count2 = 0
		end
		if count1 + count2 < info.num then
			local msg = string.format("#{_ITEMINFO%d} không đủ %d cái.",id1,info.num)
			self:notify_tips(selfId,msg)
			return
		end
		-- if not isbind then
			-- isbind = self:GetBagItemIsBind(selfId,bag_pos[i])
		-- end
	end
	if change_item_ini.award_id >= 10000000 then
		self:BeginAddItem()
		self:AddItem(change_item_ini.award_id,change_item_ini.award_count,true)
		if not self:EndAddItem(selfId,true) then
			return
		end
	else
		if self:LuaFnHaveAgname(selfId, change_item_ini.award_id)  then
			self:notify_tips(selfId,"Ngươi đã có danh hiệu này rồi")
			return
		end
		for i,j in ipairs(self.change_item_ini) do
			if i < index then
				if j.award_id < 10000000 then
					if not self:LuaFnHaveAgname(selfId, j.award_id)  then
						local msg = string.format("Đổi %s cần có %s.",change_item_ini.name,j.name)
						self:notify_tips(selfId,msg)
						return
					end
				end
			else
				break
			end
		end
	end
	for i = 1,max_count do
		id1 = change_item_ini.need[i].id[1]
		id2 = change_item_ini.need[i].id[2]
		costnum = change_item_ini.need[i].num
		if id1 >= 20000000 then
			count1 = self:GetBagItemLayCount(selfId,bag_pos[i])
			if costnum <= count1 then
				self:LuaFnDecItemLayCount(selfId,bag_pos[i],costnum)
				costnum = 0
			else
				self:LuaFnDecItemLayCount(selfId,bag_pos[i],count1)
				costnum = costnum - count1
			end
			
			if costnum > 0 then
				count1 = self:LuaFnGetAvailableItemCount(selfId,id1)
				if id2 > 0 and id2 ~= id1 then
					count2 = self:LuaFnGetAvailableItemCount(selfId,id2)
				else
					count2 = 0
				end
				if count2 >= costnum then
					self:LuaFnDelAvailableItem(selfId,id2,costnum)
					-- isbind = true
				else
					if count2 > 0 then
						self:LuaFnDelAvailableItem(selfId,id2,count2)
						costnum = costnum - count2
						-- isbind = true
					end
					self:LuaFnDelAvailableItem(selfId,id1,costnum)
				end
			end
		else
			self:EraseItem(selfId,bag_pos[i])
			costnum = costnum - 1
			if costnum > 0 then
				for j = 0,99 do
					if j ~= bag_pos[1] then
						id = self:LuaFnGetItemTableIndexByIndex(selfId,j)
						if id ~= 0 then
							if id == id1 or id == id2 then
								self:EraseItem(selfId,j)
								costnum = costnum - 1
								if costnum == 0 then
									break
								end
							end
						end
					end
				end
				if costnum > 0 then
					local msg = string.format("#{_ITEMINFO%d} trừ thất bại.",id)
					self:notify_tips(selfId,msg)
					return
				end
			end
		end
	end
	if change_item_ini.award_id >= 10000000 then
		self:BeginAddItem()
		self:AddItem(change_item_ini.award_id,change_item_ini.award_count,true);
		if not self:EndAddItem(selfId) then
			return
		end
		self:AddItemListToHuman(selfId)
		self:GiveItemTip(selfId,change_item_ini.award_id,1,18)
	else
		self:LuaFnAddNewAgname(selfId,change_item_ini.award_id)
		self:notify_tips(selfId,"Đổi thành công.")
		self:ShowObjBuffEffect(selfId,selfId,-1,18)
	end
	self:BeginUICommand()
	self:EndUICommand()
	self:DispatchUICommand(selfId,615052022)
end
function osuzhou_liangshicheng:DiscardNewEquipAttr(selfId, BagPos)
    self:LuaFnFinishRefreshEquipAttr(selfId, BagPos, false)
end

function osuzhou_liangshicheng:SwitchEquipAttr(selfId, BagPos)
    self:LuaFnFinishRefreshEquipAttr(selfId, BagPos, true)
end

function osuzhou_liangshicheng:RefreshEquipAttr(selfId,BagIndex)
    local item_index = self:GetBagItemIndex(selfId, BagIndex)
	local equip_point = self:IsEquipItem(item_index)
	if not equip_point then
        self:notify_tips(selfId, "Chỉ trang bị mới tẩy lại được.")
        return
    end
	if not self.open_chongxi_equipid[item_index] then
        self:notify_tips(selfId, "Trang bị này không mở tẩy lại.")
        return
    end
	local count1 = self:LuaFnGetAvailableItemCount(selfId,self.need_chongxi_itema)
	local count2 = 0
	if self.need_chongxi_itemb > 0 and self.need_chongxi_itemb ~= self.need_chongxi_itema then
		count2 = self:LuaFnGetAvailableItemCount(selfId,self.need_chongxi_itemb)
	end
	local cost = self.need_chongxi_item_count
	if count1 + count2 < cost then
        self:notify_tips(selfId, string.format("Thiếu %s", self:GetItemName(self.need_chongxi_itema)))
        return
    end
	local HumanMoney = self:GetMoney(selfId ) + self:GetMoneyJZ(selfId)
    if HumanMoney < 200000 then
        self:notify_tips(selfId, "Mỗi lần tẩy lại cần 20 Giao Tử")
        return
    end
	if count2 >= cost then
		self:LuaFnDelAvailableItem(selfId, self.need_chongxi_itemb, cost)
	else
		if count2 > 0 then
			self:LuaFnDelAvailableItem(selfId, self.need_chongxi_itemb, count2)
			cost = cost - count2
		end
		self:LuaFnDelAvailableItem(selfId, self.need_chongxi_itema, cost)
	end
	local del = self:LuaFnCostMoneyWithPriority(selfId, 200000)
	if not del then
        self:notify_tips(selfId, "Trừ tiền thất bại")
        return
    end
	if not self:GetBagItemIsBind(selfId,BagIndex) then
		self:LuaFnItemBind(selfId,BagIndex)
	end
    self:LuaFnRefreshEquipAttr(selfId,BagIndex,nil,1)
    -- self:LuaFnRefreshEquipAttr(selfId,BagIndex,true,2)
    -- self:LuaFnRefreshEquipAttr(selfId,BagIndex,true,3)
end



function osuzhou_liangshicheng:UpdateEventList(selfId, targetId)
	local exdata = self:GetMissionDataEx(selfId,ScriptGlobal.MDEX_CHANGE_TITLE)
    self:BeginEvent(self.script_id)
    self:AddText("  #{JPZB_0610_01}")
	--for i = 1,#self.change_title do
	--	if self.change_title[i].needcount > exdata then
	--		self:AddNumText("#G兑换"..tostring(self.change_title[i].titlename), 6, -2)
	--		break
	--	end
	--end
    --self:AddNumText("兑换师门套装", 6, 1000)
    --self:AddNumText("兑换御赐套装", 6, -1)
    --self:AddNumText("#G真重楼重洗", 6, -2)
   -- self:AddNumText("#G装备进阶", 6, -801)
    -- self:AddNumText("#G道具兑换", 6, -901)
    -- self:AddNumText("#G低级称号兑换", 6, -2001)
    -- self:AddNumText("#G高级称号兑换", 6, -3001)
    -- self:AddNumText("兑换18级套装", 6, 2000)
    -- self:AddNumText("兑换30级套装", 6, 3000)
    -- self:AddNumText("兑换40级套装", 6, 4000)
    -- self:AddNumText("兑换50级套装", 6, 5000)
    -- self:AddNumText("兑换60级套装", 6, 6000)
    -- self:AddNumText("兑换70级套装", 6, 7000)
    -- self:AddNumText("兑换80级套装", 6, 8000)
    -- self:AddNumText("兑换90级套装", 6, 9000)
    --self:AddNumText("魔兵天降介绍", 11, 11000)
    self:AddNumText("Ma Binh Thiên Giáng", 6, 10000)
    --self:AddNumText("兑换骠骑套装", 6, 14000)
    --self:AddNumText("关于骠骑套装", 11, 13000)
    self:AddNumText("Rời khỏi...", 0, 0)
    -- for i, eventId in pairs(self.g_eventList) do
    --     self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    -- end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function osuzhou_liangshicheng:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function osuzhou_liangshicheng:OnEventRequest(selfId, targetId, arg, index)
    local nNumText = index
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(findId, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
	if index == 0 then
		self:UpdateEventList(selfId, targetId)
		return
	end
	
	
	if index == -1 then
		self:BeginEvent(self.script_id)
		self:AddText("  Xin chọn bộ trang bị")
		self:AddNumText("Đổi Bộ Trang bị cấp 18", 6, 2000)
		self:AddNumText("Đổi Bộ Trang bị cấp 30", 6, 3000)
		self:AddNumText("Đổi Bộ Trang bị cấp 40", 6, 4000)
		self:AddNumText("Đổi Bộ Trang bị cấp 50", 6, 5000)
		self:AddNumText("Đổi Bộ Trang bị cấp 60", 6, 6000)
		self:AddNumText("Đổi Bộ Trang bị cấp 70", 6, 7000)
		self:AddNumText("Đổi Bộ Trang bị cấp 80", 6, 8000)
		self:AddNumText("Đổi Bộ Trang bị cấp 90", 6, 9000)
		self:AddNumText("Trở về trang chủ", 11, 0)
		self:EndEvent()
		self:DispatchEventList(selfId, targetId)
		return
	elseif index == -2 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:UICommand_AddInt(self.script_id)
        self:UICommand_AddInt(self.need_chongxi_itema)
        self:UICommand_AddInt(self.need_chongxi_itemb)
        self:UICommand_AddInt(self.need_chongxi_item_count)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 815052022)
	end
	
	
	
	
	--兑换臻品装备

	if index >= -900 and index <= -801 then
		local page = -1 * index - 800
		local show_count = 10
		local down = show_count * page
		local up = down - show_count + 1
		local text = "Tiến giai %s"
		local msg
		
		self:BeginEvent(self.script_id)
		self:AddText("  Danh sách trân phẩm")
		if page > 1 then
			self:AddNumText("#BTrang trước", 6, -800 - page + 1)
		end
		for i = up,down do
			if self.up_level_ini[i] then
				msg = string.format(text,self.up_level_ini[i].name)
				self:AddNumText(msg,6,-1000 - i)
			else
				break
			end
		end
		if #self.up_level_ini > down then
			self:AddNumText("#BTrang sau", 6, -800 - page - 1)
		end
		self:AddNumText("Trở về trang chủ", 11, 0)
		self:EndEvent()
		self:DispatchEventList(selfId, targetId)
		return
	end
	if index >= -2000 and index <= -1001 then
		local pos = -1 * index - 1000
		self:EquipJinJieNoUI(selfId, pos)
		return
	end
	if index >= -1000 and index <= -901 then
		local page = -1 * index - 900
		local show_count = 10
		local down = show_count * page
		local up = down - show_count + 1
		local text = "Đổi %s"
		local msg
		
		self:BeginEvent(self.script_id)
		self:AddText("  Danh sách trân phẩm")
		if page > 1 then
			self:AddNumText("#BTrang trước", 6, -900 - page + 1)
		end
		for i = up,down do
			if self.change_item_ini[i] then
				msg = string.format(text,self.change_item_ini[i].name)
				self:AddNumText(msg,6,-2000 - i)
			else
				break
			end
		end
		if #self.change_item_ini > down then
			self:AddNumText("#BTrang sau", 6, -900 - page - 1)
		end
		self:AddNumText("Trở về trang chủ", 11, 0)
		self:EndEvent()
		self:DispatchEventList(selfId, targetId)
		return
	end
	-- 检查是否所有低级称号都已兑换
	local function CheckAllLowTitlesExchanged(selfId)
		for _, title_info in ipairs(self.low_title_exchange) do
			if not self:LuaFnHaveAgname(selfId, title_info.titleid) then
				return false
			end
		end
		return true
	end
	
	-- 获取可用道具总数（绑定+非绑定）
	local function GetTotalItemCount(selfId, item_ids)
		local total = 0
		for _, item_id in ipairs(item_ids) do
			total = total + self:LuaFnGetAvailableItemCount(selfId, item_id)
		end
		return total
	end
	
	-- 扣除道具（优先扣除绑定的）
	local function DelItems(selfId, item_ids, count)
		local remaining = count
		for _, item_id in ipairs(item_ids) do
			if remaining <= 0 then
				break
			end
			local have_count = self:LuaFnGetAvailableItemCount(selfId, item_id)
			if have_count > 0 then
				local del_count = math.min(have_count, remaining)
				if not self:LuaFnDelAvailableItem(selfId, item_id, del_count) then
					return false
				end
				remaining = remaining - del_count
			end
		end
		return remaining == 0
	end
	
	-- 低级称号兑换列表
	if index == -2001 then
		self:BeginEvent(self.script_id)
		self:AddText("  Đổi danh hiệu cấp thấp (50 chứng nhận danh hiệu)")
		local display_count = 0
		for i, title_info in ipairs(self.low_title_exchange) do
			local has_title = self:LuaFnHaveAgname(selfId, title_info.titleid)
			-- 已兑换的称号不显示
			if not has_title then
				display_count = display_count + 1
				local total_count = GetTotalItemCount(selfId, title_info.needitem)
				local has_item = total_count >= title_info.needcount
				local text = title_info.titlename
				if not has_item then
					text = text .. "(Không đủ nguyên liệu)"
				end
				-- 使用原始索引i，这样兑换时能正确找到对应的称号
				self:AddNumText(text, 6, -4000 - i)
			end
		end
		if display_count == 0 then
			self:AddText("  Mọi danh hiệu cấp thấp đã đổi xong")
		end
		self:AddNumText("Trở về trang chủ", 11, 0)
		self:EndEvent()
		self:DispatchEventList(selfId, targetId)
		return
	end
	
	-- 高级称号兑换列表
	if index == -3001 then
		-- 检查是否所有低级称号都已兑换
		if not CheckAllLowTitlesExchanged(selfId) then
			self:notify_tips(selfId, "Cần đổi hết danh hiệu cấp thấp mới đổi cấp cao được")
			return
		end
		self:BeginEvent(self.script_id)
		self:AddText("  Đổi danh hiệu cấp cao (100 chứng nhận danh hiệu)")
		local display_count = 0
		for i, title_info in ipairs(self.high_title_exchange) do
			local has_title = self:LuaFnHaveAgname(selfId, title_info.titleid)
			-- 已兑换的称号不显示
			if not has_title then
				display_count = display_count + 1
				local total_count = GetTotalItemCount(selfId, title_info.needitem)
				local has_item = total_count >= title_info.needcount
				local text = title_info.titlename
				if not has_item then
					text = text .. "(Không đủ nguyên liệu)"
				end
				-- 使用原始索引i，这样兑换时能正确找到对应的称号
				self:AddNumText(text, 6, -5000 - i)
			end
		end
		if display_count == 0 then
			self:AddText("  Mọi danh hiệu cấp cao đã đổi xong")
		end
		self:AddNumText("Trở về trang chủ", 11, 0)
		self:EndEvent()
		self:DispatchEventList(selfId, targetId)
		return
	end
	
	-- 处理低级称号兑换
	if index >= -4010 and index <= -4001 then
		local pos = -1 * index - 4000
		local title_info = self.low_title_exchange[pos]
		if not title_info then
			return
		end
		-- 检查是否已有称号
		if self:LuaFnHaveAgname(selfId, title_info.titleid) then
			self:notify_tips(selfId, "Bạn đã có danh hiệu này rồi")
			return
		end
		-- 检查材料是否足够（绑定+非绑定）
		local total_count = GetTotalItemCount(selfId, title_info.needitem)
		if total_count < title_info.needcount then
			self:notify_tips(selfId, string.format("Không đủ chứng nhận danh hiệu, cần %d", title_info.needcount))
			return
		end
		-- 扣除材料（优先扣除绑定的）
		if not DelItems(selfId, title_info.needitem, title_info.needcount) then
			self:notify_tips(selfId, "Khấu trừ Nguyên liệu thất bại")
			return
		end
		-- 给予称号
		self:LuaFnAddNewAgname(selfId, title_info.titleid)
		self:notify_tips(selfId, string.format("Đổi danh hiệu thành công: %s", title_info.titlename))
		self:ShowObjBuffEffect(selfId, selfId, -1, 18)
		return
	end
	
	-- 处理高级称号兑换
	if index >= -5010 and index <= -5001 then
		-- 检查是否所有低级称号都已兑换
		if not CheckAllLowTitlesExchanged(selfId) then
			self:notify_tips(selfId, "Cần đổi hết danh hiệu cấp thấp mới đổi cấp cao được")
			return
		end
		local pos = -1 * index - 5000
		local title_info = self.high_title_exchange[pos]
		if not title_info then
			return
		end
		-- 检查是否已有称号
		if self:LuaFnHaveAgname(selfId, title_info.titleid) then
			self:notify_tips(selfId, "Bạn đã có danh hiệu này rồi")
			return
		end
		-- 检查材料是否足够（绑定+非绑定）
		local total_count = GetTotalItemCount(selfId, title_info.needitem)
		if total_count < title_info.needcount then
			self:notify_tips(selfId, string.format("Không đủ chứng nhận danh hiệu, cần %d", title_info.needcount))
			return
		end
		-- 扣除材料（优先扣除绑定的）
		if not DelItems(selfId, title_info.needitem, title_info.needcount) then
			self:notify_tips(selfId, "Khấu trừ Nguyên liệu thất bại")
			return
		end
		-- 给予称号
		self:LuaFnAddNewAgname(selfId, title_info.titleid)
		self:notify_tips(selfId, string.format("Đổi danh hiệu thành công: %s", title_info.titlename))
		self:ShowObjBuffEffect(selfId, selfId, -1, 18)
		return
	end
	
	if index >= -3000 and index <= -2001 then
		local pos = -1 * index - 2000
		local change_item_ini = self.change_item_ini[pos]
		if not change_item_ini then
			return
		end
		local max_count = #change_item_ini.need
		local ui_msg = string.format("#{DHDJ_250516_%d}",200 + max_count)
		local need = "%08d%08d%d"
		local need_str = {}
		local nstr
		for i,j in ipairs(change_item_ini.need) do
			nstr = string.format(need,j.id[1],j.id[2],j.num)
			table.insert(need_str,nstr)
		end
		self:BeginUICommand()
		self:UICommand_AddInt(targetId)
		self:UICommand_AddInt(self.script_id)
		self:UICommand_AddInt(max_count)
		self:UICommand_AddInt(change_item_ini.award_id)
		self:UICommand_AddInt(change_item_ini.award_count)
		self:UICommand_AddInt(pos)
		self:UICommand_AddInt(2)
		self:UICommand_AddStr("ItemChange")
		self:UICommand_AddStr(ui_msg)
		self:UICommand_AddStr(change_item_ini.name)
		for _,j in ipairs(need_str) do
			self:UICommand_AddStr(j)
		end
		self:EndUICommand()
		self:DispatchUICommand(selfId,615052021)
		return
	end

	--师门套装兑换列
    if nNumText == 1000 then
        self:BeginEvent(self.script_id)
        self:AddNumText("Lệnh bài tân thủ cấp 1 đổi bộ sư môn cấp 20", 0, 1100)
        self:AddNumText("Lệnh bài tân thủ cấp 2 đổi bộ sư môn cấp 30", 0, 1200)
        self:AddNumText("Lệnh bài tân thủ cấp 3 đổi bộ sư môn cấp 40", 0, 1300)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
    if nNumText == 1100 then
        self:BeginEvent(self.script_id)
        self:AddText(" #{YD_20080421_215}")
        self:AddText(" #{YD_20080421_216}"..self:GetItemName(40004448).."”".."1#{YD_20080421_217}")
        for i = 1,2 do
            self:AddRadioItemBonus(self.MenPaiEquipInfo[self:GetMenPai(selfId) + 1][1][i],4)
        end
        self:EndEvent()
        self:DispatchMissionContinueInfo(selfId,targetId,23100601, 0)
    elseif nNumText == 1200 then
        self:BeginEvent(self.script_id)
        self:AddText(" #{YD_20080421_215}")
        self:AddText(" #{YD_20080421_216}"..self:GetItemName(40004449).."”".."1#{YD_20080421_217}")
        for i = 1,3 do
            self:AddRadioItemBonus(self.MenPaiEquipInfo[self:GetMenPai(selfId) + 1][2][i],4)
        end
        self:EndEvent()
        self:DispatchMissionContinueInfo(selfId,targetId,23100601, 0)
    elseif nNumText == 1300 then
        self:BeginEvent(self.script_id)
        self:AddText(" #{YD_20080421_215}")
        self:AddText(" #{YD_20080421_216}"..self:GetItemName(40004450).."”".."1#{YD_20080421_217}")
        for i = 1,2 do
            self:AddRadioItemBonus(self.MenPaiEquipInfo[self:GetMenPai(selfId) + 1][3][i],4)
        end
        self:EndEvent()
        self:DispatchMissionContinueInfo(selfId,targetId,23100601, 0)
    end
    --御赐套装系列兑换
    if nNumText >= 2000 and nNumText <= 3000 then
        self:BeginEvent(self.script_id)
            self:AddText(" #{JPZB_0610_02}")
            self:AddNumText("Đổi Y phục", 0, nNumText + 100)
            self:AddNumText("Đổi Yêu Đái", 0, nNumText + 200)
            self:AddNumText("Đổi Hộ Thủ", 0, nNumText + 300)
            self:AddNumText("Đổi Giày", 0, nNumText + 400)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
    if nNumText >= 4000 and nNumText <= 5000 then
        self:BeginEvent(self.script_id)
            self:AddText(" #{JPZB_0610_02}")
            self:AddNumText("Đổi Y phục", 0, nNumText + 100)
            self:AddNumText("Đổi Yêu Đái", 0, nNumText + 200)
            self:AddNumText("Đổi Hộ Thủ", 0, nNumText + 300)
            self:AddNumText("Đổi Giày", 0, nNumText + 400)
            self:AddNumText("Đổi Hộ Uyển", 0, nNumText + 500)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
    if nNumText >= 6000 and nNumText <= 9000 then
        self:BeginEvent(self.script_id)
            self:AddText(" #{JPZB_0610_02}")
            self:AddNumText("Đổi Y phục", 0, nNumText + 100)
            self:AddNumText("Đổi Yêu Đái", 0, nNumText + 200)
            self:AddNumText("Đổi Hộ Thủ", 0, nNumText + 300)
            self:AddNumText("Đổi Giày", 0, nNumText + 400)
            self:AddNumText("Đổi Hộ Uyển", 0, nNumText + 500)
            self:AddNumText("Đổi Trục Kiên", 0, nNumText + 600)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
    local nIndex,nIndex_2 = 0,0
    if nNumText == 2100 then
        nIndex,nIndex_2 = 1,5
    elseif nNumText == 2200 then
        nIndex,nIndex_2 = 2,6
    elseif nNumText == 2300 then
        nIndex,nIndex_2 = 3,7
    elseif nNumText == 2400 then
        nIndex,nIndex_2 = 4,8
    elseif nNumText == 3100 then
        nIndex,nIndex_2 = 9,13
    elseif nNumText == 3200 then
        nIndex,nIndex_2 = 10,14
    elseif nNumText == 3300 then
        nIndex,nIndex_2 = 11,15
    elseif nNumText == 3400 then
        nIndex,nIndex_2 = 12,16
    elseif nNumText == 4100 then
        nIndex,nIndex_2 = 17,22
    elseif nNumText == 4200 then
        nIndex,nIndex_2 = 18,23
    elseif nNumText == 4300 then
        nIndex,nIndex_2 = 19,24
    elseif nNumText == 4400 then
        nIndex,nIndex_2 = 20,25
    elseif nNumText == 4500 then
        nIndex,nIndex_2 = 21,26
    elseif nNumText == 5100 then
        nIndex,nIndex_2 = 27,32
    elseif nNumText == 5200 then
        nIndex,nIndex_2 = 28,33
    elseif nNumText == 5300 then
        nIndex,nIndex_2 = 29,34
    elseif nNumText == 5400 then
        nIndex,nIndex_2 = 30,35
    elseif nNumText == 5500 then
        nIndex,nIndex_2 = 31,36
    elseif nNumText == 6100 then
        nIndex,nIndex_2 = 37,43
    elseif nNumText == 6200 then
        nIndex,nIndex_2 = 38,44
    elseif nNumText == 6300 then
        nIndex,nIndex_2 = 39,45
    elseif nNumText == 6400 then
        nIndex,nIndex_2 = 40,46
    elseif nNumText == 6500 then
        nIndex,nIndex_2 = 41,47
    elseif nNumText == 6600 then
        nIndex,nIndex_2 = 42,48
    elseif nNumText == 7100 then
        nIndex,nIndex_2 = 49,55
    elseif nNumText == 7200 then
        nIndex,nIndex_2 = 50,56
    elseif nNumText == 7300 then
        nIndex,nIndex_2 = 51,57
    elseif nNumText == 7400 then
        nIndex,nIndex_2 = 52,58
    elseif nNumText == 7500 then
        nIndex,nIndex_2 = 53,59
    elseif nNumText == 7600 then
        nIndex,nIndex_2 = 54,60
    elseif nNumText == 8100 then
        nIndex,nIndex_2 = 61,67
    elseif nNumText == 8200 then
        nIndex,nIndex_2 = 62,68
    elseif nNumText == 8300 then
        nIndex,nIndex_2 = 63,69
    elseif nNumText == 8400 then
        nIndex,nIndex_2 = 64,70
    elseif nNumText == 8500 then
        nIndex,nIndex_2 = 65,71
    elseif nNumText == 8600 then
        nIndex,nIndex_2 = 66,72
    elseif nNumText == 9100 then
        nIndex,nIndex_2 = 73,79
    elseif nNumText == 9200 then
        nIndex,nIndex_2 = 74,80
    elseif nNumText == 9300 then
        nIndex,nIndex_2 = 75,81
    elseif nNumText == 9400 then
        nIndex,nIndex_2 = 76,82
    elseif nNumText == 9500 then
        nIndex,nIndex_2 = 77,83
    elseif nNumText == 9600 then
        nIndex,nIndex_2 = 78,84
    end
    if nNumText >= 2100 and nNumText <= 9600 then
        self:BeginEvent(self.script_id)
        self:AddText(" #{YD_20080421_215}")
        self:AddText(" #{YD_20080421_216}"..self:GetItemName(self.g_ItemDataInfo[nIndex]["needItem"]).."“"..self.g_ItemDataInfo[nIndex]["needItemNum"].."”#{YD_20080421_217}")
        self:AddRadioItemBonus(self.g_ItemDataInfo[nIndex]["nPrizeItem"],4)
        self:AddRadioItemBonus(self.g_ItemDataInfo[nIndex_2]["nPrizeItem"],4)
        self:EndEvent()
        self:DispatchMissionContinueInfo(selfId,targetId,self.script_id, 0)
    end
    --骠骑套装兑换
    if nNumText == 14000 then
        self:BeginEvent(self.script_id)
        self:AddText(" #{JJTZ_090826_06}")
        self:AddNumText("Đổi Bộ Phiêu Kỵ cấp 30", 6, nNumText + 100)
        self:AddNumText("Đổi Bộ Phiêu Kỵ cấp 50", 6, nNumText + 200)
        self:AddNumText("Đổi Bộ Phiêu Kỵ cấp 70", 6, nNumText + 300)
        self:AddNumText("Đổi Bộ Phiêu Kỵ cấp 90", 6, nNumText + 400)
        self:AddNumText("#{JJTZ_090826_24}", 0, 20000)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
    if nNumText == 20000 then
        self:OnDefaultEvent(selfId, targetId)
    end
    if nNumText >= 14100 and nNumText <= 14400 then
        self:BeginEvent(self.script_id)
        self:AddText(" #{JPZB_0610_02}")
        self:AddNumText("#{JJTZ_090826_13}", 0, nNumText + 1001)
        self:AddNumText("#{JJTZ_090826_14}", 0, nNumText + 1002)
        self:AddNumText("#{JJTZ_090826_15}", 0, nNumText + 1003)
        self:AddNumText("#{JJTZ_090826_16}", 0, nNumText + 1004)
        self:AddNumText("#{JJTZ_090826_17}", 0, nNumText + 1005)
        self:AddNumText("#{JJTZ_090826_18}", 0, nNumText + 1006)
        self:AddNumText("#{JJTZ_090826_19}", 0, nNumText + 1007)
        self:AddNumText("#{JJTZ_090826_20}", 0, nNumText + 1008)
        self:AddNumText("#{JJTZ_090826_21}", 0, nNumText + 1009)
        self:AddNumText("#{JJTZ_090826_22}", 0, nNumText + 1010)
        self:AddNumText("#{JJTZ_090826_23}", 0, nNumText + 1011)
		self:AddNumText("#{JJTZ_090826_24}", 0, 14000)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
    if nNumText >= 15101 and nNumText <= 15411 then
        self:BeginEvent(self.script_id)
        self:AddText("  #{JJTZ_090826_25}")
        for i = 1,#self.BiaoQiEquipInfo[(math.floor(nNumText/100)) % 10][(nNumText % 100)] do
            self:AddRadioItemBonus(self.BiaoQiEquipInfo[(math.floor(nNumText/100)) % 10][(nNumText % 100)][i],4)
        end
        self:EndEvent()
        self:DispatchMissionContinueInfo(selfId,targetId,23100602, 0)
    end
    --重楼兑换
    if nNumText == 10000 then
        self:BeginEvent(self.script_id)
        --self:AddText("  #{JPZB_0610_06}")
		self:AddText("  Chào thiếu hiệp, ta có trang bị Trùng Lâu trong truyền thuyết, đủ nguyên liệu là đổi được.#r#GNhẫn Trùng Lâu:#YTrùng Lâu Chi Lệ*1#r#GNgọc Trùng Lâu:#YTrùng Lâu Chi Mang*1#r#GChuỗi Trùng Lâu:#YTrùng Lâu Chi Phong*40#r#GGiáp Trùng Lâu:#YThiên Địa Minh Châu*40")
        for i = 85,88 do
            self:AddRadioItemBonus(self.g_ItemDataInfo[i]["nPrizeItem"],4)
        end
        self:EndEvent()
        self:DispatchMissionContinueInfo(selfId,targetId,self.script_id, 0)
    end
    if nNumText == 0 then
        self:BeginUICommand()
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1000)
        return
    end
    if nNumText == 11000 then
        self:BeginEvent(self.script_id)
        self:AddText("#{JPZB_20080523_01}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
    if nNumText == 13000 then
        self:BeginEvent(self.script_id)
        self:AddText("#{JJTZ_090826_05}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
    end
end

function osuzhou_liangshicheng:OnMissionAccept(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            local ret = self:CallScriptFunction(missionScriptId, "CheckAccept", selfId)
            if ret > 0 then
                self:CallScriptFunction(missionScriptId, "OnAccept", selfId)
            end
            return
        end
    end
end

function osuzhou_liangshicheng:OnMissionRefuse(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:UpdateEventList(selfId, targetId)
            return
        end
    end
end

function osuzhou_liangshicheng:OnMissionContinue(selfId, targetId, missionScriptId)
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnContinue", selfId, targetId)
            return
        end
    end
end

function osuzhou_liangshicheng:ExchangeItem(selfId, targetId, selectRadioId)
    local nItemIndex = -1
    for i = 1, #(self.g_ItemDataInfo) do
        if self.g_ItemDataInfo[i]["nPrizeItem"] == selectRadioId then
            nItemIndex = i
            break
        end
    end
    if nItemIndex == -1 then
        return
    end
    local HaveItenCost = self:LuaFnGetAvailableItemCount(selfId, self.g_ItemDataInfo[nItemIndex]["needItem"])
    if HaveItenCost < self.g_ItemDataInfo[nItemIndex]["needItemNum"] then
        self:BeginEvent(self.script_id)
        self:AddText(
            string.format(
                "Bạn thiếu:#G%s cái %s, không đủ tư cách đổi.",
                self.g_ItemDataInfo[nItemIndex]["needItemNum"],
                self:GetItemName(self.g_ItemDataInfo[nItemIndex]["needItem"])
            )
        )
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    self:BeginAddItem()
    self:AddItem(self.g_ItemDataInfo[nItemIndex]["nPrizeItem"], self.g_ItemDataInfo[nItemIndex]["nPrizeItemNum"])
    if not self:EndAddItem(selfId) then
        self:BeginEvent(self.script_id)
        self:AddText("Túi đồ không đủ chỗ trống.")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if
        not self:LuaFnDelAvailableItem(
            selfId,
            self.g_ItemDataInfo[nItemIndex]["needItem"],
            self.g_ItemDataInfo[nItemIndex]["needItemNum"]
        )
    then
        self:BeginEvent(self.script_id)
        self:AddText("Khấu trừ vật phẩm thất bại")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    self:AddItemListToHuman(selfId)
end

function osuzhou_liangshicheng:OnDie(selfId, killerId)
end

function osuzhou_liangshicheng:OnMissionSubmit(selfId, targetId, missionScriptId, selectRadioId)
    if missionScriptId == self.script_id then
        self:ExchangeItem(selfId, targetId, selectRadioId)
        return
    end
    if missionScriptId == 23100601 then
        local nIndex,EquipIdx = 0,0
        local DuiHuanItem = {40004448,40004449,40004450}
        for i = 1,#self.MenPaiEquipInfo[self:GetMenPai(selfId) + 1] do
            for j = 1,#self.MenPaiEquipInfo[self:GetMenPai(selfId) + 1][i] do
                if selectRadioId == self.MenPaiEquipInfo[self:GetMenPai(selfId) + 1][i][j] then
                    nIndex = i
                    EquipIdx = j
                    break
                end
            end
        end
        if self:LuaFnGetAvailableItemCount(selfId,DuiHuanItem[nIndex]) < 1 then
            self:notify_tips(selfId,"#{YD_20080421_218}"..self:GetItemName(DuiHuanItem[nIndex]))
            return
        end
        --先判断背包格子够不够装下
        self:BeginAddItem()
        self:AddItem(self.MenPaiEquipInfo[self:GetMenPai(selfId) + 1][nIndex][EquipIdx],1)
        if not self:EndAddItem(selfId) then
            self:BeginEvent(self.script_id)
            self:AddText("Túi đồ không đủ chỗ trống.")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
            return
        end
        if not self:LuaFnDelAvailableItem(selfId,DuiHuanItem[nIndex],1) then
            self:BeginEvent(self.script_id)
            self:AddText("#{YD_20080421_220}")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
            return
        end
        self:notify_tips(selfId,"#{YD_20080421_221}")
        self:AddItemListToHuman(selfId)
        return
    end
    if missionScriptId == 23100602 then
        if self:LuaFnGetAvailableItemCount(selfId,30505197) < 1 then
            self:notify_tips(selfId,"#{JJTZ_090826_27}")
            return
        end
        --先判断背包格子够不够装下
        self:BeginAddItem()
        self:AddItem(selectRadioId,1)
        if not self:EndAddItem(selfId) then
            self:BeginEvent(self.script_id)
            self:AddText("#{JJTZ_090826_28}")
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
            return
        end
        if not self:LuaFnDelAvailableItem(selfId,30505197,1) then
            self:notify_tips(selfId,"#{JJTZ_090826_27}")
            return
        end
        self:notify_tips(selfId,"#{JJTZ_090826_29}")
        self:AddItemListToHuman(selfId)
        return
    end
    for i, findId in pairs(self.g_eventList) do
        if missionScriptId == findId then
            self:CallScriptFunction(missionScriptId, "OnSubmit", selfId, targetId, selectRadioId)
            return
        end
    end
end

return osuzhou_liangshicheng
