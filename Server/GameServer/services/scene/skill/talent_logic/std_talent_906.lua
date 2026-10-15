-- 伤心剑：心剑交融(技能828)的破绽持续buff(Impact 12413系列,logic_id=11)额外使目标降低X%的内外功防御
-- 技能828的SkillData 13043-13058施放的一次性Impact(12397-12411,logic_id=534)会对目标附加持续破绽buff(logic_id=11)
-- refix_impact拦截的正是该持续破绽buff被应用时的修正机会
local class = require "class"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_906 = class("std_talent_906", base)

function std_talent_906:refix_impact(talent, level, imp, sender, reciver)
    if imp:get_skill_id() == 828 then
        if imp:get_logic_id() == 11 then
            local params = talent.params[level]
            local percent = params[1] or 0
            local logic = impactenginer:get_logic(imp)
            if logic then
                do
                    local rate = logic:get_value_of_refix_attrib_def_physics(imp)
                    local extra = math.ceil(rate * percent / 100)
                    logic:set_value_of_refix_attrib_def_physics(imp, rate + extra)
                end
                do
                    local rate = logic:get_value_of_refix_attrib_def_magic(imp)
                    local extra = math.ceil(rate * percent / 100)
                    logic:set_value_of_refix_attrib_def_magic(imp, rate + extra)
                end
            end
        end
    end
end

return std_talent_906
