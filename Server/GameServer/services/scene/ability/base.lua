local define = require "define"
local class = require "class"
local packet_def = require "game.packet"
local human_item_logic = require "human_item_logic"
local base = class("base")

function base:get_id() return self.id end
function base:set_id(id) self.id = id end
function base:get_name() return self.name end
function base:set_name(name) self.name = name end
function base:get_level_demand() return self.level_demand end
function base:set_level_demand(demand) self.level_demand = demand end
function base:get_level_limit() return self.level_limit end
function base:set_level_limit(limit) self.level_limit = limit end
function base:get_operation_tool_id_1() return self.operation_tool_id_1 end
function base:set_operation_tool_id_1(id) self.operation_tool_id_1 = id end
function base:get_operation_tool_id_2() return self.operation_tool_id_2 end
function base:set_operation_tool_id_2(id) self.operation_tool_id_2 = id end
function base:get_operation_platform_id() return self.operation_platform_id end
function base:set_operation_platform_id(id) self.operation_platform_id = id end
function base:get_platform_distance() return self.platforn_distance end
function base:set_platform_distance(d) self.platforn_distance = d end
function base:get_operation_action_id() return self.operation_action_id end
function base:set_operation_action_id(id) self.operation_action_id = id end
function base:set_ability_enginer(ae) self.abilityenginer = ae end

function base:ctor(c)
    self.DEF_ABILITY_CHECK = "AbilityCheck"
    self.DEF_ABILITY_CONSUME = "AbilityConsume"
    self.DEF_ABILITY_GAIN_EXPERIENCE = "GainExperience"
    self.DEF_ABILITY_SUCCESSFUL_CHECK = "CheckForResult"
    self.DEF_ABILITY_PRODUCE = "AbilityProduce"
    self.DEF_ABILITY_CALC_QUALITY = "CalcQuality"
    self.ABILITY_LOGIC_SCRIPT = 701601
    self.MAX_PRESCRIPTION_STUFF = 5
    self:set_id(c["ID"])
    self:set_name(c["名称$1$"])
    self:set_level_demand(c["所需等级"])
    self:set_operation_platform_id(c["辅助平台ID"])
    self:set_operation_tool_id_1(c["工具ID"])
    self:set_operation_tool_id_2(c["工具ID2"])
    self:set_platform_distance(c["辅助平台的有效距离"])
    self:set_operation_action_id(c["操作动作ID"])
end

function base:can_use_ability(human)
    local ability_opera = human:get_ability_opera()
    local ability_id = ability_opera.ability_id
    if human:get_ability(ability_id) == nil then
        return define.OPERATE_RESULT.OR_WARNING
    end
    local operation_tool_id_1 = self:get_operation_tool_id_1()
    local operation_tool_id_2 = self:get_operation_tool_id_2()
    local operation_tool_id_1_err = false
    if operation_tool_id_1 ~= define.INVAILD_ID then
        operation_tool_id_1_err = human_item_logic:calc_equip_item_count(human, operation_tool_id_1) < 1
    end
    local operation_tool_id_2_err = false
    if operation_tool_id_2 ~= define.INVAILD_ID then
        operation_tool_id_2_err = human_item_logic:calc_equip_item_count(human, operation_tool_id_2) < 1
    end
    if (operation_tool_id_1 ~= define.INVAILD_ID or operation_tool_id_2 ~= define.INVAILD_ID)
        and (operation_tool_id_1 == define.INVAILD_ID or operation_tool_id_1_err)
        and (operation_tool_id_2 == define.INVAILD_ID or operation_tool_id_2_err) then
        return define.OPERATE_RESULT.OR_NO_TOOL
    end
    local obj = human:get_scene():get_obj_by_id(ability_opera.obj)
    if obj then
    end
    return define.OPERATE_RESULT.OR_OK
end

function base:on_proc_interrupt(human)
    human:get_ai():push_command_idle()
    local ability_opera = human:get_ability_opera()
    local msg = packet_def.GCAbilityAction.new()
    msg.m_objID = human:get_obj_id()
    msg.ability = ability_opera.ability_id
    msg.logic_count = human:get_logic_count()
    msg.prescription = ability_opera.pres_id
    msg.target_obj_id = ability_opera.obj
    msg.begin_or_end = 0
    human:get_scene():send2client(human, msg)

    msg = packet_def.GCAbilityResult.new()
    msg.ability = ability_opera.ability_id
    msg.prescription = ability_opera.pres_id
    msg.result = define.OPERATE_RESULT.OR_FAILURE
    assert(msg.result)
    human:get_scene():send2client(human, msg)

    human:stop_character_logic(true)
end

function base:on_proc_over()

end

return base
