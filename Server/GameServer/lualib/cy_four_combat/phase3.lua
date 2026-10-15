-- Per-scene wiring for the bounded Jue combo port. Global gameplay and native
-- acceptance remain separate gates; configuring the module never enables them.
local M={}
function M.configure(config)
 if config.phase3_configured then return config end
 if config.gl_ui_swap_verified==true and config.jue_combo_verified==true then
  config.disabled_logic_ids[171]=nil
  for _,source in ipairs({13262,13263})do
   config.disabled_impacts[assert(config.resolve.impacts[source])]=nil
  end
 else
  config.disabled_skills=config.disabled_skills or {}
  -- All follow-ups are learned with their xinfa. Gate them as well as the
  -- base casts until cast conditions/resource prechecks are accepted.
  for _,source in ipairs({3840,3842,3851,3846,3847})do
   config.disabled_skills[assert(config.resolve.skill_templates[source])]='Jue combo native acceptance pending'
  end
 end
 config.phase3_configured=true
 return config
end
local function bridge_for(owner)
 if not owner then return nil end
 local scene=owner:get_scene()
 local engine=scene and scene:get_impact_enginer()
 return engine and engine.cy_four_bridge
end
function M.on_filtrate(owner,incoming)
 local bridge=bridge_for(owner)
 if not bridge or bridge.config.gameplay_enabled~=true then return 0 end
 return require('cy_four_combat.jue_combo').on_filtrate(bridge,owner,incoming)
end
function M.setting(owner,modify)
 local bridge=bridge_for(owner)
 if not bridge then return modify.setting end
 return require('cy_four_combat.quickbar_projection').setting(owner,modify,bridge.config)
end
return M
