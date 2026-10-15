-- impact-logic (CY-Source 15/09/2026): logic 98 (tlbb15 StdImpact098_T 慈航普度) — khiên nhóm giảm/chuyển sát thương.
-- Bằng chứng: Server (main) StdImpact098_T::OnDamage/OnDamageTarget/OnFadeOut (Build/re/impact-logic/main-stdimpact-sel.c):
--   OnDamage (khi mang buff bị đánh): nếu người bị đánh == chủ buff → giảm 减伤率(自己) index3 % sát thương;
--     nếu là người khác trong 有效距离 index0 của chủ → giảm 减伤率(他人) index1 %, phần 他人受到的伤害转移率 index2 % chuyển về chủ (chủ mất máu tương ứng).
--   OnDamageTarget: cộng % (0x30, native RefixPowerByRate lưu) vào sát thương gây ra — bỏ qua vì CY dòng không có tham số này.
--   OnFadeOut: quét AOE gửi 子效果 (index10) — bỏ qua (子效果 = -1 ở dòng CY low-level; xem plan).
-- CY nhãn: 有效距离, 减伤率(他人), 他人受到的伤害转移率, 减伤率(自己), 扫描半径, 影响目标人数, 目标选择标记…, 是否影响自己…, 受到影响的类型…, 伤害是否使用战斗计算规则, 子效果.
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
