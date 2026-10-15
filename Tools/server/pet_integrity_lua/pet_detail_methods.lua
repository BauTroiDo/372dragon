-- Method bodies installed into BOTH live pet_detail implementations by the reapply tool.
function pet_detail:is_in_exchange()
    return self.cy_in_exchange == true
end

function pet_detail:set_in_exchange(value)
    self.cy_in_exchange = value == true
end

function pet_detail:get_skill_by_index(index)
    if not pet_rules.integer(index, 0, 11) then return nil end
    if index < 2 then return self:get_activate_skill(index + 1) end
    return self:get_positive_skill(index - 1)
end

function pet_detail:set_skill_by_index(index, skill_id)
    if not pet_rules.integer(index, 0, 11) or not pet_rules.integer(skill_id, 0, 2147483647) then return false end
    if index < 2 then self:set_activate_skill(index + 1, skill_id)
    else self:set_positive_skill(index - 1, skill_id) end
    self.db:mark_skill_dirty()
    return true
end

function pet_detail:skill_modify_study(skillid)
    local index = pet_rules.study(self, skillid,
        function(id) return skillenginer:get_skill_template(id) end,
        configenginer:get_config('pet_study_skill_table'),
        define.PET_SKILL_OPERATEMODE.PET_SKILL_OPERATE_NEEDOWNER, math.random)
    if index == nil then return false end
    return self:set_skill_by_index(index, skillid)
end
