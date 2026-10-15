local inventory_guard = require "cys_inventory_guard"
local class = require "class"
local skynet = require "skynet"
local define = require "define"
local configenginer = require "configenginer":getinstance()
local item_cls = require "item"
local item_rule_checker = require "item_rule_checker"
--local item_manager = require "item_manager"
local item_operator = class("item_operator")

function item_operator:getinstance()
    if item_operator.instance == nil then
        item_operator.instance = item_operator.new()
    end
    return item_operator.instance
end

function item_operator:ctor()
    self.server = tonumber(skynet.getenv("process_id"))
    self.world = 1
end

function item_operator:set_scene(scene)
    self.scene = scene
    self.scene_id = scene:get_id()
end

function item_operator:get_scene()
    return self.scene
end

function item_operator:gen_item_guid()
    local guid = skynet.call(".gen_serial", "lua", "inc_serial")
    guid.mask = 0
    return guid
end

function item_operator:gen_item(log_param, item_index, way, quality, extra)
    local item = item_cls.new()
    item:set_index(item_index)
    item:set_guid(self:gen_item_guid())
    item:set_lay_count(1)
    item:get_equip_data():set_slot_count(0)
    item:set_validity_period_start_time(0)
    item:set_status(0)
    if not item_rule_checker:check_type_ruler(define.ITEM_RULER_LIST.IRL_NEED_IDENT, item_index) then
        item:set_identd()
    end
    local cls = item:get_serial_class()
    if cls == define.ITEM_CLASS.ICLASS_EQUIP then
        self:gen_equip_from_table(log_param, item, way, extra)
    elseif cls == define.ITEM_CLASS.ICLASS_GEM then
        self:gen_gem_from_table(log_param, item)
    elseif cls == define.ITEM_CLASS.ICLASS_STOREMAP then
        self:gen_store_map_from_table(log_param, item)
    elseif cls == define.ITEM_CLASS.ICLASS_PET_EQUIP then
        self:gen_pet_equip_from_table(log_param, item, way, quality)
        self:gen_pet_soul_base_attr(log_param, item)
    end
    return item
end

function item_operator:gen_equip_from_table(log_param, item, way, extra)
    local quality = item:get_serial_quality()
    item:get_equip_data():set_equip_type(0)
	if extra and extra.is_special then
		self:gen_blue_equip_attrib(log_param, item, way,extra)
	else
		if quality == define.EQUIP_QUALITY.EQUALITY_NORMAL then
			self:gen_common_equip_attrib(log_param, item, way, extra)
		else
			self:gen_blue_equip_attrib(log_param, item, way,extra)
		end
	end
end

function item_operator:gen_pet_equip_from_table(logparam, item, way, quality)
    local tb = item:get_base_config()
    -- ELF兽灵道具: equip_point == 6, 走独立初始化分支
    if tb.equip_point == define.PET_EQUIP_TYPE.ELF then
        local ped = item:get_pet_equip_data()
        ped:set_pet_equip_type(define.PET_EQUIP_TYPE.ELF)
        -- 初始状态: 未鉴定, 无装备属性, 待鉴定时填充
        ped:set_attr_count(0)
        ped:set_attr_value({})
        ped:set_attr_type(0)
        ped:set_attr_types({})
        -- 确保unknow_4是干净的12字节表
        item.unknow_4 = {}
        for _i = 1, 12 do item.unknow_4[_i] = 0 end

        -- 创建时写入技能和品阶
        local item_index = item:get_index()
        local pet_jl = configenginer:get_config("pet_jl")
        local jl_entry = pet_jl and pet_jl[item_index]
        if jl_entry then
            -- 品阶
            item:set_param(3, jl_entry.grade or 1, "uchar")
            -- 技能: 从对应系列技能池随机选取
            local skill_id = 8  -- fallback
            if jl_entry.skill_pool and #jl_entry.skill_pool > 0 then
                skill_id = jl_entry.skill_pool[math.random(1, #jl_entry.skill_pool)]
            end
            item:set_param(10, skill_id, "ushort")
        end

        -- ELF道具: 设置IEL_CREATOR位
        item.status = (item.status or 0) | define.ITEM_EXT_INFO.IEL_CREATOR
        item:set_rule(tb.rule)
        return
    end

    -- 普通珍兽装备属性处理
    local item_seg_value = configenginer:get_config("item_seg_value")
    local item_seg_rate = configenginer:get_config("item_seg_rate")
    local value_id = tb["起始数值段"]
    quality = quality or 1
    local rates_conf = item_seg_rate[quality]
    local values_conf = item_seg_value[value_id]
    local attr_count = self:gen_attr_count(tb)
    local attr_type = 0
    local attr_types = {}
    local values = {}
    local shuffled = self:shuffle_attrs(tb.ex_attrs, attr_count)
    for i, name in ipairs(shuffled) do
        local rate = rates_conf[name]
        local value = values_conf[name]
        assert(rate, name)
        assert(value, name)
        value = math.floor(value * rate / 100)
        table.insert(values, value)
        local lshift = define.EQUIP_ATTR[name]
        assert(lshift, name)
        attr_type = attr_type | 1 << lshift
        table.insert(attr_types, lshift)
        if i == attr_count then
            break
        end
    end
    item:get_pet_equip_data():set_attr_count(#values)
    item:get_pet_equip_data():set_attr_value(values)
    item:get_pet_equip_data():set_attr_type(attr_type)
    item:get_pet_equip_data():set_attr_types(attr_types)
    item:get_pet_equip_data():set_quality(quality)
    item:get_pet_equip_data():set_dur(0)
    item:get_pet_equip_data():set_max_dur(0)
    item:get_pet_equip_data():set_pet_equip_type(define.PET_EQUIP_TYPE.NORMAL)
    item:set_rule(tb.rule)
end

function item_operator:gen_pet_soul_base_attr(logparam, item)
    local pet_soul_base = item:get_pet_soul_base()
    if pet_soul_base then
        item:get_pet_equip_data():set_pet_equip_type(define.PET_EQUIP_TYPE.SOUL)
        item:get_pet_equip_data():set_level(1)
        item:get_pet_equip_data():set_pet_soul_level(0)
        item:get_pet_equip_data():set_pet_soul_exp(0)
        item:get_pet_equip_data():set_pet_soul_quanlity(pet_soul_base.level)
        local pet_soul_attr = item:get_pet_equip_data():gen_soul_attr(0, 0)
        item:get_pet_equip_data():set_pet_soul_attr(pet_soul_attr)
    end
end

function item_operator:gen_gem_from_table(log_param, item)
    local gem_info = configenginer:get_config("gem_info")
    local tb = gem_info[item:get_index()]
    item:set_rule(tb.rule)
end

function item_operator:gen_store_map_from_table(log_param, item)
    local common_item = configenginer:get_config("common_item")
    local tb = common_item[item:get_index()]
    item:set_rule(tb.rule)
end

function item_operator:gen_common_equip_attrib(log_param, item, way, extra)
    local equip_base = configenginer:get_config("equip_base")
	local item_id = item:get_index()
    local tb = equip_base[item_id]
	assert(tb,item_id)
    item:get_equip_data():set_quality(1)
    item:get_equip_data():set_visual(tb.visual)
    item:get_equip_data():set_dur(tb.max_dur)
    item:get_equip_data():set_max_dur(tb.max_dur)
    item:set_rule(tb.rule)
    if extra and extra.gem_list then
        item:get_equip_data():set_gem_list(extra.gem_list)
    end
    if require('cys_dual_souls').initialize(item) then return end
    if require('cy_equipment_passives').initialize(item) then return end
    if tb.equip_point == 17 then
        self:gen_anqi_attr(item, tb)
    elseif tb.equip_point == 18 then
        self:gen_wuhun_attr(item, tb)
    elseif tb.equip_point == 37 then
        local shenbing = configenginer:get_config("shenbing")
        shenbing = shenbing[item_id]
		assert(shenbing,item_id)
		local shenbing_visual = configenginer:get_config("shenbing_visual")
        shenbing_visual = shenbing_visual[item_id]
		assert(shenbing_visual,item_id)
		item:get_equip_data():set_visual(shenbing_visual.visual)
		item:get_equip_data():set_action(shenbing_visual.action)
        self:gen_fwq_attr(item, shenbing)
    else
        local ling_yu_base = configenginer:get_config("ling_yu_base")
        ling_yu_base = ling_yu_base[item:get_index()]
        if ling_yu_base then
            self:gen_lingyu_attr(item, ling_yu_base, tb, extra)
        end
    end
end

function item_operator:gen_fwq_attr(item, shenbing)
    local star = shenbing.Star
    local all_attrs = {}
    for _, attr in ipairs(define.FWQ_EXT_ATTRS) do
        table.insert(all_attrs, { attr = attr, num = math.random(1000)})
    end
    table.sort(all_attrs, function(a1, a2)
        return a1.num > a2.num
    end)
    local attrs = { -1, -1, -1, -1, -1, -1 }
    for i = 1, star do
        attrs[i] = all_attrs[i].attr
    end
    item:get_equip_data():set_fwq_star(star)
    item:get_equip_data():set_fwq_zhuqing(1)
    item:get_equip_data():set_fwq_live_time(8000)
    item:get_equip_data():set_fwq_attrs(attrs)
	item:get_equip_data():set_fwq_change_skill(shenbing.Change_skill)
	item:get_equip_data():set_fwq_passive_skill(shenbing.Skill_1)
	item:get_equip_data():set_fwq_list_2({0,0,0})
    item:get_equip_data():set_fwq_skill_list_1({ shenbing.Skill_2, shenbing.Skill_3 })
    item:get_equip_data():set_fwq_skill_list_2({ shenbing.Skill_4, shenbing.Skill_5, shenbing.Skill_6 })
    item:get_equip_data():set_equip_type(4)
end

function item_operator:gen_lingyu_attr(item, lingyu_base, tb, extra)
    extra = extra or {}
    local ling_yu_attr_rule = configenginer:get_config("ling_yu_attr_rule")
    local ling_yu_attr_value = configenginer:get_config("ling_yu_attr_value")
    local index = lingyu_base.equip_point
    ling_yu_attr_rule = ling_yu_attr_rule[index]
    local attrs = {}
    local num = math.random(4000)
    for attr, odd in pairs(ling_yu_attr_rule.attr_odds) do
        if odd > 0 then
            table.insert(attrs, { attr = attr - 1, num = math.random(100)})
        end
    end
    table.sort(attrs, function(a1, a2) return a1.num < a2.num end)
    local final_attrs = {}
    local attr_num = extra.attr_num or math.random(1, 3)
    for i = 1, 3 do
        if i <= attr_num then
            local n = math.random(#attrs)
            local v = table.remove(attrs, n)
            table.insert(final_attrs, v.attr)
        else
            final_attrs[i] = define.INVAILD_ID
        end
    end
    table.sort( final_attrs, function(f1, f2)
        if f1 == define.INVAILD_ID then
            return false
        end
        if f2 == define.INVAILD_ID then
            return true
        end
        return f1 < f2
    end)
    local attr_values = {}
    for i = 1, #final_attrs do
        local v = ling_yu_attr_value[final_attrs[i]]
        if v then
            local values = v.values
            local value = math.random(values[lingyu_base.class] or 0, values[lingyu_base.class + 1])
            attr_values[i] = value
        else
            attr_values[i] = 0
        end
    end
    local attr_type = 0
    local enhancement_levels = {}
    for i = #final_attrs, 1, -1 do
        if attr_values[i] == nil then
            print("final_attr =", final_attrs[i], "no vlaue remove")
            final_attrs[i] = define.INVAILD_ID
        else
            table.insert(enhancement_levels, 0)
            -- table.insert(enhancement_levels, math.random(1, 80) * 100)
        end
    end
    item:get_equip_data():set_ling_yu_attr_value(attr_values)
    item:get_equip_data():set_ling_yu_attr_types(final_attrs)
    item:get_equip_data():set_ling_yu_attrs_enhancement_level(enhancement_levels)
    item:get_equip_data():set_quality(1)
    item:get_equip_data():set_dur(tb.max_dur)
    item:get_equip_data():set_max_dur(tb.max_dur)
    item:get_equip_data():set_visual(tb.visual)
    item:get_equip_data():set_equip_type(3)
    item:set_rule(tb.rule)
end

function item_operator:is_lingyu_equip(item_index)
    local ling_yu_base = configenginer:get_config("ling_yu_base")
    return ling_yu_base[item_index] ~= nil
end

function item_operator:gen_anqi_attr(item, equip_base)
    item:get_equip_data():set_aq_xiulian(1)
    item:get_equip_data():set_aq_exp(0)
    item:get_equip_data():set_aq_grow_rate(equip_base["品阶"])
    item:get_equip_data():set_aq_xi_dian(0)
    item:get_equip_data():set_equip_type(1)
    for i = 1, 3 do
        item:get_equip_data():set_aq_skill(i, 0)
    end
    for i = 1, 5 do
        item:get_equip_data():set_aq_attr(i, 1)
    end
    item:get_equip_data():set_attr_count(5)
end

function item_operator:gen_wuhun_attr(item)
    local kfs_base = configenginer:get_config("kfs_base")
    kfs_base = kfs_base[item:get_index()]
    item:get_equip_data():set_wh_hecheng_level(1)
    item:get_equip_data():set_wh_level(1)
    item:get_equip_data():set_wh_life(300)
    item:get_equip_data():set_wh_grow_rate(kfs_base.growth_rates[1])
    item:get_equip_data():set_equip_type(2)
    for i = 1, 3 do
        item:get_equip_data():set_wh_skill(i, define.INVAILD_ID)
    end
    for i = 1, 10 do
        local ea = 0
        if i == 1 then
            local n = math.random(#kfs_base.ext_attrs)
            ea = kfs_base.ext_attrs[n]
        end
        item:get_equip_data():set_wh_ex_attr(i, ea)
    end
    item:get_equip_data():add_wh_exp(0)
    item:get_equip_data():set_wh_ex_attr_number(1)
end

function item_operator:gen_quality(quality_rule, way)
    local item_seg_quality = configenginer:get_config("item_seg_quality")
    local item_seg_affect = configenginer:get_config("item_seg_affect")
    local seg_qualitys = item_seg_quality[quality_rule]
    local quality_dist_id = seg_qualitys[way] or seg_qualitys[1]
    local seg_affect = item_seg_affect[quality_dist_id]
    local total = seg_affect.total
    local num = math.random(total)
    local now = 0
    for i = 1, 9 do
        local p = seg_affect.p[i]
        now = now + p
        if now >= num then
            return i, quality_dist_id
        end
    end
end

function item_operator:gen_attr_count(tb)
    local num = math.random(tb["属性条数min"], tb["属性条数max"])
    return num
end

function item_operator:shuffle_attrs(attrs, count)
    local shuffled = {}
    local all_attrs = table.clone(attrs)
    if count > 0 then
        for i = 1, count do
            if #all_attrs > 0 then
                local n = math.random(#all_attrs)
                table.insert(shuffled, table.remove(all_attrs, n))
            end
        end
    end
    table.sort(shuffled, function(n1, n2)
        return define.EQUIP_ATTR[n1] < define.EQUIP_ATTR[n2]
    end)
    return shuffled
end

function item_operator:gen_blue_equip_attrib(log_param, item, way,extra)
    -- local equip_base = configenginer:get_config("equip_base")
    local item_index = item:get_index()
    -- local tb = equip_base[item_index]
	local quality,attr_count
	if extra and extra.is_special then
		quality = extra.new_quality
		attr_count = extra.new_attr_count
	end
    local params,attr_types,values = self:gen_equip_attrs(item_index, way,quality,attr_count)
    item:get_equip_data():set_attr_count(#values)
    item:get_equip_data():set_attr_value(values)
    item:get_equip_data():set_attr_type(params.attr_type)
    item:get_equip_data():set_attr_types(attr_types)
    item:get_equip_data():set_quality(params.quality)
    item:get_equip_data():set_dur(params.max_dur)
    item:get_equip_data():set_max_dur(params.max_dur)
    item:get_equip_data():set_visual(params.visual)
    item:set_rule(params.rule)
end

function item_operator:get_add_attr_rate()
	local nx = math.random(100)
	if nx <= 30 then
		nx = 10
	elseif nx <= 40 then
		nx = 20
	elseif nx <= 50 then
		nx = 30
	elseif nx <= 60 then
		nx = 40
	elseif nx <= 70 then
		nx = 50
	elseif nx <= 77 then
		nx = 60
	elseif nx <= 84 then
		nx = 70
	elseif nx <= 90 then
		nx = 80
	elseif nx <= 96 then
		nx = 90
	elseif nx <= 100 then
		nx = 100
	end
	local rand = math.random(nx)
	return rand
end
function item_operator:gen_equip_attrs(item_index, way,quality,attr_count)
    local equip_base = configenginer:get_config("equip_base")
    local item_seg_value = configenginer:get_config("item_seg_value")
    local item_seg_rate = configenginer:get_config("item_seg_rate")
    -- local item_index= item:get_index()
    local tb = equip_base[item_index]
    local value_id = tb["起始数值段"]
	local quality_dist_id = 1
	if not quality then
		local quality_rule = tb["品质规则"]
		quality, quality_dist_id = self:gen_quality(quality_rule, way)
	end
    local rates_conf = item_seg_rate[quality]
    local next_rates_conf = item_seg_rate[quality + 1] or rates_conf
    local values_conf = item_seg_value[value_id]
	if not attr_count then
		attr_count = self:gen_attr_count(tb)
	end
    local attr_type = 0
    local attr_types = {}
    local values = {}
    local shuffled = self:shuffle_attrs(tb.ex_attrs, attr_count)
    local rand = self:get_add_attr_rate()
    for i, name in ipairs(shuffled) do
        local rate = rates_conf[name]
        local next_rate = next_rates_conf[name]
        local final_rate = rate + math.floor((next_rate - rate) / 100 * rand)
        if quality_dist_id < 10 then
            final_rate = rate
        end
        local value = values_conf[name]
        value = math.ceil(value * final_rate / 100)
        assert(rate, name)
        assert(value, name)
		if value > 32767 then
			value = 32767
		end
        table.insert(values, value)
        local lshift = define.EQUIP_ATTR[name]
        assert(lshift, name)
        attr_type = attr_type | 1 << lshift
        table.insert(attr_types, lshift)
        if i == attr_count then
            break
        end
    end
	local params = {}
	params.attr_type = attr_type
	params.quality = quality
	params.visual = tb.visual
	params.max_dur = tb.max_dur
	params.rule = tb.rule
    return params,attr_types,values
end
function item_operator:gen_equip_attrs_special_weapon(item_index, way,quality,attr_count)
    local equip_base = configenginer:get_config("equip_base")
    local item_seg_value = configenginer:get_config("item_seg_value")
    local item_seg_rate = configenginer:get_config("item_seg_rate")
    -- local item_index= item:get_index()
    local tb = equip_base[item_index]
    local value_id = tb["起始数值段"]
	local quality_dist_id = 1
	if not quality then
		local quality_rule = tb["品质规则"]
		quality, quality_dist_id = self:gen_quality(quality_rule, way)
	end
    local rates_conf = item_seg_rate[quality]
    local next_rates_conf = item_seg_rate[quality + 1] or rates_conf
    local values_conf = item_seg_value[value_id]
	if not attr_count then
		attr_count = self:gen_attr_count(tb)
	end
    local attr_type = 0
    local attr_types = {}
    local values = {}
    local shuffled = self:shuffle_attrs(tb.ex_attrs, attr_count)
    local rand = self:get_add_attr_rate()
    for i, name in ipairs(shuffled) do
        local rate = rates_conf[name]
        local next_rate = next_rates_conf[name]
		local final_rate = math.random(rate,next_rate)
        local value = values_conf[name]
        value = math.ceil(value * final_rate / 100)
        assert(rate, name)
        assert(value, name)
		if value > 32767 then
			value = 32767
		end
        table.insert(values, value)
        local lshift = define.EQUIP_ATTR[name]
        assert(lshift, name)
        attr_type = attr_type | 1 << lshift
        table.insert(attr_types, lshift)
        if i == attr_count then
            break
        end
    end
	local params = {}
	params.attr_type = attr_type
	params.quality = quality
	params.visual = tb.visual
	params.max_dur = tb.max_dur
	params.rule = tb.rule
    return params,attr_types,values
end
--isreset = 1 重置属性条数  = 2 默认星级随机 = 3 重置条数并默认星级随机
function item_operator:refresh_equip_attr(equip,isreset)
    local index = equip:get_index()
    local equip_base = configenginer:get_config("equip_base")
    local item_seg_value = configenginer:get_config("item_seg_value")
    local item_seg_rate = configenginer:get_config("item_seg_rate")
    local base = equip_base[index]
    local value_id = base["起始数值段"]
    local values_conf = item_seg_value[value_id]
    if not base then
        return false
    end
	local attr_count = 0
	if isreset == 1 or isreset == 3 then
		attr_count = self:gen_attr_count(base)
	else
		local attr_types = equip:get_equip_data():get_attr_types()
		attr_count = #attr_types
	end
    if attr_count == 0 then
        return false
    end
    local quality = equip:get_equip_data():get_quality()
    local result_attr_type = 0
    local shuffled = self:shuffle_attrs(base.ex_attrs, attr_count)
    local result_values = {}
    local result_attr_types = {}
    local rates_conf = item_seg_rate[quality]
    local next_rates_conf = item_seg_rate[quality + 1] or rates_conf
    -- local rand = self:get_add_attr_rate()
    local rand = math.random(100)
    for i, name in ipairs(shuffled) do
        local rate = rates_conf[name]
        local next_rate = next_rates_conf[name]
        local final_rate = rate + math.floor((next_rate - rate) / 100 * rand)
		if isreset == 2 or isreset == 3 then
            final_rate = rate
        end
        local value = values_conf[name]
        value = math.ceil(value * final_rate / 100)
		if value > 32767 then
			value = 32767
		end
        table.insert(result_values, value)
        local lshift = define.EQUIP_ATTR[name]
        assert(lshift, name)
        result_attr_type = result_attr_type | 1 << lshift
        table.insert(result_attr_types, lshift)
        if i == attr_count then
            break
        end
    end
    return result_attr_type, result_attr_types, result_values
end
--+qh attr
function item_operator:gen_equip_qh_attrs(equip,add_qhd)
	local equip_data = equip:get_equip_data()
	local quality = equip_data:get_quality()
    local item_seg_rate = configenginer:get_config("item_seg_rate")
    local rates_conf = item_seg_rate[quality]
	if not rates_conf then
		return
	end
	local item_index = equip:get_index()
    local equip_base = configenginer:get_config("equip_base")
    local base = equip_base[item_index]
    if not base then
        return false
    end
	local quality_yuan = base["品质规则"]
	if quality_yuan < 1 or quality_yuan > 9 then
		quality_yuan = 1
	end
    local rates_conf_yuan = item_seg_rate[quality_yuan]
	if not rates_conf_yuan then
		return
	end
	
    local item_seg_value = configenginer:get_config("item_seg_value")
    local value_id = base["起始数值段"]
    local values_conf = item_seg_value[value_id]
	

	local qhd = equip_data:get_qihedu()
	local qhd_lv = qhd % 100
	local attr_rate = 4 * qhd_lv
	local hp_mp_rate = 0
	local attr_jk_rate = 3.5 * qhd_lv
	if qhd_lv >= 11 then
		attr_rate = 5 * qhd_lv
		hp_mp_rate = 3
		attr_jk_rate = 3.5 * qhd_lv
	end
	if qhd_lv == 20 then
		hp_mp_rate = 6
	end
	local attr_types = equip_data:get_attr_types()
	local attr_vales = equip_data:get_attr_vales()
	
	local name,value,rate
	for i,key in pairs(attr_types) do
		name = define.CHN_ATTR_SHIFT[key]
		if key == define.ITEM_ATTRIBUTE.IATTRIBUTE_RATE_MAXHP
		or key == define.ITEM_ATTRIBUTE.IATTRIBUTE_RATE_MAXMP then
			-- if add_qhd >= 2 then
				value = values_conf[name]
				rate = rates_conf_yuan[name]
				value = math.ceil(value * rate / 100)
				attr_vales[i] = value + hp_mp_rate
			-- end
		-- elseif lshift == define.ITEM_ATTRIBUTE.IATTRIBUTE_REDUCE_TARGET_COLD_RESIST
		-- or lshift == define.ITEM_ATTRIBUTE.IATTRIBUTE_REDUCE_TARGET_FIRE_RESIST
		-- or lshift == define.ITEM_ATTRIBUTE.IATTRIBUTE_REDUCE_TARGET_LIGHT_RESIST
		-- or lshift == define.ITEM_ATTRIBUTE.IATTRIBUTE_REDUCE_TARGET_POISON_RESIST then
			-- rate = rates_conf[name] + attr_jk_rate
			-- value = values_conf[name]
			-- skynet.logi("value = ",value,"rate = ",rate)
			-- value = math.ceil(value * rate / 100)
		elseif name then
			value = values_conf[name]
			rate = rates_conf[name] + attr_rate
			value = math.ceil(value * rate / 100)
			if value > 32767 then
				value = 32767
			end
			attr_vales[i] = value
		end
	end
end
--cx qh attr
function item_operator:refresh_equip_attr_qh(item_index,quality,qhd)
    local equip_base = configenginer:get_config("equip_base")
    local base = equip_base[item_index]
    if not base then
        return false
    end
    local item_seg_rate = configenginer:get_config("item_seg_rate")
    local rates_conf = item_seg_rate[quality]
	if not rates_conf then
		return
	end
	local quality_yuan = base["品质规则"]
	if quality_yuan < 1 or quality_yuan > 9 then
		quality_yuan = 1
	end
    local rates_conf_yuan = item_seg_rate[quality_yuan]
	if not rates_conf_yuan then
		return
	end
	
    local item_seg_value = configenginer:get_config("item_seg_value")
    local value_id = base["起始数值段"]
    local values_conf = item_seg_value[value_id]
	
	local attr_count = self:gen_attr_count(base)
    if attr_count == 0 then
        return false
    end
    local result_attr_type = 0
    local shuffled = self:shuffle_attrs(base.ex_attrs, attr_count)
    local result_values = {}
    local result_attr_types = {}

	local num = 0
	
	local qhd_lv = qhd % 100
	local attr_rate = 4 * qhd_lv
	local hp_mp_rate = 0
	local attr_jk_rate = 3.5 * qhd_lv
	if qhd_lv >= 11 then
		attr_rate = 5 * qhd_lv
		hp_mp_rate = 3
		attr_jk_rate = 3.5 * qhd_lv
	end
	if qhd_lv == 20 then
		hp_mp_rate = 6
	end
    for i, name in ipairs(shuffled) do
        local lshift = define.EQUIP_ATTR[name]
		if lshift then
			local rate = rates_conf[name]
			local value = values_conf[name]
			if lshift == define.ITEM_ATTRIBUTE.IATTRIBUTE_RATE_MAXHP
			or lshift == define.ITEM_ATTRIBUTE.IATTRIBUTE_RATE_MAXMP then
				rate = rates_conf_yuan[name]
				value = math.ceil(value * rate / 100)
				value = value + hp_mp_rate
			-- elseif lshift == define.ITEM_ATTRIBUTE.IATTRIBUTE_REDUCE_TARGET_COLD_RESIST
			-- or lshift == define.ITEM_ATTRIBUTE.IATTRIBUTE_REDUCE_TARGET_FIRE_RESIST
			-- or lshift == define.ITEM_ATTRIBUTE.IATTRIBUTE_REDUCE_TARGET_LIGHT_RESIST
			-- or lshift == define.ITEM_ATTRIBUTE.IATTRIBUTE_REDUCE_TARGET_POISON_RESIST then
				-- rate = rate + attr_jk_rate
				-- skynet.logi("value = ",value,"rate = ",rate)
				-- value = math.ceil(value * rate / 100)
			else
				rate = rate + attr_rate
				value = math.ceil(value * rate / 100)
			end
			if value > 32767 then
				value = 32767
			end
			table.insert(result_values, value)
			result_attr_type = result_attr_type | 1 << lshift
			table.insert(result_attr_types, lshift)
			num = num + 1
			if num == attr_count then
				break
			end
		end
    end
    return result_attr_type, result_attr_types, result_values
end
--reset attr
function item_operator:qh_reset_equip_attrs(equip)
    local equip_base = configenginer:get_config("equip_base")
    local item_seg_value = configenginer:get_config("item_seg_value")
    local item_seg_rate = configenginer:get_config("item_seg_rate")
    local item_index = equip:get_index()
    local tb = equip_base[item_index]
	if not tb then
		return false
	end
    local value_id = tb["起始数值段"]
	local quality = tb["品质规则"]
	if quality < 1 or quality > 9 then
		quality = 9
	end
    local rates_conf = item_seg_rate[quality]
    local values_conf = item_seg_value[value_id]
	local attr_count = self:gen_attr_count(tb)
    if attr_count == 0 then
        return false
    end
    local attr_type = 0
    local attr_types = {}
    local values = {}
    local shuffled = self:shuffle_attrs(tb.ex_attrs, attr_count)
	local num = 0
    for i, name in ipairs(shuffled) do
        local lshift = define.EQUIP_ATTR[name]
		if lshift then
			local rate = rates_conf[name]
			local value = values_conf[name]
			value = math.ceil(value * rate / 100)
			if value > 32767 then
				value = 32767
			end
			table.insert(values, value)
			attr_type = attr_type | 1 << lshift
			table.insert(attr_types, lshift)
			num = num + 1
			if num == attr_count then
				break
			end
		end
    end
	local equip_data = equip:get_equip_data()
	equip_data:set_quality(quality)
	equip_data:set_attr_count(#values)
	equip_data:set_attr_value(values)
	equip_data:set_attr_type(attr_type)
	equip_data:set_attr_types(attr_types)
    return true
end

function item_operator:create_pet(log_param, template)

end

function item_operator:create_item(log_param, template, dest_container, dest_index)
    -- CYS-INV create destination
    if dest_index ~= define.INVAILD_ID and not inventory_guard.accepts(dest_container, dest_index, template) then
        return define.ITEM_OPERATOR_ERROR.ITEMOE_UNKNOW
    end
    local item = table.clone(template)
    if dest_index == define.INVAILD_ID then
        if item:get_type() ~= define.ITEM_DATA_TYPE.IDT_PET then
            local sour_lay_count = item:get_layed_num()
            local rep_index = dest_container:get_index_by_type(item:get_item_table_index(), item:get_get_layed_num())
            if rep_index ~= define.INVAILD_ID then
                local dest_item = dest_container:get_item(rep_index)
                if not dest_item:is_lock() and dest_item:can_lay() then
                    local dest_lay_count = dest_item:get_layed_num()
                    local max_dest_lay_count = dest_item:get_max_layed_num()
                    if dest_lay_count + sour_lay_count <= max_dest_lay_count then
                        self:set_item_lay_count(dest_container, rep_index, dest_lay_count + sour_lay_count)
                        return rep_index
                    end
                end
            end
        end
        local bag = item:get_place_bag()
        dest_index = dest_container:get_empty_item_index(bag)
        if dest_index == define.INVAILD_ID then
            return define.ITEM_OPERATOR_ERROR.ITEMOE_DESTOPERATOR_FULL
        end
    else
        local dest_item = dest_container:get_item(dest_index)
        if dest_item then
            return define.ITEM_OPERATOR_ERROR.ITEMOE_DESTOPERATOR_HASITEM
        end
    end
    local type = item:get_type()
    if type == define.ITEM_DATA_TYPE.IDT_ITEM then
        local guid = self:gen_item_guid()
        if guid == nil then
            return define.ITEM_OPERATOR_ERROR.ITEMOE_CREATEGUID_FAIL
        end
        dest_container:set_item(dest_index, item)
        self:set_item_guid(dest_container, dest_index, guid)
    elseif type == define.ITEM_DATA_TYPE.IDT_PET then
        local guid = self:gen_item_guid()
        if guid == nil then
            return define.ITEM_OPERATOR_ERROR.ITEMOE_CREATEGUID_FAIL
        end
        dest_container:set_item(dest_index, item)
        self:set_item_guid(dest_container, dest_index, guid)
    else
        return define.ITEM_OPERATOR_ERROR.ITEMOE_CREATEGUID_FAIL
    end
    return define.ITEM_OPERATOR_ERROR.ITEMOE_SUCCESS
end

function item_operator:create_item_with_quality(log_param, itemindex, dest_container, is_bind, way, quality, extra)
    print("create_item_with_quality itemindex =", itemindex, dest_container, is_bind, way)
    if itemindex == 0 or itemindex == define.INVAILD_ID then
        return false
    end
    local new_empty_pos
    if item_rule_checker:check_type_ruler(define.ITEM_RULER_LIST.IRL_TILE, itemindex) then
        print("dest_container cls =", dest_container.classname)
        local no_full_bag_index = dest_container:get_no_full_item_index(itemindex, is_bind)
        print("no_full_bag_index =", no_full_bag_index)
        if no_full_bag_index ~= define.INVAILD_ID then
            new_empty_pos = false
            return self:inc_item_lay_count(dest_container, no_full_bag_index), no_full_bag_index, new_empty_pos
        end
    end
    local item = self:gen_item(log_param, itemindex, way, quality, extra)
    if item == nil then
        return false
    end
    item:set_is_bind(is_bind)
    local bag = item:get_place_bag()
    local empty_bag_index = dest_container:get_empty_item_index(bag)
    print("empty_bag_index =", empty_bag_index)
    if empty_bag_index == define.INVAILD_ID then
        return false
    end
    dest_container:set_item(empty_bag_index, item)
    new_empty_pos = true
    return true, empty_bag_index, new_empty_pos
end

function item_operator:copy_item()

end

function item_operator:move_item(source_container, source_index, dest_container, dest_index, flag)
    local fail = define.ITEM_OPERATOR_ERROR.ITEMOE_UNKNOW
    if not inventory_guard.accepts(source_container, source_index) then return fail end
    local source = source_container:get_item(source_index)
    if not source or source:is_lock() then return fail end
    if source_container == dest_container and source_index == dest_index then return fail end
    local before = source:get_lay_count()
    local function unchanged(pos, dest, count)
        return source_container:get_item(source_index) == source and not source:is_lock()
            and source:get_lay_count() == before and dest_container:get_item(pos) == dest
            and (not dest or (not dest:is_lock() and dest:get_lay_count() == count))
            and inventory_guard.accepts(source_container, source_index, source)
            and inventory_guard.accepts(dest_container, pos, source)
    end
    if dest_index == define.INVAILD_ID then
        -- Search all candidates with full bind/metadata checks, never the first
        -- same-ID stack (which may have different binding or expiration).
        local size = dest_container:get_size()
        local last = type(size) == 'table' and 219 or size - 1
        for i = 0, last do
            local dest = dest_container:get_item(i)
            local count = dest and dest:get_lay_count() or 0
            if inventory_guard.accepts(dest_container, i, source)
                and inventory_guard.stackable(source, dest)
                and source:get_lay_count() + dest:get_lay_count() <= dest:get_max_tile_count() then
                if not unchanged(i, dest, count) then return fail end
                dest:set_lay_count(count + before)
                source_container:erase_item(source_index)
                return i
            end
        end
        dest_index = dest_container:get_empty_item_index(source:get_place_bag())
    end
    if not inventory_guard.accepts(dest_container, dest_index, source) then return fail end
    local dest = dest_container:get_item(dest_index)
    local count = dest and dest:get_lay_count() or 0
    if dest then
        if not inventory_guard.stackable(source, dest) then return fail end
        local add = math.min(source:get_lay_count(), dest:get_max_tile_count() - dest:get_lay_count())
        if add <= 0 or not unchanged(dest_index, dest, count) then return fail end
        dest:set_lay_count(count + add)
        local left = before - add
        if left == 0 then source_container:erase_item(source_index) else source:set_lay_count(left) end
    else
        if not unchanged(dest_index, nil, 0) then return fail end
        dest_container:set_item(dest_index, source)
        source_container:erase_item(source_index)
    end
    return dest_index
end

function item_operator:exchange_item(source_container, source_index, dest_container, dest_index, checkfalse)
    -- CYS-INV exchange destinations
    if not inventory_guard.accepts(source_container, source_index)
        or not inventory_guard.accepts(dest_container, dest_index) then
        return define.ITEM_OPERATOR_ERROR.ITEMOE_UNKNOW
    end
    local si, di = source_container:get_item(source_index), dest_container:get_item(dest_index)
    if (si and si:is_lock()) or (di and di:is_lock())
        or not inventory_guard.accepts(dest_container, dest_index, si)
        or not inventory_guard.accepts(source_container, source_index, di) then
        return define.ITEM_OPERATOR_ERROR.ITEMOE_UNKNOW
    end
	local source = source_container:get_item(source_index)
	if not checkfalse then
		if not source then
			return define.ITEM_OPERATOR_ERROR.ITEMOE_SOUROPERATOR_EMPTY
		end
	end
	local source_container_type = source_container:get_container_flag()
	local dest_container_flag = dest_container:get_container_flag()
	local isok
	if source_container_type == define.CONTAINER_INDEX.HUMAN_BAG then
		if dest_container_flag == define.CONTAINER_INDEX.HUMAN_BAG
		or dest_container_flag == define.CONTAINER_INDEX.HUMAN_BANK
		or dest_container_flag == define.CONTAINER_INDEX.HUMAN_SELF
		or dest_container_flag == define.CONTAINER_INDEX.HUMAN_FASION
		or dest_container_flag == define.CONTAINER_INDEX.HUMAN_SHANGHUI_ITEM
		or dest_container_flag == define.CONTAINER_INDEX.HUMAN_PET_EQUIP then
			isok = true
		end
	elseif source_container_type == define.CONTAINER_INDEX.HUMAN_BANK then
		if dest_container_flag == define.CONTAINER_INDEX.HUMAN_BAG
		or dest_container_flag == define.CONTAINER_INDEX.HUMAN_BANK then
			isok = true
		end
	elseif source_container_type == define.CONTAINER_INDEX.HUMAN_SELF then
		if dest_container_flag == define.CONTAINER_INDEX.HUMAN_BAG
		or dest_container_flag == define.CONTAINER_INDEX.HUMAN_FASION then
			isok = true
		end
	elseif source_container_type == define.CONTAINER_INDEX.HUMAN_FASION then
		if dest_container_flag == define.CONTAINER_INDEX.HUMAN_BAG
		or dest_container_flag == define.CONTAINER_INDEX.HUMAN_FASION
		or dest_container_flag == define.CONTAINER_INDEX.HUMAN_SELF then
			isok = true
		end
	elseif source_container_type == define.CONTAINER_INDEX.HUMAN_SHANGHUI_ITEM then
		if dest_container_flag == define.CONTAINER_INDEX.HUMAN_BAG
		or dest_container_flag == define.CONTAINER_INDEX.HUMAN_SHANGHUI_ITEM then
			isok = true
		end
	elseif source_container_type == define.CONTAINER_INDEX.HUMAN_PET_EQUIP then
		if dest_container_flag == define.CONTAINER_INDEX.HUMAN_BAG then
			isok = true
		end
	elseif source_container_type == define.CONTAINER_INDEX.HUMAN_PET_BAG then
		if dest_container_flag == define.CONTAINER_INDEX.HUMAN_PET_BANK
		or dest_container_flag == define.CONTAINER_INDEX.HUMAN_SHANGHUI_PET then
			isok = true
		end
	elseif source_container_type == define.CONTAINER_INDEX.HUMAN_PET_BANK then
		if dest_container_flag == define.CONTAINER_INDEX.HUMAN_PET_BAG then
			isok = true
		end
	elseif source_container_type == define.CONTAINER_INDEX.HUMAN_SHANGHUI_PET then
		if dest_container_flag == define.CONTAINER_INDEX.HUMAN_PET_BAG then
			isok = true
		end
	end
	if not isok then
		return define.ITEM_OPERATOR_ERROR.ITEMOE_SOUROPERATOR_EMPTY
	end
    local dest = dest_container:get_item(dest_index)
    -- if dest and source:get_type() ~= dest:get_type() then
        -- return define.ITEM_OPERATOR_ERROR.ITEMOE_DIFF_ITEM_DATA
    -- end
	
	
    source_container:set_item(source_index, dest)
    dest_container:set_item(dest_index, source)
    return define.ITEM_OPERATOR_ERROR.ITEMOE_SUCCESS
end

function item_operator:split_item(logparam, src_container, src_index, count, dest_container, dest_index)
    local fail = define.ITEM_OPERATOR_ERROR.ITEMOE_UNKNOW
    if not inventory_guard.accepts(src_container, src_index) then return fail end
    local item = src_container:get_item(src_index)
    if not item or item:is_empty() or item:is_lock() or not item:can_lay()
        or not inventory_guard.integer(count, 1, item:get_lay_count() - 1) then return fail end
    if dest_index == define.INVAILD_ID then dest_index = dest_container:get_empty_item_index(item:get_place_bag()) end
    if not inventory_guard.accepts(dest_container, dest_index, item)
        or dest_container:get_item(dest_index) then return fail end
    local before = item:get_lay_count()
    local copy = table.clone(item)
    local guid = self:gen_item_guid() -- may yield; nothing has been changed yet
    if not guid or src_container:get_item(src_index) ~= item or item:is_lock()
        or item:get_lay_count() ~= before or dest_container:get_item(dest_index)
        or not inventory_guard.accepts(dest_container, dest_index, item) then return fail end
    copy:set_guid(guid)
    copy:set_lay_count(count)
    dest_container:set_item(dest_index, copy)
    item:set_lay_count(before - count)
    return define.ITEM_OPERATOR_ERROR.ITEMOE_SUCCESS
end

function item_operator:move_splice_item()

end

function item_operator:set_item_lay_count(container, index, count)
    local item = container:get_item(index)
    item:set_lay_count(count)
end

function item_operator:set_item_guid(container, index, guid)
    local item = container:get_item(index)
    item:set_guid(guid)
end

function item_operator:dec_item_lay_count(container, bag_index, count)
    local item = container:get_item(bag_index)
    if item:is_empty() then
        return false
    end
    if item:is_lock() then
        return false
    end
    return container:dec_item_lay_count(bag_index, count)
end

function item_operator:inc_item_lay_count(container, index, count)
    return container:inc_item_lay_count(index, count)
end

function item_operator:set_item_dur()

end

function item_operator:set_item_ident()

end

function item_operator:set_item_damage_point()

end

function item_operator:set_item_max_dur()

end

function item_operator:set_item_bind()

end

function item_operator:item_fail_times()

end

function item_operator:set_item_pw_lock()

end

function item_operator:set_item_creator()

end

function item_operator:set_item_param()

end

function item_operator:add_item_attr()

end

function item_operator:del_item_attr()

end

function item_operator:del_gem_info()

end

function item_operator:add_gem_info()

end

--宠物操作
function item_operator:set_item_value()

end

function item_operator:set_pet_guid()

end

function item_operator:set_spouse_guid()

end

function item_operator:set_data_id()

end

function item_operator:set_name()

end

function item_operator:set_nick()

end

function item_operator:set_level()

end

function item_operator:set_take_level()

end

function item_operator:set_attack_type()

end

function item_operator:set_ai_type()

end

function item_operator:set_hp()

end

function item_operator:set_life()

end

function item_operator:set_pet_type()

end

function item_operator:set_generation()

end

function item_operator:set_happiness()

end

function item_operator:set_str_per()

end

function item_operator:set_con_per()

end

function item_operator:set_dex_per()

end

function item_operator:set_spr_per()

end

function item_operator:set_int_per()

end

function item_operator:set_gen_gu()

end

function item_operator:set_grow_rate()

end

function item_operator:set_reamin_point()

end

function item_operator:set_exp()

end

function item_operator:set_lv1_attr()

end

function item_operator:set_skill()

end

function item_operator:lock_item()

end

function item_operator:unlock_item(container, bag_index)

end

return item_operator
