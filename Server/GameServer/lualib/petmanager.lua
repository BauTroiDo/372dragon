local skynet = require "skynet"
local define = require "define"
local class = require "class"
local configenginer = require "configenginer":getinstance()
local petmanager = class("petmanager")

function petmanager:getinstance()
    if petmanager.instance == nil then
        petmanager.instance = petmanager.new()
    end
    return petmanager.instance
end

function petmanager:set_scene(scene) self.scene = scene end

function petmanager:get_scene()
    return self.scene
end

function petmanager:make_ai_type(pet_attr_table)
    local n = math.random(1000)
    local ai_types = pet_attr_table.ai_type
    local now = 0
    for i = 0, 4 do
        now = now + ai_types[i]
        if now >= n then
            return i
        end
    end
end

function petmanager:make_growth_rate(pet_type, pet_attr_table)
    pet_type = pet_type or "Others"
    local pet_config_table = configenginer:get_config("pet_config_table")
    local key_1 = string.format("%s_GrowRate0", pet_type)
    local key_2 = string.format("%s_GrowRate1", pet_type)
    local key_3 = string.format("%s_GrowRate2", pet_type)
    local key_4 = string.format("%s_GrowRate3", pet_type)
    local key_5 = string.format("%s_GrowRate4", pet_type)
    local values = {}
    table.insert(values, pet_config_table.System[key_1])
    table.insert(values, pet_config_table.System[key_2])
    table.insert(values, pet_config_table.System[key_3])
    table.insert(values, pet_config_table.System[key_4])
    table.insert(values, pet_config_table.System[key_5])
    local num = math.random(1000)
    local now = 0
    local index = 1
    for i = 1, #values do
        local value = values[i]
        now = value + now
        if now >= num then
            index = i
            break
        end
    end
    local growth_rate = pet_attr_table.growth_rate[6 - index]
    return growth_rate / 1000
end

function petmanager:make_quick_growth_ratge(pet_attr_table)
    local i = #pet_attr_table.growth_rate
    return pet_attr_table.growth_rate[i] / 1000
end

function petmanager:make_remain_point(pet_detail)
    local pet_attr_point_distribute = configenginer:get_config("pet_attr_point_distribute")
    local num = math.random(#pet_attr_point_distribute)
    local distribute = pet_attr_point_distribute[num]
    assert(distribute, num)
    local str_rate = distribute.str
    local con_rate = distribute.con
    local spr_rate = distribute.spr
    local dex_rate = distribute.dex

    local point_remain = pet_detail:get_attrib("point_remain")
    local str = math.floor(point_remain * str_rate / 1000)
    local con = math.floor(point_remain * con_rate / 1000)
    local spr = math.floor(point_remain * spr_rate / 1000)
    local dex = math.floor(point_remain * dex_rate / 1000)
    local int = point_remain - str - con - spr - dex

    pet_detail:set_lv1_attrib({point_remain = 0})
    pet_detail:set_lv1_attrib({str = str})
    pet_detail:set_lv1_attrib({con = con})
    pet_detail:set_lv1_attrib({spr = spr})
    pet_detail:set_lv1_attrib({dex = dex})
    pet_detail:set_lv1_attrib({int = int})
end

function petmanager:create_skill_of_pet(pet_detail)
    local data_id = pet_detail:get_attrib("data_id")
    local pet_skill_distribute = configenginer:get_config("pet_skill_distribute")
    local pet_skill_index_table = configenginer:get_config("pet_skill_index_table")
    local psd = pet_skill_distribute[data_id]
    if psd == nil then
        return
    end
    local num = math.random(1000000)
    local now = 0
    for _, skill in ipairs(psd.skills) do
        now = now + skill.p
        if now <= num then
            local index = skill.index
            if pet_skill_index_table[index] then
                local id = pet_skill_index_table[index].skill
                self:add_pet_skill(pet_detail, id)
            end
        end
    end
end

function petmanager:add_pet_skill(pet_detail, skill)
    pet_detail:add_skill(skill)
end

function petmanager:create_type_of_pet(pet_detail, need_level_fluctuate, return_to_child)
    if return_to_child then
        pet_detail:set_db_attrib({level = 1})
        pet_detail:set_db_attrib({by_type = define.PET_TYPE.PET_TYPE_BABY})
        local level = pet_detail:get_attrib("level")
        pet_detail:set_lv1_attrib({point_remain = 50 + (level - 1) * 5})
        return
    end
    if not need_level_fluctuate then
        local level = pet_detail:get_attrib("level")
        if level <= 0 then
            level = 1
        end
        pet_detail:set_db_attrib({level = 1})
        pet_detail:set_lv1_attrib({point_remain = 50 + (level - 1) * 5})
    end
    local pet_config_table = configenginer:get_config("pet_config_table")

    local data_id = pet_detail:get_attrib("data_id")
    local pet_attr_table = configenginer:get_config("pet_attr_table")
    local level = pet_detail:get_attrib("level")
    if pet_attr_table[data_id].is_var_type then
        pet_detail:set_db_attrib({level = 1})
        pet_detail:set_db_attrib({by_type = define.PET_TYPE.PET_TYPE_VARIANCE})
    elseif pet_attr_table[data_id].is_baby_type then
        pet_detail:set_db_attrib({level = 1})
        pet_detail:set_db_attrib({by_type = define.PET_TYPE.PET_TYPE_BABY})
    else
        pet_detail:set_db_attrib({by_type = define.PET_TYPE.PET_TYPE_WILENESS})
        local take_level_rate = pet_config_table.System.WilenessPetRate_TakeLevel
        local low_one_level_rate = take_level_rate + pet_config_table.System.WilenessPetRate_Delta1
        local up_one_level_rate = low_one_level_rate + pet_config_table.System.WilenessPetRate_Delta1
        local low_2_level_rate = up_one_level_rate + pet_config_table.System.WilenessPetRate_Delta2
        local up_2_level_rate = low_2_level_rate + pet_config_table.System.WilenessPetRate_Delta2
        local low_3_level_rate = up_2_level_rate + pet_config_table.System.WilenessPetRate_Delta3
        local up_3_level_rate = low_3_level_rate + pet_config_table.System.WilenessPetRate_Delta3
        local num = math.random(100)
        if num < take_level_rate then
            level = level
        elseif num < low_one_level_rate then
            level = level - 1
        elseif num < up_one_level_rate then
            level = level + 1
        elseif num < low_2_level_rate then
            level = level - 2
        elseif num < up_2_level_rate then
            level = level + 2
        elseif num < low_3_level_rate then
            level = level - 3
        elseif num < up_3_level_rate then
            level = level + 3
        end
    end
    if level <= 0 then
        level = 1
    end
    pet_detail:set_lv1_attrib({point_remain = 50 + (level - 1) * 5})
end

function petmanager:get_baby_pet_data_id_by_data_id(data_id)
    if data_id % 10 == 0 then
        data_id = data_id + 9
    elseif data_id % 10 == 9 then
        data_id = data_id
    else
        return nil
    end
    return data_id
end

function petmanager:propagate(pet_detail, lock_growth_rate, lock_perception, is_quick)
    local pet_attr_table = configenginer:get_config("pet_attr_table")
    local data_id = pet_detail:get_attrib("data_id")
    data_id = self:get_baby_pet_data_id_by_data_id(data_id)
    if data_id == nil then
        return false
    end
    pet_detail:set_data_index(data_id)
    pet_attr_table = pet_attr_table[data_id]
    pet_detail:set_db_attrib({level = 1})

    local ai_type = self:make_ai_type(pet_attr_table)
    pet_detail:set_db_attrib({ai_type = ai_type})
    pet_detail:set_db_attrib({life_span = pet_attr_table.life_span})
    pet_detail:set_db_attrib({happiness = 100})
    pet_detail:set_db_attrib({exp = 0})
    pet_detail:set_db_attrib({growth_rate_queryd = true})
    pet_detail:set_lv1_attrib({point_remain = 50})
    self:make_remain_point(pet_detail)
    if lock_growth_rate == 0 then
        local growth_rate = self:make_growth_rate("RMB", pet_attr_table)
        if is_quick then
            growth_rate = self:make_quick_growth_ratge(pet_attr_table)
        end
        pet_detail:set_db_attrib({growth_rate = growth_rate})
    end
    local float = math.random(1000, 1230) / 1000
    if lock_perception == 0 then
        pet_detail:set_db_attrib({str_perception = math.ceil(pet_attr_table.str_perception * float) })
        pet_detail:set_db_attrib({con_perception = math.ceil(pet_attr_table.con_perception * float) })
        pet_detail:set_db_attrib({dex_perception = math.ceil(pet_attr_table.dex_perception * float) })
        pet_detail:set_db_attrib({spr_perception = math.ceil(pet_attr_table.spr_perception * float) })
        pet_detail:set_db_attrib({int_perception = math.ceil(pet_attr_table.int_perception * float) })
    end
    self:create_skill_of_pet(pet_detail)
    local pet_config_table = configenginer:get_config("pet_config_table")
    local base_hp = pet_config_table.System.BaseHP
    local attrib_rate = pet_config_table.System.Con_HP_Pram / 1000
    local level_rate = pet_config_table.System.Level_HP_Pram / 1000
    local con = pet_detail:get_attrib("con")
    local level = pet_detail:get_attrib("level")
    local hp = base_hp + attrib_rate * con + level * level_rate * pet_detail:get_attrib("growth_rate")
    hp = math.ceil(hp)
    pet_detail:set_db_attrib({hp = hp})
    return true
end

function petmanager:make_capture_pet_attrib(pet_detail, is_rmb, growth_rate, need_level_fluctuate, return_to_child)
    local pet_attr_table = configenginer:get_config("pet_attr_table")
    local monster_attr_ex = configenginer:get_config("monster_attr_ex")

    local data_id = pet_detail:get_attrib("data_id")
    pet_attr_table = pet_attr_table[data_id]
	if not pet_attr_table then
		local msg = string.format("不存在珍兽ID:%s",tostring(data_id))
		assert(false,msg)
	end
    monster_attr_ex = monster_attr_ex[data_id]
    pet_detail:set_db_attrib({name = pet_attr_table.name})
    pet_detail:set_db_attrib({level = pet_attr_table.level})
    pet_detail:set_db_attrib({take_level = pet_attr_table.take_level})
    local ai_type = self:make_ai_type(pet_attr_table)
    pet_detail:set_db_attrib({ai_type = ai_type})
    pet_detail:set_db_attrib({attack_type = monster_attr_ex.attack_type})
    pet_detail:set_db_attrib({life_span = pet_attr_table.life_span})
    pet_detail:set_db_attrib({happiness = 100})
    pet_detail:set_db_attrib({exp = 0})
    pet_detail:set_db_attrib({speed = monster_attr_ex.speed})
    pet_detail:set_db_attrib({move_mode = define.ENUM_MOVE_MODE.MOVE_MODE_WALK})
    local super = math.random(1, 100) == 50
    local float
    if super then
        float = math.random(1230, 1470) / 1000
    else
        float = math.random(1000, 1230) / 1000
    end
    pet_detail:set_db_attrib({str_perception = math.ceil(pet_attr_table.str_perception * float) })
    pet_detail:set_db_attrib({con_perception = math.ceil(pet_attr_table.con_perception * float) })
    pet_detail:set_db_attrib({dex_perception = math.ceil(pet_attr_table.dex_perception * float) })
    pet_detail:set_db_attrib({spr_perception = math.ceil(pet_attr_table.spr_perception * float) })
    pet_detail:set_db_attrib({int_perception = math.ceil(pet_attr_table.int_perception * float) })
    pet_detail:set_db_attrib({wuxing = 0})
    pet_detail:set_db_attrib({lingxing = 0})
    pet_detail:set_db_attrib({gengu = 0})
    pet_detail:set_db_attrib({stealth_level = 0})
    pet_detail:set_db_attrib({growth_rate_queryd = false})
    self:create_type_of_pet(pet_detail, need_level_fluctuate, return_to_child)
    growth_rate = growth_rate or self:make_growth_rate("RMB", pet_attr_table)
    pet_detail:set_db_attrib({growth_rate = growth_rate})
    self:make_remain_point(pet_detail)
    self:create_skill_of_pet(pet_detail)
    local hp_max = pet_detail:get_max_hp()
    pet_detail:set_db_attrib({hp = hp_max})
end

function petmanager:remove_pet(objid)
    local pet = self:get_scene():get_obj_by_id(objid)
    if pet then
        self:get_scene():delete_obj(pet)
    end
end

function petmanager:create_guid_of_pet(human, pet)
    local guid = pet:get_guid()
    guid:set(human:get_guid(), skynet.now() * 10 + math.random(10) % 10)
    return true
end

return petmanager