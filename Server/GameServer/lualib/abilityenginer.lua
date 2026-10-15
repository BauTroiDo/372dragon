local define = require "define"
local class = require "class"
local ability_compound = require "scene.ability.compound"
local ability_in_lay = require "scene.ability.in_lay"
local ability_foundry = require "scene.ability.foundry"
local ability_generic_gather = require "scene.ability.generic_gather"
local ability_generic = require "scene.ability.generic"
local ability_gather_fish = require "scene.ability.gather_fish"
local ability_tailor = require "scene.ability.tailor"
local ability_artwork = require "scene.ability.artwork"
local configenginer = require "configenginer":getinstance()
local abilityenginer = class("abilityenginer")
function abilityenginer:getinstance()
    if abilityenginer.instance == nil then
        abilityenginer.instance = abilityenginer.new()
    end
    return abilityenginer.instance
end

function abilityenginer:ctor()
    self.abilitys = {}
end

function abilityenginer:loadall()
    if self.loaded_all then return end
    self.loaded_all = true
    local abilitys = configenginer:get_config("ability")
    for id, ability in pairs(abilitys) do
        if (define.MENPAI_COMPOUND_ABILITIES or {})[id] then
            self.abilitys[id] = require("scene.ability.cy_four_compound").new(ability)
        elseif id == define.ABILITY_CAILIAOHECHENG then
            self.abilitys[id] = ability_compound.new(ability)
        elseif id == define.AbilityClass.ABILITY_CLASS_COOKING then
            self.abilitys[id] = ability_compound.new(ability)
        elseif id == define.AbilityClass.ABILITY_CLASS_PHARMACY then
            self.abilitys[id] = ability_compound.new(ability)
        elseif id == define.AbilityClass.ABILITY_CLASS_ARTWORK then
            self.abilitys[id] = ability_artwork.new(ability)
        elseif id == define.AbilityClass.ABILITY_CLASS_SHAOLINDRUG then
            self.abilitys[id] = ability_compound.new(ability)
        elseif id == define.AbilityClass.ABILITY_CLASS_HOLYFIRE then
            self.abilitys[id] = ability_compound.new(ability)
        elseif id == define.AbilityClass.ABILITY_CLASS_BREWING then
            self.abilitys[id] = ability_compound.new(ability)
        elseif id == define.AbilityClass.ABILITY_CLASS_THICKICE then
            self.abilitys[id] = ability_compound.new(ability)
        elseif id == define.AbilityClass.ABILITY_CLASS_INSECTCULTURING then
            self.abilitys[id] = ability_compound.new(ability)
        elseif id == define.AbilityClass.ABILITY_CLASS_POISON then
            self.abilitys[id] = ability_compound.new(ability)
        elseif id == define.AbilityClass.ABILITY_CLASS_INCANTATION then
            self.abilitys[id] = ability_compound.new(ability)
        elseif id == define.AbilityClass.ABILITY_CLASS_ALCHEMY then
            self.abilitys[id] = ability_compound.new(ability)
        elseif id == define.AbilityClass.ABILITY_CLASS_THAUMATURGY then
            self.abilitys[id] = ability_compound.new(ability)
        elseif id == define.AbilityClass.ABILITY_CLASS_ENGINEERING then
            self.abilitys[id] = ability_compound.new(ability)
        elseif id == define.AbilityClass.ABILITY_CLASS_REFOUNDRY then
            self.abilitys[id] = ability_compound.new(ability)
        elseif id == define.AbilityClass.ABILITY_CLASS_RETAILOR then
            self.abilitys[id] = ability_compound.new(ability)
        elseif id == define.AbilityClass.ABILITY_CLASS_REARTWORK then
            self.abilitys[id] = ability_compound.new(ability)
        elseif id == define.AbilityClass.ABILITY_CLASS_DINGWEIFU then
            self.abilitys[id] = ability_compound.new(ability)
        elseif id == define.AbilityClass.ABILITY_CLASS_INLAY then
            self.abilitys[id] = ability_in_lay.new(ability)
        elseif id == define.AbilityClass.ABILITY_CLASS_FOUNDRY then
            self.abilitys[id] = ability_foundry.new(ability)
        elseif id == define.AbilityClass.ABILITY_CLASS_TAILOR then
            self.abilitys[id] = ability_tailor.new(ability)
        elseif id == define.AbilityClass.ABILITY_CLASS_GATHERMINE then
            self.abilitys[id] = ability_generic_gather.new(ability)
        elseif id == define.AbilityClass.ABILITY_CLASS_GATHERMEDIC then
            self.abilitys[id] = ability_generic_gather.new(ability)
        elseif id == define.AbilityClass.ABILITY_CLASS_PLANT then
            self.abilitys[id] = ability_generic_gather.new(ability)
        elseif id == define.AbilityClass.ABILITY_CLASS_FIGHTGHOST then
            self.abilitys[id] = ability_generic_gather.new(ability)
        elseif id == define.AbilityClass.ABILITY_CLASS_SEARCHTSTORE then
            self.abilitys[id] = ability_generic_gather.new(ability)
        elseif id == define.AbilityClass.ABILITY_CLASS_PROCESSING then
            self.abilitys[id] = ability_generic_gather.new(ability)
        elseif id == define.AbilityClass.ABILITY_CLASS_GUILD_GATHERMINE then
            self.abilitys[id] = ability_generic_gather.new(ability)
        elseif id == define.AbilityClass.ABILITY_CLASS_FISH then
            self.abilitys[id] = ability_gather_fish.new(ability)
        elseif id == define.AbilityClass.ABILITY_CLASS_NOUSE then
            self.abilitys[id] = ability_generic.new(ability)
        elseif id == define.AbilityClass.ABILITY_CLASS_TRADE then
            self.abilitys[id] = ability_generic.new(ability)
        elseif id == define.AbilityClass.ABILITY_CLASS_HAGGLE then
            self.abilitys[id] = ability_generic.new(ability)
        elseif id == define.AbilityClass.ABILITY_CLASS_EXCESSPROFIT then
            self.abilitys[id] = ability_generic.new(ability)
        elseif id == define.AbilityClass.ABILITY_CLASS_PHARMACOLOGY then
            self.abilitys[id] = ability_generic.new(ability)
        elseif id == define.AbilityClass.ABILITY_CLASS_REGIMEN then
            self.abilitys[id] = ability_generic.new(ability)
        elseif id == define.AbilityClass.ABILITY_CLASS_BUDDHOLOGY then
            self.abilitys[id] = ability_generic.new(ability)
        elseif id == define.AbilityClass.ABILITY_CLASS_FIREMAKING then
            self.abilitys[id] = ability_generic.new(ability)
        elseif id == define.AbilityClass.ABILITY_CLASS_BEGSKILL then
            self.abilitys[id] = ability_generic.new(ability)
        elseif id == define.AbilityClass.ABILITY_CLASS_ICEMAKING then
            self.abilitys[id] = ability_generic.new(ability)
        elseif id == define.AbilityClass.ABILITY_CLASS_VENATIONFORMULA then
            self.abilitys[id] = ability_generic.new(ability)
        elseif id == define.AbilityClass.ABILITY_CLASS_INSECTENTICING then
            self.abilitys[id] = ability_generic.new(ability)
        elseif id == define.AbilityClass.ABILITY_CLASS_MENTALTELEPATHY then
            self.abilitys[id] = ability_generic.new(ability)
        elseif id == define.AbilityClass.ABILITY_CLASS_TAOISM then
            self.abilitys[id] = ability_generic.new(ability)
        elseif id == define.AbilityClass.ABILITY_CLASS_BODYBUILDING then
            self.abilitys[id] = ability_generic.new(ability)
        elseif id == define.AbilityClass.ABILITY_CLASS_NEWPENGREN then
            self.abilitys[id] = ability_compound.new(ability)
        elseif id == define.AbilityClass.ABILITY_CLASS_NEWZHIYAO then
            self.abilitys[id] = ability_compound.new(ability)
        elseif id == define.AbilityClass.ABILITY_CLASS_GONGJVXILIAN then
            self.abilitys[id] = ability_compound.new(ability)
        elseif id == define.AbilityClass.ABILITY_CLASS_GONGCHENG then
            self.abilitys[id] = ability_compound.new(ability)
        elseif id == define.AbilityClass.ABILITY_CLASS_NEW_CAIYAO then
            self.abilitys[id] = ability_generic_gather.new(ability)
        elseif id == define.AbilityClass.ABILITY_CLASS_NEW_CAIKUANG then
            self.abilitys[id] = ability_generic_gather.new(ability)
        else
            self.abilitys[id] = ability_generic.new(ability)
        end
        assert(self.abilitys[id], id)
        self.abilitys[id]:set_ability_enginer(self)
    end
end

function abilityenginer:get_ability(id)
    if not self.loaded_all then self:loadall() end
    return self.abilitys[id]
end

function abilityenginer:get_prescription_list()
    local prescription_list = configenginer:get_config("item_compound")
    return prescription_list
end

function abilityenginer:set_scene(scene) self.scene = scene end

function abilityenginer:get_scene()
    return self.scene
end

return abilityenginer
