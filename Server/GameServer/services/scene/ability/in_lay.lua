local class = require "class"
local define = require "define"
local packet_def = require "game.packet"
local human_item_logic = require "human_item_logic"
local scriptenginer = require "scriptenginer":getinstance()
local base = require "scene.ability.base"
local compound = class("compound", base)

function compound:can_use_ability(human)
    local res = self.super.can_use_ability(self, human)
    if res ~= define.OPERATE_RESULT.OR_OK then
        return res
    end
    local ability_opera = human:get_ability_opera()
    local prescription_list = self.abilityenginer:get_prescription_list()
    if ability_opera.pres_id > 0 and ability_opera.pres_id <= #prescription_list then
        local prescription = prescription_list[ability_opera.pres_id]
        if prescription.ability ~= self.id then
            return define.OPERATE_RESULT.OR_WARNING
        end
        if not human:is_prescription_have_learnd(ability_opera.pres_id) then
            return define.OPERATE_RESULT.OR_WARNING
        end
        if prescription["操作时间"] > 0 then
            ability_opera.max_time = prescription["操作时间"]
        end
        local script_id = prescription["脚本ID"]
        if script_id ~= define.INVAILD_ID then
            scriptenginer:call(script_id, self.DEF_ABILITY_CHECK, human:get_obj_id())
        else
            self:is_fit_prescr(human, prescription)
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
    return define.OPERATE_RESULT.OR_OK
end

function compound:on_proc_over(human)
    local ability_opera = human:get_ability_opera()
    local prescription_list = self.abilityenginer:get_prescription_list()
    if ability_opera.pres_id <= 0 then
        return define.OPERATE_RESULT.OR_ERROR
    end
    local prescription = prescription_list[ability_opera.pres_id]
    if prescription == nil then
        return define.OPERATE_RESULT.OR_ERROR 
    end
    local script_id = prescription["脚本ID"]
    if script_id > 0 then
        local res = scriptenginer:call(script_id, self.DEF_ABILITY_CHECK, human:get_obj_id())
        if res ~= define.OPERATE_RESULT.OR_OK then
            return res
        end
        scriptenginer:call(script_id, self.DEF_ABILITY_CONSUME, human:get_obj_id())
    else
        local res = self:is_fit_prescr(human)
        if res ~= define.OPERATE_RESULT.OR_OK then
            return res
        end
        self:ability_consume(human, prescription)
    end
    local ability_id = prescription["对应技能ID"]
    local ability_level = prescription["技能等级需求（此列最低填1）"]
    scriptenginer:call(self.ABILITY_LOGIC_SCRIPT, self.DEF_ABILITY_GAIN_EXPERIENCE, human:get_obj_id(), ability_id, ability_level)
    local res = scriptenginer:call(self.ABILITY_LOGIC_SCRIPT, self.DEF_ABILITY_SUCCESSFUL_CHECK, human:get_obj_id(), ability_id, ability_level)
    if res == define.OPERATE_RESULT.OR_FAILURE then
        return self:on_proc_failure(human, prescription)
    end
    if script_id ~= define.INVAILD_ID then
        return scriptenginer:call(script_id, self.DEF_ABILITY_PRODUCE, human:get_obj_id())
    else
        return self:on_proc_success(human, prescription)
    end
end

function compound:ability_consume(human, prescription)
    for i = 1, self.MAX_PRESCRIPTION_STUFF do
        local key = string.format("Stuff%dID", i)
        local id = prescription[key]
        key = string.format("Stuff%dnum", i)
        local num = prescription[key]
        if id ~= define.INVAILD_ID then
            local logparam = {}
            human_item_logic:erase_item(logparam, human, id, num)
        end
    end
    local cool_down_id = prescription["冷却组ID"]
    local cool_down_time = prescription["冷却时间(毫秒)"]
    if cool_down_id >= 0 and cool_down_time > 0 then
        human:set_cool_down(cool_down_id, cool_down_time)
    end
end

function compound:on_proc_success(human, prescription)
    local result_id = prescription["ResultID"]
    local result_num = prescription["ResultNum"]
    local ability_level = prescription["技能等级需求（此列最低填1）"]
    local ability_id = prescription["对应技能ID"]
    local ability = human:get_ability(ability_id)
    local level_limit = self:ability_level_limit()
    if result_num > 0 then
        local quality = scriptenginer:call(self.ABILITY_LOGIC_SCRIPT, self.DEF_ABILITY_CALC_QUALITY, ability_level, ability.level, level_limit)
        self:create_item_to_human(human, result_id, result_num, quality)
    end
    local msg = packet_def.GCAbilitySucc.new()
    msg.ability_id = ability_id
    msg.prescription_id = prescription["index"]
    msg.item_index = result_id
    human:get_scene():send2client(human, msg)
end

function compound:create_item_to_human(human, item_index, item_count, quality)
    assert(human)
    assert(item_index ~= define.INVAILD_ID)
    assert(item_count > 0)
    if item_count < 1 then
        return false
    end
    if item_index ~= define.INVAILD_ID then
        local logparam = {}
        local ret
        if item_count > 1 then
            ret = human_item_logic:create_item_to_human(logparam, human, item_index, item_count, 0)
        else
            local bag_index
            ret, bag_index = human_item_logic:create_item_to_bag(logparam, human, item_index, quality)
            local item = human_item_logic:get_item(human, bag_index)
            if item:is_equip() then
                item:set_item_creator(human:get_name())
				item:set_item_record_data_forindex("artisanal",human:get_menpai())
            end
            local msg = packet_def.GCNotifyEquip.new()
            msg.bagIndex = bag_index
            msg.item = item:copy_raw_data()
            human:get_scene():send2client(human, msg)
        end
        if ret then
        end
    end
    return true
end

return compound
