-- CY Server a5bf80/a5c220: attempted knives and successful knives differ.
-- Bonus = 1.5 * sum(1..successful). Constants: c198a8=1.5, b33b40=100,
-- b1ded8=.5 in main-load1-va3f0000.bin. HJ #87: one knife per cast.
local class = require "class"
local base = require "scene.skill.impact_logic.base"
local util = require "scene.skill.impact_logic.cy_impact_util"
local std_impact_101 = class("std_impact_101", base)
function std_impact_101:is_over_timed() return true end
function std_impact_101:is_intervaled() return false end

local function skill_matches(imp, skill_id)
    if not skill_id or skill_id < 0 then return false end
    local coll = util.num(imp, "生效技能集合", -1)
    return coll == -1 or require("skillenginer"):getinstance():is_skill_in_collection(skill_id, coll)
end

local function cast(imp, skill_id, token, hit)
    if not skill_matches(imp, skill_id) or type(token) ~= 'number' or token < 0 then return end
    local limit = util.num(imp, "刀数上限")
    if limit <= 0 then return end
    -- Retain this small ledger throughout the buff, including delayed victims
    -- arriving after a newer cast. Never read the actor's current handle here.
    local ledger = imp._cys_knives
    if not ledger then ledger = {}; imp._cys_knives = ledger end
    local key = tostring(token)..':'..skill_id
    local entry = ledger[key]
    if not entry then
        local knife = util.num(imp, "刀数") + 1
        if knife > limit then return end
        imp.params["刀数"] = knife
        entry = {knife=knife}; ledger[key] = entry
    end
    if hit and not entry.hit then
        local successful = util.num(imp, "命中刀数") + 1
        imp.params["命中刀数"] = successful
        entry.hit = true
        entry.rate = 1.5 * successful * (successful + 1) / 2
    end
    return entry
end

function std_impact_101:on_damage_target(imp, obj, target, damages, skill_id, attack)
    if not damages or not damages.damage_rate or not attack then return end
    local entry = cast(imp, skill_id, attack:get_caster_logic_count(), true)
    if not entry then return end
    local accel = util.num(imp, "加速BUFF", -1)
    if accel >= 0 and not imp.params._accel_sent then
        imp.params._accel_sent = true -- reserve before any engine yield
        obj:get_scene():get_impact_enginer():send_impact_to_unit(obj, accel, obj, 0, false, 0, imp:get_skill_id())
    end
    -- character:on_damages applies this once to combined damage, including
    -- direct damage. Do not add it separately to every elemental rate.
    damages.cys_nuhuo_rate = math.max(damages.cys_nuhuo_rate or 0, entry.rate)
end

function std_impact_101:on_miss_target(imp, obj, target, skill_id, cast_token)
    cast(imp, skill_id, cast_token, false)
end
return std_impact_101
