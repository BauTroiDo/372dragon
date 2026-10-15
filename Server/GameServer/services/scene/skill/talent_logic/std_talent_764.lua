-- [FIX] 天赋764（由己渡人）：回天术(skill 411)释放成功时，1/2/3/4/5% 概率给队伍中血量最低的队友附加回天术effect
-- on_use_skill_success_fully 中检查 skill_id==411，按概率扫描附近队友，找到血量最低者发送 impact 411
-- SectInfo第766行: skill_type=284, impact_id=411
-- SectDesc第766行: 参数 1/2/3/4/5
local class = require "class"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_764 = class("std_talent_764", base)

local SKILL_ID = 411
local IMPACT_ID = 411
local SCAN_RADIUS = 30
local SCAN_COUNT = 20

function std_talent_764:get_odd(talent, level)
    local params = talent.params[level]
    return params and params[1] or 0
end

-- [FIX] on_use_skill_success_fully: 回天术释放成功时，按概率给最低血量队友附加回天术effect
function std_talent_764:on_use_skill_success_fully(talent, level, skill_info, human)
    if skill_info:get_skill_id() ~= SKILL_ID then
        return
    end
    local odd = self:get_odd(talent, level)
    if odd <= 0 then
        return
    end
    if math.random(100) > odd then
        return
    end
    -- 扫描附近单位，寻找血量最低的队友（排除自身）
    local position = human:get_world_pos()
    local operate = {obj = human, x = position.x, y = position.y, radious = SCAN_RADIUS, count = SCAN_COUNT}
    local nearbys = human:get_scene():scan(operate)
    local best_target = nil
    local best_hp_ratio = 2  -- 初始值大于1，确保任何队友都能被选中
    for _, nb in ipairs(nearbys) do
        if nb ~= human and nb:is_character_obj() and nb:is_alive() and human:is_teammate(nb) then
            local max_hp = nb:get_max_hp()
            if max_hp and max_hp > 0 then
                local hp_ratio = nb:get_hp() / max_hp
                if hp_ratio < best_hp_ratio then
                    best_hp_ratio = hp_ratio
                    best_target = nb
                end
            end
        end
    end
    if best_target then
        impactenginer:send_impact_to_unit(best_target, IMPACT_ID, human, 0, false, 0)
    end
end

return std_talent_764
