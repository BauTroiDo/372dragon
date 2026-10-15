local class = require "class"
local define = require "define"
local base = require "scene.skill.impact_logic.base"
local player_exp_rate = class("player_exp_rate", base)

function player_exp_rate:is_over_timed()
    return true
end

function player_exp_rate:is_intervaled()
    return false
end


function player_exp_rate:on_active(imp, obj)
    if obj:get_obj_type() == "human" then
		local exp_rate = imp.params["经验倍数(2倍即100)"] or 0
		if exp_rate > 0 then
			obj:set_exp_rate(exp_rate / 100)
		end
    end
end
function player_exp_rate:on_fade_out(imp, obj)
    if obj:get_obj_type() == "human" then
		-- if not obj:is_alive() then
			-- return
		-- end
		obj:set_exp_rate(0)
	end
end


return player_exp_rate