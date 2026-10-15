local class = require "class"
local define = require "define"
local packet_def = require "game.packet"
local human_item_logic = require "human_item_logic"
local item_class = require "item"
local configenginer = require "configenginer":getinstance()
local scriptenginer = require "scriptenginer":getinstance()
local base = require "scene.ability.base"
local compound = class("compound", base)

function compound:can_use_ability(human)

    local recipes = require 'cys_recipe'
    if not recipes.available(self,human) then return define.OPERATE_RESULT.OR_WARNING end
    if recipes.ordinary(self,human) then
        local result = self.super.can_use_ability(self,human)
        if result ~= define.OPERATE_RESULT.OR_OK then return result end
        return recipes.check(self,human)
    end
    local res = self.super.can_use_ability(self, human)
    if res ~= define.OPERATE_RESULT.OR_OK then
        return res
    end
    local ability_opera = human:get_ability_opera()
    local prescription_list = self.abilityenginer:get_prescription_list()
    if ability_opera.pres_id >= 0 and prescription_list[ability_opera.pres_id] ~= nil then
        local prescription = prescription_list[ability_opera.pres_id]
        if prescription["对应技能ID"] ~= self.id then
            return define.OPERATE_RESULT.OR_WARNING
        end
        local have_learnd = human:is_prescription_have_learnd(ability_opera.pres_id)
        print("have_learnd =", have_learnd)
        if not have_learnd then
            return define.OPERATE_RESULT.OR_WARNING
        end
        print("prescription[\"操作时间\"] =", prescription["操作时间"])
        if prescription["操作时间"] > 0 then
            ability_opera.max_time = prescription["操作时间"]
        end
        local script_id = prescription["脚本ID"]
        if script_id ~= define.INVAILD_ID then
            return scriptenginer:call(script_id, self.DEF_ABILITY_CHECK, human:get_obj_id())
        else
            return self:is_fit_prescr(human, prescription)
        end
    end
    return define.OPERATE_RESULT.OR_WARNING
end

function compound:is_fit_prescr(human, prescription)
    assert(human)
    assert(prescription)
    local tool_id = prescription["需求工具ID"]
    if tool_id ~= define.INVAILD_ID then
        if human_item_logic:calc_bag_item_count(human, tool_id) < 1 then
            return define.OPERATE_RESULT.OR_NO_TOOL
        end
    end
    local exp_demand = prescription["熟练度需求"]
    local ability = human:get_ability(self.id)
    if exp_demand > ability.exp then
        return define.OPERATE_RESULT.OR_EXP_LACK
    end
    local cool_down_id = prescription["冷却组ID"]
    if cool_down_id > 0 then
        if not human:is_cool_downed(cool_down_id) then
            return define.OPERATE_RESULT.OR_COOL_DOWNING
        end
    end
    local result_id = prescription["ResultID"]
    local result_num = prescription["ResultNum"]
    if not human_item_logic:calc_item_space(human, result_id, result_num) then
        return define.OPERATE_RESULT.OR_BAG_OUT_OF_SPACE
    end
    local ability_id = prescription["对应技能ID"]
    local compound_mat_item_indexs = define.COMPOUND_MAT_ITEM_INDEX[ability_id]
    if compound_mat_item_indexs then
        local ability_opera = human:get_ability_opera()
        local mat_bag_index = ability_opera.mat_bag_index
        local item = human:get_prop_bag_container():get_item(mat_bag_index)
        if item == nil then
            return define.OPERATE_RESULT.OR_ERROR
        end
        if compound_mat_item_indexs[item:get_index()] == nil then
            return define.OPERATE_RESULT.OR_ERROR
        end
    else
        for i = 1, self.MAX_PRESCRIPTION_STUFF do
            local key = string.format("Stuff%dID", i)
            local id = prescription[key]
            key = string.format("Stuff%dnum", i)
            local num = prescription[key]
            if id ~= define.INVAILD_ID then
                local item_count = human_item_logic:calc_bag_item_count(human, id)
                if item_count < num then
                    return define.OPERATE_RESULT.OR_STUFF_LACK
                end
            end
        end
    end
    return define.OPERATE_RESULT.OR_OK
end

function compound:on_proc_over(human)
    local recipes = require 'cys_recipe'
    if recipes.ordinary(self,human) then return recipes.finish(self,human,'compound') end
    local ability_opera = human:get_ability_opera()
    local prescription_list = self.abilityenginer:get_prescription_list()
    if ability_opera.pres_id <= 0 then
        print(1)
        return define.OPERATE_RESULT.OR_ERROR
    end
    local prescription = prescription_list[ability_opera.pres_id]
    if prescription == nil then
        print(2)
        return define.OPERATE_RESULT.OR_ERROR
    end
    local bind = false
    local script_id = prescription["脚本ID"]
    if script_id > 0 then
        local res = scriptenginer:call(script_id, self.DEF_ABILITY_CHECK, human:get_obj_id())
        if res ~= define.OPERATE_RESULT.OR_OK then
            print(3)
            return res
        end
        scriptenginer:call(script_id, self.DEF_ABILITY_CONSUME, human:get_obj_id(), ability_opera.pres_id, prescription)
	else
        local res = self:is_fit_prescr(human, prescription)
        if res ~= define.OPERATE_RESULT.OR_OK then
            print(4)
            return res
        end
        bind = self:ability_consume(human, prescription)
    end
    local ability_id = prescription["对应技能ID"]
    local ability_level = prescription["技能等级需求（此列最低填1）"]
    scriptenginer:call(self.ABILITY_LOGIC_SCRIPT, self.DEF_ABILITY_GAIN_EXPERIENCE, human:get_obj_id(), ability_id, ability_level)
    local res = scriptenginer:call(self.ABILITY_LOGIC_SCRIPT, self.DEF_ABILITY_SUCCESSFUL_CHECK, human:get_obj_id(), ability_id, ability_level)
    if res == define.OPERATE_RESULT.OR_FAILURE then
        print(5)
        return self:on_proc_failure(human, prescription)
    end
    if script_id ~= define.INVAILD_ID then
        print(6)
        return scriptenginer:call(script_id, self.DEF_ABILITY_PRODUCE, human:get_obj_id(), ability_opera.pres_id, prescription)
    else
        print(7)
        return self:on_proc_success(human, prescription, bind)
    end
end

function compound:ability_consume(human, prescription)
    local logparam = {}
    for i = 1, self.MAX_PRESCRIPTION_STUFF do
        local key = string.format("Stuff%dID", i)
        local id = prescription[key]
        key = string.format("Stuff%dnum", i)
        local num = prescription[key]
        if id ~= define.INVAILD_ID then
            human_item_logic:erase_material_item(logparam, human, id, num)
        end
    end
    logparam = {}
    local ability_opera = human:get_ability_opera()
    local mat_bag_index = ability_opera.mat_bag_index
    local bind = false
    if mat_bag_index ~= 255 then
        local mat = human:get_prop_bag_container():get_item(mat_bag_index)
        assert(mat, mat_bag_index)
        ability_opera.mat_index = mat:get_index()
        local ret = human_item_logic:dec_item_lay_count(logparam, human, mat_bag_index, 1)
        assert(ret, string.format("合成失败， 原因扣除道具失败"))
        bind = mat:is_bind()
    end
    local cool_down_id = prescription["冷却组ID"]
    local cool_down_time = prescription["冷却时间(毫秒)"]
    if cool_down_id >= 0 and cool_down_time > 0 then
        human:set_cool_down(cool_down_id, cool_down_time)
    end
    return bind
end

function compound:on_proc_success(human, prescription, bind)
    local result_id = prescription["ResultID"]
    local result_num = prescription["ResultNum"]
    local ability_level = prescription["技能等级需求（此列最低填1）"]
    local ability_id = prescription["对应技能ID"]
    local ability = human:get_ability(ability_id)
    local level_limit = self:get_level_limit()
    local ability_opera = human:get_ability_opera()
    if result_num > 0 then
        local quality = scriptenginer:call(self.ABILITY_LOGIC_SCRIPT, self.DEF_ABILITY_CALC_QUALITY, ability_level, ability.level, level_limit, result_id)
        self:create_item_to_human(human, result_id, result_num, ability_opera.mat_index, quality, bind)
    end
    local msg = packet_def.GCAbilitySucc.new()
    msg.ability = ability_id
    msg.prescription = prescription["index"]
    msg.item_index = result_id
    msg.num = result_num
    human:get_scene():send2client(human, msg)
    return define.OPERATE_RESULT.OR_OK
end

function compound:create_item_to_human(human, item_index, item_count, mat_index, _, bind)
    assert(human)
    assert(item_index ~= define.INVAILD_ID)
    assert(item_count > 0)
    if item_count < 1 then
        return false
    end
    if item_index ~= define.INVAILD_ID then
        local logparam = {}
        local ret
        local way = 1
        local temp_item = item_class.new()
        temp_item:set_index(item_index)
        if temp_item:is_equip() then
            way = self:cal_way(item_index, mat_index)
        end
        if item_count > 1 then
            ret = human_item_logic:create_multi_item_to_bag(logparam, human, item_index, item_count, true)
        else
            local bag_index = human_item_logic:create_item_to_bag(logparam, human, item_index, bind, way)
            local item = human_item_logic:get_item(human, bag_index)
            if item:is_equip() then
                item:set_item_creator(human:get_name())
				item:set_item_record_data_forindex("artisanal",human:get_menpai())
            end
            local msg = packet_def.GCNotifyEquip.new()
            msg.bag_index = bag_index
            msg.item = item:copy_raw_data()
            human:get_scene():send2client(human, msg)

            msg = packet_def.GCItemInfo.new()
            msg.bagIndex = bag_index
            msg.item = item:copy_raw_data()
            human:get_scene():send2client(human, msg)
        end
        if ret then
        end
    end
    return true
end


function compound:cal_way(item_index, mat_index)
    local equip_base = configenginer:get_config("equip_base")
    local equip = equip_base[item_index]
    return  38 + equip.equip_point + 19 * (mat_index % 10) - 1 - 18
end


return compound
