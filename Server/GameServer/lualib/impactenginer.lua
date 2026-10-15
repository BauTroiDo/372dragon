local skynet = require "skynet"
local define = require "define"
local class = require "class"
local sharetable = require "skynet.sharetable"
local impact = require "scene.skill.impact"
local combat_core = require "scene.skill.combat_core"
local configenginer = require "configenginer":getinstance()
local eventenginer = require "eventenginer":getinstance()
local impactenginer = class("impactenginer")
function impactenginer:getinstance()
    if impactenginer.instance == nil then
        impactenginer.instance = impactenginer.new()
    end
    return impactenginer.instance
end

function impactenginer:ctor()
    self.logics = {}
end

function impactenginer:loadall()
    if self.loaded_all then return end
    self.loaded_all = true
    self.std_impact_config = configenginer:get_config("std_impact_config")
    self:register_all_impact_logics()
end

function impactenginer:set_scene(scene)
    self.scene = scene
end

function impactenginer:reload()
    -- 从 CfgDB 获取最新配置，由场景侧发布到 sharetable
    local new_config = skynet.call(".CfgDB", "lua", "get_std_impact_config")
    if new_config then
        sharetable.loadtable("std_impact_config", new_config)
    end
    configenginer:invalidate_config("std_impact_config")
    self.std_impact_config = configenginer:get_config("std_impact_config")
    -- 补注册新增的 logic_id，旧逻辑保留
    self:register_all_impact_logics()
    skynet.logd("[impactenginer] reloaded")
end

function impactenginer:get_scene()
    return self.scene
end

function impactenginer:get_data_by_data_index(data_index)
    return self.std_impact_config[data_index]
end

function impactenginer:init_impact_from_data(data_index, imp)
    if self.cy_four_bridge and self.cy_four_bridge:is_disabled_impact(data_index) then return false end
    imp:clean_up()
	if not data_index or data_index < 0 then
		skynet.logi("data_index = ", data_index, "stack =", debug.traceback())
		return false
	end
    imp:set_data_index(data_index)
    local data = self:get_data_by_data_index(data_index)
    if not data then
        -- skynet.loge("init_impact_from_data error not found data_index =", data_index)
        return false
    end
    imp:set_impact_id(data.impact_id)
    imp:set_class_id(data.class_id)
    imp:set_continuance(data.continuance)
    imp:set_logic_id(data.logic_id)
    imp:set_is_over_timed(data.is_over_timed)
    imp:set_mutex_id(data.mutex_id)
    imp:set_mutex_priority(data.mutex_priority)
    imp:set_need_channel_support(data.need_channel_support)
    imp:set_need_equip_support(data.need_equip_support)
    imp:set_remain_on_corpse(data.remain_on_corpse)
    imp:set_can_be_dispeled(data.can_be_dispeled)
    imp:set_can_be_cancled(data.can_cancel)
    imp:set_counter_when_offline(data.counter_when_offline)

    imp:set_fade_out_when_unit_on_damage(data.fade_out_when_unit_on_damage)
    imp:set_fade_out_when_unit_on_move(data.fade_out_when_unit_on_move)
    imp:set_fade_out_when_unit_on_action_start(data.fade_out_when_unit_on_action_start)
    imp:set_fade_out_when_unit_offline(data.fade_out_when_unit_offline)
    imp:set_stand_flag(data.stand_flag)

    imp:set_interval(data.interval)
    imp:set_activate_times(data.params["生效次数，无效值：-1"] or -1)
    imp:set_params(table.clone(data.params))
    --local logic = self:get_logic(imp)
    --logic:init_from_data(imp, data)
    return true
end

function impactenginer:get_logic(imp)
   return self.logics[imp:get_logic_id()]
end

function impactenginer:get_logic_for_id(id)
   return self.logics[id]
end

function impactenginer:get_stand_flag(imp)

end

function impactenginer:can_impactA_replace_impactB(imp_a, imp_b)
    return imp_a:get_mutex_priority() >= imp_b:get_mutex_priority()
end

function impactenginer:send_impact_to_unit(reciver, data_index, sender, delay_time, is_critical_hit, refix_rate, skill_id,addvalue)
	-- skynet.logi("impactenginer:send_impact_to_unit skill_id = ",skill_id,"refix_rate = ",refix_rate)
	-- skill_id = skill_id or define.INVAILD_ID
	if not data_index or data_index < 0 then
		skynet.logi("skill_id = ", skill_id, "stack =", debug.traceback())
        return false
    end
    local imp = impact.new()
    -- imp:clean_up()
    if not self:init_impact_from_data(data_index, imp) then
        return false
    end
    imp:set_skill_id(skill_id)
	local logic_id = imp:get_logic_id()
    if logic_id == 3 then
        -- 额外直接伤害：内功攻击 × addvalue% (破天式飞剑)
        if addvalue and addvalue > 0 and sender then
            local magic_attack = sender:get_attack_magic()
            if magic_attack and magic_attack > 0 then
                imp.params["伤害数值"] = (imp.params["伤害数值"] or 0) + math.floor(magic_attack * addvalue / 100)
            end
        end
        local co = combat_core.new()
        co:get_result_impact(sender, reciver, imp)
	elseif logic_id == 10 then
		imp:set_features(addvalue)
	elseif logic_id == 309 then
		skill_id = 545
		imp:set_skill_id(skill_id)
    end
    -- if is_critical_hit then
    -- end
    -- if refix_rate ~= 0 then
    -- end
    if delay_time < 0 then
        delay_time = 0
    end
    eventenginer:register_impact_event(reciver, sender, imp, delay_time, skill_id)
    return true
end

function impactenginer:is_impact_in_collection_ex(imp, collection_ids)
    if not imp or not collection_ids or #collection_ids < 1 then
        return
	-- elseif not imp:get_is_over_timed() then
		-- return
    end
    local collections_config = configenginer:get_config("id_collections")
	local back_flag
	local conf
	local impact_id = imp:get_impact_id()
	local logic_id = imp:get_logic_id()
	local mutex_id = imp:get_mutex_id()
	local skill_id = imp:get_skill_id()
	-- local mutex_id = imp:get_mutex_id()
	local value
	for _,id in ipairs(collection_ids) do
		conf = collections_config[id]
		if conf then
			if conf.type == define.CollectionIdType.TYPE_BUFF_ID then
				if imp:get_is_over_timed() then
					value = impact_id
				end
			elseif conf.type == define.CollectionIdType.TYPE_IMPACT_LOGIC_ID then
				value = logic_id
			elseif conf.type == define.CollectionIdType.TYPE_IMPACT_MUTEX_ID then
				value = mutex_id
			elseif conf.type == define.CollectionIdType.TYPE_SKILL_ID then
				value = skill_id
			elseif conf.type == define.CollectionIdType.TYPE_DIRECT_IMPACT_ID then
				value = mutex_id
			else
				value = define.INVAILD_ID
			end
			if value ~= define.INVAILD_ID then
				if conf.ids[value] then
					return true
				end
			end
		end
	end
end


function impactenginer:is_impact_in_collection(imp, collection_id)
    if not collection_id or collection_id == define.INVAILD_ID then
        return false
	elseif not imp then
        return false
	-- elseif not imp:get_is_over_timed() then
        -- return false
    end
    local collections_config = configenginer:get_config("id_collections")
    local conf = collections_config[collection_id]
	if not conf then
		return false
	end
    -- assert(conf, collection_id)
    local id = define.INVAILD_ID
	
	--4 技能逻辑 ？
	--6 
	--8 
	--10 坐骑收藏，御马令
	
	--瞬发ID 0
    if conf.type == define.CollectionIdType.TYPE_BUFF_ID then
        if imp:get_is_over_timed() then
            id = imp:get_impact_id()
			-- id = imp:get_data_index()
        end
		--逻辑ID 2
    elseif conf.type == define.CollectionIdType.TYPE_IMPACT_LOGIC_ID then
        id = imp:get_logic_id()
		--互斥ID 1
    elseif conf.type == define.CollectionIdType.TYPE_IMPACT_MUTEX_ID then
        id = imp:get_mutex_id()
		--技能ID 3
    elseif conf.type == define.CollectionIdType.TYPE_SKILL_ID then
        id = imp:get_skill_id()
		--互斥ID 5
    elseif conf.type == define.CollectionIdType.TYPE_DIRECT_IMPACT_ID then
        id = imp:get_mutex_id()
        -- if imp:get_is_over_timed() then
            -- id = imp:get_impact_id()
        -- end
    end
    if id ~= define.INVAILD_ID then
        return conf.ids[id]
    end
    return false
end

impactenginer.id_logic_module = {
    [7991] = 'scene.skill.impact_logic.cy_lingpai_buff',
    [0] = "scene.skill.impact_logic.std_impact_000",
    [1] = "scene.skill.impact_logic.std_impact_001",
    [3] = "scene.skill.impact_logic.std_impact_003",
    [4] = "scene.skill.impact_logic.std_impact_004",
    [5] = "scene.skill.impact_logic.std_impact_005",
    [8] = "scene.skill.impact_logic.std_impact_008",
    [9] = "scene.skill.impact_logic.std_impact_009",
    [10] = "scene.skill.impact_logic.std_impact_010",
    [11] = "scene.skill.impact_logic.std_impact_011",
    [12] = "scene.skill.impact_logic.std_impact_012",
    [13] = "scene.skill.impact_logic.std_impact_013",
    [14] = "scene.skill.impact_logic.std_impact_014",
    [15] = "scene.skill.impact_logic.std_impact_015",
    [17] = "scene.skill.impact_logic.std_impact_017",
    [18] = "scene.skill.impact_logic.std_impact_018",
    [19] = "scene.skill.impact_logic.std_impact_019",
    [20] = "scene.skill.impact_logic.std_impact_020",
    [21] = "scene.skill.impact_logic.std_impact_021",
    [22] = "scene.skill.impact_logic.std_impact_022",
    [23] = "scene.skill.impact_logic.std_impact_023",
    [24] = "scene.skill.impact_logic.std_impact_024",
    [25] = "scene.skill.impact_logic.std_impact_025",
    [26] = "scene.skill.impact_logic.std_impact_026",
    [27] = "scene.skill.impact_logic.std_impact_027",
    [28] = "scene.skill.impact_logic.std_impact_028",
    [29] = "scene.skill.impact_logic.std_impact_029",
    [35] = "scene.skill.impact_logic.std_impact_035",
    [36] = "scene.skill.impact_logic.std_impact_036",
    [38] = "scene.skill.impact_logic.std_impact_038",
    [52] = "scene.skill.impact_logic.std_impact_052",
    [53] = "scene.skill.impact_logic.std_impact_053",
    [54] = "scene.skill.impact_logic.std_impact_054",
    [56] = "scene.skill.impact_logic.std_impact_056",
    [57] = "scene.skill.impact_logic.std_impact_057",
    [58] = "scene.skill.impact_logic.std_impact_058",
    [59] = "scene.skill.impact_logic.std_impact_059",
    [60] = "scene.skill.impact_logic.std_impact_060",
    [61] = "scene.skill.impact_logic.std_impact_061",
    [62] = "scene.skill.impact_logic.std_impact_062",
    [64] = "scene.skill.impact_logic.std_impact_064",
    [65] = "scene.skill.impact_logic.std_impact_065",
    [66] = "scene.skill.impact_logic.std_impact_066",
    [68] = "scene.skill.impact_logic.std_impact_068",
    [69] = "scene.skill.impact_logic.std_impact_069",
    [70] = "scene.skill.impact_logic.std_impact_070",
    [72] = "scene.skill.impact_logic.std_impact_072",
    [73] = "scene.skill.impact_logic.std_impact_073",
    [74] = "scene.skill.impact_logic.std_impact_074",
    [81] = "scene.skill.impact_logic.std_impact_081",
    [83] = "scene.skill.impact_logic.std_impact_083",
    [86] = "scene.skill.impact_logic.std_impact_086",
    [88] = "scene.skill.impact_logic.std_impact_088",
    [89] = "scene.skill.impact_logic.std_impact_089",
    [92] = "scene.skill.impact_logic.std_impact_092",
    [93] = "scene.skill.impact_logic.std_impact_093",
    [94] = "scene.skill.impact_logic.std_impact_094",
    [96] = "scene.skill.impact_logic.std_impact_096",
    [100] = "scene.skill.impact_logic.std_impact_100",
    [123] = "scene.skill.impact_logic.std_impact_123",
    [124] = "scene.skill.impact_logic.std_impact_124",
    [201] = "scene.skill.impact_logic.std_impact_201",
    [301] = "scene.skill.impact_logic.std_impact_301",
    [302] = "scene.skill.impact_logic.std_impact_302",
    [303] = "scene.skill.impact_logic.std_impact_303",
    [304] = "scene.skill.impact_logic.std_impact_304",
    [305] = "scene.skill.impact_logic.std_impact_305",
    [306] = "scene.skill.impact_logic.std_impact_306",
    [307] = "scene.skill.impact_logic.std_impact_307",
    [308] = "scene.skill.impact_logic.std_impact_308",
    [309] = "scene.skill.impact_logic.std_impact_309",
    [310] = "scene.skill.impact_logic.std_impact_310",
    [311] = "scene.skill.impact_logic.std_impact_311",
    [312] = "scene.skill.impact_logic.std_impact_312",
    [313] = "scene.skill.impact_logic.std_impact_313",
    [314] = "scene.skill.impact_logic.std_impact_314",
    [315] = "scene.skill.impact_logic.std_impact_315",
    [316] = "scene.skill.impact_logic.std_impact_316",
    [317] = "scene.skill.impact_logic.std_impact_317",
    [318] = "scene.skill.impact_logic.std_impact_318",
    [319] = "scene.skill.impact_logic.std_impact_319",
    [320] = "scene.skill.impact_logic.std_impact_320",
    [321] = "scene.skill.impact_logic.std_impact_321",
    [322] = "scene.skill.impact_logic.std_impact_322",
    [323] = "scene.skill.impact_logic.std_impact_323",
    [324] = "scene.skill.impact_logic.std_impact_324",
    [325] = "scene.skill.impact_logic.std_impact_325",
    [326] = "scene.skill.impact_logic.std_impact_326",
    [327] = "scene.skill.impact_logic.std_impact_327",
    [328] = "scene.skill.impact_logic.std_impact_328",
    [329] = "scene.skill.impact_logic.std_impact_329",
    [330] = "scene.skill.impact_logic.std_impact_330",
    [331] = "scene.skill.impact_logic.std_impact_331",
    [332] = "scene.skill.impact_logic.std_impact_332",
    [333] = "scene.skill.impact_logic.std_impact_333",
    [334] = "scene.skill.impact_logic.std_impact_334",
    [335] = "scene.skill.impact_logic.std_impact_335",
    [336] = "scene.skill.impact_logic.std_impact_336",
    [337] = "scene.skill.impact_logic.std_impact_337",
    [338] = "scene.skill.impact_logic.std_impact_338",
    [339] = "scene.skill.impact_logic.std_impact_339",
    [340] = "scene.skill.impact_logic.std_impact_340",
    [341] = "scene.skill.impact_logic.std_impact_341",
    [342] = "scene.skill.impact_logic.std_impact_342",
    [343] = "scene.skill.impact_logic.std_impact_343",
    [344] = "scene.skill.impact_logic.std_impact_344",
    [345] = "scene.skill.impact_logic.std_impact_345",
    [346] = "scene.skill.impact_logic.std_impact_346",
    [347] = "scene.skill.impact_logic.std_impact_347",
    [348] = "scene.skill.impact_logic.std_impact_348",
    [349] = "scene.skill.impact_logic.std_impact_349",
    [350] = "scene.skill.impact_logic.std_impact_350",
    [351] = "scene.skill.impact_logic.std_impact_351",
    [352] = "scene.skill.impact_logic.std_impact_352",
    [353] = "scene.skill.impact_logic.std_impact_353",
    [354] = "scene.skill.impact_logic.std_impact_354",
    [355] = "scene.skill.impact_logic.std_impact_355",
    [500] = "scene.skill.impact_logic.std_impact_500",
    [501] = "scene.skill.impact_logic.std_impact_501",
    [502] = "scene.skill.impact_logic.std_impact_502",
    [503] = "scene.skill.impact_logic.std_impact_503",
    [504] = "scene.skill.impact_logic.std_impact_504",
    [505] = "scene.skill.impact_logic.std_impact_505",
    [506] = "scene.skill.impact_logic.std_impact_506",
    [507] = "scene.skill.impact_logic.std_impact_507",
	
    [508] = "scene.skill.impact_logic.qing_huan_jian",
    [509] = "scene.skill.impact_logic.she_hun_gong",
    [510] = "scene.skill.impact_logic.li_you_qiang",
    [511] = "scene.skill.impact_logic.zhu_wang_jian",
    [512] = "scene.skill.impact_logic.chang_hen_dao",
    [513] = "scene.skill.impact_logic.nu_tao_chui",
    [514] = "scene.skill.impact_logic.null_logic_buff",
    [515] = "scene.skill.impact_logic.player_exp_rate",
    [516] = "scene.skill.impact_logic.std_impact_516",
    [517] = "scene.skill.impact_logic.std_impact_517",
    [518] = "scene.skill.impact_logic.std_impact_518",
    [519] = "scene.skill.impact_logic.std_impact_519",
    [520] = "scene.skill.impact_logic.std_impact_520",
    [521] = "scene.skill.impact_logic.std_impact_521",
    [522] = "scene.skill.impact_logic.std_impact_522",
    [523] = "scene.skill.impact_logic.std_impact_523",
    [524] = "scene.skill.impact_logic.std_impact_524",
    [525] = "scene.skill.impact_logic.std_impact_525",
    [526] = "scene.skill.impact_logic.std_impact_526",
    [527] = "scene.skill.impact_logic.xiangsibi",
    [528] = "scene.skill.impact_logic.std_impact_528",
    [529] = "scene.skill.impact_logic.std_impact_529",
    [530] = "scene.skill.impact_logic.std_impact_530",
    [531] = "scene.skill.impact_logic.std_impact_531",
    [532] = "scene.skill.impact_logic.std_impact_532",
    [533] = "scene.skill.impact_logic.std_impact_533",
    [534] = "scene.skill.impact_logic.std_impact_534",
    [535] = "scene.skill.impact_logic.std_impact_535",
    [536] = "scene.skill.impact_logic.std_impact_536",
    [537] = "scene.skill.impact_logic.std_impact_537",
    [538] = "scene.skill.impact_logic.std_impact_538",
    [539] = "scene.skill.impact_logic.std_impact_539",
    [540] = "scene.skill.impact_logic.std_impact_540",
    [541] = "scene.skill.impact_logic.std_impact_541",
    [542] = "scene.skill.impact_logic.std_impact_542",
    [543] = "scene.skill.impact_logic.std_impact_543",
    [544] = "scene.skill.impact_logic.std_impact_544",
    [545] = "scene.skill.impact_logic.std_impact_545",
    [546] = "scene.skill.impact_logic.std_impact_546",
    [547] = "scene.skill.impact_logic.std_impact_547",
    [548] = "scene.skill.impact_logic.std_impact_548",
    [549] = "scene.skill.impact_logic.std_impact_549",
    [2] = "scene.skill.impact_logic.std_impact_002", -- server-impact: mới: % máu tối đa, sát thương trực tiếp
    [16] = "scene.skill.impact_logic.std_impact_016", -- server-impact: mới: % STR/Con/SPR/INT/DEX
    [43] = "scene.skill.impact_logic.std_impact_043", -- server-impact: mới: kháng 4 hệ + hệ số nộ
    [51] = "scene.skill.impact_logic.null_logic_buff", -- server-impact: buff rỗng (分身 không tham số)
    [67] = "scene.skill.impact_logic.std_impact_067", -- server-impact: mới: xác suất, % máu hiện tại, tối thiểu
    [76] = "scene.skill.impact_logic.std_impact_076", -- server-impact: mới: sát thương cộng khi trúng impact thuộc tập
    [87] = "scene.skill.impact_logic.null_logic_buff", -- server-impact: buff rỗng (搭乘坐骑 không tham số)
    [91] = "scene.skill.impact_logic.std_impact_091", -- server-impact: mới: % công ngoại/nội
    [97] = "scene.skill.impact_logic.null_logic_buff", -- server-impact: buff rỗng (坐骑 tlbb15 không tham số)
    [98] = "scene.skill.impact_logic.std_impact_098", -- server-impact: mới: khiên nhóm 慈航普度 giảm sát thương cho chủ/đồng minh trong bán kính (RE Serverhook)
    [101] = "scene.skill.impact_logic.std_impact_101", -- server-impact: mới: 怒火连斩 đếm đao + phát 加速BUFF, đạt ngưỡng tăng sát thương (RE main Server)
    [102] = "scene.skill.impact_logic.std_impact_102", -- server-impact: mới: 一日丧命散 AOE khi kích hoạt/tan (激活/消散/死亡效果) (RE main Server)
    [103] = "scene.skill.impact_logic.std_impact_103", -- server-impact: mới: 横扫AOE mỗi nhịp quét địch gửi子效果1/2/3 (RE main Server)
    [109] = "scene.skill.impact_logic.std_impact_091", -- server-impact: dùng std_impact_091 (物理/魔法攻击修正率, MAX_HP修正率)
    [110] = "scene.skill.impact_logic.std_impact_170", -- server-impact: dùng std_impact_170 (miễn % sát thương từ trân thú)
    [113] = "scene.skill.impact_logic.std_impact_113", -- server-impact: mới: khiên máu
    [114] = "scene.skill.impact_logic.std_impact_114", -- server-impact: mới: tỉ lệ trúng/né/hội tâm (%)
    [116] = "scene.skill.impact_logic.std_impact_149", -- server-impact: dùng std_impact_149 (máu thấp)
    [122] = "scene.skill.impact_logic.std_impact_114", -- server-impact: dùng std_impact_114 (闪避修正)
    [130] = "scene.skill.impact_logic.std_impact_130", -- server-impact: mới: giới hạn dưới giảm kháng
    [145] = "scene.skill.impact_logic.std_impact_114", -- server-impact: dùng std_impact_114 (% 4 chỉ số)
    [149] = "scene.skill.impact_logic.std_impact_149", -- server-impact: mới: 基础伤害增强 (các nhãn khác chưa rõ đơn vị [SL])
    [150] = "scene.skill.impact_logic.std_impact_149", -- server-impact: dùng std_impact_149 (% theo hệ)
    [155] = "scene.skill.impact_logic.std_impact_155", -- server-impact: mới: 魂离魄散 quét địch gửi impact khi kích hoạt/chết (RE Serverhook)
    [156] = "scene.skill.impact_logic.std_impact_170", -- server-impact: dùng std_impact_170 (免疫率)
    [157] = "scene.skill.impact_logic.std_impact_149", -- server-impact: dùng std_impact_149 (dòng 157 mang nhãn 149)
    [162] = "scene.skill.impact_logic.std_impact_114", -- server-impact: dùng std_impact_114 (% 4 chỉ số + 给目标的效果)
    [169] = "scene.skill.impact_logic.std_impact_169", -- server-impact: mới: 拘魂·命/金刚不坏 hồi máu-khí theo千分比 mỗi nhịp + 免疫率 (RE Serverhook)
    [170] = "scene.skill.impact_logic.std_impact_170", -- server-impact: mới: miễn % + phản đòn
    [175] = "scene.skill.impact_logic.std_impact_015", -- server-impact: bí danh std_impact_015 (nhãn trùng 100 %)
    [176] = "scene.skill.impact_logic.std_impact_015", -- server-impact: bí danh std_impact_015 (nhãn trùng 100 %)
    [185] = "scene.skill.impact_logic.std_impact_009", -- server-impact: bí danh std_impact_009 (瞬移, nhãn trùng 100 %)
    [187] = "scene.skill.impact_logic.std_impact_170", -- server-impact: dùng std_impact_170 (免疫率; 回复/附加 chưa)
    [115] = "scene.skill.impact_logic.std_impact_115", -- skill-logic: sát thương = N % đòn đánh thường (伤害量缩放系数), theo mã CY StdImpact115_T @0xa5f2f8
    [171] = "scene.skill.impact_logic.std_impact_171", -- skill-logic: trạng thái có hẹn giờ (13 dòng: 九阳炽脉 13058, 九阴煞魄 13059, 各式刃影, 五绝计时) — thiếu ô này thì eventenginer bỏ qua impact vì get_logic trả nil
}

function impactenginer:register_all_impact_logics()
    require("cy_four_combat.bootstrap").bind_impacts(self)
    local logic_id_2_conf = {}
    local timed_only = {} -- server-impact
    for _, c in pairs(self.std_impact_config) do
        if c.logic_id then
            logic_id_2_conf[c.logic_id] = c
            if timed_only[c.logic_id] == nil then timed_only[c.logic_id] = true end
            if not c.is_over_timed then timed_only[c.logic_id] = false end
        end
    end
    logic_id_2_conf[352] = true
    local std_impact_003 = require "scene.skill.impact_logic.std_impact_003"
    for logic_id in pairs(logic_id_2_conf) do
        assert(logic_id < 8000 or self.logics[logic_id], "CY impact logic not configured: "..logic_id)
        if self.logics[logic_id] == nil then
            print("注册效果逻辑id id =", logic_id)
            local module = self.id_logic_module[logic_id]
            if module then
                self.logics[logic_id] = require(module).new()
            elseif type(logic_id_2_conf[logic_id]) == "table" and timed_only[logic_id] then
                -- server-impact: logic tlbb15 chưa cài mà mọi dòng là hiệu ứng duy trì → buff rỗng (trước: std_impact_003.on_active gọi on_damages với sát thương 0)
                self.logics[logic_id] = require("scene.skill.impact_logic.null_logic_buff").new()
            else
                self.logics[logic_id] = std_impact_003.new()
            end
        end
    end
end

return impactenginer