-- 天赋152（众生如来）：中冲剑(技能488)附加的抗性降低buff(logic_id=523)额外增加X点降抗
-- 技能488的抗性降低buff分4种属性组合，data_index范围：
--   29743-29758: 降低 火/玄/毒 抗
--   29759-29774: 降低 冰/火/毒 抗
--   29775-29790: 降低 冰/玄/毒 抗
--   29791-29806: 降低 冰/火/玄 抗
local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_152 = class("std_talent_152", base)

function std_talent_152:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_152:refix_impact(talent, level, imp, sender, reciver)
    if imp:get_skill_id() == 488 then
        if imp:get_logic_id() == 523 then
            local value = self:get_refix_value(talent, level)
            local logic = impactenginer:get_logic(imp)
            if logic and value > 0 then
                local id = imp:get_data_index()
                if id >= 29743 and id <= 29758 then
                    -- 降低 火/玄/毒 抗
                    do
                        local def = logic:get_value_of_refix_def_fire(imp)
                        def = def - value
                        logic:set_value_of_refix_def_fire(imp, def)
                    end
                    do
                        local def = logic:get_value_of_refix_def_light(imp)
                        def = def - value
                        logic:set_value_of_refix_def_light(imp, def)
                    end
                    do
                        local def = logic:get_value_of_refix_def_poison(imp)
                        def = def - value
                        logic:set_value_of_refix_def_poison(imp, def)
                    end
                elseif id >= 29759 and id <= 29774 then
                    -- 降低 冰/火/毒 抗
                    do
                        local def = logic:get_value_of_refix_def_cold(imp)
                        def = def - value
                        logic:set_value_of_refix_def_cold(imp, def)
                    end
                    do
                        local def = logic:get_value_of_refix_def_fire(imp)
                        def = def - value
                        logic:set_value_of_refix_def_fire(imp, def)
                    end
                    do
                        local def = logic:get_value_of_refix_def_poison(imp)
                        def = def - value
                        logic:set_value_of_refix_def_poison(imp, def)
                    end
                elseif id >= 29775 and id <= 29790 then
                    -- 降低 冰/玄/毒 抗
                    do
                        local def = logic:get_value_of_refix_def_cold(imp)
                        def = def - value
                        logic:set_value_of_refix_def_cold(imp, def)
                    end
                    do
                        local def = logic:get_value_of_refix_def_light(imp)
                        def = def - value
                        logic:set_value_of_refix_def_light(imp, def)
                    end
                    do
                        local def = logic:get_value_of_refix_def_poison(imp)
                        def = def - value
                        logic:set_value_of_refix_def_poison(imp, def)
                    end
                else
                    -- 降低 冰/火/玄 抗（id >= 29791）
                    do
                        local def = logic:get_value_of_refix_def_cold(imp)
                        def = def - value
                        logic:set_value_of_refix_def_cold(imp, def)
                    end
                    do
                        local def = logic:get_value_of_refix_def_fire(imp)
                        def = def - value
                        logic:set_value_of_refix_def_fire(imp, def)
                    end
                    do
                        local def = logic:get_value_of_refix_def_light(imp)
                        def = def - value
                        logic:set_value_of_refix_def_light(imp, def)
                    end
                end
            end
        end
    end
end

return std_talent_152