






















local class = require "class"
local base = require "scene.skill.impact_logic.base"
local impact = require "scene.skill.impact"
local combat_core = require "scene.skill.combat_core"
local std_impact_003 = require "scene.skill.impact_logic.std_impact_003"

local std_impact_115 = class("std_impact_115", base)

std_impact_115.ID = 115
std_impact_115.NORMAL_ATTACK_DATA_INDEX = 0        -- dòng StandardImpact của đòn đánh thường (CY: DataIndex 0)
std_impact_115.SCALE_LABEL = "伤害量缩放系数"

function std_impact_115:is_over_timed()
    return false
end

function std_impact_115:is_intervaled()
    return false
end

function std_impact_115:get_scale(imp)
    local v = tonumber(imp.params and imp.params[self.SCALE_LABEL])
    if v == nil or v <= 0 then
        return 100
    end
    return v
end

-- tách riêng để test đơn vị: dựng impact đánh thường đã qua CombatCore + nhân hệ số
function std_impact_115:make_normal_attack(imp, obj, caster)
    local scene = obj:get_scene()
    local engine = scene and scene:get_impact_enginer()
    if not engine then
        return nil
    end
    local new = impact.new()
    new:clean_up()
    if not engine:init_impact_from_data(self.NORMAL_ATTACK_DATA_INDEX, new) then
        return nil
    end
    if new:get_logic_id() == std_impact_003.ID then
        local cc = combat_core.new()
        cc:get_result_impact(caster, obj, new)
        local scale = self:get_scale(imp)
        if scale ~= 100 then
            std_impact_003.refix_power_by_rate(std_impact_003, new, scale - 100)
        end
    end
    new:set_caster_obj_id(imp:get_caster_obj_id())
    new:set_skill_id(imp:get_skill_id())
    new:set_skill_level(imp:get_skill_level())
    if imp:is_critical_hit() then
        new:mark_critical_hit_flag()
    end
    return new
end

function std_impact_115:on_active(imp, obj)
    if not imp or not obj or not obj:is_alive() then
        return
    end
    local scene = obj:get_scene()
    if not scene then
        return
    end
    local caster_id = imp:get_caster_obj_id()
    local caster = caster_id and scene:get_obj_by_id(caster_id)
    if not caster then
        return
    end
    local t = caster.get_obj_type and caster:get_obj_type()
    if not (t == "human" or t == "pet" or t == "monster") then     -- native: (GetObjType()-1) u< 3
        return
    end
    local new = self:make_normal_attack(imp, obj, caster)
    if not new then
        return
    end
    -- native đăng ký sự kiện impact lên mục tiêu; phía Lua, std_impact_003.on_active là chỗ
    -- biến các ô 物理伤害/魔法伤害/… đã tính thành obj:on_damages (đúng một nhịp, không trễ).
    std_impact_003.on_active(std_impact_003, new, obj)
end

return std_impact_115
