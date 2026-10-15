-- Optional phase2 composition; phase1 remains unmodified and gated.
local M={}
local N=require 'cy_four_combat.numeric'
function M.prepare(config,base)
 local GuiGu=require 'cy_four_combat.guigu'
 local Summon=require 'cy_four_combat.summon_runtime'
 local ctx=require('cy_four_combat.guigu_adapter').new(config,base,Summon)
 local ok,missing=GuiGu.readiness(config,ctx)
 for _,profile in pairs(GuiGu.profiles)do
  if not(config.resolve.monsters and config.resolve.monsters[profile.monster])then missing[#missing+1]='monsters:'..profile.monster end
 end
 if #missing>0 then return nil,missing end
 local timers=GuiGu.new(config,ctx)
 local callbacks=require 'cy_four_combat.callbacks'
 local names={[808254]='Trường Sinh Trận',[808255]='Phá Quân Trận',[808256]='Âm Dương Trận',[808257]='Thất Sát Trận',[808258]='Tham Lang Trận'}
 local function spawn(owner,desc,pos,tier)
  local p=assert(GuiGu.profiles[desc.script],'unknown verified formation')
  if config.gameplay_enabled~=true then return false,'gameplay_gated' end
  if (desc.script==808256 or desc.script==808258) and config.guigu_aura_payload_verified~=true then
   return false,'aura_payload_unverified'
  end
  assert(tier>=1 and tier<=12,'source twelve-tier formation')
  local profile={source_script=desc.script,interval=p.interval,life=p.life,phase=p.phase,
   base_ai=6,ai_file=-1,int_params=desc.int1~=nil and {[1]=desc.int1} or {},name=names[desc.script]}
  return Summon.spawn(owner,config.resolve.monsters[p.monster],pos,profile,function(obj,id)timers:tick(obj,id)end)~=nil
 end
 local reverse={};for donor,target in pairs(config.resolve.impacts)do reverse[target]=donor end
 local adapters=callbacks.build_adapters{donor_impact_by_target=reverse,special_objects=config.resolve.special_objects,
  formations_verified=true,spawn_formation=spawn,set_cooldown=function(owner,id,ms)owner:set_cool_down(id,ms)end,
  float2int=N.float2int,
  send_specific_delay=function(owner,id,delay)return base:send_specific_delay(owner,owner,id,delay)end,
  teleport_position=function(owner,pos)return owner:on_teleport(pos)end}
 local target_skills={}
 for _,profile in pairs(GuiGu.profiles)do target_skills[config.resolve.skill_templates[profile.skill]]=true end
 function timers:on_use_skill_successfully(owner,info)
  if config.gameplay_enabled~=true or owner:get_obj_type()~='human' or not owner:get_scene() or owner:get_menpai()~=config.resolve.faction[12] then return false end
  if not target_skills[info:get_skill_id()]then return false end
  local pos=owner:get_targeting_and_depleting_params():get_target_position()
  local numeric=require 'cy_four_combat.numeric'
  callbacks.start_xin_zhen(owner,numeric.float2int(pos.x),numeric.float2int(pos.y))
  return true
 end
 timers.callback_adapters=adapters
 return timers,{}
end
return M
