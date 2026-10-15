-- 慕容门派技能公共函数
-- 供破天式/凌神式/化气式共用

local skynet = require "skynet"
local impactenginer = require "impactenginer":getinstance()

local M = {}

-- 化气状态 StandardImpact data_index
M.HUAQI_BUFF_DATA_INDEX = 63017 -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
-- 化气状态 mutex_id
M.HUAQI_MUTEX_ID = 1540

-- 检查角色是否拥有化气状态
function M.has_huaqi_state(caster)
    if not caster then return nil end
    local impacts = caster:get_impact_list()
    if not impacts then return nil end
    for i = #impacts, 1, -1 do
        local imp = impacts[i]
        if imp and imp.mutex_id == M.HUAQI_MUTEX_ID then
            return imp
        end
    end
    return nil
end

-- 移除角色的化气状态
function M.remove_huaqi_state(caster)
    local imp = M.has_huaqi_state(caster)
    if imp then
        caster:on_impact_fade_out(imp)
        caster:remove_impact(imp)
    end
end

-- 给施法者挂化气buff
function M.apply_huaqi_buff(caster, skill_id)
    local impact_mod = require "scene.skill.impact"
    local imp = impact_mod.new()
    imp:clean_up()
    if impactenginer:init_impact_from_data(M.HUAQI_BUFF_DATA_INDEX, imp) then
        impactenginer:send_impact_to_unit(caster, M.HUAQI_BUFF_DATA_INDEX, caster, 0, false, 0, skill_id)
    end
end

-- 计算目标附近可落点位置
-- 返回 {x, y} 或 nil
function M.calc_near_target_position(caster, target, distance)
    if not caster or not target then return nil end
    local caster_pos = caster:get_world_pos()
    local target_pos = target:get_world_pos()
    local dx = caster_pos.x - target_pos.x
    local dy = caster_pos.y - target_pos.y
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist < 0.1 then
        -- 几乎重叠，偏移一小段
        return { x = target_pos.x + distance, y = target_pos.y }
    end
    -- 在目标和施法者连线上，距目标 distance 处
    local nx = dx / dist
    local ny = dy / dist
    local pos_x = target_pos.x + nx * distance
    local pos_y = target_pos.y + ny * distance
    if pos_x < 0 then pos_x = 0 end
    if pos_y < 0 then pos_y = 0 end
    return { x = pos_x, y = pos_y }
end

return M
