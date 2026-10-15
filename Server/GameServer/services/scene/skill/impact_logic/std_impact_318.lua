local class = require "class"
local define = require "define"
local configenginer= require "configenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_318 = class("std_impact_318", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_BACK = DI_DamagesByValue_T.enum_DAMAGE_TYPE_BACK

function std_impact_318:is_over_timed()
    return true
end

function std_impact_318:is_intervaled()
    return false
end

function std_impact_318:get_dispel_level(imp)
    return imp.params["驱散级别"]
end

function std_impact_318:get_dispel_count(imp)
    return imp.params["驱散个数"]
end

function std_impact_318:get_collection_by_index(imp, index)
    local key = string.format("驱散集合%d", index)
    return imp.params[key]
end

function std_impact_318:set_shield_hp(imp, hp)
    imp.params["护盾生命值"] = hp
end

function std_impact_318:get_shield_hp(imp)
    return imp.params["护盾生命值"]
end

function std_impact_318:get_make_shield_from_hp_rate(imp)
    return imp.params["护盾生命值百分比"] or 0
end

function std_impact_318:set_make_shield_from_hp_rate(imp, percent)
    imp.params["护盾生命值百分比"] = percent
end

function std_impact_318:on_damages(imp, obj, damages)
	local shield_hp = self:get_shield_hp(imp)
	if not shield_hp or shield_hp <= 0 then
        obj:on_impact_fade_out(imp)
        obj:remove_impact(imp)
		return
	end
	if damages and damages.damage_rate then
		local idx = DAMAGE_TYPE_BACK[1]
		table.insert(damages[idx],imp)
	end
    -- local shield_hp = self:get_shield_hp(imp)
    -- if shield_hp == nil then
        -- shield_hp = math.ceil(obj:get_max_hp() * self:get_make_shield_from_hp_rate(imp) / 100)
    -- end
    -- local absorb_damage = math.floor(damages.hp_damage)
    -- absorb_damage = absorb_damage > shield_hp and shield_hp or absorb_damage
	-- if damages.damage_rate then
		-- damages.sub_all_damage_point = damages.sub_all_damage_point or 0 + absorb_damage
	-- end
    -- damages.hp_damage = damages.hp_damage - absorb_damage
    -- shield_hp = shield_hp - absorb_damage
    -- if shield_hp > 0 then
        -- self:set_shield_hp(imp, shield_hp)
    -- else
        -- obj:on_impact_fade_out(imp)
        -- obj:remove_impact(imp)
    -- end
end

function std_impact_318:on_damages_back(imp, obj, damage_value)
    local shield_hp = self:get_shield_hp(imp)
    if not shield_hp or shield_hp <= 0 then
		return 0
	elseif damage_value <= 0 then
		return 0
    end
	
    local absorb_damage = math.floor(damage_value)
    absorb_damage = absorb_damage > shield_hp and shield_hp or absorb_damage
    shield_hp = shield_hp - absorb_damage
    if shield_hp > 0 then
        self:set_shield_hp(imp, shield_hp)
    else
        obj:on_impact_fade_out(imp)
        obj:remove_impact(imp)
    end
    local caster_obj_id = imp:get_caster_obj_id()
	obj:show_skill_missed(obj:get_obj_id(),caster_obj_id,imp:get_skill_id(),obj:get_logic_count(),define.MISS_FLAG.FLAG_ABSORB)
	return absorb_damage
end

function std_impact_318:on_active(imp, obj_me)
    local shield_hp = self:get_shield_hp(imp)
    if not shield_hp then
        shield_hp = math.ceil(obj_me:get_max_hp() * self:get_make_shield_from_hp_rate(imp) / 100)
		self:set_shield_hp(imp, shield_hp)
    end
    local collections_config = configenginer:get_config("id_collections")
    local dispel_level = self:get_dispel_level(imp)
    local dispel_count = 1000
    local COLLECTION_NUMBER = 4
    local dispeld = 0
    assert(dispel_level, imp:get_data_index())
    for i = 1, COLLECTION_NUMBER do
        local collection_id = self:get_collection_by_index(imp, i)
        if collection_id ~= define.INVAILD_ID then
            local collections = collections_config[collection_id]
            if collections then
                dispeld = dispeld + obj_me:dispel_Impact_in_specific_collection(collection_id, dispel_level, dispel_count)
            end
        end
    end
end

return std_impact_318