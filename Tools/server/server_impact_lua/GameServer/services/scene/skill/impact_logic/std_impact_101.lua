-- impact-logic (CY-Source 15/09/2026): logic 101 (tlbb15 StdImpact101_T 怒火连斩) — đếm "số đao" khi đánh trúng bằng kỹ năng thuộc tập, phát 加速BUFF, tới ngưỡng thì tăng sát thương.
-- Bằng chứng: Server (main) StdImpact101_T::OnDamageTarget/OnMissTarget/GetIntAttrRefix/OnFiltrateImpact (Build/re/impact-logic/main-stdimpact-sel.c):
--   OnDamageTarget: nếu 生效技能集合 (index1)=-1 hoặc kỹ năng thuộc tập → 刀数(0x2c)++, gọi Sect_OnKnifeNumUpdate; nếu chưa có 加速BUFF (index0)
--     thì phát nó; khi 刀数 ≥ 刀数上限 (index2) thì cộng % sát thương theo tổng lũy tiến (Σ i×hệ số, i=1..0x30).
--   GetIntAttrRefix (0x33 = hội tâm): cộng 0x34 (giá trị hội tâm tích) — dòng CY không nạp 0x34 nên = 0.
-- CY nhãn: 加速BUFF, 生效技能集合, 刀数上限. Bản Lua đếm đao + phát加速BUFF (cơ chế chính); % sát thương lũy tiến giữ theo native (hệ số nội bộ)
--   [SL] xấp xỉ +刀数% khi đạt ngưỡng (hệ số float native chưa giải chính xác) — đánh dấu suy luận.
local class = require "class"
local base = require "scene.skill.impact_logic.base"
local util = require "scene.skill.impact_logic.cy_impact_util"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE
local std_impact_101 = class("std_impact_101", base)

function std_impact_101:is_over_timed()
    return true
end

function std_impact_101:is_intervaled()
    return false
end

local function skill_matches(imp, obj, skill_id)
    local coll = util.num(imp, "生效技能集合", -1)
    if coll == -1 then return true end
    if not skill_id or skill_id == -1 then return false end
    -- dùng bộ kiểm tập kỹ năng của engine nếu có
    if obj.get_scene then
        local ok, res = pcall(function()
            return require("skillenginer"):getinstance()
        end)
        if ok and res and res.is_skill_in_collection then
            return res:is_skill_in_collection(skill_id, coll) and true or false
        end
    end
    return false
end

function std_impact_101:on_damage_target(imp, obj, target, damages, skill_id)
    if not damages or not damages.damage_rate then
        return
    end
    if not skill_matches(imp, obj, skill_id) then
        return
    end
    local knife = util.num(imp, "刀数") + 1
    imp.params["刀数"] = knife
    -- phát 加速BUFF một lần
    if not imp.params["_accel_sent"] then
        local accel = util.num(imp, "加速BUFF", -1)
        if accel >= 0 then
            obj:get_scene():get_impact_enginer():send_impact_to_unit(obj, accel, obj, 0, false, 0, imp:get_skill_id())
            imp.params["_accel_sent"] = 1
        end
    end
    local limit = util.num(imp, "刀数上限", 0)
    if limit > 0 and knife >= limit then
        -- [SL] tăng sát thương theo số đao (native dùng tổng lũy tiến với hệ số float chưa giải)
        for _, k in ipairs(DAMAGE_TYPE_RATE) do
            damages[k] = (damages[k] or 100) + knife
        end
    end
end

function std_impact_101:on_skill_miss(imp, obj)
    imp.params["刀数"] = util.num(imp, "刀数") + 1
end

return std_impact_101
