-- Bounded port of donor MenPai_14::OnFiltrateImpact, a2acb..a2c84.
-- The incoming marker13264 advances every existing13263 instance. It does
-- not create171 or substitute for the rest of the faction's filter hooks.
local M={}
function M.advance(context,state,owner)
 assert(state.donor_id==13263,'only verified combo171 state is accepted')
 local duration=assert(math.tointeger(state.params[0]))
 assert(duration>=0,'invalid combo duration')
 context:set_duration(state,duration)
 context:reset_elapsed(state)
 state.timer=duration
 state.phase=math.min(3,(state.phase or 0)+1)
 if state.phase==2 then context:swap_skill(owner,state.params[3],state.params[4],1,0) end
 return state.phase
end
function M.on_filtrate(bridge,owner,incoming)
 local config=bridge.config
 if config.gameplay_enabled~=true or config.jue_combo_verified~=true then return 0 end
 local c=bridge.context
 if not owner or not c:is_human(owner) or not c:has_scene(owner) then return 0 end
 if incoming:get_data_index()~=config.resolve.impacts[13264] then return 0 end
 -- MenPai_T::OnFiltrateImpact dispatches on the same-scene caster, not
 -- the receiver. The receiver still must be human for the bounded171 port.
 local caster=c:get_object(owner,incoming:get_caster_obj_id())
 if not c:is_human(caster) or c:donor_faction(caster)~=14 then return 0 end
 local count=0
 for _,imp in ipairs(owner:get_impact_list())do
  if imp:get_data_index()==config.resolve.impacts[13263] then
   M.advance(c,bridge:state(imp),owner);count=count+1
  end
 end
 return count
end
return M
