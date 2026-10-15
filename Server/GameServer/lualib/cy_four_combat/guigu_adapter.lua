-- Host engine bindings for the recovered GuiGu timers. No live file patching.
-- Shared healing, damage, piercing and hostility keep this world's rules.
local N=require 'cy_four_combat.numeric'
local M={}
function M.new(config,base,summon)
 local ctx={}
 function ctx:resolve(kind,id)return assert(config.resolve[kind][id],kind..':'..id)end
 function ctx:owner(obj)
  local owner=summon.resolve_owner(obj._cy_four_summon)
  if not owner or not obj:get_scene() or owner:get_scene()~=obj:get_scene() then return nil end
  return owner
 end
 function ctx:phase(obj)return assert(obj._cy_four_summon,'owned formation required').phase or 0 end
 function ctx:set_phase(obj,value)
  obj._cy_four_summon.phase=value
  obj.ai:set_int_param_by_index(1,value)
 end
 function ctx:set_die_time(obj,value)return obj:set_die_time(value)end
 function ctx:position(obj)return obj:get_world_pos()end
 function ctx:party_targets(owner)
  local team=owner:get_team_info()
  if not team or not team:has_team() then return {owner} end
  -- Host scene_members excludes self, unlike the donor's complete roster.
  local targets={owner};local seen={[owner]=true};local scene=owner:get_scene()
  for i=1,team:get_scene_member_count()do
   local obj=scene:get_obj_by_id(team:get_scene_member_obj_id(i))
   if obj and obj:get_scene()==scene and not seen[obj] then targets[#targets+1]=obj;seen[obj]=true end
  end
  return targets
 end
 function ctx:max_hp(owner)return owner:get_attrib('hp_max')end
 function ctx:send_specific(target,caster,id)return base:send_specific(target,caster,id)end
 function ctx:matching_impacts(owner,id,caster)
  local found={};local scene=owner:get_scene()
  for _,imp in ipairs(owner:get_impact_list())do
   if imp:get_data_index()==id and (not caster or (imp:get_caster_obj_id()~=0 and scene:get_obj_by_id(imp:get_caster_obj_id())==caster))then found[#found+1]=imp end
  end
  return found
 end
 function ctx:expire(imp)return imp:set_continuance(0)end
 function ctx:heal(owner,target,amount,skill)
  target:health_increment(amount,owner,false,nil,skill)
  owner:on_heal_target(skill,amount,target:get_obj_id())
 end
 function ctx:target(owner)
  local id=owner:get_targeting_and_depleting_params():get_target_obj()
  if id<=0 then return nil end
  return owner:get_scene():get_obj_by_id(id)
 end
 function ctx:attack_elements(owner)return {owner:get_attack_cold(),owner:get_attack_fire(),owner:get_attack_light(),owner:get_attack_posion()}end
 function ctx:damage(owner,target,amount,skill)
  -- Actual health_increment adds get_chuanci_damage when param_skill!=-1,
  -- then routes direct damage and piercing through on_damages once.
  return target:health_increment(-amount,owner,false,nil,skill)
 end
 function ctx:target_visual(formation,owner,target,skill)
  local packet=require('game.packet').GCTargetListAndHitFlags.new()
  packet.data_type=0;packet.m_objID=formation:get_obj_id();packet.logic_count=formation:get_logic_count()
  packet.skill_or_special_obj_id=skill;packet.target_pos=target:get_world_pos()
  packet.unknow_1=N.float2int(N.f32(N.f32(owner:get_targeting_and_depleting_params():get_target_dir())*255))&255
  packet.size=1;packet.target_list={target:get_obj_id()}
  local scene=formation:get_scene()
  require('skynet').fork(function()if formation:get_scene()==scene then scene:broadcast(formation,packet,true)end end)
 end
 function ctx:scan(owner,center,count,radius)return base:scan(owner,center,count,radius)end
 function ctx:enemy(owner,target)local v=base:is_enemy(owner,target);return v==true or v==1 end
 function ctx:has_impact(owner,id)return base:has_impact(owner,id)end
 return ctx
end
return M
