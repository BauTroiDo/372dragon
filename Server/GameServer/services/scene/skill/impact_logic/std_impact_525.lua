local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_525 = class("std_impact_525", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE

function std_impact_525:is_over_timed()
    return true
end

function std_impact_525:is_intervaled()
    return false
end

function std_impact_525:get_need_skill(imp)
    return imp.params["指定技能"] or -1
end

function std_impact_525:get_increase_target_status_probability()
    return imp.params["增加目标状态概率"] or 0
end

function std_impact_525:refix_skill(imp, obj, skill_info)
    if skill_info:get_skill_id() == self:get_need_skill(imp) then
		local value = self:get_increase_target_status_probability()
		if value > 0 then
			local give_target = skill_info:get_give_target_impact()
			give_target.p = give_target.p + value
		end
    end
end

-- [FIX] 861 无处遁形：impact到期时，施法者有该天赋则按概率对目标施加禁位移+破隐身
local FORBID_MOVE_IMPACT_ID = 63005  -- 禁止移动 impact -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
function std_impact_525:on_fade_out(imp, obj)
    -- 获取施法者
    local caster_obj_id = imp:get_caster_obj_id()
    if not caster_obj_id then return end
    local caster = obj:get_scene():get_obj_by_id(caster_obj_id)
    if not caster then return end

    -- 检查施法者是否学了武道861（无处遁形）
    local val = caster:have_talent(861)
    if val <= 0 then return end

    -- 概率判定：have_talent(861) 返回 params[1]，即 15/30/45/60/75
    if math.random(100) > val then return end

    -- 目标存活才施加控制
    if not obj:is_alive() then return end

    -- 施加禁止移动状态（持续时间由 impact 配置决定）
    impactenginer:send_impact_to_unit(obj, FORBID_MOVE_IMPACT_ID, caster, 0, false, 0)
    -- 强制破除目标隐身
    obj:set_shenbind_status(0)
end

return std_impact_525