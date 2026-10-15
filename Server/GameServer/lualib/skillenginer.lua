local skynet = require "skynet"
local packet_def = require "game.packet"
local class = require "class"
local define = require "define"
local configenginer = require "configenginer":getinstance()
local skillenginer = class("skillenginer")
local c_skill_info = require "skillinfo"

function skillenginer:getinstance()
    if skillenginer.instance == nil then
        skillenginer.instance = skillenginer.new()
    end
    return skillenginer.instance
end

function skillenginer:ctor()
    self.skill_logics = {}
    self.exterior_ride_config = {}
    self.xinfa_orders = {}
    self.skill_orders = {}
end

function skillenginer:set_scene(scene)
    self.scene = scene
end

function skillenginer:loadall()
    if self.loaded_all then return end
    self.loaded_all = true
    -- print("skillenginer:loadall")
    self.skill_template_conf = configenginer:get_config("skill_template")
    self.skill_data_conf = configenginer:get_config("skill_data")
    self:register_all_skill_logics()
    self:init_exterior_ride_config()
    self:init_xinfa_orders()
    self:init_skill_orders()
end

function skillenginer:init_xinfa_orders()
    local xinfa_v1 = configenginer:get_config("xinfa_v1")
    local menpais = {}
    for id, xinfa in pairs(xinfa_v1) do
        menpais[xinfa.menpai] = menpais[xinfa.menpai] or {}
        table.insert(menpais[xinfa.menpai], id)
    end
    for _, xinfas in pairs(menpais) do
        table.sort(xinfas, function(x1, x2) return x1 < x2 end)
        for order, xinfa in ipairs(xinfas) do
            self.xinfa_orders[xinfa] = order
        end
    end
end

function skillenginer:init_skill_orders()
    local templates = configenginer:get_config("skill_template")
    local xinfa_skills = {}
    for id, template in pairs(templates) do
        local xinfa = template.xinfa
        if xinfa ~= define.INVAILD_ID then
            xinfa_skills[xinfa] = xinfa_skills[xinfa] or {}
            table.insert(xinfa_skills[xinfa], id)
        end
    end
    for xinfa, skills in pairs(xinfa_skills) do
        table.sort(skills, function(s1, s2) return s1 < s2 end)
        for order, skill in ipairs(skills) do
            self.skill_orders[skill] = order
        end
    end
end

function skillenginer:get_xinfa_order(xinfa)
    return self.xinfa_orders[xinfa]
end

function skillenginer:get_skill_order(skill)
    return self.skill_orders[skill]
end

function skillenginer:get_skill_xinfa_order(skill)
    -- print("skill =", skill)
    local template = self:get_skill_template(skill)
    assert(template.xinfa ~= define.INVAILD_ID, skill)
    return self:get_xinfa_order(template.xinfa)
end

function skillenginer:get_skill_xinfa(skill)
    -- print("skill =", skill)
    local template = self:get_skill_template(skill)
    return template.xinfa
end

function skillenginer:init_exterior_ride_config()
    local list = configenginer:get_config("exterior_ride")
    for _, conf in pairs(list) do
        if conf.id then
            self.exterior_ride_config[conf.id] = conf
        end
    end
end

function skillenginer:get_skill_template(id,key)
    -- skynet.logi("get_skill_template id =", id,"key =", key)
    local templates = self.skill_template_conf
	if not key then
		return templates[id]
	else
		if templates[id] then
			return templates[id][key]
		end
	end
end

function skillenginer:get_skill_templates()
    return self.skill_template_conf
end

function skillenginer:get_exterior_ride_config(id)
    return self.exterior_ride_config[id]
end

function skillenginer:activated_item(obj_me)
    local params = obj_me:get_targeting_and_depleting_params()
    local skill_info = self:instance_skill(obj_me, params:get_activated_skill(), params:get_skill_level())
    -- print("skill_info =", skill_info)
    if not skill_info then
        params:set_errcode(define.OPERATE_RESULT.OR_INVALID_SKILL)
        params:set_errparam(params:get_activated_skill())
        return false
    end
    local bag_index = params:get_bag_index_of_deplted_item()
    local item = obj_me:get_prop_bag_container():get_item(bag_index)
    if not item then
		-- skynet.logi("activated_item bag_index = ",bag_index)
        params:set_errcode(define.OPERATE_RESULT.OR_WARNING)
        return false
    end
    local base_config = item:get_base_config()
    if obj_me:get_level() < base_config.level then
        params:set_errcode(define.OPERATE_RESULT.OR_NO_LEVEL)
        obj_me:notify_tips("等级不足")
        return false
    end
    obj_me:refix_skill(skill_info)
    local logic = self:get_script_logic()
    local stype = skill_info:get_skill_type()
    if stype == define.ENUM_SKILL_TYPE.SKILL_TYPE_LAUNCH then
		-- skynet.logi("activated_item start_launching stype = ",stype)
        logic:start_launching(obj_me)
    elseif stype == define.ENUM_SKILL_TYPE.SKILL_TYPE_GATHER then
		-- skynet.logi("activated_item start_charging stype = ",stype)
        logic:start_charging(obj_me)
    elseif stype == define.ENUM_SKILL_TYPE.SKILL_TYPE_LEAD then
		-- skynet.logi("activated_item start_channeling stype = ",stype)
        logic:start_channeling(obj_me)
    end
    return true
end

function skillenginer:activated_monster(obj_me)
    local params = obj_me:get_targeting_and_depleting_params()
    local skill_info = self:instance_skill(obj_me, params:get_activated_skill(), params:get_skill_level())
    -- print("skill_info =", skill_info)
    if not skill_info then
        params:set_errcode(define.OPERATE_RESULT.OR_INVALID_SKILL)
        params:set_errparam(params:get_activated_skill())
        return false
    end
    obj_me:refix_skill(skill_info)
    if params:get_active_time() > 0 then
        skill_info.charge_time = params:get_active_time()
    end
    local logic = self:get_active_monster_logic()
    local stype = skill_info:get_skill_type()
    if stype == define.ENUM_SKILL_TYPE.SKILL_TYPE_LAUNCH then
		-- skynet.logi("activated_monster start_launching stype = ",stype)
        logic:start_launching(obj_me)
    elseif stype == define.ENUM_SKILL_TYPE.SKILL_TYPE_GATHER then
		-- skynet.logi("activated_monster start_charging stype = ",stype)
        logic:start_charging(obj_me)
    elseif stype == define.ENUM_SKILL_TYPE.SKILL_TYPE_LEAD then
		-- skynet.logi("activated_monster start_channeling stype = ",stype)
        logic:start_channeling(obj_me)
    end
    return true
end

function skillenginer:taget_loigc_condition_check(obj_me, obj_tar, template)
    local condition_ok = false
    local target_logic_by_stand = template.target_logic_by_stand
    target_logic_by_stand = target_logic_by_stand or define.INVAILD_ID
    if target_logic_by_stand == define.INVAILD_ID then
        condition_ok = true
    elseif (target_logic_by_stand == 0 and obj_me:is_friend(obj_tar)) then
        condition_ok = true
    elseif (target_logic_by_stand == 1 and obj_me:is_enemy(obj_tar))  then
        condition_ok = true
    elseif (target_logic_by_stand == 2 and obj_me:is_teammate(obj_tar))  then
        condition_ok = true
    end
    return condition_ok
end

function skillenginer:process_skill_request(obj_me, skill_id, level, id_tar, pos_tar, dir_tar, guid_tar, script_arg_1, script_arg_2, script_arg_3,charge_time)
    if not require('cys_dual_souls').authorized(obj_me,skill_id) then return false end
	local params = obj_me:get_targeting_and_depleting_params()
    if obj_me.talent_refix_skill_id then
        skill_id = obj_me:talent_refix_skill_id(skill_id)
    end
    local template = self:get_skill_template(skill_id)
    if not template then
        
        params:set_errcode(define.OPERATE_RESULT.OR_INVALID_SKILL)
        return false
    end
    if skill_id == -1 then
        params:set_errcode(define.OPERATE_RESULT.OR_OK)
        return true
    end
    if not obj_me:is_alive() then
        params:set_errcode(define.OPERATE_RESULT.OR_DIE);
        return false
    end
    if not obj_me:can_use_this_skill_in_this_status(skill_id) then
        params:set_errcode(define.OPERATE_RESULT.OR_LIMIT_USE_SKILL)
        return false
    end
	local ignore_condition_check_flag = params:get_ignore_condition_check_flag()
    if obj_me:get_obj_type() == "human" then
		if template.use_need_learnd
		and not ignore_condition_check_flag
		and not obj_me:have_skill(skill_id) then
            params:set_errcode(define.OPERATE_RESULT.OR_NEED_LEARN_SKILL_FIRST)
            return false
        end
    end
    -- Authored school skill unlocks remain enforced for old saved skill lists.
    if obj_me:get_obj_type() == "human" and not ignore_condition_check_flag
        and template.use_need_learnd and (template.xinfa or -1) >= 0 then
        local xinfa = obj_me:get_xinfa(template.xinfa)
        if not xinfa or xinfa.m_nXinFaLevel < (template.xinfa_level_require or 0) then
            params:set_errcode(define.OPERATE_RESULT.OR_NEED_LEARN_SKILL_FIRST)
            return false
        end
    end
    if not obj_me:is_skill_cool_down(skill_id) and not ignore_condition_check_flag then
        params:set_errcode(define.OPERATE_RESULT.OR_COOL_DOWNING)
        return false
    end
    if not self.scene:get_action_enginer():can_do_next_action(obj_me) then
        params:set_errcode(define.OPERATE_RESULT.OR_BUSY)
        return false
    end
    if template.skill_classs == -1 and template.menpai == -1 then
        level = 1
    end
    local targeting_logic = template.targeting_logic
    local is_single_skill = targeting_logic == define.ENUM_TARGET_LOGIC.TARGET_SPECIFIC_UNIT
    if is_single_skill then
        local obj_tar = self.scene:get_obj_by_id(id_tar)
        if obj_tar and not self:taget_loigc_condition_check(obj_me, obj_tar, template) then
            params:set_errcode(define.OPERATE_RESULT.OR_WARNING)
            return false
        end
    end
    params:set_activated_script(define.INVAILD_ID)
    params:set_activated_skill(skill_id)
    params:set_skill_level(level)
    params:set_target_obj(id_tar)
    params:set_target_position(pos_tar)
    params:set_target_dir(dir_tar)
    params:set_target_guid(guid_tar)
    params:set_script_arg_1(script_arg_1)
    params:set_script_arg_2(script_arg_2)
    params:set_script_arg_3(script_arg_3)
    local ret = self:active_skill_now(obj_me,charge_time)
    if not ret then
        self:on_exception(obj_me)
    end
    return ret
end

function skillenginer:active_skill_now(obj_me,charge_time)
    local params = obj_me:get_targeting_and_depleting_params()
    local skill_id = params:get_activated_skill()
    local skill_info = self:instance_skill(obj_me, skill_id, params:get_skill_level())
    if not skill_info then
        params:set_errcode(define.OPERATE_RESULT.OR_INVALID_SKILL)
        params:set_errparam(skill_id)
        return false
    end
	if charge_time then
		skill_info:set_charge_time(charge_time)
	end
	obj_me:refix_skill(skill_info)
    local logic_id = skill_info:get_logic_id()
    local logic = self:get_logic_by_id(logic_id)
    if logic == nil then
        params:set_errcode(define.OPERATE_RESULT.OR_INVALID_SKILL)
        params:set_errparam(skill_id)
        return false
    end
    if logic:cancel_skill_effect() then
        params:set_errcode(define.OPERATE_RESULT.OR_OK)
        return true
    end
    if logic:is_passive() then
        params:set_errcode(define.OPERATE_RESULT.OR_ERROR)
        return false
    end
    if not obj_me:is_skill_cool_down(skill_id) and not params:get_ignore_condition_check_flag() then
        params:set_errcode(define.OPERATE_RESULT.OR_COOL_DOWNING)
        return false
    end
    local flag = skill_info:get_need_weapon_flag()
    if flag == 1 then
        local otype = obj_me:get_obj_type()
        if otype == "human" then
            local equip = obj_me:get_equip(define.HUMAN_EQUIP.HEQUIP_WEAPON)
            local shenbing = obj_me:get_equip(define.HUMAN_EQUIP.SHENBING)
            if not equip and not shenbing then
                params:set_errcode(define.OPERATE_RESULT.OR_NEED_A_WEAPON)
                return false
            end
        end
    end
    if not params:get_ignore_condition_check_flag() then
        if not logic:is_condition_satisfied(obj_me) then
            return false
        end
        if not logic:speical_operation_on_skill_start(obj_me) then
            return false
        end
    end
    local stype = skill_info:get_skill_type()
    if stype == define.ENUM_SKILL_TYPE.SKILL_TYPE_LAUNCH then
        local ret = logic:start_launching(obj_me)
        return ret
    elseif stype == define.ENUM_SKILL_TYPE.SKILL_TYPE_GATHER then
        return logic:start_charging(obj_me)
    elseif stype == define.ENUM_SKILL_TYPE.SKILL_TYPE_LEAD then
        return logic:start_channeling(obj_me)
    else
        return false
    end
end

function skillenginer:get_logic_by_id(id)
    return  self.skill_logics[id]
end

function skillenginer:get_script_logic()
    return self.skill_logics.script
end

function skillenginer:get_active_monster_logic()
    return self.skill_logics.active_monster
end

function skillenginer:get_logic(skill_info)
    local logic_id = skill_info:get_logic_id()
    return self:get_logic_by_id(logic_id)
end

function skillenginer:instance_skill(obj_me, skill_id, level)
    local bridge = self.cy_four_bridge
    if bridge and not require("cy_four_combat.availability").allowed(obj_me,skill_id,bridge.config) then
        return nil
    end
    local params = obj_me:get_targeting_and_depleting_params()
    local template = self:get_skill_template(skill_id)
    if level == 0 or level > define.MAX_CHAR_SKILL_LEVEL then
        level = define.MAX_CHAR_SKILL_LEVEL
    end
    params:set_skill_level(level)
    if template then
        local skill_info_id = self:get_skill_info_id_by_level(template, level)
        local info = self:get_skill_info(skill_info_id)
        local skill_info = c_skill_info.new(template, info, level)
        return skill_info
    end
end

function skillenginer:get_skill_logic_id(skill_id, level)
    local template = self:get_skill_template(skill_id)
    if level == 0 or level > define.MAX_CHAR_SKILL_LEVEL then
        level = 1
    end
    local skill_info_id = self:get_skill_info_id_by_level(template, level)
    local info = self:get_skill_info(skill_info_id)
    return info.logic_id
end

function skillenginer:is_skill_in_collection(skill_id, collection_id)
    if collection_id == define.INVAILD_ID then
        return false
    end
    local collections_config = configenginer:get_config("id_collections")
    local conf = collections_config[collection_id]
    assert(conf, collection_id)
    if skill_id ~= define.INVAILD_ID then
        return conf.ids[skill_id]
    end
    return false
end

function skillenginer:get_skill_info_id_by_level(template, level)
    return template.level_skills[level]
end

function skillenginer:get_skill_info(id,index)
	if not index then
		return self.skill_data_conf[id]
	else
		return self.skill_data_conf[id][index]
	end
end

skillenginer.id_logic_module = {
    script = "scene.skill.human.script",
    active_monster = "scene.skill.human.active_monster",
    [0] = "scene.skill.human.skill_0",
    [1] = "scene.skill.human.skill_1",
    [2] = "scene.skill.human.skill_2",
    [3] = "scene.skill.human.skill_3",
    [4] = "scene.skill.human.skill_4",
    [5] = "scene.skill.human.skill_5",
    [8] = "scene.skill.human.armor_mastery",
    [9] = "scene.skill.human.weapon_mastery",
    [10] = "scene.skill.human.skill_10",
    [11] = "scene.skill.human.skill_11",
    [14] = "scene.skill.human.skill_14",
    [15] = "scene.skill.human.skill_15",
    [16] = "scene.skill.human.skill_16",
    [17] = "scene.skill.human.skill_17",
    [52] = "scene.skill.human.skill_52",
    [80] = "scene.skill.human.skill_80",
    [81] = "scene.skill.human.skill_81",
    [82] = "scene.skill.human.skill_82",
    [141] = "scene.skill.human.skill_141",
    [201] = "scene.skill.human.skill_201",
    [231] = "scene.skill.human.skill_231",
    [260] = "scene.skill.human.skill_260",
    [261] = "scene.skill.human.skill_261",
    [290] = "scene.skill.pet.skill_290",
    [291] = "scene.skill.pet.skill_291",
    [292] = "scene.skill.pet.skill_292",
    [293] = "scene.skill.pet.skill_293",
    [294] = "scene.skill.pet.skill_294",
    [441] = "scene.skill.human.skill_441",
    [642] = "scene.skill.human.skill_642",
    [670] = "scene.skill.human.skill_670",
    [671] = "scene.skill.human.skill_671",
    [689] = "scene.skill.human.skill_689",
    [690] = "scene.skill.human.skill_690",
    [699] = "scene.skill.human.skill_699",
    [700] = "scene.skill.human.skill_700",
    [701] = "scene.skill.human.skill_701",
    [702] = "scene.skill.human.skill_702",
    [703] = "scene.skill.human.skill_703",
    [704] = "scene.skill.human.skill_704",
    [705] = "scene.skill.human.skill_705",
    [706] = "scene.skill.human.skill_706",
    [707] = "scene.skill.human.skill_707",
    [708] = "scene.skill.human.skill_708",
    [709] = "scene.skill.human.skill_709",
    [710] = "scene.skill.human.skill_710",
    [711] = "scene.skill.human.skill_711",
    [712] = "scene.skill.human.skill_712",
    [713] = "scene.skill.human.skill_713",
    [714] = "scene.skill.human.skill_714",
    [715] = "scene.skill.human.skill_715",
    [716] = "scene.skill.human.skill_716",
    [717] = "scene.skill.human.skill_717",
    [718] = "scene.skill.human.skill_718",
    [750] = "scene.skill.human.skill_750",
    [751] = "scene.skill.human.skill_751",
    [72] = "scene.skill.human.skill_72",
    [73] = "scene.skill.human.skill_73",
    [691] = "scene.skill.human.skill_73",
    [745] = "scene.skill.human.skill_751",
    [746] = "scene.skill.human.skill_73",
    [752] = "scene.skill.human.skill_73",
    [269] = "scene.skill.human.skill_269", -- [FIX] 断臂渡生技能5386护盾链路
    [734] = "scene.skill.pet.skill_734",
    [840] = "scene.skill.human.skill_840", -- 荡千军 Dang Thien Quan: tu thuan di roi danh vung
    [5100] = "scene.skill.human.skill_5100",
    [6] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [12] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [18] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [77] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [111] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [142] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [143] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [144] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [145] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [146] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [147] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [148] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [149] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [170] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [171] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [172] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [173] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [174] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [175] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [176] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [177] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [178] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [179] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [202] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [204] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [205] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [206] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [208] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [262] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [400] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [643] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [644] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [648] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [649] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [672] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [730] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [731] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [732] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [736] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [760] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [761] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [762] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [763] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [764] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [765] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [767] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [768] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [769] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [770] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [791] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [792] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [793] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [794] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [795] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [797] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [799] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [800] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [801] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [802] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [803] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [835] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [836] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [837] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [838] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [841] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [842] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [862] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [864] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [865] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [866] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [867] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [868] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [869] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [870] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [882] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [883] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [884] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [885] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [886] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [887] = "scene.skill.human.skill_cy_spec", -- skill-logic
    [901] = "scene.skill.human.skill_cy_spec", -- skill-logic
}

function skillenginer:register_all_skill_logics()
    require("cy_four_combat.bootstrap").bind_skills(self)
    --print("skillenginer:register_all_skill_logics self.infos =", table.tostr(self.infos))
    local base_skill = require "scene.skill.base"
    local default_skill = require "scene.skill.human.skill_0"
    local skill_data = configenginer:get_config("skill_data")
    for _, skill in pairs(skill_data) do
        assert(skill.logic_id < 8000 or self.skill_logics[skill.logic_id], "CY skill logic not configured: "..skill.logic_id)
        if self.skill_logics[skill.logic_id] == nil then
            print("注册技能逻辑 id =", skill.id, ";逻辑id =", skill.logic_id)
            local module = self.id_logic_module[skill.logic_id]
            if module then
                local ok, mod = pcall(require, module)
                if not ok then
                    print("[skillenginer] require失败 logic_id =", skill.logic_id, "; module =", module, "; err =", mod)
                    mod = base_skill
                elseif type(mod) ~= "table" then
                    print("[skillenginer] 模块返回类型异常 logic_id =", skill.logic_id, "; module =", module, "; type =", type(mod))
                    mod = base_skill
                end
                self.skill_logics[skill.logic_id] = mod.new()
            else
                -- server-impact: skill_0 + nhãn impact CY mà cfghelper không nhận
                self.skill_logics[skill.logic_id] = require("scene.skill.human.skill_cy_generic").new()
            end
        end
    end
    self.skill_logics.script = require(self.id_logic_module.script).new()
    self.skill_logics.active_monster = require (self.id_logic_module.active_monster).new()
    local count = 0
    for key in pairs(self.skill_logics) do
        count = count + 1
    end
    print("技能逻辑共有", count, "个")
end

function skillenginer:on_exception(obj)

end

return skillenginer
