-- Imported skill IDs are isolated; existing skills bypass this content gate.
local M={}
function M.allowed(owner,skill_id,config)
    if not config.donor_skill_templates[skill_id] then return true end
    if config.gameplay_enabled~=true then return false end
    if config.disabled_skills and config.disabled_skills[skill_id] then return false end
    if not owner or owner:get_obj_type()~='human' then return false end
    local faction=config.template_factions and config.template_factions[skill_id]
    if not faction or owner:get_menpai()~=faction then return false end
    if not require("cy_four_combat.jue_cast_guard").allowed(owner,skill_id,config) then return false end
    local define=require 'define'
    local registry=require 'menpai_registry'
    return registry.check_ready(define,faction,function(key)
        return require('configenginer'):getinstance():get_config(key)
    end)
end
return M
