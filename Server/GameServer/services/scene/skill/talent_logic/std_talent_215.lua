local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_215 = class("std_talent_215", base)
local impacts = {
    44294, 44295, 44296, 44297, 44298
}
function std_talent_215:get_refix_p(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_215:get_impact(talent, level)
    return impacts[level] or define.INVAILD_ID
end

function std_talent_215:on_be_critical_hit(talent_config, level, reciver, sender, skill)
    local p = self:get_refix_p(talent_config, level)
    local n = math.random(100)
    local impact_id = self:get_impact(talent_config, level)
    if impact_id ~= define.INVAILD_ID then
        impactenginer:send_impact_to_unit(reciver, impact_id, reciver, 0, false, 0)
    end
end

return std_talent_215