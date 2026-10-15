local crypt = require "skynet.crypt"
local gbk = require "wire_charset"
local packet_def = require "game.packet"
local class = require "class"
local define = require "define"
local guid_cls = require "guid"
local iostream = require "iostream"
local item_rule_checker = require "item_rule_checker"
local configenginer = require "configenginer":getinstance()
local equip_data = class("equip_data")
function equip_data:ctor()
    self.attr_count = 0
    self.attr_values = {}
    self.attr_types = {}
    self.attr_type = 0
    self.quality = 0
    self.dur = 0
    self.max_dur = 0
    self.visual = 0
    self.qualifications = {0, 0, 0, 0, 0, 0}
    self.gem_count = 0
    self.enhancement_level = 0
    self.unknow_7 = 0
    self.unknow_9 = 0
    self.unknow_4 = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
    self.list_2 = {0, 0, 0, 0}
    self.diaowen_id = 0
    self.diaowen_material_count = 0
	self.reshuffle_count = 0
	self.dw_advance_level = 0
	self.dw_rankexp = 0
	self.dw_featuresid = 0
	
end

function equip_data:get_reshuffle_count()
	return self.reshuffle_count
end

function equip_data:set_reshuffle_count(value)
	if not value or value < 0 or value > 255 then
		return
	end
	self.reshuffle_count = value
end

function equip_data:set_dw_jinjie_details(dw_advance_level,dw_rankexp,dw_featuresid)
	self.dw_advance_level = dw_advance_level
	self.dw_rankexp = dw_rankexp
	self.dw_featuresid = dw_featuresid
end

function equip_data:get_dw_jinjie_details()
	return self.dw_advance_level,self.dw_featuresid,self.dw_rankexp
end

function equip_data:set_dw_jinjie_finedraw(dw_advance_level,dw_rankexp)
	self.dw_advance_level = dw_advance_level
	self.dw_rankexp = dw_rankexp
end

function equip_data:get_dw_jinjie_finedraw()
	return self.dw_advance_level,self.dw_rankexp
end

function equip_data:get_dw_jinjie_featuresid()
	return self.dw_featuresid,self.dw_advance_level
end

function equip_data:set_dw_jinjie_featuresid(dw_featuresid)
	self.dw_featuresid = dw_featuresid
end

function equip_data:set_attr_count(count)
    self.attr_count = count
end

function equip_data:set_attr_value(value)
    if value then
        self.attr_values = table.clone(value)
    end
end

function equip_data:get_attr_vales()
    return self.attr_values
end

function equip_data:set_attr_type(type)
    self.attr_type = type
end

function equip_data:set_attr_types(ats)
    self.attr_types = ats
end

function equip_data:get_attr_types()
    return self.attr_types
end

function equip_data:get_attr_count()
    return #self.attr_types
end

function equip_data:add_attr(attr, val)
    if attr < define.ITEM_ATTRIBUTE.IATTRIBUTE_POINT_MAXHP then
        return false
    end
    if attr > define.ITEM_ATTRIBUTE.IATTRIBUTE_REDUCE_TARGET_POISON_RESIST then
        return false
    end
    if val < 0 or val > define.USHORT_MAX then
        return false
    end
    local lshift = attr
    self.attr_type = self.attr_type | 1 << lshift
    local pos = self:get_attr_pos(attr)
    if pos == nil then
        table.insert(self.attr_types, attr)
        table.sort(self.attr_types, function(a1, a2) return a1 < a2 end)
        pos = self:get_attr_pos(attr)
    end
    self.attr_values[pos] = val
    self.attr_count = #self.attr_types
    return true
end

function equip_data:get_attr_pos(attr)
    for i, at in ipairs(self.attr_types) do
        if at == attr then
            return i
        end
    end
end

function equip_data:set_quality(quality)
    self.quality = quality
end

function equip_data:get_quality()
    return self.quality
end

function equip_data:set_dur(dur)
    self.dur = dur
end

function equip_data:get_dur()
    return self.dur
end

function equip_data:get_damage_point()
    return self.damage_point or 0
end

function equip_data:set_damage_point(point)
    self.damage_point = point
end

function equip_data:set_max_dur(max_dur)
    self.max_dur = max_dur
end

function equip_data:get_max_dur()
    return self.max_dur
end

function equip_data:set_repaire_fail_times(times)
    self.unknow_7 = times
end

function equip_data:get_repaire_fail_times()
    return self.unknow_7
end

function equip_data:set_visual(visual)
    self.visual = visual
end

function equip_data:get_visual()
    return self.visual or 0
end

function equip_data:set_action(action)
    self.action = action
end

function equip_data:get_action()
    return self.action or -1
end

function equip_data:set_qualifications(qualifications)
    if qualifications then
        self.qualifications = table.clone(qualifications)
    end
end

function equip_data:get_qualifications()
    return self.qualifications
end

function equip_data:set_creator(name)
    self.creator = name
end

function equip_data:get_creator()
    return self.creator
end

function equip_data:set_equip_type(type)
    self.equip_type = type
end

function equip_data:get_equip_type()
    return self.equip_type
end

function equip_data:get_equip_point()
    return self.equip_type
end

function equip_data:set_slot_count(count)
    self.slot_count = count
end

function equip_data:get_slot_count()
    return self.slot_count
end

function equip_data:add_slot()
    self.slot_count = self.slot_count + 1
end

function equip_data:get_slot_gem(location)
    return self.list_2[location]
end

function equip_data:gem_embed(location, gem)
    -- 只有该槽位原本为空时才增加 gem_count，避免宝石升级等"替换"操作导致计数虚增
    if not self.list_2[location] or self.list_2[location] == 0 then
        self.gem_count = self.gem_count + 1
    end
    self.list_2[location] = gem
end

function equip_data:set_gem_list(list)
    self.list_2 = table.clone(list)
end

function equip_data:get_gem_list()
    return self.list_2
end

function equip_data:set_enhancement_level(level)
    self.enhancement_level = level
end

function equip_data:get_enhancement_level()
    return self.enhancement_level
end

-- CYS-EQUIP 17/09/2026: nho ID ngoc la da lam hong get_gem_attrs (xem Tools/server/gem_guard.py).
local cys_gem_missing_logged = {}

function equip_data:get_gem_attrs()
    local gem_attrs = {}
    local gem_config = configenginer:get_config("gem_info")
    for i = 1, 4 do
        local id = self.list_2[i] or 0
        if id > 0 then
            local config = gem_config[id]
            -- CYS-EQUIP: `human_item_logic:gem_compound_item_index` tinh ID ngoc cap ke tiep thuan so
            -- hoc va KHONG kiem bang, nen co ID khong co dong trong GemInfo.txt (30 cong thuc, do live
            -- 17/09). Thieu guard nay thi `config[chn]` ben duoi nem "index a nil value" NGAY trong
            -- item_effect_flush => nhan vat mat SACH thuoc tinh trang bi.
            if config == nil then
                if not cys_gem_missing_logged[id] then
                    cys_gem_missing_logged[id] = true
                    print("[CYS-EQUIP] gem id khong co trong GemInfo.txt, bo qua:", id)
                end
            else
            for i = define.ITEM_ATTRIBUTE.IATTRIBUTE_POINT_MAXHP, define.ITEM_ATTRIBUTE.IATTRIBUTE_BASE_MISS do
                local chn = define.CHN_ATTR_SHIFT[i]
                if chn then
                    local value = config[chn]
                    if value and value > 0 then
                        gem_attrs[i] = (gem_attrs[i] or 0) + value
                    end
                end
            end
            end
        end
    end
    return gem_attrs
end

function equip_data:remove_gem(location)
    self.list_2[location] = 0
    self.gem_count = self.gem_count - 1
end

function equip_data:set_gem_count(count)
    self.gem_count = count
end

function equip_data:get_gem_count()
    return self.gem_count
end

function equip_data:set_creator(creator)
    self.creator = creator
end

function equip_data:is_judge_aptd()
    local is_jduge_aptd = false
    for i = 1, 6 do
        if self.qualifications[i] ~= 0 then
            is_jduge_aptd = true
        end
    end
    return is_jduge_aptd
end
function equip_data:judge_apt(equipid)
	local valmin,valmax
	local equip_base = configenginer:get_config("equip_base")
	local equip = equip_base[equipid]
	if equip then
		valmin,valmax = equip["资质min"],equip["资质max"]
	end
	valmin = valmin or 1
	valmax = valmax or 1
	if valmax > 0 and valmax < 255 then
		valmax = 255
	end
    for i = 1, 6 do
        self.qualifications[i] = math.random(valmin,valmax)
    end
end

function equip_data:get_apt(i)
    return self.qualifications[i]
end

function equip_data:set_aq_xiulian(xiulian)
    self.aq_xiulian = xiulian
end

function equip_data:get_aq_xiulian()
    return self.aq_xiulian
end

function equip_data:set_aq_exp(exp)
    self.aq_exp = math.max(0, exp or 0)
end

function equip_data:get_aq_exp()
    return self.aq_exp
end

function equip_data:set_aq_skill(i, skill)
    self.aq_skill = self.aq_skill or {0, 0, 0}
    self.aq_skill[i] = skill
end

function equip_data:get_aq_skill(i)
    self.aq_skill = self.aq_skill or {0, 0, 0}
    return self.aq_skill[i]
end

function equip_data:set_aq_attr(i, value)
    self.aq_attr = self.aq_attr or {0, 0, 0, 0, 0}
    self.aq_attr[i] = value
    local name = define.ANQI_ATTR[i]
    local lshift = define.EQUIP_ATTR[name]
    self.attr_types[i] = lshift
    self.attr_values[i] = value
    if lshift then
        self.attr_type = (self.attr_type or 0) | (1 << lshift)
    end
end

function equip_data:get_aq_attr(i)
    self.aq_attr = self.aq_attr or {0, 0, 0, 0, 0}
    return self.aq_attr[i]
end

function equip_data:set_aq_grow_rate(rate)
    self.aq_grow_rate = rate
end

function equip_data:get_aq_grow_rate()
    return self.aq_grow_rate
end

function equip_data:set_aq_xi_dian(xi_dian)
    self.aq_xidian = xi_dian
end

function equip_data:get_aq_xi_dian()
    return self.aq_xidian
end

function equip_data:add_exp(add_exp, award_exp)
    assert(self.equip_type == 1, self.equip_type)
    if self.aq_xiulian >= 119 then
        return 0, 0
    end
    if self.aq_xiulian >= 30 and self.aq_xiulian % 10 == 9 then
        return 0, 0
    end
    local dark_exp_level = configenginer:get_config("dark_exp_level")
    self.aq_exp = self.aq_exp + add_exp + award_exp
    local up_level = dark_exp_level[self.aq_xiulian]
    while up_level and self.aq_exp > up_level and self.aq_xiulian < 119 do
        self.aq_exp = self.aq_exp - up_level
        self.aq_xiulian = self.aq_xiulian + 1
        up_level = dark_exp_level[self.aq_xiulian]
        self:on_anqi_level_up()
    end
    if up_level == nil then
        self.aq_exp = 0
    end
    return add_exp, award_exp
end

function equip_data:on_anqi_level_up()
    for i = 1, 5 do
        local n = math.random(3)
        if n == 1 or n == 2 then
            local ai = math.random(5)
            local v = self:get_aq_attr(ai)
            self:set_aq_attr(ai, v + 1)
        end
    end
    self:anqi_understand_skill()
    self:anqi_upgrade_skill()
end

function equip_data:anqi_understand_skill()
    local level=self:get_aq_xiulian()
    local spec=define.ANQI_SKILL[level]
    if not spec then return end
    local skill=require('cy_equipment_skills').dark_effect(spec.index,level)
    if skill then self:set_aq_skill(spec.index,skill) end
end

function equip_data:anqi_upgrade_skill(force)
    local level=self:get_aq_xiulian()
    if not force and level%10~=0 then return end
    local skills=require('cy_equipment_skills')
    for i,required in ipairs({40,70,90})do
        if level>=required then
            local old=self:get_aq_skill(i)
            local kind=skills.dark_kind(i,old)
            -- Preserve a valid family on level-up; never silently reroll an unknown ID.
            if kind then
                local id=skills.dark_effect(i,level,kind)
                if id then self:set_aq_skill(i,id) end
            end
        end
    end
end

function equip_data:get_aq_skill_type(skill_id, std_imp)
    local dark_skill_list = configenginer:get_config("dark_skill_list")
    local grades = dark_skill_list[skill_id]
    for _, types_impacts in pairs(grades) do
        for n, impacts in pairs(types_impacts) do
            for _, imp in pairs(impacts) do
                if imp == std_imp then
                    return n
                end
            end
        end
    end
end

function equip_data:dark_level_up()
    if self.aq_xiulian >= 119 then
        return false
    end
    self.aq_exp = 0
    self.aq_xiulian = self.aq_xiulian + 1
    self:on_anqi_level_up()
    return true
end

function equip_data:diaowen_shike(diaowen_id)
    self.diaowen_id = diaowen_id
end

function equip_data:set_diaowen_id(diaowen_id)
    self.diaowen_id = diaowen_id or 0
end

function equip_data:set_diaowen_material_count(count)
    self.diaowen_material_count = count or 0
end

function equip_data:get_diaowen_id()
    return self.diaowen_id
end

function equip_data:get_diaowen_material_count()
    return self.diaowen_material_count
end

function equip_data:set_wh_hecheng_level(level)
    self.wh_hecheng_level = level
end

function equip_data:get_wh_hecheng_level()
    return self.wh_hecheng_level
end

function equip_data:set_wh_level(level)
    self.wh_level = level
end

function equip_data:get_wh_level()
    return self.wh_level
end

function equip_data:set_wh_life(wh_life)
    self.wh_life = wh_life
end

function equip_data:get_wh_life()
    return self.wh_life
end

function equip_data:set_wh_grow_rate(wh_grow_rate)
    self.wh_grow_rate = wh_grow_rate
end

function equip_data:get_wh_grow_rate()
    return self.wh_grow_rate
end

function equip_data:get_wh_grow_rate_level()
    for i, gw in ipairs(define.KFS_GROW_LEVEL) do
        if self.wh_grow_rate >= gw and self.wh_grow_rate < (gw + 50) then
            return i
        end
    end
end

function equip_data:set_wh_skill(i, skill)
    assert(skill)
    self.wh_skill = self.wh_skill or {}
    self.wh_skill[i] = skill
end

function equip_data:get_wh_skill()
    return table.clone(self.wh_skill)
end

function equip_data:set_wh_attr(i, value)
    local name = define.ANQI_ATTR[i]
    local lshift = define.EQUIP_ATTR[name]
    self.attr_types[i] = lshift
    self.attr_values[i] = value
end

function equip_data:set_wh_ex_attr_number(i)
    self.wh_ex_attr_number = i
end

function equip_data:get_wh_ex_attr_number()
    return self.wh_ex_attr_number
end

function equip_data:set_wh_exp(exp)
    self.wh_exp = exp
end

function equip_data:add_wh_exp(exp, max_level)
    max_level = max_level or 1
    self.wh_exp = self.wh_exp or 0
    assert(self.equip_type == 2, self.equip_type)
    local kfs_level_up_exp = configenginer:get_config("kfs_level_up_exp")
    if self.wh_level < max_level then
        self.wh_exp = self.wh_exp + exp
        while self.wh_exp > kfs_level_up_exp[self.wh_level] and self.wh_level < #kfs_level_up_exp do
            self.wh_exp = self.wh_exp - kfs_level_up_exp[self.wh_level]
            self.wh_level = self.wh_level + 1
        end
        return true
    else
        local level_max_exp = kfs_level_up_exp[self.wh_level]
        if level_max_exp == self.wh_exp then
            return false
        end
        self.wh_exp = self.wh_exp + exp
        self.wh_exp = self.wh_exp > level_max_exp and level_max_exp or self.wh_exp
        return true
    end
end

function equip_data:wh_understand_skill(i)
    local skill=require('cy_equipment_skills').wuhun_roll(i,1)
    if not skill then return false end
    self:set_wh_skill(i,skill)
    return true
end

function equip_data:wh_understand_skills()
    local levels = { 40, 70, 90}
    for i = 1, 3 do
        local level = levels[i]
        if self.wh_level >= level then
            self:wh_understand_skill(i)
        end
    end
end

function equip_data:set_wh_ex_attr(i, v)
    self.wh_ex_attr = self.wh_ex_attr or {}
    self.wh_ex_attr[i] = v
end

function equip_data:get_wh_ex_attr()
    return table.clone(self.wh_ex_attr)
end

function equip_data:set_ling_yu_attr_value(values)
    self.ling_yu_attr_values = table.clone(values)
end

function equip_data:get_ling_yu_attr_values()
    return table.clone(self.ling_yu_attr_values)
end

function equip_data:set_ling_yu_attr_types(attrs)
    self.ling_yu_attrs = table.clone(attrs)
end

function equip_data:get_ling_yu_attr_types()
    return table.clone(self.ling_yu_attrs)
end

function equip_data:set_ling_yu_attrs_enhancement_level(levels)
    self.ling_yu_attrs_enhancement_level = table.clone(levels)
end

function equip_data:get_ling_yu_attrs_enhancement_level()
    return table.clone(self.ling_yu_attrs_enhancement_level)
end

function equip_data:set_lingyu_enhancement_levels_new(levels)
    self.lingyu_enhancement_levels_new = table.clone(levels)
end

function equip_data:wash_ling_yu_attrs_enhancement_level(lock_count)
    local lingyu_enhancement_levels_new = {}
    local attr_indexs = {}
    for i = #self.ling_yu_attrs, 1, -1 do
        if self.ling_yu_attrs[i] ~= define.INVAILD_ID then
            table.insert(attr_indexs, i)
        end
    end
    while #attr_indexs > 0
    do
        local i = table.remove(attr_indexs, math.random(1, #attr_indexs))
        if lock_count > 0 then
            table.insert(lingyu_enhancement_levels_new, math.random(50, 80) * 100)
            lock_count = lock_count - 1
        else
            table.insert(lingyu_enhancement_levels_new, math.random(1, 80) * 100)
        end
    end
    self.lingyu_enhancement_levels_new = lingyu_enhancement_levels_new
end

function equip_data:switch_ling_yu_attrs_enhancement_level()
    self.ling_yu_attrs_enhancement_level = self.lingyu_enhancement_levels_new
    self.lingyu_enhancement_levels_new = { 0, 0, 0}
end

function equip_data:set_fwq_change_skill(id)
    self.fwq_change_skill = id
end

function equip_data:get_fwq_change_skill()
    return self.fwq_change_skill or -1
end

function equip_data:set_fwq_passive_skill(id)
    self.fwq_passive_skill = id
end

function equip_data:get_fwq_passive_skill()
    return self.fwq_passive_skill or -1
end

function equip_data:set_fwq_star(star)
    self.fwq_star = star
end

function equip_data:get_fwq_star()
    return self.fwq_star
end

function equip_data:set_fwq_zhuqing(zhuqing)
    self.fwq_zhuqing = zhuqing
end

function equip_data:get_fwq_zhuqing()
    return self.fwq_zhuqing
end

function equip_data:set_fwq_live_time(timer)
    self.fwq_live_time = timer
end

function equip_data:get_fwq_live_time()
    return self.fwq_live_time or 8000
end

function equip_data:set_fwq_attrs(attrs)
    self.fwq_attrs = table.clone(attrs)
end

function equip_data:set_fwq_list_2(list)
    self.fwq_list_2 = list
end

function equip_data:set_fwq_list_2_value(key,value)
    self.fwq_list_2[key] = value
end

function equip_data:set_fwq_skill_list_1(list_1)
    self.fwq_skill_list_1 = list_1
end

function equip_data:set_fwq_skill_list_1_value(key,value)
    self.fwq_skill_list_1[key] = value
end

function equip_data:set_fwq_skill_list_2(list_2)
    self.fwq_skill_list_2 = list_2
end

function equip_data:set_fwq_skill_list_2_value(key,value)
    self.fwq_skill_list_2[key] = value
end

function equip_data:get_fwq_list_2()
    return self.fwq_list_2 or {0,0,0}
end

function equip_data:get_fwq_skill_list_1()
    return self.fwq_skill_list_1 or {}
end

function equip_data:get_fwq_skill_list_2()
    return self.fwq_skill_list_2 or {}
end

function equip_data:get_qihedu()
    return self.qihedu or 0
end

function equip_data:set_qihedu(value)
    self.qihedu = value
	if value then
		local formatted_value = string.format("%03d", value)
		if not self.creator then
			self.creator = "&SQ" .. formatted_value
		else
			local new_creator, count = string.gsub(self.creator, "(&SQ)(%d%d%d)(.*)", function(prefix, _, rest)
				return prefix .. formatted_value .. rest
			end)
			if count == 0 then
				self.creator = self.creator .. "&SQ" .. formatted_value
			else
				self.creator = new_creator
			end
		end
	end
end

function equip_data:get_transfer(item)
    local ostream = iostream.bostream
    local os = ostream.new()
    local equip_type = self.equip_type or 0
    local base_config = item and item:get_base_config()
    if base_config then
        local equip_type_by_point = { [17] = 1, [18] = 2, [39] = 2, [37] = 4 }
        equip_type = equip_type_by_point[base_config.equip_point] or equip_type
    end
    os:writeint(item.item_index)
    os:writeuchar(item.status)
    os:writeuchar(self.dur)
    os:writeushort(self.unknow_9)
    os:writeuchar(self.max_dur)
    os:writeuchar(self.unknow_7 or 0)
    os:writeuchar(self.slot_count)
    os:writeuchar(self.slot_count or 0)
    os:writeuchar(self.enhancement_level)
    os:writeuchar(self.diaowen_id // 8)
    --os:writeuchar(self.enhancement_level)
    --os:writeuchar(self.diaowen_id // 8)
    local dmc = (self.diaowen_material_count or 0) * 8 + (self.diaowen_id or 0) % 8
    if dmc > 32767 then dmc = 32767 elseif dmc < -32768 then dmc = -32768 end
    os:writeshort(dmc)
    os:writeuchar(self.quality)
    os:writeshort(self.visual)
    for i = 1, 6 do
        os:writeuchar(self.qualifications[i])
    end
    local transfer_attr_count = self.attr_count or 0
    if equip_type == 1 then
        transfer_attr_count = 5
    end
    os:writeuchar(transfer_attr_count)
    for i = 1, transfer_attr_count do
        local attr_value = self.attr_values[i] or 0
        if equip_type == 1 and self.aq_attr and self.aq_attr[i] ~= nil then
            attr_value = self.aq_attr[i]
        end
        os:writeushort(attr_value)
    end
    local transfer_attr_type = self.attr_type or 0
    if equip_type == 1 then
        transfer_attr_type = 0
        for i = 1, transfer_attr_count do
            local attr_type = self.attr_types[i] or define.EQUIP_ATTR[define.ANQI_ATTR[i]]
            if attr_type then
                transfer_attr_type = transfer_attr_type | (1 << attr_type)
            end
        end
    end
    os:writeulong(transfer_attr_type)
    for i = 1, 4 do
        os:writeuint(self.list_2[i])
    end
    
    local function write_finedraw_data()
        if (self.diaowen_id or 0) > 0 then
            os:writeuchar(self.dw_advance_level or 0)
            os:writeshort(self.dw_rankexp or 0)
            os:writeuchar(self.dw_featuresid or 0)
        end
    end
    if equip_type == 0 then
        os:writeuchar(0)
        os:writeuchar(0)
        os:writeuchar(0)
        write_finedraw_data()
        local creator = self.creator or string.char(0)
        creator = gbk.fromutf8(creator)
        os:write(creator, string.len(creator))
    elseif equip_type == 1 then
        os:writeuchar(1)
        os:writeuchar(0)
        os:writeuchar(0)
        write_finedraw_data()
        os:writeuchar(self.aq_xiulian)
        os:writeuint(self.aq_exp)
        os:writeushort(self.aq_grow_rate)
        os:writeushort(self.aq_xidian or 0)
        for i = 1, 3 do
            os:writeushort(self.aq_skill[i])
        end
        for i = 1, 5 do
            os:writeushort(self.aq_attr[i])
        end
    elseif equip_type == 2 then
        os:writeuchar(2)
        os:writeuchar(0)
        os:writeuchar(0)
        write_finedraw_data()
        os:writeuint(self.wh_exp)
        os:writeushort(self.wh_life)
        for i = 1, 3 do
            os:writeshort(self.wh_skill[i])
        end
        for i = 1, 10 do
            os:writeuchar(self.wh_ex_attr[i] or 0)
        end
        os:writeuchar(self.unknow_39 or 0)
        os:writeuchar(self.wh_level)
        os:writeuchar(self.wh_hecheng_level)
        os:writeuchar(self.wh_ex_attr_number)
        os:writeushort(self.wh_grow_rate)
    elseif equip_type == 3 then
        os:writeuchar(3)
        os:writeuchar(0)
        os:writeuchar(0)
        write_finedraw_data()
        self.ling_yu_attrs_enhancement_level = self.ling_yu_attrs_enhancement_level or {}
        for i = 1, 3 do
            os:writechar(self.ling_yu_attrs[i] or define.INVAILD_ID)
            os:writeuint(self.ling_yu_attr_values[i] or 0)
            os:writeuint(self.ling_yu_attrs_enhancement_level[i] or 0)
        end
    elseif equip_type == 4 then
        os:writeuchar(4)
        os:writeuchar(0)
        os:writeuchar(0)
        write_finedraw_data()
        os:writeuchar(self.fwq_star)
        os:writeuchar(self.fwq_zhuqing)
        for i = 1, 6 do
            os:writechar(self.fwq_attrs[i])
        end
        for i = 1, 3 do
            os:writechar(self.fwq_list_2[i])
        end
        -- os:write("", 3)
        for i = 1, 2 do
            os:writeshort(self.fwq_skill_list_1[i])
        end
        for i = 1, 3 do
            os:writeshort(self.fwq_skill_list_2[i])
        end
    end
    local s = os:get()
    s = string.gsub(s, string.char(0x5C), string.char(0x5C) .. string.char(0x5C))
    s = string.gsub(s, string.char(0), "\\0")
    return s
end

function equip_data:get_stream(os)
    for i = 1, 2 do
        os:writeuchar(0)
    end
    local equip_type = self.equip_type or 0
    if equip_type == 0 then
        local creator = self.creator or ""
        creator = gbk.fromutf8(creator)
        os:write(creator or "", 46)
        for i = 1, 26 do
            os:writeuchar(0)
        end
        os:writeuchar(self.dur)
        os:writeuchar(self.slot_count or 0)
        os:writeuchar(0)
        os:writeuchar(self.max_dur)
        for i = 1, 2 do
            os:writeuchar(0)
        end
        os:writeuchar(self.attr_count)
        --os:writeuchar(self.gem_count)
        os:writeuchar(self.slot_count)
        os:writeuchar(self.enhancement_level)
        os:writeuchar(self.diaowen_id // 8)
        local dmc = (self.diaowen_material_count or 0) * 8 + (self.diaowen_id or 0) % 8
        if dmc > 32767 then dmc = 32767 elseif dmc < -32768 then dmc = -32768 end
        os:writeshort(dmc)
        for i = 1, 6 do
            os:writeuchar(self.qualifications[i])
        end
        os:writeuchar(self.quality)
        os:writeuchar(0)
        os:writeshort(self.visual)
        os:writeuchar(0x50)
        os:writeuchar(0)
        os:writeulong(self.attr_type)
        for i = 1, 4 do
            os:writeuint(self.list_2[i] or 0)
        end
        for i = 1, 2 do
            os:writeuchar(0)
        end
        for i = 1, 7 do
            os:writeushort(self.attr_values[i] or 0)
        end
        os:write("", 28)
		
		for i = 1, 2 do
            os:writeuint(0)
        end
    elseif equip_type == 1 then
        os:writeuint(self.aq_exp)
        for i = 1, 3 do
            os:writeushort(self.aq_skill[i])
        end
        for i = 1, 5 do
            os:writeushort(self.aq_attr[i])
        end
        os:writeushort(self.aq_xidian)
        os:writeushort(self.aq_grow_rate)
        os:writeuchar(self.aq_xiulian)
        for i = 1, 47 do
            os:writeuchar(0)
        end
        os:writeuchar(self.max_dur or 0xc8)
        os:writeuchar(self.slot_count)
        os:writeuchar(0)
        os:writeuchar(0xc6)
        os:writeuchar(0xc7)
        os:writeuchar(0)
        os:writeuchar(self.attr_count)
        os:writeuchar(0)
        os:writeuchar(self.enhancement_level)
        os:writeuchar(self.diaowen_id // 8)
        local dmc = (self.diaowen_material_count or 0) * 8 + (self.diaowen_id or 0) % 8
        if dmc > 32767 then dmc = 32767 elseif dmc < -32768 then dmc = -32768 end
        os:writeshort(dmc)
        for i = 1, 6 do os:writeuchar(self.qualifications[i]) end
        os:writeuchar(self.quality)
        os:writeuchar(0)
        os:writeshort(self.visual)
        os:writeuchar(0x13)
        os:writeuchar(0)
        os:writeulong(self.attr_type)
        for i = 1, 4 do
            os:writeuint(self.list_2[i])
        end
        os:writeuchar(equip_type)
        os:writeuchar(0)
        for i = 1, 5 do
            os:writeushort(self.attr_values[i])
        end
        for i = 1, 32 do
            os:writeuchar(0)
        end
		for i = 1, 2 do
            os:writeuint(0)
        end
    elseif equip_type == 2 then
        os:writeuint(self.wh_exp)
        os:writeushort(self.wh_life)
        for i = 1, 3 do
            os:writeshort(self.wh_skill[i])
        end
        for i = 1, 10 do
            os:writeuchar(self.wh_ex_attr[i] or 0)
        end
        os:writeuchar(0)
        os:writeuchar(self.wh_level)
        os:writeuchar(self.wh_hecheng_level)
        os:writeuchar(self.wh_ex_attr_number)
        os:writeushort(self.wh_grow_rate)
        for i = 1, 44 do
            os:writeuchar(0)
        end
        os:writeuchar(self.max_dur)
        os:writeuchar(self.slot_count)
        os:writeuchar(self.unknow_7 or 0)
        os:writeuchar(self.dur)
        os:writeuchar(0x21)
        os:writeuchar(0)
        os:writeuchar(self.attr_count)
        --os:writeuchar(self.gem_count)
        os:writeuchar(self.slot_count)
        for i = 1, 10 do
            os:writeuchar(0)
        end
        os:writeuchar(self.quality)
        os:writeuchar(0)
        os:writeshort(self.visual)
        for i = 1, 10 do
            os:writeuchar(0)
        end
        for i = 1, 4 do
            os:writeuint(self.list_2[i])
        end
        os:writeuchar(equip_type)
        for i = 1, 43 do
            os:writeuchar(0)
        end
		for i = 1, 2 do
            os:writeuint(0)
        end
    elseif equip_type == 3 then
        for i = 1, 3 do
            os:writeint(self.ling_yu_attrs[i] or 0)
            os:writeuint(self.ling_yu_attr_values[i] or 0)
            self.ling_yu_attrs_enhancement_level = self.ling_yu_attrs_enhancement_level or {}
            os:writeuint(self.ling_yu_attrs_enhancement_level[i] or 0)
        end
        os:write("", 36)
        os:writeushort(100)
        os:writeuchar(0)
        os:writeuint(100)
        os:write("", 11)
        os:writeushort(1)
        os:writeshort(-1)
        os:write("", 26)
        os:writeuchar(equip_type)
        os:write("", 43)
		for i = 1, 2 do
            os:writeuint(0)
        end
    elseif equip_type == 4 then
        os:writeuchar(self.fwq_star)
        os:writeuchar(self.fwq_zhuqing)
        for i = 1, 6 do
            os:writechar(self.fwq_attrs[i])
        end
        os:writeuchar(0)
        for i = 1, 3 do
            os:writechar(self.fwq_list_2[i])
        end
        -- os:write("", 3)
        for i = 1, 2 do
            os:writeshort(self.fwq_skill_list_1[i])
        end
        for i = 1, 3 do
            os:writeshort(self.fwq_skill_list_2[i])
        end
        os:write("", 50)
        os:writeuchar(self.dur)
        os:writeuchar(self.slot_count or 0)
        os:writeuchar(0)
        os:writeuchar(self.max_dur)
        for i = 1, 2 do
            os:writeuchar(0)
        end
        os:writeuchar(self.attr_count)
        --os:writeuchar(self.gem_count)
        os:writeuchar(self.slot_count)
        os:writeuchar(self.enhancement_level)
        os:writeuchar(self.diaowen_id // 8)
        local dmc = (self.diaowen_material_count or 0) * 8 + (self.diaowen_id or 0) % 8
        if dmc > 32767 then dmc = 32767 elseif dmc < -32768 then dmc = -32768 end
        os:writeshort(dmc)
        for i = 1, 6 do
            os:writeuchar(self.qualifications[i])
        end
        os:writeuchar(self.quality)
        os:writeuchar(0)
        os:writeshort(self.visual)
        os:writeuchar(0x12)
        os:writeuchar(0)
        os:writeulong(self.attr_type)
        for i = 1, 4 do
            os:writeuint(self.list_2[i] or 0)
        end
        os:writeuchar(self.equip_type)
        os:write("", 43)
		for i = 1, 2 do
            os:writeuint(0)
        end
    end
end

function equip_data:init_from_data(data)
    self:set_attr_count(data.attr_count)
    self:set_attr_value(data.attr_values)
    self:set_attr_type(data.attr_type)
    self:set_quality(data.quality)
    self:set_dur(data.dur)
    self:set_damage_point(data.damage_point)
    self:set_repaire_fail_times(data.unknow_7)
    self:set_max_dur(data.max_dur)
    self:set_visual(data.visual)
	self:set_action(data.action)
    self:set_qualifications(data.qualifications)
    self:set_equip_type(data.equip_type)
    self:set_attr_types(data.attr_types)
    self:set_slot_count(data.slot_count)
    self:set_gem_list(data.list_2)
    self:set_gem_count(data.gem_count)
    self:set_creator(data.creator)
    self:set_aq_xiulian(data.aq_xiulian)
    self:set_aq_exp(data.aq_exp)
    self:set_aq_grow_rate(data.aq_grow_rate)
    self:set_aq_xi_dian(data.aq_xidian)
    self:set_enhancement_level(data.enhancement_level)
    self:set_reshuffle_count(data.reshuffle_count or 0)
    self:set_diaowen_id(data.diaowen_id)
	self:set_dw_jinjie_details(data.dw_advance_level or 0,data.dw_rankexp or 0,data.dw_featuresid or 0)
    self:set_diaowen_material_count(data.diaowen_material_count)
    self:set_wh_hecheng_level(data.wh_hecheng_level)
    self:set_wh_level(data.wh_level)
    self:set_wh_life(data.wh_life)
    self:set_wh_grow_rate(data.wh_grow_rate)
    self:set_wh_ex_attr_number(data.wh_ex_attr_number)
    self:set_wh_exp(data.wh_exp)
    self:set_ling_yu_attr_value(data.ling_yu_attr_values)
    self:set_ling_yu_attr_types(data.ling_yu_attrs)
    self:set_ling_yu_attrs_enhancement_level(data.ling_yu_attrs_enhancement_level)
    self:set_lingyu_enhancement_levels_new(data.lingyu_enhancement_levels_new)
    self:set_fwq_star(data.fwq_star)
    self:set_fwq_zhuqing(data.fwq_zhuqing)
    self:set_fwq_attrs(data.fwq_attrs)
	self:set_fwq_change_skill(data.fwq_change_skill)
	self:set_fwq_passive_skill(data.fwq_passive_skill)
	self:set_fwq_live_time(data.fwq_live_time)
	self:set_fwq_list_2(data.fwq_list_2)
    self:set_fwq_skill_list_1(data.fwq_skill_list_1)
    self:set_fwq_skill_list_2(data.fwq_skill_list_2)
	self.qihedu = data.qihedu
    if data.aq_skill then
        for i = 1, 3 do
            self:set_aq_skill(i, data.aq_skill[i])
        end
    end
    if data.aq_attr then
        for i = 1, 5 do
            self:set_aq_attr(i, data.aq_attr[i])
        end
    end
    if data.wh_skill then
        for i = 1, 3 do
            self:set_wh_skill(i, data.wh_skill[i])
        end
    end
    if data.wh_ex_attr then
        for i = 1, 10 do
            self:set_wh_ex_attr(i, data.wh_ex_attr[i])
        end
    end
end

function equip_data:copy_raw_data()
    local data = table.clone(self)
    data.lay_count = 1
    if data.attr_count > 0 then
        data.attr_type = 0
        table.sort(data.attr_types, function(a1, a2) return a1 < a2 end)
        for i = 1, self.attr_count do
            local ia = 1 <<  data.attr_types[i]
            data.attr_type = data.attr_type | ia
        end
    end
    return data
end

local material_data = class("material_data")
function material_data:ctor()
    self.unknow_19 = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
end

function material_data:copy_raw_data()
    local data = table.clone(self)
    data.lay_count = self:get_lay_count()
    return data
end

function material_data:set_lay_count(count)
    self.unknow_19[1] = count
end

function material_data:get_lay_count()
    return self.unknow_19[1]
end

function material_data:get_stream(os)
    for i = 1,74 do
        os:writeuchar(0)
    end
    os:writeuchar(self:get_lay_count())
    for i = 1, 91 do
        os:writeuchar(0)
    end
	for i = 1, 2 do
        os:writeuint(0)
    end
end

local store_map_data = class("store_map_data")
function store_map_data:ctor()
    self.unknow_20 = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
end

function store_map_data:copy_raw_data()
    local data = table.clone(self)
    data.lay_count = self:get_lay_count()
    return data
end

function store_map_data:get_transfer()
    return "\\0"
end

function store_map_data:get_stream(os, item)
    for i = 1, 62 do
        os:writeuchar(0)
    end
    for i = 1, 12 do
        os:writeuchar(item.unknow_4[i])
    end
    os:writeuchar(self:get_lay_count())
    for i = 1, 91 do
        os:writeuchar(0)
    end
	for i = 1, 2 do
        os:writeuint(0)
    end
end


function store_map_data:set_lay_count(count)
    self.unknow_20[1] = count
end

function store_map_data:get_lay_count()
    return self.unknow_20[1]
end

local gem_data = class("gem_data")
function gem_data:ctor()
    self.unknow_22 = { 44, 0, 37, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 248, 36, 1, 0, 1, 0, 0, 0, 5, 0, 0, 0, 250, 0, 0, 0 }
end

function gem_data:copy_raw_data()
    local data = table.clone(self)
    data.lay_count = self:get_lay_count()
    return data
end

function gem_data:get_transfer()
    return "\\0"
end

function gem_data:get_stream(os)
    for i = 1, 122 do
        os:writeuchar(0)
    end
    os:writeuchar(self:get_lay_count())
    for i = 1, 43 do
        os:writeuchar(0)
    end
	for i = 1, 2 do
        os:writeuint(0)
    end
end

function gem_data:set_lay_count(count)
    self.unknow_22[49] = count
end

function gem_data:get_lay_count()
    return self.unknow_22[49]
end

local pet_equip_data = class("pet_equip_data")
function pet_equip_data:ctor()
    self.pet_equip_unknow_8 = 300
    self.pet_equip_unknow_1 = 0
    self.pet_equip_unknow_2 = 0
    self.pet_equip_unknow_3 = 0
    self.pet_equip_unknow_4 = { 4, 0, 0, 0 }
    self.pet_equip_unknow_6 = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }
    self.unknow_24 = 0
    self.unknow_25 = 0
    self.unknow_26 = 0
    self.unknow_28 = 0
    self.pet_equip_type = 0
    self.unknow_29 = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}

    self.pet_soul_attr = {}
    self.attr_count = 0
    self.attr_values = {}
    self.attr_types = {}
    self.attr_type = 0
    self.quality = 0
    self.dur = 0
    self.max_dur = 0
    self.visual = 0
    self.qualifications = {0, 0, 0, 0, 0, 0}
end

function pet_equip_data:get_transfer(item)
    local ostream = iostream.bostream
    local os = ostream.new()
    os:writeint(item.item_index)
    os:writeuchar(self.pet_equip_type)
    for i = 1, 6 do
        os:writeuchar(0)
    end
    os:writeuchar(1)
    if self.pet_equip_type == 0 then
        for i = 1, 2 do
            os:writeuchar(0)
        end
        for i = 1, 6 do
            os:writeuchar(self.qualifications[i])
        end
        os:writeushort(self.attr_count)
        for i = 1, self.attr_count do
            os:writeushort(self.attr_values[i])
        end
        os:writeulong(self.attr_type)
        for i = 1, 16 do
            os:writeuchar(0)
        end
    else
        for i = 1, 9 do
            os:writeuchar(0)
        end
        os:writeuchar(1)
        for i = 1, 24 do
            os:writeuchar(0)
        end
        os:writeushort(self.level or 0)
        os:writeushort(self.pet_equip_unknow_8)
        os:writeushort(self.pet_soul_exp or 0)
        os:writeuchar(self.pet_soul_level or 0)
        for i = 1, 6 do
            local pet_soul = self.pet_soul_attr[i] or { type = define.INVAILD_ID, value = 0}
            os:writechar(pet_soul.type)
            os:writeuint(pet_soul.value)
        end
    end
    local s = os:get()
    s = string.gsub(s, string.char(0x5C), string.char(0x5C) .. string.char(0x5C))
    s = string.gsub(s, string.char(0), "\\0")
    return s
end

function pet_equip_data:get_stream(os, item)
    if self.pet_equip_type == 0 then
        for i = 1, 75 do
            os:writeuchar(0)
        end
        os:writeushort(self.attr_count)
        for i = 1, 5 do
            os:writeuchar(0)
        end
        for i = 1, 6 do
            os:writeuchar(self.qualifications[i])
        end
        os:writeuchar(1)
        for i = 1, 21 do
            os:writeuchar(0)
        end
        os:writeulong(self.attr_type)
        os:writeushort(0)
        for i = 1, 6 do
            os:writeushort(self.attr_values[i] or 0)
        end
        for i = 1, 34 do
            os:writeuchar(0)
        end
    elseif self.pet_equip_type == define.PET_EQUIP_TYPE.ELF then
        -- ELF兽灵: unknow_4[3]=鉴定, [4]=品阶, [5~9]=属性key, [11~12]=skill_id
        local unknow_4 = item and item.unknow_4 or {}
        for i = 1, 12 do
            os:writeuchar(unknow_4[i] or 0)
        end
        for i = 1, 154 do
            os:writeuchar(0)
        end
    else
        for i = 1, 2 do
            os:writeuchar(0)
        end
        os:writeushort(self.level)
        os:writeuint(self.pet_equip_unknow_8)
        os:writeshort(self.pet_soul_exp)
        os:writeuint(self.pet_soul_level)
        for i = 1, 6 do
            local pet_soul = self.pet_soul_attr[i] or { type = define.INVAILD_ID, value = 0 }
            os:writeint(pet_soul.type)
            os:writeint(pet_soul.value)
        end
        for i = 1, 26 do
            os:writeuchar(0)
        end
        os:writeuchar(1)
        for i = 1, 29 do
            os:writeuchar(0)
        end
        os:writeuchar(1)
        for i = 1, 47 do
            os:writeuchar(0)
        end
    end
	for i = 1, 2 do
		os:writeuint(0)
    end
end

function pet_equip_data:parse_soul_attr_lock(lock_value)
    local values = { string.match(tostring(lock_value), "(%d?)(%d?)(%d?)(%d?)(%d?)(%d?)") }
    for i, v in ipairs(values) do
        values[i] = tonumber(v)
    end
    for i = #values + 1, 6 do
        table.insert(values, 1, 0)
    end
    return values
end

function pet_equip_data:gen_soul_attr(lock_value, lock_color_count)
    return require('cys_soul_reforge').generate(self:get_pet_soul_quanlity(),self.pet_soul_attr,
        lock_value,lock_color_count,define.PET_SOUL_ATTRS,configenginer:get_config('pet_soul_extension'))
end

function pet_equip_data:set_attr_count(count)
    self.attr_count = count
end

function pet_equip_data:set_attr_value(value)
    if value then
        self.attr_values = table.clone(value)
    end
end

function pet_equip_data:set_attr_type(type)
    self.attr_type = type
end

function pet_equip_data:set_attr_types(ats)
    self.attr_types = ats
end

function pet_equip_data:set_quality(quality)
    self.quality = quality
end

function pet_equip_data:get_quality()
    return self.quality
end

function pet_equip_data:set_dur(dur)
    self.dur = dur
end

function pet_equip_data:set_max_dur(max_dur)
    self.max_dur = max_dur
end

function pet_equip_data:set_qualifications(qualifications)
    if qualifications then
        self.qualifications = table.clone(qualifications)
    end
end

function pet_equip_data:set_level(level)
    self.level = level
end

function pet_equip_data:get_level()
    return self.level
end

function pet_equip_data:set_pet_soul_quanlity(quanlity)
    self.pet_soul_quanlity = quanlity
end

function pet_equip_data:get_pet_soul_quanlity()
    return self.pet_soul_quanlity
end

function pet_equip_data:set_pet_soul_attr(pet_soul_attr)
    if pet_soul_attr then
        self.pet_soul_attr = table.clone(pet_soul_attr)
    end
end

function pet_equip_data:get_pet_soul_attr()
    return table.clone(self.pet_soul_attr)
end

function pet_equip_data:set_pet_soul_level(pet_soul_level)
    self.pet_soul_level = pet_soul_level
end

function pet_equip_data:get_pet_soul_level()
    return self.pet_soul_level
end

function pet_equip_data:set_pet_soul_exp(pet_soul_exp)
    self.pet_soul_exp = pet_soul_exp
end

function pet_equip_data:get_pet_soul_exp()
    return self.pet_soul_exp
end

function pet_equip_data:set_pet_equip_type(type)
    self.pet_equip_type = type
end

function pet_equip_data:get_pet_equip_type()
    return self.pet_equip_type
end

function pet_equip_data:add_exp(pet_soul_base, add_exp)
    self.pet_soul_exp = self.pet_soul_exp + add_exp
    while self.pet_soul_exp >= pet_soul_base.exps[self.pet_soul_level + 1] do
        self.pet_soul_exp = self.pet_soul_exp - pet_soul_base.exps[self.pet_soul_level + 1]
        self.pet_soul_level = self.pet_soul_level + 1
    end
end

function pet_equip_data:is_judge_aptd()
    local is_jduge_aptd = false
    for i = 1, 6 do
        if self.qualifications[i] ~= 0 then
            is_jduge_aptd = true
        end
    end
    return is_jduge_aptd
end

function pet_equip_data:judge_apt()
    for i = 1, 6 do
        self.qualifications[i] = math.random(1, 255)
    end
end

function pet_equip_data:copy_raw_data()
    local data = table.clone(self)
    return data
end

function pet_equip_data:init_from_data(data)
    -- HJ05: 0 is valid exhausted life; absent legacy fields keep 300.
    local life = tonumber(data.pet_equip_unknow_8)
    if life and life == life and life >= 0 and life <= 65535 then
        self.pet_equip_unknow_8 = math.floor(life)
    end
    self:set_pet_equip_type(data.pet_equip_type)
    self:set_level(data.level)
    self:set_attr_count(data.attr_count)
    self:set_attr_value(data.attr_values)
    self:set_attr_type(data.attr_type)
    self:set_quality(data.quality)
    self:set_dur(data.dur)
    self:set_max_dur(data.max_dur)
    self:set_qualifications(data.qualifications)
    self:set_attr_types(data.attr_types)
    self:set_pet_soul_attr(data.pet_soul_attr)
    self:set_pet_soul_level(data.pet_soul_level)
    self:set_pet_soul_exp(data.pet_soul_exp)
    self:set_pet_soul_quanlity(data.pet_soul_quanlity)
end

local task_data = class("task_data")
function task_data:ctor()
    self.unknow_21 = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
end

function task_data:copy_raw_data()
    local data = table.clone(self)
    data.lay_count = self:get_lay_count()
    return data
end

function task_data:get_transfer()
    return "\\0"
end

function task_data:get_stream(os)
    for i = 1, 74 do
        os:writeuchar(0)
    end
    os:writeuchar(self:get_lay_count())
    for i = 1, 91 do
        os:writeuchar(0)
    end
	for i = 1, 2 do
        os:writeuint(0)
    end
end


function task_data:set_lay_count(count)
    self.unknow_21[1] = count
end

function task_data:get_lay_count()
    return self.unknow_21[1]
end

local item = class("item")
function item:ctor()
    self.guid = guid_cls.new()
    self.item_index = -1
    self.rule = 0
    self.status = 0
    self.unknow_4 = { 
	0, 0, 0, 0, 0,
	0, 0, 0, 0, 0,
	0, 0}
    self.unknow_44 = 0
    self.unknow_45 = 0
	self.record_data = {}
    self.equip_data = equip_data.new()
    self.store_map_data = store_map_data.new()
    self.material_data = material_data.new()
    self.gem_data = gem_data.new()
    self.pet_equip_data = pet_equip_data.new()
    self.task_data = task_data.new()
end

function item:get_equip_data()
    return self.equip_data
end

function item:get_material_data()
    return self.material_data
end

function item:get_store_map_data()
    return self.store_map_data
end

function item:get_gem_data()
    return self.gem_data
end

function item:get_pet_equip_data()
    return self.pet_equip_data
end

function item:get_task_data()
    return self.task_data
end

function item:get_index()
    return self.item_index
end

function item:set_index(index)
    assert(index)
    self.item_index = index
end

function item:is_bind()
    return self.status & define.ITEM_EXT_INFO.IEI_BIND_INFO == define.ITEM_EXT_INFO.IEI_BIND_INFO
end

function item:set_is_bind(bind)
    if bind and bind ~= 0 then
        self.status = self.status | define.ITEM_EXT_INFO.IEI_BIND_INFO
    else
        self.status = self.status & ~define.ITEM_EXT_INFO.IEI_BIND_INFO
    end
end

function item:is_lock()
    return self.status & define.ITEM_EXT_INFO.IEI_PLOCK_INFO == define.ITEM_EXT_INFO.IEI_PLOCK_INFO
end

function item:set_lock(lock)
    if lock then
        self.status = self.status | define.ITEM_EXT_INFO.IEI_PLOCK_INFO
    else
        self.status = self.status & ~define.ITEM_EXT_INFO.IEI_PLOCK_INFO
    end
end

function item:set_in_exchange()

end

function item:is_identd()
    return self.status & define.ITEM_EXT_INFO.IEI_IDEN_INFO == define.ITEM_EXT_INFO.IEI_IDEN_INFO
end

function item:set_identd()
    self.status = self.status | define.ITEM_EXT_INFO.IEI_IDEN_INFO
end

function item:is_qidentd()
    return self.status & define.ITEM_EXT_INFO.IEI_QIDEN_INFO == define.ITEM_EXT_INFO.IEI_QIDEN_INFO
end

function item:set_qidentd(equipid)
	assert(equipid and equipid // 10000000 == define.ITEM_CLASS.ICLASS_EQUIP,equipid)
    self.status = self.status | define.ITEM_EXT_INFO.IEI_QIDEN_INFO
    self:get_equip_data():judge_apt(equipid)
end

function item:set_pet_equip_qidentd()
    self.status = self.status | define.ITEM_EXT_INFO.IEI_QIDEN_INFO
    self:get_pet_equip_data():judge_apt()
end

function item:have_creator()
    return self.status & define.ITEM_EXT_INFO.IEL_CREATOR == define.ITEM_EXT_INFO.IEL_CREATOR
end

function item:set_creator(creator)
    if creator then
        self.status = self.status | define.ITEM_EXT_INFO.IEL_CREATOR
        local ed = self:get_equip_data()
        ed:set_creator(creator)
    end
end

function item:get_serial_class()
    return math.floor(self.item_index / 10000000)
end

function item:get_serial_type()
    return math.floor((self.item_index % 100000) / 1000)
end

function item:get_serial_quality()
    return math.floor((self.item_index % 10000000) / 100000)
end

function item:set_index(index)
    self.item_index = index
end

function item:set_guid(guid)
    self.guid:set_guid(guid)
end

function item:get_guid()
    return self.guid
end

function item:set_rule(rule)
    self.rule = rule
end

function item:set_status(status)
    self.status = status
end

function item:set_lay_count(count)
    if self:get_serial_class() == define.ITEM_CLASS.ICLASS_GEM then
        self.gem_data:set_lay_count(count)
    elseif self:get_serial_class() == define.ITEM_CLASS.ICLASS_STOREMAP then
        self.store_map_data:set_lay_count(count)
    elseif self:get_serial_class() == define.ITEM_CLASS.ICLASS_MATERIAL then
        self.material_data:set_lay_count(count)
    elseif self:get_serial_class() == define.ITEM_CLASS.ICLASS_TASK then
        self.task_data:set_lay_count(count)
    end
    self:set_count(count)
end

function item:get_lay_count()
    if self:get_serial_class() == define.ITEM_CLASS.ICLASS_GEM then
        return self.gem_data:get_lay_count()
    elseif self:get_serial_class() == define.ITEM_CLASS.ICLASS_STOREMAP then
        return self.store_map_data:get_lay_count()
    elseif self:get_serial_class() == define.ITEM_CLASS.ICLASS_MATERIAL then
        return self.material_data:get_lay_count()
    elseif self:get_serial_class() == define.ITEM_CLASS.ICLASS_TASK then
        return self.task_data:get_lay_count()
    end
    return 1
end

function item:is_cos_self()
    local common_item = configenginer:get_config("common_item")
    local config = common_item[self:get_index()]
    return config.is_cost_self
end

function item:get_param(pos, vtype)
    local values = {}
    for i = 1, 0xc do
        table.insert(values, string.char(self.unknow_4[i]))
    end
    local buffer = table.concat(values)
    local istream = iostream.bistream
    local is = istream.new()
    is:attach(buffer)
    is:skip(pos)
    vtype = vtype or "int"
    local fn = "read" .. vtype
    local f = is[fn]
    assert(f, fn)
    return f(is)
end

function item:set_param(i, v, vtype)
    print("item:set_param(i, v, vtype)", i, v, vtype)
    v = math.ceil(v)
    local ostream = iostream.bostream
    local os = ostream.new()
    vtype = vtype or "int"
    local fn = "write" .. vtype
    local f = os[fn]
    assert(f, fn)
    f(os, v)
    local buffer = os:get()
    local istream = iostream.bistream
    local is = istream.new()
    is:attach(buffer)
    for pos = 1, string.len(buffer) do
        self.unknow_4[i + pos] = is:readuchar()
    end
end

function item:set_count(count)
    self.count = count
end

function item:set_unknow_4(data)
    if data then
        self.unknow_4 = table.clone(data)
    end
end

function item:can_lay()
    return item_rule_checker:check_type_ruler(define.ITEM_RULER_LIST.IRL_TILE, self.item_index)
end

function item:is_ruler(ruler)
    return item_rule_checker:check_type_ruler(ruler, self.item_index)
end

function item:can_discard()
    return self:is_ruler(define.ITEM_RULER_LIST.IRL_DISCARD)
end

function item:can_sell()
    return self:is_ruler(define.ITEM_RULER_LIST.IRL_CANSELL)
end

function item:can_exchange()
    return self:is_ruler(define.ITEM_RULER_LIST.IRL_CANEXCHANGE)
end

function item:inc_lay_count(add)
    add = add or 1
    assert(add > 0)
    local count = self:get_lay_count()
    count = count + add
    self:set_lay_count(count)
    return true
end

function item:dec_lay_count(dec)
    local count = self:get_lay_count()
    if count < dec then
        return false
	elseif dec < 1 then
		return false
    end
    count = count - dec
    self:set_lay_count(count)
    return true
end

function item:get_level()
    if self:get_serial_class() == define.ITEM_CLASS.ICLASS_EQUIP then
        local equip_base = configenginer:get_config("equip_base")
        local equip = equip_base[self.item_index]
        return equip.level
    end
end

function item:get_max_gem_slot()
    if self:get_serial_class() == define.ITEM_CLASS.ICLASS_EQUIP then
        local equip_base = configenginer:get_config("equip_base")
        local equip = equip_base[self.item_index]
        return equip.max_gem_slot
    end
end

function item:get_item_point()
    if self:get_serial_class() == define.ITEM_CLASS.ICLASS_EQUIP then
        local equip_base = configenginer:get_config("equip_base")
        local equip = equip_base[self.item_index]
		if equip then
			return equip.equip_point
		end
    end
end


function item:get_max_tile_count()
    local common_item = configenginer:get_config("common_item")
    local max_tile_count = 1
    local cls = self:get_serial_class()
    if cls == define.ITEM_CLASS.ICLASS_GEM then
        max_tile_count = 250
    elseif cls == define.ITEM_CLASS.ICLASS_EQUIP then
        max_tile_count = 1
	elseif cls == define.ITEM_CLASS.ICLASS_PET_EQUIP then
        max_tile_count = 1
    else
        local conf = common_item[self.item_index]
        if conf then
            max_tile_count = conf.max_tile_count
        end
    end
    -- CYS-ROUND2 23/09 Preserve single-instance gear and non-stackable special items.
    if max_tile_count > 1 and self:can_lay() then return 250 end
    return max_tile_count
end

function item:is_full()
    local max_tile_count = self:get_max_tile_count()
    local count = self:get_lay_count()
    -- print("is_full count =", count, ";max_tile_count =", max_tile_count)
    return count >= max_tile_count
end

function item:is_empty()
    local count = self:get_lay_count()
    return count == 0
end

function item:is_pet_equip()
    return self:get_serial_class() == define.ITEM_CLASS.ICLASS_PET_EQUIP
end

function item:is_gem()
    return self:get_serial_class() == define.ITEM_CLASS.ICLASS_GEM
end

function item:is_quest()
    return self:get_serial_class() == define.ITEM_CLASS.ICLASS_TASK
end

function item:is_material()
    return self:get_serial_class() == define.ITEM_CLASS.ICLASS_MATERIAL
end

function item:is_base()
    return self:get_serial_class() == define.ITEM_CLASS.ICLASS_STOREMAP
end

function item:is_equip()
    return self:get_serial_class() == define.ITEM_CLASS.ICLASS_EQUIP
end

function item:set_item_creator(name)
    if name then
        if self:is_equip() then
            self:get_equip_data():set_creator(name)
        else
            self.creator = name
        end
        self.unknow_47 = 0
        self.status = self.status | define.ITEM_EXT_INFO.IEL_CREATOR
    end
end

function item:set_item_record_data(record_data)
	self.record_data = record_data or {}
end

function item:get_item_record_data()
	return self.record_data
end

function item:get_item_record_data_forindex(index)
	local i = tostring(index)
	return self.record_data[i]
end

function item:set_item_record_data_forindex(index,value)
	local i = tostring(index)
	self.record_data[i] = value
end


function item:get_item_creator()
    if self:is_equip() then
        return self:get_equip_data():get_creator()
    else
        return self.creator
    end
end

function item:set_is_identd(is)
    if is then
        self.status = self.status | define.ITEM_EXT_INFO.IEI_IDEN_INFO
    else
        self.status = self.status & ~define.ITEM_EXT_INFO.IEI_IDEN_INFO
    end
end

function item:set_is_ebind(is)
    if is then
        self.status = self.status | define.ITEM_EXT_INFO.IEI_EBIND_INFO
    else
        self.status = self.status & ~define.ITEM_EXT_INFO.IEI_EBIND_INFO
    end
end

function item:is_ebind()
    return self.status & define.ITEM_EXT_INFO.IEI_EBIND_INFO == define.ITEM_EXT_INFO.IEI_EBIND_INFO
end

function item:get_type()
    return define.ITEM_DATA_TYPE.IDT_ITEM
end

function item:get_place_bag()
    local cls = self:get_serial_class()
    if cls == 1 or cls == 3 or cls == 7 then
        return "prop"
    elseif cls == 4 then
        return "task"
    else
        return "material"
    end
end

function item:init_from_data(data)
    self.guid:set_guid(data.guid)
    self:set_index(data.item_index)
    self:set_rule(data.rule)
    self:set_status(data.status)
    self:set_count(data.count or 1)
    self:set_lay_count(data.lay_count or 1)
    self:set_unknow_4(data.unknow_4)
    self:set_item_creator(data.creator)
	self:set_item_record_data(data.record_data)
    if self:get_serial_class() == define.ITEM_CLASS.ICLASS_EQUIP then
        local equip = self:get_equip_data()
        equip:init_from_data(data)
    elseif self:get_serial_class() == define.ITEM_CLASS.ICLASS_PET_EQUIP then
        local equip = self:get_pet_equip_data()
        equip:init_from_data(data)
    end
end

function item:copy_raw_data()
    local data = self:get_equip_data():copy_raw_data()
    if self:get_serial_class() == define.ITEM_CLASS.ICLASS_STOREMAP then
        data = self:get_store_map_data():copy_raw_data()
    elseif self:get_serial_class() == define.ITEM_CLASS.ICLASS_GEM then
        data = self:get_gem_data():copy_raw_data()
    elseif self:get_serial_class() == define.ITEM_CLASS.ICLASS_MATERIAL then
        data = self:get_material_data():copy_raw_data()
    elseif self:get_serial_class() == define.ITEM_CLASS.ICLASS_PET_EQUIP then
        data = self:get_pet_equip_data():copy_raw_data()
    elseif self:get_serial_class() == define.ITEM_CLASS.ICLASS_TASK then
        data = self:get_task_data():copy_raw_data()
    end
    data.guid = table.clone(self.guid)
    data.item_index = self.item_index
    data.rule = self.rule
    data.status = self.status
    -- ELF道具: 确保status有IEL_CREATOR位, 使GCItemInfo bos写入a1+16的32字节ELF metadata
    if self:get_serial_class() == define.ITEM_CLASS.ICLASS_PET_EQUIP then
        local ped = self:get_pet_equip_data()
        if ped and ped.pet_equip_type == define.PET_EQUIP_TYPE.ELF then
            data.status = data.status | define.ITEM_EXT_INFO.IEL_CREATOR
        end
    end
    data.count = data.lay_count or self.count
    data.unknow_44 = self.unknow_44
    data.unknow_45 = self.unknow_45
    data.unknow_4 = self.unknow_4
    data.price = self.price
    data.quality = data.quality or 0
    data.creator = data.creator or self.creator
	data.record_data = self.record_data
    return data
end

function item:copy_del_item_data()
	local data = {}
    data.guid = table.clone(self.guid)
    data.item_index = self.item_index
	return data
end

function item:get_gem_attrs()
    assert(self:get_serial_class() == define.ITEM_CLASS.ICLASS_EQUIP)
    return self:get_equip_data():get_gem_attrs()
end

function item:get_transfer()
    print("item:get_transfer self.item_index =", self.item_index)
    local transfer = string.pack("i4", self.item_index)
    local len
    print("item:get_transfer transfer =", crypt.hexencode(transfer))
    if self:get_serial_class() == define.ITEM_CLASS.ICLASS_EQUIP then
        transfer = "i" .. self:get_equip_data():get_transfer(self)
        len = string.len(transfer)
    elseif self:get_serial_class() == define.ITEM_CLASS.ICLASS_GEM then
        transfer = "i" .. transfer .. self:get_gem_data():get_transfer()
        len = string.len(transfer)
    elseif self:get_serial_class() == define.ITEM_CLASS.ICLASS_STOREMAP then
        transfer = "i" .. transfer .. self:get_store_map_data():get_transfer()
        len = string.len(transfer)
    elseif self:get_serial_class() == define.ITEM_CLASS.ICLASS_MATERIAL  then
        transfer = "i" .. transfer .. self:get_gem_data():get_transfer()
        len = string.len(transfer)
    elseif self:get_serial_class() == define.ITEM_CLASS.ICLASS_TASK then
        transfer = "i" .. transfer .. self:get_task_data():get_transfer()
        len = string.len(transfer)
    elseif self:get_serial_class() == define.ITEM_CLASS.ICLASS_PET_EQUIP then
        transfer = "i" .. self:get_pet_equip_data():get_transfer(self)
        len = string.len(transfer)
    end
    transfer = string.format("%03d%s", len, transfer)
    print("item:get_transfer transfer =", crypt.hexencode(transfer))
    return transfer
end

function item:get_base_config()
    local config
    local cls = self:get_serial_class()
    if cls == define.ITEM_CLASS.ICLASS_EQUIP then
        config = configenginer:get_config("equip_base")[self.item_index]
    elseif cls == define.ITEM_CLASS.ICLASS_GEM then
        config = configenginer:get_config("gem_info")[self.item_index]
    elseif cls == define.ITEM_CLASS.ICLASS_STOREMAP then
        config = configenginer:get_config("common_item")[self.item_index]
    elseif cls == define.ITEM_CLASS.ICLASS_PET_EQUIP then
        config = configenginer:get_config("pet_equip_base")[self.item_index]
    elseif cls == define.ITEM_CLASS.ICLASS_MATERIAL or cls == define.ITEM_CLASS.ICLASS_TASK then
        config = configenginer:get_config("common_item")[self.item_index]
    end
    return config
end

function item:get_name()
    local name
    local config = self:get_base_config()
    if config then
        name = config.name
    end
    name = name or "未知物品"
    return name
end

function item:get_next_enhance_config()
    local configs = configenginer:get_config("item_enhance")
    local base = self:get_base_config()
    local slot = base.equip_point
    local enchance_level = self:get_equip_data():get_enhancement_level()
    for _, config in pairs(configs) do
        if config.slot == slot and config.level == (enchance_level + 1) then
            return config
        end
    end
	return false
end

function item:get_enhance_config()
    local configs = configenginer:get_config("item_enhance")
    local base = self:get_base_config()
    local slot = base.equip_point
    local enchance_level = self:get_equip_data():get_enhancement_level()
    for _, config in pairs(configs) do
        if config.slot == slot and config.level == (enchance_level) then
            return config
        end
    end
	return false
end

function item:get_apt_config()
    local configs = configenginer:get_config("item_apt_rate")
    local qualifications = self:get_equip_data():get_qualifications()
    local bonus = {}
    for i, quality in ipairs(qualifications) do
        local config = configs[quality]
        if config then
            for j, c in ipairs(config.bonus) do
                if i == j then
                    bonus[c.ia] = c.iv
                end
            end
        end
    end
    return bonus
end

function item:get_diaowen_attrs()
	local equip_datas = self:get_equip_data()
    local diaowen_id = equip_datas:get_diaowen_id()
    local diaowen_attrs = {}
    local diaowen_std_impact = define.INVAILD_ID
	local dw_advance_level,dw_featuresid = 0,0
	if diaowen_id > 0 then
		local configs = configenginer:get_config("diaowen_info")
		config = configs[diaowen_id]
		if config then
			for i = define.ITEM_ATTRIBUTE.IATTRIBUTE_POINT_MAXHP, define.ITEM_ATTRIBUTE.IATTRIBUTE_BASE_MISS do
				local chn = define.CHN_ATTR_SHIFT[i]
				if chn then
					local value = config[chn]
					if value and value > 0 then
						diaowen_attrs[i] = (diaowen_attrs[i] or 0) + value
					end
				end
			end
			dw_advance_level,dw_featuresid = equip_datas:get_dw_jinjie_details()
			if dw_advance_level > 0 then
				local dw_jinjie_info = configenginer:get_config("dw_jinjie_info")
				dw_jinjie_info = dw_jinjie_info[dw_advance_level]
				dw_advance_level = dw_advance_level // 5
				if dw_jinjie_info then
					for i,j in pairs(diaowen_attrs) do
						if i >= define.ITEM_ATTRIBUTE.IATTRIBUTE_STR and i <= define.ITEM_ATTRIBUTE.IATTRIBUTE_ALL then
							diaowen_attrs[i] = diaowen_attrs[i] + dw_jinjie_info.onesx
						elseif i >= define.ITEM_ATTRIBUTE.IATTRIBUTE_REDUCE_TARGET_COLD_RESIST and i <= define.ITEM_ATTRIBUTE.IATTRIBUTE_REDUCE_TARGET_POISON_RESIST then
							diaowen_attrs[i] = diaowen_attrs[i] + dw_jinjie_info.threesx
						elseif i == define.ITEM_ATTRIBUTE.IATTRIBUTE_COLD_ATTACK
						or i == define.ITEM_ATTRIBUTE.IATTRIBUTE_FIRE_ATTACK
						or i == define.ITEM_ATTRIBUTE.IATTRIBUTE_LIGHT_ATTACK
						or i == define.ITEM_ATTRIBUTE.IATTRIBUTE_POISON_ATTACK then
							diaowen_attrs[i] = diaowen_attrs[i] + dw_jinjie_info.threesx
						elseif i == define.ITEM_ATTRIBUTE.IATTRIBUTE_COLD_RESIST
						or i == define.ITEM_ATTRIBUTE.IATTRIBUTE_FIRE_RESIST
						or i == define.ITEM_ATTRIBUTE.IATTRIBUTE_LIGHT_RESIST
						or i == define.ITEM_ATTRIBUTE.IATTRIBUTE_POISON_RESIST then
							diaowen_attrs[i] = diaowen_attrs[i] + dw_jinjie_info.threesx
						end
					end
				end
			end
			local value = config["技能ID"]
			if value and value > 0 then
				diaowen_std_impact = value
			end
		end
	end
    return diaowen_attrs,diaowen_std_impact,dw_advance_level,dw_featuresid
end

function item:get_diaowen_std_impact()
    local configs = configenginer:get_config("diaowen_info")
    local diaowen_id = self:get_equip_data():get_diaowen_id()
    local config = configs[diaowen_id]
    if config then
        local value = config["技能ID"]
        if value and value > 0 then
            return value
        end
    end
    return define.INVAILD_ID
end


function item:get_extra_config()
    return configenginer:get_config("equip_extra_attr")[self.item_index]
end

function item:get_pet_soul_base()
    local config
    if self:get_serial_class() == define.ITEM_CLASS.ICLASS_PET_EQUIP then
        config = configenginer:get_config("pet_soul_base")[self.item_index]
    end
    return config
end

function item:set_validity_period_start_time(type)
    local extra_config = self:get_extra_config()
    if extra_config then
		local expiration_date = extra_config.expiration_date
		if	expiration_date ~= define.INVAILD_ID then
			if type == extra_config.expiration_date_calculate_when_equipped then
				local date = os.date("%y%m%d%H%M")
				local ndate = tonumber(date)
				-- print("item:set_validity_period_start_time =", ndate)
				self:set_param(0, ndate, "uint")
				local deltime = os.time() + expiration_date * 3600
				self:set_item_record_data_forindex("deltime",deltime)
			end
        end
    end
end

function item:get_validity_period_start_time()
    local now = os.time()
    local extra_config = self:get_extra_config()
    if extra_config.expiration_date ~= define.INVAILD_ID then
        if 0 == extra_config.expiration_date_calculate_when_equipped then
           local ndate = self:get_param(0, "uint")
            local dt = {}
            dt.year, dt.month, dt.day, dt.hour, dt.min = string.match(tostring(ndate), "(%d%d)(%d%d)(%d%d)(%d%d)(%d%d)")
            dt.year = dt.year + 2000
            return os.time(dt),true
        end
        return now,false
    end
end

function item:get_can_add_expairation_time()
    local extra_config = self:get_extra_config()
    if extra_config == nil then
        return -1
    end
    local expiration_date = extra_config.expiration_date
    if expiration_date == -1 then
        return -1
    end
    local validity_period_start_time = self:get_validity_period_start_time()
    local expiration_date_sec = expiration_date * 60 * 60
    return validity_period_start_time + expiration_date_sec - os.time()
end

function item:add_exp(add_exp)
    if self:get_serial_class() == define.ITEM_CLASS.ICLASS_PET_EQUIP then
        if self:get_pet_equip_data():get_pet_equip_type() == define.PET_EQUIP_TYPE.SOUL then
            local pet_soul_base = configenginer:get_config("pet_soul_base")
            pet_soul_base = pet_soul_base[self:get_index()]
            self:get_pet_equip_data():add_exp(pet_soul_base, add_exp)
        end
    end
end

function item:get_stream()
    local ostream = iostream.bostream
    local os = ostream.new()
    packet_def.ItemGUID.bos(self.guid, os)
    os:writeint(self.item_index)
    os:writeuchar(self.rule)
    os:writeuchar(self.status)
    if self.item_index == -1 then
        os:write("", 182)
    elseif self:get_serial_class() == define.ITEM_CLASS.ICLASS_EQUIP then
        self:get_equip_data():get_stream(os, self)
    elseif self:get_serial_class() == define.ITEM_CLASS.ICLASS_GEM then
        self:get_gem_data():get_stream(os, self)
    elseif self:get_serial_class() == define.ITEM_CLASS.ICLASS_STOREMAP then
        self:get_store_map_data():get_stream(os, self)
    elseif self:get_serial_class() == define.ITEM_CLASS.ICLASS_MATERIAL  then
        self:get_material_data():get_stream(os, self)
    elseif self:get_serial_class() == define.ITEM_CLASS.ICLASS_TASK then
        self:get_task_data():get_stream(os, self)
    elseif self:get_serial_class() == define.ITEM_CLASS.ICLASS_PET_EQUIP then
        self:get_pet_equip_data():get_stream(os, self)
    end
    return os:get()
end

function item:is_expensive()
    if self:get_serial_class() == define.ITEM_CLASS.ICLASS_EQUIP then
        local data = self:get_equip_data()
        local gem_list = data:get_gem_list()
        for i = 1, 4 do
            local gem_id = gem_list[i] or define.INVAILD_ID
            local gem_item = item.new()
            gem_item:set_index(gem_id)
            if gem_item:is_expensive() then
                return true
            end
        end
    elseif self:get_serial_class() == define.ITEM_CLASS.ICLASS_GEM then
        local config = self:get_base_config()
        if config then
            return config.quality >= 4
        end
    end
    return false
end

return item
