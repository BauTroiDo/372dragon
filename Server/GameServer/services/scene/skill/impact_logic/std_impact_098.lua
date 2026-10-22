






local class = require "class"
local base = require "scene.skill.impact_logic.base"
local util = require "scene.skill.impact_logic.cy_impact_util"
local std_impact_098 = class("std_impact_098", base)

function std_impact_098:is_over_timed()
    return true
end

function std_impact_098:is_intervaled()
    return false
end

-- người mang buff bị đánh: giảm sát thương, chuyển phần về chủ buff
function std_impact_098:on_damages(imp, obj, damages, caster_obj_id)
    if not damages or not damages.damage_rate then
        return
    end
    local scene = obj:get_scene()
    local owner = scene:get_obj_by_id(imp:get_caster_obj_id())
    local reduce
    if owner == nil or owner == obj then
        reduce = util.num(imp, "减伤率(自己)")
    else
        -- người khác chỉ được che khi còn trong有效距离 của chủ (đo trên world pos)
        local range = util.num(imp, "有效距离", -1)
        if range >= 0 and obj.get_world_pos and owner.get_world_pos then
            local a, b = obj:get_world_pos(), owner:get_world_pos()
            if a and b then
                local dx, dz = a.x - b.x, a.y - b.y
                if dx * dx + dz * dz > range * range then
                    return
                end
            end
        end
        reduce = util.num(imp, "减伤率(他人)")
    end
    if reduce > 0 then
        damages.imm_dmg_rate = (damages.imm_dmg_rate or 0) + math.min(reduce, 100)
    end
    -- 他人受到的伤害转移率 (chuyển phần sát thương về chủ buff): native tính trên sát thương thực sau khấu trừ;
    -- on_damages Lua chạy trước khi ra số cuối → chưa chuyển được ở tầng này [SL, xem Docs/specs/server/impact-logic_vi.md].
end

return std_impact_098
