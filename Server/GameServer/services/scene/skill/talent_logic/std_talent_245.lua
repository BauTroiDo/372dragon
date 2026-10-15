local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_245 = class("std_talent_245", base)
function std_talent_245:get_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_245:on_skill_miss(talent, level, sender, reciver, skill_id)
    local odd = self:get_value(talent, level)
    local n = math.random(1, 100)
    if n <= odd then
        local data_index = 63039 -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
        impactenginer:send_impact_to_unit(reciver, data_index, reciver, 0, false, 0)
    end
end

return std_talent_245