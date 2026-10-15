local class = require "class"
local script_base = require "script_base"
local configenginer = require "configenginer":getinstance()
local define = require "define"
local PetSoulRanse = class("PetSoulRanse", script_base)

local COST_MATERIAL_ID = 30503154
local BASE_PLAN_COUNT = 3
local MAX_PLAN_COUNT = 5

local function get_plan_count(self, selfId)
    local bonus = self:GetDressSoulColorSlotBonus(selfId) or 0
    local count = BASE_PLAN_COUNT + bonus
    if count < BASE_PLAN_COUNT then
        return BASE_PLAN_COUNT
    end
    if count > MAX_PLAN_COUNT then
        return MAX_PLAN_COUNT
    end
    return count
end

local function notify_plan_locked(self, selfId, index)
    if index == 4 then
        self:notify_tips(selfId, "#{SZTJ_251014_79}")
    elseif index == 5 then
        self:notify_tips(selfId, "#{SZTJ_251014_80}")
    else
        self:notify_tips(selfId, "#{SHRS_230621_35}")
    end
end

local function roll_color(self, selfId, PetSoulId)
    local configs = self:GetPetSoulPossPaintConfig(PetSoulId)
    if not configs then
        self:notify_tips(selfId, "#{SHRS_230621_34}")
        return
    end
    local num = math.random(1000)
    local value = 0
    local result
    for _, c in ipairs(configs) do
        value = value + c.Odds
        result = c
        if value >= num then
            break
        end
    end
    if result == nil then
        self:notify_tips(selfId, "#{SHRS_230621_34}")
        return
    end
    return result.ColorValue
end

function PetSoulRanse:DoPaint(selfId, Index, PetSoulId)
    Index = tonumber(Index) or 0
    PetSoulId = tonumber(PetSoulId) or 0
    if Index < 1 or Index > get_plan_count(self, selfId) then
        notify_plan_locked(self, selfId, Index)
        return false
    end
    if PetSoulId <= 0 then
        self:notify_tips(selfId, "#{SHRS_230621_33}")
        return false
    end
    local item_count = self:LuaFnGetAvailableItemCount(selfId, COST_MATERIAL_ID)
    if item_count < 1 then
        self:notify_tips(selfId, "#{SHRS_230621_37}")
        return false
    end
    local color_value = roll_color(self, selfId, PetSoulId)
    if not color_value then
        return false
    end
    local ok = self:LuaFnDelAvailableItem(selfId, COST_MATERIAL_ID, 1)
    if not ok then
        self:notify_tips(selfId, "#{SHRS_230621_37}")
        return false
    end
    self:UnlockExteriorRanSe(selfId, PetSoulId, Index, color_value)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 18, 0)
    return true
end

function PetSoulRanse:OnPossPaint(selfId, targetId, Index, PetSoulId)
    self:DoPaint(selfId, Index, PetSoulId)
end

function PetSoulRanse:OnAutoRanSe(selfId, targetId, Index, PetSoulId)
    self:DoPaint(selfId, Index, PetSoulId)
end

function PetSoulRanse:OnSuccRanSe(selfId, Index, PetSoulId)
end

local function has_exterior_poss(human, pet_soul_id)
    for _, poss in ipairs(human.exterior.poss or {}) do
        if poss.id == pet_soul_id then
            return true
        end
    end
    return false
end

local function is_current_equip_poss(human, pet_soul_id)
    local soul_melting_pet_guid = human:get_current_soul_melting_pet_guid()
    if not soul_melting_pet_guid or soul_melting_pet_guid:is_null() then
        return false
    end
    local pet_detail = human:get_pet_bag_container():get_pet_by_guid(soul_melting_pet_guid)
    if not pet_detail then
        return false
    end
    local exterior_poss = configenginer:get_config("exterior_poss")[pet_soul_id]
    local models = exterior_poss and exterior_poss.models
    if not models then
        return false
    end
    local equip_model = pet_detail:get_pet_soul_melting_model()
    for i = 1, 3 do
        if models[i] == equip_model then
            return true
        end
    end
    return false
end

function PetSoulRanse:SaveExterior(selfId, PetSoulId, VisualIndex, ColorValue, UseEquip)
    PetSoulId = tonumber(PetSoulId) or 0
    VisualIndex = tonumber(VisualIndex) or -1
    ColorValue = tonumber(ColorValue) or 0
    UseEquip = tonumber(UseEquip) or 0

    local human = self:get_scene():get_obj_by_id(selfId)
    if not human or PetSoulId <= 0 or VisualIndex < 0 or VisualIndex > 2 then
        return false
    end
    if UseEquip == 1 then
        if not is_current_equip_poss(human, PetSoulId) then
            return false
        end
    elseif not has_exterior_poss(human, PetSoulId) then
        self:notify_tips(selfId, "#{SHRH_20220427_70}")
        return false
    end

    local level = human:get_pet_soul_melting_level()
    if level == define.INVAILD_ID then
        return false
    end
    local max_model_level = math.min(level // 3 + 1, 3)
    local model_level = VisualIndex + 1
    if model_level > max_model_level then
        self:notify_tips(selfId, "#{SHRS_230621_35}")
        return false
    end

    local exterior_poss = configenginer:get_config("exterior_poss")[PetSoulId]
    if not exterior_poss then
        return false
    end
    local model = exterior_poss.models and exterior_poss.models[model_level]
    if not model then
        return false
    end

    if ColorValue ~= 0 then
        local plan_index = human:get_exterior_ranse_plan_index(PetSoulId, ColorValue)
        if not human:is_exterior_ranse_plan_unlocked(plan_index) then
            notify_plan_locked(self, selfId, plan_index or 0)
            return false
        end
        local ranse_config = configenginer:get_config("exterior_ranse")[PetSoulId]
        local color_config = ranse_config and ranse_config[ColorValue]
        if not color_config or not color_config.ColorModel[model_level] then
            return false
        end
        model = color_config.ColorModel[model_level]
    end

    if UseEquip == 1 then
        human:set_exterior_pet_soul_id(0)
        human:set_exterior_equip_pet_soul_id(PetSoulId)
    else
        human:set_exterior_pet_soul_id(PetSoulId)
        human:set_exterior_equip_pet_soul_id(0)
    end
    human:set_exterior_ranse_id(ColorValue)
    human:set_exterior_ranse_model_level(model_level)
    human:set_exterior_ranse_select_by_ranse_id(PetSoulId, ColorValue)
    human:set_pet_soul_melting_model(model)
    human:send_exterior_info(6)
    human:send_refresh_attrib()
    human:send_exterior_ranse(2)
    self:notify_tips(selfId, "#{SHRH_20220427_32}")
    return true
end

return PetSoulRanse
