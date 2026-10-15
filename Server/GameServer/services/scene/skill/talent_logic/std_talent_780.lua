-- [FIX] 天赋780（敲霜醒花）：西子捧心(skill 403)命中后，10/20/30/40/50% 概率触发群疗
-- on_damage_target 中检查 skill_id==403，按概率对附近队友（含自身）按最大HP百分比回血
-- SectInfo第782行: skill_type=292, impact_id=403
-- SectDesc第782行: 参数 10/20/30/40/50
local class = require "class"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_780 = class("std_talent_780", base)

local SKILL_ID = 403  -- 西子捧心
local SCAN_RADIUS = 20
local SCAN_COUNT = 20
local HEAL_PERCENT = 5  -- 群疗固定回复最大HP的5%

function std_talent_780:get_odd(talent, level)
    local params = talent.params[level]
    return params and params[1] or 0
end

-- [FIX] on_damage_target: 西子捧心命中后按概率触发群疗效果
function std_talent_780:on_damage_target(talent, level, id, sender, reciver, damages, skill_id)
    if skill_id ~= SKILL_ID then
        return
    end
    local odd = self:get_odd(talent, level)
    if odd <= 0 then
        return
    end
    if math.random(100) > odd then
        return
    end
    -- 计算治愈量：对人目标回复同伤害值，对怪回复5%最大HP
    local heal_amount = 0
    if reciver and reciver:get_obj_type() == "human" then
        for i = 0, 6 do
            heal_amount = heal_amount + (tonumber(damages[i]) or 0)
        end
    else
        local max_hp = reciver and reciver:get_max_hp() or 0
        heal_amount = math.ceil(max_hp * HEAL_PERCENT / 100)
    end
    if heal_amount <= 0 then
        return
    end
    -- 群疗：扫描附近队友，对每人回复治愈量
    local position = sender:get_world_pos()
    local operate = {obj = sender, x = position.x, y = position.y, radious = SCAN_RADIUS, count = SCAN_COUNT}
    local nearbys = sender:get_scene():scan(operate)
    -- 包含施法者自身
    table.insert(nearbys, sender)
    for _, nb in ipairs(nearbys) do
        if nb:is_character_obj() and nb:is_alive() and (nb == sender or sender:is_teammate(nb)) then
            -- local max_hp = nb:get_max_hp()
            -- if max_hp and max_hp > 0 then
            --     local recover_hp = math.ceil(max_hp * HEAL_PERCENT / 100)
            --     nb:health_increment(recover_hp, sender, false)
            -- end
            nb:health_increment(recover_hp, sender, false)
        end
    end
end

return std_talent_780
