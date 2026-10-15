local skynet = require "skynet"
local gbk = require "wire_charset"
local profile = require "skynet.profile"
local define = require "define"
local class = require "class"
local utils = require "utils"
local impactenginer = require "impactenginer":getinstance()
local configenginer = require "configenginer":getinstance()
local actionenginer = require "actionenginer":getinstance()
local skillenginer = require "skillenginer":getinstance()
local talentenginer = require "talentenginer":getinstance()
local petmanager = require "petmanager":getinstance()
local shopenginer = require "shopenginer":getinstance()
local human_item_logic = require "human_item_logic"
local packet_def = require "game.packet"
local team_info_cls = require "teaminfo"
local exchange_box_cls = require "exchange_box"
local Item_cls = require "item"
local pet_guid = require "pet_guid"
local shop_guid = require "shop_guid"
local item_container = require "item_container"
local pet_container = require "pet_container"
local stall_bax = require "stallbox"
local human_bag_container = require "human_bag_container"
local attacker_or_pk_delaction_list = require "attacker_or_pk_delaction_list"
local wild_war_guilds = require "wild_war_guilds"
local human_db_attr = require "db.human_attrib"
local pet_detail = require "pet_detail"
local db_impact = require "db.impact_data"
local menpai_logic = require "menpai"
local ai_human = require "scene.ai.human"
local character = require "scene.obj_agent.character"
local human = class("human", character)

function human:ctor(data)
    self.obj_address = skynet.newservice("obj", "human", data)
end

function human:update_md_value(md)
    skynet.send(self.obj_address, "lua", "update_md_value", md)
end

function human:get_prop_bag_size()
    return skynet.call(self.obj_address, "lua", "get_prop_bag_size")
end

function human:get_material_bag_size()
    return skynet.call(self.obj_address, "lua", "get_material_bag_size")
end

function human:get_bag_size()
    local size = {}
    size.prop = self:get_prop_bag_size()
    size.material = self:get_material_bag_size()
    size.task = 20
    return size
end

function human:get_bank_bag_size()
    return skynet.call(self.obj_address, "lua", "get_bank_bag_size")
end

function human:set_bank_bag_size(size)
    skynet.send(self.obj_address, "lua", "set_bank_bag_size", size)
end

function human:get_pet_bank_bag_size()
    return skynet.call(self.obj_address, "lua", "get_pet_bank_bag_size")
end

function human:set_pet_bank_bag_size(size)
    skynet.send(self.obj_address, "lua", "set_pet_bank_bag_size", size)
end

function human:get_pet_num_extra()
    return skynet.call(self.obj_address, "lua", "get_pet_num_extra")
end

function human:set_pet_num_extra(num)
    skynet.send(self.obj_address, "lua", "set_pet_num_extra", num)
end

function human:get_pet_bag_size()
    return skynet.call(self.obj_address, "lua", "get_pet_bag_size")
end

function human:get_current_pet()
    return skynet.call(self.obj_address, "lua", "get_current_pet")
end

function human:get_bank_save_money()
    return skynet.call(self.obj_address, "lua", "get_bank_save_money")
end

function human:get_equip_visuals()
    return skynet.call(self.obj_address, "lua", "get_equip_visuals")
end

function human:set_datura_flower_max(count)
    skynet.send(self.obj_address, "lua", "set_datura_flower_max", count)
end

function human:set_bank_save_money(money, reason, extra)
    skynet.send(self.obj_address, "lua", "set_bank_save_money", money, reason, extra)
end

function human:unlock_exterior_head(id)
    return skynet.call(self.obj_address, "lua", "unlock_exterior_head", id)
end

function human:unlock_exterior_face(id)
    return skynet.call(self.obj_address, "lua", "unlock_exterior_face", id)
end

function human:unlock_exterior_hair(id)
    return skynet.call(self.obj_address, "lua", "unlock_exterior_hair", id)
end

function human:unlock_exterior_poss(id)
    return skynet.call(self.obj_address, "lua", "unlock_exterior_poss", id)
end

function human:unlock_exterior_ranse(soul_id, index, color_value, target_id)
    skynet.send(self.obj_address, "lua", "unlock_exterior_ranse", soul_id, index, color_value, target_id)
end

function human:set_exterior_ranse_id(id)
    skynet.send(self.obj_address, "lua", "set_exterior_ranse_id", id)
end

function human:set_exterior_ranse_select_by_ranse_id(pet_soul_id, ranse_id)
    skynet.send(self.obj_address, "lua", "set_exterior_ranse_select_by_ranse_id", pet_soul_id, ranse_id)
end

function human:get_exterior_ranse_select()
    return skynet.call(self.obj_address, "lua", "get_exterior_ranse_select")
end

function human:get_exterior_ranse_id()
    return skynet.call(self.obj_address, "lua", "get_exterior_ranse_id")
end

function human:reset_ability_opera()
    return skynet.call(self.obj_address, "lua", "reset_ability_opera")
end

function human:get_ability_opera()
    return skynet.call(self.obj_address, "lua", "get_ability_opera")
end

function human:get_cy_four_resource(id)
    return skynet.call(self.obj_address,"lua","get_cy_four_resource",id)
end
function human:set_cy_four_resource(id,value)
    return skynet.call(self.obj_address,"lua","set_cy_four_resource",id,value)
end

function human:get_save_data()
    return skynet.call(self.obj_address, "lua", "get_save_data")
end

function human:update(...)
    skynet.send(self.obj_address, "lua", "update", ...)
end

function human:set_restore_hp_reset_time(ntime,nrate)
    skynet.send(self.obj_address, "lua", "set_restore_hp_reset_time", ntime,nrate)
end

function human:get_limit_restore_hp()
    return skynet.call(self.obj_address, "lua", "get_limit_restore_hp")
end

function human:set_restore_hp_value(value)
    skynet.send(self.obj_address, "lua", "set_restore_hp_value",value)
end

function human:get_attackers()
    return skynet.call(self.obj_address, "lua", "get_attackers")
end

function human:get_pk_declaration_list()
    return skynet.call(self.obj_address, "lua", "get_pk_declaration_list")
end

function human:get_wild_war_guilds()
    return skynet.call(self.obj_address, "lua", "get_wild_war_guilds")
end

function human:get_guild_id()
    return skynet.call(self.obj_address, "lua", "get_guild_id")
end

function human:get_guild_name()
    return skynet.call(self.obj_address, "lua", "get_guild_name")
end

function human:get_confederate_id()
    return skynet.call(self.obj_address, "lua", "get_confederate_id")
end

function human:begin_shop(shop)
    skynet.send(self.obj_address, "lua", "begin_shop", shop)
end

function human:end_shop()
    skynet.send(self.obj_address, "lua", "end_shop")
end

function human:buy_back(request)
    skynet.send(self.obj_address, "lua", "buy_back", request)
end

function human:shop_sell(sell_bag_index)
    skynet.send(self.obj_address, "lua", "shop_sell", sell_bag_index)
end

function human:do_jump()
    return skynet.call(self.obj_address, "lua", "do_jump")
end

function human:interrupt_current_ability_opera()

end

function human:do_shop(index, buy_num)
    skynet.send(self.obj_address, "lua", "do_shop", index, buy_num)
end

function human:get_mystery_shop_count_by_id(id)
    return skynet.call(self.obj_address, "lua", "get_mystery_shop_count_by_id", id)
end

function human:on_wanshige_shop_buy(item_id, camp)
    skynet.send(self.obj_address, "lua", "on_wanshige_shop_buy", item_id, camp)
end

function human:check_reset_wanshige_data()
    skynet.send(self.obj_address, "lua", "check_reset_wanshige_data")
end

function human:get_wanshige_shop_count_by_id(id)
    return skynet.call(self.obj_address, "lua", "get_wanshige_shop_count_by_id", id)
end

function human:on_jiyuan_shop_buy(item_id, targetId)
    skynet.send(self.obj_address, "lua", "on_jiyuan_shop_buy", item_id, targetId)
end

function human:send_jiyuan_shop_info(targetId)
    skynet.send(self.obj_address, "lua", "send_jiyuan_shop_info", targetId)
end

function human:check_jiyuan_shop_info()
    skynet.send(self.obj_address, "lua", "check_jiyuan_shop_info")
end

function human:get_jiyuan_shop_count_by_id(id)
    return skynet.call(self.obj_address, "lua", "get_jiyuan_shop_count_by_id", id)
end

function human:send_shengwang_info(camp)
    skynet.send(self.obj_address, "lua", "send_shengwang_info", camp)
end

function human:send_mystery_shop_info()
    skynet.send(self.obj_address, "lua", "send_mystery_shop_info")
end

function human:send_digong_shop_info()
    skynet.send(self.obj_address, "lua", "send_digong_shop_info")
end

function human:reset_mystery_shop_info()
    skynet.send(self.obj_address, "lua", "reset_mystery_shop_info")
end

function human:get_impact_list()
    return skynet.call(self.obj_address, "lua", "get_impact_list")
end

function human:get_stall_box()
    return skynet.call(self.obj_address, "lua", "get_stall_box")
end

function human:get_exchange_box()
    return skynet.call(self.obj_address, "lua", "get_exchange_box")
end

function human:get_prop_bag()
    return skynet.call(self.obj_address, "lua", "get_prop_bag")
end

function human:get_bank_bag_container()
    return skynet.call(self.obj_address, "lua", "get_bank_bag_container")
end

function human:get_pet_bag_container()
    return skynet.call(self.obj_address, "lua", "get_pet_bag_container")
end

function human:get_pet_bank_container()
    return skynet.call(self.obj_address, "lua", "get_pet_bank_container")
end

function human:get_sold_out_container()
    return skynet.call(self.obj_address, "lua", "get_sold_out_container")
end

function human:get_equip_container()
    return skynet.call(self.obj_address, "lua", "get_equip_container")
end

function human:get_prop_bag_container()
    return skynet.call(self.obj_address, "lua", "get_prop_bag_container")
end

function human:get_fasion_bag_container()
    return skynet.call(self.obj_address, "lua", "get_fasion_bag_container")
end

function human:update_fasion_buff(fasionid,buff_flag)
    return skynet.call(self.obj_address, "lua", "update_fasion_buff",fasionid,buff_flag)
end

function human:get_menpai()
    return skynet.call(self.obj_address, "lua", "get_menpai")
end

function human:get_attack_traits_type()
    local menpai = self:get_menpai()
    return (define.MENPAI_ATTACK_TRAITS or {})[menpai] or menpai
end

function human:get_equip_list()
    return skynet.call(self.obj_address, "lua", "get_equip_list")
end

function human:get_equip(equip_point)
    return skynet.call(self.obj_address, "lua", "get_equip", equip_point)
end

function human:get_wuhun_wg()
    return skynet.call(self.obj_address, "lua", "get_wuhun_wg")
end

function human:send_wuhun_wg(who, type, huanhun_id)
    skynet.send(self.obj_address, "lua", "send_wuhun_wg", who, type, huanhun_id)
end

function human:get_skill_level(skill_id)
    return skynet.call(self.obj_address, "lua", "get_skill_level", skill_id)
end

function human:add_lingwu_skill(skill)

end

function human:get_item_bag_list()
    return skynet.call(self.obj_address, "lua", "get_item_bag_list")
end

function human:get_fasion_bag_list()
    return skynet.call(self.obj_address, "lua", "get_fasion_bag_list")
end

function human:get_xinfa_list()
    return skynet.call(self.obj_address, "lua", "get_xinfa_list")
end

function human:get_talent()
    return skynet.call(self.obj_address, "lua", "get_talent")
end

function human:get_xinfa(id)
    return skynet.call(self.obj_address, "lua", "get_xinfa", id)
end

function human:study_xinfa(id, level)
    skynet.send(self.obj_address, "lua", "study_xinfa", id, level)
end

function human:get_ability_list()
    return skynet.call(self.obj_address, "lua", "get_ability_list")
end

function human:get_prescriptions()
    return skynet.call(self.obj_address, "lua", "get_prescriptions")
end

function human:cy_four_crafting_learn(faction)
    return skynet.call(self.obj_address, "lua", "cy_four_crafting_learn", faction)
end

function human:cy_four_training_quote(faction, kind, id)
    return skynet.call(self.obj_address, "lua", "cy_four_training_quote", faction, kind, id)
end

function human:cy_four_training_perform(faction, kind, id, previous)
    return skynet.call(self.obj_address, "lua", "cy_four_training_perform", faction, kind, id, previous)
end

function human:study_ability(id, exp, level)
    skynet.send(self.obj_address, "lua", "study_ability", id, exp, level)
end

function human:add_ability_exp(id, exp)
    skynet.send(self.obj_address, "lua", "add_ability_exp", id, exp)
end

function human:set_ability_exp(id, exp, exp_top)
    skynet.send(self.obj_address, "lua", "set_ability_exp", id, exp, exp_top)
end

function human:get_ability_exp(id)
    return skynet.call(self.obj_address, "lua", "get_ability_exp", id)
end

function human:study_prescription(id, flag)
    skynet.send(self.obj_address, "lua", "study_prescription", id, flag)
end

function human:is_prescription_have_learnd(id)
    return skynet.call(self.obj_address, "lua", "is_prescription_have_learnd", id)
end

function human:send_ability_list()
    skynet.send(self.obj_address, "lua", "send_ability_list")
end

function human:stop_character_logic(...)
    self.character_logic_stopped = true
    self:on_stop_character_logic(...)
    self:set_character_logic(define.ENUM_CHARACTER_LOGIC.CHARACTER_LOGIC_IDLE)
end

function human:clear_xinfa_list()
    skynet.send(self.obj_address, "lua", "clear_xinfa_list")
end

function human:get_skill_list()
    return skynet.call(self.obj_address, "lua", "get_skill_list")
end

function human:get_total_skills_list()
    return skynet.call(self.obj_address, "lua", "get_total_skills_list")
end

function human:have_skill(skill)
    local skills = self:get_total_skills_list()
    for _, id in ipairs(skills) do
        if id == skill then
            return true
        end
    end
    return false
end

function human:clear_menpai_skills()
    skynet.send(self.obj_address, "lua", "clear_menpai_skills")
end

function human:get_obj_type()
    return "human"
end

function human:get_agent()
    return skynet.call(self.obj_address, "lua", "get_agent")
end

function human:get_exterior_list()
    return skynet.call(self.obj_address, "lua", "get_exterior_list")
end

function human:get_ride()
    return skynet.call(self.obj_address, "lua", "get_ride")
end

function human:get_ride_model()
    return skynet.call(self.obj_address, "lua", "get_ride_model")
end

function human:get_model_id()
    return skynet.call(self.obj_address, "lua", "get_model_id")
end

function human:item_value(ia)
    return skynet.call(self.obj_address, "lua", "item_value", ia)
end

function human:damage_rate()
    return skynet.call(self.obj_address, "lua", "damage_rate")
end
function human:set_server_id(server_id)
    skynet.send(self.obj_address, "lua", "set_server_id", server_id)
end

function human:get_server_id()
    return skynet.call(self.obj_address, "lua", "get_server_id")
end

function human:set_guild_id(guild_id)
    skynet.send(self.obj_address, "lua", "set_guild_id", guild_id)
end

function human:set_guild_name(guild_name)
    skynet.send(self.obj_address, "lua", "set_guild_name", guild_name)
end

function human:set_confederate_id(confederate_id)
    skynet.send(self.obj_address, "lua", "set_confederate_id", confederate_id)
end

function human:set_confederate_name(confederate_name)
    skynet.send(self.obj_address, "lua", "set_confederate_name", confederate_name)
end

function human:get_confederate_name()
    return skynet.call(self.obj_address, "lua", "get_confederate_name")
end

function human:get_guild()
    return skynet.call(self.obj_address, "lua", "get_guild")
end

function human:get_guild_uinfo()
    return skynet.call(self.obj_address, "lua", "get_guild_uinfo")
end

function human:get_honour()
    return skynet.call(self.obj_address, "lua", "get_honour")
end

function human:set_honour(honour)
    skynet.send(self.obj_address, "lua", "set_honour", honour)
end

function human:set_ride(ride)
    skynet.send(self.obj_address, "lua", "set_ride", ride)
end

function human:get_ride_model()
    return skynet.call(self.obj_address, "lua", "get_ride_model")
end

function human:add_hair_color(hair_color)
    skynet.send(self.obj_address, "lua", "add_hair_color", hair_color)
end

function human:set_hair_color(hair_index)
    skynet.send(self.obj_address, "lua", "set_hair_color", hair_index)
end

function human:get_hair_color_index_by_color_value(color_value)
    return skynet.call(self.obj_address, "lua", "get_hair_color_index_by_color_value", color_value)
end

function human:save_hair_color(hair_color)
    skynet.send(self.obj_address, "lua", "save_hair_color", hair_color)
end

function human:active_weapon_visual(visual)
    skynet.send(self.obj_address, "lua", "active_weapon_visual", visual)
end

function human:get_hair_color_index_by_color_value(color_value)
    return skynet.call(self.obj_address, "lua", "get_hair_color_index_by_color_value", color_value)
end

function human:set_shenbind_status(change)
    skynet.send(self.obj_address, "lua", "set_shenbind_status", change)
end

function human:get_cur_weapon_visual(sceneId)
    skynet.call(self.obj_address, "lua", "get_cur_weapon_visual", sceneId)
end

function human:get_exterior_face_style_index()
    return skynet.call(self.obj_address, "lua", "get_exterior_face_style_index")
end

function human:set_exterior_hair_style_index(index)
    skynet.send(self.obj_address, "lua", "set_exterior_hair_style_index", index)
end

function human:get_exterior_hair_style_index()
    return skynet.call(self.obj_address, "lua", "get_exterior_hair_style_index")
end

function human:set_exterior_hair_color_index(index)
    skynet.send(self.obj_address, "lua", "set_exterior_hair_color_index", index)
end

function human:get_exterior_hair_color_index()
    return skynet.call(self.obj_address, "lua", "get_exterior_hair_color_index")
end

function human:set_exterior_portrait_index(index)
    skynet.send(self.obj_address, "lua", "set_exterior_portrait_index", index)
end

function human:get_exterior_portrait_index()
    return skynet.call(self.obj_address, "lua", "get_exterior_portrait_index")
end

function human:set_exterior_pet_soul_id(id)
    skynet.send(self.obj_address, "lua", "set_exterior_pet_soul_id", id)
end

function human:get_exterior_pet_soul_id()
    return skynet.call(self.obj_address, "lua", "get_exterior_pet_soul_id")
end

function human:set_fashion_depot_index(index)
    skynet.send(self.obj_address, "lua", "set_fashion_depot_index", index)
end

function human:get_fashion_depot_index()
    return skynet.call(self.obj_address, "lua", "get_fashion_depot_index")
end

function human:get_pet_soul_melting_level()
    return skynet.call(self.obj_address, "lua", "get_pet_soul_melting_level")
end

function human:set_pet_soul_melting_model(model)
    skynet.send(self.obj_address, "lua", "set_pet_soul_melting_model", model)
end

function human:set_exterior_weapon_visual_id(index,level)
    skynet.send(self.obj_address, "lua", "set_exterior_weapon_visual_id", index, level)
end

function human:get_exterior_weapon_visual_id()
    return skynet.call(self.obj_address, "lua", "get_exterior_weapon_visual_id")
end

function human:get_exterior_weapon_visual_data(id)
    return skynet.call(self.obj_address, "lua", "get_exterior_weapon_visual_data",id)
end

function human:get_exterior_weapon_visual()
    return skynet.call(self.obj_address, "lua", "get_exterior_weapon_visual")
end

function human:get_exterior_head_by_id(id)
    return skynet.call(self.obj_address, "lua", "get_exterior_head_by_id",id)
end
function human:get_exterior_head_info()
    return skynet.call(self.obj_address, "lua", "get_exterior_head_info")
end
function human:get_exterior_back_info()
    return skynet.call(self.obj_address, "lua", "get_exterior_back_info")
end
function human:get_exterior_back_by_id(id)
    return skynet.call(self.obj_address, "lua", "get_exterior_back_by_id",id)
end
function human:set_exterior_head_pos(id,posx,posy,posz)
    return skynet.call(self.obj_address, "lua", "set_exterior_head_pos",id,posx,posy,posz)
end
function human:set_exterior_back_pos(id,posx,posy,posz)
    return skynet.call(self.obj_address, "lua", "set_exterior_back_pos",id,posx,posy,posz)
end
function human:set_exterior_head_id(add)
    return skynet.call(self.obj_address, "lua", "set_exterior_head_id",add)
end
function human:set_exterior_back_id(add)
    return skynet.call(self.obj_address, "lua", "set_exterior_back_id",add)
end
function human:get_exterior_head_visual_id()
    return skynet.call(self.obj_address, "lua", "get_exterior_head_visual_id")
end

function human:set_exterior_head_visual_id(id,pos)
    return skynet.call(self.obj_address, "lua", "set_exterior_head_visual_id",id,pos)
end

function human:get_exterior_back_visual_id()
    return skynet.call(self.obj_address, "lua", "get_exterior_back_visual_id")
end

function human:set_exterior_back_visual_id(id,pos)
    return skynet.call(self.obj_address, "lua", "set_exterior_back_visual_id",id,pos)
end

function human:set_portrait_id(id)
    skynet.send(self.obj_address, "lua", "set_portrait_id", id)
end

function human:get_portrait_id()
    return skynet.call(self.obj_address, "lua", "get_portrait_id")
end

function human:set_face_style(id)
    skynet.send(self.obj_address, "lua", "set_face_style", id)
end

function human:set_hair_style(id)
    skynet.send(self.obj_address, "lua", "set_hair_style", id)
end

function human:get_money()
    return skynet.call(self.obj_address, "lua", "get_money")
end

function human:get_jiaozi()
    return skynet.call(self.obj_address, "lua", "get_jiaozi")
end

function human:set_mood(mood)
    skynet.send(self.obj_address, "lua", "set_mood", mood)
end

function human:get_mood()
    return skynet.call(self.obj_address, "lua", "get_mood")
end

function human:set_money(money, reason, extra)
    skynet.send(self.obj_address, "lua", "set_money", money, reason, extra)
end

function human:set_jiaozi(money, reason, extra)
    return skynet.call(self.obj_address, "lua", "set_jiaozi", money, reason, extra)
end

function human:get_yuanbao()
    return skynet.call(self.obj_address, "lua", "get_yuanbao")
end

function human:set_yuanbao(yuanbao, reason, extra)
    return skynet.call(self.obj_address, "lua", "set_yuanbao", yuanbao, reason, extra)
end

function human:cost_yuanbao(count, reason, extra)
    return skynet.call(self.obj_address, "lua", "cost_yuanbao", count, reason, extra)
end

function human:add_yuanbao(count, reason, extra)
    return skynet.call(self.obj_address, "lua", "add_yuanbao", count, reason, extra)
end

function human:set_menpai(menpai)
    return skynet.call(self.obj_address, "lua", "set_menpai", menpai)
end

function human:set_exp(exp)
    return skynet.call(self.obj_address, "lua", "set_exp", exp)
end

function human:get_exp()
    return skynet.call(self.obj_address, "lua", "get_exp")
end

function human:add_exp(add_exp, pet_add_exp, is_from_monster)
    skynet.send(self.obj_address, "lua", "add_exp", add_exp, pet_add_exp, is_from_monster)
end

function human:add_aq_exp(add_exp, award_exp)
    return skynet.call(self.obj_address, "lua", "add_aq_exp", add_exp, award_exp)
end

function human:on_level_up(level)
    skynet.send(self.obj_address, "lua", "on_level_up", level)
end

function human:on_login()
    self:get_scene():get_script_engienr():call(define.SCENE_SCRIPT_ID, "OnScenePlayerLogin", self:get_obj_id(), os.time())
    local logout_time = self:get_logout_time()
    if logout_time == 0 then
        self:on_fist_login()
    end
end

function human:on_fist_login()
    self:get_scene():get_script_engienr():call(define.SCENE_SCRIPT_ID, "OnScenePlayerFirstLogin", self:get_obj_id(), os.time())
end

function human:get_logout_time()
    return skynet.call(self.obj_address, "lua", "get_logout_time")
end

function human:set_logout_time(logout_time)
    skynet.send(self.obj_address, "lua", "set_logout_time", logout_time)
end

function human:get_pet()
    return skynet.call(self.obj_address, "lua", "get_pet")
end

function human:set_assistant_id()

end

function human:get_assistant_id()

end

function human:create_new_obj_packet()
    return skynet.call(self.obj_address, "lua", "create_new_obj_packet")
end

function human:get_name()
    return skynet.call(self.obj_address, "lua", "get_name")
end

function human:get_guid()
    return skynet.call(self.obj_address, "lua", "get_guid")
end

function human:set_world_pos(world_pos)
    skynet.send(self.obj_address, "lua", "set_world_pos", world_pos)
    self.scene:char_world_pos_changed(self)
end

function human:get_world_pos()
    return skynet.call(self.obj_address, "lua", "get_world_pos")
end

function human:get_scene_id()
    return skynet.call(self.obj_address, "lua", "get_scene_id")
end

function human:set_attrib(...)
    skynet.send(self.obj_address, "lua", "set_attrib", ...)
end

function human:set_cool_down(id, cool_down_time)
    skynet.send(self.obj_address, "lua", "set_cool_down", id, cool_down_time)
end

function human:update_cool_down_time(id, value)
    skynet.send(self.obj_address, "lua", "update_cool_down_time", id, value)
end

function human:send_default_skill_combo_operation()
    skynet.send(self.obj_address, "lua", "send_default_skill_combo_operation")
end

function human:get_hit()
    return skynet.call(self.obj_address, "lua", "get_hit")
end

function human:get_miss()
    return skynet.call(self.obj_address, "lua", "get_miss")
end

function human:get_speed()
    return skynet.call(self.obj_address, "lua", "get_speed")
end

function human:get_base_attribs()
    return skynet.call(self.obj_address, "lua", "get_base_attribs")
end

function human:get_detail_attribs()
    return skynet.call(self.obj_address, "lua", "get_detail_attribs")
end

function human:get_attrib(attr)
    return skynet.call(self.obj_address, "lua", "get_attrib", attr)
end

function human:on_damages(damages, caster_obj_id, is_critical, skill_id, imp)
    skynet.send(self.obj_address, "lua", "on_damages", damages, caster_obj_id, is_critical, skill_id, imp)
end

function human:on_damage_target(target, damages, skill_id)
    skynet.send(self.obj_address, "lua", "on_damage_target", target, damages, skill_id)
end

function human:on_hit_target(reciver, skill)
    skynet.send(self.obj_address, "lua", "on_hit_target", reciver, skill)
end

function human:on_be_hit(sender, skill)
    skynet.send(self.obj_address, "lua", "on_be_hit", sender, skill)
end

function human:on_be_skill(sender, skill_id, behaviortype)
    skynet.send(self.obj_address, "lua", "on_be_skill", sender, skill_id, behaviortype)
end

function human:on_be_hostility_skill(sender, skill_id, behaviortype)
    skynet.send(self.obj_address, "lua", "on_be_hostility_skill", sender, skill_id, behaviortype)
end

function human:modify_setting(key, value)
    skynet.send(self.obj_address, "lua", "modify_setting", key, value)
end

function human:get_setting()
    return skynet.call(self.obj_address, "lua", "get_setting")
end

function human:get_setting_by_type(type)
    return skynet.call(self.obj_address, "lua", "get_setting_by_type", type)
end

function human:setting_flag_is_true(st, shift)
    return skynet.call(self.obj_address, "lua", "setting_flag_is_true", st, shift)
end

function human:get_empty_setting(start, stop, ignore)
    return skynet.call(self.obj_address, "lua", "get_empty_setting", start, stop, ignore)
end

function human:send_operate_result_msg(result)
    skynet.send(self.obj_address, "lua", "send_operate_result_msg", result)
end

function human:notify_tips(msg)
    skynet.send(self.obj_address, "lua", "notify_tips", msg)
end

function human:use_ident_scroll(ident_bag_index, equip_bag_index)
    return skynet.call(self.obj_address, "lua", "use_ident_scroll", ident_bag_index, equip_bag_index)
end

function human:use_yuanbao_piao(bag_index)
    return skynet.call(self.obj_address, "lua", "use_yuanbao_piao", bag_index)
end

function human:split_item(split)
    return skynet.call(self.obj_address, "lua", "split_item", split)
end

function human:is_new_player_relive()
    return false
end

function human:set_on_relive_script_id(script_id)
    skynet.send(self.obj_address, "lua", "set_on_relive_script_id", script_id)
end

function human:change_scene(to, world_pos)
    self:get_scene():notify_change_scene(self:get_obj_id(), to, world_pos.x, world_pos.y)
end

function human:verify_item()
    skynet.send(self.obj_address, "lua", "verify_item")
end

function human:depleting_used_item(selfId)
    return self:skill_deplte_item(selfId)
end

function human:skill_deplte_item()
    return skynet.call(self.obj_address, "lua", "skill_deplte_item")
end

function human:set_temp_pk_mode(mode)
    skynet.send(self.obj_address, "lua", "set_temp_pk_mode", mode)
end

function human:set_pvp_rule(rule)
    skynet.send(self.obj_address, "lua", "set_pvp_rule", rule)
end

function human:set_chedifulu_data(index, sceneid, position)
    skynet.send(self.obj_address, "lua", "set_chedifulu_data", index, sceneid, position)
end

function human:get_chedifulu_data(index)
    return skynet.call(self.obj_address, "lua", "get_chedifulu_data", index)
end

function human:send_chedifulu_data(index)
    skynet.send(self.obj_address, "lua", "send_chedifulu_data", index)
end

function human:send_rmb_chat_face_info()
    skynet.send(self.obj_address, "lua", "send_rmb_chat_face_info")
end

function human:send_rmb_chat_action_info()
    skynet.send(self.obj_address, "lua", "send_rmb_chat_action_info")
end

function human:send_mission_list()
    skynet.send(self.obj_address, "lua", "send_mission_list")
end

function human:send_setting()
    skynet.send(self.obj_address, "lua", "send_setting")
end

function human:get_title_is_hide()
    return skynet.call(self.obj_address, "lua", "get_title_is_hide")
end

function human:set_chedifulu_data_select_index(index)
    skynet.send(self.obj_address, "lua", "set_chedifulu_data_select_index", index)
end

function human:get_chedifulu_data_select_index()
    return skynet.call(self.obj_address, "lua", "get_chedifulu_data_select_index")
end

function human:update_chedifulu_use_times(value)
    skynet.send(self.obj_address, "lua", "update_chedifulu_use_times", value)
end

function human:get_chedifulu_use_times()
    return skynet.call(self.obj_address, "lua", "get_chedifulu_use_times")
end

function human:send_sold_out_list()
    skynet.send(self.obj_address, "lua", "send_sold_out_list")
end

function human:add_xinfa(xinfa_id)
    skynet.send(self.obj_address, "lua", "add_xinfa", xinfa_id)
end

function human:send_xinfa_list()
    skynet.send(self.obj_address, "lua", "send_xinfa_list")
end

function human:add_skill(skill)
    skynet.send(self.obj_address, "lua", "add_skill", skill)
end

function human:del_skill(id)
    skynet.send(self.obj_address, "lua", "del_skill", id)
end

function human:send_skill_list()
    skynet.send(self.obj_address, "lua", "send_skill_list")
end

function human:add_money(money, reason, extra)
    skynet.send(self.obj_address, "lua", "add_money", money, reason, extra)
end

function human:add_jiaozi(money, reason, extra)
    skynet.send(self.obj_address, "lua", "add_money", money, reason, extra)
end

function human:add_bind_yuanbao(value, reason, extra)
    skynet.send(self.obj_address, "lua", "add_bind_yuanbao", value, reason, extra)
end

function human:get_bind_yuanbao()
    return skynet.call(self.obj_address, "lua", "get_bind_yuanbao")
end

function human:set_bind_yuanbao(bind_yuanbao, reason, extra)
    skynet.send(self.obj_address, "lua", "set_bind_yuanbao", bind_yuanbao, reason, extra)
end

function human:cost_bind_yuanbao(value, reason, extra)
    skynet.send(self.obj_address, "lua", "cost_bind_yuanbao", value, reason, extra)
end

function human:is_attackers(other)
    return skynet.call(self.obj_address, "lua", "is_attackers", other)
end

function human:is_in_pk_declaration_list(other)
    return skynet.call(self.obj_address, "lua", "is_in_pk_declaration_list", other)
end

function human:is_wild_war_guild(other)
    return skynet.call(self.obj_address, "lua", "is_wild_war_guild", other)
end

function human:is_counter_killed(killer)
    return skynet.call(self.obj_address, "lua", "is_counter_killed", killer)
end

function human:is_enemy_human(other)
    return skynet.call(self.obj_address, "lua", "is_enemy_human", other)
end

function human:is_enemy(other)
    return skynet.call(self.obj_address, "lua", "is_enemy", other)
end

function human:is_teammate(other)
    return skynet.call(self.obj_address, "lua", "is_teammate", other)
end

function human:is_raidmate(other)
    return skynet.call(self.obj_address, "lua", "is_raidmate", other)
end

function human:is_partner(other)
    return skynet.call(self.obj_address, "lua", "is_partner", other)
end

function human:get_model()
    return skynet.call(self.obj_address, "lua", "get_model")
end

function human:set_model(model)
    skynet.send(self.obj_address, "lua", "set_model", model)
end

function human:get_face_style()
    return skynet.call(self.obj_address, "lua", "get_face_style")
end

function human:get_hair_style()
    return skynet.call(self.obj_address, "lua", "get_hair_style")
end

function human:get_hair_color()
    return skynet.call(self.obj_address, "lua", "get_hair_color")
end

function human:get_team_id()
    return skynet.call(self.obj_address, "lua", "get_team_id")
end

function human:get_team_info()
    return skynet.call(self.obj_address, "lua", "get_team_info")
end

function human:get_is_team_leader()
    return skynet.call(self.obj_address, "lua", "get_is_team_leader")
end

function human:get_team_follow_flag()
    return skynet.call(self.obj_address, "lua", "get_team_follow_flag")
end

function human:set_team_follow_flag(flag)
    skynet.send(self.obj_address, "lua", "set_team_follow_flag", flag)
end

function human:add_team_follow_member(follow_member)
    skynet.send(self.obj_address, "lua", "add_team_follow_member", follow_member)
end

function human:get_team_follow_speed()
    return skynet.call(self.obj_address, "lua", "get_team_follow_speed")
end

function human:set_team_follow_speed(speed)
    skynet.send(self.obj_address, "lua", "set_team_follow_speed", speed)
end

function human:get_team_follow_speed_up()
    return skynet.call(self.obj_address, "lua", "get_team_follow_speed_up")
end

function human:set_team_follow_speed_up(team_follow_speed_up)
    skynet.send(self.obj_address, "lua", "set_team_follow_speed_up", team_follow_speed_up)
end

function human:out_of_team_follow_range()

end

function human:in_team_follow_range()

end

function human:update_raid_info(msg)
    return skynet.call(self.obj_address, "lua", "update_raid_info", msg)
end

function human:update_team_info(msg)
    return skynet.call(self.obj_address, "lua", "update_team_info", msg)
end

function human:stop_team_follow()
    skynet.send(self.obj_address, "lua", "stop_team_follow")
end

function human:update_team_info_by_team_list(msg)
    skynet.send(self.obj_address, "lua", "update_team_info_by_team_list", msg)
end

function human:update_team_option(msg)
    skynet.send(self.obj_address, "lua", "update_team_option", msg)
end

function human:item_flush(equipPoint)
    skynet.send(self.obj_address, "lua", "item_flush", equipPoint)
end

function human:send_refresh_attrib()
    skynet.send(self.obj_address, "lua", "send_refresh_attrib")
end

function human:mark_data_dirty_flag(param)
    skynet.send(self.obj_address, "lua", "mark_data_dirty_flag",param)
end

function human:sync_team_member_info()
    skynet.send(self.obj_address, "lua", "sync_team_member_info")
end

function human:wash_some_points(ntype, point)
    skynet.send(self.obj_address, "lua", "wash_some_points", ntype, point)
end

function human:wash_points()
    skynet.send(self.obj_address, "lua", "wash_points")
end

function human:change_menpai_points()
    skynet.send(self.obj_address, "lua", "change_menpai_points")
end

function human:manual_attr(manual)
    return skynet.call(self.obj_address, "lua", "manual_attr", manual)
end

function human:add_ride_buff(BUFFID,acttrue)
    skynet.send(self.obj_address, "lua", "add_ride_buff", BUFFID,acttrue)
end

function human:send_exterior_info(open_type)
    skynet.send(self.obj_address, "lua", "send_exterior_info", open_type)
end

function human:have_this_head_image(id)
    return skynet.call(self.obj_address, "lua", "have_this_head_image", id)
end

function human:have_this_face_style(id)
    return skynet.call(self.obj_address, "lua", "have_this_face_style", id)
end

function human:have_this_hair_style(id)
    return skynet.call(self.obj_address, "lua", "have_this_hair_style", id)
end

function human:have_this_ride(index)
    return skynet.call(self.obj_address, "lua", "have_this_ride", index)
end

function human:reverse_ride(index)
    return skynet.call(self.obj_address, "lua", "reverse_ride", index)
end

function human:add_expiration_time(index, add)
    return skynet.call(self.obj_address, "lua", "add_expiration_time", index, add)
end

function human:get_double_exp_info()
    return skynet.call(self.obj_address, "lua", "get_double_exp_info")
end

function human:send_double_exp_info()
    skynet.send(self.obj_address, "lua", "send_double_exp_info")
end

function human:set_exp_rate(value)
    skynet.send(self.obj_address, "lua", "set_exp_rate",value)
end

function human:get_double_exp_mult()
    return skynet.call(self.obj_address, "lua", "get_double_exp_mult")
end

function human:add_pet_by_data_id(data_id, is_rmb, growth_rate, pet_guid_low)
    return skynet.call(self.obj_address, "lua", "add_pet_by_data_id", data_id, is_rmb, growth_rate, pet_guid_low)
end

function human:add_pet(pet)
    return skynet.call(self.obj_address, "lua", "add_pet_by_data_id", pet)
end

function human:send_pets_detail(who, type)
    skynet.send(self.obj_address, "lua", "send_pets_detail", who, type)
end

function human:send_pet_detail(pet, who, type)
    skynet.send(self.obj_address, "lua", "send_pet_detail", pet, who, type)
end

function human:set_guid_of_call_up_pet(guid)
    skynet.send(self.obj_address, "lua", "set_guid_of_call_up_pet", guid)
end

function human:get_guid_of_call_up_pet()
    return skynet.call(self.obj_address, "lua", "get_guid_of_call_up_pet")
end

function human:can_take(pet)
    return skynet.call(self.obj_address, "lua", "can_take", pet)
end

function human:test_call_up_pet(guid)
    return skynet.call(self.obj_address, "lua", "test_call_up_pet", guid)
end

function human:recall_pet()
    return skynet.call(self.obj_address, "lua", "recall_pet")
end

function human:set_current_pet_guid(guid)
    skynet.send(self.obj_address, "lua", "set_current_pet_guid", guid)
end

function human:get_current_pet_guid()
    return skynet.call(self.obj_address, "lua", "get_current_pet_guid")
end

function human:is_my_spouse()

end

function human:create_pet()
    return skynet.call(self.obj_address, "lua", "create_pet")
end

function human:release_pet()
    skynet.send(self.obj_address, "lua", "release_pet")
end

function human:call_up_pet()
    return skynet.call(self.obj_address, "lua", "call_up_pet")
end

function human:test_pet_soul_melting(guid)
    return skynet.call(self.obj_address, "lua", "test_pet_soul_melting", guid)
end

function human:remelting_pet_soul()
    return skynet.call(self.obj_address, "lua", "remelting_pet_soul")
end

function human:set_current_soul_melting_pet_guid(guid)
    skynet.send(self.obj_address, "lua", "set_current_soul_melting_pet_guid", guid)
end

function human:get_current_soul_melting_pet_guid()
    return skynet.call(self.obj_address, "lua", "get_current_soul_melting_pet_guid")
end

function human:set_guid_of_soul_melting_pet(guid)
    skynet.send(self.obj_address, "lua", "set_guid_of_soul_melting_pet", guid)
end

function human:get_guid_of_soul_melting_pet()
    return skynet.call(self.obj_address, "lua", "get_guid_of_soul_melting_pet")
end

function human:pet_soul_melting()
    return skynet.call(self.obj_address, "lua", "pet_soul_melting")
end

function human:baby_to_attack()
    skynet.send(self.obj_address, "lua", "baby_to_attack")
end

function human:on_register_to_scene()
    skynet.send(self.obj_address, "lua", "on_register_to_scene")
end

function human:clean_up_pet()
    skynet.send(self.obj_address, "lua", "clean_up_pet")
end

function human:free_pet_to_nature(logparam, guid)
    return skynet.call(self.obj_address, "lua", "free_pet_to_nature", logparam, guid)
end

function human:remove_pet(logparam, guid)
    return skynet.call(self.obj_address, "lua", "remove_pet", logparam, guid)
end

function human:cy_commit_equipment_skill_roll(pos,pending,materials,cost)
    return skynet.call(self.obj_address,'lua','cy_commit_equipment_skill_roll',pos,pending,materials,cost)
end

function human:cy_replace_equipment_skill_roll(pos,kind)
    return skynet.call(self.obj_address,'lua','cy_replace_equipment_skill_roll',pos,kind)
end

function human:cy_longwen_skill_operation(pos,operation,selection)
    return skynet.call(self.obj_address,'lua','cy_longwen_skill_operation',pos,operation,selection)
end

function human:cy_lingpai_operation(operation,pos,group)
    return skynet.call(self.obj_address,'lua','cy_lingpai_operation',operation,pos,group)
end

function human:set_temp_aq_skills(skills)
    skynet.send(self.obj_address, "lua", "set_temp_aq_skills", skills)
end

function human:get_temp_aq_skills()
    return skynet.call(self.obj_address, "lua", "get_temp_aq_skills")
end

function human:set_temp_wh_skills(skills)
    skynet.send(self.obj_address, "lua", "set_temp_wh_skills", skills)
end

function human:get_temp_wh_skills()
    return skynet.call(self.obj_address, "lua", "get_temp_wh_skills")
end

function human:set_temp_pet_soul_attr_data(bag_index, attr)
    skynet.send(self.obj_address, "lua", "set_temp_pet_soul_attr_data", bag_index, attr)
end

function human:get_temp_pet_soul_attr_data()
    return skynet.call(self.obj_address, "lua", "get_temp_pet_soul_attr_data")
end

function human:set_temp_super_attrs(super_attrs)
    skynet.send(self.obj_address, "lua", "set_temp_super_attrs", super_attrs)
end

function human:get_temp_super_attrs()
    return skynet.call(self.obj_address, "lua", "get_temp_super_attrs")
end

function human:get_pk_mode()
    return skynet.call(self.obj_address, "lua", "get_pk_mode")
end

function human:change_pk_mode(mode)
    skynet.send(self.obj_address, "lua", "change_pk_mode", mode)
end

function human:set_huanhun_qk(qk, index)
    skynet.send(self.obj_address, "lua", "set_huanhun_qk", qk, index)
end

function human:get_wuhun_visual()
    return skynet.call(self.obj_address, "lua", "get_wuhun_visual")
end

function human:active_wuhun_wg(id)
    skynet.send(self.obj_address, "lua", "active_wuhun_wg", id)
end

function human:active_rmb_chat_info(id, date)
    skynet.send(self.obj_address, "lua", "active_rmb_chat_info", id, date)
end

function human:get_mission_data_by_script_id(id)
    return skynet.call(self.obj_address, "lua", "get_mission_data_by_script_id", id)
end

function human:get_mission_flag_by_script_id(id)
    return skynet.call(self.obj_address, "lua", "get_mission_flag_by_script_id", id)
end

function human:set_mission_flag_by_script_id(id, val)
    skynet.send(self.obj_address, "lua", "set_mission_flag_by_script_id", id, val)
end

function human:get_mission_data_ex_by_script_id(id)
    return skynet.call(self.obj_address, "lua", "get_mission_data_ex_by_script_id", id)
end

function human:set_mission_data_ex_by_script_id(id, val)
    skynet.send(self.obj_address, "lua", "set_mission_data_ex_by_script_id", id, val)
end

function human:set_mission_data_by_script_id(id, val)
    skynet.send(self.obj_address, "lua", "set_mission_data_by_script_id", id, val)
end

function human:mission_abandon(index)
    skynet.send(self.obj_address, "lua", "mission_abandon", index)
end

function human:save_restore_scene_and_pos(sn)
    skynet.send(self.obj_address, "lua", "save_restore_scene_and_pos", sn)
end

function human:is_have_mission(mission_id)
    return skynet.call(self.obj_address, "lua", "is_have_mission", mission_id)
end

function human:get_mission_index(mission_id)
    return skynet.call(self.obj_address, "lua", "get_mission_index", mission_id)
end

function human:get_mission_by_id(mission_id)
    return skynet.call(self.obj_address, "lua", "get_mission_by_id", mission_id)
end

function human:get_mission_param(mission_index, index)
    return skynet.call(self.obj_address, "lua", "get_mission_param", mission_index, index)
end

function human:set_mission_by_index(mission_index, index, value)
    skynet.send(self.obj_address, "lua", "set_mission_by_index", mission_index, index, value)
end

function human:del_mission(mission_id)
    return skynet.call(self.obj_address, "lua", "del_mission", mission_id)
end

function human:del_all_mission()
    skynet.send(self.obj_address, "lua", "del_all_mission")
end

function human:add_mission(id, script_id, killObjEvent, enterAreaEvent, itemChangeEvent)
    return skynet.call(self.obj_address, "lua", "add_mission", id, script_id, killObjEvent, enterAreaEvent, itemChangeEvent)
end

function human:reset_mission_event()

end

function human:get_script_id_by_mission_id(mission_id)
    return skynet.call(self.obj_address, "lua", "get_script_id_by_mission_id", mission_id)
end

function human:set_mission_event(mission_id, event)
    skynet.send(self.obj_address, "lua", "set_mission_event", mission_id, event)
end

function human:is_mission_full()
    return skynet.call(self.obj_address, "lua", "is_mission_full")
end

function human:is_mission_have_done(id_mission)
    return skynet.call(self.obj_address, "lua", "is_mission_have_done", id_mission)
end

function human:set_mission_have_done(id_mission, done)
    skynet.send(self.obj_address, "lua", "set_mission_have_done", id_mission, done)
end

function human:get_mission_have_done(id_mission)
    return skynet.call(self.obj_address, "lua", "get_mission_have_done", id_mission)
end

function human:get_mission_count()
    return skynet.call(self.obj_address, "lua", "get_mission_count")
end

function human:on_kill_object(obj)
    skynet.send(self.obj_address, "lua", "on_kill_object", obj)
end

function human:on_pick_up_item(item, bag_index)
    skynet.send(self.obj_address, "lua", "on_pick_up_item", item, bag_index)
end

function human:on_add_pet(pet)
    skynet.send(self.obj_address, "lua", "on_add_pet", pet)
end

function human:get_copy_scene_sn()
    return skynet.call(self.obj_address, "lua", "get_copy_scene_sn")
end

function human:reset_mission_cache_data()
    skynet.send(self.obj_address, "lua", "reset_mission_cache_data")
end

function human:set_mission_cache_data(id, val)
    skynet.send(self.obj_address, "lua", "set_mission_cache_data", id, val)
end

function human:get_mission_cache_data(id)
    return skynet.call(self.obj_address, "lua", "get_mission_cache_data", id)
end

function human:get_shop_guids()
    return skynet.call(self.obj_address, "lua", "get_shop_guids")
end

function human:set_shop_guid(index, shg)
    skynet.send(self.obj_address, "lua", "set_shop_guid", index, shg)
end

function human:set_char_shop_guids(sgs)
    skynet.send(self.obj_address, "lua", "set_char_shop_guids", sgs)
end

function human:get_shop_guid_by_index(index)
    return skynet.call(self.obj_address, "lua", "get_shop_guid_by_index", index)
end

function human:add_id_title(id)
    skynet.send(self.obj_address, "lua", "add_id_title", id)
end

function human:have_id_title(id)
    return skynet.call(self.obj_address, "lua", "have_id_title", id)
end

function human:set_title(id, titlestr)
    skynet.send(self.obj_address, "lua", "set_title", id, titlestr)
end

function human:set_current_title(title)
    skynet.send(self.obj_address, "lua", "set_current_title", title)
end

function human:get_current_title()
    return skynet.call(self.obj_address, "lua", "get_current_title")
end

function human:get_title_by_id(id)
    return skynet.call(self.obj_address, "lua", "get_title_by_id", id)
end

function human:set_cur_title_by_id(id)
    skynet.send(self.obj_address, "lua", "set_cur_title_by_id", id)
end

function human:set_cur_title_by_id_title(id)
    skynet.send(self.obj_address, "lua", "set_cur_title_by_id_title", id)
end

function human:get_cur_title()
    return skynet.call(self.obj_address, "lua", "get_cur_title")
end

function human:update_titles_to_client()
    skynet.send(self.obj_address, "lua", "update_titles_to_client")
end

function human:up_xinfa_level(level)
    skynet.send(self.obj_address, "lua", "up_xinfa_level", level)
end

function human:get_min_xinfa_level()
    return skynet.call(self.obj_address, "lua", "get_min_xinfa_level")
end

function human:get_xiulian_level(index)
    return skynet.call(self.obj_address, "lua", "get_xiulian_level", index)
end

function human:get_max_level_xiulian_level()
    return skynet.call(self.obj_address, "lua", "get_max_level_xiulian_level")
end

function human:get_xiulian_upper_limit(index)
    return skynet.call(self.obj_address, "lua", "get_xiulian_upper_limit", index)
end

function human:xiulian_can_level_up(index)
    return skynet.call(self.obj_address, "lua", "xiulian_can_level_up", index)
end

function human:xiulian_level_up(index)
    skynet.send(self.obj_address, "lua", "xiulian_level_up", index)
end

function human:xiulian_upper_limit_up(index, count)
    skynet.send(self.obj_address, "lua", "xiulian_upper_limit_up", index, count)
end

function human:send_xiulian_list()
    skynet.send(self.obj_address, "lua", "send_xiulian_list")
end

function human:reset_talent()
    skynet.send(self.obj_address, "lua", "reset_talent")
end

function human:send_talent(show_type)
    skynet.send(self.obj_address, "lua", "send_talent", show_type)
end

function human:study_sect(talent_id)
    skynet.send(self.obj_address, "lua", "study_sect", talent_id)
end

function human:get_gong_li()
    return skynet.call(self.obj_address, "lua", "get_gong_li")
end

function human:set_gong_li(gongli)
    skynet.send(self.obj_address, "lua", "set_gong_li", gongli)
end

function human:cost_gong_li(count)
    skynet.send(self.obj_address, "lua", "cost_gong_li", count)
end

function human:get_sweep_count(index)
    return skynet.call(self.obj_address, "lua", "get_sweep_count", index)
end

function human:get_sweep_counts()
    return skynet.call(self.obj_address, "lua", "get_sweep_counts")
end

function human:add_sweep_count(index, count)
    skynet.send(self.obj_address, "lua", "add_sweep_count", index, count)
end

function human:cost_sweep_count(index, count)
    skynet.send(self.obj_address, "lua", "cost_sweep_count", index, count)
end

function human:set_sweep_point(index, count)
    skynet.send(self.obj_address, "lua", "set_sweep_point", index, count)
end

function human:set_sec_kill_data(data)
    skynet.send(self.obj_address, "lua", "set_sec_kill_data", data)
end

function human:send_sec_kill_data()
    skynet.send(self.obj_address, "lua", "send_sec_kill_data")
end

function human:get_sec_kill_item_by_index(index)
    return skynet.call(self.obj_address, "lua", "get_sec_kill_item_by_index", index)
end

function human:get_sec_kill_item_count()
    return skynet.call(self.obj_address, "lua", "get_sec_kill_item_count")
end

function human:get_sec_kill_item_by_i(i)
    return skynet.call(self.obj_address, "lua", "get_sec_kill_item_by_i", i)
end

function human:remove_sec_kill_item(index, is_discard)
    skynet.send(self.obj_address, "lua", "remove_sec_kill_item", index, is_discard)
end

function human:remove_all_sec_kill_item()
    skynet.send(self.obj_address, "lua", "remove_all_sec_kill_item")
end

function human:get_campaign_count(index)
    return skynet.call(self.obj_address, "lua", "get_campaign_count", index)
end

function human:get_campaign_counts()
    return skynet.call(self.obj_address, "lua", "get_campaign_counts")
end

function human:set_campaign_count(index, count)
    skynet.send(self.obj_address, "lua", "set_campaign_count", index, count)
end

function human:reset_campaign_count()
    skynet.send(self.obj_address, "lua", "reset_campaign_count")
end

function human:get_pk_value()
    return skynet.call(self.obj_address, "lua", "get_pk_value")
end

function human:set_pk_value(value)
    skynet.send(self.obj_address, "lua", "set_pk_value", value)
end

function human:send_campaign_count()
    skynet.send(self.obj_address, "lua", "send_campaign_count")
end

function human:send_week_active()
    skynet.send(self.obj_address, "lua", "send_week_active")
end

function human:get_week_active()
    return skynet.call(self.obj_address, "lua", "get_week_active")
end

function human:get_week_active_day()
    return skynet.call(self.obj_address, "lua", "get_week_active_day")
end

function human:send_cool_down_time()
    skynet.send(self.obj_address, "lua", "send_cool_down_time")
end

function human:challenge_refresh_skill_cool_down()
    skynet.send(self.obj_address, "lua", "challenge_refresh_skill_cool_down")
end

function human:challenge_restore_skill_cool_down()
    skynet.send(self.obj_address, "lua", "challenge_restore_skill_cool_down")
end

function human:update_kill_monster_count(count)
    skynet.send(self.obj_address, "lua", "update_kill_monster_count", count)
end

function human:get_today_kill_monster_count()
    return skynet.call(self.obj_address, "lua", "get_today_kill_monster_count")
end

function human:set_today_kill_monster_count(count)
    skynet.send(self.obj_address, "lua", "set_today_kill_monster_count", count)
end

function human:can_be_dispatch_item_box()
    return skynet.call(self.obj_address, "lua", "can_be_dispatch_item_box")
end

function human:get_vigor()
    return skynet.call(self.obj_address, "lua", "get_vigor")
end

function human:set_vigor(vigor)
    skynet.send(self.obj_address, "lua", "set_vigor", vigor)
end

function human:get_vigor_max()
    return skynet.call(self.obj_address, "lua", "get_vigor")
end

function human:get_stamina()
    return skynet.call(self.obj_address, "lua", "get_stamina")
end

function human:set_stamina(stamina)
    skynet.send(self.obj_address, "lua", "set_stamina", stamina)
end

function human:get_stamina_max()
    return skynet.call(self.obj_address, "lua", "get_stamina_max")
end

function human:change_menpai(menpai)
    return skynet.call(self.obj_address, "lua", "get_stamina_max")
end

function human:change_menpai_change_xinfa(target_menpai)
    skynet.send(self.obj_address, "lua", "change_menpai_change_xinfa", target_menpai)
end

function human:get_relation_info()
    return skynet.call(self.obj_address, "lua", "get_relation_info")
end

function human:set_relation_info(realtion_list)
    skynet.send(self.obj_address, "lua", "set_relation_info", realtion_list)
end

function human:set_relation_list_from_agent(relation_list)
    skynet.send(self.obj_address, "lua", "set_relation_list_from_agent", relation_list)
end

function human:relation_on_be_human_kill(killer)
    skynet.send(self.obj_address, "lua", "relation_on_be_human_kill", killer)
end

function human:check_right_limit_exchange()
    return skynet.call(self.obj_address, "lua", "check_right_limit_exchange")
end

function human:set_agree_swear_list(otherId)
    skynet.send(self.obj_address, "lua", "set_agree_swear_list", otherId)
end

function human:get_agree_swear_list()
    return skynet.call(self.obj_address, "lua", "get_agree_swear_list")
end

function human:get_master_level()
    return skynet.call(self.obj_address, "lua", "get_master_level")
end

function human:set_master_level(master_level)
    skynet.send(self.obj_address, "lua", "set_master_level", master_level)
end

function human:get_prentice_supply_exp()
    return skynet.call(self.obj_address, "lua", "get_prentice_supply_exp")
end

function human:add_prentice_pro_exp(add_exp)
    skynet.send(self.obj_address, "lua", "add_prentice_pro_exp", add_exp)
end

function human:get_good_bad_value()
    return skynet.call(self.obj_address, "lua", "get_good_bad_value")
end

function human:set_good_bad_value(value)
    skynet.send(self.obj_address, "lua", "set_good_bad_value", value)
end

function human:get_master_moral_point()
    return skynet.call(self.obj_address, "lua", "get_master_moral_point")
end

function human:set_jiebai_name(jiebai_name)
    skynet.send(self.obj_address, "lua", "set_jiebai_name", jiebai_name)
end

function human:get_jiebai_name()
    return skynet.call(self.obj_address, "lua", "get_jiebai_name")
end

function human:set_marry_info(marry_target_guid, is_accept)
    skynet.send(self.obj_address, "lua", "set_marry_info", marry_target_guid, is_accept)
end

function human:get_marry_info()
    return skynet.call(self.obj_address, "lua", "get_marry_info")
end

function human:on_bus(bus_id)
    skynet.send(self.obj_address, "lua", "on_bus", bus_id)
end

function human:off_bus()
    skynet.send(self.obj_address, "lua", "off_bus")
end

function human:has_mount()
    return skynet.call(self.obj_address, "lua", "has_mount")
end

function human:has_dride()
    return false
end

function human:has_change_mode()
    return skynet.call(self.obj_address, "lua", "has_change_mode")
end

function human:start_mission_timer(mission_id)
    skynet.send(self.obj_address, "lua", "start_mission_timer", mission_id)
end

function human:stop_mission_timer(mission_id)
    skynet.send(self.obj_address, "lua", "stop_mission_timer", mission_id)
end

function human:cost_money_with_priority(cost, reason, extra)
    return skynet.call(self.obj_address, "lua", "cost_money_with_priority", cost, reason, extra)
end

function human:cost_money(cost, reason, extra)
    skynet.call(self.obj_address, "lua", "cost_money", cost, reason, extra)
end

function human:check_money_with_priority(cost)
    skynet.call(self.obj_address, "lua", "check_money_with_priority", cost)
end

function human:set_wild_war_list(wild_war_list)
    skynet.call(self.obj_address, "lua", "set_wild_war_list", wild_war_list)
end

function human:is_friend_relation(other)
    return skynet.call(self.obj_address, "lua", "is_friend_relation", other)
end

function human:is_prentice_relation(other)
    return skynet.call(self.obj_address, "lua", "is_prentice_relation", other)
end

function human:get_relation_by_guid_in_group(guid, group)
    return skynet.call(self.obj_address, "lua", "get_relation_by_guid_in_group", guid, group)
end

function human:add_good_bad_value(add)
    return skynet.call(self.obj_address, "lua", "add_good_bad_value", add)
end

function human:inc_friend_point(other)
    skynet.send(self.obj_address, "lua", "inc_friend_point", other)
end

function human:refix_skill_cool_down_time(skill_info, cool_down_time)
    skynet.send(self.obj_address, "lua", "refix_skill_cool_down_time", skill_info, cool_down_time)
end

function human:on_skill_miss(sender, skill_id)
    skynet.send(self.obj_address, "lua", "on_skill_miss",sender, skill_id)
end

function human:on_skill_miss_target(reciver, skill_id)
    skynet.send(self.obj_address, "lua", "on_skill_miss_target", reciver, skill_id)
end

function human:get_skill_template(skill_id)
    return skynet.call(self.obj_address, "lua", "get_skill_template", skill_id)
end

function human:set_talent_trigger_time(name)
    skynet.send(self.obj_address, "lua", "set_talent_trigger_time", name)
end

function human:get_talent_trigger_time(name)
    return skynet.call(self.obj_address, "lua", "get_talent_trigger_time", name)
end

function human:get_top_up_point()
    return skynet.call(self.obj_address, "lua", "get_top_up_point")
end

function human:cost_top_up_point(cost)
    return skynet.call(self.obj_address, "lua", "cost_top_up_point", cost)
end

function human:get_prerechage_money(...)
    return skynet.call(self.obj_address, "lua", "get_prerechage_money", ...)
end

function human:on_enter_scene()
    skynet.call(self.obj_address, "lua", "on_enter_scene")
end

function human:is_begin_send_refresh_attrib()
    return skynet.call(self.obj_address, "lua", "is_begin_send_refresh_attrib")
end

function human:set_near_team_members(members)
    skynet.call(self.obj_address, "lua", "set_near_team_members", members)
end

function human:get_near_team_members()
    return skynet.call(self.obj_address, "lua", "get_near_team_members")
end

function human:add_mission_huoyuezhi(type, count, sync_client)
    skynet.send(self.obj_address, "lua", "add_mission_huoyuezhi", type, count, sync_client)
end

function human:set_is_first_login(is_first_login)
    skynet.call(self.obj_address, "lua", "set_is_first_login", is_first_login)
end

function human:get_is_first_login()
    return skynet.call(self.obj_address, "lua", "get_is_first_login")
end

function human:set_enter_scene_time()
    skynet.send(self.obj_address, "lua", "set_enter_scene_time")
end

function human:get_enter_scene_time()
    return skynet.call(self.obj_address, "lua", "get_enter_scene_time")
end

function human:get_enter_scene_time_diff()
    return skynet.call(self.obj_address, "lua", "get_enter_scene_time_diff")
end

function human:get_talent_by_skill_id(skill_id)
    return skynet.call(self.obj_address, "lua", "get_talent_by_skill_id", skill_id)
end

function human:get_dw_jinjie_features()
    return skynet.call(self.obj_address, "lua", "get_dw_jinjie_features")
end

function human:get_dw_jinjie_features_value(id)
    return skynet.call(self.obj_address, "lua", "get_dw_jinjie_features_value",id)
end

function human:set_dw_jinjie_features_value(id,value)
    return skynet.call(self.obj_address, "lua", "set_dw_jinjie_features_value",id,value)
end

function human:set_dw_jinjie_feature_details(id,level,nexp)
    return skynet.call(self.obj_address, "lua", "set_dw_jinjie_feature_details",id,level,nexp)
end

function human:get_dw_jinjie_feature_details(id)
    return skynet.call(self.obj_address, "lua", "get_dw_jinjie_feature_details",id)
end

function human:set_dw_jinjie_effect_details(equip_point,dw_featuresid,dw_advance_level)
    return skynet.call(self.obj_address, "lua", "set_dw_jinjie_effect_details",equip_point,dw_featuresid,dw_advance_level)
end

function human:get_dw_jinjie_effect_details(id)
    return skynet.call(self.obj_address, "lua", "get_dw_jinjie_effect_details",id)
end

function human:features_effect_notify_client(id,objid)
    return skynet.call(self.obj_address, "lua", "features_effect_notify_client",id,objid)
end

function human:get_game_flag_key(key)
    return skynet.call(self.obj_address, "lua", "get_game_flag_key",key)
end

function human:set_game_flag_key(key,value)
    return skynet.send(self.obj_address, "lua", "set_game_flag_key",key,value)
end

function human:get_game_flag_keys(key)
    return skynet.call(self.obj_address, "lua", "get_game_flag_keys",key)
end

function human:set_game_flag_keys(values)
    return skynet.send(self.obj_address, "lua", "set_game_flag_keys",values)
end

function human:set_game_flag_keys_visual(eq_point,value)
    return skynet.call(self.obj_address, "lua", "set_game_flag_keys_visual",eq_point,value)
end

function human:get_game_flag_keys_visual(eq_point)
    -- [audit 2026-09-03] send luon tra nil -> ngoai hinh trang bi nil; phai call
    return skynet.call(self.obj_address, "lua", "get_game_flag_keys_visual",eq_point)
end

function human:del_limit_shop(shopid)
    skynet.send(self.obj_address, "lua", "del_limit_shop",shopid)
end
function human:reset_limit_shop(shopid,ntime)
    skynet.send(self.obj_address, "lua", "reset_limit_shop",shopid,ntime)
end
function human:get_limit_shop_buy_count(shopid,itemid)
    return skynet.call(self.obj_address, "lua", "get_limit_shop_buy_count",shopid,itemid)
end
function human:set_limit_shop_buy_count(shopid,itemid,buy_num)
    skynet.send(self.obj_address, "lua", "get_limit_shop_buy_count",shopid,itemid,buy_num)
end


return human
