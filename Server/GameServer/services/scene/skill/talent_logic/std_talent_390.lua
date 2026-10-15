local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_390 = class("std_talent_390", base)
function std_talent_390:on_active(talent, level, human)
    human:set_datura_flower_max(7)
end

function std_talent_390:on_remove(talent, level, human)
    human:set_datura_flower_max(6)
end

function std_talent_390:on_use_skill_success_fully(talent, level, skill_info, human)
    local skill_id = skill_info:get_skill_id()
    local collection_id = 313
    local is_in_collection = skillenginer:is_skill_in_collection(skill_id, collection_id)
    if is_in_collection then
        local odd = self:get_odd(human)
        local num = math.random(100)
        if num <= odd then
            local data_index = 63050 -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
            impactenginer:send_impact_to_unit(human, data_index, human, 0, false, 0)
        end
    end
end

local odds = { 17, 19, 21, 23, 25}
function std_talent_390:get_odd(human)
    local talent_level = human:get_talent_level_by_id(612)
    return odds[talent_level] or 15
end

return std_talent_390