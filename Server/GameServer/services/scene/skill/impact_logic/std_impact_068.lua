local class = require "class"
local define = require "define"
local impactenginer = require "impactenginer":getinstance()
local eventenginer = require "eventenginer":getinstance()
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local combat_core = require "scene.skill.combat_core"
local impact = require "scene.skill.impact"
local base = require "scene.skill.impact_logic.base"
local std_impact_068 = class("std_impact_068", base)

function std_impact_068:is_over_timed()
    return true
end

function std_impact_068:is_intervaled()
    return false
end

function std_impact_068:get_affect_radious(imp)
    return imp.params["爆炸半径"]
end

function std_impact_068:get_affect_target_count(imp)
    return imp.params["影响的个体的最大数目"]
end

function std_impact_068:set_affect_target_count(imp, count)
    imp.params["影响的个体的最大数目"] = count
end

function std_impact_068:get_bomb_sub_impact(imp)
    return imp.params["爆炸的子效果"]
end

function std_impact_068:on_hit_target(imp, sender, reciver)
    if imp:get_is_over_timed() then
        local radious = self:get_affect_radious(imp)
        local affect_count = self:get_affect_target_count(imp)
        local position = reciver:get_world_pos()
        local operate = {obj = reciver, x = position.x, y = position.y, radious = radious, count = affect_count}
        local nearbys = reciver:get_scene():scan(operate)
        for _, nb in ipairs(nearbys) do
            -- 调试输出已屏蔽
            -- print("nb.classname =", nb.classname)
            if nb:is_character_obj() then
               if sender:is_enemy(nb) and nb:is_alive() then
                    local value = self:get_bomb_sub_impact(imp)
                    local new_imp = impact.new()
                    new_imp:clean_up()
                    impactenginer:init_impact_from_data(value, new_imp)
                    if new_imp:get_logic_id() == DI_DamagesByValue_T.ID then
                        local co = combat_core.new()
                        co:get_result_impact(sender, reciver, new_imp)
                    end
                    eventenginer:register_impact_event(nb, sender, new_imp, 0, define.INVAILD_ID)
               end
            end
        end
    end
end

function std_impact_068:on_active(imp, reciver)
    if not imp:get_is_over_timed() then
        local caster_obj_id = imp:get_caster_obj_id()
        local sender = reciver:get_scene():get_obj_by_id(caster_obj_id)
        if sender then
            local radious = self:get_affect_radious(imp)
            local affect_count = self:get_affect_target_count(imp)
            local position = reciver:get_world_pos()
            local operate = {obj = reciver, x = position.x, y = position.y, radious = radious, count = affect_count}
            local nearbys = reciver:get_scene():scan(operate)
            for _, nb in ipairs(nearbys) do
                -- 调试输出已屏蔽
                -- print("nb.classname =", nb.classname)
                if nb:is_character_obj() then
                   if sender:is_enemy(nb) and nb:is_alive() then
                        local value = self:get_bomb_sub_impact(imp)
                        local new_imp = impact.new()
                        new_imp:clean_up()
                        impactenginer:init_impact_from_data(value, new_imp)
                        if new_imp:get_logic_id() == DI_DamagesByValue_T.ID then
                            local co = combat_core.new()
                            co:get_result_impact(sender, reciver, new_imp)
                        end
                        eventenginer:register_impact_event(nb, sender, new_imp, 0, define.INVAILD_ID)
                   end
                end
            end
        end
    end
end



return std_impact_068