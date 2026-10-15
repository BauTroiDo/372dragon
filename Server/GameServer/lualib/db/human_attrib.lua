local skynet = require "skynet"
local class = require "class"
local define = require "define"
local packet_def = require "game.packet"
local menpai_logic = require "menpai"
local configenginer = require "configenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local skillenginer = require "skillenginer":getinstance()
local pet_guid = require "pet_guid"
local exterior_bonus = require "exterior_bonus"
local equip_dress_bonus = require "equip_dress_bonus"
local ride_huayu_bonus = require "ride_huayu_bonus"
local human_attrib = class("human_attrib")
local must_be_positive = {
    attrib_att_magic = true,
    attrib_att_physics = true,
    attrib_def_magic = true,
    attrib_def_physics = true,
    attrib_hit = true,
    attrib_miss = true,
    hp = true,
    hp_max = true,
    mp = true,
    mp_max = true,
    point_remain = true,
    mind_attack = true,
    mind_defend = true,
    rage = true,
    strike_point = true,
    datura_flower = true,
    att_cold = true,
    reduce_def_cold = true,
    reduce_def_cold_low_limit = true,
    att_fire = true,
    reduce_def_fire = true,
    reduce_def_fire_low_limit = true,
    att_light = true,
    reduce_def_light = true,
    reduce_def_light_low_limit = true,
    att_poison = true,
    reduce_def_poison = true,
    reduce_def_poison_low_limit = true,
    vigor = true,
    stamina = true,
    str = true,
    spr = true,
    con = true,
    int = true,
    dex = true,
    exp = true,
    hp_re_speed = true,
    mp_re_speed = true,

    xiulian_str = true,
    xiulian_spr = true,
    xiulian_con = true,
    xiulian_int = true,
    xiulian_dex = true,

    xiulian_attrib_att_physics = true,
    xiulian_attrib_att_magic = true,
    xiulian_attrib_def_physics = true,
    xiulian_attrib_def_magic = true,
    xiulian_attrib_hit = true,
    xiulian_attrib_miss = true,

    exterior_hair_color_index = true,
}

local xiulian_bonus = {
    str = { key = "xiulian_str", index = 1},
    spr = { key = "xiulian_spr", index = 2},
    con = { key = "xiulian_con", index = 3},
    int = { key = "xiulian_int", index = 4},
    dex = { key = "xiulian_dex", index = 5},

    attrib_att_physics = { key = "xiulian_attrib_att_physics", index = 6},
    attrib_att_magic = { key = "xiulian_attrib_att_magic", index = 7},
    attrib_def_magic = { key = "xiulian_attrib_def_magic", index = 9},
    attrib_def_physics = { key = "xiulian_attrib_def_physics", index = 8},
    attrib_hit = { key = "xiulian_attrib_hit", index = 10},
    attrib_miss = { key = "xiulian_attrib_miss", index = 11},
}



local lv1_attribs = {
    str = true,
    spr = true,
    con = true,
    int = true,
    dex = true,
    point_remain = true
}

local IA = define.ITEM_ATTRIBUTE
local item_effct_shift = {
    str =  { point = IA.IATTRIBUTE_STR },
    spr =  { point = IA.IATTRIBUTE_SPR },
    con =  { point = IA.IATTRIBUTE_CON },
    int =  { point = IA.IATTRIBUTE_INT },
    dex =  { point = IA.IATTRIBUTE_DEX },
    hp_max = { point = IA.IATTRIBUTE_POINT_MAXHP, rate = IA.IATTRIBUTE_RATE_MAXHP, restore =  IA.IATTRIBUTE_RESTORE_HP},
    mp_max = { point = IA.IATTRIBUTE_POINT_MAXMP, rate = IA.IATTRIBUTE_RATE_MAXMP, restore =  IA.IATTRIBUTE_RESTORE_MP},
    attrib_att_physics = { point = IA.IATTRIBUTE_ATTACK_P, rate = IA.IATTRIBUTE_RATE_ATTACK_P, base = IA.IATTRIBUTE_BASE_ATTACK_P},
    attrib_att_magic = { point = IA.IATTRIBUTE_ATTACK_M, rate = IA.IATTRIBUTE_RATE_ATTACK_M, base = IA.IATTRIBUTE_BASE_MAGIC_P},
    attrib_def_physics = { point = IA.IATTRIBUTE_DEFENCE_P, rate = IA.IATTRIBUTE_RATE_DEFENCE_P, base = IA.IATTRIBUTE_BASE_DEFENCE_P},
    attrib_def_magic = { point = IA.IATTRIBUTE_DEFENCE_M, rate = IA.IATTRIBUTE_RATE_DEFENCE_M, base = IA.IATTRIBUTE_BASE_DEFENCE_P},
    attrib_hit =  { point = IA.IATTRIBUTE_HIT, base = IA.IATTRIBUTE_BASE_HIT },
    attrib_miss =  { point = IA.IATTRIBUTE_MISS, base = IA.IATTRIBUTE_BASE_MISS },
    mind_attack = { point = IA.IATTRIBUTE_2ATTACK_RATE },
    mind_defend = { point = IA.IATTRIBUTE_LUK },

    att_cold  = { point = IA.IATTRIBUTE_COLD_ATTACK },
    att_fire  = { point = IA.IATTRIBUTE_FIRE_ATTACK },
    att_light = { point = IA.IATTRIBUTE_LIGHT_ATTACK },
    att_poison  = { point = IA.IATTRIBUTE_POISON_ATTACK },

    def_cold  = { point = IA.IATTRIBUTE_COLD_RESIST },
    def_fire  = { point = IA.IATTRIBUTE_FIRE_RESIST },
    def_light = { point = IA.IATTRIBUTE_LIGHT_RESIST },
    def_poison  = { point = IA.IATTRIBUTE_POISON_RESIST },

    reduce_def_cold = { point = IA.IATTRIBUTE_REDUCE_TARGET_COLD_RESIST },
    reduce_def_fire = { point = IA.IATTRIBUTE_REDUCE_TARGET_FIRE_RESIST },
    reduce_def_light = { point = IA.IATTRIBUTE_REDUCE_TARGET_LIGHT_RESIST },
    reduce_def_poison = { point = IA.IATTRIBUTE_REDUCE_TARGET_POISON_RESIST },

    reduce_def_cold_low_limit = { point = IA.IATTRIBUTE_COLD_TIME },
    reduce_def_fire_low_limit = { point = IA.IATTRIBUTE_FIRE_TIME },
    reduce_def_light_low_limit = { point = IA.IATTRIBUTE_LIGHT_TIME },
    reduce_def_poison_low_limit = { point = IA.IATTRIBUTE_POISON_TIME },
}

local attrib_influences = {
    str = { attrib_att_physics = true},
    spr = { attrib_att_magic = true},
    con = { hp_max = true, attrib_def_physics = true},
    int = { mp_max = true, attrib_def_magic = true},
    dex = { attrib_hit = true, attrib_miss = true, mind_attack = true, mind_defend = true},
    hp = { hp_max = true },
    mp = { mp_max = true},

    soul_melting_pet_guid = { pet_soul_melting_model = true },
    team_follow_flag = { speed = true },
    team_follow_speed = { speed = true },
    team_follow_speed_up = { speed = true },
}

local base_attribs = {
    name = true,
    title = true,
    model = true,
    new_player_set = true,
    face_style = true,
    hair_style = true,
    hair_color = true,
    portrait_id = true,
    model_id = true,
    guid = true,
    level = true,
    owner_id = true,
    team_id = true,
    raid_id = true,
    raid_position = true,
	raid_is_full = true,
    menpai = true,
    speed = true,
    rage = true,
    ride_model = true,
    stealth_level = true,
    is_sit = true,
    hp = true,
    mp = true,
    hp_max = true,
    mp_max = true,
    reputation = true,
    pk_mode = true,
    pet_soul_melting_model = true,
    is_in_team = true,
    is_team_leader = true,
    world_pos = true,
    camp_id = true,
    stall_is_open = true,
    stall_name = true,
    guild_id = true,
    guild_name = true,
    confederate_id = true,
    confederate_name = true,
    pk_value = true,
    bus_id = true,
    server_id = true,
    exterior_head_id = true,
    exterior_head_pos = true,
    exterior_back_id = true,
    exterior_back_pos = true,
}

local detail_attribs = {
    attrib_att_magic = true,
    attrib_att_physics = true,
    attrib_def_magic = true,
    attrib_def_physics = true,
    attrib_hit = true,
    attrib_miss = true,
    hp = true,
    hp_max = true,
    mp = true,
    mp_max = true,
    level = true,
    ride = true,
    point_remain = true,
    mind_attack = true,
    mind_defend = true,
    rage = true,
    strike_point = true,
    datura_flower = true,
    att_cold = true,
    def_cold = true,
    reduce_def_cold = true,
    reduce_def_cold_low_limit = true,
    att_fire = true,
    def_fire = true,
    reduce_def_fire = true,
    reduce_def_fire_low_limit = true,
    att_light = true,
    def_light = true,
    reduce_def_light = true,
    reduce_def_light_low_limit = true,
    att_poison = true,
    def_poison = true,
    reduce_def_poison = true,
    reduce_def_poison_low_limit = true,
    menpai = true,
    speed = true,
    vigor = true,
    vigor_max = true,
    stamina = true,
    stamina_max = true,
    ride_model = true,
    team_id = true,
    exterior_face_style_index = true,
    exterior_hair_style_index = true,
    exterior_portrait_index = true,
    fashion_depot_index = true,
    exterior_weapon_visual_id = true,
    exterior_weapon_selcet_level = true,
    yuanbao = true,
    zengdian = true,
    bind_yuanbao = true,
    str = true,
    spr = true,
    con = true,
    int = true,
    dex = true,
    exp = true,
    money = true,
    jiaozi = true,
    hp_re_speed = true,
    mp_re_speed = true,
    can_action_1 = true,
    can_action_2 = true,
    can_move = true,
    reputation = true,
    model_id = true,
    pet_guid = true,
    pk_mode = true,
    change_pk_mode_delay = true,
    soul_melting_pet_guid = true,

    xiulian_str = true,
    xiulian_spr = true,
    xiulian_con = true,
    xiulian_int = true,
    xiulian_dex = true,

    xiulian_attrib_att_physics = true,
    xiulian_attrib_att_magic = true,
    xiulian_attrib_def_physics = true,
    xiulian_attrib_def_magic = true,
    xiulian_attrib_hit = true,
    xiulian_attrib_miss = true,
	
	wuhun_yy_flag = true,
    huanhun_qian_index = true,
    huanhun_kun_index = true,

    pk_min_level = true,
    pvp_rule = true,
    camp_id = true,
    is_fear = true,

    guild_id = true,
    confederate_id = true,

    team_follow_flag  = true,
    gongli = true,
    cur_attacker = true,
    today_kill_monster_count = true,
    pet_num_extra = true,
    master_level = true,
    master_moral_point = true,
    good_bad_value = true,
    exterior_pet_soul_id = true,
    exterior_ranse_model_level = true,
    menghui = true,
	
    exterior_head_id = true,
    exterior_head_pos = true,
    exterior_back_id = true,
    exterior_back_pos = true,
	
}

local not_gen_attribs = {
    pk_min_level = true,
    pvp_rule = true,
    camp_id = true,
    stall_is_open = true,
    stall_name = true,

    raid_id = true,
    raid_position = true,
	raid_is_full = true,
	
    is_in_team = true,
    is_team_leader = true,
    team_id = true,
    is_fear = true,

    team_follow_speed = true,
    team_follow_flag = true,
    team_follow_speed_up = true,

    pet_exp_multiple = true,
    cur_attacker = true,
    server_id = true,
    menghui = true
}

local db_attribs = {
    model = true,
    new_player_set = true,
    camp_id = true,
    face_style = true,
    hair_style = true,
    hair_color = true,
    vigor_max = true,
    stamina_max = true,
    ride_model = true,
    stealth_level = true,
    attack_speed = true,
    can_action_1 = true,
    can_action_2 = true,
    can_move = true,
    unbreakable = true,
    can_ignore_disturb = true,
    rage_max = true,
    strike_point_max = true,
    datura_flower_max = true,
    detect_level = true,
    want_change_pk_mode = true,
    change_pk_mode_delay = true,

    name = true,
    title = true,
    portrait_id = true,
    model_id = true,
    guid = true,
    owner_id = true,
    level = true,
    hp = true,
    mp = true,
    ride = true,
    rage = true,
    strike_point = true,
    datura_flower = true,
    menpai = true,
    vigor = true,
    stamina = true,
    exterior_face_style_index = true,
    exterior_hair_style_index = true,
    exterior_hair_color_index = true,
    exterior_portrait_index = true,
    fashion_depot_index = true,
    exterior_weapon_visual_id = true,
    exterior_weapon_selcet_level = true,
    yuanbao = true,
    zengdian = true,
    bind_yuanbao = true,
    exp = true,
    money = true,
    jiaozi = true,
    is_sit = true,
    world_pos = true,
    sceneid = true,
    reputation =true,
    speed = true,
    pet_guid = true,
    pk_mode = true,
    soul_melting_pet_guid = true,
    pet_soul_melting_model = true,
    exterior_pet_soul_id = true,
    exterior_equip_pet_soul_id = true,
    exterior_ranse_id = true,
    exterior_ranse_select = true,
    exterior_ranse_model_level = true,
    xiulian_str = true,
    xiulian_spr = true,
    xiulian_con = true,
    xiulian_int = true,
    xiulian_dex = true,
    xiulian_attrib_att_physics = true,
    xiulian_attrib_att_magic = true,
    xiulian_attrib_def_physics = true,
    xiulian_attrib_def_magic = true,
    xiulian_attrib_hit = true,
    xiulian_attrib_miss = true,
	
	wuhun_yy_flag = true,
    wuhun_show_flag = true,
    huanhun_qian_index = true,
    huanhun_kun_index = true,

    restore_scene_and_pos = true,
    guild_name = true,
    pk_value = true,
    pet_num_extra = true,
    honour = true,
    master_level = true,
    prentice_supply_exp = true,
    master_moral_point = true,
    jiebai_name = true,
    good_bad_value = true,
    logout_time = true,
    menghui = true,
	
    exterior_head_id = true,
    exterior_head_pos = true,
    exterior_back_id = true,
    exterior_back_pos = true,
}

local menpai_attribs = {
    hp_max = true,
    mp_max = true,
    hp_re_speed = true,
    mp_re_speed = true,
    attrib_att_physics = true,
    attrib_att_magic = true,
    attrib_def_physics = true,
    attrib_def_magic = true,
    attrib_hit = true,
    attrib_miss = true,
    mind_attack = true,
    mind_defend = true,
    att_cold = true,
    def_cold = true,
    reduce_def_cold = true,
    reduce_def_cold_low_limit = true,
    att_fire = true,
    def_fire = true,
    reduce_def_fire = true,
    reduce_def_fire_low_limit = true,
    att_light = true,
    def_light = true,
    reduce_def_light = true,
    reduce_def_light_low_limit = true,
    att_poison = true,
    def_poison = true,
    reduce_def_poison = true,
    reduce_def_poison_low_limit = true,
}

local db_save_attribs = {
    name = true,
    title = true,
    portrait_id = true,
    level = true,
    hp = true,
    hp_max = true,
    mp = true,
    mp_max = true,
    ride = true,
    rage = true,
    strike_point = true,
    datura_flower = true,
    menpai = true,
    vigor = true,
    stamina = true,
    exterior_face_style_index = true,
    exterior_hair_style_index = true,
    exterior_portrait_index = true,
    fashion_depot_index = true,
    exterior_weapon_visual_id = true,
    exterior_weapon_selcet_level = true,
    exterior_head_id = true,
    exterior_head_pos = true,
    exterior_back_id = true,
    exterior_back_pos = true,
    yuanbao = true,
    zengdian = true,
    bind_yuanbao = true,
    exp = true,
    money = true,
    jiaozi = true,
    is_sit = true,
    world_pos = true,
    sceneid = true,
    reputation =true,
    pet_guid = true,
    pk_mode = true,
    soul_melting_pet_guid = true,
    pet_soul_melting_model = true,
    exterior_pet_soul_id = true,
    exterior_equip_pet_soul_id = true,
    exterior_ranse_id = true,
    exterior_ranse_select = true,
    exterior_ranse_model_level = true,
    xiulian_str = true,
    xiulian_spr = true,
    xiulian_con = true,
    xiulian_int = true,
    xiulian_dex = true,
    xiulian_attrib_att_physics = true,
    xiulian_attrib_att_magic = true,
    xiulian_attrib_def_physics = true,
    xiulian_attrib_def_magic = true,
    xiulian_attrib_hit = true,
    xiulian_attrib_miss = true,
	wuhun_yy_flag = true,
    wuhun_show_flag = true,
    huanhun_qian_index = true,
    huanhun_kun_index = true,
    today_kill_monster_count = true,
    pk_value = true,
    honour = true,
    master_level = true,
    prentice_supply_exp = true,
    master_moral_point = true,
    jiebai_name = true,
    good_bad_value = true,
    logout_time = true,
    menghui = true,
    gm_attr_bonus = true
}

local refix_by_other = {
    mp = function(self, value)
        local mp_max = self:get_attrib("mp_max")
        if mp_max < value then
            value = mp_max
        end
        return value
    end,
    hp = function(self, value)
        local hp_max = self:get_attrib("hp_max")
        if hp_max < value then
            value = hp_max
        end
        return value
    end,
    pet_soul_melting_model = function(self)
        local soul_melting_pet_guid = self:get_attrib("soul_melting_pet_guid")
        if soul_melting_pet_guid:is_null() then
            return define.INVAILD_ID
        end
        local pet_detail = self:get_human():get_pet_bag_container():get_pet_by_guid(soul_melting_pet_guid)
        if pet_detail == nil then
            return define.INVAILD_ID
        end
        local exterior_pet_soul_id = self:get_attrib("exterior_pet_soul_id")
        exterior_pet_soul_id = exterior_pet_soul_id or 0
        local equip_pet_soul_id = self:get_attrib("exterior_equip_pet_soul_id") or 0
        local selected_pet_soul_id = exterior_pet_soul_id ~= 0 and exterior_pet_soul_id or equip_pet_soul_id
        if selected_pet_soul_id ~= 0 then
            local level = self.human:get_pet_soul_melting_level()
            if level == define.INVAILD_ID then
                return define.INVAILD_ID
            end
            if level ~= define.INVAILD_ID then
                local exterior_poss = configenginer:get_config("exterior_poss")
                exterior_poss = exterior_poss[selected_pet_soul_id]
                if not exterior_poss then
                    return pet_detail:get_pet_soul_melting_model()
                end
                local models = exterior_poss.models
                if not models then
                    return pet_detail:get_pet_soul_melting_model()
                end
                if exterior_pet_soul_id == 0 then
                    local equip_model = pet_detail:get_pet_soul_melting_model()
                    local matches_equip = false
                    for i = 1, 3 do
                        if models[i] == equip_model then
                            matches_equip = true
                            break
                        end
                    end
                    if not matches_equip then
                        return equip_model
                    end
                end
                local max_model_level = math.min(level // 3 + 1, 3)
                local model_level = self:get_attrib("exterior_ranse_model_level") or 0
                if model_level < 1 or model_level > max_model_level then
                    model_level = max_model_level
                end
                local model = exterior_poss["外观"][model_level]
                model = models[model_level] or model
                local ranse_id = self:get_attrib("exterior_ranse_id") or 0
                if ranse_id ~= 0 then
                    local exterior_ranse = configenginer:get_config("exterior_ranse")
                    exterior_ranse = exterior_ranse[selected_pet_soul_id]
                    local color_config = exterior_ranse and exterior_ranse[ranse_id]
                    if color_config and color_config.ColorModel then
                        model = color_config.ColorModel[model_level] or model
                    end
                end
                return model or pet_detail:get_pet_soul_melting_model()
            end
        else
            return pet_detail:get_pet_soul_melting_model()
        end
    end
}

local replace_by_other = {
    speed = function(self, value)
        local speed = value
        local team_follow_flag = self:get_attrib("team_follow_flag")
        if team_follow_flag == 1 then
            local is_team_leader = self:get_attrib("is_team_leader")
            if is_team_leader == 0 then
                local team_follow_speed = self:get_attrib("team_follow_speed")
                speed = team_follow_speed ~= nil and team_follow_speed or speed
            end
        end
        return speed
    end
}

function human_attrib:ctor(human, lv1, db)
    self.human = human
	if db.wuhun_show_flag == nil then
		db.wuhun_show_flag = 1
	end
    local p_guid = pet_guid.new()
    local db_pet_guid = db.pet_guid or {m_uHighSection = 0, m_uLowSection = 0}
    p_guid:set(db_pet_guid.m_uHighSection, db_pet_guid.m_uLowSection)
    local soul_melting_pet_guid = pet_guid.new()
    local db_soul_melting_pet_guid = db.soul_melting_pet_guid or {m_uHighSection = 0, m_uLowSection = 0}
    soul_melting_pet_guid:set(db_soul_melting_pet_guid.m_uHighSection, db_soul_melting_pet_guid.m_uLowSection)
    db.pet_guid = p_guid
    db.soul_melting_pet_guid = soul_melting_pet_guid
    db.can_action_1 = 1
    db.can_action_2 = 1
    require('cys_currency').normalize(db)
    self.db_attribs = db
    self.lv1_attribs = lv1
	self.chuanci = 0
	self.fangchuan = 0
    self.attribs = {}
    self.attribs_refix = {}
    self.dirty_flags = {}
    self.refix_dirty_flags = {}
    self.item_effect = {}
    self.equip_std_impacts = {}
    self.equip_add_skills = {}
    self.dirty_datas = {}
    self.not_gen_attribs = {}
    self.dw_jinjie_effect = {}
    self.base_attribs = nil
    self.detail_attribs = nil
    self:set_not_gen_attrib({ is_fear = 0 })
    self:set_not_gen_attrib({ pet_exp_multiple = 0 })
    self:set_not_gen_attrib({ cur_attacker = define.INVAILD_ID})
    self:refix_db_attrib()
end

function human_attrib:refix_db_attrib()
    local bank_save_money = self:get_attrib("bank_save_money")
    if bank_save_money == nil then
        self:set_db_attrib({ bank_save_money = 0 })
    end
end

function human_attrib:init()
    -- 登录初始化阶段装备/兽魂/称号等加成异常时降级跳过，优先保证人物进场。
    local ok, err = pcall(function()
        self:item_effect_flush()
    end)
    if not ok then
        self.item_effect = {}
        self.equip_std_impacts = {}
        self.equip_add_skills = {}
        self.dw_jinjie_effect = {}
        self:mark_all_attr_dirty()
    end
    -- self:mark_all_attr_dirty()
end

function human_attrib:mark_all_attr_dirty()
    for key in pairs(detail_attribs) do
        self.dirty_flags[key] = true
    end
    for key in pairs(base_attribs) do
        self.dirty_flags[key] = true
    end
end

function human_attrib:mark_attrib_dirty(key)
    self.dirty_flags[key] = true
    local influence = attrib_influences[key]
    if influence then
        for skey in pairs(influence) do
            self:mark_attrib_dirty(skey)
        end
    end
end

function human_attrib:get_dirty_flags (key)
    return self.dirty_flags[key] ~= nil or self.refix_dirty_flags[key] ~= nil
end

function human_attrib:clear_dirty_flag(key)
    self.dirty_flags[key] = nil
end

function human_attrib:mark_data_dirty_flag(key)
    --print("human_attrib:mark_data_dirty =", key)
    self.dirty_datas[key] = true
end

function human_attrib:clear_data_dirty_flag(key)
    --print("human_attrib:clear_data_dirty_flag =", key)
    self.dirty_datas[key] = nil
end


function human_attrib:get_item_effect(shift)
    return self.item_effect[shift] or 0
end

function human_attrib:get_damage_rate()
	local damage_rate = self.damage_rate or 0
	local sub_damage_rate = self.sub_damage_rate or 0
    return damage_rate,sub_damage_rate
end
function human_attrib:skill_refix_item_attr(slot, item_type, ia, iv)
    for _, skill in ipairs(self.mastery_skills) do
        local logic = skillenginer:get_logic_by_id(skill:get_logic_id())
        if logic and logic:is_passive() then
            iv = logic:refix_item_effect(skill, slot, ia, iv, item_type)
        end
    end
    return iv
end

function human_attrib:cal_item_effect(ia, iv, equip_point, item_type)
    -- 配表或历史数据缺字段时跳过本条加成，避免人物登录初始化被 nil 数值中断。
    if ia == nil or iv == nil then
        return
    end
    if ia == IA.IATTRIBUTE_BASE_ATTACK_P or ia == IA.IATTRIBUTE_BASE_MAGIC_P or ia == IA.IATTRIBUTE_BASE_DEFENCE_P or ia == IA.IATTRIBUTE_BASE_DEFENCE_M then
        iv = self:skill_refix_item_attr(equip_point, item_type, ia, iv)
        if iv == nil then
            return
        end
        self.item_effect[ia] = (self.item_effect[ia] or 0) + iv
    elseif ia == IA.IATTRIBUTE_ALL then
        self.item_effect[IA.IATTRIBUTE_STR] = (self.item_effect[IA.IATTRIBUTE_STR] or 0) + iv
        self.item_effect[IA.IATTRIBUTE_SPR] = (self.item_effect[IA.IATTRIBUTE_SPR] or 0) + iv
        self.item_effect[IA.IATTRIBUTE_CON] = (self.item_effect[IA.IATTRIBUTE_CON] or 0) + iv
        self.item_effect[IA.IATTRIBUTE_INT] = (self.item_effect[IA.IATTRIBUTE_INT] or 0) + iv
        self.item_effect[IA.IATTRIBUTE_DEX] = (self.item_effect[IA.IATTRIBUTE_DEX] or 0) + iv
    elseif ia == IA.IATTRIBUTE_POINT_ATTACK_P_ATTACK_M then
        self.item_effect[IA.IATTRIBUTE_ATTACK_P] = (self.item_effect[IA.IATTRIBUTE_ATTACK_P] or 0) + iv
        self.item_effect[IA.IATTRIBUTE_ATTACK_M] = (self.item_effect[IA.IATTRIBUTE_ATTACK_M] or 0) + iv
    else
        self.item_effect[ia] = (self.item_effect[ia] or 0) + iv
    end
end

function human_attrib:get_zengfu_level(equip)
    local creator_name = tostring(equip:get_item_creator() or "")
    local pos = string.find(creator_name, "&ZF", 1, true)
    if not pos then
        return 0
    end
    return tonumber(string.sub(creator_name, pos + 3)) or 0
end

function human_attrib:is_zengfu_blocked_attr(ia)
    return ia == IA.IATTRIBUTE_RATE_MAXHP
        or ia == IA.IATTRIBUTE_COLD_RESIST
        or ia == IA.IATTRIBUTE_FIRE_RESIST
        or ia == IA.IATTRIBUTE_LIGHT_RESIST
        or ia == IA.IATTRIBUTE_POISON_RESIST
        or ia == IA.IATTRIBUTE_RESIST_ALL
        or ia == IA.IATTRIBUTE_REDUCE_TARGET_COLD_RESIST
        or ia == IA.IATTRIBUTE_REDUCE_TARGET_FIRE_RESIST
        or ia == IA.IATTRIBUTE_REDUCE_TARGET_LIGHT_RESIST
        or ia == IA.IATTRIBUTE_REDUCE_TARGET_POISON_RESIST
        or ia == IA.IATTRIBUTE_POINT_JIAN_SU_RESIST
        or ia == IA.IATTRIBUTE_POINT_DIAN_XUE_RESIST
        or ia == IA.IATTRIBUTE_POINT_MA_BI_RESIST
        or ia == IA.IATTRIBUTE_POINT_SAN_GONG_RESIST
        or ia == IA.IATTRIBUTE_POINT_FENG_YIN_RESIST
        or ia == IA.IATTRIBUTE_POINT_SHI_MING_RESIST
end

function human_attrib:calc_zengfu_value(equip, ia, iv)
    local level = self:get_zengfu_level(equip)
    if level <= 0 or iv <= 0 or self:is_zengfu_blocked_attr(ia) then
        return iv
    end

    local bonus = 0
    if level <= 10 then
        bonus = level * 10
    elseif level == 11 then
        bonus = 120
    elseif level == 12 then
        bonus = 150
    elseif level == 13 then
        bonus = 190
    elseif level == 14 then
        bonus = 240
    elseif level == 15 then
        bonus = 300
    elseif level == 16 then
        bonus = 420
    elseif level == 17 then
        bonus = 600
    elseif level == 18 then
        bonus = 840
    elseif level == 19 then
        bonus = 1140
    elseif level >= 20 then
        bonus = 1500
    end

    if bonus <= 0 then
        return iv
    end

    return iv + ((iv * bonus + 50) // 100)
end

function human_attrib:instant_mastery_skills()
    self.mastery_skills = {}
    local skills = self:get_human():get_total_skills_list()
    for _, id in ipairs(skills) do
        local level = self:get_human():get_skill_level(id)
        local skill_logic_id = skillenginer:get_skill_logic_id(id, level)
        local logic = skillenginer:get_logic_by_id(skill_logic_id)
        if logic then
            if logic.classname == "armor_mastery" or logic.classname == "weapon_mastery" then
                local skill_info = skillenginer:instance_skill(self:get_human(), id, level)
                table.insert(self.mastery_skills, skill_info)
            end
        else
            print("skill_id =", id, "; level =", level, ";skill_logic_id =", skill_logic_id, "can not find logic")
        end
    end
end

function human_attrib:cal_quality_effect(equip, ia, iv)
    local ir = define.EQUIP_BASE_ATTR_BASE_ATTR_RATE[ia]
    local bonus = equip:get_apt_config()
    if bonus[ir] then
		local addiv = bonus[ir] * iv + 50
		addiv = addiv // 100
		return addiv
        -- return math.ceil(iv * (100 + bonus[ir]) / 100)
    end
    -- return iv
    return 0
end

function human_attrib:cal_enhance_effect(equip, ia, iv)
    local ir = define.EQUIP_BASE_ATTR_BASE_ATTR_RATE[ia]
    local config = equip:get_enhance_config()
    if config then
        local bonus = config.bonus
        if bonus[ir] then
			-- local addiv = bonus[ir] * iv + 50
			local addiv = bonus[ir] * iv
			addiv = addiv // 100
			return addiv
            -- return math.ceil(iv * (100 + bonus[ir]) / 100)
        end
    end
    -- return iv
    return 0
end

function human_attrib:kfs_base_effect_flush(equip)
    local kfs_level_up = configenginer:get_config("kfs_level_up")
    local kfs_level = equip:get_equip_data():get_wh_level()
    local kfs_growth_rate = equip:get_equip_data():get_wh_grow_rate()
    local item_index = equip:get_index()
    local attrs = table.clone(kfs_level_up[0][item_index])
    for i = 1, kfs_level do
        for j = 1, 5 do
            local v = attrs[j]
            assert(kfs_level_up[i], i)
            assert(kfs_level_up[i][item_index], item_index)
            assert(kfs_level_up[i][item_index][j], j)
            local add = kfs_level_up[i][item_index][j]
            attrs[j] = v + add
        end
    end
    for ia = define.ITEM_ATTRIBUTE.IATTRIBUTE_STR, define.ITEM_ATTRIBUTE.IATTRIBUTE_DEX do
        local iv = attrs[ia - 41]
        if kfs_level_up[1][item_index][ia - 41] == 1 then
            iv = math.ceil(iv * (kfs_growth_rate + 850) / 1000)
        end
        iv = math.ceil(iv * kfs_growth_rate / 1000)
        self:cal_item_effect(ia, iv)
    end
end

function human_attrib:kfs_extra_effect_flush(equip, i, item_type)
    local ext_attr = equip:get_equip_data():get_wh_ex_attr()
    local kfs_attr_ext = configenginer:get_config("kfs_attr_ext")
    local kfs_growth_rate = equip:get_equip_data():get_wh_grow_rate()
    local wh_hecheng_level = equip:get_equip_data():get_wh_hecheng_level()
    for _, id in ipairs(ext_attr) do
        local attr_conf = kfs_attr_ext[id]
        if attr_conf then
            for ia = define.ITEM_ATTRIBUTE.IATTRIBUTE_POINT_MAXHP, define.ITEM_ATTRIBUTE.IATTRIBUTE_BASE_MISS do
                local chn = define.CHN_ATTR_SHIFT[ia]
                if chn then
                    local value = attr_conf[chn]
                    if value and value > 0 then
                        local iv = math.ceil(value * (kfs_growth_rate / 1000.0) * wh_hecheng_level / (define.KFS_EXT_ATTR_VALUE_RATE[wh_hecheng_level] or 1) )
                        self:cal_item_effect(ia, iv, i, item_type)
                    end
                end
            end
        end
    end
end

function human_attrib:kfs_wg_effect_flush(wuhun_wg_level, i)
    local huanhuns = self:get_human():get_wuhun_wg()
    local si = tostring(i)
    local huanhun = huanhuns[si]
    if huanhun then
        local level = huanhun.level
        local grade = huanhun.grade
        local Index = i * 10000 + level * 100 + grade
        wuhun_wg_level = wuhun_wg_level[Index]
        if wuhun_wg_level then
            local ia = wuhun_wg_level.IA
            local iv = wuhun_wg_level.IV
            local add_rate_ia
            local add_rate_iv
            if self:get_attrib("huanhun_qian_index") == i then
                ia = wuhun_wg_level.qian_IA
                iv = wuhun_wg_level.qian_IV
                add_rate_ia = define.ITEM_ATTRIBUTE.IATTRIBUTE_POINT_ADD_ATTACK_MAGIC_DAMAGE_RATE + i - 1
                add_rate_iv = wuhun_wg_level.qian_add_attack_iv
            elseif self:get_attrib("huanhun_kun_index") == i then
                ia = wuhun_wg_level.kun_IA
                iv = wuhun_wg_level.kun_IV
                add_rate_ia = define.ITEM_ATTRIBUTE.IATTRIBUTE_POINT_ADD_MAGIC_DEFENCE_RATE + i - 1
                add_rate_iv = wuhun_wg_level.kun_add_defence_iv
            end
            self:cal_item_effect(ia, iv)
            if add_rate_ia then
                self:cal_item_effect(add_rate_ia, add_rate_iv)
            end
        end
    end
end

function human_attrib:kfs_wgs_effect_flush()
    local wuhun_wg_level = configenginer:get_config("wuhun_wg_level")
    for i = 1, 6 do
        self:kfs_wg_effect_flush(wuhun_wg_level, i)
    end
end

function human_attrib:kfs_effect_flush(equip, i, item_type)
    if require('cys_dual_souls').definition(equip:get_index()) then return end -- its mastery skill is the only passive source
    self:kfs_base_effect_flush(equip, i, item_type)
    self:kfs_extra_effect_flush(equip, i, item_type)
    self:kfs_wgs_effect_flush(equip, i, item_type)
end

function human_attrib:pet_soul_attr_effect(pet_detail, attr)
    local type = attr.type
    if type ~= define.INVAILD_ID then
        local value = attr.value
        local cof = define.PET_SOUL_MELTING_COF[type]
        local collection = define.PET_SOUL_MELTING_INFLUENCE_PERCEPTION[type]
        local growth_rate = pet_detail:get_growth_rate() * 1000
        assert(collection, type)
        local perception = pet_detail:get_max_perception_in_collection(collection)
        local growth_rate_arg = ( growth_rate * growth_rate / 64000000.0) + 0.0099999998
        if type == 15 or type == 16 or type == 17 or type == 18 or type == 19 or type == 20 then
            local iv = ((((perception + 2000) * (perception + 2000))  * cof ) + 0.0099999998)* (value * growth_rate_arg)
            iv = iv * 11.58
            if iv > value * 1.2 then
                iv = value * 1.2
            end
            iv = math.floor(iv)
            if type ~= define.INVAILD_ID then
                local ia = define.PET_SOUL_MELTING_ATTR_2_IA[type]
                assert(ia, type)
                self:cal_item_effect(ia, iv)
            end
        elseif type == 11 or type == 12 or type == 13 or type == 14 then
            local iv = ((((perception + 2000) * (perception + 2000))  * cof ) + 0.0099999998)* (value * growth_rate_arg)
            iv = iv * 11.58
            if iv > value * 1.2 then
                iv = value * 1.2
            end
            iv = math.floor(iv)
            if type ~= define.INVAILD_ID then
                local ia = define.PET_SOUL_MELTING_ATTR_2_IA[type]
                assert(ia, type)
                self:cal_item_effect(ia, iv)
            end
        elseif type == 21 or type == 22 then
            value = value / 100
            local iv = (((perception + 2000) * (perception + 2000) * cof) + 0.0099999998) * (value * growth_rate_arg) * 15.0
            iv = iv * 11.58
            if (value * 18) <= iv then
                iv = value * 18
            end
            iv = math.floor(iv)
            iv = iv < 1 and 1 or iv
            if type ~= define.INVAILD_ID then
                local ia = define.PET_SOUL_MELTING_ATTR_2_IA[type]
                assert(ia, type)
                self:cal_item_effect(ia, iv)
            end
        elseif type == 0 then
            local iv = ((((perception + 2000) * (perception + 2000))  * cof )+ 0.0099999998)* (value * growth_rate_arg)
            iv = iv * 15.27699669966997
            if iv > value * 1.2 then
                iv = value * 1.2
            end
            iv = math.floor(iv)
            if type ~= define.INVAILD_ID then
                local ia = define.PET_SOUL_MELTING_ATTR_2_IA[type]
                assert(ia, type)
                self:cal_item_effect(ia, iv)
            end 
        elseif  type == 1 or type == 2 or type == 3 or type == 4 or type == 5
            or type == 6 or type == 7 or type == 8 then
            local iv = ((((perception + 2000) * (perception + 2000))  * cof )+ 0.0099999998)* (value * growth_rate_arg)
            iv = iv * 11.19
            if iv > value * 1.2 then
                iv = value * 1.2
            end
            iv = math.floor(iv)
            if type ~= define.INVAILD_ID then
                local ia = define.PET_SOUL_MELTING_ATTR_2_IA[type]
                assert(ia, type)
                self:cal_item_effect(ia, iv)
            end
        elseif type == 9 then
            local iv = ((((perception + 2000) * (perception + 2000))  * cof )+ 0.0099999998)* (value * growth_rate_arg)
            iv = iv * 7.63
            if iv > value * 1.2 then
                iv = value * 1.2
            end
            iv = math.floor(iv)
            if type ~= define.INVAILD_ID then
                local ia = define.PET_SOUL_MELTING_ATTR_2_IA[type]
                assert(ia, type)
                self:cal_item_effect(ia, iv)
            end
        elseif type == 10 then
            local iv = ((((perception + 2000) * (perception + 2000))  * cof )+ 0.0099999998)* (value * growth_rate_arg)
            iv = iv * 4.23
            if iv > value * 1.2 then
                iv = value * 1.2
            end
            iv = math.floor(iv)
            if type ~= define.INVAILD_ID then
                local ia = define.PET_SOUL_MELTING_ATTR_2_IA[type]
                assert(ia, type)
                self:cal_item_effect(ia, iv)
            end
        else
            local iv = ((((perception + 2000) * (perception + 2000))  * cof )+ 0.0099999998)* (value * growth_rate_arg)
            if iv > value * 1.2 then
                iv = value * 1.2
            end
            iv = math.floor(iv)
            if type ~= define.INVAILD_ID then
                local ia = define.PET_SOUL_MELTING_ATTR_2_IA[type]
                assert(ia, type)
                self:cal_item_effect(ia, iv)
            end
        end
    end
end

function human_attrib:pet_soul_melting_base_effect_one(skill, level, impact_id)
    local pet_soul_skill = configenginer:get_config("pet_soul_skill")
    local skill_conf = pet_soul_skill and pet_soul_skill[skill]
    local melting_impact = skill_conf and skill_conf.melting_impacts and skill_conf.melting_impacts[impact_id]
    if not melting_impact then
        -- 兽魂融魂配置缺失时只跳过本条效果，不能阻断人物进场。
        return
    end
    local desc = melting_impact.desc
    local values = melting_impact.values
    local iv = values and values[level]
    if desc ~= define.INVAILD_ID then
        local ia = define.PET_SOUL_BASE_ATTR_2_IA[desc]
        if not ia or iv == nil then
            -- 融魂等级越界或属性映射缺失时跳过，保留日志供后续修数据。
            return
        end
        if ia == define.ITEM_ATTRIBUTE.IATTRIBUTE_QIONGQI_MELTING_IMPACT then
            local impact = define.QIONGQI_IMPACT[level]
            if impact then
                self.equip_std_impacts[impact] = true
            end
        else
            self:cal_item_effect(ia, iv)
        end
    end
end

function human_attrib:pet_soul_melting_base_effect()
    local soul_melting_pet_guid = self:get_attrib("soul_melting_pet_guid")
    if not soul_melting_pet_guid:is_null() then
        local pet_detail = self:get_human():get_pet_bag_container():get_pet_by_guid(soul_melting_pet_guid)
        if pet_detail then
            local soul = pet_detail:get_equip_container():get_item(define.PET_EQUIP.PEQUIP_SOUL)
            if soul then
                local level = (soul:get_pet_equip_data():get_pet_soul_level() or 0) + 1
                local base = soul:get_pet_soul_base()
                local skill = base and base.skill
                if skill then
                    self:pet_soul_melting_base_effect_one(skill, level, 1)
                    self:pet_soul_melting_base_effect_one(skill, level, 2)
                    self:pet_soul_melting_base_effect_one(skill, level, 3)
                end
            end
        end
    end
end

function human_attrib:pet_soul_melting_extra_effect()
    local soul_melting_pet_guid = self:get_attrib("soul_melting_pet_guid")
    if not soul_melting_pet_guid:is_null() then
        local pet_detail = self:get_human():get_pet_bag_container():get_pet_by_guid(soul_melting_pet_guid)
        if pet_detail then
            local soul = pet_detail:get_equip_container():get_item(define.PET_EQUIP.PEQUIP_SOUL)
            if soul then
                local level = soul:get_pet_equip_data():get_pet_soul_level() + 1
                local pet_soul_attr = soul:get_pet_equip_data():get_pet_soul_attr()
                if not pet_soul_attr then

                    return
                end
                for i = 1, level do
                    local attr = pet_soul_attr[i]
                    -- 兽魂扩展属性缺层时跳过，避免历史高等级数据越界卡登录。
                    if attr then
                        self:pet_soul_attr_effect(pet_detail, attr)
                    end
                end
            end
        end
    end
end

function human_attrib:pet_soul_melting_effect()
    self:pet_soul_melting_base_effect()
    self:pet_soul_melting_extra_effect()
end

function human_attrib:common_equip_effect_flush_publish_xrx()
	local human = self:get_human()
    local container = human:get_equip_container()
	local equip_enhanceex = configenginer:get_config("equip_enhanceex")
    local equip_base = configenginer:get_config("equip_base")
    local equip_sets = {}
	local zhen_cl = 0
    for i = define.HUMAN_EQUIP.HEQUIP_WEAPON, define.HUMAN_EQUIP.HEQUIP_WUHUN do
        local equip = container:get_item(i)
        if equip then
            local dur = equip:get_equip_data():get_dur()
            local wh_life = equip:get_equip_data():get_wh_life()
            if (i ~= define.HUMAN_EQUIP.HEQUIP_WUHUN and dur > 0) 
			or (i == define.HUMAN_EQUIP.HEQUIP_WUHUN and wh_life > 0) then
			-- or ( i == define.HUMAN_EQUIP.SHENBING and dur > 0) then
				local eqid = equip:get_index()
				if i == define.HUMAN_EQUIP.HEQUIP_RING_1 or i == define.HUMAN_EQUIP.HEQUIP_RING_2 then
					if eqid == 10422150 or eqid == 10513137 then
						zhen_cl = zhen_cl + 1
					end
				elseif i == define.HUMAN_EQUIP.HEQUIP_AMULET_1 or i == define.HUMAN_EQUIP.HEQUIP_AMULET_2 then
					if eqid == 10423026 or eqid == 10513136 then
						zhen_cl = zhen_cl + 1
					end
				elseif i == define.HUMAN_EQUIP.HEQUIP_NECKLACE then
					if eqid == 10420088 or eqid == 10420090 or eqid == 10513138 or eqid == 10513138 then
						zhen_cl = zhen_cl + 1
					end
				elseif i == define.HUMAN_EQUIP.HEQUIP_ARMOR then
					if eqid == 10413104 or eqid == 10513140 then
						--zhen_cl = zhen_cl + 1
					end
				elseif i == define.HUMAN_EQUIP.HEQUIP_SHOULDER then
					if eqid == 10415056 or eqid == 10513139 then
						--zhen_cl = zhen_cl + 1
					end
				elseif i == define.HUMAN_EQUIP.HEQUIP_CUFF then
					if eqid == 10513130 then
						self.damage_rate = 20
					end
				elseif i == define.HUMAN_EQUIP.HEQUIP_GLOVE then
					if eqid == 10513135 then
						self.sub_damage_rate = 20
					end
				end
                local equip_data = equip:get_equip_data()
                local gem_attrs = equip:get_gem_attrs()
                local diaowen_attrs,diaowen_std_impact,dw_advance_level,dw_featuresid = equip:get_diaowen_attrs()
                if dw_featuresid > 0 then
					local idx = tostring(i)
					self.dw_jinjie_effect[idx] = {id = dw_featuresid,finedraw = dw_advance_level}
				end
                local item_type = equip:get_serial_type()
				local qhlv = equip_data:get_enhancement_level()
				if qhlv > 8 and qhlv < 100 then
					if equip_enhanceex[qhlv] then
						local mdid = define.CHUANCIGONGFANG[i]
						if mdid == 602 then
							self.chuanci = self.chuanci + equip_enhanceex[qhlv].chuangci
						elseif mdid == 603 then
							self.fangchuan = self.fangchuan + equip_enhanceex[qhlv].fangchuan
						end
					end
				end
                for j = 1, equip_data.attr_count do
                    local ef = equip_data.attr_types[j]
                    local ev = self:calc_zengfu_value(equip, ef, require("cys_equipcraft").bonus(equip, ef, equip_data.attr_values[j]))
                    self:cal_item_effect(ef, ev, i, item_type)
                end
                for ia, iv in pairs(gem_attrs) do
                    self:cal_item_effect(ia, iv, i, item_type)
                end
                for ia, iv in pairs(diaowen_attrs) do
                    self:cal_item_effect(ia, iv, i, item_type)
                end
                local base = equip_base[eqid]
                assert(base,eqid)
                if i == define.HUMAN_EQUIP.HEQUIP_ANQI then
                    local aq_xiulian = equip:get_equip_data():get_aq_xiulian() or 1
                    local val = 32 + (aq_xiulian // 10 - 1) * 85
                    base = { base_attrs = { ["基础外功攻击"] = val, ["基础内功攻击"] = val}, skill_id = define.INVAILD_ID}
                    -- [FIX] 暗器aq_attr五维属性加成
                    local aq_data = equip:get_equip_data()
                    for attr_idx = 1, 5 do
                        local attr_name = define.ANQI_ATTR[attr_idx]
                        local attr_val = aq_data:get_aq_attr(attr_idx)
                        if attr_val and attr_val > 0 then
                            local ia = define.EQUIP_ATTR[attr_name]
                            if ia then
                                self:cal_item_effect(ia, attr_val, i, item_type)
                            end
                        end
                    end
                end
				local isebind = equip:is_ebind()
				local ebind_rate = 0
				if isebind then
					ebind_rate = 10
				end
				local iv_quality,iv_enhance,iv_ebind
                for chn, ia in pairs(define.EQUIP_BASE_ATTRIB) do
                    local iv = base.base_attrs[chn]
                    if iv and iv > 0 then
						iv_enhance = self:cal_enhance_effect(equip, ia, iv)
						iv_ebind = iv * ebind_rate
						iv_ebind = iv_ebind // 100
						iv = iv + iv_enhance + iv_ebind
						iv_quality = self:cal_quality_effect(equip, ia, iv)
						iv = iv + iv_quality
                        iv = self:calc_zengfu_value(equip, ia, iv)
						self:cal_item_effect(ia, iv, i, item_type)
                    end
                end
                if base.skill_id ~= define.INVAILD_ID then
                    self.equip_std_impacts[base.skill_id] = true
                end
                if diaowen_std_impact ~= define.INVAILD_ID then
                    self.equip_std_impacts[diaowen_std_impact] = true
                end
                if i == define.HUMAN_EQUIP.HEQUIP_WUHUN then
                    self:kfs_effect_flush(equip, i, item_type)
                end
                local base_config = equip:get_base_config()
                local set_id = base_config.set_id
                if set_id ~= define.INVAILD_ID and set_id ~= 219 then
					local equip_point = base_config.equip_point
					if equip_point == define.HUMAN_EQUIP.HEQUIP_RING_1 or equip_point == define.HUMAN_EQUIP.HEQUIP_RING_2 then
						equip_point = define.HUMAN_EQUIP.HEQUIP_RING_1
					elseif equip_point == define.HUMAN_EQUIP.HEQUIP_AMULET_1 or equip_point == define.HUMAN_EQUIP.HEQUIP_AMULET_2 then
						equip_point = define.HUMAN_EQUIP.HEQUIP_AMULET_1
					end
					equip_sets[set_id] = equip_sets[set_id] or {}
					equip_sets[set_id][equip_point] = true
                end
			end
		end
	end
	local equip_set_attr = configenginer:get_config("equip_set_attr")
    for set_id, set_id_points in pairs(equip_sets) do
        local set = equip_set_attr[set_id]
        if set then
			local count = 0
			for e_point in pairs(set_id_points) do
				count = count + 1
			end
			if set_id == 219 then
				 if count >= 3 then
					 --self.equip_std_impacts[5980] = true
				 elseif count >= 2 then
					 --self.equip_std_impacts[5981] = true
				 end
			else
				for i = 1, count do
					local ia = set.IAS[i]
					if ia then
						if ia.IA == 100 then
						
						elseif ia.IA ~= define.INVAILD_ID then
							self:cal_item_effect(ia.IA, ia.IV)
						end
					end
				end
			end
        end
    end
	if zhen_cl >= 3 then
		for i = IA.IATTRIBUTE_COLD_ATTACK,IA.IATTRIBUTE_POISON_TIME,3 do
			self:cal_item_effect(i,288)
		end
		for i = IA.IATTRIBUTE_REDUCE_TARGET_COLD_RESIST,IA.IATTRIBUTE_REDUCE_TARGET_POISON_RESIST do
			self:cal_item_effect(i,60)
		end
		--human:notify_tips("身上重楼装备数量>=3件且都有耐久度，属性攻额外+288，减抗额外+60。")
	elseif zhen_cl >= 2 then
		for i = IA.IATTRIBUTE_COLD_ATTACK,IA.IATTRIBUTE_POISON_TIME,3 do
			self:cal_item_effect(i,188)
		end
		for i = IA.IATTRIBUTE_REDUCE_TARGET_COLD_RESIST,IA.IATTRIBUTE_REDUCE_TARGET_POISON_RESIST do
			self:cal_item_effect(i,30)
		end
		--human:notify_tips("身上重楼装备数量>=2件且都有耐久度，属性攻额外+188，减抗额外+30。")
	end
end

function human_attrib:common_equip_effect_flush_publish_xws()
	local human = self:get_human()
    local container = human:get_equip_container()
	local equip_enhanceex = configenginer:get_config("equip_enhanceex")
    local equip_base = configenginer:get_config("equip_base")
    local equip_sets = {}
	local zhen_cl = 0
    for i = define.HUMAN_EQUIP.HEQUIP_WEAPON, define.HUMAN_EQUIP.HEQUIP_WUHUN do
        local equip = container:get_item(i)
        if equip then
            local dur = equip:get_equip_data():get_dur()
            local wh_life = equip:get_equip_data():get_wh_life()
            if (i ~= define.HUMAN_EQUIP.HEQUIP_WUHUN and dur > 0) 
			or (i == define.HUMAN_EQUIP.HEQUIP_WUHUN and wh_life > 0) then
			-- or ( i == define.HUMAN_EQUIP.SHENBING and dur > 0) then
				local eqid = equip:get_index()
				if i == define.HUMAN_EQUIP.HEQUIP_RING_1 or i == define.HUMAN_EQUIP.HEQUIP_RING_2 then
					if eqid == 10422150 then
						zhen_cl = zhen_cl + 1
					end
				elseif i == define.HUMAN_EQUIP.HEQUIP_AMULET_1 or i == define.HUMAN_EQUIP.HEQUIP_AMULET_2 then
					if eqid == 10423026 then
						zhen_cl = zhen_cl + 1
					end
				elseif i == define.HUMAN_EQUIP.HEQUIP_NECKLACE then
					if eqid == 10420088 or eqid == 10420090 then
						zhen_cl = zhen_cl + 1
					end
				elseif i == define.HUMAN_EQUIP.HEQUIP_ARMOR then
					if eqid == 10413104 then
						--zhen_cl = zhen_cl + 1
					end
				elseif i == define.HUMAN_EQUIP.HEQUIP_SHOULDER then
					if eqid == 10415056 then
						--zhen_cl = zhen_cl + 1
					end
				end
                local equip_data = equip:get_equip_data()
                local gem_attrs = equip:get_gem_attrs()
                local diaowen_attrs,diaowen_std_impact,dw_advance_level,dw_featuresid = equip:get_diaowen_attrs()
                if dw_featuresid > 0 then
					local idx = tostring(i)
					self.dw_jinjie_effect[idx] = {id = dw_featuresid,finedraw = dw_advance_level}
				end
                local item_type = equip:get_serial_type()
				local qhlv = equip_data:get_enhancement_level()
				if qhlv > 8 and qhlv < 100 then
					if equip_enhanceex[qhlv] then
						local mdid = define.CHUANCIGONGFANG[i]
						if mdid == 602 then
							self.chuanci = self.chuanci + equip_enhanceex[qhlv].chuangci
						elseif mdid == 603 then
							self.fangchuan = self.fangchuan + equip_enhanceex[qhlv].fangchuan
						end
					end
				end
                for j = 1, equip_data.attr_count do
                    local ef = equip_data.attr_types[j]
                    local ev = self:calc_zengfu_value(equip, ef, require("cys_equipcraft").bonus(equip, ef, equip_data.attr_values[j]))
                    self:cal_item_effect(ef, ev, i, item_type)
                end
                for ia, iv in pairs(gem_attrs) do
                    self:cal_item_effect(ia, iv, i, item_type)
                end
                for ia, iv in pairs(diaowen_attrs) do
                    self:cal_item_effect(ia, iv, i, item_type)
                end
                local base = equip_base[eqid]
                assert(base,eqid)
                if i == define.HUMAN_EQUIP.HEQUIP_ANQI then
                    local val = 32 + ((equip:get_equip_data():get_aq_xiulian() or 1) // 10 - 1) * 85
                    base = { base_attrs = { ["基础外功攻击"] = val, ["基础内功攻击"] = val}, skill_id = define.INVAILD_ID}
                    -- [FIX] 暗器aq_attr五维属性加成
                    local aq_data = equip:get_equip_data()
                    for attr_idx = 1, 5 do
                        local attr_name = define.ANQI_ATTR[attr_idx]
                        local attr_val = aq_data:get_aq_attr(attr_idx)
                        if attr_val and attr_val > 0 then
                            local ia = define.EQUIP_ATTR[attr_name]
                            if ia then
                                self:cal_item_effect(ia, attr_val, i, item_type)
                            end
                        end
                    end
                end
				local isebind = equip:is_ebind()
				local ebind_rate = 0
				if isebind then
					ebind_rate = 10
				end
				local iv_quality,iv_enhance,iv_ebind
                for chn, ia in pairs(define.EQUIP_BASE_ATTRIB) do
                    local iv = base.base_attrs[chn]
                    if iv and iv > 0 then
						iv_enhance = self:cal_enhance_effect(equip, ia, iv)
						iv_ebind = iv * ebind_rate
						iv_ebind = iv_ebind // 100
						iv = iv + iv_enhance + iv_ebind
						iv_quality = self:cal_quality_effect(equip, ia, iv)
						iv = iv + iv_quality
                        iv = self:calc_zengfu_value(equip, ia, iv)
						self:cal_item_effect(ia, iv, i, item_type)
                    end
                end
                if base.skill_id ~= define.INVAILD_ID then
                    self.equip_std_impacts[base.skill_id] = true
                end
                if diaowen_std_impact ~= define.INVAILD_ID then
                    self.equip_std_impacts[diaowen_std_impact] = true
                end
                if i == define.HUMAN_EQUIP.HEQUIP_WUHUN then
                    self:kfs_effect_flush(equip, i, item_type)
                end
                local base_config = equip:get_base_config()
                local set_id = base_config.set_id
                if set_id ~= define.INVAILD_ID then
					local equip_point = base_config.equip_point
					if equip_point == define.HUMAN_EQUIP.HEQUIP_RING_1 or equip_point == define.HUMAN_EQUIP.HEQUIP_RING_2 then
						equip_point = define.HUMAN_EQUIP.HEQUIP_RING_1
					elseif equip_point == define.HUMAN_EQUIP.HEQUIP_AMULET_1 or equip_point == define.HUMAN_EQUIP.HEQUIP_AMULET_2 then
						equip_point = define.HUMAN_EQUIP.HEQUIP_AMULET_1
					end
					equip_sets[set_id] = equip_sets[set_id] or {}
					equip_sets[set_id][equip_point] = true
                end
			end
		end
	end
	local equip_set_attr = configenginer:get_config("equip_set_attr")
    for set_id, set_id_points in pairs(equip_sets) do
        local set = equip_set_attr[set_id]
        if set then
			local count = 0
			for e_point in pairs(set_id_points) do
				count = count + 1
			end
			if set_id == 219 then
				 if count >= 3 then
					 self.equip_std_impacts[5980] = true
				 elseif count >= 2 then
					 self.equip_std_impacts[5981] = true
				 end
			else
				for i = 1, count do
					local ia = set.IAS[i]
					if ia then
						if ia.IA == 100 then
						
						elseif ia.IA ~= define.INVAILD_ID then
							self:cal_item_effect(ia.IA, ia.IV)
						end
					end
				end
			end
        end
    end
	if zhen_cl >= 3 then
		--for i = IA.IATTRIBUTE_COLD_ATTACK,IA.IATTRIBUTE_POISON_TIME,3 do
			--self:cal_item_effect(i,288)
		--end
		--for i = IA.IATTRIBUTE_REDUCE_TARGET_COLD_RESIST,IA.IATTRIBUTE_REDUCE_TARGET_POISON_RESIST do
			--self:cal_item_effect(i,60)
		--end
		--human:notify_tips("身上重楼装备数量>=3件且都有耐久度，属性攻额外+288，减抗额外+60。")
	elseif zhen_cl >= 2 then
		--for i = IA.IATTRIBUTE_COLD_ATTACK,IA.IATTRIBUTE_POISON_TIME,3 do
			--self:cal_item_effect(i,188)
		--end
		--for i = IA.IATTRIBUTE_REDUCE_TARGET_COLD_RESIST,IA.IATTRIBUTE_REDUCE_TARGET_POISON_RESIST do
			--self:cal_item_effect(i,30)
		--end
		--human:notify_tips("身上重楼装备数量>=2件且都有耐久度，属性攻额外+188，减抗额外+30。")
	end
end

function human_attrib:common_equip_effect_flush_publish_xhz()
	local human = self:get_human()
    local container = human:get_equip_container()
	local equip_enhanceex = configenginer:get_config("equip_enhanceex")
    local equip_base = configenginer:get_config("equip_base")
    local equip_sets = {}
	local nice_star = 0
    for i = define.HUMAN_EQUIP.HEQUIP_WEAPON, define.HUMAN_EQUIP.HEQUIP_WUHUN do
        local equip = container:get_item(i)
        if equip then
			local is_update = 0
			if i == define.HUMAN_EQUIP.HEQUIP_WUHUN then
				local wh_life = equip:get_equip_data():get_wh_life()
				if wh_life > 0 then
					is_update = 1
				end
			else
				local dur = equip:get_equip_data():get_dur()
				if dur > 0 then
					if i ~= define.HUMAN_EQUIP.HEQUIP_WEAPON and i ~= define.HUMAN_EQUIP.HEQUIP_ANQI then
						is_update = 2
					else
						is_update = 1
					end
				end
			end
			if is_update > 0 then
				local eqid = equip:get_index()
                local equip_data = equip:get_equip_data()
				if is_update == 2 then
					local star_lv = equip_data:get_quality()
					if star_lv >= 9 then
						nice_star = nice_star + 1
					end
				end
                local gem_attrs = equip:get_gem_attrs()
                local diaowen_attrs,diaowen_std_impact,dw_advance_level,dw_featuresid = equip:get_diaowen_attrs()
                if dw_featuresid > 0 then
					local idx = tostring(i)
					self.dw_jinjie_effect[idx] = {id = dw_featuresid,finedraw = dw_advance_level}
				end
                local item_type = equip:get_serial_type()
				local qhlv = equip_data:get_enhancement_level()
				if qhlv > 8 and qhlv < 100 then
					if equip_enhanceex[qhlv] then
						local mdid = define.CHUANCIGONGFANG[i]
						if mdid == 602 then
							self.chuanci = self.chuanci + equip_enhanceex[qhlv].chuangci
						elseif mdid == 603 then
							self.fangchuan = self.fangchuan + equip_enhanceex[qhlv].fangchuan
						end
					end
				end
                for j = 1, equip_data.attr_count do
                    local ef = equip_data.attr_types[j]
                    local ev = self:calc_zengfu_value(equip, ef, require("cys_equipcraft").bonus(equip, ef, equip_data.attr_values[j]))
                    self:cal_item_effect(ef, ev, i, item_type)
                end
                for ia, iv in pairs(gem_attrs) do
                    self:cal_item_effect(ia, iv, i, item_type)
                end
                for ia, iv in pairs(diaowen_attrs) do
                    self:cal_item_effect(ia, iv, i, item_type)
                end
                local base = equip_base[eqid]
                assert(base,eqid)
                if i == define.HUMAN_EQUIP.HEQUIP_ANQI then
                    local val = 32 + ((equip:get_equip_data():get_aq_xiulian() or 1) // 10 - 1) * 85
                    base = { base_attrs = { ["基础外功攻击"] = val, ["基础内功攻击"] = val}, skill_id = define.INVAILD_ID}
                    -- [FIX] 暗器aq_attr五维属性加成
                    local aq_data = equip:get_equip_data()
                    for attr_idx = 1, 5 do
                        local attr_name = define.ANQI_ATTR[attr_idx]
                        local attr_val = aq_data:get_aq_attr(attr_idx)
                        if attr_val and attr_val > 0 then
                            local ia = define.EQUIP_ATTR[attr_name]
                            if ia then
                                self:cal_item_effect(ia, attr_val, i, item_type)
                            end
                        end
                    end
                end
				local isebind = equip:is_ebind()
				local ebind_rate = 0
				if isebind then
					ebind_rate = 10
				end
				local iv_quality,iv_enhance,iv_ebind
                for chn, ia in pairs(define.EQUIP_BASE_ATTRIB) do
                    local iv = base.base_attrs[chn]
                    if iv and iv > 0 then
						iv_enhance = self:cal_enhance_effect(equip, ia, iv)
						iv_ebind = iv * ebind_rate
						iv_ebind = iv_ebind // 100
						iv = iv + iv_enhance + iv_ebind
						iv_quality = self:cal_quality_effect(equip, ia, iv)
						iv = iv + iv_quality
                        iv = self:calc_zengfu_value(equip, ia, iv)
						self:cal_item_effect(ia, iv, i, item_type)
                    end
                end
                if base.skill_id ~= define.INVAILD_ID then
                    self.equip_std_impacts[base.skill_id] = true
                end
                if diaowen_std_impact ~= define.INVAILD_ID then
                    self.equip_std_impacts[diaowen_std_impact] = true
                end
                if i == define.HUMAN_EQUIP.HEQUIP_WUHUN then
                    self:kfs_effect_flush(equip, i, item_type)
                end
                local base_config = equip:get_base_config()
                local set_id = base_config.set_id
                if set_id ~= define.INVAILD_ID then
					local equip_point = base_config.equip_point
					if equip_point == define.HUMAN_EQUIP.HEQUIP_RING_1 or equip_point == define.HUMAN_EQUIP.HEQUIP_RING_2 then
						equip_point = define.HUMAN_EQUIP.HEQUIP_RING_1
					elseif equip_point == define.HUMAN_EQUIP.HEQUIP_AMULET_1 or equip_point == define.HUMAN_EQUIP.HEQUIP_AMULET_2 then
						equip_point = define.HUMAN_EQUIP.HEQUIP_AMULET_1
					end
					equip_sets[set_id] = equip_sets[set_id] or {}
					equip_sets[set_id][equip_point] = true
                end
			end
		end
	end
	local equip_set_attr = configenginer:get_config("equip_set_attr")
    for set_id, set_id_points in pairs(equip_sets) do
        local set = equip_set_attr[set_id]
        if set then
			local count = 0
			for e_point in pairs(set_id_points) do
				count = count + 1
			end
			if set_id == 219 then
				if count >= 3 then
					self.equip_std_impacts[5980] = true
				elseif count >= 2 then
					self.equip_std_impacts[5981] = true
				end
			else
				for i = 1, count do
					local ia = set.IAS[i]
					if ia then
						if ia.IA == 100 then
						
						elseif ia.IA ~= define.INVAILD_ID then
							self:cal_item_effect(ia.IA, ia.IV)
						end
					end
				end
			end
        end
    end
	if nice_star >= 12 then
		for i = IA.IATTRIBUTE_COLD_ATTACK,IA.IATTRIBUTE_POISON_TIME,3 do
			self:cal_item_effect(i,500)
		end
		human:notify_tips("身上除武器、副武器、武魂、暗器外其它的9星装备数量>=12件且都有耐久度，属性攻额外+500。")
	elseif nice_star >= 9 then
		for i = IA.IATTRIBUTE_COLD_ATTACK,IA.IATTRIBUTE_POISON_TIME,3 do
			self:cal_item_effect(i,300)
		end
		human:notify_tips("身上除武器、副武器、武魂、暗器外其它的9星装备数量>=9件且都有耐久度，属性攻额外+400。")
	elseif nice_star >= 6 then
		for i = IA.IATTRIBUTE_COLD_ATTACK,IA.IATTRIBUTE_POISON_TIME,3 do
			self:cal_item_effect(i,200)
		end
		human:notify_tips("身上除武器、副武器、武魂、暗器外其它的9星装备数量>=6件且都有耐久度，属性攻额外+200。")
	elseif nice_star >= 3 then
		for i = IA.IATTRIBUTE_COLD_ATTACK,IA.IATTRIBUTE_POISON_TIME,3 do
			self:cal_item_effect(i,100)
		end
		human:notify_tips("身上除武器、副武器、武魂、暗器外其它的9星装备数量>=3件且都有耐久度，属性攻额外+100。")
	end
end

function human_attrib:common_equip_effect_flush()
	local env = skynet.getenv("env")
	if env == "publish_xrx" then
		self:common_equip_effect_flush_publish_xrx()
		return
	elseif env == "publish_xws" then
		self:common_equip_effect_flush_publish_xws()
		return
	elseif env == "publish_xhz" then
		self:common_equip_effect_flush_publish_xhz()
		return
	end
	local human = self:get_human()
    local container = human:get_equip_container()
	local equip_enhanceex = configenginer:get_config("equip_enhanceex")
    local equip_base = configenginer:get_config("equip_base")
    local equip_sets = {}
    for i = define.HUMAN_EQUIP.HEQUIP_WEAPON, define.HUMAN_EQUIP.HEQUIP_WUHUN do
        local equip = container:get_item(i)
        if equip then
			local equip_data = equip:get_equip_data()
			local is_unavailable = false
			local msg = ""
			if i ~= define.HUMAN_EQUIP.HEQUIP_WUHUN then
				if equip_data:get_dur() <= 0 then
					is_unavailable = true
					msg = "#{DWJJ_240329_346}"
				end
			elseif i == define.HUMAN_EQUIP.HEQUIP_WUHUN then
				if equip_data:get_wh_life() <= 0 then
					is_unavailable = true
					msg = "#{DWJJ_240329_345}"
				end
			end
			if not is_unavailable then
				local eqid = equip:get_index()
                local gem_attrs = equip:get_gem_attrs()
                local diaowen_attrs,diaowen_std_impact,dw_advance_level,dw_featuresid = equip:get_diaowen_attrs()
                if dw_featuresid > 0 then
					local idx = tostring(i)
					self.dw_jinjie_effect[idx] = {id = dw_featuresid,finedraw = dw_advance_level}
				end
				-- human:set_dw_jinjie_effect_details(i,dw_featuresid,dw_advance_level)
				-- local diaowen_std_impact = equip:get_diaowen_std_impact()
                local item_type = equip:get_serial_type()
				local qhlv = equip_data:get_enhancement_level()
				if qhlv > 8 and qhlv < 100 then
					if equip_enhanceex[qhlv] then
						local mdid = define.CHUANCIGONGFANG[i]
						if mdid == 602 then
							self.chuanci = self.chuanci + equip_enhanceex[qhlv].chuangci
						elseif mdid == 603 then
							self.fangchuan = self.fangchuan + equip_enhanceex[qhlv].fangchuan
						end
					end
				end
                for j = 1, equip_data.attr_count do
                    local ef = equip_data.attr_types[j]
                    local ev = self:calc_zengfu_value(equip, ef, require("cys_equipcraft").bonus(equip, ef, equip_data.attr_values[j]))
                    self:cal_item_effect(ef, ev, i, item_type)
                end
                for ia, iv in pairs(gem_attrs) do
                    self:cal_item_effect(ia, iv, i, item_type)
                end
                for ia, iv in pairs(diaowen_attrs) do
                    self:cal_item_effect(ia, iv, i, item_type)
                end
                local base = equip_base[eqid]
                assert(base,eqid)
                if i == define.HUMAN_EQUIP.HEQUIP_ANQI then
                    local val = 32 + ((equip:get_equip_data():get_aq_xiulian() or 1) // 10 - 1) * 85
                    base = { base_attrs = { ["基础外功攻击"] = val, ["基础内功攻击"] = val}, skill_id = define.INVAILD_ID}
                    -- [FIX] 暗器aq_attr五维属性加成
                    local aq_data = equip:get_equip_data()
                    for attr_idx = 1, 5 do
                        local attr_name = define.ANQI_ATTR[attr_idx]
                        local attr_val = aq_data:get_aq_attr(attr_idx)
                        if attr_val and attr_val > 0 then
                            local ia = define.EQUIP_ATTR[attr_name]
                            if ia then
                                self:cal_item_effect(ia, attr_val, i, item_type)
                            end
                        end
                    end
                end
				
				local isebind = equip:is_ebind()
				local ebind_rate = 0
				if isebind then
					ebind_rate = 10
				end
				local iv_quality,iv_enhance,iv_ebind
                for chn, ia in pairs(define.EQUIP_BASE_ATTRIB) do
                    local iv = base.base_attrs[chn]
                    if iv and iv > 0 then
						iv_enhance = self:cal_enhance_effect(equip, ia, iv)
						iv_ebind = iv * ebind_rate
						iv_ebind = iv_ebind // 100
						iv = iv + iv_enhance + iv_ebind
						iv_quality = self:cal_quality_effect(equip, ia, iv)
						iv = iv + iv_quality
						iv = self:calc_zengfu_value(equip, ia, iv)
						self:cal_item_effect(ia, iv, i, item_type)
                    end
                end
                if base.skill_id ~= define.INVAILD_ID then
                    self.equip_std_impacts[base.skill_id] = true
                end
                if diaowen_std_impact ~= define.INVAILD_ID then
                    self.equip_std_impacts[diaowen_std_impact] = true
                end
                if i == define.HUMAN_EQUIP.HEQUIP_WUHUN then
                    self:kfs_effect_flush(equip, i, item_type)
                end
                local base_config = equip:get_base_config()
                local set_id = base_config.set_id
                if set_id ~= define.INVAILD_ID and set_id ~= 219 then
					local equip_point = base_config.equip_point
					if equip_point == define.HUMAN_EQUIP.HEQUIP_RING_1 or equip_point == define.HUMAN_EQUIP.HEQUIP_RING_2 then
						equip_point = define.HUMAN_EQUIP.HEQUIP_RING_1
					elseif equip_point == define.HUMAN_EQUIP.HEQUIP_AMULET_1 or equip_point == define.HUMAN_EQUIP.HEQUIP_AMULET_2 then
						equip_point = define.HUMAN_EQUIP.HEQUIP_AMULET_1
					end
					equip_sets[set_id] = equip_sets[set_id] or {}
					equip_sets[set_id][equip_point] = true
                end
			end
		end
	end
	local equip_set_attr = configenginer:get_config("equip_set_attr")
    for set_id, set_id_points in pairs(equip_sets) do
        local set = equip_set_attr[set_id]
        if set then
			local count = 0
			for e_point in pairs(set_id_points) do
				count = count + 1
			end
			if set_id == 219 then
				-- if count >= 3 then
					-- self.equip_std_impacts[5980] = true
				-- elseif count >= 2 then
					-- self.equip_std_impacts[5981] = true
				-- end
			else
				for i = 1, count do
					local ia = set.IAS[i]
					if ia then
						if ia.IA == 100 then
						
						elseif ia.IA ~= define.INVAILD_ID then
							self:cal_item_effect(ia.IA, ia.IV)
						end
					end
				end
			end
        end
    end
end

function human_attrib:title_new_effect_flush()
    local char_title_new = configenginer:get_config("char_title_new")
    local titles = self:get_human():get_id_titles()
    for _, title in ipairs(titles) do
        local id = title.id
        local config = char_title_new and char_title_new[id]
        for i = 1, config and 6 or 0 do  --- 6 =增加内外功攻击 有的版本是6
            local ia = config.IA[i]
            local iv = config.IV[i]
            if ia and iv and ia >= 0 and iv > 0 then
                self:cal_item_effect(ia, iv, define.INVAILD_ID, define.INVAILD_ID)
            end
        end
    end
end

-- 武境巅峰等级属性加成
function human_attrib:dfeng_effect_flush()
    local human = self:get_human()
    local dfeng_level = human:get_mission_data_by_script_id(961) or 0
    if dfeng_level <= 0 then return end

    local dfeng_level_info = configenginer:get_config("dfeng_level_info")
    if not dfeng_level_info then return end

    for lv = 1, dfeng_level do
        local info = dfeng_level_info[lv]
        if info then
            local ia = info.attr_id
            local iv = info.attr_value
            if ia and iv and ia >= 0 and iv > 0 then
                self:cal_item_effect(ia, iv, define.INVAILD_ID, define.INVAILD_ID)
            end
        end
    end
end

-- 心络孔位五行攻击加成（加到att_cold/fire/light/poison，人物面板自动显示）
-- active: 1=专脉→attr_bonus, 2=二脉→attr_value1, 3=三脉→attr_value2, 4=四属性→attr_value3
-- 元素选择从 MD 976-985 读取
function human_attrib:dfeng_essence_effect_flush()
    local human = self:get_human()
    local kw_info = configenginer:get_config("dfeng_essence_kw_info")
    if not kw_info then return end

    local kw_attack = {0, 0, 0, 0}  -- 1=冰 2=火 3=玄 4=毒
    local bonus_fields = { "attr_bonus", "attr_value1", "attr_value2", "attr_value3" }
    for i = 1, 20 do
        local level = human:get_dfeng_kw_slot_level(i)
        local active = human:get_dfeng_kw_slot_active(i)
        if level > 0 and active >= 1 and active <= 4 and kw_info[i] then
            local cfg = kw_info[i][level]
            local bonus_field = bonus_fields[active]
            if cfg and bonus_field and cfg[bonus_field] then
                local bonus = cfg[bonus_field]
                local sel1, sel2, sel3 = human:get_dfeng_kw_slot_attrs(i)
                if active == 1 then
                    if sel1 >= 1 and sel1 <= 4 then kw_attack[sel1] = kw_attack[sel1] + bonus end
                elseif active == 2 then
                    if sel1 >= 1 and sel1 <= 4 then kw_attack[sel1] = kw_attack[sel1] + bonus end
                    if sel2 >= 1 and sel2 <= 4 then kw_attack[sel2] = kw_attack[sel2] + bonus end
                elseif active == 3 then
                    if sel1 >= 1 and sel1 <= 4 then kw_attack[sel1] = kw_attack[sel1] + bonus end
                    if sel2 >= 1 and sel2 <= 4 then kw_attack[sel2] = kw_attack[sel2] + bonus end
                    if sel3 >= 1 and sel3 <= 4 then kw_attack[sel3] = kw_attack[sel3] + bonus end
                elseif active == 4 then
                    for e = 1, 4 do kw_attack[e] = kw_attack[e] + bonus end
                end
            end
        end
    end

    local attr_map = {
        IA.IATTRIBUTE_COLD_ATTACK,
        IA.IATTRIBUTE_FIRE_ATTACK,
        IA.IATTRIBUTE_LIGHT_ATTACK,
        IA.IATTRIBUTE_POISON_ATTACK,
    }
    for i = 1, 4 do
        if kw_attack[i] > 0 then
            self:cal_item_effect(attr_map[i], kw_attack[i], define.INVAILD_ID, define.INVAILD_ID)
        end
    end
end

-- 通脉等级属性加成（MD 962 通脉等级，读DFengEssence.txt配置）
function human_attrib:dfeng_essence_level_effect_flush()
    local human = self:get_human()
    local essence_level = human:get_mission_data_by_script_id(962) or 0
    if essence_level <= 0 then return end

    local essence_info = configenginer:get_config("dfeng_essence_info")
    if not essence_info then return end

    for lv = 1, essence_level do
        local info = essence_info[lv]
        if info then
            local ia = info.attr_id
            local iv = info.attr_value
            if ia and iv and ia >= 0 and iv > 0 then
                self:cal_item_effect(ia, iv, define.INVAILD_ID, define.INVAILD_ID)
            end
        end
    end
end

function human_attrib:shenbing_equio_effect_flush()
    local equip_base = configenginer:get_config("equip_base")
    local shenbing_level = configenginer:get_config("shenbing_level")
	local equip_enhanceex = configenginer:get_config("equip_enhanceex")
    local container = self:get_human():get_equip_container()
    local equip = container:get_item(define.HUMAN_EQUIP.SHENBING)
    if equip then
		local equip_data = equip:get_equip_data()
        local dur = equip_data:get_dur()
        if dur > 0 then
            local raw_data = equip:copy_raw_data()
            local gem_attrs = equip:get_gem_attrs()
            local item_type = equip:get_serial_type()
			local diaowen_attrs,diaowen_std_impact,dw_advance_level,dw_featuresid = equip:get_diaowen_attrs()
			if dw_featuresid > 0 then
				local idx = tostring(i)
				self.dw_jinjie_effect[idx] = {id = dw_featuresid,finedraw = dw_advance_level}
			end
            -- local diaowen_attrs = equip:get_diaowen_attrs()
            local zhuqing = raw_data.fwq_zhuqing or 1
			local qhlv = equip_data:get_enhancement_level()
			if qhlv > 8 and qhlv < 100 and equip_enhanceex[qhlv] then
				local mdid = define.CHUANCIGONGFANG[define.HUMAN_EQUIP.SHENBING]
				if mdid == 602 then
					self.chuanci = self.chuanci + equip_enhanceex[qhlv].chuangci
				elseif mdid == 603 then
					self.fangchuan = self.fangchuan + equip_enhanceex[qhlv].fangchuan
				end
			end
            shenbing_level = shenbing_level[zhuqing]
            for j = 1, 6 do
                local ef = raw_data.fwq_attrs[j]
                local chn = define.CHN_ATTR_SHIFT[ef]
                local ev = shenbing_level[chn] or 0
                self:cal_item_effect(ef, ev, define.HUMAN_EQUIP.SHENBING, item_type)
            end
            for ia, iv in pairs(gem_attrs) do
                self:cal_item_effect(ia, iv, define.HUMAN_EQUIP.SHENBING, item_type)
            end
            for ia, iv in pairs(diaowen_attrs) do
                self:cal_item_effect(ia, iv, define.HUMAN_EQUIP.SHENBING, item_type)
            end
            local base = equip_base[equip:get_index()]
            assert(base, equip:get_index())
			local isebind = equip:is_ebind()
			local ebind_rate = 0
			if isebind then
				ebind_rate = 10
			end
			local iv_quality,iv_enhance,iv_ebind
            for chn, ia in pairs(define.EQUIP_BASE_ATTRIB) do
                local iv = base.base_attrs[chn]
                if iv and iv > 0 then
					iv_enhance = self:cal_enhance_effect(equip, ia, iv)
					-- iv_ebind = iv * ebind_rate + 50
					iv_ebind = iv * ebind_rate
					iv_ebind = iv_ebind // 100
					iv = iv + iv_enhance + iv_ebind
					iv_quality = self:cal_quality_effect(equip, ia, iv)
					iv = iv + iv_quality
                    self:cal_item_effect(ia, iv, define.HUMAN_EQUIP.SHENBING, item_type)
                end
            end
        end
    end
end

function human_attrib:lingwu_equip_effect_flush()
    local container = self:get_human():get_equip_container()
    local ling_yu_base = configenginer:get_config("ling_yu_base")
    local ling_yu_set = configenginer:get_config("ling_yu_set")
    local ling_yu_set_effect = configenginer:get_config("ling_yu_set_effect")
    local ling_yu_sets = {}
    for i = define.HUMAN_EQUIP.LINGWU_JING, define.HUMAN_EQUIP.LINGWU_DI do
        local equip = container:get_item(i)
        if equip and not require('cy_equipment_passives').kind(equip:get_index()) then
            local item_index = equip:get_index()
            local raw_data = equip:copy_raw_data()
            local item_type = equip:get_serial_type()
            local base = ling_yu_base[item_index]
            for j, ia in pairs(base.base_attr_keys) do
                if ia ~= define.INVAILD_ID then
                    local iv = base.base_attr_values[j]
                    self:cal_item_effect(ia, iv, i, item_type)
                end
            end
            local ling_yu_attrs_enhancement_level = raw_data.ling_yu_attrs_enhancement_level
            for j, ia in ipairs(raw_data.ling_yu_attrs) do
                if ia ~= define.INVAILD_ID then
                    local iv = raw_data.ling_yu_attr_values[j]
                    local el = 0
                    if ling_yu_attrs_enhancement_level and ling_yu_attrs_enhancement_level[j] then
                        el = ling_yu_attrs_enhancement_level[j]
                    end
                    iv = math.floor(iv * (10000 + el) / 10000)
                    self:cal_item_effect(ia, iv, i, item_type)
                end
            end
            local set = ling_yu_sets[base.set] or { count = 0, min_cls = 4}
            set.count = set.count + 1
            set.min_cls = base.class < set.min_cls and set.min_cls or base.class
            ling_yu_sets[base.set] = set
        end
    end
    local set_ids = {}
    for set, c in pairs(ling_yu_sets) do
        local sc = ling_yu_set[set]
        if c.count >= 3 then
            table.insert(set_ids, sc.id[1] + c.min_cls - 1)
        end
        if c.count >= 6 then
            table.insert(set_ids, sc.id[5] + c.min_cls - 1)
        end
    end
    for _, id in ipairs(set_ids) do
        local effects = ling_yu_set_effect[id]
        for i, ia in ipairs(effects.ias) do
            if ia ~= define.INVAILD_ID then
                local iv = effects.ivs[i]
                self:cal_item_effect(ia, iv)
            end
        end
        if effects.add_impact ~= define.INVAILD_ID then
            self.equip_std_impacts[effects.add_impact] = true
        end
        if effects.add_skill ~= define.INVAILD_ID then
           self.equip_add_skills[effects.add_skill] = true
        end
    end
end

function human_attrib:get_chuanci()
	return self.chuanci
end

function human_attrib:get_fangchuan()
	return self.fangchuan
end

function human_attrib:item_effect_flush()
	self.chuanci = 0
	self.fangchuan = 0
	self.damage_rate = 0
	self.sub_damage_rate = 0
    self:instant_mastery_skills()
    self.item_effect = {}
    self.equip_std_impacts = {}
    self.equip_add_skills = {}
    self.dw_jinjie_effect = {}
    self:common_equip_effect_flush()
    require("cys_shending").attributes(self)
    local lw=self:get_human():get_equip_container():get_item(19)
    if lw then require('cy_equipment_passives').apply_attributes(self,lw,19) end
    self:lingwu_equip_effect_flush()
    self:pet_soul_melting_effect()
    self:shenbing_equio_effect_flush()
    self:title_new_effect_flush()
    self:dfeng_effect_flush()
    self:dfeng_essence_effect_flush()
    self:dfeng_essence_level_effect_flush()
	local human = self:get_human()
	human:set_dw_jinjie_effect(self.dw_jinjie_effect)
	
	
	human:set_mission_data_by_script_id(602,self.chuanci)
	human:set_mission_data_by_script_id(603,self.fangchuan)
    skynet.fork(function()
        for impact in pairs(self.equip_std_impacts) do
            impactenginer:send_impact_to_unit(human, impact, human, 0, false, 0)
        end
    end)
	local effect_value,feature_rate = human:get_dw_jinjie_effect_details(4)
	local value
	if effect_value > 0 then
		effect_value = effect_value / feature_rate
		self.dirty_flags["attrib_def_physics"] = true
		self.dirty_flags["level"] = true
		self.dirty_flags["con"] = true
		value = self:get_attrib("attrib_def_physics") or 0
		if value > 0 then
			value = math.ceil(value * effect_value / 100)
			self:cal_item_effect(IA.IATTRIBUTE_DEFENCE_P,0 - value)
			self:cal_item_effect(IA.IATTRIBUTE_ATTACK_P,value)
			-- human:features_effect_notify_client(4)
		end
	end
	effect_value,feature_rate = human:get_dw_jinjie_effect_details(5)
	if effect_value > 0 then
		effect_value = effect_value / feature_rate
		self.dirty_flags["attrib_def_magic"] = true
		self.dirty_flags["level"] = true
		self.dirty_flags["int"] = true
		value = self:get_attrib("attrib_def_magic") or 0
		if value > 0 then
			value = math.ceil(value * effect_value / 100)
			self:cal_item_effect(IA.IATTRIBUTE_DEFENCE_M,0 - value)
			self:cal_item_effect(IA.IATTRIBUTE_ATTACK_M,value)
			-- human:features_effect_notify_client(5)
		end
	end
	local imp = human:impact_get_first_impact_of_specific_class_id(99)
	if not imp then
		local effect_value,feature_rate = human:get_dw_jinjie_effect_details(11)
		if effect_value > 0 then
			effect_value = effect_value // feature_rate
			self:cal_item_effect(IA.IATTRIBUTE_SPEED_RATE,effect_value)
			-- human:features_effect_notify_client(11)
		end
	end
	-- 重新应用经脉加成（避免穿脱装备后经脉属性丢失）
    local jingmai_bonus = self.db_attribs["jingmai_attr_bonus"]
    if type(jingmai_bonus) == "table" then
        for ia, val in pairs(jingmai_bonus) do
            local ia_num = tonumber(ia)
            local value = tonumber(val) or 0
            if ia_num and value ~= 0 then
                self:cal_item_effect(ia_num, value)
            end
        end
    end
    -- Reapply persistent GM bonuses after every attribute rebuild.
    local gm_bonus = self.db_attribs["gm_attr_bonus"]
    if type(gm_bonus) == "table" then
        for ia, val in pairs(gm_bonus) do
            local ia_num = tonumber(ia)
            local value = tonumber(val) or 0
            if ia_num and value ~= 0 then
                self:cal_item_effect(ia_num, value)
            end
        end
    end
    self:mark_all_attr_dirty()
end

function human_attrib:get_equip_add_skills()
    return self.equip_add_skills
end

function human_attrib:get_lv1_attrib()
    return self.lv1_attribs
end

function human_attrib:get_base_attrib(key)
    --print("human_attrib:get_base_attrib(key)", key)
    if lv1_attribs[key] then
        return self.lv1_attribs[key]
    elseif not_gen_attribs[key] and self.not_gen_attribs[key] ~= nil then
        return self.not_gen_attribs[key]
    elseif db_attribs[key] then
        return self.db_attribs[key]
    elseif menpai_attribs[key] then
        local base = 0
        local menpai = self.db_attribs.menpai
        local base_value_table = configenginer:get_config("base_value_table")
        local menpai_key = string.format("MENPAI%d", menpai)
        local menpai_base_value = base_value_table[menpai_key]
		--menpai_base_value = AINFOTYPE0 - AINFOTYPE41
        local influence = menpai_logic.influence[key]
        if influence then
            local init_key = influence.init
            local init_value = menpai_base_value[init_key]
            base = init_value
            for k, value in pairs(influence) do
                if k ~= "init" then
                    local influce_key = value
                    local influce_value = menpai_base_value[influce_key]
                    base = base + influce_value * self:get_attrib(k)
                end
            end
            base = math.ceil(base / 100)
            if must_be_positive[key] then
                assert(base >= 0)
            end
        end
        return base
    else
        return self.attribs[key]
    end
end

function human_attrib:get_xiulian_base_attrib(key)
    if lv1_attribs[key] then
        return self.lv1_attribs[key]
    elseif menpai_attribs[key] then
        local base = 0
        local menpai = self.db_attribs.menpai
        local base_value_table = configenginer:get_config("base_value_table")
        local menpai_key = string.format("MENPAI%d", menpai)
        local menpai_base_value = base_value_table[menpai_key]
        local influence = menpai_logic.influence[key]
        if influence then
            local init_key = menpai_logic.influence[key].init
            local init_value = menpai_base_value[init_key]
            base = init_value
            for k, value in pairs(menpai_logic.influence[key] or {}) do
                if k ~= "init" then
                    local influce_key = value
                    local influce_value = menpai_base_value[influce_key]
                    base = base + influce_value * self:get_xiulian_base_attrib(k)
                end
            end
            base = math.ceil(base / 100)
            if must_be_positive[key] then
                assert(base >= 0)
            end
        end
        return base
    else
        return self:get_base_attrib(key)
    end
end

function human_attrib:set_attrib_refix(key, value)
    self.attribs_refix[key] = value
end

function human_attrib:get_exist_attrib_refix(key)
    return self.attribs_refix[key]
end

function human_attrib:get_attrib_refix_dirty(key)
    return self.refix_dirty_flags[key]
end

-- transform-model 17/09: còn ô refix nào đang bẩn không?
-- `character:remove_impact` dùng cờ này để biết có cần gửi lại thuộc tính sau khi GỠ impact hay không.
-- `character:on_impact_fade_out` gọi `send_refresh_attrib` KHI impact VẪN CÒN trong danh sách, nên các thuộc tính
-- kiểu `replace` (model_id/ride_model/can_move/stealth_level…) vẫn tính ra giá trị CỦA LÚC CÒN BUFF; chỉ sau
-- `remove_impact` mới có giá trị đúng. Xem `Docs/specs/server/impact-data_vi.md` mục 9.
function human_attrib:has_attrib_refix_dirty()
    return next(self.refix_dirty_flags) ~= nil
end

function human_attrib:clear_attrib_refix_dirty(key)
    self.refix_dirty_flags[key] = nil
end

function human_attrib:mark_attrib_refix_dirty(key)
    self.refix_dirty_flags[key] = true
    local influence = attrib_influences[key]
    if influence then
        for skey in pairs(influence) do
            self:mark_attrib_refix_dirty(skey)
        end
    end
end

function human_attrib:imp_get_attrib_refix(key)
    local value = {}
    local human = self:get_human()
    local impacts = human:get_impact_list()
    for _, imp in ipairs(impacts) do
        local logic = impactenginer:get_logic(imp)
        if logic then
            logic:get_refix(imp, key, value, human)
        end
    end
    return value
end

function human_attrib:get_attrib_refix(key)
    if self:get_attrib_refix_dirty(key) then
        local value = self:imp_get_attrib_refix(key)
        self:set_attrib_refix(key, value)
        self:clear_attrib_refix_dirty(key)
    end
    return self:get_exist_attrib_refix(key)
end

function human_attrib:get_xiulian_bonus_base_val(key)
    if key == "str" or key == "spr" or key == "con" or key == "int" or key == "dex" then
        return self:get_xiulian_base_attrib(key)
    else
        return self:get_xiulian_base_attrib(key)
    end
end

function human_attrib:xiulian_bonus(key)
    local bonus_conf = xiulian_bonus[key]
    if bonus_conf then
        local min_xinfa_level = self.human:get_min_xinfa_level()
        local xiuluan_rate = configenginer:get_config("xiulian_rate")
        local rate = xiuluan_rate[min_xinfa_level]
        if rate then
            local val = self:get_xiulian_bonus_base_val(key)
            local bonus = val * rate["比例"][1] / 100 * self:get_xiulian_bonus(bonus_conf.index)
            bonus = math.ceil(bonus*2)
            self:set_attrib({ [bonus_conf.key] = bonus})
            return bonus
        end
    end
    return 0
end

function human_attrib:get_xiulian_bonus(mjid)
    local menpai = self.human:get_menpai()
    local xiulian_level = self.human:get_xiulian_level(mjid)
    local xiulian_detail = configenginer:get_config("xiulian_detail")
    for _, details in ipairs(xiulian_detail) do
        if details.BOOKLEVEL == xiulian_level and details.BOOKID == menpai then
            return details[mjid].bonus
        end
    end
    return 0
end

function human_attrib:get_attrib(key)
    if self:get_dirty_flags(key) then
        local value
        local base = self:get_base_attrib(key)
        if refix_by_other[key] then
            base = refix_by_other[key](self, base)
        end
        value = base
        if type(base) == "number" then
            base = base + self:xiulian_bonus(key)
            local item_point_base = 0
            local item_point_refix = 0
            local item_rate_refix = 0
            local impact_skill_refix
            local ie_shfit = item_effct_shift[key]
			if ie_shfit then
				if ie_shfit.base then
					local ie = self:get_item_effect(ie_shfit.base)
					if ie then
						item_point_base = ie
					end
				end
				if ie_shfit.point then
					local ie = self:get_item_effect(ie_shfit.point)
					if ie then
						item_point_refix = ie
					end
				end
				if ie_shfit.rate then
					local ie = self:get_item_effect(ie_shfit.rate)
					if ie then
						item_rate_refix = math.ceil(base * (ie / 100))
					end
				end
			end
            -- 外观属性加成（时装/坐骑/武器外观）
            local ext = exterior_bonus.get_bonus(self:get_human())
            if ext then
                local ext_attr = ext[key]
                if ext_attr then
                    if ext_attr.point then
                        base = base + ext_attr.point
                    end
                    if ext_attr.rate then
                        base = math.ceil(base * (100 + ext_attr.rate) / 100)
                    end
                end
            end
            if key == "hp_max" then
                base = base + equip_dress_bonus.get_xiuyi_hp_bonus(self:get_human())
            end
            if key == "speed" then
                local huayu_speed_rate = ride_huayu_bonus.get_ride_speed_rate(self:get_human())
                if huayu_speed_rate and huayu_speed_rate > 0 then
                    base = math.ceil(base * (100 + huayu_speed_rate) / 100)
                end
            end
            impact_skill_refix = self:get_attrib_refix(key)
			if impact_skill_refix then
				if impact_skill_refix.rate then
					base = math.ceil(base * (100 + impact_skill_refix.rate) / 100)
				end
				if impact_skill_refix.item_point_refix_rate then
					if item_point_refix > 0 then
						item_point_refix = math.ceil(item_point_refix * (100 + impact_skill_refix.item_point_refix_rate) / 100)
					end
				end
				if impact_skill_refix.point then
					impact_skill_refix.point = impact_skill_refix.point or 0
					base = base + impact_skill_refix.point
				end
				if impact_skill_refix.replace then
					value = impact_skill_refix.replace
				else
					value = base + item_point_base + item_point_refix + item_rate_refix
				end
			else
				value = base + item_point_base + item_point_refix + item_rate_refix
			end
			if must_be_positive[key] and value < 0 then
				value = 0
			end
        end
        --print("key =", key)
        if replace_by_other[key] then
            value = replace_by_other[key](self, value)
        end
        self:set_attrib({[key] = value})
        self:clear_dirty_flag(key)
    end
    return self:get_exist_attrib(key)
end


function human_attrib:get_attrib_bffff(key)
    if not self:get_dirty_flags(key) then
        return self:get_exist_attrib(key)
    end
	
	local value
	local base = self:get_base_attrib(key)
	if refix_by_other[key] then
		base = refix_by_other[key](self, base)
	end
	value = base
	if type(base) == "number" then
		base = base + self:xiulian_bonus(key)
		local item_point_base = 0
		local item_point_refix = 0
		local item_rate_refix = 0
		local ie_shfit = item_effct_shift[key]
		if ie_shfit then
			if ie_shfit.base then
				item_point_base = self:get_item_effect(ie_shfit.base) or 0
			end
			if ie_shfit.point then
				item_point_refix = self:get_item_effect(ie_shfit.point) or 0
			end
			if ie_shfit.rate then
				item_rate_refix = math.ceil(base * (self:get_item_effect(ie_shfit.rate) or 0 / 100))
			end
		end
		local impact_skill_refix = self:get_attrib_refix(key)
		if impact_skill_refix then
			if impact_skill_refix.replace then
				value = impact_skill_refix.replace
			else
				if impact_skill_refix.rate then
					base = math.ceil(base * (100 + impact_skill_refix.rate) / 100)
				end
				if impact_skill_refix.item_point_refix_rate then
					item_point_refix = math.ceil(item_point_refix * (100 + impact_skill_refix.item_point_refix_rate) / 100)
				end
				if impact_skill_refix.point then
					impact_skill_refix.point = impact_skill_refix.point
					base = base + impact_skill_refix.point
				end
				value = base + item_point_base + item_point_refix + item_rate_refix
			end
		else
			value = base + item_point_base + item_point_refix + item_rate_refix
		end
		if must_be_positive[key] and value < 0 then
			value = 0
		end
		-- value = math.ceil(value)
	end
	--print("key =", key)
	if replace_by_other[key] then
		value = replace_by_other[key](self, value)
	end
	self:set_attrib({[key] = value})
	self:clear_dirty_flag(key)
end

function human_attrib:get_exist_attrib(key)
    local value = self.attribs[key] or self.db_attribs[key]
    return value
end

function human_attrib:set_attrib(set_list)
    for key, value in pairs(set_list) do
        local old = self:get_exist_attrib(key)
        --print("human_attrib:set_attrib key =", key, ";value =", value, ";old =", old, ";tbl =", self.attribs)
        if old ~= value or self.attribs[key] == nil then
            self:mark_data_dirty_flag(key)
        end
        self.attribs[key] = value
        if db_save_attribs[key] then
            self:set_db_attrib({ [key] = value})
        end
        if base_attribs[key] and self.base_attribs then
            self.base_attribs[key] = value
        end
        if detail_attribs[key] and self.detail_attribs then
            self.detail_attribs[key] = value
        end
    end
end

function human_attrib:get_base_attribs()
    if self.base_attribs == nil then
        self.base_attribs = self:full_get_base_attribs()
    end
    return self.base_attribs
end

function human_attrib:full_get_base_attribs()
    local ret = {}
    for key in pairs(base_attribs) do
        ret[key] = self:get_attrib(key)
    end
    return ret
end

function human_attrib:get_detail_attribs()
    if self.detail_attribs == nil then
        self.detail_attribs = self:full_get_detail_attribs()
    end
    return self.detail_attribs
end

function human_attrib:full_get_detail_attribs()
    local ret = {}
    for key in pairs(detail_attribs) do
        ret[key] = self:get_attrib(key)
    end
    return ret
end

function human_attrib:get_db_attrib(key)
    return self.db_attribs[key]
end

function human_attrib:get_db_save_attrib()
    return self.db_attribs
end

function human_attrib:get_human()
    return self.human
end

function human_attrib:set_lv1_attrib(set_list)
    for key, value in pairs(set_list) do
        self:mark_attrib_dirty(key)
        self.lv1_attribs[key] = value
    end
end

function human_attrib:set_db_attrib(set_list)
    set_list = require('cys_currency').update(self.db_attribs,set_list)
    for key, value in pairs(set_list) do
        self:mark_attrib_dirty(key)
        local old = self:get_exist_attrib(key)
        if old ~= value then
            self:mark_data_dirty_flag(key)
        end
        if type(value) == "table" then
            local tbl = table.clone(value)
            self.db_attribs[key] = tbl
        else
            self.db_attribs[key] = value
        end
        -- 同步更新 base_attribs 缓存（如果缓存存在）
        if base_attribs[key] and self.base_attribs then
            self.base_attribs[key] = value
        end
    end
end

function human_attrib:set_not_gen_attrib(set_list)
    for key, value in pairs(set_list) do
        self:mark_attrib_dirty(key)
        local old = self:get_exist_attrib(key)
        if old ~= value then
            self:mark_data_dirty_flag(key)
        end
        self.not_gen_attribs[key] = value
    end
end

function human_attrib:set_db_attrib_nil(key)
    self:mark_attrib_dirty(key)
    local old = self:get_exist_attrib(key)
    if old ~= nil then
        self:mark_data_dirty_flag(key)
    end
    self.db_attribs[key] = nil
end

function human_attrib:refresh_dirty_attribs()
    local dirty_flags = {}
    for key in pairs(self.dirty_flags) do
        dirty_flags[key] = true
    end
    for key in pairs(self.refix_dirty_flags) do
        dirty_flags[key] = true
    end
    for key in pairs(dirty_flags) do
        self:get_attrib(key)
    end
end

function human_attrib:send_refresh_attrib(update_flag)
	local human = self.human
	if not human then
		return
	end
    if not human:is_begin_send_refresh_attrib() then
        return
    end
    self:refresh_dirty_attribs()
    if human and human:get_character_logic() == define.ENUM_CHARACTER_LOGIC.CHARACTER_LOGIC_MOVE then
        local can_move = self:get_attrib("can_move")
        if can_move == 0 then
            human:stop_character_logic(true)
        end
    end
    local send_refresh_base_attrib = false
    local send_refresh_detail_attrib = false
    local refresh_base_attrib
    local refresh_detail_attrib
    local attackers_list = human:get_attackers()
    local pk_declaration_list = human:get_pk_declaration_list()
    local wild_war_guilds = human:get_wild_war_guilds()
    if next(self.dirty_datas) 
	or attackers_list:is_dirty() 
	or pk_declaration_list:is_dirty() 
	or wild_war_guilds:is_dirty()
	or update_flag == "dw_jinjie" then
        refresh_base_attrib = packet_def.GCCharBaseAttrib.new()
        refresh_detail_attrib = packet_def.GCDetailAttrib.new()
		--flagwg
		local fn,f,value
        for key in pairs(self.dirty_datas) do
			fn = string.format("set_%s", key)
			value = self:get_attrib(key)
			if key == "hp" then
				local hp_percent = math.ceil(value / self:get_attrib("hp_max") * 100)
				refresh_base_attrib:set_hp_percent(hp_percent)
				send_refresh_base_attrib = true
			elseif key == "hp_max" then
				local hp_percent = math.ceil(self:get_attrib("hp") / value * 100)
				refresh_base_attrib:set_hp_percent(hp_percent)
				send_refresh_base_attrib = true
			elseif key == "mp" then
				local mp_percent = math.ceil(value / self:get_attrib("mp_max") * 100)
				refresh_base_attrib:set_mp_percent(mp_percent)
				send_refresh_base_attrib = true
			elseif key == "mp_max" then
				local mp_percent = math.ceil(self:get_attrib("mp") / value * 100)
				refresh_base_attrib:set_mp_percent(mp_percent)
				send_refresh_base_attrib = true
			elseif key == "stall_is_open" then
				refresh_base_attrib:set_stall_is_open(value)
				refresh_base_attrib:set_stall_name(self:get_attrib("stall_name"))
				send_refresh_base_attrib = true
			elseif key == "raid_id" then
				refresh_base_attrib:set_raid_id(value)
				refresh_base_attrib:set_raid_position(self:get_attrib("raid_position"))
				refresh_base_attrib:set_raid_is_full(self:get_attrib("raid_is_full"))
				send_refresh_base_attrib = true
			elseif key == "raid_position" then
				refresh_base_attrib:set_raid_position(value)
				refresh_base_attrib:set_raid_id(self:get_attrib("raid_id"))
				refresh_base_attrib:set_raid_is_full(self:get_attrib("raid_is_full"))
				send_refresh_base_attrib = true
			elseif key == "raid_is_full" then
				refresh_base_attrib:set_raid_is_full(value)
				refresh_base_attrib:set_raid_id(self:get_attrib("raid_id"))
				refresh_base_attrib:set_raid_position(self:get_attrib("raid_position"))
				send_refresh_base_attrib = true
			elseif key == "is_in_team" then
				refresh_base_attrib:set_is_in_team(value)
				refresh_base_attrib:set_is_team_leader(self:get_attrib("is_team_leader"))
				send_refresh_base_attrib = true
			elseif key == "is_team_leader" then
				refresh_base_attrib:set_is_in_team(self:get_attrib("is_in_team"))
				refresh_base_attrib:set_is_team_leader(value)
				send_refresh_base_attrib = true
			elseif key == "stealth_level" then
				refresh_base_attrib:set_stealth_level(value)
				send_refresh_base_attrib = true
				human:stealth_level_update()
			elseif key == "detect_level" then
				-- refresh_base_attrib:set_detect_level(value)
				-- send_refresh_base_attrib = true
				human:detect_level_update()
			else
				f = refresh_base_attrib[fn]
				if f then
					f(refresh_base_attrib,value)
					send_refresh_base_attrib = true
				end
			end
			f = refresh_detail_attrib[fn]
			if f then
				f(refresh_detail_attrib,value)
				send_refresh_detail_attrib = true
			end
            self:clear_data_dirty_flag(key)
        end
        if attackers_list:is_dirty() then
            attackers_list:clear_dirty()
            refresh_base_attrib:set_attackers_list(attackers_list.list)
            refresh_detail_attrib:set_attackers_list(attackers_list.list)
            send_refresh_base_attrib = true
            send_refresh_detail_attrib = true
        end
        if pk_declaration_list:is_dirty() then
            pk_declaration_list:clear_dirty()
            refresh_base_attrib:set_pk_declaration_list(pk_declaration_list.list)
            refresh_detail_attrib:set_pk_declaration_list(pk_declaration_list.list)
            send_refresh_base_attrib = true
            send_refresh_detail_attrib = true
        end
        if wild_war_guilds:is_dirty() then
            wild_war_guilds:clear_dirty()
            refresh_base_attrib:set_wild_war_guilds(wild_war_guilds.list)
            send_refresh_base_attrib = true
        end
		if update_flag == "dw_jinjie" then
			refresh_detail_attrib:set_Features_list(human:get_dw_jinjie_features())
			send_refresh_detail_attrib = true
		end
    end
    if send_refresh_base_attrib then
        local data_id = human:inc_data_id()
        refresh_base_attrib:set_data_id(data_id)
        local title = self:get_attrib("title")
        if title then
            title.is_hide = human:get_title_is_hide()
            refresh_base_attrib:set_title(title)
        end
        refresh_base_attrib.m_objID = human:get_obj_id()
        human:get_scene():broadcast(human, refresh_base_attrib, true)
    end
    if send_refresh_detail_attrib then
        refresh_detail_attrib.m_objID = human:get_obj_id()
        human:get_scene():send2client(human, refresh_detail_attrib)
    end
end

return human_attrib
