-- Server-side enforcement of the three temporary skills projected by combo171.
-- This is an explicit integrity rule for the port, not a claim that the donor
-- enforced the same rule in CommonConditionCheck. State comes from real171;
-- requests never create/advance an impact or spend resources here.
local M={}
local function live(imp,state,source)
 return state and state.donor_id==source and state.target_id==imp:get_data_index()
  and state.engine_impact==imp and not imp:get_is_out() and not imp:is_fade_out()
  and imp:get_continuance()>0 and imp:get_continuance_elapsed()<imp:get_continuance()
end
function M.allowed(owner,skill_id,config)
 if config.gameplay_enabled~=true then return true end
 local m=config.resolve.skill_templates
 local source,phase
 if skill_id==m[3842] then source=13262
 elseif skill_id==m[3846] then source=13263;phase=1
 elseif skill_id==m[3847] then source=13263;phase=2
 else return true end
 if not owner or owner:get_obj_type()~='human' or not owner:get_scene()
  or owner:get_menpai()~=config.resolve.faction[14] then return false end
 local target=assert(config.resolve.impacts[source])
 for _,imp in ipairs(owner:get_impact_list())do
  if imp:get_data_index()==target then
   local state=require("cy_four_combat.state_cache")[imp]   -- skill-logic guard
   if live(imp,state,source) and (not phase or state.phase==phase) then return true end
  end
 end
 return false
end
function M.recheck(owner,skill_info)
 local scene=owner:get_scene()
 local engine=scene and scene:get_impact_enginer()
 local bridge=engine and engine.cy_four_bridge
 if not bridge or M.allowed(owner,skill_info:get_skill_id(),bridge.config) then return true end
 owner:get_targeting_and_depleting_params():set_errcode(require('define').OPERATE_RESULT.OR_U_CANNT_DO_THIS_RIGHT_NOW)
 return false
end
return M
