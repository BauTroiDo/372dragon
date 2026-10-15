-- 倒行逆施：彼行我释(825)可以在被控制时使用，有X%概率解除自身控制
-- 技能逻辑通过have_talent(922)允许被控时使用
local class = require "class"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_922 = class("std_talent_922", base)
local control_collections = {40,41,42,43,44,130,131,132,133,134,135,137,321,332}

function std_talent_922:on_use_skill_success_fully(talent, level, skill_info, human)
    if skill_info:get_skill_id() == 825 then
        local params = talent.params[level]
        local chance = params[1] or 0
        local n = math.random(100)
        if n <= chance then
            local list = human:get_impact_list()
            for i = #list, 1, -1 do
                local imp = list[i]
                if imp:is_can_be_dispeled() and impactenginer:is_impact_in_collection_ex(imp, control_collections) then
                    human:on_impact_fade_out(imp)
                    human:remove_impact(imp)
                    break
                end
            end
        end
    end
end

return std_talent_922
