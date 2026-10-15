local class = require "class"
local skynet = require "skynet"
local define = require "define"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_812 = class("std_talent_812", base)

function std_talent_812:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_812:refix_impact(talent, level, imp, sender, reciver)
	if imp:get_skill_id() ~= 488 then
		return
	end
	if reciver:get_obj_type() ~= "human" then
		return
	end
	local id = imp:get_data_index()
	local attr = 0
	if id >= 29743 and id <= 29758 then
		attr = sender:get_attrib("att_cold") + sender:get_attrib("att_fire") + sender:get_attrib("att_light")
	elseif id >= 29759 and id <= 29774 then
		attr = sender:get_attrib("att_cold") + sender:get_attrib("att_fire") + sender:get_attrib("att_poison")
	elseif id >= 29775 and id <= 29790 then
		attr = sender:get_attrib("att_cold") + sender:get_attrib("att_light") + sender:get_attrib("att_poison")
	else
		attr = sender:get_attrib("att_light") + sender:get_attrib("att_fire") + sender:get_attrib("att_poison")
	end
	local value = self:get_refix_value(talent, level)
	if value <= 0 or attr <= 0 then
		return
	end
	local mana_per_tick = -1 * attr * value / 100
	local continuance = imp:get_continuance()
	local sn = imp:get_sn()
	skynet.fork(function()
		local elapsed = 0
		while elapsed < continuance do
			skynet.sleep(100)
			elapsed = elapsed + 1000
			if not reciver:is_alive() then
				return
			end
			reciver:mana_increment(mana_per_tick, sender)
		end
	end)
end

return std_talent_812