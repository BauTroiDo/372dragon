-- Host bindings for the verified summon/move/recall branches.
local M={}
function M.prepare(config,base)
 local Runtime=require 'cy_four_combat.summon_runtime'
 local callbacks=require 'cy_four_combat.callbacks'
 local c={summon_lifecycle_verified=true,logic168_verified=config.tao_logic168_verified==true or config.tao_logic168_base_ready==true}
 local port
 function c:is_human(o)return base:is_human(o)end
 function c:menpai(o)return o:get_menpai()end
 function c:position(o)return base:position(o)end
 function c:send_specific(o,s,id)return base:send_specific(o,s,id)end
 function c:send_specific_delay(o,s,id,d)return base:send_specific_delay(o,s,id,d)end
 function c:has_impact(o,id)return base:has_impact(o,id)end
 function c:float2int(v)return base:float2int(v)end
 function c:cooldown(o,id)return o:get_cool_down(id)end
 function c:set_cooldown(o,id,ms)return o:set_cool_down(id,ms)end
 function c:charge(o,p,mode)assert(mode==1);return o:skill_charge(p)end
 function c:special(o,id,p,duration)
  local obj=o:skill_create_obj_specail(p,id)
  if obj then obj:set_continuance(duration)end
  return obj
 end
 function c:create_doll(o,id,p,profile)
  return Runtime.spawn(o,id,p,{base_ai=profile.base_ai,ai_file=profile.ai_file,
   source_script=profile.source_script,interval=profile.timer_ms,name='Con rối'},function(obj)port:tick_doll(obj)end)
 end
 function c:resolve_owner(tag)return Runtime.resolve_owner(tag)end
 function c:set_die_time(o,ms)return o:set_die_time(ms)end
 function c:scan_characters(o,p,count,radius)return base:scan(o,p,count,radius)end
 function c:is_enemy(o,t)local v=base:is_enemy(o,t);return v==true or v==1 end
 function c:in_impact_collection(o,id)return base:in_collection(o,id)end
 function c:dispel_specific(o,id)return base:dispel_impact(o,id)end
 -- do_action is deliberately absent until the GL packet has been verified.
 if config.tao_action_packet_verified then
  assert(type(base.do_action)=='function','verified Tao action adapter required')
  function c:do_action(...)return base:do_action(...)end
 end
 port=require('cy_four_combat.tao').new(c,config.resolve)
 local out={port=port,context=c}
 function out:on_use_skill_successfully(owner,info)
  if config.gameplay_enabled~=true then return false,'gameplay_gated' end
  return port:on_skill_success(owner,info:get_skill_id(),owner:get_targeting_and_depleting_params():get_target_position())
 end
 return out
end
return M
