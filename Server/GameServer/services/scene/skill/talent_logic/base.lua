local class = require "class"
local base = class("base")

function base:ctor()
end

function base:refix_impact()
end

function base:on_critical_hit_target()
end

function base:on_damage_target()
end

function base:on_hit_target()
end

function base:refix_skill_cool_down_time(talent, level, talent_id, skill_info, cool_down_time)
    return cool_down_time
end

function base:on_impact_get_combat_result()

end

function base:on_use_skill_success_fully()

end

function base:refix_skill_info()

end

function base:on_skill_miss()

end

function base:on_be_hit()

end

function base:on_be_critical_hit()

end

function base:on_be_skill()

end

function base:on_active()

end

function base:get_add_skill()

end

function base:on_remove()

end

function base:on_get_skill_template()

end

function base:on_skill_miss_target()

end

function base:on_damages()

end

function base:refix_skill_id()

end

function base:on_stealth_level_update()

end

function base:on_impact_fade_out()

end

function base:on_damages_back_talent(talent,level,obj,sender,hp_modify,skill_id)

end
function base:trigger_talent_cost(id,cost)

end

function base:on_die()

end
function base:talent_study_sect()

end

return base