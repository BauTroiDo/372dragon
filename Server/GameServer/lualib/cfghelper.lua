require "skynet.manager"
local skynet = require "skynet"
local class = require "class"
local define = require "define"
local sharetable = require "skynet.sharetable"
local cfghelper = class("cfghelper")

function cfghelper:getinstance()
    if cfghelper.instance == nil then
        cfghelper.instance = cfghelper.new()
    end
    return cfghelper.instance
end

function cfghelper:ctor()
    self.SceneAttr = nil
end

function cfghelper:init()
    skynet.logd("register CfgDB")
    self._loaded = {}

    -- PRELOAD: core configs essential for server startup
    local preloads = {
        "read_scene_info", "read_scene_attr", "read_scene_define_ex",
        "read_config_info", "read_scripts", "read_ai_script_dat",
        "read_special_obj_data",
        "read_skill_template", "read_skill_data", "read_std_impact",
        "read_impact_se_data", "read_attck_traits",
        "read_monster_attr_ex", "read_monster_ai_table",
        "read_monster_drop_boxs", "read_drop_box_content", "read_drop_notify",
        "read_equip_base", "read_common_item", "read_gem_info",
        "read_item_ruler", "read_item_seg_affect", "read_item_seg_quality",
        "read_item_seg_rate", "read_item_seg_value", "read_exp_attenuation",
        "read_player_exp_level", "read_base_value_table",
        "read_xinfa_v1", "read_xinfa_study_speed_v1", "read_id_collections",
        "read_sect_desc", "read_sect_info",
        "read_pet_attr_table", "read_pet_collection", "read_pet_config_table", "read_camp_and_stand",
        "read_activity_ruler", "read_activity_notice",
    }
    for _, method in ipairs(preloads) do
        self[method](self)
        self._loaded[method] = true
    end

    collectgarbage("collect")
end

function cfghelper:read_scene_info()
    local inireader = require "inireader".new()
    self.scene_info = inireader:load("SceneInfo.ini")
end

function cfghelper:get_scene_info()
    return self.scene_info
end

function cfghelper:get_scene_attr()
    return self.scene_attr
end

function cfghelper:get_skill_template()
    return self.skill_template
end

function cfghelper:get_skill_data()
    return self.skill_data
end

function cfghelper:get_monster_attr_ex()
    return self.monster_attr_ex
end

function cfghelper:get_std_impact_config()
    return self.std_impact_config
end

function cfghelper:get_monster_drop_boxs()
    return self.monster_drop_boxs
end

function cfghelper:get_drop_box_content()
    return self.drop_box_content
end

function cfghelper:get_exterior_ride()
    return self.exterior_ride
end

function cfghelper:get_equip_base()
    return self.equip_base
end

function cfghelper:get_common_item()
    return self.common_item
end

function cfghelper:get_gem_info()
    return self.gem_info
end

function cfghelper:get_exp_attenuation()
    return self.exp_attenuation
end

function cfghelper:get_config_info()
    return self.config_info
end

function cfghelper:get_item_ruler()
    return self.item_ruler
end

function cfghelper:get_item_seg_affect()
    return self.item_seg_affect
end

function cfghelper:get_item_seg_quality()
    return self.item_seg_quality
end

function cfghelper:get_item_seg_rate()
    return self.item_seg_rate
end

function cfghelper:get_item_seg_value()
    return self.item_seg_value
end

function cfghelper:get_attck_traits()
    return self.attck_traits
end

function cfghelper:get_monster_ai_table()
    return self.monster_ai_table
end

function cfghelper:get_impact_se_data()
    return self.impact_se_data
end

function cfghelper:get_player_exp_level()
    return self.player_exp_level
end

function cfghelper:get_attr_level_up_table()
    return self.attr_level_up_table
end

function cfghelper:get_base_value_table()
    return self.base_value_table
end

function cfghelper:get_item_compound()
    return self.item_compound
end

function cfghelper:get_xinfa_v1()
    return self.xinfa_v1
end

function cfghelper:get_xinfa_study_speed_v1()
    return self.xinfa_study_speed_v1
end

function cfghelper:get_id_collections()
    return self.id_collections
end

function cfghelper:get_shop_table()
    return self.shop_table
end

function cfghelper:get_slot_cost()
    return self.slot_cost
end

function cfghelper:get_gem_carve()
    return self.gem_carve
end

function cfghelper:get_gem_melting()
    return self.gem_melting
end

function cfghelper:get_double_gem_compound()
    return self.double_gem_compound
end

function cfghelper:get_ability()
    return self.ability
end

function cfghelper:get_menpaishenghuo()
    return self.menpaishenghuo
end

function cfghelper:get_ability_level_up_zhuzao()
    return self.ability_level_up_zhuzao
end

function cfghelper:get_ability_level_up_diaoyu()
    return self.ability_level_up_diaoyu
end

function cfghelper:get_ability_level_up_caiyao()
    return self.ability_level_up_caiyao
end

function cfghelper:get_ability_level_up_caikuang()
    return self.ability_level_up_caikuang
end

function cfghelper:get_ability_level_up_dingweifu()
    return self.ability_level_up_dingweifu
end

function cfghelper:get_ability_level_up_fengren()
    return self.ability_level_up_fengren
end

function cfghelper:get_ability_level_up_pengren()
    return self.ability_level_up_pengren
end

function cfghelper:get_ability_level_up_yangsheng()
    return self.ability_level_up_yangsheng
end

function cfghelper:get_ability_level_up_yaoli()
    return self.ability_level_up_yaoli
end

function cfghelper:get_ability_level_up_zhongzhi()
    return self.ability_level_up_zhongzhi
end

function cfghelper:get_ability_level_up_assistant_menpai()
    return self.ability_level_up_assistant_menpai
end

function cfghelper:get_ability_level_up_assistant()
    return self.ability_level_up_assistant
end

function cfghelper:get_ability_level_up_cailiaojiagong()
    return self.ability_level_up_cailiaojiagong
end

function cfghelper:get_ability_level_up_gaojishenghuo()
    return self.ability_level_up_gaojishenghuo
end

function cfghelper:get_ability_level_up_gongyi()
    return self.ability_level_up_gongyi
end

function cfghelper:get_ability_level_up_menpai()
    return self.ability_level_up_menpai
end

function cfghelper:get_ability_level_up_menpaifuzhu()
    return self.ability_level_up_menpaifuzhu
end

function cfghelper:get_ability_level_up_normal()
    return self.ability_level_up_normal
end

function cfghelper:get_ability_level_up_putongshenghuo()
    return self.ability_level_up_putongshenghuo
end

function cfghelper:get_ability_level_up_shenghuofuzhu()
    return self.ability_level_up_shenghuofuzhu
end

function cfghelper:get_ability_level_up_xiangqian()
    return self.ability_level_up_xiangqian
end

function cfghelper:get_ability_level_up_zhiyao()
    return self.ability_level_up_zhiyao
end

function cfghelper:get_ability_level_up_dingweifu()
    return self.ability_level_up_dingweifu
end

function cfghelper:get_dress_color_rate()
    return self.dress_color_rate
end

function cfghelper:get_exterior_head()
    return self.exterior_head
end

function cfghelper:get_exterior_face()
    return self.exterior_face
end

function cfghelper:get_exterior_hair()
    return self.exterior_hair
end

function cfghelper:get_char_face_geo()
    return self.char_face_geo
end

function cfghelper:get_char_hair_geo()
    return self.char_hair_geo
end

function cfghelper:get_equip_extra_attr()
    return self.equip_extra_attr
end

function cfghelper:get_pet_attr_table()
    return self.pet_attr_table
end

function cfghelper:get_pet_collection()
    return self.pet_collection
end

function cfghelper:get_pet_config_table()
    return self.pet_config_table
end

function cfghelper:get_pet_attr_point_distribute()
    return self.pet_attr_point_distribute
end

function cfghelper:get_pet_skill_distribute()
    return self.pet_skill_distribute
end

function cfghelper:get_pet_skill_index_table()
    return self.pet_skill_index_table
end

function cfghelper:get_pet_ai_stratety_table()
    return self.pet_ai_stratety_table
end

function cfghelper:get_camp_and_stand()
    return self.camp_and_stand
end

function cfghelper:get_pet_level_up_table()
    return self.pet_level_up_table
end

function cfghelper:get_pet_apperceive_skill_table()
    return self.pet_apperceive_skill_table
end

function cfghelper:get_dark_exp_level()
    return self.dark_exp_level
end

function cfghelper:get_dark_skill_list()
    return self.dark_skill_list
end

function cfghelper:get_pet_skill_book()
    return self.pet_skill_book
end

function cfghelper:get_pet_study_skill_table()
    return self.pet_study_skill_table
end

function cfghelper:get_pet_huan_hua_table()
    return self.pet_huan_hua_table
end

function cfghelper:get_pet_equip_base()
    return self.pet_equip_base
end

function cfghelper:get_pet_soul_level_up_info()
    return self.pet_soul_level_up_info
end

function cfghelper:get_pet_soul_extension()
    return self.pet_soul_extension
end

function cfghelper:get_pet_soul_base()
    return self.pet_soul_base
end

function cfghelper:get_pet_jl()
    return self.pet_jl
end

function cfghelper:get_pet_soul_level_cost()
    return self.pet_soul_level_cost
end

function cfghelper:get_pet_equip_suit_up_info()
    return self.pet_equip_suit_up_info
end

function cfghelper:get_pet_equip_set_attr()
    return self.pet_equip_set_attr
end

function cfghelper:get_special_obj_data()
    return self.special_obj_data
end

function cfghelper:get_item_enhance()
    return self.item_enhance
end

function cfghelper:get_diaowen_info()
    return self.diaowen_info
end

function cfghelper:get_diaowen_rule()
    return self.diaowen_rule
end

function cfghelper:get_kfs_base()
    return self.kfs_base
end

function cfghelper:get_kfs_slot()
    return self.kfs_slot
end

function cfghelper:get_kfs_attr_ex_book()
    return self.kfs_attr_ex_book
end

function cfghelper:get_kfs_attr_ext()
    return self.kfs_attr_ext
end

function cfghelper:get_kfs_level_up_exp()
    return self.kfs_level_up_exp
end

function cfghelper:get_kfs_skill_level_up()
    return self.kfs_skill_level_up
end

function cfghelper:get_item_apt_rate()
    return self.item_apt_rate
end

function cfghelper:get_pet_soul_skill()
    return self.pet_soul_skill
end

function cfghelper:get_kfs_level_up()
    return self.kfs_level_up
end

function cfghelper:get_wuhun_wg()
    return self.wuhun_wg
end

function cfghelper:get_wuhun_wg_level()
    return self.wuhun_wg_level
end

function cfghelper:get_pvp_rule()
    return self.pvp_rule
end

function cfghelper:get_activity_notice()
    return self.activity_notice
end

function cfghelper:get_activity_ruler()
    return self.activity_ruler
end

function cfghelper:get_ling_yu_base()
    return self.ling_yu_base
end

function cfghelper:get_ling_yu_attr_rule()
    return self.ling_yu_attr_rule
end

function cfghelper:get_ling_yu_attr_value()
    return self.ling_yu_attr_value
end

function cfghelper:get_ling_yu_set()
    return self.ling_yu_set
end

function cfghelper:get_ling_yu_set_effect()
    return self.ling_yu_set_effect
end

function cfghelper:get_drop_notify()
    return self.drop_notify
end

function cfghelper:get_scene_define_ex()
    return self.scene_define_ex
end

function cfghelper:get_scripts()
    return self.scripts
end

function cfghelper:get_ai_script_dat()
    return self.ai_script_dat
end

function cfghelper:get_lv_max_money()
    return self.lv_max_money
end

function cfghelper:get_super_weapon_up()
    return self.super_weapon_up
end

function cfghelper:get_exterior_weapon_visual()
    return self.exterior_weapon_visual
end

function cfghelper:get_char_title()
    return self.char_title
end

function cfghelper:get_xiulian_rate()
    return self.xiulian_rate
end

function cfghelper:get_xiulian_detail()
    return self.xiulian_detail
end

function cfghelper:get_sect_info()
    return self.sect_info
end

function cfghelper:get_week_active()
    return self.week_active
end

function cfghelper:get_die_penalty()
    return self.die_penalty
end

function cfghelper:get_sect_desc()
    return self.sect_desc
end

function cfghelper:get_questions()
    return self.questions
end

function cfghelper:get_grow_point()
    return self.grow_point
end

function cfghelper:get_bus_info()
    return self.bus_info
end

function cfghelper:get_city_info()
    return self.city_info
end

function cfghelper:get_city_building()
    return self.city_building
end

function cfghelper:get_guild_war_point()
    return self.guild_war_point
end

function cfghelper:get_char_title_new()
    return self.char_title_new
end

function cfghelper:get_pet_title()
    return self.pet_title
end

function cfghelper:get_mission_loot_item()
    return self.mission_loot_item
end

function cfghelper:get_mission_delivery()
    return self.mission_delivery
end

function cfghelper:get_mission_enter_area()
    return self.mission_enter_area
end

function cfghelper:get_mission_husong()
    return self.mission_husong
end

function cfghelper:get_mission_kill_monster()
    return self.mission_kill_monster
end

function cfghelper:get_mission_loot_item()
    return self.mission_loot_item
end

function cfghelper:get_drop_rate_of_item_table()
    return self.drop_rate_of_item_table
end

function cfghelper:get_stiry_telling_duo_logue()
    return self.stiry_telling_duo_logue
end

function cfghelper:get_mission_npc_hash_table()
    return self.mission_npc_hash_table
end

function cfghelper:get_mission_item_hash_table()
    return self.mission_item_hash_table
end

function cfghelper:get_mission_pet_hash_table()
    return self.mission_pet_hash_table
end

function cfghelper:get_white_equip_base()
    return self.white_equip_base
end

function cfghelper:get_shimen_round_multiple_table()
    return self.shimen_round_multiple_table
end

function cfghelper:get_shimen_level_money_bonus_table()
    return self.shimen_level_money_bonus_table
end

function cfghelper:get_pet_medicine_hc_compound()
    return self.pet_medicine_hc_compound
end

function cfghelper:get_pet_skill_level_up()
    return self.pet_skill_level_up
end

function cfghelper:get_exterior_poss()
    return self.exterior_poss
end

function cfghelper:get_pet_soul_poss_visual_locator()
    return self.pet_soul_poss_visual_locator
end

function cfghelper:get_zhanling_info()
    return self.zhanling_info
end

function cfghelper:get_zhanling_time_info()
    return self.zhanling_time_info
end

function cfghelper:get_new_zhanling_info()
    if not self.new_zhanling_info then
        self:read_new_zhanling_info()
    end
    return self.new_zhanling_info
end

function cfghelper:get_pet_huantong_cost()
    return self.pet_huantong_cost
end

function cfghelper:get_equip_set_attr()
    return self.equip_set_attr
end

function cfghelper:get_exterior_ranse()
    return self.exterior_ranse
end

function cfghelper:get_shenbing()
    return self.shenbing
end

function cfghelper:get_shenbing_level()
    return self.shenbing_level
end

function cfghelper:get_equip_enhanceex()
    return self.equip_enhanceex
end

function cfghelper:get_exterior_ts()
    return self.exterior_ts
end

function cfghelper:get_exterior_bg()
    return self.exterior_bg
end

function cfghelper:get_exterior_weapon_levelup()
    return self.exterior_weapon_levelup
end

function cfghelper:get_allowable_script_fun()
    if not self.allowable_script_fun then
        self:read_allowable_script_fun()
    end
    return self.allowable_script_fun
end

function cfghelper:read_lv_max_money()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("LvMaxMoney.txt")
    for _, conf in pairs(configs) do
        local level = conf["Level"]
        transferd[level] = conf["Max"]
    end
    self.lv_max_money = transferd
end

function cfghelper:read_config_info()
    local inireader = require "inireader".new()
    self.config_info = inireader:load("ConfigInfo.ini")
end

function cfghelper:read_scene_attr()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("SceneAttr.txt")
    for _, conf in pairs(configs) do
        local t = {}
        t.id = conf["ID"]
        if t.id then
            t.name = conf["Name$1$"]
            t.safe_level = conf["安全级别"]
            transferd[t.id] = t
        end
    end
    self.scene_attr = transferd
end

function cfghelper:read_skill_template()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("SkillTemplate_V1.txt")
    for _, conf in pairs(configs) do
        --print("conf =", table.tostr(conf))
        local t = {}
        t.id = conf["ID,(技能系的ID)"]
        if t.id then
            t.level_skills = {}
            for desc, value in pairs(conf) do
                local level = string.match(desc, "心法(%d+)级对应的实际技能ID")
                if level then
                    level = tonumber(level)
                    t.level_skills[level] = value
                end
            end
            t.name = conf["技能名字$1$"]
            t.accuracy = conf["命中率"]
            t.critical_rate = conf["会心率"]
            t.menpai = conf["门派"]
            t.skill_classs = conf["招式类型"]
            t.use_need_learnd = conf["使用前是否需要学会"] == 1
            t.target_must_in_special_state = conf["所选的目标必须是活的还是死的"]
            t.target_must_be_teammate = conf["是否仅对队友有效。注:队友珍兽算作队友。1为只对队友有效,0为无此限制。 "] == 1
            t.class_by_user = conf["技能类型按使用者划分"]
            t.select_type = conf["鼠标点选操作类型"]
            t.stand_flag = conf["技能友好度,=0为中性技能,>0为正面技能,<0为 负面技能"]
            t.radious = conf["范围半径"]
            t.target_count = conf["范围搜索的目标个数"]
            t.target_check_by_obj_type = conf["目标类型"]
            t.target_logic_by_stand = conf["目标和使用者阵营关系"]
            t.charges_or_interval = conf["连续攻击次数或引导的时间间隔(ms)"]
            t.auto_shot_skill_flag = conf["是否自动连续释放"] == 1
            t.delay_time = conf["延迟时间"]
            t.optimal_range_min = conf["最小射程(m)"]
            t.optimal_range_max = conf["最大射程(m)"]
            t.cool_down_id = conf["冷却ID"]
            t.need_weapon_flag = conf["需要拿武器"]
            t.skill_type = conf["技能类型"]
            t.play_action_time = conf["动作时间(ms)"]
            t.targeting_logic = conf["目标选择逻辑"]
            t.direct_study_up = conf["是否直接学会"] == 1
            t.xinfa_level_require = conf["技能的心法等级限制"]
            t.xinfa = conf["心法ID"]
            t.is_passive = conf["主动技能还是被动技能"] == 1
            t.enable_or_disable_auto_shot = conf["中断或激活自动释放技能"]
            t.enable_or_disable_pet_attack = conf["中断或激活珍兽攻击"]
            t.disable_by_flag_1 = conf["受限于控制1"] == 1
            t.disable_by_flag_2 = conf["受限于控制2"] == 1
            t.disable_by_flag_3 = conf["受限于骑乘/变身"] == 1
            t.operate_mode = conf["珍兽技能发动类型 0:主人手动点选,1:AI自动执行,2:增强自身属性的被动技能"]
            t.type_of_skill = conf["珍兽技能类型,0:物功,1:法功,2:护主,3:防御,4:复仇;"]
            t.pet_rate_of_skill = conf["技能发动几率,只对珍兽技能有效"]
            t.group_id = conf["技能组ID"]
            t.impact_id_of_skill = conf["珍兽技能产生的效果ID"]
            t.percentage_of_distraction = conf["干扰时间百分比"]
            t.chance_of_interference = conf["干扰几率"]
            t.percentage_of_disturbance_time_floats = conf["干扰时间浮动百分比"]
            t.is_shenbing_skill = conf["七情技能"] == 1
            skynet.logd("SkillTemplate_V1 t =", table.tostr(t))
            assert(transferd[t.id] == nil, t.id)
            transferd[t.id] = t
        end
    end
    self.skill_template = transferd
end

function cfghelper:read_skill_data()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("SkillData_V1.txt")
    for _, conf in pairs(configs) do
        --print("conf =", table.tostr(conf))
        local t = {}
        t.name = conf["效果的简要逻辑说明$1$"]
        t.id = conf["ID"]
        t.logic_id = conf["技能逻辑ID"]
        t.cool_down_time = conf["冷却时间"]
        t.charge_time = conf["聚气时间(ms)"]
        t.channel_time = conf["引导时间(ms)"]
        t.target_level = conf["目标级别"]
        t.channel_support = conf["是否需要引导支持"]
        t.condition_and_deplete = {}
        for i = 1, 3 do
            local d = {}
            d.desc = conf["条件或消耗参数说明"][i]
            d.type = conf["条件和消耗逻辑"][i]
            d.params = {}
            local j = 2 * i -1
            d.params[1] = conf["条件或消耗参数值"][j]
            d.params[2] = conf["条件或消耗参数值"][j + 1]
            t.condition_and_deplete[i] = d
        end
        local impact_desc = conf["参数说明"]
        local impact_values = conf["参数值"]
        t.cy_raw_params = {} -- server-impact: cặp (nhãn, DataIndex) thô cho scene.skill.human.skill_cy_generic
        for i, desc in ipairs(impact_desc) do
            local v = tonumber(impact_values[i])
            if type(desc) == "string" and desc ~= "" and v then
                t.cy_raw_params[#t.cy_raw_params + 1] = {desc, v}
            end
        end
        t.impacts = { effect_once = {}, effect_each_tick = {}, give_self = {}, give_target = {}}
        t.descriptor = {}
        for i, desc in ipairs(impact_desc) do
            if desc == "|生效一次的附加效果1"  then
                t.impacts.effect_once[1] = impact_values[i]
            end
            if desc == "|伤害buff" then
                t.impacts.effect_once[1] = impact_values[i]
            end
            if desc == "|生效一次的附加效果1（选择1个附近10米玩家给buff）" then
                t.impacts.effect_once[1] = impact_values[i]
            end
            if desc == "|生效一次的附加效果2" then
                t.impacts.effect_once[2] = impact_values[i]
            end
            if desc == "|生效一次的附加效果3" then
                t.impacts.effect_once[3] = impact_values[i]
            end
            if desc == "|生效一次的附加效果4" then
                t.impacts.effect_once[4] = impact_values[i]
            end
            if desc == "|生效一次的附加效果5" then
                t.impacts.effect_once[5] = impact_values[i]
            end
            if desc == "|生效一次的附加效果6" then
                t.impacts.effect_once[6] = impact_values[i]
            end
            if desc == "|生效一次的附加效果7" then
                t.impacts.effect_once[7] = impact_values[i]
            end
            if desc == "|生效一次的附加效果8" then
                t.impacts.effect_once[8] = impact_values[i]
            end
            if desc == "|生效一次的附加效果9" then
                t.impacts.effect_once[9] = impact_values[i]
            end
            if desc == "|生效一次的附加效果10" then
                t.impacts.effect_once[10] = impact_values[i]
            end
            if desc == "|生效一次的附加效果11" then
                t.impacts.effect_once[11] = impact_values[i]
            end
            if desc == "|生效一次的附加效果12" then
                t.impacts.effect_once[12] = impact_values[i]
            end
            if desc == "|生效一次的附加效果13" then
                t.impacts.effect_once[13] = impact_values[i]
            end
            if desc == "|生效一次的附加效果14" then
                t.impacts.effect_once[14] = impact_values[i]
            end
            if desc == "|生效一次的附加效果15" then
                t.impacts.effect_once[15] = impact_values[i]
            end
            if desc == "|生效一次的附加效果16" then
                t.impacts.effect_once[16] = impact_values[i]
            end
            if desc == "|生效一次的附加效果17" then
                t.impacts.effect_once[17] = impact_values[i]
            end
            if desc == "生效一次的效果(自己)" or desc == "生效一次的效果(自己)|" then
                t.impacts.effect_once.self = impact_values[i]
            end
            if desc == "生效一次的效果(目标)" then
                t.impacts.effect_once.target = impact_values[i]
            end
            if desc == "|引导周期的附加效果1" then
                t.impacts.effect_each_tick[1] = impact_values[i]
            end
            if desc == "|引导周期的附加效果2" then
                t.impacts.effect_each_tick[2] = impact_values[i]
            end
            if desc == "攻击的效果" or desc == "攻击效果" then
                t.impacts.attack = impact_values[i]
            end
            if desc == "给自己的效果" then
                t.impacts.give_self.id = impact_values[i]
            end
            if desc == "给自己的效果的发生几率" then
                t.impacts.give_self.p = impact_values[i]
            end
            if desc == "给目标的效果" then
                t.impacts.give_target.id = impact_values[i]
            end
            if desc == "给目标的效果的发生几率" then
                t.impacts.give_target.p = impact_values[i]
            end
            if desc == "给目标的多少次效果" then
                t.impacts.give_target.c = impact_values[i]
            end
            if desc == "瞬移效果" or desc == "瞬移特效" or desc == "|瞬移特效" then
                t.impacts.instant_transport = impact_values[i]
            end
            if desc == "防具的基础物理防御修正%" then
                t.descriptor["防具的基础物理防御修正%"] = impact_values[i]
            end
            if desc == "防具的基础魔法防御修正%" then
                t.descriptor["防具的基础魔法防御修正%"] = impact_values[i]
            end
            if desc == "武器的基础物理攻击修正%" then
                t.descriptor["武器的基础物理攻击修正%"] = impact_values[i]
            end
            if desc == "武器的基础魔法攻击修正%" then
                t.descriptor["武器的基础魔法攻击修正%"] = impact_values[i]
            end
            if desc == "武器类型1" then
                t.descriptor["武器类型1"] = impact_values[i]
            end
            if desc == "武器类型2" then
                t.descriptor["武器类型2"] = impact_values[i]
            end
            if desc == "效果1(人宠)" then
                t.descriptor["效果1(人宠)"] = impact_values[i]
            end
            if desc == "效果2(人宠)" then
                t.descriptor["效果2(人宠)"] = impact_values[i]
            end
            if desc == "效果3(人宠)" then
                t.descriptor["效果3(人宠)"] = impact_values[i]
            end
            if desc == "效果4(人宠)" then
                t.descriptor["效果4(人宠)"] = impact_values[i]
            end
            if desc == "效果1(怪)" then
                t.descriptor["效果1(怪)"] = impact_values[i]
            end
            if desc == "效果2(怪)" then
                t.descriptor["效果2(怪)"] = impact_values[i]
            end
            if desc == "效果3(怪)" then
                t.descriptor["效果3(怪)"] = impact_values[i]
            end
            if desc == "效果4(怪)" then
                t.descriptor["效果4(怪)"] = impact_values[i]
            end
            if desc == "效果1" then
                t.descriptor["效果1"] = impact_values[i]
            end
            if desc == "效果2" then
                t.descriptor["效果2"] = impact_values[i]
            end
            if desc == "效果3" then
                t.descriptor["效果3"] = impact_values[i]
            end
            if desc == "效果4" then
                t.descriptor["效果4"] = impact_values[i]
            end
            if desc == "无连击段对应效果" then
                t.descriptor["无连击段对应效果"] = impact_values[i]
            end
            if desc == "一段连击对应效果" then
                t.descriptor["一段连击对应效果"] = impact_values[i]
            end
            if desc == "二段连击对应效果" then
                t.descriptor["二段连击对应效果"] = impact_values[i]
            end
            if desc == "三段连击对应效果" then
                t.descriptor["三段连击对应效果"] = impact_values[i]
            end
            if desc == "生效一次效果1" then
                t.descriptor["生效一次效果1"] = impact_values[i]
            end
            if desc == "生效一次效果2" then
                t.descriptor["生效一次效果2"] = impact_values[i]
            end
            if desc == "给自己生效一次的附加效果1" then
                t.descriptor["给自己生效一次的附加效果1"] = impact_values[i]
            end
            if desc == "给自己生效一次的附加效果2" then
                t.descriptor["给自己生效一次的附加效果2"] = impact_values[i]
            end
            if desc == "给自己生效一次的附加效果3" then
                t.descriptor["给自己生效一次的附加效果3"] = impact_values[i]
            end

            if desc == "给目标生效一次的附加效果1" then
                t.descriptor["给目标生效一次的附加效果1"] = impact_values[i]
            end
            if desc == "给目标生效一次的附加效果2" then
                t.descriptor["给目标生效一次的附加效果2"] = impact_values[i]
            end
            if desc == "给目标生效一次的附加效果3" then
                t.descriptor["给目标生效一次的附加效果3"] = impact_values[i]
            end
            if desc == "|冰封效果" then
                t.descriptor["|冰封效果"] = impact_values[i]
            end

            if desc == "|敌对效果1" then
                t.descriptor["|敌对效果1"] = impact_values[i]
            end
            if desc == "|敌对效果2" then
                t.descriptor["|敌对效果2"] = impact_values[i]
            end
            if desc == "|友好效果1" then
                t.descriptor["|友好效果1"] = impact_values[i]
            end
            if desc == "|友好效果2" then
                t.descriptor["|友好效果2"] = impact_values[i]
            end
            if desc == "疲劳buff的ID" or desc == "疲劳buff的id" then
                t.descriptor["疲劳buff的ID"] = impact_values[i]
            end
            if desc == "纪录陷阱的buffID" then
                t.descriptor["纪录陷阱的buffID"] = impact_values[i]
            end
            if desc == "陷阱数据ID" then
                t.descriptor["陷阱数据ID"] = impact_values[i]
            end
            if desc == "同类陷阱数目上限" then
                t.descriptor["同类陷阱数目上限"] = impact_values[i]
            end
            if desc == "瞬发效果ID" then
                t.descriptor["瞬发效果ID"] = impact_values[i]
            end
            if desc == "引爆的陷阱类型ID" then
                t.descriptor["引爆的陷阱类型ID"] = impact_values[i]
            end
            if desc == "脚本ID" then
                t.descriptor["脚本ID"] = impact_values[i]
            end
            if desc == "个体拥有这些buff（这个填个buff集合的ID）时使用强化陷阱1" then
                t.descriptor["个体拥有这些buff（这个填个buff集合的ID）时使用强化陷阱1"] = impact_values[i]
            end
            if desc == "个体拥有这些buff（这个填个buff集合的ID）时使用强化陷阱2" then
                t.descriptor["个体拥有这些buff（这个填个buff集合的ID）时使用强化陷阱2"] = impact_values[i]
            end
            if desc == "强化陷阱1" then
                t.descriptor["强化陷阱1"] = impact_values[i]
            end
            if desc == "强化陷阱2" then
                t.descriptor["强化陷阱2"] = impact_values[i]
            end
            if desc == "陷阱数据ID增强" then
                t.descriptor["陷阱数据ID增强"] = impact_values[i]
            end
            if desc == "强化陷阱1增强" then
                t.descriptor["强化陷阱1增强"] = impact_values[i]
            end
            if desc == "强化陷阱2增强" then
                t.descriptor["强化陷阱2增强"] = impact_values[i]
            end
            if desc == "生效BUFFid" then
                t.descriptor["生效BUFFid"] = impact_values[i]
            end
            if desc == "回城术的效果" then
                t.descriptor["回城术的效果"] = impact_values[i]
            end
            if desc == "合集ID" then
                t.descriptor["合集ID"] = impact_values[i]
            end
            if desc == "生效一次的效果1(自己)" then
                t.descriptor["生效一次的效果1(自己)"] = impact_values[i]
            end
            if desc == "生效一次的效果2(自己)" then
                t.descriptor["生效一次的效果2(自己)"] = impact_values[i]
            end
            if desc == "生效一次的效果3(自己)" then
                t.descriptor["生效一次的效果3(自己)"] = impact_values[i]
            end
            if desc == "生效一次的效果4(自己)" then
                t.descriptor["生效一次的效果4(自己)"] = impact_values[i]
            end
            if desc == "生效一次的效果5(自己)" then
                t.descriptor["生效一次的效果5(自己)"] = impact_values[i]
            end
            if desc == "生效一次的效果1(目标)" then
                t.descriptor["生效一次的效果1(目标)"] = impact_values[i]
            end
            if desc == "生效一次的效果2(目标)" then
                t.descriptor["生效一次的效果2(目标)"] = impact_values[i]
            end
            if desc == "生效一次的效果3(目标)" then
                t.descriptor["生效一次的效果3(目标)"] = impact_values[i]
            end
            if desc == "生效一次的效果4(目标)" then
                t.descriptor["生效一次的效果4(目标)"] = impact_values[i]
            end
            if desc == "生效一次的效果5(目标)" then
                t.descriptor["生效一次的效果5(目标)"] = impact_values[i]
            end
			if desc == "buff1" then
                t.descriptor["buff1"] = impact_values[i]
            end
            if desc == "buff2" then
                t.descriptor["buff2"] = impact_values[i]
            end
            if desc == "buff3" then
                t.descriptor["buff3"] = impact_values[i]
            end
            if desc == "buff4" then
                t.descriptor["buff4"] = impact_values[i]
            end
            if desc == "buff5" then
                t.descriptor["buff5"] = impact_values[i]
            end
            if desc == "自身获得的BUFF" then
                t.descriptor["自身获得的BUFF"] = impact_values[i]
            end
            if desc == "对目标附加的BUFF" then
                t.descriptor["对目标附加的BUFF"] = impact_values[i]
            end
            if desc == "伤害id" then
                t.descriptor["伤害id"] = impact_values[i]
            end
            if desc == "冷却ID" then
                t.descriptor["冷却ID"] = impact_values[i]
            end
            if desc == "减少时间" then
                t.descriptor["减少时间"] = impact_values[i]
            end
            if desc == "普攻id" then
                t.descriptor["普攻id"] = impact_values[i]
            end
            if desc == "丧魂状态集合id" then
                t.descriptor["丧魂状态集合id"] = impact_values[i]
            end
            if desc == "丧魂状态百分比" then
                t.descriptor["丧魂状态百分比"] = impact_values[i]
            end
            if desc == "2丧魂状态百分比" then
                t.descriptor["2丧魂状态百分比"] = impact_values[i]
            end
            if desc == "3丧魂状态百分比" then
                t.descriptor["3丧魂状态百分比"] = impact_values[i]
            end
            if desc == "给自己的BUFF1" then
                t.descriptor["给自己的BUFF1"] = impact_values[i]
            end
            if desc == "给自己的BUFF2" then
                t.descriptor["给自己的BUFF2"] = impact_values[i]
            end
            if desc == "需要BUFF" then
                t.descriptor["需要BUFF"] = impact_values[i]
            end
            if desc == "需要惊魂" then
                t.descriptor["需要惊魂"] = impact_values[i]
            end
            if desc == "1魂BUFF" then
                t.descriptor["1魂BUFF"] = impact_values[i]
            end
            if desc == "2魂BUFF" then
                t.descriptor["2魂BUFF"] = impact_values[i]
            end
            if desc == "3魂BUFF" then
                t.descriptor["3魂BUFF"] = impact_values[i]
            end
            if desc == "拘3魂几率" then
                t.descriptor["拘3魂几率"] = impact_values[i]
            end
            if desc == "拘天魂id" then
                t.descriptor["拘天魂id"] = impact_values[i]
            end
            if desc == "拘地魂id" then
                t.descriptor["拘地魂id"] = impact_values[i]
            end
            if desc == "拘命魂id" then
                t.descriptor["拘命魂id"] = impact_values[i]
            end
            if desc == "失天魂id" then
                t.descriptor["失天魂id"] = impact_values[i]
            end
            if desc == "失地魂id" then
                t.descriptor["失地魂id"] = impact_values[i]
            end
            if desc == "失命魂id" then
                t.descriptor["失命魂id"] = impact_values[i]
            end
            if desc == "燃两魂百分比" then
                t.descriptor["燃两魂百分比"] = impact_values[i]
            end
            if desc == "两魂麻痹id" then
                t.descriptor["两魂麻痹id"] = impact_values[i]
            end
            if desc == "燃三魂伤害百分比" then
                t.descriptor["燃三魂伤害百分比"] = impact_values[i]
            end
            if desc == "三魂麻痹id" then
                t.descriptor["三魂麻痹id"] = impact_values[i]
            end
            if desc == "天魂集合id" then
                t.descriptor["天魂集合id"] = impact_values[i]
            end
            if desc == "失天魂id" then
                t.descriptor["失天魂id"] = impact_values[i]
            end
            if desc == "地魂集合id" then
                t.descriptor["地魂集合id"] = impact_values[i]
            end
            if desc == "失地魂id" then
                t.descriptor["失地魂id"] = impact_values[i]
            end
            if desc == "命魂集合id" then
                t.descriptor["命魂集合id"] = impact_values[i]
            end
            if desc == "失命魂id" then
                t.descriptor["失命魂id"] = impact_values[i]
            end
            if desc == "斩击的冷却id" then
                t.descriptor["斩击的冷却id"] = impact_values[i]
            end
            if desc == "丧魂buff集合" then
                t.descriptor["丧魂buff集合"] = impact_values[i]
            end
            if desc == "丧魂百分比" then
                t.descriptor["丧魂百分比"] = impact_values[i]
            end
            if desc == "2丧魂百分比" then
                t.descriptor["2丧魂百分比"] = impact_values[i]
            end
            if desc == "3丧魂百分比" then
                t.descriptor["3丧魂百分比"] = impact_values[i]
            end
            if desc == "斩杀失明" then
                t.descriptor["斩杀失明"] = impact_values[i]
            end
			if desc == "|生效一次的附加效果1（自己）" then
                t.impacts.give_self[1] = impact_values[i]
            end
            if desc == "|生效一次的附加效果2（自己）" then
                t.impacts.give_self[2] = impact_values[i]
            end
            if desc == "|生效一次的附加效果1（目标）" then
                t.impacts.give_target[1] = impact_values[i]
            end
            if desc == "|生效一次的附加效果2（目标）" then
                t.impacts.give_target[2] = impact_values[i]
            end
            -- 彼行我释：蓄气集合 → 控制效果映射
            for idx = 1, 6 do
                if desc == string.format("个体拥有这些BUFF时使用效果%d", idx) then
                    t.descriptor[desc] = impact_values[i]
                end
                if desc == string.format("给目标的效果%d", idx) then
                    t.descriptor[desc] = impact_values[i]
                end
            end
            -- 化气式：门派→绝学技能映射
            for idx = 0, 11 do
                if desc == string.format("门派%d技能ID", idx) then
                    t.descriptor[desc] = impact_values[i]
                end
            end
        end
        assert(transferd[t.id] == nil, t.id)
        skynet.logd("read_skill_data t =", table.tostr(t))
        transferd[t.id] = t
    end
    self.skill_data = transferd
end

function cfghelper:read_monster_attr_ex()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("MonsterAttrExTable.txt")
    for _, conf in pairs(configs) do
        --print("conf =", table.tostr(conf))
        local t = {}
        t.id = conf["怪物编号"]
        if t.id then
            t.name = conf["名称$1$"]
            t.model_id = conf["外型ID"]
            t.sex = conf["怪物性别"]
            t.level = conf["等级"]
            t.speed = conf["移动速度"] / 1000
            t.walk_speed = conf["步行速度"] / 1000
            t.is_npc = conf["是否可以交互"] == 1
            t.reputation = conf["势力ID"]
            t.hp = conf["HP上限"]
            t.mp = conf["MP上限"]
            t.hp_max = conf["HP上限"]
            t.mp_max = conf["MP上限"]
            t.attrib_att_physics = conf["物理攻击"]
            t.attrib_def_physics = conf["物理防御"]
            t.attrib_att_magic = conf["魔法攻击"]
            t.attrib_def_magic = conf["魔法防御"]
            t.attrib_hit = conf["命中率"]
            t.attrib_miss = conf["闪避"]
            t.mind_attack = conf["会心率"]
            t.mind_defend = conf["会心防御"]
            t.att_cold = conf["冰攻击"]
            t.def_cold = conf["冰防御"]
            t.reduce_def_cold = conf["降低目标冰抵抗"]
            t.att_fire = conf["火攻击"]
            t.def_fire = conf["火防御"]
            t.reduce_def_fire = conf["降低目标火抵抗"]
            t.att_light = conf["电攻击"]
            t.def_light = conf["电防御"]
            t.reduce_def_light = conf["降低目标玄抵抗"]
            t.att_poison = conf["毒攻击"]
            t.def_poison = conf["毒防御"]
            t.reduce_def_poison = conf["降低目标毒抵抗"]
            t.base_exp = conf["基础经验获得"]
            t.is_boss = conf["BOSS标记"] == 1
            t.base_ai = conf["基础AI"]
            t.ai_script = conf["扩展AI"]
            t.attack_cool_down_time = conf["攻击冷却时间"]
            t.attack_anim_time = conf["攻击动作时间"]
            t.attack_type = conf["攻击特性ID"]
            t.camp_id = conf["阵营"]
            t.active_time = conf["激活时间"]
            skynet.logd("cfghelper:read_monster_attr_ex t =", table.tostr(t))
            transferd[t.id] = t
        end
    end
    self.monster_attr_ex = transferd
end

function cfghelper:read_std_impact()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("StandardImpact.txt")
    for l, conf in pairs(configs) do
        --print("read_std_impact conf =", table.tostr(conf))
        local t = {}
        t.id = conf["Data_Index"]
        if t.id then
            t.name = conf["效果名称$1$"]
            t.logic_id = conf["逻辑ID"]
            t.logic_desc = conf["逻辑ID的说明"]
            t.is_over_timed = conf["是否是持续性效果"] == 1
            t.class_id = conf["分类ID（专门用于识别某一类BUFF）"]
            t.mutex_id = conf["互斥ID(效果互相替换用)"]
            t.mutex_priority = conf["互斥优先级"]
            t.can_dispel = conf["是否可以被技能驱散"] == 1
            t.can_cancel = conf["是否可以被手动取消"] == 1
            t.counter_when_offline = conf["下线仍然计时否"] == 1
            t.continuance = conf["总持续时间(毫秒)"]
            t.impact_id = conf["瞬发效果ID/驻留效果ID"]
            t.remain_on_corpse = conf["死后是否保留"] == 1
            t.need_channel_support = conf["是否需要引导支持"] == 1
            t.need_equip_support = conf["是否需要装备支持"] == 1
            t.interval = conf["发作时间间隔(毫秒)"]
            t.can_be_dispeled = conf["是否可以被技能驱散"] == 1
            t.fade_out_when_unit_on_damage  = conf["受到伤害时是否消失"] == 1
            t.fade_out_when_unit_on_move  = conf["开始移动时是否消失"] == 1
            t.fade_out_when_unit_on_action_start  = conf["开始动作时是否消失"] == 1
            t.fade_out_when_unit_offline  = conf["下线就消失否"] == 1
            t.stand_flag = conf["影响性质"]
            t.params = {}
            for key, value in pairs(conf) do
                local index = tonumber(string.match(key, "参数(%d+)说明"))
                if index and index ~= "" then
                    -- 去掉配表中参数描述首尾多余的双引号
                    if type(value) == "string" then
                        value = string.gsub(value, '^"(.*)"$', '%1')
                    end
                    t.params[index] = value
                end
            end
            --print("参数名 =", table.tostr(t.params))
            --print("参数值 =", table.tostr(conf["参数值"]))
            for index, value in ipairs(conf["参数值"]) do
                index = tonumber(index)
                local key = t.params[index]
                t.params[key] = value
                t.params[index] = nil
            end
            skynet.logd("StandardImpact t.id =", t.id, ";impact =", table.tostr(t))
            -- 重复id时，保留logic_id有效的条目（跳过全零的垃圾行）
            if transferd[t.id] == nil or (t.logic_id and t.logic_id ~= 0) then
                transferd[t.id] = t
            end
        end
    end
    require('cy_lingpai_combat').install(transferd)
    self.std_impact_config = transferd

    -- 注入借力buff条目 (logic_id=532, data_index=19001)
    if not transferd[69001] then
        transferd[69001] = {
            id = 69001, -- CS3c: dời khỏi 19001 (HJS = 高级血爆)
            name = "心剑交融(借力)",
            logic_id = 532,
            logic_desc = "STD_IMPACT_532",
            is_over_timed = true,
            class_id = 32,
            mutex_id = 69001,
            mutex_priority = 10,
            can_dispel = false,
            can_cancel = true,
            counter_when_offline = false,
            continuance = 15000,
            impact_id = 69001,
            remain_on_corpse = false,
            need_channel_support = false,
            need_equip_support = false,
            interval = 0,
            can_be_dispeled = false,
            fade_out_when_unit_on_damage = false,
            fade_out_when_unit_on_move = false,
            fade_out_when_unit_on_action_start = false,
            fade_out_when_unit_offline = false,
            stand_flag = 0,
            params = {
                ["借力返施技能集合ID"] = -1,
            },
        }
    end
    -- 注入心剑交融(12397-12412)的借力触发概率和借力效果ID
    for idx = 12397, 12412 do
        local imp = transferd[idx]
        if imp and imp.logic_id == 534 then
            local lv = idx - 12397
            imp.params["借力触发概率"] = math.min(10 + lv * 2, 30)
            imp.params["借力效果ID"] = 69001
        end
    end
end

function cfghelper:reload_std_impact()
    local read = require "txtreader".new()
    local configs = read:load("StandardImpact.txt")
    if not configs or not next(configs) then
        return false, "StandardImpact.txt 读取失败或为空"
    end
    local new_table = {}
    local count = 0
    for _, conf in pairs(configs) do
        local t = {}
        t.id = conf["Data_Index"]
        if t.id then
            t.name = conf["效果名称$1$"]
            t.logic_id = conf["逻辑ID"]
            t.logic_desc = conf["逻辑ID的说明"]
            t.is_over_timed = conf["是否是持续性效果"] == 1
            t.class_id = conf["分类ID（专门用于识别某一类BUFF）"]
            t.mutex_id = conf["互斥ID(效果互相替换用)"]
            t.mutex_priority = conf["互斥优先级"]
            t.can_dispel = conf["是否可以被技能驱散"] == 1
            t.can_cancel = conf["是否可以被手动取消"] == 1
            t.counter_when_offline = conf["下线仍然计时否"] == 1
            t.continuance = conf["总持续时间(毫秒)"]
            t.impact_id = conf["瞬发效果ID/驻留效果ID"]
            t.remain_on_corpse = conf["死后是否保留"] == 1
            t.need_channel_support = conf["是否需要引导支持"] == 1
            t.need_equip_support = conf["是否需要装备支持"] == 1
            t.interval = conf["发作时间间隔(毫秒)"]
            t.can_be_dispeled = conf["是否可以被技能驱散"] == 1
            t.fade_out_when_unit_on_damage = conf["受到伤害时是否消失"] == 1
            t.fade_out_when_unit_on_move = conf["开始移动时是否消失"] == 1
            t.fade_out_when_unit_on_action_start = conf["开始动作时是否消失"] == 1
            t.fade_out_when_unit_offline = conf["下线就消失否"] == 1
            t.stand_flag = conf["影响性质"]
            t.params = {}
            for key, value in pairs(conf) do
                local index = tonumber(string.match(key, "参数(%d+)说明"))
                if index and index ~= "" then
                    -- 去掉配表中参数描述首尾多余的双引号
                    if type(value) == "string" then
                        value = string.gsub(value, '^"(.*)"$', '%1')
                    end
                    t.params[index] = value
                end
            end
            for index, value in ipairs(conf["参数值"]) do
                index = tonumber(index)
                local key = t.params[index]
                t.params[key] = value
                t.params[index] = nil
            end
            if new_table[t.id] then
                return false, string.format("StandardImpact Data_Index=%d 重复", t.id)
            end
            new_table[t.id] = t
            count = count + 1
        end
    end
    if count == 0 then return false, "StandardImpact 解析后为空表" end

    -- 注入借力buff条目 (logic_id=532, data_index=19001)
    if not new_table[69001] then
        new_table[69001] = {
            id = 69001, -- CS3c: dời khỏi 19001 (HJS = 高级血爆)
            name = "心剑交融(借力)",
            logic_id = 532,
            logic_desc = "STD_IMPACT_532",
            is_over_timed = true,
            class_id = 32,
            mutex_id = 69001,
            mutex_priority = 10,
            can_dispel = false,
            can_cancel = true,
            counter_when_offline = false,
            continuance = 15000,
            impact_id = 69001,
            remain_on_corpse = false,
            need_channel_support = false,
            need_equip_support = false,
            interval = 0,
            can_be_dispeled = false,
            fade_out_when_unit_on_damage = false,
            fade_out_when_unit_on_move = false,
            fade_out_when_unit_on_action_start = false,
            fade_out_when_unit_offline = false,
            stand_flag = 0,
            params = {
                ["借力返施技能集合ID"] = -1,
            },
        }
        count = count + 1
    end
    -- 注入心剑交融(12397-12412)的借力触发概率和借力效果ID
    for idx = 12397, 12412 do
        local imp = new_table[idx]
        if imp and imp.logic_id == 534 then
            local lv = idx - 12397
            imp.params["借力触发概率"] = math.min(10 + lv * 2, 30)
            imp.params["借力效果ID"] = 69001
        end
    end

    require('cy_lingpai_combat').install(new_table)
    self.std_impact_config = new_table
    self._loaded["read_std_impact"] = true
    sharetable.loadtable("std_impact_config", new_table)
    skynet.logd("[cfghelper] reload_std_impact done,", count, "impacts")
    return true, string.format("StandardImpact 重载成功, %d 条记录", count)
end

function cfghelper:read_monster_drop_boxs()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("MonsterDropBoxs.txt")
    for _, conf in pairs(configs) do
        local t = {}
        t.id = conf["ID(怪物编号)"]
        if t.id then
            t.value = conf["Mvalue(怪物价值)"]
            t.drop_type = conf["怪物掉落类型"]
            t.drops = {}
            for desc, drop in pairs(conf) do
                local key = string.match(desc, "DID(%d+)")
                if key then
                    table.insert(t.drops, drop)
                end
            end
            transferd[t.id] = t
        end
    end
    self.monster_drop_boxs = transferd
end

function cfghelper:read_drop_box_content()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("DropBoxContent.txt")
    for _, conf in pairs(configs) do
        --print("conf = ", table.tostr(conf))
        local t = {}
        t.id = conf["ID(掉落包编号)"]
        if t.id then
            t.value = conf["BoxValue(掉落包价值)"]
            t.broad_type = conf["广播类型ID（Form DropNotify.txt）"]
            t.force_bind = conf["是否强制绑定"]
            t.items = {}
            local levels = conf["Level"]
            for desc, item in pairs(conf) do
                local id = string.match(desc, "Item(%d+)ID")
                if id then
                    id = tonumber(id)
                    table.insert(t.items, {id = item, level = levels[id]})
                end
            end
            transferd[t.id] = t
        end
    end
    self.drop_box_content = transferd
end

function cfghelper:reload_drop_rate()
    skynet.logi("[cfghelper] reload_drop_rate START")
    -- 事务组：两张表必须同时成功才提交
    local read1 = require "txtreader".new()
    local raw_boxs = read1:load("MonsterDropBoxs.txt")
    if not raw_boxs or not next(raw_boxs) then
        skynet.logi("[cfghelper] reload_drop_rate FAIL: MonsterDropBoxs.txt 读取失败或为空")
        return false, "MonsterDropBoxs.txt 读取失败或为空"
    end
    skynet.logi("[cfghelper] reload_drop_rate: MonsterDropBoxs raw rows =", #raw_boxs)
    local read2 = require "txtreader".new()
    local raw_content = read2:load("DropBoxContent.txt")
    if not raw_content or not next(raw_content) then
        skynet.logi("[cfghelper] reload_drop_rate FAIL: DropBoxContent.txt 读取失败或为空")
        return false, "DropBoxContent.txt 读取失败或为空"
    end
    skynet.logi("[cfghelper] reload_drop_rate: DropBoxContent raw rows =", #raw_content)
    -- 构建 monster_drop_boxs
    local new_boxs = {}
    local boxs_count = 0
    for _, conf in pairs(raw_boxs) do
        local t = {}
        t.id = conf["ID(怪物编号)"]
        if t.id then
            t.value = conf["Mvalue(怪物价值)"]
            t.drop_type = conf["怪物掉落类型"]
            t.drops = {}
            for desc, drop in pairs(conf) do
                local key = string.match(desc, "DID(%d+)")
                if key then
                    table.insert(t.drops, drop)
                end
            end
            new_boxs[t.id] = t
            boxs_count = boxs_count + 1
        end
    end
    if boxs_count == 0 then return false, "MonsterDropBoxs 解析后为空表" end
    -- 构建 drop_box_content
    local new_content = {}
    local content_count = 0
    for _, conf in pairs(raw_content) do
        local t = {}
        t.id = conf["ID(掉落包编号)"]
        if t.id then
            t.value = conf["BoxValue(掉落包价值)"]
            t.broad_type = conf["广播类型ID（Form DropNotify.txt）"]
            t.force_bind = conf["是否强制绑定"]
            t.items = {}
            local levels = conf["Level"]
            for desc, item in pairs(conf) do
                local id = string.match(desc, "Item(%d+)ID")
                if id then
                    id = tonumber(id)
                    table.insert(t.items, {id = item, level = levels[id]})
                end
            end
            new_content[t.id] = t
            content_count = content_count + 1
        end
    end
    if content_count == 0 then return false, "DropBoxContent 解析后为空表" end
    -- 事务提交：两张表同时更新
    self.monster_drop_boxs = new_boxs
    self.drop_box_content = new_content
    self._loaded["read_monster_drop_boxs"] = true
    self._loaded["read_drop_box_content"] = true
    sharetable.loadtable("monster_drop_boxs", new_boxs)
    sharetable.loadtable("drop_box_content", new_content)
    skynet.logi("[cfghelper] reload_drop_rate done,", boxs_count, "monsters,", content_count, "boxes")
    return true, string.format("爆率重载成功, %d 怪物, %d 掉落包", boxs_count, content_count)
end

function cfghelper:read_exterior_ride()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("Exterior_Ride.txt")
    for _, conf in pairs(configs) do
        local t = {}
        t.id = conf["index"]
        if t.id then
            t.menpai = conf["门派"]
            t.name = conf["名字"]
            t.icon = conf["图标"]
            t.desc = conf["描述"]
            t.model = conf["模型索引"]
            t.speed_up = conf["速度索引"]
            t.impacts = {
                [10] = conf["速度10"],
                [20] = conf["速度20"],
                [40] = conf["速度40"],
                [70] = conf["速度70"],
                [75] = conf["速度75"],
                [80] = conf["速度80"],
                [85] = conf["速度85"],
                [90] = conf["速度90"],
                [125] = conf["速度125"],    -- CYS-RIDE-FINISH: bac 125 cua CY (照夜白/香鬃乌), cot cuoi bang
            }
            transferd[t.id] = t
            skynet.logd("read_exterior_ride =", table.tostr(t))
        end
    end
    self.exterior_ride = transferd
end

function cfghelper:read_equip_base()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("EquipBase.txt")
    for _, conf in pairs(configs) do
        local t = {}
        t.id = conf["Index"]
        if t.id then
            t.class = conf["class(基本类型)"]
            t.quality = conf["Quality(品质)"]
            t.type = conf["Type(类别)"]
            t.index = conf["Index(物品号)"]
            t.equip_point = conf["EquipPoint(装备点)"]
            t.visual = conf["Visual"]
            t.rule = conf["适应规则"]
            t.max_gem_slot = conf["镶嵌宝石上限"]
            t.level = conf["Lv(需求等级)"]
            t.max_dur = conf["Max耐久"]
            t.skill_id = conf["技能ID：装备点为武器时标识效果ID（From StandardImpact.txt）"]
            t.script_id = conf["脚本ID"]
            t.name = conf["Name(名称)$1$"]
            t.base_price = conf["基本价格"]
            t.sell_price = conf["出售价格"]
            t.set_id = conf["套装编号"]
            t.broad_cast = conf["是否广播"] == 1
            t["是否受品质影响"] = conf["是否受品质影响"]
            t["是否有资质"] = conf["是否有资质"]
            t["品质规则"] = conf["品质规则"]
            t["起始数值段"] = conf["起始数值段"]
            t["起始数值段"] = conf["起始数值段"]
            t["属性条数min"] = conf["属性条数min"]
            t["属性条数max"] = conf["属性条数max"]
            t["资质min"] = conf["资质min"]
            t["资质max"] = conf["资质max"]
            t["行囊"] = conf["行囊"]
            t["格箱"] = conf["格箱"]
            t["品阶"] = conf["品阶"]
            t.base_attrs = {}
            if conf["基础外功攻击"] ~= -1 then
                t.base_attrs["基础外功攻击"] = conf["基础外功攻击"]
            end
            if conf["基础内功攻击"] ~= -1 then
                t.base_attrs["基础内功攻击"] = conf["基础内功攻击"]
            end
            if conf["基础外功防御"] ~= -1 then
                t.base_attrs["基础外功防御"] = conf["基础外功防御"]
            end
            if conf["基础内功防御"] ~= -1 then
                t.base_attrs["基础内功防御"] = conf["基础内功防御"]
            end
            if conf["基础命中"] ~= -1 then
                t.base_attrs["基础命中"] = conf["基础命中"]
            end
            if conf["基础闪避"] ~= -1 then
                t.base_attrs["基础闪避"] = conf["基础闪避"]
            end
            t.ex_attrs = {}
            if conf["增加HP的上限"] ~= -1 then
                table.insert(t.ex_attrs, "增加HP的上限")
            end
            if conf["百分比增加HP的上限"] ~= -1 then
                table.insert(t.ex_attrs, "百分比增加HP的上限")
            end
            if conf["加快HP的回复速度"] ~= -1 then
                table.insert(t.ex_attrs, "加快HP的回复速度")
            end
            if conf["增加MP的上限"] ~= -1 then
                table.insert(t.ex_attrs, "增加MP的上限")
            end
            if conf["百分比增加MP的上限"] ~= -1 then
                table.insert(t.ex_attrs, "百分比增加MP的上限")
            end
            if conf["加快MP的回复速度"] ~= -1 then
                table.insert(t.ex_attrs, "加快MP的回复速度")
            end
            if conf["冰攻击"] ~= -1 then
                table.insert(t.ex_attrs, "冰攻击")
            end
            if conf["冰抵抗"] ~= -1 then
                table.insert(t.ex_attrs, "冰抵抗")
            end
            if conf["减少冰冻迟缓时间"] ~= -1 then
                table.insert(t.ex_attrs, "减少冰冻迟缓时间")
            end
            if conf["火攻击"] ~= -1 then
                table.insert(t.ex_attrs, "火攻击")
            end
            if conf["火抵抗"] ~= -1 then
                table.insert(t.ex_attrs, "火抵抗")
            end
            if conf["减少火烧持续时间"] ~= -1 then
                table.insert(t.ex_attrs, "减少火烧持续时间")
            end
            if conf["玄攻击"] ~= -1 then
                table.insert(t.ex_attrs, "玄攻击")
            end
            if conf["玄抵抗"] ~= -1 then
                table.insert(t.ex_attrs, "玄抵抗")
            end
            if conf["减少玄击眩晕时间"] ~= -1 then
                table.insert(t.ex_attrs, "减少玄击眩晕时间")
            end
            if conf["毒攻击"] ~= -1 then
                table.insert(t.ex_attrs, "毒攻击")
            end
            if conf["毒抵抗"] ~= -1 then
                table.insert(t.ex_attrs, "毒抵抗")
            end
            if conf["减少中毒时间"] ~= -1 then
                table.insert(t.ex_attrs, "减少中毒时间")
            end
            if conf["按百分比抵消所有属性攻击"] ~= -1 then
                table.insert(t.ex_attrs, "按百分比抵消所有属性攻击")
            end
            if conf["外功攻击"] ~= -1 then
                table.insert(t.ex_attrs, "外功攻击")
            end
            if conf["按百分比增加外功攻击"] ~= -1 then
                table.insert(t.ex_attrs, "按百分比增加外功攻击")
            end
            if conf["对装备基础外功攻击百分比加成"] ~= -1 then
                table.insert(t.ex_attrs, "对装备基础外功攻击百分比加成")
            end
            if conf["外功防御"] ~= -1 then
                table.insert(t.ex_attrs, "外功防御")
            end
            if conf["按百分比增加外功防御"] ~= -1 then
                table.insert(t.ex_attrs, "按百分比增加外功防御")
            end
            if conf["对装备基础外功防御百分比加成"] ~= -1 then
                table.insert(t.ex_attrs, "对装备基础外功防御百分比加成")
            end
            if conf["按百分比抵消外功伤害"] ~= -1 then
                table.insert(t.ex_attrs, "按百分比抵消外功伤害")
            end
            if conf["内功攻击"] ~= -1 then
                table.insert(t.ex_attrs, "内功攻击")
            end
            if conf["按百分比增加内功攻击"] ~= -1 then
                table.insert(t.ex_attrs, "按百分比增加内功攻击")
            end
            if conf["对装备基础内功攻击百分比加成"] ~= -1 then
                table.insert(t.ex_attrs, "对装备基础内功攻击百分比加成")
            end
            if conf["内功防御"] ~= -1 then
                table.insert(t.ex_attrs, "内功防御")
            end
            if conf["按百分比增加内功防御"] ~= -1 then
                table.insert(t.ex_attrs, "按百分比增加内功防御")
            end
            if conf["对装备基础内功防御百分比加成"] ~= -1 then
                table.insert(t.ex_attrs, "对装备基础内功防御百分比加成")
            end
            if conf["按百分比抵消内功伤害"] ~= -1 then
                table.insert(t.ex_attrs, "按百分比抵消内功伤害")
            end
            if conf["攻击速度(两次攻击间隔时间)"] ~= -1 then
                table.insert(t.ex_attrs, "攻击速度(两次攻击间隔时间)")
            end
            if conf["内功冷却速度"] ~= -1 then
                table.insert(t.ex_attrs, "内功冷却速度")
            end
            if conf["命中"] ~= -1 then
                table.insert(t.ex_attrs, "命中")
            end
            if conf["闪避"] ~= -1 then
                table.insert(t.ex_attrs, "闪避")
            end
            if conf["会心"] ~= -1 then
                table.insert(t.ex_attrs, "会心")
            end
            if conf["无视对方防御比率"] ~= -1 then
                table.insert(t.ex_attrs, "无视对方防御比率")
            end
            if conf["移动速度百分比"] ~= -1 then
                table.insert(t.ex_attrs, "移动速度百分比")
            end
            if conf["伤害反射"] ~= -1 then
                table.insert(t.ex_attrs, "伤害反射")
            end
            if conf["伤害由内力抵消"] ~= -1 then
                table.insert(t.ex_attrs, "伤害由内力抵消")
            end
            if conf["力量"] ~= -1 then
                table.insert(t.ex_attrs, "力量")
            end
            if conf["灵气"] ~= -1 then
                table.insert(t.ex_attrs, "灵气")
            end
            if conf["体力"] ~= -1 then
                table.insert(t.ex_attrs, "体力")
            end
            if conf["定力"] ~= -1 then
                table.insert(t.ex_attrs, "定力")
            end
            if conf["身法"] ~= -1 then
                table.insert(t.ex_attrs, "身法")
            end
            if conf["会心防御"] ~= -1 then
                table.insert(t.ex_attrs, "会心防御")
            end
            if conf["增加所有的人物一级属性"] ~= -1 then
                table.insert(t.ex_attrs, "增加所有的人物一级属性")
            end
            if conf["生命偷取"] ~= -1 then
                table.insert(t.ex_attrs, "生命偷取")
            end
            if conf["内力偷取"] ~= -1 then
                table.insert(t.ex_attrs, "内力偷取")
            end
            if conf["增加某个技能等级"] ~= -1 then
                table.insert(t.ex_attrs, "增加某个技能等级")
            end
            if conf["增加所有技能等级"] ~= -1 then
                table.insert(t.ex_attrs, "增加所有技能等级")
            end
            if conf["特殊技能发动概率"] ~= -1 then
                table.insert(t.ex_attrs, "特殊技能发动概率")
            end
            if conf["降低目标冰抵抗"] ~= -1 then
                table.insert(t.ex_attrs, "降低目标冰抵抗")
            end
            if conf["降低目标火抵抗"] ~= -1 then
                table.insert(t.ex_attrs, "降低目标火抵抗")
            end
            if conf["降低目标玄抵抗"] ~= -1 then
                table.insert(t.ex_attrs, "降低目标玄抵抗")
            end
            if conf["降低目标毒抵抗"] ~= -1 then
                table.insert(t.ex_attrs, "降低目标毒抵抗")
            end
            skynet.logd("装备基础信息 =", table.tostr(t))
            transferd[t.id] = t
        end
    end
    self.equip_base = transferd
    --print("read_equip_base =", table.tostr(transferd))
end

function cfghelper:read_common_item()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("CommonItem.txt")
    for _, conf in pairs(configs) do
        --print("conf = ", table.tostr(conf))
        local t = {}
        t.id = conf["index"]
        t.name = conf["name$1$"]
        t.rule = conf["适应规则"]
        t.max_tile_count = conf["叠放数量"]
        t.skill_id = conf["技能编号"]
        t.script_id = conf["脚本编号"]
        t.is_cost_self = conf["是否消耗"] == 1
        t.base_price = conf["基本价格"]
        t.grade = conf["档次等级"]
        t.sell_price = conf["出售价格"]
        t.base_price = conf["基本价格"]
        t.level = conf["等级"]
        t.broad_cast = conf["是否广播"] == 1
        transferd[t.id] = t
        skynet.logd("read_common_item t =", table.tostr(t))
    end
    self.common_item = transferd
end

function cfghelper:read_gem_info()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("GemInfo.txt")
    for _, conf in pairs(configs) do
        --print("conf = ", table.tostr(conf))
        local t = table.clone(conf)
        t.id = conf["index"]
        t.quality = conf["quality"]
        t.name = conf["名称$1$"]
        t.type = conf["Type"]
        t.rule = conf["适应规则"]
        t.base_price = conf["基本价格"]
        t.sell_price = conf["出售价格"]
        t.broad_cast = conf["是否广播"] == 1
        t.lay_count = 250
        transferd[t.id] = t
        skynet.logd("cfghelper:read_gem_info id =", t.id, ";conf =", table.tostr(t))
    end
    self.gem_info = transferd
end

function cfghelper:read_exp_attenuation()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("ExpAttenuation.txt")
    for _, conf in pairs(configs) do
        --print("conf = ", table.tostr(conf))
        local t = {}
        t.delta = conf["Delta"]
        t.rate = conf["Rate"]
        transferd[t.delta] = t.rate
    end
    self.exp_attenuation = transferd
end

function cfghelper:read_item_ruler()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("ItemRule.txt")
    for _, conf in pairs(configs) do
        --print("conf = ", table.tostr(conf))
        local t = {}
        t.id = conf["index"]
        t.discard = conf["丢弃"] == 1
        t.tile = conf["重叠"] == 1
        t.short_cut = conf["快捷"] == 1
        t.can_sell = conf["出售"] == 1
        t.can_exchange = conf["交易"] == 1
        t.can_use = conf["使用"] == 1
        t.is_pick_bind = conf["拾取绑定"] == 1
        t.is_equip_bind = conf["装备绑定"] == 1
        t.is_unqiue = conf["是否唯一"] == 1
        t.need_ident = conf["是否需要鉴定"] == 1
        t.is_virtual = conf["是否虚拟道具"] == 1
        t.can_save_bank = conf["是否可以存入银行"] == 1
        t.is_short_cut_tile = conf["快捷栏是否叠加显示"] == 1
        transferd[t.id] = t
    end
    self.item_ruler = transferd
end

function cfghelper:read_item_seg_affect()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("ItemSegAffect.txt")
    for _, conf in pairs(configs) do
        --print("conf = ", table.tostr(conf))
        local t = {}
        t.total = conf.total
        t.id = conf["品质分布编号"]
        t.p = {}
        for k, v in pairs(conf) do
            local n = tonumber(string.match(k, "段(%d+)几率"))
            if n then
                t.p[n] = v
            end
        end
        --print("read_item_seg_value t = ", table.tostr(t))
        transferd[t.id] = t
    end
    self.item_seg_affect = transferd
end

function cfghelper:read_item_seg_quality()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("ItemSegQuality.txt")
    for _, conf in pairs(configs) do
        local t = {}
        t.id = conf["规则ID"]
        t[0] = conf["0-普通怪"]
        t[1] = conf["1-首领"]
        t[2] = conf["2-头目"]
        for k, v in pairs(conf) do
            local a, b, c = string.match(k, "(%d+)%-(%d+)级材料三精%_(%d+)号装配点")
            --print(a,b,c)
            if a then
                local n = tonumber(a)
                if n then
                    t[n] = v
                end
            end
        end
        --print("cfghelper:read_item_seg_quality t =", table.tostr(t))
        transferd[t.id] = t
    end
    self.item_seg_quality = transferd
end

function cfghelper:read_item_seg_rate()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("ItemSegRate.txt")
    for _, conf in pairs(configs) do
        --print("conf = ", table.tostr(conf))
        local t = conf
        transferd[t["品质段"]] = t
    end
    self.item_seg_rate = transferd
end

function cfghelper:read_item_seg_value()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("ItemSegValue.txt")
    for _, conf in pairs(configs) do
        --print("conf = ", table.tostr(conf))
        local t = conf
        transferd[t["Index"]] = t
    end
    self.item_seg_value = transferd
end

function cfghelper:read_attck_traits()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("AttackTraits.txt")
    for _, conf in pairs(configs) do
        local t = conf
        t.id = conf["ID"]
        t[0] = conf["C-phy"]
        t[1] = conf["C-magic"]
        t[2] = conf["C-cold"]
        t[3] = conf["C-fire"]
        t[4] = conf["C-light"]
        t[5] = conf["C-poison"]
        transferd[t["id"]] = t
    end
    self.attck_traits = transferd
end

function cfghelper:read_monster_ai_table()
    local inireader = require "inireader".new()
    self.monster_ai_table = inireader:load("MonsterAITable.ini")
end

function cfghelper:read_impact_se_data()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("ImpactSEData_V1.txt")
    for _, conf in pairs(configs) do
        local t = conf
        t.id = conf["ID"]
        t.icon = conf["图标文件名"]
        transferd[t["id"]] = t
    end
    self.impact_se_data = transferd
end

function cfghelper:read_player_exp_level()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("PlayerExpLevel.txt")
    for _, conf in pairs(configs) do
        transferd[conf["Level"]] = conf["Exp"]
    end
    self.player_exp_level = transferd
end

function cfghelper:read_attr_level_up_table()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("AttrLevelUpTable.txt")
    for _, conf in pairs(configs) do
        local t = {}
        local level = conf["级别"]

        local attrs = {str = "力量", spr = "灵气", con = "体质", dex = "定力", int = "身法"}
        for key, chn in pairs(attrs) do
            t[key] = {}
            for k, value in pairs(conf) do
                local pos = string.find(k, chn)
                if pos then
                    local menpai = string.sub(k, 1, pos - 1)
                    t[key][menpai] = value
                end
            end
        end
        transferd[level] = t
    end
    self.attr_level_up_table = transferd
end

function cfghelper:read_base_value_table()
    local inireader = require "inireader".new()
    self.base_value_table = inireader:load("BaseValueTable.ini")
end

function cfghelper:read_xinfa_v1()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("XinFa_V1.txt")
    for _, conf in pairs(configs) do
        local id = conf["心法ID"]
        if id then
            local t = {}
            t.menpai = conf["门派ID"]
            transferd[id] = t
        end
    end
    self.xinfa_v1 = transferd
end

function cfghelper:read_xinfa_study_speed_v1()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("XinFaStudySpend_V1.txt")
    for _, conf in pairs(configs) do
        local level = conf["学习等级"]
        if level then
            local t = {}
            t.cost_money = conf["消耗金钱"]
            t.cost_exp = conf["消耗经验"]
            transferd[level] = t
        end
    end
    self.xinfa_study_speed_v1 = transferd
end

function cfghelper:read_id_collections()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("IDCollections.txt")
    for _, conf in pairs(configs) do
        local id = conf["标识ID的分类ID"]
        if id then
            local t = {ids = {}}
            local count = conf["本类中的ID数量"]
            for i = 1, count do
                local key = string.format("ID%d", i)
                t.ids[conf[key]] = true
            end
            t.type = conf["本行中所有ID的类型(必须填)"]
            transferd[id] = t
        end
    end
    self.id_collections = transferd
end

function cfghelper:read_shop_table()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("ShopTable.txt")
    for _, conf in pairs(configs) do
        local id = conf["Index"]
        if id then
            local t = {}
            t.shop_type = conf["货币单位(1代表金币，2代表善恶值，4，帮贡，3代表师德点，5元宝，6赠点，7师门贡献度，8代表交子)"]
            t.is_yuanbao_shop = conf["is_yuanbao_shop"]
            t.can_multiple_buy = conf["是否能够购买多个物品"]
            t.merchandise_num = conf["Num(商品数量)"]
            t.merchadise_list = {}
            for i = 1, t.merchandise_num do
                local merchandise = {}
                local id_key = string.format("PID(商品编号%d)", i)
                local price_key = string.format("商品%d价格", i)
                merchandise.id = conf[id_key]
                if merchandise.id and merchandise.id > 0 then
                    merchandise.pnum = conf["PNUM(每组多少个)"][i] or 1
                    if merchandise.pnum == -1 then
                        merchandise.pnum = 1
                    end
                    merchandise.pmax = conf["PMAX(有限商品的数量上限)"][i]
                    merchandise.price = conf[price_key]
                    merchandise.discount = conf["商品折扣"][i]
                    merchandise.color = conf["商品颜色"][i]
                    t.merchadise_list[i] = merchandise
                end
            end
            t.merchandise_num = #t.merchadise_list
            transferd[id] = t
            skynet.logd("cfghelper:read_shop_table id =", id, ";shop =", table.tostr(t))
        end
    end
    self.shop_table = transferd
end

function cfghelper:reload_shop_table()
    local read = require "txtreader".new()
    local configs = read:load("ShopTable.txt")
    if not configs or not next(configs) then
        return false, "ShopTable.txt 读取失败或为空"
    end
    local new_table = {}
    local count = 0
    for _, conf in pairs(configs) do
        local id = conf["Index"]
        if id then
            local t = {}
            t.shop_type = conf["货币单位(1代表金币，2代表善恶值，4，帮贡，3代表师德点，5元宝，6赠点，7师门贡献度，8代表交子)"]
            t.is_yuanbao_shop = conf["is_yuanbao_shop"]
            t.can_multiple_buy = conf["是否能够购买多个物品"]
            t.merchandise_num = conf["Num(商品数量)"]
            t.merchadise_list = {}
            for i = 1, t.merchandise_num do
                local merchandise = {}
                local id_key = string.format("PID(商品编号%d)", i)
                local price_key = string.format("商品%d价格", i)
                merchandise.id = conf[id_key]
                if merchandise.id and merchandise.id > 0 then
                    merchandise.pnum = conf["PNUM(每组多少个)"][i] or 1
                    if merchandise.pnum == -1 then
                        merchandise.pnum = 1
                    end
                    merchandise.pmax = conf["PMAX(有限商品的数量上限)"][i]
                    merchandise.price = conf[price_key]
                    merchandise.discount = conf["商品折扣"][i]
                    merchandise.color = conf["商品颜色"][i]
                    t.merchadise_list[i] = merchandise
                end
            end
            t.merchandise_num = #t.merchadise_list
            new_table[id] = t
            count = count + 1
        end
    end
    if count == 0 then
        return false, "ShopTable 解析后为空表"
    end
    self.shop_table = new_table
    self._loaded["read_shop_table"] = true
    sharetable.loadtable("shop_table", new_table)
    skynet.logd("[cfghelper] reload_shop_table done,", count, "shops")
    return true, string.format("ShopTable 重载成功, %d 个商店", count)
end

function cfghelper:reload_equip_base()
    local read = require "txtreader".new()
    local configs = read:load("EquipBase.txt")
    if not configs or not next(configs) then
        return false, "EquipBase.txt 读取失败或为空"
    end
    local new_table = {}
    local count = 0
    for _, conf in pairs(configs) do
        local t = {}
        t.id = conf["Index"]
        if t.id then
            t.class = conf["class(基本类型)"]
            t.quality = conf["Quality(品质)"]
            t.type = conf["Type(类别)"]
            t.index = conf["Index(物品号)"]
            t.equip_point = conf["EquipPoint(装备点)"]
            t.visual = conf["Visual"]
            t.rule = conf["适应规则"]
            t.max_gem_slot = conf["镶嵌宝石上限"]
            t.level = conf["Lv(需求等级)"]
            t.max_dur = conf["Max耐久"]
            t.skill_id = conf["技能ID：装备点为武器时标识效果ID（From StandardImpact.txt）"]
            t.script_id = conf["脚本ID"]
            t.name = conf["Name(名称)$1$"]
            t.base_price = conf["基本价格"]
            t.sell_price = conf["出售价格"]
            t.set_id = conf["套装编号"]
            t.broad_cast = conf["是否广播"] == 1
            t["是否受品质影响"] = conf["是否受品质影响"]
            t["是否有资质"] = conf["是否有资质"]
            t["品质规则"] = conf["品质规则"]
            t["起始数值段"] = conf["起始数值段"]
            t["属性条数min"] = conf["属性条数min"]
            t["属性条数max"] = conf["属性条数max"]
            t["资质min"] = conf["资质min"]
            t["资质max"] = conf["资质max"]
            t["行囊"] = conf["行囊"]
            t["格箱"] = conf["格箱"]
            t["品阶"] = conf["品阶"]
            t.base_attrs = {}
            if conf["基础外功攻击"] ~= -1 then t.base_attrs["基础外功攻击"] = conf["基础外功攻击"] end
            if conf["基础内功攻击"] ~= -1 then t.base_attrs["基础内功攻击"] = conf["基础内功攻击"] end
            if conf["基础外功防御"] ~= -1 then t.base_attrs["基础外功防御"] = conf["基础外功防御"] end
            if conf["基础内功防御"] ~= -1 then t.base_attrs["基础内功防御"] = conf["基础内功防御"] end
            if conf["基础命中"] ~= -1 then t.base_attrs["基础命中"] = conf["基础命中"] end
            if conf["基础闪避"] ~= -1 then t.base_attrs["基础闪避"] = conf["基础闪避"] end
            t.ex_attrs = {}
            local ex_keys = {
                "增加HP的上限","百分比增加HP的上限","加快HP的回复速度",
                "增加MP的上限","百分比增加MP的上限","加快MP的回复速度",
                "冰攻击","冰抵抗","减少冰冻迟缓时间",
                "火攻击","火抵抗","减少火烧持续时间",
                "玄攻击","玄抵抗","减少玄击眩晕时间",
                "毒攻击","毒抵抗","减少中毒时间",
                "按百分比抵消所有属性攻击",
                "外功攻击","按百分比增加外功攻击","对装备基础外功攻击百分比加成",
                "外功防御","按百分比增加外功防御","对装备基础外功防御百分比加成",
                "按百分比抵消外功伤害",
                "内功攻击","按百分比增加内功攻击","对装备基础内功攻击百分比加成",
                "内功防御","按百分比增加内功防御","对装备基础内功防御百分比加成",
                "按百分比抵消内功伤害",
                "攻击速度(两次攻击间隔时间)","内功冷却速度",
                "命中","闪避","会心","无视对方防御比率","移动速度百分比",
                "伤害反射","伤害由内力抵消",
                "力量","灵气","体力","定力","身法",
                "会心防御","增加所有的人物一级属性","生命偷取","内力偷取",
                "增加某个技能等级","增加所有技能等级","特殊技能发动概率",
                "降低目标冰抵抗","降低目标火抵抗","降低目标玄抵抗","降低目标毒抵抗",
            }
            for _, key in ipairs(ex_keys) do
                if conf[key] ~= nil and conf[key] ~= -1 then
                    table.insert(t.ex_attrs, key)
                end
            end
            new_table[t.id] = t
            count = count + 1
        end
    end
    if count == 0 then
        return false, "EquipBase 解析后为空表"
    end
    self.equip_base = new_table
    self._loaded["read_equip_base"] = true
    sharetable.loadtable("equip_base", new_table)
    skynet.logi("[cfghelper] reload_equip_base done,", count, "equips")
    return true, string.format("装备配置重载成功, %d 条目", count)
end

function cfghelper:reload_monster_attr_ex()
    local read = require "txtreader".new()
    local configs = read:load("MonsterAttrExTable.txt")
    if not configs or not next(configs) then
        return false, "MonsterAttrExTable.txt 读取失败或为空"
    end
    local new_table = {}
    local count = 0
    for _, conf in pairs(configs) do
        local t = {}
        t.id = conf["怪物编号"]
        if t.id then
            t.name = conf["名称$1$"]
            t.sex = conf["怪物性别"]
            t.level = conf["等级"]
            t.speed = conf["移动速度"] / 1000
            t.walk_speed = conf["步行速度"] / 1000
            t.is_npc = conf["是否可以交互"] == 1
            t.reputation = conf["势力ID"]
            t.hp = conf["HP上限"]
            t.mp = conf["MP上限"]
            t.hp_max = conf["HP上限"]
            t.mp_max = conf["MP上限"]
            t.attrib_att_physics = conf["物理攻击"]
            t.attrib_def_physics = conf["物理防御"]
            t.attrib_att_magic = conf["魔法攻击"]
            t.attrib_def_magic = conf["魔法防御"]
            t.attrib_hit = conf["命中率"]
            t.attrib_miss = conf["闪避"]
            t.mind_attack = conf["会心率"]
            t.mind_defend = conf["会心防御"]
            t.att_cold = conf["冰攻击"]
            t.def_cold = conf["冰防御"]
            t.reduce_def_cold = conf["降低目标冰抵抗"]
            t.att_fire = conf["火攻击"]
            t.def_fire = conf["火防御"]
            t.reduce_def_fire = conf["降低目标火抵抗"]
            t.att_light = conf["电攻击"]
            t.def_light = conf["电防御"]
            t.reduce_def_light = conf["降低目标玄抵抗"]
            t.att_poison = conf["毒攻击"]
            t.def_poison = conf["毒防御"]
            t.reduce_def_poison = conf["降低目标毒抵抗"]
            t.base_exp = conf["基础经验获得"]
            t.is_boss = conf["BOSS标记"] == 1
            t.base_ai = conf["基础AI"]
            t.ai_script = conf["扩展AI"]
            t.attack_cool_down_time = conf["攻击冷却时间"]
            t.attack_anim_time = conf["攻击动作时间"]
            t.attack_type = conf["攻击特性ID"]
            t.camp_id = conf["阵营"]
            t.active_time = conf["激活时间"]
            new_table[t.id] = t
            count = count + 1
        end
    end
    if count == 0 then
        return false, "MonsterAttrExTable 解析后为空表"
    end
    self.monster_attr_ex = new_table
    self._loaded["read_monster_attr_ex"] = true
    sharetable.loadtable("monster_attr_ex", new_table)
    skynet.logi("[cfghelper] reload_monster_attr_ex done,", count, "monsters")
    return true, string.format("怪物属性配置重载成功, %d 条目", count)
end

function cfghelper:read_slot_cost()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("SlotCost.txt")
    for _, conf in pairs(configs) do
        local id = conf["INDEX(Level*100+孔数)"]
        if id then
            local t = {}
            t.cost = {}
            t.cost[1] = {}
            t.cost[1].money = conf["耗钱"]
            t.cost[1].item = {}
            t.cost[1].item.id = conf["物品1"]
            t.cost[1].item.count = conf["消耗数1"]
            t.cost[2] = {}
            t.cost[2].money = conf["耗钱2"]
            t.cost[2].item = {}
            t.cost[2].item.id = conf["物品2"]
            t.cost[2].item.count = conf["消耗数2"]
            transferd[id] = t
            --print("read_slot_cost id =", id, ";t =", table.tostr(t))
        end
    end
    self.slot_cost = transferd
end

function cfghelper:read_gem_carve()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("GemCarve.txt")
    for _, conf in pairs(configs) do
        local gemid = conf["宝石ID"]
        if gemid then
            local t = {}
            t.product_id = conf["雕琢后宝石ID"]
            t.need_money = conf["需要金钱"]
            t.need_item = conf["需要物品ID"]
            transferd[gemid] = t
            --print("read_slot_cost id =", gemid, ";t =", table.tostr(t))
        end
    end
    self.gem_carve = transferd
end

function cfghelper:read_gem_melting()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("GemMelting.txt")
    for _, conf in pairs(configs) do
        local gemid = conf["宝石ID"]
        if gemid then
            local t = {}
            t.product_id = conf["熔炼后宝石ID"]
            t.need_money = conf["需要金钱"]
            t.need_item = conf["需要物品ID"]
            transferd[gemid] = t
        end
    end
    self.gem_melting = transferd
end

function cfghelper:read_double_gem_compound()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("DoubleGemCompound.txt")
    for _, conf in pairs(configs) do
        local doubleid = conf["DoubleId"]
        if doubleid then
            local t = {}
            t.DoubleId = doubleid
            t.MainId = conf["MainId"]
            t.AssertId = conf["AssertId"]
            t.AssertNum = conf["AssertNum"]
            transferd[doubleid] = t
        end
    end
    self.double_gem_compound = transferd
end

function cfghelper:read_item_compound()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("ItemCompound.txt")
    for _, conf in pairs(configs) do
        local id = conf["index"]
        skynet.logd("read_item_compound t =", table.tostr(conf))
        assert(id, table.tostr(conf))
        transferd[id] = conf
    end
    self.item_compound = transferd
end

function cfghelper:read_ability()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("Ability.txt")
    for _, conf in pairs(configs) do
        local id = conf["ID"]
        if id then
            local t = conf
            transferd[id] = t
        end
    end
    self.ability = transferd
end

function cfghelper:read_menpaishenghuo()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("AbilityLevelUp/menpaishenghuo.txt")
    for _, conf in pairs(configs) do
        local id = conf["级别"]
        if id then
            local t = conf
            transferd[id] = t
        end
    end
    self.menpaishenghuo = transferd
end

function cfghelper:read_ability_level_up_zhuzao()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("AbilityLevelUp/zhuzao.txt")
    for _, conf in pairs(configs) do
        local id = conf["级别"]
        if id then
            local t = conf
            transferd[id] = t
        end
    end
    self.ability_level_up_zhuzao = transferd
end

function cfghelper:read_ability_level_up_diaoyu()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("AbilityLevelUp/diaoyu.txt")
    for _, conf in pairs(configs) do
        local id = conf["级别"]
        if id then
            local t = conf
            transferd[id] = t
        end
    end
    self.ability_level_up_diaoyu = transferd
end

function cfghelper:read_ability_level_up_caiyao()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("AbilityLevelUp/caiyao.txt")
    for _, conf in pairs(configs) do
        local id = conf["级别"]
        if id then
            local t = conf
            transferd[id] = t
        end
    end
    self.ability_level_up_caiyao = transferd
end

function cfghelper:read_ability_level_up_caikuang()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("AbilityLevelUp/caikuang.txt")
    for _, conf in pairs(configs) do
        local id = conf["级别"]
        if id then
            local t = conf
            transferd[id] = t
        end
    end
    self.ability_level_up_caikuang = transferd
end

function cfghelper:read_ability_level_up_dingweifu()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("AbilityLevelUp/dingweifu.txt")
    for _, conf in pairs(configs) do
        local id = conf["级别"]
        if id then
            local t = conf
            transferd[id] = t
        end
    end
    self.ability_level_up_dingweifu = transferd
end

function cfghelper:read_ability_level_up_fengren()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("AbilityLevelUp/fengren.txt")
    for _, conf in pairs(configs) do
        local id = conf["级别"]
        if id then
            local t = conf
            transferd[id] = t
        end
    end
    self.ability_level_up_fengren = transferd
end

function cfghelper:read_ability_level_up_pengren()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("AbilityLevelUp/pengren.txt")
    for _, conf in pairs(configs) do
        local id = conf["级别"]
        if id then
            local t = conf
            transferd[id] = t
        end
    end
    self.ability_level_up_pengren = transferd
end

function cfghelper:read_ability_level_up_yangsheng()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("AbilityLevelUp/yangsheng.txt")
    for _, conf in pairs(configs) do
        local id = conf["级别"]
        if id then
            local t = conf
            transferd[id] = t
        end
    end
    self.ability_level_up_yangsheng = transferd
end

function cfghelper:read_ability_level_up_yaoli()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("AbilityLevelUp/yaoli.txt")
    for _, conf in pairs(configs) do
        local id = conf["级别"]
        if id then
            local t = conf
            transferd[id] = t
        end
    end
    self.ability_level_up_yaoli = transferd
end

function cfghelper:read_ability_level_up_zhongzhi()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("AbilityLevelUp/zhongzhi.txt")
    for _, conf in pairs(configs) do
        local id = conf["级别"]
        if id then
            local t = conf
            transferd[id] = t
        end
    end
    self.ability_level_up_zhongzhi = transferd
end

function cfghelper:read_ability_level_up_assistant_menpai()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("AbilityLevelUp/assistant_menpai.txt")
    for _, conf in pairs(configs) do
        local id = conf["级别"]
        if id then
            local t = conf
            transferd[id] = t
        end
    end
    self.ability_level_up_assistant_menpai = transferd
end

function cfghelper:read_ability_level_up_assistant()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("AbilityLevelUp/assistant.txt")
    for _, conf in pairs(configs) do
        local id = conf["级别"]
        if id then
            local t = conf
            transferd[id] = t
        end
    end
    self.ability_level_up_assistant = transferd
end

function cfghelper:read_ability_level_up_cailiaojiagong()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("AbilityLevelUp/cailiaojiagong.txt")
    for _, conf in pairs(configs) do
        local id = conf["级别"]
        if id then
            local t = conf
            transferd[id] = t
        end
    end
    self.ability_level_up_cailiaojiagong = transferd
end

function cfghelper:read_ability_level_up_gaojishenghuo()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("AbilityLevelUp/gaojishenghuo.txt")
    for _, conf in pairs(configs) do
        local id = conf["级别"]
        if id then
            local t = conf
            transferd[id] = t
        end
    end
    self.ability_level_up_gaojishenghuo = transferd
end

function cfghelper:read_ability_level_up_gongyi()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("AbilityLevelUp/gongyi.txt")
    for _, conf in pairs(configs) do
        local id = conf["级别"]
        if id then
            local t = conf
            transferd[id] = t
        end
    end
    self.ability_level_up_gongyi = transferd
end

function cfghelper:read_ability_level_up_menpai()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("AbilityLevelUp/menpai.txt")
    for _, conf in pairs(configs) do
        local id = conf["级别"]
        if id then
            local t = conf
            transferd[id] = t
        end
    end
    self.ability_level_up_menpai = transferd
end

function cfghelper:read_ability_level_up_menpaifuzhu()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("AbilityLevelUp/menpaifuzhu.txt")
    for _, conf in pairs(configs) do
        local id = conf["级别"]
        if id then
            local t = conf
            transferd[id] = t
        end
    end
    self.ability_level_up_menpaifuzhu = transferd
end

function cfghelper:read_ability_level_up_normal()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("AbilityLevelUp/normal.txt")
    for _, conf in pairs(configs) do
        local id = conf["级别"]
        if id then
            local t = conf
            transferd[id] = t
        end
    end
    self.ability_level_up_normal = transferd
end

function cfghelper:read_ability_level_up_putongshenghuo()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("AbilityLevelUp/putongshenghuo.txt")
    for _, conf in pairs(configs) do
        local id = conf["级别"]
        if id then
            local t = conf
            transferd[id] = t
        end
    end
    self.ability_level_up_putongshenghuo = transferd
end

function cfghelper:read_ability_level_up_shenghuofuzhu()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("AbilityLevelUp/shenghuofuzhu.txt")
    for _, conf in pairs(configs) do
        local id = conf["级别"]
        if id then
            local t = conf
            transferd[id] = t
        end
    end
    self.ability_level_up_shenghuofuzhu = transferd
end

function cfghelper:read_ability_level_up_xiangqian()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("AbilityLevelUp/xiangqian.txt")
    for _, conf in pairs(configs) do
        local id = conf["级别"]
        if id then
            local t = conf
            transferd[id] = t
        end
    end
    self.ability_level_up_xiangqian = transferd
end

function cfghelper:read_ability_level_up_zhiyao()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("AbilityLevelUp/zhiyao.txt")
    for _, conf in pairs(configs) do
        local id = conf["级别"]
        if id then
            local t = conf
            transferd[id] = t
        end
    end
    self.ability_level_up_zhiyao = transferd
end

function cfghelper:read_ability_level_up_dingweifu()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("AbilityLevelUp/dingweifu.txt")
    for _, conf in pairs(configs) do
        local id = conf["级别"]
        if id then
            local t = conf
            transferd[id] = t
        end
    end
    self.ability_level_up_dingweifu = transferd
end

function cfghelper:read_dress_color_rate()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("DressColorRate.txt")
    for _, conf in pairs(configs) do
        local id = conf["ID"]
        if id then
            local t = {}
            t.desc = conf["描述"]
            t.cost_item_id = conf["消耗材料ID"]
            t.visual = {}
            for i = 1, 9 do
                local v = {}
                local key = string.format("外观%dID", i)
                v.id = conf[key]
                key = string.format("概率%d", i)
                v.rate = conf[key]
                table.insert(t.visual, v)
            end
            skynet.logd("cfghelper:read_dress_color_rate =", table.tostr(t))
            transferd[id] = t
        end
    end
    self.dress_color_rate = transferd
end

function cfghelper:read_exterior_head()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("Exterior_Head.txt")
    for _, conf in pairs(configs) do
        local id = conf["ID"]
        if id then
            local t = {}
            t[0] = conf["女"]
            t[1] = conf["男"]
            skynet.logd("cfghelper:read_exterior_head =", table.tostr(t))
            transferd[id] = t
        end
    end
    self.exterior_head = transferd
end

function cfghelper:read_exterior_face()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("Exterior_Face.txt")
    for _, conf in pairs(configs) do
        local id = conf["ID"]
        if id then
            local t = {}
            t[0] = conf["女"]
            t[1] = conf["男"]
            skynet.logd("cfghelper:read_exterior_face =", table.tostr(t))
            transferd[id] = t
        end
    end
    self.exterior_face = transferd
end

function cfghelper:read_exterior_hair()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("Exterior_Hair.txt")
    for _, conf in pairs(configs) do
        local id = conf["ID"]
        if id then
            local t = {}
            t[0] = conf["女"]
            t[1] = conf["男"]
            skynet.logd("cfghelper:read_exterior_hair =", table.tostr(t))
            transferd[id] = t
        end
    end
    self.exterior_hair = transferd
end

function cfghelper:read_char_face_geo()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("CharFaceGeo.txt")
    for _, conf in pairs(configs) do
        local id = conf["ID"]
        if id then
            local t = {}
            t.cost_item_id = conf["消耗物品ID"]
            t.cost_item_count = conf["消耗物品数量"]
            t.cost_money = conf["消耗金钱"]
            print("cfghelper:read_char_face_geo =", table.tostr(t))
            transferd[id] = t
        end
    end
    self.char_face_geo = transferd
end

function cfghelper:read_char_hair_geo()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("CharHairGeo.txt")
    for _, conf in pairs(configs) do
        local id = conf["ID"]
        if id then
            local t = {}
            t.cost_item_id = conf["消耗物品ID"]
            t.cost_item_count = conf["消耗物品数量"]
            t.cost_money = conf["消耗金钱"]
            print("cfghelper:read_char_hair_geo =", table.tostr(t))
            transferd[id] = t
        end
    end
    self.char_hair_geo = transferd
end

function cfghelper:read_equip_extra_attr()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("EquipExtraAttr.txt")
    for _, conf in pairs(configs) do
        local id = conf["Index"]
        if id then
            local t = {}
            t.id = id
            t.expiration_date = conf["有效期(小时)"]
            t.expiration_date_calculate_when_equipped = conf["是否装备时计算有效期"]
            t.yuanbao_exchange_type = conf["元宝交易类型:0可元宝交易，1不可元宝交易，2即可元宝交易也可金币交易"]
            t.sell_money_type = conf["卖店是否获得交子，1获得交子，0获得金币"]
            print("cfghelper:read_equip_extra_attr =", table.tostr(t))
            transferd[id] = t
        end
    end
    self.equip_extra_attr = transferd
end

function cfghelper:read_pet_attr_table()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("PetAttrTable.txt")
    for _, conf in pairs(configs) do
        local id = conf["宠物编号"]
        if id then
            local t = {}
            t.id = id
            t.name = conf["名称$1$"]
            t.type = conf["宠物类型"]
            t.take_level = conf["可携带等级"]
            t.is_mutated = conf["是否变异"]
            t.is_baby_type = conf["是否宝宝"] == 1
            t.is_var_type = conf["是否变异"] == 1
            t.food_type = conf["食物类"]
            t.can_study_skill_count = conf["所能学的技能数"]

            t.skill = {}
            t.skill.activate = {}
            t.skill.activate[1] = {}
            t.skill.activate[1].id = conf["主动技能"]
            t.skill.activate[1].build_probility = conf["主动技能生成几率（1/100w）"]

            t.skill.activate[2] = {}
            t.skill.activate[2].id = conf["主动技能2"]
            t.skill.activate[2].build_probility = conf["主动技能2生成几率（1/100w）"]

            t.skill.positive = {}
            t.skill.positive[1] = {}
            t.skill.positive[1].id = conf["被动技能1"]
            t.skill.positive[1].build_probility = conf["被动技能1生成几率（1/100w）"]

            t.skill.positive[2] = {}
            t.skill.positive[2].id = conf["被动技能2"]
            t.skill.positive[2].build_probility = conf["被动技能2生成几率（1/100w）"]

            t.skill.positive[3] = {}
            t.skill.positive[3].id = conf["被动技能3"]
            t.skill.positive[3].build_probility = conf["被动技能3生成几率（1/100w）"]

            t.skill.positive[4] = {}
            t.skill.positive[4].id = conf["被动技能4"]
            t.skill.positive[4].build_probility = conf["被动技能4生成几率（1/100w）"]

            t.skill.positive[5] = {}
            t.skill.positive[5].id = conf["被动技能5"]
            t.skill.positive[5].build_probility = conf["被动技能5生成几率（1/100w）"]

            t.skill.positive[6] = {}
            t.skill.positive[6].id = conf["被动技能6"]
            t.skill.positive[6].build_probility = conf["被动技能6生成几率（1/100w）"]

            t.skill.positive[7] = {}
            t.skill.positive[7].id = conf["被动技能7"]
            t.skill.positive[7].build_probility = conf["被动技能7生成几率（1/100w）"]

            t.skill.positive[8] = {}
            t.skill.positive[8].id = conf["被动技能8"]
            t.skill.positive[8].build_probility = conf["被动技能8生成几率（1/100w）"]

            t.skill.positive[9] = {}
            t.skill.positive[9].id = conf["被动技能9"]
            t.skill.positive[9].build_probility = conf["被动技能9生成几率（1/100w）"]

            t.skill.positive[10] = {}
            t.skill.positive[10].id = conf["被动技能10"]
            t.skill.positive[10].build_probility = conf["被动技能10生成几率（1/100w）"]

            t.life_span = conf["标准寿命"]

            t.str_perception = conf["标准力量资质"]
            t.con_perception = conf["标准体质资质"]
            t.spr_perception = conf["标准灵气资质"]
            t.dex_perception = conf["标准身法资质"]
            t.int_perception = conf["标准定力资质"]

            t.growth_rate = {}
            t.growth_rate[1] = conf["成长率1"]
            t.growth_rate[2] = conf["成长率2"]
            t.growth_rate[3] = conf["成长率3"]
            t.growth_rate[4] = conf["成长率4"]
            t.growth_rate[5] = conf["成长率5"]

            t.ai_type = {}
            t.ai_type[0] = conf["胆小(1/1000)"]
            t.ai_type[1] = conf["谨慎(1/1000)"]
            t.ai_type[2] = conf["忠诚(1/1000)"]
            t.ai_type[3] = conf["精明(1/1000)"]
            t.ai_type[4] = conf["勇猛(1/1000)"]

            t.breeding_time = conf["宠物繁殖时间(ms)"]
            t.similar_pet_type = conf["同类参考珍兽类型"]

            print("cfghelper:read_pet_attr_table =", table.tostr(t))
            transferd[id] = t
        end
    end
    self.pet_attr_table = transferd
end

function cfghelper:read_pet_collection()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("PetCollection.txt")
    for _, conf in pairs(configs) do
        local values = conf["INT"]
        if type(values) == "table" and #values >= 3 then
            table.insert(transferd, {
                data_id = values[1],
                order = values[2],
                name = conf["STRING"],
                group = values[3],
            })
        end
    end
    table.sort(transferd, function(left, right)
        return left.order < right.order
    end)
    self.pet_collection = transferd
end

function cfghelper:read_pet_config_table()
    local inireader = require "inireader".new()
    self.pet_config_table = inireader:load("PetConfigTable.ini")
end

function cfghelper:read_pet_attr_point_distribute()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("PetAttrPointDistribute.txt")
    for _, conf in pairs(configs) do
        local id = conf["方案号"]
        if id then
            local t = {}
            t.id = id
            t.str = conf["属性1概率"]
            t.con = conf["属性2概率"]
            t.spr = conf["属性3概率"]
            t.dex = conf["属性4概率"]
            t.int = conf["属性5概率"]
            print("cfghelper:pet_attr_point_distribute =", table.tostr(t))
            transferd[id] = t
        end
    end
    self.pet_attr_point_distribute = transferd
end

function cfghelper:read_pet_skill_distribute()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("PetSkillDistribute.txt")
    for _, conf in pairs(configs) do
        local id = conf[1]
        if id then
            local t = {}
            t.id = id
            t.name = conf[2]
            t.skills = {}
            for index, val in ipairs(conf) do
                index = index - 3
                if index >= 0 then
                    if val > 0 then
                        local skill = { index = index, p = val}
                        table.insert(t.skills, skill)
                    end
                end
            end
            print("cfghelper:read_pet_skill_distribute =", table.tostr(t))
            transferd[id] = t
        end
    end
    self.pet_skill_distribute = transferd
end

function cfghelper:read_pet_skill_index_table()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("PetSkillIndexTable.txt")
    for _, conf in pairs(configs) do
        local id = conf["技能索引号"]
        if id then
            local t = {}
            t.id = id
            t.skill = conf["技能ID"]
            print("cfghelper:pet_skill_index_table =", table.tostr(t))
            transferd[id] = t
        end
    end
    self.pet_skill_index_table = transferd
end

function cfghelper:read_pet_ai_stratety_table()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("PetAIStrategyTbl.txt")
    for _, conf in pairs(configs) do
        local id = conf["ID"]
        if id then
            local t = transferd[id] or {}
            t[0] = conf["胆小"]
            t[1] = conf["警慎"]
            t[2] = conf["忠诚"]
            t[3] = conf["精明"]
            t[4] = conf["勇猛"]
            print("cfghelper:pet_ai_stratety_table =", table.tostr(t))
            transferd[id] = t
        end
    end
    self.pet_ai_stratety_table = transferd
end

function cfghelper:read_camp_and_stand()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("CampAndStand.txt")
    for _, conf in pairs(configs) do
        local id = conf["Camp\\Camp"]
        if id then
            local t = {}
            for key, val in pairs(conf) do
                local n = tonumber(key)
                if n then
                    t[n] = val
                end
            end
            print("cfghelper:read_camp_and_stand =", table.tostr(t))
            transferd[id] = t
        end
    end
    self.camp_and_stand = transferd
end

function cfghelper:read_pet_level_up_table()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("PetLevelUpTable.txt")
    for _, conf in pairs(configs) do
        transferd[conf["宠物等级"]] = conf["升级经验"]
    end
    self.pet_level_up_table = transferd
end

function cfghelper:read_pet_apperceive_skill_table()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("PetApperceiveSkillTable.txt")
    for _, conf in pairs(configs) do
        local id = conf["编号"]
        if id then
            local t = {}
            t.id = id
            t.skill_count = conf["宠物技能总数"]
            t.voluntary_skill_count = conf["已有主动技能数"]
            t.passive_skill_count = conf["已有被动技能数"]
            t.voluntary_rate = conf["领悟主动技能概率（单位1/10w）"]
            t.passive_rate = conf["领悟被动技能概率（单位1/10w）"]
            transferd[id] = t
        end
    end
    self.pet_apperceive_skill_table = transferd
end

function cfghelper:read_dark_exp_level()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("DarkExpLevel.txt")
    for _, conf in pairs(configs) do
        transferd[conf["Level"]] = conf["Exp"]
    end
    self.dark_exp_level = transferd
end

function cfghelper:read_dark_skill_list()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("DarkSkillList.txt")
    for _, conf in pairs(configs) do
        local skill_id = conf["技能ID"]
        local grade = conf["品阶"]
        local type = conf["技能类型"]
        local impacts = {}
        impacts[10] = conf["10级技能"]
        impacts[20] = conf["20级技能"]
        impacts[30] = conf["30级技能"]
        impacts[40] = conf["40级技能"]
        impacts[50] = conf["50级技能"]
        impacts[60] = conf["60级技能"]
        impacts[70] = conf["70级技能"]
        impacts[80] = conf["80级技能"]
        impacts[90] = conf["90级技能"]
        impacts[100] = conf["100级技能"]
        impacts[110] = conf["110级技能"]
        impacts[120] = conf["120级技能"]
        impacts[130] = conf["130级技能"]
        impacts[140] = conf["140级技能"]
        impacts[150] = conf["150级技能"]
        impacts[160] = conf["160级技能"]

        local grades = transferd[skill_id] or {}
        transferd[skill_id] = grades
        local grade_type_impacts = grades[grade] or {}
        grades[grade] = grade_type_impacts
        grade_type_impacts[type] = impacts
    end
    print("cfghelper:read_dark_skill_list", table.tostr(transferd))
    self.dark_skill_list = transferd
end

function cfghelper:read_pet_skill_book()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("PetSkillBook.txt")
    for _, conf in pairs(configs) do
        local id = conf["珍兽技能书的物品ID"]
        local skill = conf["珍兽技能书所对应的技能ID"]
        transferd[id] = skill
    end
    print("cfghelper:read_pet_skill_book", table.tostr(transferd))
    self.pet_skill_book = transferd
end

function cfghelper:read_pet_study_skill_table()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("PetStudySkllTable.txt")
    for _, conf in pairs(configs) do
        local id = conf["编号"]
        local max_skill_count = conf["被动技能最大数"]
        local non_skill_count = conf["被动技能空位数"]
        local odd = conf["打在新格的几率（分母1000）"]
        transferd[id] = { max_skill_count = max_skill_count, non_skill_count = non_skill_count, odd = odd }
    end
    print("cfghelper:pet_study_skill_table", table.tostr(transferd))
    self.pet_study_skill_table = transferd
end

function cfghelper:read_pet_huan_hua_table()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("PetHuanhuaTable.txt")
    for _, conf in pairs(configs) do
        local id = conf["旧外观ID"]
        local model_1 = conf["幻化外观1"]
        local model_2 = conf["幻化外观2"]
        local cost = conf["金币"]
        transferd[id] = { [1] = model_1, [2] = model_2, cost = cost }
    end
    print("cfghelper:read_pet_huan_hua_table", table.tostr(transferd))
    self.pet_huan_hua_table = transferd
end


function cfghelper:read_pet_equip_base()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("PetEquipBase.txt")
    for _, conf in pairs(configs) do
        local t = {}
        t.id = conf["Index"]
        if t.id then
            t.class = conf["class(基本类型)"]
            t.quality = conf["Quality(品质)"]
            t.type = conf["Type(类别)"]
            t.index = conf["Index(物品号)"]
            t.equip_point = conf["EquipPoint(装备点)"]
            t.visual = conf["Visual"]
            t.rule = conf["适应规则"]
            t.set_id = conf["套装编号"]
            t.max_gem_slot = conf["镶嵌宝石上限"]
            t.level = conf["Lv(需求等级)"]
            t.max_dur = conf["Max耐久"]
            t.skill_id = conf["技能ID：装备点为武器时标识效果ID（From StandardImpact.txt）"]
            t.script_id = conf["脚本ID"]
            t.name = conf["Name(名称)$1$"]
            t.base_price = conf["基本价格"]
            t.sell_price = conf["出售价格"]
            t.broad_cast = conf["是否广播"] == 1
            t["是否有资质"] = conf["是否有资质"]
            t["品质规则"] = conf["品质规则"]
            t["起始数值段"] = conf["起始数值段"]
            t["起始数值段"] = conf["起始数值段"]
            t["属性条数min"] = conf["属性条数min"]
            t["属性条数max"] = conf["属性条数max"]
            t["资质min"] = conf["资质min"]
            t["资质max"] = conf["资质max"]
            t["行囊"] = conf["行囊"]
            t["格箱"] = conf["格箱"]
            t["品阶"] = conf["品阶"]
            t.base_attrs = {}
            if conf["基础外功攻击"] ~= -1 then
                t.base_attrs["基础外功攻击"] = conf["基础外功攻击"]
            end
            if conf["基础内功攻击"] ~= -1 then
                t.base_attrs["基础内功攻击"] = conf["基础内功攻击"]
            end
            if conf["基础外功防御"] ~= -1 then
                t.base_attrs["基础外功防御"] = conf["基础外功防御"]
            end
            if conf["基础内功防御"] ~= -1 then
                t.base_attrs["基础内功防御"] = conf["基础内功防御"]
            end
            if conf["基础命中"] ~= -1 then
                t.base_attrs["基础命中"] = conf["基础命中"]
            end
            if conf["基础闪避"] ~= -1 then
                t.base_attrs["基础闪避"] = conf["基础闪避"]
            end
            t.ex_attrs = {}
            if conf["增加HP的上限"] ~= -1 then
                table.insert(t.ex_attrs, "增加HP的上限")
            end
            if conf["百分比增加HP的上限"] ~= -1 then
                table.insert(t.ex_attrs, "百分比增加HP的上限")
            end
            if conf["加快HP的回复速度"] ~= -1 then
                table.insert(t.ex_attrs, "加快HP的回复速度")
            end
            if conf["增加MP的上限"] ~= -1 then
                table.insert(t.ex_attrs, "增加MP的上限")
            end
            if conf["百分比增加MP的上限"] ~= -1 then
                table.insert(t.ex_attrs, "百分比增加MP的上限")
            end
            if conf["加快MP的回复速度"] ~= -1 then
                table.insert(t.ex_attrs, "加快MP的回复速度")
            end
            if conf["冰攻击"] ~= -1 then
                table.insert(t.ex_attrs, "冰攻击")
            end
            if conf["冰抵抗"] ~= -1 then
                table.insert(t.ex_attrs, "冰抵抗")
            end
            if conf["减少冰冻迟缓时间"] ~= -1 then
                table.insert(t.ex_attrs, "减少冰冻迟缓时间")
            end
            if conf["火攻击"] ~= -1 then
                table.insert(t.ex_attrs, "火攻击")
            end
            if conf["火抵抗"] ~= -1 then
                table.insert(t.ex_attrs, "火抵抗")
            end
            if conf["减少火烧持续时间"] ~= -1 then
                table.insert(t.ex_attrs, "减少火烧持续时间")
            end
            if conf["玄攻击"] ~= -1 then
                table.insert(t.ex_attrs, "玄攻击")
            end
            if conf["玄抵抗"] ~= -1 then
                table.insert(t.ex_attrs, "玄抵抗")
            end
            if conf["减少玄击眩晕时间"] ~= -1 then
                table.insert(t.ex_attrs, "减少玄击眩晕时间")
            end
            if conf["毒攻击"] ~= -1 then
                table.insert(t.ex_attrs, "毒攻击")
            end
            if conf["毒抵抗"] ~= -1 then
                table.insert(t.ex_attrs, "毒抵抗")
            end
            if conf["减少中毒时间"] ~= -1 then
                table.insert(t.ex_attrs, "减少中毒时间")
            end
            if conf["按百分比抵消所有属性攻击"] ~= -1 then
                table.insert(t.ex_attrs, "按百分比抵消所有属性攻击")
            end
            if conf["外功攻击"] ~= -1 then
                table.insert(t.ex_attrs, "外功攻击")
            end
            if conf["按百分比增加外功攻击"] ~= -1 then
                table.insert(t.ex_attrs, "按百分比增加外功攻击")
            end
            if conf["对装备基础外功攻击百分比加成"] ~= -1 then
                table.insert(t.ex_attrs, "对装备基础外功攻击百分比加成")
            end
            if conf["外功防御"] ~= -1 then
                table.insert(t.ex_attrs, "外功防御")
            end
            if conf["按百分比增加外功防御"] ~= -1 then
                table.insert(t.ex_attrs, "按百分比增加外功防御")
            end
            if conf["对装备基础外功防御百分比加成"] ~= -1 then
                table.insert(t.ex_attrs, "对装备基础外功防御百分比加成")
            end
            if conf["按百分比抵消外功伤害"] ~= -1 then
                table.insert(t.ex_attrs, "按百分比抵消外功伤害")
            end
            if conf["内功攻击"] ~= -1 then
                table.insert(t.ex_attrs, "内功攻击")
            end
            if conf["按百分比增加内功攻击"] ~= -1 then
                table.insert(t.ex_attrs, "按百分比增加内功攻击")
            end
            if conf["对装备基础内功攻击百分比加成"] ~= -1 then
                table.insert(t.ex_attrs, "对装备基础内功攻击百分比加成")
            end
            if conf["内功防御"] ~= -1 then
                table.insert(t.ex_attrs, "内功防御")
            end
            if conf["按百分比增加内功防御"] ~= -1 then
                table.insert(t.ex_attrs, "按百分比增加内功防御")
            end
            if conf["对装备基础内功防御百分比加成"] ~= -1 then
                table.insert(t.ex_attrs, "对装备基础内功防御百分比加成")
            end
            if conf["按百分比抵消内功伤害"] ~= -1 then
                table.insert(t.ex_attrs, "按百分比抵消内功伤害")
            end
            if conf["攻击速度(两次攻击间隔时间)"] ~= -1 then
                table.insert(t.ex_attrs, "攻击速度(两次攻击间隔时间)")
            end
            if conf["内功冷却速度"] ~= -1 then
                table.insert(t.ex_attrs, "内功冷却速度")
            end
            if conf["命中"] ~= -1 then
                table.insert(t.ex_attrs, "命中")
            end
            if conf["闪避"] ~= -1 then
                table.insert(t.ex_attrs, "闪避")
            end
            if conf["会心"] ~= -1 then
                table.insert(t.ex_attrs, "会心")
            end
            if conf["无视对方防御比率"] ~= -1 then
                table.insert(t.ex_attrs, "无视对方防御比率")
            end
            if conf["移动速度百分比"] ~= -1 then
                table.insert(t.ex_attrs, "移动速度百分比")
            end
            if conf["伤害反射"] ~= -1 then
                table.insert(t.ex_attrs, "伤害反射")
            end
            if conf["伤害由内力抵消"] ~= -1 then
                table.insert(t.ex_attrs, "伤害由内力抵消")
            end
            if conf["力量"] ~= -1 then
                table.insert(t.ex_attrs, "力量")
            end
            if conf["灵气"] ~= -1 then
                table.insert(t.ex_attrs, "灵气")
            end
            if conf["体力"] ~= -1 then
                table.insert(t.ex_attrs, "体力")
            end
            if conf["定力"] ~= -1 then
                table.insert(t.ex_attrs, "定力")
            end
            if conf["身法"] ~= -1 then
                table.insert(t.ex_attrs, "身法")
            end
            if conf["会心防御"] ~= -1 then
                table.insert(t.ex_attrs, "会心防御")
            end
            if conf["增加所有的人物一级属性"] ~= -1 then
                table.insert(t.ex_attrs, "增加所有的人物一级属性")
            end
            if conf["生命偷取"] ~= -1 then
                table.insert(t.ex_attrs, "生命偷取")
            end
            if conf["内力偷取"] ~= -1 then
                table.insert(t.ex_attrs, "内力偷取")
            end
            if conf["增加某个技能等级"] ~= -1 then
                table.insert(t.ex_attrs, "增加某个技能等级")
            end
            if conf["增加所有技能等级"] ~= -1 then
                table.insert(t.ex_attrs, "增加所有技能等级")
            end
            if conf["特殊技能发动概率"] ~= -1 then
                table.insert(t.ex_attrs, "特殊技能发动概率")
            end
            if conf["降低目标冰抵抗"] ~= -1 then
                table.insert(t.ex_attrs, "降低目标冰抵抗")
            end
            if conf["降低目标火抵抗"] ~= -1 then
                table.insert(t.ex_attrs, "降低目标火抵抗")
            end
            if conf["降低目标玄抵抗"] ~= -1 then
                table.insert(t.ex_attrs, "降低目标玄抵抗")
            end
            if conf["降低目标毒抵抗"] ~= -1 then
                table.insert(t.ex_attrs, "降低目标毒抵抗")
            end
            print("宠物装备基础信息 =", table.tostr(t))
            transferd[t.id] = t
        end
    end
    self.pet_equip_base = transferd
    --print("read_equip_base =", table.tostr(transferd))
end

function cfghelper:read_pet_soul_level_up_info()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("PetSoulLevelupInfo.txt")
    for _, conf in pairs(configs) do
        local item_index = conf["装备ID"]
        local level = conf["等级"]
        local add_str_perception = conf["力量资质加成"]
        local add_spr_perception = conf["灵气资质加成"]
        local add_con_perception = conf["体力资质加成"]
        local add_dex_perception = conf["定力资质加成"]
        local add_int_perception = conf["身法资质加成"]

        local add = { add_str_perception = add_str_perception, add_spr_perception = add_spr_perception, add_con_perception = add_con_perception, add_dex_perception = add_dex_perception, add_int_perception = add_int_perception}
        local info = transferd[item_index] or {}
        info[level] = add
        transferd[item_index] = info
    end
    print("cfghelper:read_pet_soul_level_up_info", table.tostr(transferd))
    self.pet_soul_level_up_info = transferd
end

function cfghelper:read_pet_soul_extension()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("PetSoulExtension.txt")
    for _, conf in pairs(configs) do
        local index = conf["Index"]
        local values = { conf["Value_1"], conf["Value_2"], conf["Value_3"], conf["Value_4"], conf["Value_5"], conf["Value_6"], conf["Value_7"], conf["Value_8"], conf["Value_9"], conf["Value_10"], conf["Value_11"], conf["Value_12"]}
        transferd[index] = values
    end
    print("cfghelper:read_pet_soul_extension", table.tostr(transferd))
    self.pet_soul_extension = transferd
end

function cfghelper:read_item_enhance()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("ItemEnhance.txt")
    for _, conf in pairs(configs) do
        local id = conf["索引"]
        if id then
            local t = {}
            t.id = id
            t.slot = conf["装备点"]
            t.level = conf["强化等级"]
            t.cost_money = conf["收取金钱"]
            t.odd = conf["成功率"]
            t.down_level = conf["退化等级"]
            t.bonus = {}
            t.bonus[define.ITEM_ATTRIBUTE.IATTRIBUTE_RATE_ATTACK_EP] = conf["外攻"]
            t.bonus[define.ITEM_ATTRIBUTE.IATTRIBUTE_RATE_ATTACK_EM]  = conf["内攻"]
            t.bonus[define.ITEM_ATTRIBUTE.IATTRIBUTE_RATE_DEFENCE_EP] = conf["外防"]
            t.bonus[define.ITEM_ATTRIBUTE.IATTRIBUTE_RATE_DEFENCE_EM]  = conf["内防"]
            t.bonus[define.ITEM_ATTRIBUTE.IATTRIBUTE_RATE_BASE_HIT] = conf["命中"]
            t.bonus[define.ITEM_ATTRIBUTE.IATTRIBUTE_RATE_BASE_MISS]  = conf["闪避"]

            print("cfghelper:read_item_enhance", table.tostr(t))
            transferd[id] = t
        end
    end
    self.item_enhance = transferd
end

function cfghelper:read_special_obj_data()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("SpecialObjData.txt")
    for _, conf in pairs(configs) do
        local id = conf["ID"]
        if id then
            local t = {}
            t.id = id
            t.name = conf["名称$1$"]
            t.desc = conf["ToolTips$1$"]
            t.class = conf["类别"]
            t.logic_id = conf["逻辑ID"]
            t.stealth_level = conf["隐形级别"]
            t.continuance = conf["持续时间"]
            t.interval = conf["激活或触发时间间隔"]
            t.trigger_radious = conf["触发半径"]
            t.effect_radious = conf["影响半径"]
            t.affect_count = conf["影响个体数目"]
            t.active_times = conf["可激活次数"]
            t.trap_used_flag = conf["陷阱专用标记"]
            t.descriptor = {}
            local descs = conf["参数说明"]
            local values = conf["参数值"]
            for i, desc in ipairs(descs) do
                t.descriptor[desc] = values[i]
            end
            print("cfghelper:read_special_obj_data", table.tostr(t))
            transferd[id] = t
        end
    end
    self.special_obj_data = transferd
end

function cfghelper:read_pet_soul_base()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("PetSoulBase.txt")
    for _, conf in pairs(configs) do
        local id = conf["兽魂ID"]
        local level = conf["兽魂等级"]
        local exp_1 = conf["经验_1"]
        local exp_2 = conf["经验_2"]
        local exp_3 = conf["经验_3"]
        local exp_4 = conf["经验_4"]
        local exp_5 = conf["经验_5"]
        local exp_6 = conf["经验_6"]
        local exps = { exp_1, exp_2, exp_3, exp_4, exp_5, exp_6 }
        local skill = conf["技能ID"]
        local data_id_1 = conf["宠物模型_1"]
        local data_id_2 = conf["宠物模型_2"]
        local data_id_3 = conf["宠物模型_3"]
        local data_id_4 = conf["宠物模型_4"]
        local data_id_5 = conf["宠物模型_5"]
        local data_id_6 = conf["宠物模型_6"]
        local data_id = { data_id_1, data_id_2, data_id_3, data_id_4, data_id_5, data_id_6}
        local model_1 = conf["宠物融魂_1"]
        local model_2 = conf["宠物融魂_2"]
        local model_3 = conf["宠物融魂_3"]
        local model_4 = conf["宠物融魂_4"]
        local model_5 = conf["宠物融魂_5"]
        local model_6 = conf["宠物融魂_6"]
        local soul_melting_models = { model_1, model_2, model_3, model_4, model_5, model_6}
        local material = conf["材料"]
        transferd[id] = { level = level, exps = exps, material = material, model_id = data_id, soul_melting_models = soul_melting_models, skill = skill}
    end
    print("cfghelper:read_pet_soul_base", table.tostr(transferd))
    self.pet_soul_base = transferd
end

-- 兽灵技能池: PetJL model → PetElfSkill skill_id 列表
local ELF_SKILL_POOLS = {
    ["Kunwu11_8"]  = {16,17,18,19,20,21,31,54,55,56,57,60},
    ["Kunwu11_9"]  = {22,23,24,25,26,27,28,29,30,48,49,50,51,52,53},
    ["Kunwu11_5"]  = {11,12,13,14,15,36,37,38,39,40,41,42,43,44,45,46,47},
    ["Kunwu11_6"]  = {1,2,3,4,5,6,7,8,9,10,61,62,63,64},
    ["Kunwu11_7"]  = {32,33,34,35,58,59},
    ["Kunwu11_10"] = {1,2,3,4,5,6,7,8,9,10,61,62,63,64},
}

-- PetJL: 兽灵物品表 (item_id -> {attack_type, grade, model, skill_pool})
-- PetJL.txt 无列名行, 18列: INT STRING INT*14 STRING INT
-- conf["INT"]    = {item_id, attack_type, grade, type, cfg_id, ...共16个}
-- conf["STRING"] = {name, model}
function cfghelper:read_pet_jl()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("PetJL.txt")
    for _, conf in pairs(configs) do
        local ints = conf["INT"]
        local strs = conf["STRING"]
        if type(ints) == "table" and #ints >= 1 then
            local id = ints[1]
            if id and id > 0 then
                local model = ""
                if type(strs) == "table" then
                    model = strs[2] or ""
                elseif type(strs) == "string" then
                    model = strs
                end
                local pool = ELF_SKILL_POOLS[model] or {}
                transferd[id] = {
                    attack_type = ints[2] or 0,
                    grade = ints[3] or 0,
                    model = model,
                    flag  = ints[16] or 0,
                    skill_pool = pool,
                }
            end
        end
    end
    self.pet_jl = transferd
end

-- PetJLAttr: 兽灵属性值表 (level -> {[attr_key]=value}, attr_pool)
-- PetJLAttr.txt 无列名行, 67列全INT: level, attr0..attr65
function cfghelper:read_pet_jl_attr()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("PetJLAttr.txt")
    local attr_pool = {}
    for _, conf in pairs(configs) do
        local vals = conf["INT"]
        if type(vals) == "table" and #vals >= 2 then
            local level = vals[1]
            if level and level > 0 then
                transferd[level] = {}
                for j = 2, #vals do
                    transferd[level][j - 2] = vals[j]
                end
            end
        end
    end
    if transferd[1] then
        for k = 0, 65 do
            if transferd[1][k] and transferd[1][k] > 0 then
                table.insert(attr_pool, k)
            end
        end
    end
    transferd.attr_pool = attr_pool
    self.pet_jl_attr = transferd
end

function cfghelper:get_pet_jl_attr()
    return self.pet_jl_attr
end

-- PetElfSkill: 兽灵技能定义表 (skill_id -> {name, use_type, impact_id, ...})
function cfghelper:read_pet_elf_skill()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("PetElfSkill.txt")
    for _, conf in pairs(configs) do
        local ints = conf["INT"]
        local name = conf["STRING"]
        if type(ints) == "table" and #ints >= 2 then
            local id = ints[1]
            if id and id > 0 then
                transferd[id] = {
                    name = name or "",
                    use_type = ints[2] or 0,
                    impact_id = ints[3] or -1,
                    impact_id2 = ints[4] or -1,
                    upgrade_skills = {ints[5] or -1, ints[6] or -1, ints[7] or -1, ints[8] or -1},
                    ints = ints,
                }
            end
        end
    end
    self.pet_elf_skill = transferd
end

function cfghelper:get_pet_elf_skill()
    return self.pet_elf_skill
end

function cfghelper:read_pet_soul_level_cost()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("PetSoulLevelcost.txt")
    for _, conf in pairs(configs) do
        local level = conf["Level"]
        local cost_1 = conf["Cost_1"]
        local cost_money_1 = conf["Cost_Money_1"]
        local cost_2 = conf["Cost_2"]
        local cost_money_2 = conf["Cost_Money_2"]
        local cost_3 = conf["Cost_3"]
        local cost_money_3 = conf["Cost_Money_3"]
        local cost_4 = conf["Cost_4"]
        local cost_money_4 = conf["Cost_Money_4"]
        transferd[level] = { cost_count = { cost_1, cost_2, cost_3, cost_4}, cost_money = { cost_money_1, cost_money_2, cost_money_3, cost_money_4} }
    end
    print("cfghelper:read_pet_soul_level_cost", table.tostr(transferd))
    self.pet_soul_level_cost = transferd
end

function cfghelper:read_pet_equip_suit_up_info()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("PetEquipSuitUp.txt")
    for _, conf in pairs(configs) do
        local material_equip = conf["Material_Equip"]
        local material = conf["Material"]
        local material_count = conf["Material_Count"]
        local cost_money = conf["Cost_Money"]
        local product_equip = conf["Product_Equip"]
        transferd[material_equip] = { material = material, material_count = material_count, cost_money = cost_money, product_equip = product_equip}
    end
    print("cfghelper:pet_equip_suit_up_info", table.tostr(transferd))
    self.pet_equip_suit_up_info = transferd
end

function cfghelper:read_pet_equip_set_attr()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("PetEquipSetAttr.txt")
    for _, conf in pairs(configs) do
        local t = {}
        local Index = conf["Index"]
        t.count = conf["Max"]
        t.name = conf["Name"]
        t.IAS = {}
        for i = 1, t.count do
            local IA = conf[string.format("IA_%d", i)]
            local IV = conf[string.format("IV_%d", i)]
            t.IAS[i] = { IA = IA, IV = IV}
        end
        transferd[Index] = t
        print("cfghelper:pet_equip_set_attr", table.tostr(t))
    end
    self.pet_equip_set_attr = transferd
end

function cfghelper:read_diaowen_info()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("DiaowenInfo.txt")
    for _, conf in pairs(configs) do
        local t = table.clone(conf)
        local Index = conf["Index"]
        t.id = Index
        t.product = conf["道具ID"]
        t.level = conf["Level"]
        t.name = conf["Name"]
        t.rule = conf["雕纹规则"]
        t.tupu_material = conf["图谱"][1]
        t.danqing_material = conf["丹青"]
        t.danqing_material_count = 20
        t.enhance_material = conf["升级材料"]
        t.enhance_material_count = conf["升级材料数量"]
        t.huangzhi_material = 20502009
        t.huangzhi_material_count = 20
        transferd[Index] = t
        print("cfghelper:read_diaowen_info", table.tostr(t))
    end
    self.diaowen_info = transferd
end

function cfghelper:read_diaowen_rule()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("DiaowenRule.txt")
    for _, conf in pairs(configs) do
        local t = {}
        local Index = conf["Index"]
        t[0] = conf["武器"]
        t[1] = conf["帽子"]
        t[2] = conf["盔甲"]
        t[3] = conf["手套"]
        t[4] = conf["鞋"]
        t[5] = conf["腰带"]
        t[6] = conf["戒子"]
        t[7] = conf["项链"]
        t[8] = conf["骑乘"]
        t[9] = conf["行囊"]
        t[10] = conf["格箱"]
        t[11] = conf["护腕"]
        t[12] = conf["护符"]
        t[15] = conf["护肩"]
        t[14] = conf["护腕"]
        t[17] = conf["暗器"]
        t[18] = conf["武魂"]
        t[37] = conf["副武器"]
        transferd[Index] = t
        print("cfghelper:read_diaowen_rule", table.tostr(t))
    end
    self.diaowen_rule = transferd
end

function cfghelper:read_kfs_base()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("KFSBase.txt")
    for _, conf in pairs(configs) do
        local t = table.clone(conf)
        local Index = conf["Index"]
        t.growth_rates = conf["成长率"]
        t.ext_attrs = conf["拓展属性"]
        t.attack_type = conf["内外功"]
        t.max_visual = conf["大外观"]
        transferd[Index] = t
        print("cfghelper:read_kfs_base", table.tostr(t))
    end
    self.kfs_base = transferd
end

function cfghelper:read_kfs_slot()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("KFSSlot.txt")
    for _, conf in pairs(configs) do
        local t = {}
        local Index = conf["Index"]
        t.materials = conf["材料"]
        t.cost_moneys = conf["金币"]
        t.odd = conf["概率"]
        transferd[Index] = t
        print("cfghelper:read_kfs_slot", table.tostr(t))
    end
    self.kfs_slot = transferd
end

function cfghelper:read_kfs_attr_ex_book()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("KFSAttrExBook.txt")
    for _, conf in pairs(configs) do
        local t = {}
        local Index = conf["Index"]
        t.attr = conf["属性"]
        transferd[Index] = t
        print("cfghelper:read_kfs_attr_ex_book", table.tostr(t))
    end
    self.kfs_attr_ex_book = transferd
end

function cfghelper:read_kfs_attr_level_up()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("KFSAttrLevelUp.txt")
    for _, conf in pairs(configs) do
        local t = {}
        local Index = conf["Index"]
        t.attr = conf["属性"]
        transferd[Index] = t
        print("cfghelper:read_kfs_attr_level_up", table.tostr(t))
    end
    self.kfs_attr_level_up = transferd
end

function cfghelper:read_kfs_attr_ext()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("KFSAttrEx.txt")
    for _, conf in pairs(configs) do
        local t = table.clone(conf)
        local Index = conf["Index"]
        t.name = conf["Name"]
        t.level_up_material = conf["材料ID"]
        t.level_up_money = conf["金币"]
        t.next_id = conf["升级后ID"]
        transferd[Index] = t
        print("cfghelper:read_kfs_attr_ext", table.tostr(t))
    end
    self.kfs_attr_ext = transferd
end

function cfghelper:read_kfs_level_up_exp()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("KFSLevelupExp.txt")
    for _, conf in pairs(configs) do
        local Index = conf["Level"]
        transferd[Index] = conf["Exp"]
        print("cfghelper:read_kfs_level_up_exp", table.tostr(t))
    end
    self.kfs_level_up_exp = transferd
end

function cfghelper:read_kfs_skill_level_up()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("KFSSkillLevelup.txt")
    for _, conf in pairs(configs) do
        local t = {}
        local Index = conf["Index"]
        t.next = conf["NextIndex"]
        t.material = conf["材料"]
        t.money = conf["金币"]
        t.level = conf["等级"]
        transferd[Index] = t
        print("cfghelper:read_kfs_skill_level_up", table.tostr(t))
    end
    self.kfs_skill_level_up = transferd
end

function cfghelper:read_item_apt_rate()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("ItemAptRate.txt")
    for _, conf in pairs(configs) do
        local t = {}
        local Index = conf["资质点"]
        t.bonus = {}
        t.bonus[1] = { ia = define.ITEM_ATTRIBUTE.IATTRIBUTE_RATE_ATTACK_EP, iv = conf["外攻"] }
        t.bonus[2] = { ia = define.ITEM_ATTRIBUTE.IATTRIBUTE_RATE_DEFENCE_EP, iv = conf["外防"] }
        t.bonus[3] = { ia = define.ITEM_ATTRIBUTE.IATTRIBUTE_RATE_ATTACK_EM, iv = conf["内攻"] }
        t.bonus[4] = { ia = define.ITEM_ATTRIBUTE.IATTRIBUTE_RATE_DEFENCE_EM, iv = conf["内防"] }
        t.bonus[5] = { ia = define.ITEM_ATTRIBUTE.IATTRIBUTE_RATE_BASE_HIT, iv = conf["命中"] }
        t.bonus[6] = { ia = define.ITEM_ATTRIBUTE.IATTRIBUTE_RATE_BASE_MISS, iv = conf["闪避"] }
        -- t.bonus[1] = { ia = define.ITEM_ATTRIBUTE.IATTRIBUTE_RATE_ATTACK_EP, iv = conf["外攻"] }
        -- t.bonus[2] = { ia = define.ITEM_ATTRIBUTE.IATTRIBUTE_RATE_ATTACK_EM, iv = conf["内攻"] }
        -- t.bonus[3] = { ia = define.ITEM_ATTRIBUTE.IATTRIBUTE_RATE_DEFENCE_EP, iv = conf["外防"] }
        -- t.bonus[4] = { ia = define.ITEM_ATTRIBUTE.IATTRIBUTE_RATE_DEFENCE_EM, iv = conf["内防"] }
        -- t.bonus[5] = { ia = define.ITEM_ATTRIBUTE.IATTRIBUTE_RATE_BASE_HIT, iv = conf["命中"] }
        -- t.bonus[6] = { ia = define.ITEM_ATTRIBUTE.IATTRIBUTE_RATE_BASE_MISS, iv = conf["闪避"] }
        transferd[Index] = t
        print("cfghelper:read_item_apt_rate", table.tostr(t))
    end
    self.item_apt_rate = transferd
end

function cfghelper:read_pet_soul_skill()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("PetSoulSkill.txt")
    for _, conf in pairs(configs) do
        local t = {}
        local Index = conf["Index"]
        t.fight_skills = conf["出战"]
        t.melting_impacts = {}
        t.melting_impacts[1] = { values = conf["附体效果1"], desc = conf["附体效果1描述"]}
        t.melting_impacts[2] = { values = conf["附体效果2"], desc = conf["附体效果2描述"]}
        t.melting_impacts[3] = { values = conf["附体效果3"], desc = conf["附体效果3描述"]}
        transferd[Index] = t
        print("cfghelper:read_pet_soul_skill", table.tostr(t))
    end
    self.pet_soul_skill = transferd
end

function cfghelper:read_kfs_level_up()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("KFSAttrLevelUp.txt")
    for _, conf in pairs(configs) do
        local t = {}
        local Index = conf["Index"]
        t[10156001] = conf["10156001"]
        t[10156002] = conf["10156002"]
        t[10156003] = conf["10156003"]
        t[10156004] = conf["10156004"]
        t[10156005] = conf["10156005"]
        transferd[Index] = t
        print("cfghelper:read_kfs_level_up", table.tostr(t))
    end
    self.kfs_level_up = transferd
end

function cfghelper:read_wuhun_wg()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("WuhunWg.txt")
    for _, conf in pairs(configs) do
        local t = {}
        local Index = conf["Index"]
        t.name = conf["Names"]
        t.active_cost_money = conf["激活消耗金币"]
        t.active_cost_materials = conf["激活消耗材料"]
        t.active_cost_material_count = conf["激活消耗材料数量"]
        t.wg_atts = conf["外观攻"]
        t.wg_defs = conf["外观守"]
        transferd[Index] = t
        print("cfghelper:read_wuhun_wg", table.tostr(t))
    end
    self.wuhun_wg = transferd
end

function cfghelper:read_wuhun_wg_level()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("WuhunWgLevel.txt")
    for _, conf in pairs(configs) do
        local t = {}
        local Index = conf["Index"]
        t.id = conf["ID"]
        t.level = conf["Level"]
        t.grade = conf["Grade"]
        t.cost_money = conf["消耗金币"]
        t.cost_materials = conf["消耗材料"]
        t.cost_materials_count = conf["消耗材料数量"]
        t.qian_IA = conf["乾位属性IA"]
        t.qian_IV = conf["乾位属性IV"]
        t.kun_IA = conf["坤位属性IA"]
        t.kun_IV = conf["坤位属性IV"]
        t.IA = conf["不嵌入属性IA"]
        t.IV = conf["不嵌入属性IV"]
        t.add_rate_ia = conf["乾位增伤值"]
        t.qian_add_attack_iv = conf["乾位增伤值"]
        t.kun_add_defence_iv = conf["坤位减伤值"]
        transferd[Index] = t
        print("cfghelper:read_wuhun_wg_level", table.tostr(t))
    end
    self.wuhun_wg_level = transferd
end

function cfghelper:read_pvp_rule()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("PvpRuler.txt")
    for _, conf in pairs(configs) do
        local t = {}
        local Index = conf["ID"]
        t.pk_min_level = conf["允许Pk最小级别"]
        local rule_1 = conf["允许决斗"]
        local rule_2 = conf["允许自由PK"]
        local rule_3 = conf["允许Pvp竞技"]
        local rule_4 = conf["允许宣战"]
        t.allow_add_pk_value = conf["允许杀气值增加"] == 1
        t.allow_reduce_pk_value = conf["允许杀气值减退"] == 1
        t.pvp_rule = (rule_1 == 1 and (1 << 0) or 0) + (rule_2 == 1 and (1 << 1) or 0) + (rule_3 == 1 and (1 << 2) or 0) + (rule_4 == 1 and (1 << 3) or 0)
        transferd[Index] = t
        print("cfghelper:read_pvp_rule", table.tostr(t))
    end
    self.pvp_rule = transferd
end

function cfghelper:read_activity_notice()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("ActivityNotice.txt")
    for _, conf in pairs(configs) do
        local t = {}
        local Index = conf["id"]
        t.id = Index
        t.sceneid = conf.sceneid
        t.time_type = conf.time_type
        t.time_start = conf.time_start
        t.scriptid = conf.scriptid
        t.slow_broad = conf["慢报内容$1$"]
        t.time_invalid = conf["失效时间"]
        t.ruler = conf.ruler
        t.opt_type = conf.opt_type
        transferd[Index] = t
        print("cfghelper:read_activity_notice", table.tostr(t))
    end
    self.activity_notice = transferd
end

function cfghelper:read_activity_ruler()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("ActivityRuler.txt")
    for _, conf in pairs(configs) do
        local t = {}
        local Index = conf["actid"]
        t.sceneids = conf.sceneid
        t.rates = conf.rate
        transferd[Index] = t
        print("cfghelper:read_activity_ruler", table.tostr(t))
    end
    self.activity_ruler = transferd
end

function cfghelper:reload_activity_notice()
    skynet.logi("[cfghelper] reload_activity_notice START")
    -- 读取 ActivityNotice.txt
    local read1 = require "txtreader".new()
    local raw_notice = read1:load("ActivityNotice.txt")
    if not raw_notice or not next(raw_notice) then
        skynet.logi("[cfghelper] reload_activity_notice FAIL: ActivityNotice.txt 读取失败或为空")
        return false, "ActivityNotice.txt 读取失败或为空"
    end
    skynet.logi("[cfghelper] reload_activity_notice: ActivityNotice raw rows =", #raw_notice)
    -- 解析 activity_notice
    local new_notice = {}
    local notice_count = 0
    for _, conf in pairs(raw_notice) do
        local t = {}
        local Index = conf["id"]
        t.id = Index
        t.sceneid = conf.sceneid
        t.time_type = conf.time_type
        t.time_start = conf.time_start
        t.scriptid = conf.scriptid
        t.slow_broad = conf["慢报内容$1$"]
        t.time_invalid = conf["失效时间"]
        t.ruler = conf.ruler
        t.opt_type = conf.opt_type
        if Index then
            new_notice[Index] = t
            notice_count = notice_count + 1
        end
    end
    if notice_count == 0 then
        skynet.logi("[cfghelper] reload_activity_notice FAIL: ActivityNotice 解析后为空表")
        return false, "ActivityNotice 解析后为空表"
    end
    -- 读取 ActivityRuler.txt
    local read2 = require "txtreader".new()
    local raw_ruler = read2:load("ActivityRuler.txt")
    if not raw_ruler or not next(raw_ruler) then
        skynet.logi("[cfghelper] reload_activity_notice FAIL: ActivityRuler.txt 读取失败或为空")
        return false, "ActivityRuler.txt 读取失败或为空"
    end
    skynet.logi("[cfghelper] reload_activity_notice: ActivityRuler raw rows =", #raw_ruler)
    -- 解析 activity_ruler
    local new_ruler = {}
    local ruler_count = 0
    for _, conf in pairs(raw_ruler) do
        local t = {}
        local Index = conf["actid"]
        t.sceneids = conf.sceneid
        t.rates = conf.rate
        if Index then
            new_ruler[Index] = t
            ruler_count = ruler_count + 1
        end
    end
    if ruler_count == 0 then
        skynet.logi("[cfghelper] reload_activity_notice FAIL: ActivityRuler 解析后为空表")
        return false, "ActivityRuler 解析后为空表"
    end
    -- 事务提交：两张表同时更新
    self.activity_notice = new_notice
    self.activity_ruler = new_ruler
    self._loaded["read_activity_notice"] = true
    self._loaded["read_activity_ruler"] = true
    sharetable.loadtable("activity_notice", new_notice)
    sharetable.loadtable("activity_ruler", new_ruler)
    skynet.logi("[cfghelper] reload_activity_notice done,", notice_count, "activities,", ruler_count, "rulers")
    return true, string.format("活动公告重载成功, %d 条活动, %d 条规则", notice_count, ruler_count)
end

function cfghelper:read_ling_yu_base()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("LingYuBase.txt")
    for _, conf in pairs(configs) do
        local t = {}
        local Index = conf["Index"]
        t.equip_point = conf["EquipPoint(装备点)"]
        t.class = conf["class(基本类型)"]
        t.set = conf["套装编号"]
        t.base_attr_keys = conf["基础属性类型"]
        t.base_attr_values = conf["基础属性值"]
        transferd[Index] = t
        print("cfghelper:read_ling_yu_base", table.tostr(t))
    end
    self.ling_yu_base = transferd
end

function cfghelper:read_ling_yu_attr_rule()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("LingYuAttrRule.txt")
    for _, conf in pairs(configs) do
        local t = {}
        local Index = conf["EquipPoint(装备点)"]
        t.attr_odds = conf["生成属性概率"]
        transferd[Index] = t
        print("cfghelper:ling_yu_attr_rule", table.tostr(t))
    end
    self.ling_yu_attr_rule = transferd
end

function cfghelper:read_ling_yu_attr_value()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("LingYuAttrValue.txt")
    for _, conf in pairs(configs) do
        local t = {}
        local Index = conf["属性类型"]
        t.values = conf["属性值"]
        transferd[Index] = t
        print("cfghelper:ling_yu_attr_value", table.tostr(t))
    end
    self.ling_yu_attr_value = transferd
end

function cfghelper:read_ling_yu_set()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("LingYuSet.txt")
    for _, conf in pairs(configs) do
        local t = {}
        local Index = conf["Index"]
        t.id = conf["id"]
        transferd[Index] = t
        print("cfghelper:read_ling_yu_set", table.tostr(t))
    end
    self.ling_yu_set = transferd
end

function cfghelper:read_ling_yu_set_effect()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("LingYuSetEffect.txt")
    for _, conf in pairs(configs) do
        local t = {}
        local Index = conf["Index"]
        t.ias = conf["属性类型"]
        t.ivs = conf["属性值"]
        t.add_impact = conf["效果"]
        t.add_skill = conf["技能"]
        transferd[Index] = t
        print("cfghelper:read_ling_yu_set_effect", table.tostr(t))
    end
    self.ling_yu_set_effect = transferd
end

function cfghelper:read_drop_notify()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("DropNotify.txt")
    for _, conf in pairs(configs) do
        local Index = conf["广播类型ID（顺序递增）"]
        local t = transferd[Index] or {}
        local notify = {}
        notify.channel = conf["频道类型：4-系统消息，6-帮派消息，7-门派消息"]
        notify.content = conf["广播内容（消息限长256CHAR，严禁使用字符%）：&A-活动描述，&S-场景名称，&T-队长名称，&U-玩家名称，&I-物品名称$1$"]
        table.insert(t, notify)
        transferd[Index] = t
        print("cfghelper:read_drop_notify", table.tostr(t))
    end
    self.drop_notify = transferd
end

function cfghelper:read_scene_define_ex()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("SceneDefineEx.txt")
    for _, conf in pairs(configs) do
        local t = {}
        local Index = conf["Index"]
        if Index then
            t.name = conf["Name"]
            print("cfghelper:read_scene_define_ex", table.tostr(t))
            transferd[Index] = t
        end
    end
    self.scene_define_ex = transferd
end

function cfghelper:read_scripts()
    self.scripts = require "scripts.scripts"
end

function cfghelper:read_ai_script_dat()
    local read = require "datreader".new()
    local configs = read:load("AIScript.dat")
    self.ai_script_dat = configs
end

function cfghelper:read_super_weapon_up()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("SuperWeaponUp.txt")
    for _, conf in pairs(configs) do
        local Index = conf["神器ID"]
        if Index then
            transferd[Index] = conf
            print("read_super_weapon_up t =", table.tostr(conf))
        end
    end
    self.super_weapon_up = transferd
end

function cfghelper:read_exterior_weapon_visual()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("Exterior_Weapon.txt")
    for _, conf in pairs(configs) do
        local Index = conf["Index"]
        if Index then
            transferd[Index] = conf
            print("read_exterior_weapon_visual t =", table.tostr(conf))
        end
    end
    self.exterior_weapon_visual = transferd
end

function cfghelper:read_char_title()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("CharTitle.txt")
    for _, conf in pairs(configs) do
        local Index = conf["ID"]
        if Index then
            transferd[Index] = conf
            print("read_char_title t =", table.tostr(conf))
        end
    end
    self.char_title = transferd
end

function cfghelper:read_xiulian_rate()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("XiuLianRate.txt")
    for _, conf in pairs(configs) do
        local Index = conf["心法等级"]
        if Index then
            transferd[Index] = conf
            print("read_xiulian_rate t =", table.tostr(conf))
        end
    end
    self.xiulian_rate = transferd
end

function cfghelper:read_xiulian_detail()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("XiuLianDetail.txt")
    for _, conf in pairs(configs) do
        local Index = conf["Index"]
        if Index then
            local details = {}
            details.BOOKLEVEL = conf.BOOKLEVEL
            details.BOOKID = conf.BOOKID
            for i = 1, 15 do
                local detail = {}
                detail.cost_exp = conf["经验"][i]
                detail.cost_gold = conf["金币"][i]
                detail.bonus = conf["加成"][i]
                details[i] = detail
            end
            transferd[Index] = details
            print("read_xiulian_detail t =", table.tostr(conf))
        end
    end
    self.xiulian_detail = transferd
end

function cfghelper:read_sect_info()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("SectInfo.txt")
    for _, conf in pairs(configs) do
        local Index = conf["Index"]
        if Index then
            transferd[Index] = conf
            print("read_sect_info t =", table.tostr(conf))
        end
    end
    self.sect_info = transferd
end

function cfghelper:read_week_active()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("Weekactive.txt")
    for _, conf in ipairs(configs) do
        local type = conf.SubType
        local confs = transferd[type] or {}
        local t = {}
        t.id = conf.Index + 1
        t.award_num = conf.AwardNum
        t.target = conf.Target
        table.insert(confs, t)
        transferd[type] = confs
        print("read_week_active t =", table.tostr(t))
    end
    self.week_active = transferd
end

function cfghelper:read_die_penalty()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("DiePenalty.txt")
    local function convert(conf, t, min_key, max_key, min_result_key, max_result_key)
        local min_str = conf[min_key]
        local last_char = string.sub(min_str, -1, -1)
        if last_char == "%" then
            t["percent_" .. min_result_key] = tonumber(string.sub(min_str, 1, -2))
        else
            t[min_result_key] = tonumber(min_str)
        end

        local max_str = conf[max_key]
        last_char = string.sub(max_str, -1, -1)
        if last_char == "%" then
            t["percent_" .. max_result_key] = tonumber(string.sub(max_str, 1, -2))
        else
            t[max_result_key] = tonumber(max_str)
        end
    end
    for _, conf in pairs(configs) do
        local Index = conf["ID"]
        if Index then
            local t = {}
            convert(conf, t, "MoneyMin", "MoneyMax", "money_min", "money_max")
            convert(conf, t, "ExpMin", "ExpMax", "exp_min", "exp_max")
            convert(conf, t, "EquipDurMin", "EquipDurMax", "equip_dur_min", "equip_dur_max")
            convert(conf, t, "ItemMin", "ItemMax", "item_min", "item_max")
            convert(conf, t, "EquipMin", "EquipMax", "equip_min", "equip_max")
            transferd[Index] = t
            print("read_die_penalty t =", table.tostr(t))
        end
    end
    self.die_penalty = transferd
end

function cfghelper:read_sect_desc()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("SectDesc.txt")
    for _, conf in pairs(configs) do
        local t = {}
        local Index = conf["Index"]
        assert(Index)
        t.name = conf["Name"]
        t.params = {}
        for _, param in ipairs(conf["参数"]) do
            local sub_params = string.split(param, ";")
            for i, sb in ipairs(sub_params) do
                sub_params[i] = tonumber(sb)
            end
            table.insert(t.params, sub_params)
        end
        transferd[Index] = t
        print("read_sect_desc t =", table.tostr(t))
    end
    self.sect_desc = transferd
end

function cfghelper:read_questions()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("Questions.txt")
    for _, conf in pairs(configs) do
        local question = {}
        question.id = conf["问题号"]
        question.con = conf["问题内容$1$"]
        question.opt0 = conf["选项0$1$"]
        question.opt1 = conf["选项1$1$"]
        question.opt2 = conf["选项2$1$"]
        question.opt3 = conf["选项3$1$"]
        question.opt4 = conf["选项4$1$"]
        question.opt5 = conf["选项5$1$"]
        question.key0 = conf["答案0"]
        question.key1 = conf["答案1"]
        question.key2 = conf["答案2"]
        question.key3 = conf["答案3"]
        question.key4 = conf["答案4"]
        question.key5 = conf["答案5"]
        question.sztype = conf["1=新，2=城，3=亚，4=科举易，5=科举难，6=夫妻，7=夫妻，8=喜从天降，9=新圣火传递"]
        table.insert(transferd, question)
        print("read_questions t =", table.tostr(question))
    end
    self.questions = transferd
end

function cfghelper:read_grow_point()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("GrowPoint.txt")
    for _, conf in pairs(configs) do
        local grow_point = conf
        local id = grow_point["编号"]
        transferd[id] = grow_point
        print("read_grow_point t =", table.tostr(grow_point))
    end
    self.grow_point = transferd
end

function cfghelper:read_bus_info()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("BusInfo.txt")
    for _, conf in pairs(configs) do
        local id = conf["ID"]
        transferd[id] = conf
        print("read_bus_info t =", table.tostr(conf))
    end
    self.bus_info = transferd
end

function cfghelper:read_city_info()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("CityInfo.txt")
    for _, conf in pairs(configs) do
        local id = conf["ID"]
        transferd[id] = conf
        print("read_city_info t =", table.tostr(conf))
    end
    self.city_info = transferd
end

function cfghelper:read_city_building()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("CityBuilding.txt")
    for _, conf in pairs(configs) do
        local id = conf["ID"]
        transferd[id] = conf
        print("read_city_building t =", table.tostr(conf))
    end
    self.city_building = transferd
end

function cfghelper:read_guild_war_point()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("GuildWarPoint.txt")
    for _, conf in pairs(configs) do
        local id = conf["ID"]
        transferd[id] = conf
        print("read_guild_war_point t =", table.tostr(conf))
    end
    self.guild_war_point = transferd
end

function cfghelper:read_char_title_new()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("CharTitleNew.txt")
    for _, conf in pairs(configs) do
        local id = conf["ID"]
        transferd[id] = conf
        print("read_char_title_new t =", table.tostr(conf))
    end
    self.char_title_new = transferd
end

function cfghelper:read_pet_title()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("PetTitle.txt")
    for _, conf in pairs(configs) do
        local id = conf["ID"]
        transferd[id] = conf
        print("read_pet_title t =", table.tostr(conf))
    end
    self.pet_title = transferd
end

function cfghelper:read_mission_loot_item()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("Mission_LootItem.txt")
    for _, conf in pairs(configs) do
        local id = conf["MissionIndex"]
        transferd[id] = conf
        print("read_mission_loot_item t =", table.tostr(conf))
    end
    self.mission_loot_item = transferd
end

function cfghelper:read_mission_delivery()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("Mission_Delivery.txt")
    for _, conf in pairs(configs) do
        local id = conf["MissionIndex"]
        transferd[id] = conf
        print("read_mission_delivery t =", table.tostr(conf))
    end
    self.mission_delivery = transferd
end

function cfghelper:read_mission_enter_area()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("Mission_EnterArea.txt")
    for _, conf in pairs(configs) do
        local id = conf["MissionIndex"]
        transferd[id] = conf
        print("read_mission_enter_area t =", table.tostr(conf))
    end
    self.mission_enter_area = transferd
end

function cfghelper:read_mission_husong()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("Mission_Husong.txt")
    for _, conf in pairs(configs) do
        local id = conf["MissionIndex"]
        transferd[id] = conf
        print("read_mission_husong t =", table.tostr(conf))
    end
    self.mission_husong = transferd
end

function cfghelper:read_mission_kill_monster()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("Mission_KillMonster.txt")
    for _, conf in pairs(configs) do
        local id = conf["MissionIndex"]
        transferd[id] = conf
        print("read_mission_kill_monster t =", table.tostr(conf))
    end
    self.mission_kill_monster = transferd
end

function cfghelper:read_drop_rate_of_item_table()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("DropRateOfItemTable.txt")
    for _, conf in pairs(configs) do
        table.insert(transferd, conf)
        print("read_drop_rate_of_item_table t =", table.tostr(conf))
    end
    self.drop_rate_of_item_table = transferd
end

function cfghelper:read_stiry_telling_duo_logue()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("StorytellingDuologue.txt")
    for _, conf in pairs(configs) do
        local id = conf["对话序号"]
        transferd[id] = conf
        print("read_stiry_telling_duo_logue t =", table.tostr(conf))
    end
    self.stiry_telling_duo_logue = transferd
end

function cfghelper:read_mission_npc_hash_table()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("MissionNPC_HashTable.txt")
    transferd.index = {}
    transferd.data = {}
    for _, conf in pairs(configs) do
        local id = conf["编号"]
        for i = 0, 354 do
            if conf[tostring(i)] == 1 then
                local index = transferd.index[i] or {}
                table.insert(index, id)
                transferd.index[i] = index
            end
        end
        transferd.data[id] = conf
        print("read_mission_npc_hash_table t =", table.tostr(conf))
    end
    self.mission_npc_hash_table = transferd
end

function cfghelper:read_mission_pet_hash_table()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("MissionPet_HashTable.txt")
    transferd.index = {}
    transferd.data = {}
    for _, conf in pairs(configs) do
        local id = conf["珍兽编号"]
        for i = 1, 14 do
            local index_conf = conf["珍兽出现几率"]
            local index = transferd.index[i] or {}
            table.insert(index, { id = id, conf = index_conf[i]})
            transferd.index[i] = index
        end
        transferd.data[id] = conf
        print("read_mission_pet_hash_table t =", table.tostr(conf))
    end
    self.mission_pet_hash_table = transferd
end

function cfghelper:read_mission_item_hash_table()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("MissionItem_HashTable.txt")
    transferd.use = {}
    transferd.award = {}
    transferd.broad = {}
    transferd.data = {}
    for _, conf in pairs(configs) do
        local id = conf["物品编号"]
        local use_conf = conf["物品使用几率"]
        local award_conf = conf["奖励几率"]
        local broad_conf = conf["广播类型0.普通说话消息1.队伍消息2.场景消息4.系统消息世界消息6.帮派消息7.门派消息"]
        for i = 1, #use_conf do
            local use = transferd.use[i] or {}
            table.insert(use, { id = id, conf = use_conf[i]})
            transferd.use[i] = use
        end
        for i = 1, #award_conf do
            local award = transferd.award[i] or {}
            table.insert(award, { id = id, conf = award_conf[i]})
            transferd.award[i] = award
        end
        for i = 1, #broad_conf do
            local broad = transferd.broad[i] or {}
            table.insert(broad, { id = id, conf = broad_conf[i]})
            transferd.broad[i] = broad
        end
        transferd.data[id] = conf
    end
    --print("read_mission_item_hash_table t =", table.tostr(transferd))
    self.mission_item_hash_table = transferd
end

function cfghelper:read_white_equip_base()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("WhiteEquipBase.txt")
    for _, conf in pairs(configs) do
        local id = conf["Index"]
        transferd[id] = conf
        print("read_white_equip_base t =", table.tostr(conf))
    end
    self.white_equip_base = transferd
end

function cfghelper:read_shimen_round_multiple_table()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("ShimenRoundMultipleTable.txt")
    for _, conf in pairs(configs) do
        local id = conf["环数"]
        transferd[id] = conf
        print("read_shimen_round_multiple_table t =", table.tostr(conf))
    end
    self.shimen_round_multiple_table = transferd
end

function cfghelper:read_shimen_level_money_bonus_table()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("ShimenLevelMoneyBonusTable.txt")
    for _, conf in pairs(configs) do
        local id = conf["等级"]
        transferd[id] = conf
        print("shimen_level_money_bonus_table t =", table.tostr(conf))
    end
    self.shimen_level_money_bonus_table = transferd
end

function cfghelper:read_pet_medicine_hc_compound()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("PetMedicineHCCompound.txt")
    for _, conf in pairs(configs) do
        local id = conf["需要合成的灵兽丹ID"]
        transferd[id] = conf
        print("pet_medicine_hc_compound t =", table.tostr(conf))
    end
    self.pet_medicine_hc_compound = transferd
end

function cfghelper:read_pet_skill_level_up()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("PetSkillLevelup.txt")
    for _, conf in pairs(configs) do
        local id = conf["需要升级的珍兽技能ID"]
        transferd[id] = conf
        print("pet_skill_level_up t =", table.tostr(conf))
    end
    self.pet_skill_level_up = transferd
end

function cfghelper:read_exterior_poss()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("Exterior_Poss.txt")
    for _, conf in ipairs(configs) do
        local id = conf["ID"]
        for _, value in pairs(conf) do
            if type(value) == "table" and #value == 3 and tonumber(value[1]) and value[1] > 100 then
                conf.models = value
                break
            end
        end
        transferd[id] = conf
        print("exterior_poss t =", table.tostr(conf))
    end
    self.exterior_poss = transferd
end

function cfghelper:read_pet_soul_poss_visual_locator()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("PetSoulPossVisualLocator.txt")
    for _, conf in pairs(configs) do
        local model_id = conf[1] or conf["INT"] or conf["ID"]
        local locator = conf[2] or conf["STRING"] or conf["Locator"]
        if model_id then
            transferd[tonumber(model_id)] = {
                model_id = tonumber(model_id),
                locator = locator,
            }
            print("pet_soul_poss_visual_locator t =", table.tostr(transferd[tonumber(model_id)]))
        end
    end
    self.pet_soul_poss_visual_locator = transferd
end

function cfghelper:read_zhanling_info()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("ZhanLingInfo.txt")
    for _, conf in pairs(configs) do
        local id = conf["Level"]
        transferd[id] = conf
        print("zhanling_info t =", table.tostr(conf))
    end
    self.zhanling_info = transferd
end

function cfghelper:read_zhanling_time_info()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("ZhanLingTimeInfo.txt")
    for _, conf in pairs(configs) do
        local id = conf["ID"]
        transferd[id] = conf
        print("zhanling_time_info t =", table.tostr(conf))
    end
    self.zhanling_time_info = transferd
end

function cfghelper:read_new_zhanling_info()
    local config_path = skynet.getenv("config_path")
    local file_path = string.format(config_path, "NewZhanLingInfo.txt")
    local file = assert(io.open(file_path, "r"), "cannot open " .. file_path)
    local periods_by_key = {}
    local periods = {}
    local line_number = 0

    for line in file:lines() do
        line_number = line_number + 1
        if line_number > 2 and line ~= "" and line:sub(1, 1) ~= "#" then
            line = line:gsub("\r", "")
            local columns = {}
            for value in (line .. "\t"):gmatch("([^\t]*)\t") do
                columns[#columns + 1] = tonumber(value)
            end

            local begin_date = columns[2]
            local end_date = columns[3]
            local level = columns[4]
            local need_point = columns[5]
            local item_id = columns[20]
            local item_count = columns[21]
            if begin_date and end_date and level and level >= 1 and level <= 20
                and need_point and item_id and item_id > 0 and item_count and item_count > 0 then
                local key = tostring(begin_date) .. ":" .. tostring(end_date)
                local period = periods_by_key[key]
                if not period then
                    period = { begin_date = begin_date, end_date = end_date, rewards = {} }
                    periods_by_key[key] = period
                    periods[#periods + 1] = period
                end
                period.rewards[level] = {
                    need_point = need_point,
                    item_id = item_id,
                    item_count = item_count,
                    is_bind = true,
                }
            end
        end
    end
    file:close()

    table.sort(periods, function(a, b)
        return a.begin_date < b.begin_date
    end)
    self.new_zhanling_info = periods
end

function cfghelper:read_pet_huantong_cost()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("PetHuanTongCost.txt")
    for _, conf in pairs(configs) do
        local id = conf["宠物携带等级"]
        transferd[id] = conf
        print("pet_huantong_cost t =", table.tostr(conf))
    end
    self.pet_huantong_cost = transferd
end

function cfghelper:read_equip_set_attr()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("EquipSetAttr.txt")
    for _, conf in pairs(configs) do
        local t = {}
        local id = conf["套装编号"]
        t.count = conf["组件数"]
        t.name = conf["套装名字$1$"]
        t.IAS = {}
        for i = 1, t.count do
            local IA = conf[string.format("效果类型%d", i - 1)]
            local IV = conf["效果值"][i]
            t.IAS[i] = { IA = IA, IV = IV}
        end
        transferd[id] = t
    end
    self.equip_set_attr = transferd
end

function cfghelper:read_exterior_ranse()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("Exterior_RanSe.txt")
    for _, conf in pairs(configs) do
        local pet_soul_id = conf["PetSoulId"]
        local pet_soul_colors = transferd[pet_soul_id] or {}
        local color_value = conf["ColorValue"]
        pet_soul_colors[color_value] = conf
        transferd[pet_soul_id] = pet_soul_colors
    end
    self.exterior_ranse = transferd
end

function cfghelper:read_shenbing()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("ShenBing.txt")
    for _, conf in pairs(configs) do
        local Index = conf["Index"]
        transferd[Index] = conf
    end
    self.shenbing = transferd
end

function cfghelper:read_shenbing_level()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("ShenBingLevel.txt")
    for _, conf in pairs(configs) do
        local Level = conf["Level"]
        transferd[Level] = conf
    end
    self.shenbing_level = transferd
end

function cfghelper:read_equip_enhanceex()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("ItemEnhance.txt")
    for _, conf in pairs(configs) do
        local id = conf["强化等级"]
        if id then
            local cc = conf["穿刺强化"] or 0
            local fc = conf["穿刺防御"] or 0
            if transferd[id] then
                if cc > transferd[id].chuangci then transferd[id].chuangci = cc end
                if fc > transferd[id].fangchuan then transferd[id].fangchuan = fc end
            else
                local t = {}
                t.id = id
                t.chuangci = cc
                t.fangchuan = fc
                transferd[id] = t
            end
        end
    end
    self.equip_enhanceex = transferd
end

function cfghelper:read_allowable_script_fun()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("AllowableScriptFunc.txt")
    for _, conf in pairs(configs) do
        local id = conf["脚本ID"]
        if id then
            transferd[id] = conf
        end
    end
    self.allowable_script_fun = transferd
end

function cfghelper:read_exterior_ts()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("Exterior_TS.txt")
    for _, conf in pairs(configs) do
        local t = {}
        t.id = conf["index"]
        if t.id then
            t.name = conf["名称"]
            t.num = conf["编号"]
            t.minx = conf["X最小值"]
            t.maxx = conf["X最大值"]
            t.miny = conf["Y最小值"]
            t.maxy = conf["Y最大值"]
            t.minz = conf["Z最小值"]
            t.maxz = conf["Z最大值"]
            t.defx = conf["X默认"]
            t.defy = conf["Y默认"]
            t.defz = conf["Z默认"]
            t.itemid = conf["激活道具"]
            transferd[t.id] = t
            print("exterior_ts t =", table.tostr(t))
        end
    end
    self.exterior_ts = transferd
end

function cfghelper:read_exterior_bg()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("Exterior_BG.txt")
    local bg_item_map = {
        [1] = 38003260, [2] = 38003321, [3] = 38003382,
        [4] = 38003425, [5] = 38003563, [6] = 38003574,
        [7] = 38003575, [8] = 38003586, [9] = 38003656,
        [10] = 38003673, [11] = 38003681, [12] = 38003682,
        [13] = 38003690, [14] = 38003724, [15] = 38003885,
        [16] =  38003886, [18] = 38003931, [19] = 38003932, [21] = 38008320, [22] = 38008833, [23] = 38003987, -- orn2026-20260910
    }
    for _, conf in pairs(configs) do
        local t = {}
        t.id = conf["index"]
        if t.id then
            t.name = conf["名称"]
            t.num = conf["编号"]
            t.minx = conf["X最小值"]
            t.maxx = conf["X最大值"]
            t.miny = conf["Y最小值"]
            t.maxy = conf["Y最大值"]
            t.minz = conf["Z最小值"]
            t.maxz = conf["Z最大值"]
            t.defx = conf["X默认"]
            t.defy = conf["Y默认"]
            t.defz = conf["Z默认"]
            t.itemid = bg_item_map[t.id]
            transferd[t.id] = t
            print("exterior_bg t =", table.tostr(t))
        end
    end
    self.exterior_bg = transferd
end

function cfghelper:read_exterior_weapon_levelup()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("ExteriorWeaponLevelUp.txt")
    for _, conf in pairs(configs) do
        local t = {}
        t.id = conf["index"]
        if t.id then
            t[1] = {conf["金钱1级"],conf["道具1级"],conf["数量1级"]}
            t[2] = {conf["金钱2级"],conf["道具2级"],conf["数量2级"]}
            t[3] = {conf["金钱3级"],conf["道具3级"],conf["数量3级"]}
            transferd[t.id] = t
            print("exterior_weapon_levelup t =", table.tostr(t))
        end
    end
    self.exterior_weapon_levelup = transferd
end

function cfghelper:get_dw_jinjie_texing()
    return self.dw_jinjie_texing
end
function cfghelper:get_dw_jinjie_info()
    return self.dw_jinjie_info
end
function cfghelper:get_dw_jinjie_zx_gif_box()
    return self.dw_jinjie_zx_gif_box
end
function cfghelper:get_dw_jinjie_texing_shengji()
    return self.dw_jinjie_texing_shengji
end

function cfghelper:get_shenbing_skill_up()
    return self.shenbing_skill_up
end

function cfghelper:get_shenbing_common_skill()
    return self.shenbing_common_skill
end

function cfghelper:get_shenbing_visual()
    return self.shenbing_visual
end

function cfghelper:get_stall_info()
    return self.stall_info
end

function cfghelper:read_dw_jinjie_texing()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("DWJinJieTeXing.txt")
    for _, conf in pairs(configs) do
        local t = {}
        t.id = conf["index"]
        if t.id then
			if conf["纹刻ID"] ~= 0 then
				t.name = conf["纹刻名称"]
				t.feature_max = conf["特性上限"]
				t.add_feature_max = conf["附加特性上限"]
				t.feature_rate = conf["特性分母"]
				t.itemid = conf["纹刻ID"]
				t.feature_list = {}
				for i = 1,10 do
					local lv_value = conf[string.format("特性%d级",i)]
					table.insert(t.feature_list,lv_value)
				end
				transferd[t.id] = t
			end
        end
    end
    self.dw_jinjie_texing = transferd
end

function cfghelper:read_dw_jinjie_info()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("DWJinJieInfo.txt")
    for _, conf in pairs(configs) do
        local t = {}
        t.id = conf["index"]
        if t.id then
			t.needexp = conf["经验"]
			t.onesx = conf["一维"]
			t.threesx = conf["属性"]
			t.skill_value = conf["技能数值"]
			t.skill = conf["技能除10"]
			transferd[t.id] = t
        end
    end
    self.dw_jinjie_info = transferd
end

function cfghelper:read_dw_jinjie_zx_gif_box()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("ZXgiftbox.txt")
	local index = 0
    for _, conf in pairs(configs) do
        local t = {}
        t.id = conf["index"]
        if t.id then
			index = index + 1
			t.itemid = conf["ID"]
			t.name = conf["名称"]
			t.count = conf["数量"]
			transferd[index] = t
        end
    end
    self.dw_jinjie_zx_gif_box = transferd
end

function cfghelper:read_dw_jinjie_texing_shengji()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("DWJinJieTeXingShengJi.txt")
    for _, conf in pairs(configs) do
        local t = {}
        t.id = conf["index"]
        if t.id then
			t.nexp = conf["经验"]
			t.money = conf["金钱"]
			t.mjc_count = conf["描金彩数量"]
			transferd[t.id] = t
        end
    end
    self.dw_jinjie_texing_shengji = transferd
end

function cfghelper:read_shenbing_skill_up()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("ShenBingSkillUp.txt")
    for _, conf in pairs(configs) do
		local index = conf["index"]
        if index then
			local t = {}
			t.id = conf["技能ID"]
			t.level = conf["技能等级"]
			t.newid = conf["升级后ID"]
			t.needitem = conf["需求道具"]
			t.needitem_count = conf["需求数量"]
			t.needmoney = conf["需求金钱"]
			transferd[t.id] = t
        end
    end
    self.shenbing_skill_up = transferd
end

function cfghelper:read_shenbing_common_skill()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("ShenBingCommonSkill.txt")
    for _, conf in pairs(configs) do
		local id = conf["index"]
        if id then
			local t = {
				id = id,
				up = {{},{},{},{}},
				down = {{},{},{},{}},
			}
			local value
			for i = 1,10 do
				value = conf[string.format("上卷冰%d级",i)]
				table.insert(t.up[1],value)
				value = conf[string.format("上卷火%d级",i)]
				table.insert(t.up[2],value)
				value = conf[string.format("上卷玄%d级",i)]
				table.insert(t.up[3],value)
				value = conf[string.format("上卷毒%d级",i)]
				table.insert(t.up[4],value)
				value = conf[string.format("下卷拂尘%d级",i)]
				table.insert(t.down[1],value)
				value = conf[string.format("下卷伤神%d级",i)]
				table.insert(t.down[2],value)
				value = conf[string.format("下卷护佑%d级",i)]
				table.insert(t.down[3],value)
				value = conf[string.format("下卷入骨%d级",i)]
				table.insert(t.down[4],value)
			end
			transferd[id] = t
        end
    end
    self.shenbing_common_skill = transferd
end

function cfghelper:read_shenbing_visual()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("ShenBingVisual.txt")
    for _, conf in pairs(configs) do
		local id = conf["index"]
        if id then
			local t = {}
			t.id = id
			t.action = conf["动作ID"]
			t.visual = conf["外观ID"]
			transferd[id] = t
        end
    end
    self.shenbing_visual = transferd
end

function cfghelper:read_stall_info()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("Stall_Info.txt")
    for _, conf in pairs(configs) do
		local id = conf["序号"]
        if id then
			local t = {}
			id = conf["摆摊场景"]
			t.ntype = conf["摊位类型(0:money 1:yuanbao)"]
			t.pos_tax = conf["摊位费"]
			t.trade_tax = conf["交易税率%"]
			t.pos_left = conf["摊位定位点X_1"]
			t.pos_right = conf["摊位定位点X_2"]
			t.pos_top = conf["摊位定位点Z_1"]
			t.pos_bottom = conf["摊位定位点Z_2"]
			if transferd[id] then
				table.insert(transferd[id],t)
			else
				transferd[id] = {t}
			end
        end
    end
    self.stall_info = transferd
end

-- =============================================================
-- LAZY LOADING: auto-load configs on first get_* access
-- =============================================================
-- Build mapping: get_xxx -> read_xxx (auto-detect by naming convention)
local _lazy_map = {}
for name, method in pairs(cfghelper) do
    if type(method) == "function" and name:sub(1, 5) == "read_" then
        local suffix = name:sub(6)  -- e.g. "scene_info"
        local get_name = "get_" .. suffix
        if type(cfghelper[get_name]) == "function" then
            _lazy_map[get_name] = name
        end
    end
end
-- Known naming exception: get_std_impact_config -> read_std_impact
_lazy_map["get_std_impact_config"] = "read_std_impact"

-- Wrap all get_* methods: if read_* hasn't been called yet, call it first
for get_name, read_name in pairs(_lazy_map) do
    local original_get = cfghelper[get_name]
    cfghelper[get_name] = function(self, ...)
        if not self._loaded then self._loaded = {} end
        if not self._loaded[read_name] then
            self._loaded[read_name] = true
            self[read_name](self)
        end
        return original_get(self, ...)
    end
end

-- 武境巅峰: DFengPointInfo 升级经验阈值
function cfghelper:read_dfeng_point_info()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("DFengPointInfo.txt")
    for _, conf in pairs(configs) do
        local data = conf["INT"]
        if type(data) == "table" then
            transferd[data[1]] = data[2]
        end
    end
    self.dfeng_point_info = transferd
end

function cfghelper:get_dfeng_point_info()
    if not self.dfeng_point_info then
        self:read_dfeng_point_info()
    end
    return self.dfeng_point_info
end

-- 武境巅峰: DFengLevelInfo 等级属性加成
function cfghelper:read_dfeng_level_info()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("DFengLevelInfo.txt")
    for _, conf in pairs(configs) do
        local data = conf["INT"]
        if type(data) == "table" then
            transferd[data[1]] = { attr_id = data[2], attr_value = data[3] }
        end
    end
    self.dfeng_level_info = transferd
end

function cfghelper:get_dfeng_level_info()
    if not self.dfeng_level_info then
        self:read_dfeng_level_info()
    end
    return self.dfeng_level_info
end

-- 武境通脉: DFengEssence 升级配置
-- 格式: level → { attr_id, attr_value, item_id, item_count, success_rate, money_cost }
function cfghelper:read_dfeng_essence_info()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("DFengEssence.txt")
    for _, conf in pairs(configs) do
        local data = conf["INT"]
        if type(data) == "table" and #data >= 7 then
            transferd[data[1]] = {
                attr_id = data[2],
                attr_value = data[3],
                item_id = data[4],
                item_count = data[5],
                success_rate = data[6],
                money_cost = data[7],
            }
        end
    end
    self.dfeng_essence_info = transferd
end

function cfghelper:get_dfeng_essence_info()
    if not self.dfeng_essence_info then
        self:read_dfeng_essence_info()
    end
    return self.dfeng_essence_info
end

-- 武境心络: DFengEssenceKW 孔位配置
-- 格式: [section][level] → { row_id, section, level, type, req_level, bonus, attr1, attr2, attr3, item_id, cost, rate, money, res }
-- DFengEssenceKW.txt: 14列 (13×INT + 1×STRING)
-- Col1=row_id, Col2=section(1-20), Col3=level(0-8), Col4=type(8),
-- Col5=req_essence_level, Col6=attr_bonus, Col7=attr1, Col8=attr2, Col9=attr3,
-- Col10=item_id, Col11=item_cost, Col12=rate, Col13=money_cost, Col14=res_string
function cfghelper:read_dfeng_essence_kw_info()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("DFengEssenceKW.txt")
    for _, conf in pairs(configs) do
        local data = conf["INT"]
        if type(data) == "table" and #data >= 13 then
            local section = data[2]  -- 孔位编号 1-20
            local level = data[3]    -- 等级 0-8
            if not transferd[section] then
                transferd[section] = {}
            end
            transferd[section][level] = {
                row_id = data[1],
                section = section,
                level = level,
                slot_type = data[4],          -- 类型 (始终=8)
                req_essence_level = data[5],  -- 通脉等级要求 (section*10)
                attr_bonus = data[6],         -- 属性加成值 (0,10,20,...80)
                attr_value1 = data[7],        -- 属性加成1
                attr_value2 = data[8],        -- 属性加成2
                attr_value3 = data[9],        -- 属性加成3
                item_id = data[10],           -- 强化消耗道具ID (38003578=心络丹, -1=不可强化)
                item_cost = data[11],         -- 消耗数量
                success_rate = data[12],      -- 成功率
                money_cost = data[13],        -- 银两消耗
            }
        end
    end
    self.dfeng_essence_kw_info = transferd
end

function cfghelper:get_dfeng_essence_kw_info()
    if not self.dfeng_essence_kw_info then
        self:read_dfeng_essence_kw_info()
    end
    return self.dfeng_essence_kw_info
end

function cfghelper:read_tran_sport_define()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("TransportDefine.txt")
    for _, conf in pairs(configs) do
        local t = {}
        t.trans_id = conf["TransId"]
        if t.trans_id then
            t.source_scene_name = conf["源场景名称"]
            t.source_scene_id   = conf["原场景ID"]
            t.npc_name          = conf["传送NPC名"]
            t.pos_x             = conf["POSX"]
            t.pos_z             = conf["POSZ"]
            t.tar_scene         = conf["TARSCENE"]
            t.tar_scene_name    = conf["STRING"]
            t.need_level        = conf["NeedLevel"]
            t.tar_pos_x         = conf["TARPOSX"]
            t.tar_pos_z         = conf["TARPOSZ"]
            transferd[t.trans_id] = t
        end
    end
    self.tran_sport_define = transferd
end

function cfghelper:get_tran_sport_define()
    if not self.tran_sport_define then
        self:read_tran_sport_define()
    end
    return self.tran_sport_define
end

-- 读取外观加成配置
-- 格式: { [id] = { ["增加HP的上限"] = N, ["力量"] = N, ... } } 单层表，中文属性名直接作为key
function cfghelper:read_exterior_bonus()
    local transferd = {}
    local read = require "txtreader".new()
    local configs = read:load("ExteriorBonus.txt")
    for _, conf in pairs(configs) do
        local id = conf["Index"]
        if id then
            local t = table.clone(conf)
            t.id = id
            transferd[id] = t
            skynet.logd("read_exterior_bonus id=", id)
        end
    end
    self.exterior_bonus = transferd
end

function cfghelper:get_exterior_bonus()
    if not self.exterior_bonus then
        self:read_exterior_bonus()
    end
    return self.exterior_bonus
end

-- CYS-PET shared rules config
function cfghelper:read_cy_pet_rules_data()
    self.cy_pet_rules_data = require "cy_pet_rules_data"
end
function cfghelper:get_cy_pet_rules_data()
    if not self.cy_pet_rules_data then self:read_cy_pet_rules_data() end
    return self.cy_pet_rules_data
end

return cfghelper
