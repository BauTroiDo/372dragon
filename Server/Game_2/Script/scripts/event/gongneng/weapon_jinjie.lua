local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ScriptGlobal = require "scripts.ScriptGlobal"
local packet_def = require "game.packet"
local configenginer = require "configenginer":getinstance()
local item_operator = require "item_operator":getinstance()
local weapon_jinjie = class("weapon_jinjie", script_base)
local gbk = require "wire_charset"
weapon_jinjie.script_id = 900069

local function set_attr_bit(mask, shift)
	if not shift then
		return mask
	end
	return mask | (1 << shift)
end

local function boost_attr_values(values, rate)
	if not values or not rate or rate <= 0 then
		return values
	end
	local out = {}
	for i, v in ipairs(values) do
		local nv = tonumber(v) or 0
		if nv > 0 then
			nv = math.floor(nv * rate / 100 + 0.5)
			if nv > 32767 then
				nv = 32767
			end
		end
		out[i] = nv
	end
	return out
end

--特殊进阶
weapon_jinjie.open_special_jj = true			--是否开启九星进阶，重洗
local XILIAN_FORCE_ATTRS = {
	"降低目标冰抵抗",
	"降低目标火抵抗",
	"降低目标玄抵抗",
	"降低目标毒抵抗",
}

local function build_xilian_attr_pool(ex_attrs, attr_range)
	local pool = {}
	local seen = {}
	if type(ex_attrs) == "table" then
		for _, name in ipairs(ex_attrs) do
			if name and not seen[name] then
				table.insert(pool, name)
				seen[name] = true
			end
		end
	end
	for _, name in ipairs(XILIAN_FORCE_ATTRS) do
		if attr_range and attr_range[name] and not seen[name] then
			table.insert(pool, name)
			seen[name] = true
		end
	end
	return pool
end

local function roll_attr_count_by_star(star, base)
	if star == 7 then
		return math.random(7, 10)
	elseif star == 8 then
		return math.random(8, 11)
	elseif star == 9 then
		local rand = math.random(1, 100)
		if rand <= 50 then
			return 12
		elseif rand <= 75 then
			return 13
		elseif rand <= 90 then
			return 14
		elseif rand <= 95 then
			return 15
		end
		return 16
	end

	if base then
		return item_operator:gen_attr_count(base)
	end
	return 0
end

weapon_jinjie.special_jj = {
	[10300103] = 10513141,
	[10300104] = 10513142,
	[10300105] = 10513143,
	[10300106] = 10513144,
	[10300107] = 10513145,
	[10300108] = 10513146,
	[10300109] = 10513147,
	[10300110] = 10513148,
	[10300111] = 10513149,
	[10301103] = 10513150,
	[10301104] = 10513151,
	[10301105] = 10513152,
	[10301106] = 10513153,
	[10301107] = 10513154,
	[10301108] = 10513155,
	[10301109] = 10513156,
	[10301110] = 10513157,
	[10301111] = 10513158,
	[10301203] = 10513159,
	[10301204] = 10513160,
	[10301205] = 10513161,
	[10301206] = 10513162,
	[10301207] = 10513163,
	[10301208] = 10513164,
	[10301209] = 10513165,
	[10301210] = 10513166,
	[10301211] = 10513167,
	[10302103] = 10513168,
	[10302104] = 10513169,
	[10302105] = 10513170,
	[10302106] = 10513171,
	[10302107] = 10513172,
	[10302108] = 10513173,
	[10302109] = 10513174,
	[10302110] = 10513175,
	[10302111] = 10513176,
	[10302203] = 10513177,
	[10302204] = 10513178,
	[10302205] = 10513179,
	[10302206] = 10513180,
	[10302207] = 10513181,
	[10302208] = 10513182,
	[10302209] = 10513183,
	[10302210] = 10513184,
	[10302211] = 10513185,
	[10303103] = 10513186,
	[10303104] = 10513187,
	[10303105] = 10513188,
	[10303106] = 10513189,
	[10303107] = 10513190,
	[10303108] = 10513191,
	[10303109] = 10513192,
	[10303110] = 10513193,
	[10303111] = 10513194,
	[10303203] = 10513195,
	[10303204] = 10513196,
	[10303205] = 10513197,
	[10303206] = 10513198,
	[10303207] = 10513199,
	[10303208] = 10513200,
	[10303209] = 10513201,
	[10303210] = 10513202,
	[10303211] = 10513203,
	[10304103] = 10513204,
	[10304104] = 10513205,
	[10304105] = 10513206,
	[10304106] = 10513207,
	[10304107] = 10513208,
	[10304108] = 10513209,
	[10304109] = 10513210,
	[10304110] = 10513211,
	[10304111] = 10513212,
	[10305103] = 10513213,
	[10305104] = 10513214,
	[10305105] = 10513215,
	[10305106] = 10513216,
	[10305107] = 10513217,
	[10305108] = 10513218,
	[10305109] = 10513219,
	[10305110] = 10513220,
	[10305111] = 10513221,
	[10305203] = 10513222,
	[10305204] = 10513223,
	[10305205] = 10513224,
	[10305206] = 10513225,
	[10305207] = 10513226,
	[10305208] = 10513227,
	[10305209] = 10513228,
	[10305210] = 10513229,
	[10305211] = 10513230,
	[10306103] = 10513231,
	[10306104] = 10513232,
	[10306105] = 10513233,
	[10306106] = 10513234,
	[10306107] = 10513235,
	[10306108] = 10513236,
	[10306109] = 10513237,
	[10306110] = 10513238,
	[10306111] = 10513239,
	[10307103] = 10513240,
	[10307104] = 10513241,
	[10307105] = 10513242,
	[10307106] = 10513243,
	[10307107] = 10513244,
	[10307108] = 10513245,
	[10307109] = 10513246,
	[10307110] = 10513247,
	[10307111] = 10513248,
}
-- 进阶材料配置
-- 玄兵石
weapon_jinjie.item_xuanbingshi = 30505821
weapon_jinjie.item_xuanbingshi_bind = 30505822
-- 女娲石
weapon_jinjie.item_nvwaishi = 30505827
weapon_jinjie.item_nvwaishi_bind = 30505828
-- 女娲神石
weapon_jinjie.item_nvwashenshi = 30505829
weapon_jinjie.item_nvwashenshi_bind = 30505830
-- 伏羲玉
weapon_jinjie.item_fuxiyu = 30505833
weapon_jinjie.item_fuxiyu_bind = 30505834

-- 三档进阶消耗配置
-- 1进阶（6星-7星）：500玄兵石 + 女娲石*1
weapon_jinjie.jinjie_cost_6to7 = {
	xuanbingshi = 500,
	nvwaishi = 0,
	nvwashenshi = 0,
	fuxiyu = 0,
	money = 0,
}
-- 2进阶（7星-8星）：500玄兵石 + 女娲神石*1 + 伏羲玉*500
weapon_jinjie.jinjie_cost_7to8 = {
	xuanbingshi = 1500,
	nvwaishi = 0,
	nvwashenshi = 0,
	fuxiyu = 0,
	money = 0,
}
-- 3进阶（8星-9星）：600玄兵石 + 女娲神石*2 + 伏羲玉*1000
weapon_jinjie.jinjie_cost_8to9 = {
	xuanbingshi = 2500,
	nvwaishi = 0,
	nvwashenshi = 0,
	fuxiyu = 0,
	money = 0,
}

-- 重洗材料
weapon_jinjie.special_cx_item_1 = 30505835
weapon_jinjie.special_cx_item_2 = 30505836
weapon_jinjie.special_cx_item_count = 5

-- 神器星级属性提升百分比
-- 7星比6星提升80%，8星比7星提升40%
weapon_jinjie.star_boost_rate = {
	[6] = 100,   -- 6星基础值100%
	[7] = 114,   -- 7星 = 6星 × 180%（提升80%）
	[8] = 120,   -- 8星 = 7星 × 140% = 180×1.4 = 252%（比7星提升40%）
	[9] = 100,   -- 9星保持8星属性（换ID）
}

-- 重洗属性范围配置（每个星级每个属性的最小值和最大值）
-- 7星 = 6星 × 1.8，8星 = 7星 × 1.4
weapon_jinjie.refresh_attr_range = {
	-- [6] = {
	-- 	["百分比增加HP的上限"] = {min = 14, max = 14},
	-- 	["百分比增加MP的上限"] = {min = 14, max = 14},
	-- 	["外功攻击"] = {min = 720, max = 1032},
	-- 	["内功攻击"] = {min = 720, max = 1032},
	-- 	["外功防御"] = {min = 80, max = 120},
	-- 	["内功防御"] = {min = 80, max = 120},
	-- 	["命中"] = {min = 414, max = 504},
	-- 	["闪避"] = {min = 30, max = 50},
	-- 	["会心"] = {min = 7, max = 10},
	-- 	["会心防御"] = {min = 2, max = 4},
	-- 	["力量"] = {min = 40, max = 55},
	-- 	["灵气"] = {min = 40, max = 55},
	-- 	["体力"] = {min = 40, max = 55},
	-- 	["定力"] = {min = 40, max = 55},
	-- 	["身法"] = {min = 26, max = 32},
	-- 	["冰攻击"] = {min = 80, max = 96},
	-- 	["火攻击"] = {min = 80, max = 96},
	-- 	["玄攻击"] = {min = 80, max = 96},
	-- 	["毒攻击"] = {min = 80, max = 96},
	-- 	["增加所有的人物一级属性"] = {min = 10, max = 20},
	-- 	["降低目标冰抵抗"] = {min = 40, max = 80},
	-- 	["降低目标火抵抗"] = {min = 40, max = 80},
	-- 	["降低目标玄抵抗"] = {min = 40, max = 80},
	-- 	["降低目标毒抵抗"] = {min = 40, max = 80},
	-- },
	[7] = {
		["百分比增加HP的上限"] = {min = 16, max = 19},
		["增加HP的上限"] = {min = 5960, max = 8800},
		["增加MP的上限"] = {min = 1960, max = 5960},
		["外功攻击"] = {min = 1296, max = 1858},
		["内功攻击"] = {min = 1296, max = 1858},
		["命中"] = {min = 745, max = 907},
		["会心"] = {min = 20, max = 30},
		["力量"] = {min = 72, max = 99},
		["灵气"] = {min = 72, max = 99},
		["体力"] = {min = 72, max = 99},
		["定力"] = {min = 72, max = 99},
		["身法"] = {min = 47, max = 58},
		["增加所有的人物一级属性"] = {min = 18, max = 36},
		["冰攻击"] = {min = 144, max = 182},
		["火攻击"] = {min = 144, max = 182},
		["玄攻击"] = {min = 144, max = 182},
		["毒攻击"] = {min = 144, max = 182},
		["降低目标冰抵抗"] = {min = 72, max = 96},
		["降低目标火抵抗"] = {min = 72, max = 96},
		["降低目标玄抵抗"] = {min = 72, max = 96},
		["降低目标毒抵抗"] = {min = 72, max = 96},
	},
	[8] = {
		["百分比增加HP的上限"] = {min = 20, max = 25},
		["增加HP的上限"] = {min = 8800, max = 12800},
		["增加MP的上限"] = {min = 4800, max = 8800},
		["外功攻击"] = {min = 1814, max = 2601},
		["内功攻击"] = {min = 1814, max = 2601},
		["命中"] = {min = 1043, max = 1270},
		["会心"] = {min = 30, max = 45},
		["力量"] = {min = 101, max = 139},
		["灵气"] = {min = 101, max = 139},
		["体力"] = {min = 101, max = 139},
		["定力"] = {min = 101, max = 139},
		["身法"] = {min = 66, max = 81},
		["增加所有的人物一级属性"] = {min = 25, max = 50},
		["冰攻击"] = {min = 202, max = 288},
		["火攻击"] = {min = 202, max = 288},
		["玄攻击"] = {min = 202, max = 288},
		["毒攻击"] = {min = 202, max = 288},
		["降低目标冰抵抗"] = {min = 96, max = 158},
		["降低目标火抵抗"] = {min = 96, max = 158},
		["降低目标玄抵抗"] = {min = 96, max = 158},
		["降低目标毒抵抗"] = {min = 96, max = 158},
	},
	[9] = {
		["百分比增加HP的上限"] = {min = 27, max = 35},
		["增加HP的上限"] = {min = 15000, max = 22000},
		["增加MP的上限"] = {min = 9000, max = 15000},
		["外功攻击"] = {min = 2214, max = 3601},
		["内功攻击"] = {min = 2214, max = 3601},
		["命中"] = {min = 1743, max = 3270},
		["会心"] = {min = 45, max = 55},
		["力量"] = {min = 168, max = 289},
		["灵气"] = {min = 168, max = 289},
		["体力"] = {min = 168, max = 289},
		["定力"] = {min = 168, max = 289},
		["身法"] = {min = 88, max = 149},
		["增加所有的人物一级属性"] = {min = 35, max = 60},
		["冰攻击"] = {min = 400, max = 588},
		["火攻击"] = {min = 400, max = 588},
		["玄攻击"] = {min = 400, max = 588},
		["毒攻击"] = {min = 400, max = 588},
		["降低目标冰抵抗"] = {min = 158, max = 288},
		["降低目标火抵抗"] = {min = 158, max = 288},
		["降低目标玄抵抗"] = {min = 158, max = 288},
		["降低目标毒抵抗"] = {min = 158, max = 288},
	},
}


--当前最高开放20
--开放装备契合最大等级 这里的需要金钱少 加的属性少   等级尽量整10设置 如 10，9，30
weapon_jinjie.limit_equip_id_1 = {
}

--开放装备契合最大等级 这里的需要金钱中 加的属性中   等级尽量整10设置 如 10，20，30
weapon_jinjie.limit_equip_id_2 = {

}

--开放装备契合最大等级 这里的需要金钱多 加的属性多   等级尽量整10设置 如 10，20，30
weapon_jinjie.limit_equip_id_3 = {
	[10300103] = 20,
	[10300104] = 20,
	[10300105] = 20,
	[10300106] = 20,
	[10300107] = 20,
	[10300108] = 20,
	[10300109] = 20,
	[10300110] = 20,
	[10300111] = 20,

	[10301103] = 20,
	[10301104] = 20,
	[10301105] = 20,
	[10301106] = 20,
	[10301107] = 20,
	[10301108] = 20,
	[10301109] = 20,
	[10301110] = 20,
	[10301111] = 20,

	[10301203] = 20,
	[10301204] = 20,
	[10301205] = 20,
	[10301206] = 20,
	[10301207] = 20,
	[10301208] = 20,
	[10301209] = 20,
	[10301210] = 20,
	[10301211] = 20,

	[10302103] = 20,
	[10302104] = 20,
	[10302105] = 20,
	[10302106] = 20,
	[10302107] = 20,
	[10302108] = 20,
	[10302109] = 20,
	[10302110] = 20,
	[10302111] = 20,

	[10302203] = 20,
	[10302204] = 20,
	[10302205] = 20,
	[10302206] = 20,
	[10302207] = 20,
	[10302208] = 20,
	[10302209] = 20,
	[10302210] = 20,
	[10302211] = 20,

	[10303103] = 20,
	[10303104] = 20,
	[10303105] = 20,
	[10303106] = 20,
	[10303107] = 20,
	[10303108] = 20,
	[10303109] = 20,
	[10303110] = 20,
	[10303111] = 20,

	[10303203] = 20,
	[10303204] = 20,
	[10303205] = 20,
	[10303206] = 20,
	[10303207] = 20,
	[10303208] = 20,
	[10303209] = 20,
	[10303210] = 20,
	[10303211] = 20,

	[10304103] = 20,
	[10304104] = 20,
	[10304105] = 20,
	[10304106] = 20,
	[10304107] = 20,
	[10304108] = 20,
	[10304109] = 20,
	[10304110] = 20,
	[10304111] = 20,

	[10305103] = 20,
	[10305104] = 20,
	[10305105] = 20,
	[10305106] = 20,
	[10305107] = 20,
	[10305108] = 20,
	[10305109] = 20,
	[10305110] = 20,
	[10305111] = 20,

	[10305203] = 20,
	[10305204] = 20,
	[10305205] = 20,
	[10305206] = 20,
	[10305207] = 20,
	[10305208] = 20,
	[10305209] = 20,
	[10305210] = 20,
	[10305211] = 20,

	[10306103] = 20,
	[10306104] = 20,
	[10306105] = 20,
	[10306106] = 20,
	[10306107] = 20,
	[10306108] = 20,
	[10306109] = 20,
	[10306110] = 20,
	[10306111] = 20,

	[10307103] = 20,
	[10307104] = 20,
	[10307105] = 20,
	[10307106] = 20,
	[10307107] = 20,
	[10307108] = 20,
	[10307109] = 20,
	[10307110] = 20,
	[10307111] = 20,
}


--契合三档 需求材料，金钱，数量
weapon_jinjie.equip_qh_cost_1 = {
	[1] = {item_id = 30505821,item_id_bind = 30505822,
			money = {33800,36700,40500,45100,50600,56900,64000,72000},
			count = {5,9,14,22,29,36,43,50}},
	[2] = {item_id = 30505821,item_id_bind = 30505822,
			money = {90500,101000,112300,124500,137500,151400,166100,181600},
			count = {50,54,58,62,66,70,74,78}},
}

weapon_jinjie.equip_qh_cost_2 = {
	[1] = {item_id = 30505821,item_id_bind = 30505822,
			money = {45000,49000,54000,60200,67400,75800,85400,96000},
			count = {5,9,14,22,29,36,43,50}},
	[2] = {item_id = 30505821,item_id_bind = 30505822,
			money = {120600,134600,149800,166000,183400,201800,221400,242200},
			count = {50,54,58,62,66,70,74,78}},
}

weapon_jinjie.equip_qh_cost_3 = {
	[1] = {item_id = 30505821,item_id_bind = 30505822,
			money = {56300,61200,67500,75200,84300,94800,106700,120000},
			count = {5,9,14,22,29,36,43,50}},
	[2] = {item_id = 30505821,item_id_bind = 30505822,
			money = {150800,168300,187200,207500,229200,252300,276800,302700},
			count = {50,54,58,62,66,70,74,78}},
}
--进阶三档 需求材料，数量，金钱，进阶后的契合等级
weapon_jinjie.equip_jinjie_cost_money_1 = {
	[1] = {item_id = 30505827,item_id_bind = 30505828,count = 1,money = 90000,level = 11},
	[2] = {item_id = 30505829,item_id_bind = 30505830,count = 1,money = 210000,level = 20},
}
weapon_jinjie.equip_jinjie_cost_money_2 = {
	[1] = {item_id = 30505827,item_id_bind = 30505828,count = 1,money = 120000,level = 111},
	[2] = {item_id = 30505829,item_id_bind = 30505830,count = 1,money = 280000,level = 120},
}
weapon_jinjie.equip_jinjie_cost_money_3 = {
	[1] = {item_id = 30505827,item_id_bind = 30505828,count = 1,money = 150000,level = 211},
	[2] = {item_id = 30505829,item_id_bind = 30505830,count = 1,money = 350000,level = 220},
}
weapon_jinjie.item_tl = 30505818
weapon_jinjie.item_count_tl = 1
weapon_jinjie.money_tl = 50000

function weapon_jinjie:super_weapon_tl(selfId,bag_pos_equip,bag_pos_item)
	local equip_id,equip_qhd = self:GetEquipQHD(selfId,bag_pos_equip)
	if not equip_qhd then
		return
	elseif equip_qhd > 0 then
		self:notify_tips(selfId, "Trang bị đã thông linh.")
		return
	elseif not self:CheckEquipTL(selfId,equip_id) then
		return
	end
	local curlv
	if self.limit_equip_id_1[equip_id] then
		curlv = 1
	elseif self.limit_equip_id_2[equip_id] then
		curlv = 101
	elseif self.limit_equip_id_3[equip_id] then
		curlv = 201
	else
		self:notify_tips(selfId, "Trang bị này không mở thông linh.")
		return
	end
	if not self:CheckMoney(selfId,self.money_tl) then
		return
	end
	if self:LuaFnGetItemTableIndexByIndex(selfId,bag_pos_item) ~= self.item_tl then
		local msg = string.format("Chưa đặt %s",self:GetItemName(self.item_tl))
		self:notify_tips(selfId,msg)
		return
	elseif self:GetBagItemLayCount(selfId,bag_pos_item) < self.item_count_tl then
		self:MaterialNotEnoughTip(selfId,self.item_tl,self.item_count_tl)
		return
	end
	self:LuaFnDecItemLayCount(selfId,bag_pos_item,self.item_count_tl)
	self:LuaFnCostMoneyWithPriority(selfId,self.money_tl)
	self:SetEquipQHD(selfId,bag_pos_equip,curlv,1)
	self:notify_tips(selfId,"Thông linh thành công.")
	self:ShowObjBuffEffect(selfId,selfId,-1,18)
end
function weapon_jinjie:super_weapon_qh(selfId,bag_pos)
	local equip_id,equip_qhd = self:GetEquipQHD(selfId,bag_pos)
	if not equip_qhd then
		return
	elseif equip_qhd == 0 then
		self:notify_tips(selfId,"Trang bị chưa thông linh.")
		return
	end
	local up_lx = equip_qhd % 100
	local idx = up_lx // 10 + 1
	local tbl
	if self.limit_equip_id_1[equip_id] then
		if up_lx >= self.limit_equip_id_1[equip_id] then
			if not open_special_jj then
				self:notify_tips(selfId,"Khế hợp đã tối đa.")
			else
				self:notify_tips(selfId,"Khế hợp đã tối đa, thần khí tám sao tiến giai tiếp thành chín sao Vương Giả·Thần Khí được.")
			end
			return
		end
		tbl = self.equip_qh_cost_1[idx]
	elseif self.limit_equip_id_2[equip_id] then
		if up_lx >= self.limit_equip_id_2[equip_id] then
			if not open_special_jj then
				self:notify_tips(selfId,"Khế hợp đã tối đa.")
			else
				self:notify_tips(selfId,"Khế hợp đã tối đa, thần khí tám sao tiến giai tiếp thành chín sao Vương Giả·Thần Khí được.")
			end
			return
		end
		tbl = self.equip_qh_cost_2[idx]
	elseif self.limit_equip_id_3[equip_id] then
		if up_lx >= self.limit_equip_id_3[equip_id] then
			if not open_special_jj then
				self:notify_tips(selfId,"Khế hợp đã tối đa.")
			else
				self:notify_tips(selfId,"Khế hợp đã tối đa, thần khí tám sao tiến giai tiếp thành chín sao Vương Giả·Thần Khí được.")
			end
			return
		end
		tbl = self.equip_qh_cost_3[idx]
	end
	if not tbl then
		local msg = string.format("Phát hiện bất thường:[%d]",equip_qhd)
		self:notify_tips(selfId,msg)
		return
	end
	local qhd = equip_qhd % 10
	if qhd == 9 then
		self:notify_tips(selfId,"Cần tiến giai rồi mới khế hợp tiếp.")
		return
	end
	local need_id = tbl.item_id
	local need_id_bind = tbl.item_id_bind
	local need_count = tbl.count[qhd]
	local need_money = tbl.money[qhd]
	if not need_id or not need_id_bind or not need_count or not need_money then
		local msg = string.format("Phát hiện bất thường:[%d][%s][%s][%s][%s]",equip_qhd,
		tostring(need_id),tostring(need_id_bind),tostring(need_count),tostring(need_money))
		self:notify_tips(selfId,msg)
		return
	elseif not self:CheckMoney(selfId,need_money) then
		return
	end
	local num = self:LuaFnGetAvailableItemCount(selfId,need_id)
	local num_bind = self:LuaFnGetAvailableItemCount(selfId,need_id_bind)
	if num + num_bind < need_count then
		self:MaterialNotEnoughTip(selfId,need_id,need_count)
		return
	end
	if num_bind >= need_count then
		self:LuaFnDelAvailableItem(selfId,need_id_bind,need_count)
	else
		if num_bind > 0 then
			self:LuaFnDelAvailableItem(selfId,need_id_bind,num_bind)
			need_count = need_count - num_bind
		end
		self:LuaFnDelAvailableItem(selfId,need_id,need_count)
	end
	self:LuaFnCostMoneyWithPriority(selfId,need_money)
	equip_qhd = equip_qhd + 1
	self:SetEquipQHD(selfId,bag_pos,equip_qhd,1)
	self:notify_tips(selfId,"Khế hợp thành công.")
	self:ShowObjBuffEffect(selfId,selfId,-1,18)
	self:BeginUICommand()
	self:UICommand_AddInt(0)
	self:UICommand_AddInt(bag_pos)
	self:UICommand_AddInt(equip_qhd)
	self:EndUICommand()
	self:DispatchUICommand(selfId,60000170)
	-- self:LuaFnRefreshItemInfo(selfId, bag_pos)
end

function weapon_jinjie:super_weapon_special_jj(flag,selfId,bag_pos,equip_id,equip_qhd)
	if flag ~= "special_jj" then
		return
	end
	local newid = self.special_jj[equip_id]
	if not newid then
		self:notify_tips(selfId,"Thần khí này chưa mở tiến giai chín sao.")
		return
	end
	local a_num = self:LuaFnGetAvailableItemCount(selfId,self.special_jj_item_a1)
	local a_num_bind = self:LuaFnGetAvailableItemCount(selfId,self.special_jj_item_a2)
	local a_need_count = self.special_jj_item_count_a
	if a_num + a_num_bind < a_need_count then
		self:MaterialNotEnoughTip(selfId,self.special_jj_item_a1,a_need_count)
		return
	end
	local b_num = self:LuaFnGetAvailableItemCount(selfId,self.special_jj_item_b1)
	local b_num_bind = self:LuaFnGetAvailableItemCount(selfId,self.special_jj_item_b2)
	local b_need_count = self.special_jj_item_count_b
	if b_num + b_num_bind < b_need_count then
		self:MaterialNotEnoughTip(selfId,self.special_jj_item_b1,b_need_count)
		return
	end
	if a_num_bind >= a_need_count then
		self:LuaFnDelAvailableItem(selfId,self.special_jj_item_a2,a_need_count)
	else
		if a_num_bind > 0 then
			self:LuaFnDelAvailableItem(selfId,self.special_jj_item_a2,a_num_bind)
			a_need_count = a_need_count - a_num_bind
		end
		self:LuaFnDelAvailableItem(selfId,self.special_jj_item_a1,a_need_count)
	end
	if b_num_bind >= b_need_count then
		self:LuaFnDelAvailableItem(selfId,self.special_jj_item_b2,b_need_count)
	else
		if b_num_bind > 0 then
			self:LuaFnDelAvailableItem(selfId,self.special_jj_item_b2,b_num_bind)
			b_need_count = b_need_count - b_num_bind
		end
		self:LuaFnDelAvailableItem(selfId,self.special_jj_item_b1,b_need_count)
	end
	local ret = self:LuaFnRefreshEquipID_Attr(selfId,bag_pos,newid,1)
	if ret == 0 then
		self:ShowObjBuffEffect(selfId,selfId,-1,18)
		self:notify_tips(selfId,"Tiến giai thành công.")
	else
		local msg = string.format("Tiến giai lỗi: %s",tostring(ret))
		self:notify_tips(selfId,msg)
	end
end

-- 神器进阶（基于星级直接进阶）
-- 6星->7星：500玄兵石 + 女娲石*1
-- 7星->8星：500玄兵石 + 女娲神石*1 + 伏羲玉*500
-- 8星->9星：600玄兵石 + 女娲神石*2 + 伏羲玉*1000（换装备ID）
function weapon_jinjie:super_weapon_jj(selfId,bag_pos)
	if bag_pos < 0 or bag_pos == nil then
		return
	end
	local equip_id = self:LuaFnGetItemTableIndexByIndex(selfId,bag_pos)
	if not equip_id then
		self:notify_tips(selfId,"Xin đặt thần khí vào.")
		return
	end
	if equip_id < 10300000 or equip_id > 10399999 then
		self:notify_tips(selfId,"Chỉ Thần khí mới có thể tiến hành thăng sao")
		return
	end
	local equip_level = self:GetBagItemLevel(selfId, bag_pos)
	if not equip_level or equip_level ~= 102 then
		self:notify_tips(selfId,"Chỉ thần khí cấp 102 mới tiến giai được.")
		return
	end
	local star = self:GetBagItemQuality(selfId,bag_pos)  -- 获取神器星级
	if not star or star < 6 then
		self:notify_tips(selfId,"Chỉ thần khí 6 sao trở lên mới tiến giai được.")
		return
	end
	if star >= 9 then
		self:notify_tips(selfId,"Thần khí đã sao tối đa, không tiến giai tiếp được.")
		return
	end
	
	-- 根据星级选择消耗配置
	local cost_cfg
	if star == 6 then
		cost_cfg = self.jinjie_cost_6to7
	elseif star == 7 then
		cost_cfg = self.jinjie_cost_7to8
	elseif star == 8 then
		cost_cfg = self.jinjie_cost_8to9
	end

	if not cost_cfg then
		self:notify_tips(selfId,"upgrade config error")
		return
	end

	if cost_cfg.money > 0 and not self:CheckMoney(selfId, cost_cfg.money) then
		return
	end

	local xuanbingshi_num = self:LuaFnGetAvailableItemCount(selfId, self.item_xuanbingshi)
	local xuanbingshi_num_bind = self:LuaFnGetAvailableItemCount(selfId, self.item_xuanbingshi_bind)
	if xuanbingshi_num + xuanbingshi_num_bind < cost_cfg.xuanbingshi then
		self:MaterialNotEnoughTip(selfId, self.item_xuanbingshi, cost_cfg.xuanbingshi)
		return
	end

	local nvwaishi_num = self:LuaFnGetAvailableItemCount(selfId, self.item_nvwaishi)
	local nvwaishi_num_bind = self:LuaFnGetAvailableItemCount(selfId, self.item_nvwaishi_bind)
	if nvwaishi_num + nvwaishi_num_bind < cost_cfg.nvwaishi then
		self:MaterialNotEnoughTip(selfId, self.item_nvwaishi, cost_cfg.nvwaishi)
		return
	end

	local nvwashenshi_num = self:LuaFnGetAvailableItemCount(selfId, self.item_nvwashenshi)
	local nvwashenshi_num_bind = self:LuaFnGetAvailableItemCount(selfId, self.item_nvwashenshi_bind)
	if nvwashenshi_num + nvwashenshi_num_bind < cost_cfg.nvwashenshi then
		self:MaterialNotEnoughTip(selfId, self.item_nvwashenshi, cost_cfg.nvwashenshi)
		return
	end

	local fuxiyu_num = self:LuaFnGetAvailableItemCount(selfId, self.item_fuxiyu)
	local fuxiyu_num_bind = self:LuaFnGetAvailableItemCount(selfId, self.item_fuxiyu_bind)
	if fuxiyu_num + fuxiyu_num_bind < cost_cfg.fuxiyu then
		self:MaterialNotEnoughTip(selfId, self.item_fuxiyu, cost_cfg.fuxiyu)
		return
	end

	if cost_cfg.xuanbingshi > 0 then
		self:DelItemWithBind(selfId, self.item_xuanbingshi, self.item_xuanbingshi_bind, cost_cfg.xuanbingshi, xuanbingshi_num_bind)
	end
	if cost_cfg.nvwaishi > 0 then
		self:DelItemWithBind(selfId, self.item_nvwaishi, self.item_nvwaishi_bind, cost_cfg.nvwaishi, nvwaishi_num_bind)
	end
	if cost_cfg.nvwashenshi > 0 then
		self:DelItemWithBind(selfId, self.item_nvwashenshi, self.item_nvwashenshi_bind, cost_cfg.nvwashenshi, nvwashenshi_num_bind)
	end
	if cost_cfg.fuxiyu > 0 then
		self:DelItemWithBind(selfId, self.item_fuxiyu, self.item_fuxiyu_bind, cost_cfg.fuxiyu, fuxiyu_num_bind)
	end
	if cost_cfg.money > 0 then
		self:LuaFnCostMoneyWithPriority(selfId, cost_cfg.money)
	end

	local new_star = star + 1
	local obj = self.scene:get_obj_by_id(selfId)
	local item = obj and obj:get_prop_bag_container():get_item(bag_pos) or nil
	if not item then
		self:notify_tips(selfId,"upgrade failed")
		return
	end

	local equip_base = configenginer:get_config("equip_base")
	local base = equip_base[item:get_index()]
	if not base then
		self:notify_tips(selfId,"equip config error")
		return
	end

	local attr_range = self.refresh_attr_range[new_star]
	if not attr_range then
		self:notify_tips(selfId,"attr range config error")
		return
	end

	local attr_count = roll_attr_count_by_star(new_star, base)

	local shuffled = item_operator:shuffle_attrs(base.ex_attrs, attr_count)
	local attr_type = 0
	local attr_types = {}
	local attr_values = {}
	for i, name in ipairs(shuffled) do
		local range = attr_range[name]
		if range then
			local value = math.random(range.min, range.max)
			if value > 32767 then
				value = 32767
			end
			local lshift = define.EQUIP_ATTR[name]
			if lshift then
				table.insert(attr_values, value)
				attr_type = set_attr_bit(attr_type, lshift)
				table.insert(attr_types, lshift)
			end
		end
		if #attr_types >= attr_count then
			break
		end
	end
	if #attr_values == 0 then
		self:notify_tips(selfId,"upgrade failed")
		return
	end

	item:set_is_bind(true)
	local equip_data = item:get_equip_data()
	equip_data:set_attr_count(#attr_values)
	equip_data:set_attr_value(attr_values)
	equip_data:set_attr_type(attr_type)
	equip_data:set_attr_types(attr_types)
	equip_data:set_quality(new_star)

	local msg = packet_def.GCItemInfo.new()
	msg.bagIndex = bag_pos
	msg.item = item:copy_raw_data()
	self.scene:send2client(obj, msg)

	self:ShowObjBuffEffect(selfId,selfId,-1,18)
	self:notify_tips(selfId,string.format("Thần khí tiến giai thành công tới %d sao", new_star))

	-- broadcast
	local transfer = self:GetBagItemTransfer(selfId, bag_pos)
	local str = string.format("#{_INFOUSR%s}#Ptại chỗ#YÂu Dã Thanh#Pdùng tiến giai thần khí, nâng thần khí lên#{_INFOMSG%s}#P", self:GetName(selfId), transfer)
	str = gbk.fromutf8(str)
	self:BroadMsgByChatPipe(selfId, str, 4)
end

-- 辅助函数：扣除物品（优先扣除绑定物品）
function weapon_jinjie:DelItemWithBind(selfId, item_id, item_id_bind, need_count, bind_count)
	if bind_count >= need_count then
		self:LuaFnDelAvailableItem(selfId, item_id_bind, need_count)
	else
		if bind_count > 0 then
			self:LuaFnDelAvailableItem(selfId, item_id_bind, bind_count)
			need_count = need_count - bind_count
		end
		self:LuaFnDelAvailableItem(selfId, item_id, need_count)
	end
end
--九星返还暂未开放
function weapon_jinjie:super_weapon_fh(selfId,bag_pos)
	local equip_id,equip_qhd = self:GetEquipQHD(selfId,bag_pos)
	if not equip_qhd then
		return
	elseif equip_qhd == 0 then
		self:notify_tips(selfId,"Trang bị chưa thông linh.")
		return
	end
	local up_lx = equip_qhd % 100
	local tbl,tbl2
	if self.limit_equip_id_1[equip_id] then
		if up_lx > self.limit_equip_id_1[equip_id] then
			self:notify_tips(selfId,"Độ khế hợp bất thường.")
			return
		end
		tbl = self.equip_qh_cost_1
		tbl2 = self.equip_jinjie_cost_money_1
	elseif self.limit_equip_id_2[equip_id] then
		if up_lx > self.limit_equip_id_2[equip_id] then
			self:notify_tips(selfId,"Độ khế hợp bất thường.")
			return
		end
		tbl = self.equip_qh_cost_2
		tbl2 = self.equip_jinjie_cost_money_2
	elseif self.limit_equip_id_3[equip_id] then
		if up_lx > self.limit_equip_id_3[equip_id] then
			self:notify_tips(selfId,"Độ khế hợp bất thường.")
			return
		end
		tbl = self.equip_qh_cost_3
		tbl2 = self.equip_jinjie_cost_money_3
	end
	if not tbl or not tbl2 then
		local msg = string.format("Phát hiện bất thường:[%d]",equip_qhd)
		self:notify_tips(selfId,msg)
		return
	end
	local nv_wa_1,nv_wa_2,qhd
	local nv_wa_1_count,nv_wa_2_count
	local back_item = {}
	local money = 20000
	if up_lx > 1 then
		if up_lx <= 11 then
			qhd = up_lx
			if up_lx > 9 then
				nv_wa_1 = tbl2[1].item_id_bind
				nv_wa_1_count = tbl2[1].count
				qhd = 9
			end
			local item_id = tbl[1].item_id_bind
			back_item[item_id] = back_item[item_id] or 0
			for i = 2,qhd do
				back_item[item_id] = back_item[item_id] + tbl[1].count[i - 1]
			end
			local tbl = {33800,70500,111000,156100,206700,263600,327600,399600,481600};
			money = tbl[qhd];
		elseif up_lx <= 20 then
			nv_wa_1 = tbl2[1].item_id_bind
			nv_wa_1_count = tbl2[1].count
			local qhds = {9,1}
			if up_lx > 19 then
				nv_wa_2 = tbl2[2].item_id_bind
				nv_wa_2_count = tbl2[2].count
				qhds[2] = 9
			else
				qhds[2] = up_lx % 10
			end
			local item_id
			for n = 1,2 do
				qhd = qhds[n]
				item_id = tbl[n].item_id_bind
				back_item[item_id] = back_item[item_id] or 0
				for i = 2,qhd do
					back_item[item_id] = back_item[item_id] + tbl[n].count[i - 1]
				end
			end
			qhd = qhds[2]
			local tbl = {33800,70500,111000,156100,206700,263600,327600,399600,481600};
			money = tbl[qhd];
		else
			self:notify_tips(selfId,"Chưa Mở")
			return
		end
	end
	if not self:CheckMoney(selfId,money) then
		return
	end
	self:BeginAddItem()
	self:AddItem(self.item_tl,self.item_count_tl,true)
	if nv_wa_1 and nv_wa_1_count then
		self:AddItem(nv_wa_1,nv_wa_1_count,true)
	end
	if nv_wa_2 and nv_wa_2_count then
		self:AddItem(nv_wa_2,nv_wa_2_count,true)
	end
	for id,num in pairs(back_item) do
		self:AddItem(id,num,true)
	end
	if not self:EndAddItem(selfId,true) then
		return
	end
	if self:EmptyEquipQHD(selfId,bag_pos) then
		self:LuaFnCostMoneyWithPriority(selfId,money)
		self:BeginAddItem()
		self:AddItem(self.item_tl,self.item_count_tl,true)
		if nv_wa_1 and nv_wa_1_count then
			self:AddItem(nv_wa_1,nv_wa_1_count,true)
		end
		if nv_wa_2 and nv_wa_2_count then
			self:AddItem(nv_wa_2,nv_wa_2_count,true)
		end
		for id,num in pairs(back_item) do
			self:AddItem(id,num,true)
		end
		-- if not self:EndAddItem(selfId) then
			-- return
		-- end
		self:AddItemListToHuman(selfId)
		self:ShowObjBuffEffect(selfId,selfId,-1,18)
		self:notify_tips(selfId,"Thoát linh thành công.")
	else
		self:notify_tips(selfId,"Thoát linh thất bại.")
	end
end

function weapon_jinjie:DiscardNewEquipAttr(selfId, BagPos)
    self:LuaFnFinishRefreshEquipAttr(selfId, BagPos, false)
end

function weapon_jinjie:SwitchEquipAttr(selfId, BagPos)
    self:LuaFnFinishRefreshEquipAttr(selfId, BagPos, true)
end

function weapon_jinjie:RefreshEquipAttr(selfId,bag_pos,bind_confirmed)
	-- 统一使用神器洗练符作为重洗材料
	local item_id = self.special_cx_item_1      -- 30505835
	local item_id_bine = self.special_cx_item_2 -- 30505836
	local need_count = self.special_cx_item_count -- 5
	
	local equip_id = self:LuaFnGetItemTableIndexByIndex(selfId, bag_pos)
	if not equip_id then
		self:notify_tips(selfId,"Xin đặt thần khí vào.")
		return
	end
	if equip_id < 10300000 or equip_id > 10399999 then
		self:notify_tips(selfId,"Chỉ Thần khí mới có thể tiến hành tẩy luyện")
		return
	end

	-- 检查装备等级，只允许102级装备洗练
	local equip_level = self:GetBagItemLevel(selfId, bag_pos)
	if not equip_level or equip_level ~= 102 then
		self:notify_tips(selfId,"Chỉ thần khí cấp 102 mới tẩy luyện được.")
		return
	end
	
	-- 改为检测星级，不再需要契合度
	local star = self:GetBagItemQuality(selfId, bag_pos)
	if not star or star < 7 then
		self:notify_tips(selfId,"Chỉ thần khí 7 sao trở lên mới tẩy lại được.")
		return
	end
	
	if not self:CheckMoney(selfId,50000) then
		return
	end
	local num = self:LuaFnGetAvailableItemCount(selfId,item_id)
	local num_bind = self:LuaFnGetAvailableItemCount(selfId,item_id_bine)
	if num + num_bind < need_count then
		self:MaterialNotEnoughTip(selfId,item_id,need_count)
		return
	end
	if num_bind >= need_count then
		self:LuaFnDelAvailableItem(selfId,item_id_bine,need_count)
	else
		if num_bind > 0 then
			self:LuaFnDelAvailableItem(selfId,item_id_bine,num_bind)
			need_count = need_count - num_bind
		end
		self:LuaFnDelAvailableItem(selfId,item_id,need_count)
	end
	self:LuaFnCostMoneyWithPriority(selfId,50000)
	
	-- 使用自定义洗练逻辑
	self:RefreshEquipAttr_Custom(selfId,bag_pos)
end

-- 自定义洗练函数：9星洗练时随机12-15条属性
function weapon_jinjie:RefreshEquipAttr_Custom(selfId, bag_pos)
	local obj = self.scene:get_obj_by_id(selfId)
	local item = obj:get_prop_bag_container():get_item(bag_pos)
	if not item then
		return
	end
	
	item:set_is_bind(true)
	local equip_data = item:get_equip_data()
	local quality = equip_data:get_quality()
	local item_index = item:get_index()
	
	-- 获取装备配置
	local equip_base = configenginer:get_config("equip_base")
	local base = equip_base[item_index]
	if not base then
		return
	end
	
	-- 获取属性范围配置
	local attr_range = self.refresh_attr_range[quality]
	if not attr_range then
		self:notify_tips(selfId,"Cấu hình phạm vi thuộc tính bất thường.")
		return
	end
	
	local attr_count = roll_attr_count_by_star(quality, base)
	
	if attr_count == 0 then
		return
	end
	
	-- 随机属性类型
	local attr_pool = {}
	for name, _ in pairs(attr_range) do
		table.insert(attr_pool, name)
	end
	local shuffled = item_operator:shuffle_attrs(attr_pool, attr_count)
	local attr_type = 0
	local attr_types = {}
	local attr_values = {}
	
	for i, name in ipairs(shuffled) do
		local range = attr_range[name]
		if range then
			-- 洗练时随机属性值
			local value = math.random(range.min, range.max)
			if value > 32767 then
				value = 32767
			end
			local lshift = define.EQUIP_ATTR[name]
			if lshift then
				table.insert(attr_values, value)
				attr_type = set_attr_bit(attr_type, lshift)
				table.insert(attr_types, lshift)
			end
		end
		if #attr_types >= attr_count then
			break
		end
	end
	
	-- 保存到临时属性，等待玩家确认替换
	local equip_attrs = { attr_type = attr_type, attr_types = attr_types, attr_values = attr_values }
	obj:set_temp_equip_attrs(item:get_guid(), equip_attrs)
	
	-- 发送消息给客户端显示预览
	local msg = packet_def.GCRefreshEquipAttr.new()
	msg.type = 2
	msg.attr_count = #attr_types
	msg.attr_type = attr_type
	msg.attr_values = attr_values
	msg.item_index = item_index
	self.scene:send2client(obj, msg)
end

function weapon_jinjie:fetch_item_data(selfId,index,bag_pos)
	-- 改为返回星级，不再返回契合度
	local star = self:GetBagItemQuality(selfId, bag_pos)
	if not star then
		star = 0
	end
	self:BeginUICommand()
	self:UICommand_AddInt(index)
	self:UICommand_AddInt(bag_pos)
	self:UICommand_AddInt(star)  -- 返回星级
	self:EndUICommand()
	self:DispatchUICommand(selfId,60000170)
end

return weapon_jinjie
