local class = require "class"
local define = require "define"
local config = require "cy_four_crafting_config"
local engine = require "configenginer":getinstance()
local item_logic = require "human_item_logic"
local compound = require "scene.ability.compound"
local base = require "scene.ability.base"
local cy_four_compound = class("cy_four_compound", compound)
local OK = define.OPERATE_RESULT.OR_OK

function cy_four_compound:check_recipe(human)
    local op = human:get_ability_opera()
    local recipe = config.recipes[op.pres_id]
    if not recipe or recipe.ability ~= self.id or op.ability_id ~= self.id
        or human:get_menpai() ~= recipe.faction or op.mat_bag_index ~= 255 then
        return define.OPERATE_RESULT.OR_WARNING
    end
    local ability = human:get_ability(self.id)
    if not ability or ability.level < recipe.level
        or not human:is_prescription_have_learnd(op.pres_id) then
        return define.OPERATE_RESULT.OR_WARNING
    end
    if human:get_stamina() < recipe.energy then
        return define.OPERATE_RESULT.OR_NOT_ENOUGH_ENERGY
    end
    return OK, recipe
end

function cy_four_compound:can_use_ability(human)
    local res = self:check_recipe(human)
    if res ~= OK then return res end
    res = base.can_use_ability(self, human)
    if res ~= OK then return res end
    local op = human:get_ability_opera()
    local row = self.abilityenginer:get_prescription_list()[op.pres_id]
    if not row then return define.OPERATE_RESULT.OR_WARNING end
    op.max_time = row["操作时间"]
    return compound.is_fit_prescr(self, human, row)
end

function cy_four_compound:on_proc_over(human)
    -- Revalidate the complete request after the progress timer, before spending.
    local res = self:can_use_ability(human)
    if res ~= OK then return res end
    local op = human:get_ability_opera()
    local recipe = config.recipes[op.pres_id]
    local row = self.abilityenginer:get_prescription_list()[op.pres_id]
    local bind = false
    for id, count in pairs(recipe.materials) do
        local remaining = count
        for _, item in human:get_prop_bag_container():ipairs("material") do
            if remaining > 0 and item and item:get_index() == id then
                bind = bind or item:is_bind()
                remaining = remaining - math.min(remaining, item:get_lay_count())
            end
        end
        assert(remaining == 0, "CY4 material bag changed after validation")
        assert(item_logic:erase_material_item({}, human, id, count))
    end
    human:set_stamina(human:get_stamina() - recipe.energy)
    -- Native profession proficiency curve; no call to the absent legacy
    -- CheckForResult callback. These CY recipes have no failure product/script.
    local ability = human:get_ability(self.id)
    local costs = engine:get_config("menpaishenghuo")[ability.level]
    local cap = costs["本级熟练度的上限"]
    local disparity = ability.level - recipe.level
    local gain = disparity == 0 and 100 or (disparity == 1 and 50 or 0)
    if ability.exp < cap and gain > 0 then
        human:set_ability_exp(self.id, math.min(cap, ability.exp + gain), cap)
    end
    return compound.on_proc_success(self, human, row, bind)
end

return cy_four_compound
