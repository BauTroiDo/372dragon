local skynet = require "skynet"
local sharetable = require "skynet.sharetable"
local class = require "class"
local configenginer = class("configenginer")
local configs = {
    "scene_info",
    "skill_template",
    "skill_data",
    "exterior_ride",
    "scene_attr",
    "equip_base",
    "common_item",
    "gem_info",
    "exp_attenuation",
    "monster_drop_boxs",
    "drop_box_content",
    "config_info",
    "item_ruler",
    "item_seg_affect",
    "item_seg_quality",
    "item_seg_rate",
    "item_seg_value",
    "attck_traits",
    "monster_ai_table",
    "exterior_ride",
    "impact_se_data",
    "player_exp_level",
    "attr_level_up_table",
    "base_value_table",
    "xinfa_v1",
    "xinfa_study_speed_v1",
    "id_collections",
    "shop_table",
    "slot_cost",
    "gem_carve",
    "gem_melting",
    "double_gem_compound",
    "item_compound",
    "ability",
    "dress_color_rate",
    "exterior_head",
    "exterior_face",
    "exterior_hair",
    "char_face_geo",
    "char_hair_geo",
    "equip_extra_attr",
    "pet_attr_table",
    "pet_collection",
    "monster_attr_ex",
    "pet_config_table",
    "cy_pet_rules_data",
    "pet_attr_point_distribute",
    "pet_skill_distribute",
    "pet_skill_index_table",
    "pet_ai_stratety_table",
    "camp_and_stand",
    "pet_level_up_table",
    "pet_apperceive_skill_table",
    "dark_exp_level",
    "dark_skill_list",
    "pet_skill_book",
    "pet_study_skill_table",
    "pet_huan_hua_table",
    "pet_equip_base",
    "pet_jl",
    "pet_jl_attr",
    "pet_elf_skill",
    "pet_soul_level_up_info",
    "pet_soul_extension",
    "pet_soul_base",
    "pet_soul_level_cost",
    "pet_equip_suit_up_info",
    "pet_equip_set_attr",
    "special_obj_data",
    "item_enhance",
    "diaowen_info",
    "diaowen_rule",
    "kfs_base",
    "kfs_slot",
    "kfs_attr_ex_book",
    "kfs_attr_ext",
    "kfs_level_up_exp",
    "kfs_skill_level_up",
    "item_apt_rate",
    "std_impact_config",
    "pet_soul_skill",
    "kfs_level_up",
    "wuhun_wg",
    "wuhun_wg_level",
    "pvp_rule",
    "activity_notice",
    "activity_ruler",
    "ling_yu_base",
    "ling_yu_attr_rule",
    "ling_yu_attr_value",
    "ling_yu_set",
    "ling_yu_set_effect",
    "drop_notify",
    "scene_define_ex",
    "ai_script_dat",
    "lv_max_money",
    "ability_level_up_zhuzao",
    "ability_level_up_diaoyu",
    "ability_level_up_caiyao",
    "ability_level_up_caikuang",
    "ability_level_up_dingweifu",
    "ability_level_up_fengren",
    "ability_level_up_pengren",
    "ability_level_up_yangsheng",
    "ability_level_up_yaoli",
    "ability_level_up_zhongzhi",
    "ability_level_up_assistant_menpai",
    "ability_level_up_assistant",
    "ability_level_up_cailiaojiagong",
    "ability_level_up_gaojishenghuo",
    "ability_level_up_gongyi",
    "ability_level_up_menpai",
    "ability_level_up_menpaifuzhu",
    "ability_level_up_normal",
    "ability_level_up_putongshenghuo",
    "ability_level_up_shenghuofuzhu",
    "ability_level_up_xiangqian",
    "ability_level_up_zhiyao",
    "ability_level_up_dingweifu",
    "super_weapon_up",
    "exterior_weapon_visual",
    "char_title",
    "scripts",
    "xiulian_rate",
    "xiulian_detail",
    "sect_info",
    "week_active",
    "menpaishenghuo",
    "die_penalty",
    "sect_desc",
    "questions",
    "grow_point",
    "bus_info",
    "city_info",
    "city_building",
    "guild_war_point",
    "char_title_new",
    "pet_title",
    "mission_loot_item",
    "mission_delivery",
    "mission_enter_area",
    "mission_husong",
    "mission_kill_monster",
    "drop_rate_of_item_table",
    "stiry_telling_duo_logue",
    "mission_npc_hash_table",
    "white_equip_base",
    "mission_pet_hash_table",
    "mission_item_hash_table",
    "shimen_round_multiple_table",
    "shimen_level_money_bonus_table",
    "pet_medicine_hc_compound",
    "pet_skill_level_up",
    "exterior_poss",
    "pet_soul_poss_visual_locator",
    "zhanling_info",
    "zhanling_time_info",
    "new_zhanling_info",
    "pet_huantong_cost",
    "equip_set_attr",
    "exterior_ranse",
    "shenbing",
    "shenbing_level",
    "equip_enhanceex",
    "exterior_ts",
    "exterior_bg",
    "exterior_weapon_levelup",
    "dw_jinjie_texing",
    "dw_jinjie_info",
    "dw_jinjie_zx_gif_box",
    "dw_jinjie_texing_shengji",
    "shenbing_skill_up",
    "shenbing_common_skill",
    "shenbing_visual",
    "stall_info",
    "allowable_script_fun",
    "dfeng_point_info",
    "dfeng_level_info",
    "dfeng_essence_info",
    "dfeng_essence_kw_info",
    "exterior_bonus",
}

function configenginer:getinstance()
    if configenginer.instance == nil then
        configenginer.instance = configenginer.new()
    end
    return configenginer.instance
end

function configenginer:ctor()
    self.configs = {}
    self.loaded_all = false
end

-- 加载单个配置
function configenginer:load(name)
    if self.configs[name] then return end
    local config = sharetable.query(name)
    if config == nil then
        local cmd = string.format("get_%s", name)
        config = skynet.call(".CfgDB", "lua", cmd)
        sharetable.loadtable(name, config)
    end
    config = sharetable.query(name)
    self.configs[name] = config
end

-- 批量加载指定配置
function configenginer:loadmany(names)
    for _, name in ipairs(names) do
        self:load(name)
    end
end

function configenginer:loadall()
    if self.loaded_all then return end
    self.loaded_all = true
    local count = 0
    local seen = {}
    for _, name in ipairs(configs) do
        if not seen[name] then
            seen[name] = true
            self:load(name)
            count = count + 1
        end
    end
    skynet.logd("[configenginer] loadall done, loaded", count, "configs")
end

function configenginer:set_scene(scene) self.scene = scene end

function configenginer:get_scene()
    return self.scene
end

-- 获取配置，未加载时自动按需加载
function configenginer:get_config(name)
    local cfg = self.configs[name]
    if cfg == nil then
        self:load(name)
        cfg = self.configs[name]
    end
    return cfg
end

-- 清除配置缓存，下�? get_config 会重新从 sharetable/CfgDB 加载
function configenginer:clear_cache()
    self.configs = {}
    self.loaded_all = false
end

-- 定向清除单个配置缓存
function configenginer:invalidate_config(name)
    self.configs[name] = nil
end

-- 获取外观加成配置，返回单个id对应的属性表
function configenginer:get_exterior_bonus(id)
    local cfg = self:get_config("exterior_bonus")
    if not cfg then
        return nil
    end
    local result = cfg[id]
    if not result and not self._ext_bonus_debug then
        self._ext_bonus_debug = true
        local count = 0
        for k, _ in pairs(cfg) do
            count = count + 1
            if count >= 10 then break end
        end
    end
    return result
end

return configenginer
