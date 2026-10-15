--云晓晓

local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_yunxiaoxiao = class("osuzhou_yunxiaoxiao", script_base)
local packet_def = require "game.packet"

function osuzhou_yunxiaoxiao:OnDefaultEvent(selfId, targetId)
	self:BeginEvent(self.script_id)
    self:AddText("#{SHXT_20211230_237}")
    self:AddNumText("#{SHXT_20211230_246}", 6, 103)
    self:AddNumText("#{SHXT_20211230_53}", 6, 105)
    self:AddNumText("#{SHXT_20211230_52}", 6, 104)
    self:AddNumText("#{SHXT_20211230_54}", 6, 106)
    self:AddNumText("Cùng Kỳ Dung Hồn Kỹ năng Thôn Phệ", 6, 108)
    self:AddNumText("Cùng Kỳ Dung Hồn Kỹ năng Hoàn Nguyên", 6, 109)
    self:AddNumText("#{SHXT_20211230_55}", 11, 107)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function osuzhou_yunxiaoxiao:OnEventRequest(selfId, targetId, arg, index)
    if index == 103 then
        self:BeginUICommand()
		self:UICommand_AddInt(1)
        self:UICommand_AddInt(targetId)
		self:EndUICommand()
		self:DispatchUICommand(selfId, 80012801)
        return
    end
    --穷奇吞噬
    if index == 108 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
		self:EndUICommand()
		self:DispatchUICommand(selfId, 99852201)
        return
    end
    --穷奇还原
    if index == 109 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
		self:EndUICommand()
		self:DispatchUICommand(selfId, 99852203)--899852203
        return
    end
    if index == 105 then
        self:BeginUICommand()
		self:UICommand_AddInt(1)
        self:UICommand_AddInt(targetId)
		self:EndUICommand()
		self:DispatchUICommand(selfId, 80012705)
        return
    end
    if index == 104 then
        self:BeginUICommand()
		self:UICommand_AddInt(1)
        self:UICommand_AddInt(targetId)
		self:EndUICommand()
		self:DispatchUICommand(selfId, 80012704)
        return
    end
    if index == 106 then
        self:BeginUICommand()
		self:UICommand_AddInt(1)
        self:UICommand_AddInt(targetId)
		self:EndUICommand()
		self:DispatchUICommand(selfId, 80012706)
        return
    end
    if index == 107 then
        self:BeginEvent(self.script_id)
        self:AddNumText("#{SHXT_20211230_238}", 11, 117)
        self:AddNumText("#{SHXT_20211230_150}", 11, 118)
        self:AddNumText("#{SHXT_20211230_217}", -1, 120)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 117 then
        self:BeginEvent(self.script_id)
        self:AddText("#{SHXT_20211230_239}")
        self:AddNumText("#{SHXT_20211230_217}", -1, 107)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 118 then
        self:BeginEvent(self.script_id)
        self:AddText("#{SHXT_20211230_158}")
        self:AddNumText("#{SHXT_20211230_217}", -1, 107)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 120 then
        self:OnDefaultEvent(selfId, targetId)
        return
    end
end

local PetSoulMaterials = {
    { 38002525, 38002526, 38002527, 38002528, 38002529},
    { 38002520, 38002521, 38002522, 38002523, 38002524},
    { 38002515, 38002516, 38002517, 38002518, 38002519},
    { 38002732 }
}

local TransformTargets = {
    [38002515] = PetSoulMaterials[3],
    [38002516] = PetSoulMaterials[3],
    [38002517] = PetSoulMaterials[3],
    [38002518] = PetSoulMaterials[3],
    [38002519] = PetSoulMaterials[3],

    [38002520] = PetSoulMaterials[2],
    [38002521] = PetSoulMaterials[2],
    [38002522] = PetSoulMaterials[2],
    [38002523] = PetSoulMaterials[2],
    [38002524] = PetSoulMaterials[2],

    [38002525] = PetSoulMaterials[1],
    [38002526] = PetSoulMaterials[1],
    [38002527] = PetSoulMaterials[1],
    [38002528] = PetSoulMaterials[1],
    [38002529] = PetSoulMaterials[1],
}
function osuzhou_yunxiaoxiao:OnPetSoulPieceZhuanHua(selfId, targetId, BagPos_1, BagPos_2, TransformTargetIndex)
    print("osuzhou_yunxiaoxiao:OnPetSoulPieceZhuanHua", selfId, BagPos_1, BagPos_2, TransformTargetIndex)
    if not BagPos_1 or not BagPos_2 or BagPos_2 == BagPos_1 then
        self:notify_tips(selfId, "Vị trí túi bất thường, xin thao tác lại")
        return
	elseif not TransformTargetIndex or TransformTargetIndex < 1 or TransformTargetIndex > 5 then
        self:notify_tips(selfId, "Chọn bất thường")
        return
    end
	local Item_Index_1 = self:GetBagItemIndex(selfId, BagPos_1)
    local Item_Index_2 = self:GetBagItemIndex(selfId, BagPos_2)
	-- local additem1,additem2
	-- if Item_Index_1 ~= define.INVAILD_ID then
		-- additem1 = TransformTargets[Item_Index_1][TransformTargetIndex]
	-- end
	-- if Item_Index_2 ~= define.INVAILD_ID then
		-- additem2 = TransformTargets[Item_Index_2][TransformTargetIndex]
	-- end
	-- local Item_Count_1,Item_Count_2 = 0,0
	-- local bind1,bind2 = true,true
	-- if additem1 and additem2 then
		-- if additem1 ~= additem2 then
			-- self:notify_tips(selfId, "放入的魂玉类型不符")
			-- return
		-- end
		-- Item_Count_1 = self:GetBagItemLayCount(selfId, BagPos_1)
		-- Item_Count_2 = self:GetBagItemLayCount(selfId, BagPos_2)
		-- bind1 = self:GetBagItemIsBind(selfId, BagPos_1)
		-- bind2 = self:GetBagItemIsBind(selfId, BagPos_2)
	-- elseif additem1 then
		-- Item_Count_1 = self:GetBagItemLayCount(selfId, BagPos_1)
		-- bind1 = self:GetBagItemIsBind(selfId, BagPos_1)
	-- elseif additem2 then
		-- Item_Count_2 = self:GetBagItemLayCount(selfId, BagPos_2)
		-- bind2 = self:GetBagItemIsBind(selfId, BagPos_2)
	-- else
        -- self:notify_tips(selfId, "请放入魂玉")
        -- return
	-- end
	-- local delinfo = {}
	-- local addinfo = {}
	-- if Item_Count_1 > 0 then
		-- local count = Item_Count_1 // 2
	-- end
    assert( (Item_Index_1 ~= define.INVAILD_ID) or (Item_Index_2 ~= define.INVAILD_ID))
    local TargetItemIndex
    if Item_Index_1 ~= define.INVAILD_ID and Item_Index_2 ~= define.INVAILD_ID then
        assert(TransformTargets[Item_Index_1] == TransformTargets[Item_Index_2])
        TargetItemIndex = TransformTargets[Item_Index_1][TransformTargetIndex]
    end
    assert(TargetItemIndex)

    local Item_Count_1 = self:GetBagItemLayCount(selfId, BagPos_1)
    local Item_Count_2 = self:GetBagItemLayCount(selfId, BagPos_2)

    local Resist = Item_Count_1 % 2
    local Transformd_Count = (Item_Count_1 - Resist) / 2
    if Transformd_Count > 0 then
        local bind = self:GetBagItemIsBind(selfId, BagPos_1)
		local del = self:LuaFnDecItemLayCount(selfId, BagPos_1, 2 * Transformd_Count)
		if not del then
			return
		end
        if self:TryRecieveItemWithCount(selfId, TargetItemIndex, Transformd_Count, bind) ~= define.INVAILD_ID then
            -- self:LuaFnDecItemLayCount(selfId, BagPos_1, 2 * Transformd_Count)
        end
    end
    if Resist > 0 and Item_Count_2 > 0 then
        Item_Count_2 = Item_Count_2 - 1
        local bind = self:GetBagItemIsBind(selfId, BagPos_1)
		if not bind then
			bind = self:GetBagItemIsBind(selfId, BagPos_2)
		end
		local del = self:LuaFnDecItemLayCount(selfId, BagPos_1, 1)
		if not del then
			return
		end
		del = self:LuaFnDecItemLayCount(selfId, BagPos_2, 1)
		if not del then
			return
		end
        if self:TryRecieveItemWithCount(selfId, TargetItemIndex, 1, bind) ~= define.INVAILD_ID then
            -- self:LuaFnDecItemLayCount(selfId, BagPos_1, 1)
            -- self:LuaFnDecItemLayCount(selfId, BagPos_2, 1)
        end
    end
    Resist = Item_Count_2 % 2
    Transformd_Count = (Item_Count_2 - Resist) / 2
    if Transformd_Count > 0 then
        local bind = self:GetBagItemIsBind(selfId, BagPos_2)
        local del = self:LuaFnDecItemLayCount(selfId, BagPos_2, 2 * Transformd_Count)
		if not del then
			return
		end
        if self:TryRecieveItemWithCount(selfId, TargetItemIndex, Transformd_Count, bind) ~= define.INVAILD_ID then
        end
    end
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 18, 0)
end

local FusionTargets = {
    [38002515] = { cost = 40, id = 70600000},
    [38002516] = { cost = 40, id = 70600001},
    [38002517] = { cost = 40, id = 70600002},
    [38002518] = { cost = 40, id = 70600003},
    [38002519] = { cost = 40, id = 70600004},

    [38002520] = { cost = 30, id = 70600005 },
    [38002521] = { cost = 30, id = 70600006 },
    [38002522] = { cost = 30, id = 70600007 },
    [38002523] = { cost = 30, id = 70600008 },
    [38002524] = { cost = 30, id = 70600009 },

    [38002525] = { cost = 20, id = 70600010 },
    [38002526] = { cost = 20, id = 70600011 },
    [38002527] = { cost = 20, id = 70600012 },
    [38002528] = { cost = 20, id = 70600013 },
    [38002529] = { cost = 20, id = 70600014 },

    [38002732] = { cost = 40, id = 70600015 },
}

function osuzhou_yunxiaoxiao:OnPetSoulFusion(selfId, TargetId, BagPos_1, BagPos_2)
    print("osuzhou_yunxiaoxiao:OnPetSoulFusion", selfId, TargetId, BagPos_1, BagPos_2)
    local Item_Index_1 = self:GetBagItemIndex(selfId, BagPos_1)
    local Item_Index_2 = self:GetBagItemIndex(selfId, BagPos_2)
    if Item_Index_1 ~= define.INVAILD_ID and Item_Index_2 ~= define.INVAILD_ID then
		if Item_Index_1 ~= Item_Index_2 then
			self:notify_tips(selfId, "Hai loại nguyên liệu thú hồn khác nhau.")
			return
		end
	elseif Item_Index_1 == define.INVAILD_ID and Item_Index_2 == define.INVAILD_ID then
        self:notify_tips(selfId, "Thiếu nguyên liệu thú hồn.")
        return
    end
    local space_count = self:LuaFnGetPropertyBagSpace(selfId)
    if space_count < 1 then
        self:notify_tips(selfId, "Túi hành trang không đủ chỗ")
        return
    end
	local idx = Item_Index_1 ~= define.INVAILD_ID and Item_Index_1 or Item_Index_2
    local Target = FusionTargets[idx]
	if not Target then
        self:notify_tips(selfId, "Đạo cụ không khớp.")
        return
    end
    local cost = Target.cost
    local Item_Count_1 = self:GetBagItemLayCount(selfId, BagPos_1)
    local Item_Count_2 = self:GetBagItemLayCount(selfId, BagPos_2)
    if Item_Count_1 + Item_Count_2 < cost then
        return
    end
    local need_bind = false
    if cost > 0 then
        if Item_Count_1 > 0 then
            need_bind = need_bind or self:GetBagItemIsBind(selfId, BagPos_1)
            if Item_Count_1 >= cost then
                self:LuaFnDecItemLayCount(selfId, BagPos_1, cost)
                cost = 0
            else
                cost = cost - Item_Count_1
                self:LuaFnDecItemLayCount(selfId, BagPos_1, Item_Count_1)
            end
        end
    end
    if cost > 0 then
        if Item_Count_2 > 0 then
            need_bind = need_bind or self:GetBagItemIsBind(selfId, BagPos_2)
            if Item_Count_2 >= cost then
                self:LuaFnDecItemLayCount(selfId, BagPos_2, cost)
                cost = 0
            end
        end
    end
    assert(cost == 0, cost)
    self:TryRecieveItem(selfId, Target.id, need_bind)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 18, 0)
end

local petsoulleveldownTable = 
{
    [1] = {2,20000,3,30000,6,60000,6,60000,1,50000,2,100000,4,200000,4,200000,0,0,0,0},
    [2] = {2,20000,3,30000,6,60000,6,60000,1,50000,2,100000,4,200000,4,200000,2,3,6,6},
    [3] = {2,20000,3,30000,6,60000,6,60000,1,50000,2,100000,4,200000,4,200000,4,6,12,12},
    [4] = {2,20000,3,30000,6,60000,6,60000,1,50000,2,100000,4,200000,4,200000,6,9,18,18},
    [5] = {4,40000,6,60000,12,120000,12,120000,1,50000,2,100000,4,200000,4,200000,8,12,24,24},
    [6] = {4,40000,6,60000,12,120000,12,120000,1,50000,2,100000,4,200000,4,200000,12,18,36,36},
    [7] = {4,40000,6,60000,12,120000,12,120000,1,50000,2,100000,4,200000,4,200000,16,24,48,48},
    [8] = {4,40000,6,60000,12,120000,12,120000,1,50000,2,100000,4,200000,4,200000,20,30,60,60},
    [9] = {4,40000,6,60000,12,120000,12,120000,1,50000,2,100000,4,200000,4,200000,24,36,72,72},
    [10] = {6,60000,9,90000,18,180000,18,180000,1,50000,2,100000,4,200000,4,200000,28,42,84,84},
    [11] = {6,60000,9,90000,18,180000,18,180000,2,100000,4,200000,8,400000,8,400000,34,51,102,102},
    [12] = {6,60000,9,90000,18,180000,18,180000,2,100000,4,200000,8,400000,8,400000,40,60,120,120},
    [13] = {6,60000,9,90000,18,180000,18,180000,2,100000,4,200000,8,400000,8,400000,46,69,138,138},
    [14] = {6,60000,9,90000,18,180000,18,180000,2,100000,4,200000,8,400000,8,400000,52,78,156,156},
    [15] = {8,80000,12,120000,24,240000,24,240000,2,100000,4,200000,8,400000,8,400000,58,87,174,174},
    [16] = {8,80000,12,120000,24,240000,24,240000,2,100000,4,200000,8,400000,8,400000,66,99,198,198},
    [17] = {8,80000,12,120000,24,240000,24,240000,2,100000,4,200000,8,400000,8,400000,74,111,222,222},
    [18] = {8,80000,12,120000,24,240000,24,240000,2,100000,4,200000,8,400000,8,400000,82,123,246,246},
    [19] = {8,80000,12,120000,24,240000,24,240000,2,100000,4,200000,8,400000,8,400000,90,135,270,270},
    [20] = {10,100000,15,150000,30,300000,30,300000,2,100000,4,200000,8,400000,8,400000,98,147,294,294},
    [21] = {10,100000,15,150000,30,300000,30,300000,3,150000,6,300000,12,600000,12,600000,108,162,324,324},
    [22] = {10,100000,15,150000,30,300000,30,300000,3,150000,6,300000,12,600000,12,600000,118,177,354,354},
    [23] = {10,100000,15,150000,30,300000,30,300000,3,150000,6,300000,12,600000,12,600000,128,192,384,384},
    [24] = {10,100000,15,150000,30,300000,30,300000,3,150000,6,300000,12,600000,12,600000,138,207,414,414},
    [25] = {12,120000,18,180000,36,360000,36,360000,3,150000,6,300000,12,600000,12,600000,148,222,444,444},
    [26] = {12,120000,18,180000,36,360000,36,360000,3,150000,6,300000,12,600000,12,600000,160,240,480,480},
    [27] = {12,120000,18,180000,36,360000,36,360000,3,150000,6,300000,12,600000,12,600000,172,258,516,516},
    [28] = {12,120000,18,180000,36,360000,36,360000,3,150000,6,300000,12,600000,12,600000,184,276,552,552},
    [29] = {12,120000,18,180000,36,360000,36,360000,3,150000,6,300000,12,600000,12,600000,196,294,588,588},
    [30] = {16,160000,24,240000,48,480000,48,480000,3,150000,6,300000,12,600000,12,600000,208,312,624,624},
    [31] = {16,160000,24,240000,48,480000,48,480000,4,200000,8,400000,16,800000,16,800000,224,336,672,672},
    [32] = {16,160000,24,240000,48,480000,48,480000,4,200000,8,400000,16,800000,16,800000,240,360,720,720},
    [33] = {16,160000,24,240000,48,480000,48,480000,4,200000,8,400000,16,800000,16,800000,256,384,768,768},
    [34] = {16,160000,24,240000,48,480000,48,480000,4,200000,8,400000,16,800000,16,800000,272,408,816,816},
    [35] = {20,200000,30,300000,60,600000,60,600000,4,200000,8,400000,16,800000,16,800000,288,432,864,864},
    [36] = {20,200000,30,300000,60,600000,60,600000,4,200000,8,400000,16,800000,16,800000,308,462,924,924},
    [37] = {20,200000,30,300000,60,600000,60,600000,4,200000,8,400000,16,800000,16,800000,328,492,984,984},
    [38] = {20,200000,30,300000,60,600000,60,600000,4,200000,8,400000,16,800000,16,800000,348,522,1044,1044},
    [39] = {20,200000,30,300000,60,600000,60,600000,4,200000,8,400000,16,800000,16,800000,368,552,1104,1104},
    [40] = {26,260000,39,390000,78,780000,78,780000,4,200000,8,400000,16,800000,16,800000,388,582,1164,1164},
    [41] = {26,260000,39,390000,78,780000,78,780000,5,250000,10,500000,20,1000000,20,1000000,414,621,1242,1242},
    [42] = {26,260000,39,390000,78,780000,78,780000,5,250000,10,500000,20,1000000,20,1000000,440,660,1320,1320},
    [43] = {26,260000,39,390000,78,780000,78,780000,5,250000,10,500000,20,1000000,20,1000000,466,699,1398,1398},
    [44] = {26,260000,39,390000,78,780000,78,780000,5,250000,10,500000,20,1000000,20,1000000,492,738,1476,1476},
    [45] = {32,320000,48,480000,96,960000,96,960000,5,250000,10,500000,20,1000000,20,1000000,518,777,1554,1554},
    [46] = {32,320000,48,480000,96,960000,96,960000,5,250000,10,500000,20,1000000,20,1000000,550,825,1650,1650},
    [47] = {32,320000,48,480000,96,960000,96,960000,5,250000,10,500000,20,1000000,20,1000000,582,873,1746,1746},
    [48] = {32,320000,48,480000,96,960000,96,960000,5,250000,10,500000,20,1000000,20,1000000,614,921,1842,1842},
    [49] = {32,320000,48,480000,96,960000,96,960000,5,250000,10,500000,20,1000000,20,1000000,646,969,1938,1938},
    [50] = {40,400000,60,600000,120,1200000,120,1200000,5,250000,10,500000,20,1000000,20,1000000,678,1017,2034,2034},
    [51] = {40,400000,60,600000,120,1200000,120,1200000,6,300000,12,600000,24,1200000,24,1200000,718,1077,2154,2154},
    [52] = {40,400000,60,600000,120,1200000,120,1200000,6,300000,12,600000,24,1200000,24,1200000,758,1137,2274,2274},
    [53] = {40,400000,60,600000,120,1200000,120,1200000,6,300000,12,600000,24,1200000,24,1200000,798,1197,2394,2394},
    [54] = {40,400000,60,600000,120,1200000,120,1200000,6,300000,12,600000,24,1200000,24,1200000,838,1257,2514,2514},
    [55] = {48,480000,72,720000,144,1440000,144,1440000,6,300000,12,600000,24,1200000,24,1200000,878,1317,2634,2634},
    [56] = {48,480000,72,720000,144,1440000,144,1440000,6,300000,12,600000,24,1200000,24,1200000,926,1389,2778,2778},
    [57] = {48,480000,72,720000,144,1440000,144,1440000,6,300000,12,600000,24,1200000,24,1200000,974,1461,2922,2922},
    [58] = {48,480000,72,720000,144,1440000,144,1440000,6,300000,12,600000,24,1200000,24,1200000,1022,1533,3066,3066},
    [59] = {48,480000,72,720000,144,1440000,144,1440000,6,300000,12,600000,24,1200000,24,1200000,1070,1605,3210,3210},
    [60] = {58,580000,87,870000,174,1740000,174,1740000,6,300000,12,600000,24,1200000,24,1200000,1118,1677,3354,3354},
    [61] = {58,580000,87,870000,174,1740000,174,1740000,7,350000,14,700000,28,1400000,28,1400000,1176,1764,3528,3528},
    [62] = {58,580000,87,870000,174,1740000,174,1740000,7,350000,14,700000,28,1400000,28,1400000,1234,1851,3702,3702},
    [63] = {58,580000,87,870000,174,1740000,174,1740000,7,350000,14,700000,28,1400000,28,1400000,1292,1938,3876,3876},
    [64] = {58,580000,87,870000,174,1740000,174,1740000,7,350000,14,700000,28,1400000,28,1400000,1350,2025,4050,4050},
    [65] = {68,680000,102,1020000,204,2040000,204,2040000,7,350000,14,700000,28,1400000,28,1400000,1408,2112,4224,4224},
    [66] = {68,680000,102,1020000,204,2040000,204,2040000,7,350000,14,700000,28,1400000,28,1400000,1476,2214,4428,4428},
    [67] = {68,680000,102,1020000,204,2040000,204,2040000,7,350000,14,700000,28,1400000,28,1400000,1544,2316,4632,4632},
    [68] = {68,680000,102,1020000,204,2040000,204,2040000,7,350000,14,700000,28,1400000,28,1400000,1612,2418,4836,4836},
    [69] = {68,680000,102,1020000,204,2040000,204,2040000,7,350000,14,700000,28,1400000,28,1400000,1680,2520,5040,5040},
    [70] = {80,800000,120,1200000,240,2400000,240,2400000,7,350000,14,700000,28,1400000,28,1400000,1748,2622,5244,5244},
    [71] = {80,800000,120,1200000,240,2400000,240,2400000,8,400000,16,800000,32,1600000,32,1600000,1828,2742,5484,5484},
    [72] = {80,800000,120,1200000,240,2400000,240,2400000,8,400000,16,800000,32,1600000,32,1600000,1908,2862,5724,5724},
    [73] = {80,800000,120,1200000,240,2400000,240,2400000,8,400000,16,800000,32,1600000,32,1600000,1988,2982,5964,5964},
    [74] = {80,800000,120,1200000,240,2400000,240,2400000,8,400000,16,800000,32,1600000,32,1600000,2068,3102,6204,6204},
    [75] = {92,920000,138,1380000,276,2760000,276,2760000,8,400000,16,800000,32,1600000,32,1600000,2148,3222,6444,6444},
    [76] = {92,920000,138,1380000,276,2760000,276,2760000,8,400000,16,800000,32,1600000,32,1600000,2240,3360,6720,6720},
    [77] = {92,920000,138,1380000,276,2760000,276,2760000,8,400000,16,800000,32,1600000,32,1600000,2332,3498,6996,6996},
    [78] = {92,920000,138,1380000,276,2760000,276,2760000,8,400000,16,800000,32,1600000,32,1600000,2424,3636,7272,7272},
    [79] = {92,920000,138,1380000,276,2760000,276,2760000,8,400000,16,800000,32,1600000,32,1600000,2516,3774,7548,7548},
    [80] = {106,1060000,159,1590000,318,3180000,318,3180000,8,400000,16,800000,32,1600000,32,1600000,2608,3912,7824,7824},
    [81] = {106,1060000,159,1590000,318,3180000,318,3180000,9,450000,18,900000,36,1800000,36,1800000,2714,4071,8142,8142},
    [82] = {106,1060000,159,1590000,318,3180000,318,3180000,9,450000,18,900000,36,1800000,36,1800000,2820,4230,8460,8460},
    [83] = {106,1060000,159,1590000,318,3180000,318,3180000,9,450000,18,900000,36,1800000,36,1800000,2926,4389,8778,8778},
    [84] = {106,1060000,159,1590000,318,3180000,318,3180000,9,450000,18,900000,36,1800000,36,1800000,3032,4548,9096,9096},
    [85] = {120,1200000,180,1800000,360,3600000,360,3600000,9,450000,18,900000,36,1800000,36,1800000,3138,4707,9414,9414},
    [86] = {120,1200000,180,1800000,360,3600000,360,3600000,9,450000,18,900000,36,1800000,36,1800000,3258,4887,9774,9774},
    [87] = {120,1200000,180,1800000,360,3600000,360,3600000,9,450000,18,900000,36,1800000,36,1800000,3378,5067,10134,10134},
    [88] = {120,1200000,180,1800000,360,3600000,360,3600000,9,450000,18,900000,36,1800000,36,1800000,3498,5247,10494,10494},
    [89] = {120,1200000,180,1800000,360,3600000,360,3600000,9,450000,18,900000,36,1800000,36,1800000,3618,5427,10854,10854},
    [90] = {136,1360000,204,2040000,408,4080000,408,4080000,9,450000,18,900000,36,1800000,36,1800000,3738,5607,11214,11214},
    [91] = {136,1360000,204,2040000,408,4080000,408,4080000,10,500000,20,1000000,40,2000000,40,2000000,3874,5811,11622,11622},
    [92] = {136,1360000,204,2040000,408,4080000,408,4080000,10,500000,20,1000000,40,2000000,40,2000000,4010,6015,12030,12030},
    [93] = {136,1360000,204,2040000,408,4080000,408,4080000,10,500000,20,1000000,40,2000000,40,2000000,4146,6219,12438,12438},
    [94] = {136,1360000,204,2040000,408,4080000,408,4080000,10,500000,20,1000000,40,2000000,40,2000000,4282,6423,12846,12846},
    [95] = {152,1520000,228,2280000,456,4560000,456,4560000,10,500000,20,1000000,40,2000000,40,2000000,4418,6627,13254,13254},
    [96] = {152,1520000,228,2280000,456,4560000,456,4560000,10,500000,20,1000000,40,2000000,40,2000000,4570,6855,13710,13710},
    [97] = {152,1520000,228,2280000,456,4560000,456,4560000,10,500000,20,1000000,40,2000000,40,2000000,4722,7083,14166,14166},
    [98] = {152,1520000,228,2280000,456,4560000,456,4560000,10,500000,20,1000000,40,2000000,40,2000000,4874,7311,14622,14622},
    [99] = {152,1520000,228,2280000,456,4560000,456,4560000,10,500000,20,1000000,40,2000000,40,2000000,5026,7539,15078,15078},
    [100] = {0,0,0,0,0,0,0,0,10,500000,20,1000000,40,2000000,40,2000000,5178,7767,15534,15534},
}

function osuzhou_yunxiaoxiao:OnPetSoulLevelDown(selfId,TargetId,bagPos,YuanBaocheck,Isopen)
    local equip_type = self:GetPetEquipType(selfId,bagPos)
    local quanlity = self:GetPetSoulQuanlity(selfId,bagPos)
    if equip_type ~= define.PET_EQUIP_TYPE.SOUL then
        self:notify_tips(selfId, "#{SHXT_20211230_124}")
        return
    end
    local level = self:GetPetSoulLevel(selfId, bagPos)
    if level <= 1 then
        self:notify_tips(selfId, "#{SHXT_20211230_125}")
        return
    end
    local nGiveItemCount,nItemCount,nMoneyCount = self:LuaFnGetPetSoulLeveldownCost(level,quanlity)
    if nGiveItemCount == 0 or nItemCount == 0 or nMoneyCount == 0 then
        self:notify_tips(selfId,"SHXT_20211230_124")
        return
    end
    if self:GetMoney(selfId) + self:GetMoneyJZ(selfId) < nMoneyCount then
        self:notify_tips(selfId,string.format("Không đủ kim tệ, thao tác này tốn %s kim Giao Tử",math.floor(nMoneyCount/1000)))
        return
    end
    if YuanBaocheck == 0 then
        nGiveItemCount = math.floor(tonumber(nGiveItemCount)*0.4)
        if Isopen == 0 then
            self:BeginUICommand()
		    self:UICommand_AddInt(TargetId)
            self:UICommand_AddInt(bagPos)
            self:UICommand_AddInt(YuanBaocheck)
            self:UICommand_AddInt(0)
		    self:EndUICommand()
		    self:DispatchUICommand(selfId, 80012717)
            return
        end
    else
        if self:LuaFnGetAvailableItemCount(selfId,38002531) < nItemCount then
            self:notify_tips(selfId,"#{SHXT_20211230_126}")
            return
        end
        if not self:LuaFnDelAvailableItem(selfId,38002531,nItemCount) then
            self:notify_tips(selfId,"#{SHXT_20211230_126}")
            return
        end
    end
    if nGiveItemCount < 1 then
        self:notify_tips(selfId,"Không có Thăng Hồn Đan hoàn lại, phản hồn thất bại.")
        return
    end
    self:BeginAddItem()
    self:AddItem(38002530,nGiveItemCount,true)
    if not self:EndAddItem(selfId) then
        self:notify_tips(selfId,"Túi đồ không đủ chỗ trống.")
        return
    end
    self:LuaFnCostMoneyWithPriority(selfId,nMoneyCount)

    local obj = self.scene:get_obj_by_id(selfId)
    local container = obj:get_prop_bag_container()
    local item = container:get_item(bagPos)
    if item == nil then
        return false
    end
    if item:get_serial_class() ~= define.ITEM_CLASS.ICLASS_PET_EQUIP then
        return false
    end
    item:get_pet_equip_data():set_level(1)
    local msg = packet_def.GCItemInfo.new()
    msg.bagIndex = bagPos
    msg.item = item:copy_raw_data()
    obj:get_scene():send2client(obj, msg)

    self:AddItemListToHuman(selfId)
    self:notify_tips(selfId,"#{SHXT_20211230_129}")
    self:notify_tips(selfId,string.format("Bạn nhận %s Thăng Hồn Đan!",nGiveItemCount))
    self:LuaFnSendSpecificImpactToUnit(selfId,selfId,selfId,18,0)
end

function osuzhou_yunxiaoxiao:LuaFnGetPetSoulLeveldownCost(level,quanlity)
    local nGiveItemCount,nItemCount,nMoneyCount = 0,0,0
    local nLevelDownCost = petsoulleveldownTable[level]
    if nLevelDownCost == nil then
        return 0,0,0
    end
    if quanlity == 0 then
        nGiveItemCount = nLevelDownCost[quanlity + 17]
        nItemCount = nLevelDownCost[quanlity + 9]
        nMoneyCount = nLevelDownCost[quanlity + 10]
    elseif quanlity == 1 then
        nGiveItemCount = nLevelDownCost[quanlity + 17]
        nItemCount = nLevelDownCost[quanlity + 10]
        nMoneyCount = nLevelDownCost[quanlity + 11]
    elseif quanlity == 2 then
        nGiveItemCount = nLevelDownCost[quanlity + 17]
        nItemCount = nLevelDownCost[quanlity + 11]
        nMoneyCount = nLevelDownCost[quanlity + 12]
    end
    return nGiveItemCount,nItemCount,nMoneyCount
end

function osuzhou_yunxiaoxiao:OnPetSoulSmash(selfId, _, BagPos)
    local equip_type = self:GetPetEquipType(selfId, BagPos)
    if equip_type ~= define.PET_EQUIP_TYPE.SOUL then
        self:notify_tips(selfId, "#{SHXT_20211230_124}")
        return
    end
    local soul_index = self:GetItemTableIndexByIndex(selfId, BagPos)
    if soul_index == 70600015 then
		if 0 == 0 then
			elf:notify_tips(selfId, "Thú hồn này không phân giải được.")
			return
		end
        local level_1_count, level_2_count, is_bind = self:GetQiongQiSoulSmashResult(selfId, BagPos)
        self:BeginAddItem()
        if level_1_count > 0 then
            self:AddItem(38002742, level_1_count, is_bind)
        end
        if level_2_count > 0 then
            self:AddItem(38002742, level_2_count, is_bind)
        end
        local ret = self:EndAddItem(selfId)
        if ret then
            self:LuaFnEraseItem(selfId, BagPos)
            self:AddItemListToHuman(selfId)
        else
            self:notify_tips(selfId, "Túi hành trang không đủ chỗ")
        end
    else
        local item_index, count, is_bind = self:GetPetSoulSmashResult(selfId, BagPos)
        self:BeginAddItem()
        self:AddItem(item_index, count, is_bind)
        local ret = self:EndAddItem(selfId)
        if ret then
            self:LuaFnEraseItem(selfId, BagPos)
            self:AddItemListToHuman(selfId)
        else
            self:notify_tips(selfId, "Túi hành trang không đủ chỗ")
        end
    end
end

function osuzhou_yunxiaoxiao:GetQiongQiSoulSmashResult(selfId, BagPos)
    local configenginer = require "configenginer":getinstance()
    local obj_me = self:get_scene():get_obj_by_id(selfId)
    local prop_bag_container = obj_me:get_prop_bag_container()
    local soul = prop_bag_container:get_item(BagPos)
    local pet_soul_level = soul:get_pet_equip_data():get_pet_soul_level()
    local pet_soul_exp = soul:get_pet_equip_data():get_pet_soul_exp()
    local pet_soul_base = configenginer:get_config("pet_soul_base")
    pet_soul_base = pet_soul_base[soul:get_index()]
    for i = 1, pet_soul_level do
        pet_soul_exp = pet_soul_exp + pet_soul_base.exps[i]
    end
    local level_1_count = pet_soul_exp // 100
    local level_2_count = (pet_soul_exp - (level_1_count * 100)) // 10
    return level_1_count, level_2_count, soul:is_bind()
end

return osuzhou_yunxiaoxiao