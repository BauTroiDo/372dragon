local class = require "class"
local base = require "scene.skill.impact_logic.base"
local xiangsibi = class("xiangsibi", base)
--527

function xiangsibi:is_over_timed()
    return true
end

function xiangsibi:is_intervaled()
    return false
end

function xiangsibi:get_combo_skill_id(imp)
	return imp.params["连续技ID"] or -1
end

function xiangsibi:on_active(imp,obj)
	 obj:set_shenbind_status(imp:get_data_index())
end

function xiangsibi:on_fade_out(imp, obj)
	obj:set_shenbind_status(0)
end

return xiangsibi