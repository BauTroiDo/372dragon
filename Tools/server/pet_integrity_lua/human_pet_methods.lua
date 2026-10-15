-- Destructive user release is distinct from internal transfer/compound removal.
function human:free_pet_to_nature(logparam, guid)
    local pet = guid and self:get_pet_bag_container():get_pet_by_guid(guid)
    if not pet or pet:is_lock() or pet:is_in_exchange() or pet:have_equip()
        or guid == self:get_current_pet_guid()
        or guid == self:get_current_soul_melting_pet_guid() then
        return define.OPERATE_RESULT.OR_ERROR
    end
    for _, slot in pairs(pet.elf_slots or {}) do
        if (slot.activated or 0) ~= 0 then return define.OPERATE_RESULT.OR_ERROR end
    end
    return self:remove_pet(logparam, guid) and define.OPERATE_RESULT.OR_OK or define.OPERATE_RESULT.OR_ERROR
end

function human:test_pet_soul_melting(guid)
    local pet = guid and self:get_pet_bag_container():get_pet_by_guid(guid)
    if not pet or pet:is_lock() or pet:is_in_exchange() then return define.OPERATE_RESULT.OR_ERROR end
    if not self:can_use_skill_now() then return define.OPERATE_RESULT.OR_BUSY end
    if pet:get_hp() <= 0 then return define.OPERATE_RESULT.OR_NOT_ENOUGH_HP end
    if pet:get_life() <= 0 then return define.OPERATE_RESULT.OR_NEED_LIFE end
    return define.OPERATE_RESULT.OR_OK
end

function human:impact_clean_when_remelting_pet_soul(pet)
    if not pet then return end
    local soul = pet:get_equip_container():get_item(define.PET_EQUIP.PEQUIP_SOUL)
    if not soul then return end
    local base = soul:get_pet_soul_base()
    local table = configenginer:get_config('pet_soul_skill')
    local conf = base and table[base.skill]
    if not conf or not conf.melting_impacts then return end
    local level = (soul:get_pet_equip_data():get_pet_soul_level() or 0) + 1
    for _, row in ipairs(conf.melting_impacts) do
        if define.PET_SOUL_BASE_ATTR_2_IA[row.desc] == define.ITEM_ATTRIBUTE.IATTRIBUTE_QIONGQI_MELTING_IMPACT then
            local id = define.QIONGQI_IMPACT[level]
            if id then
                local impact = self:impact_get_first_impact_of_specific_data_index(id)
                if impact then self:on_impact_fade_out(impact);self:remove_impact(impact) end
            end
        end
    end
end
