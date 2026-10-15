-- Base-four-faction release. Missing donor Lua808280 is replaced by the
-- documented landing effect, not advertised as recovered native code.
local M={}
local callbacks=require 'cy_four_combat.callbacks'
local num=require 'cy_four_combat.numeric'
function M.configure(c)
 if c.release_configured then return end
 local delta=require 'cy_four_combat.release_config'
 for source,target in pairs(delta.resolve.impacts)do
  assert(not c.resolve.impacts[source]);c.resolve.impacts[source]=target
 end
 for target,row in pairs(delta.impacts)do assert(not c.impacts[target]);c.impacts[target]=row end
 c.tao_damage_scaling=delta.tao_damage_scaling
 -- 168's only confirmed amount writer is talent138. This release has no
 -- donor talents: initialize zero, preserve its channel lifetime, never invent
 -- an absorption/accumulation mechanic from the unused conversion descriptor.
 assert(c.talents_enabled==false,'base168 requires the base talent profile')
 c.disabled_logic_ids[168]=nil
 c.disabled_impacts[c.resolve.impacts[4543]]=nil
 c.tao_logic168_base_ready=true
 c.tao_landing_replacement=true
 c.release_configured=true
end
local function bridge(owner)
 local scene=owner and owner:get_scene()
 local engine=scene and scene:get_impact_enginer()
 local b=engine and engine.cy_four_bridge
 if b and b.config.gameplay_enabled==true then return b end
end
function M.target_list(logic,owner,info)
 local b=bridge(owner);if not b then return nil end
 local map=b.config.resolve.skill_templates;local id=info:get_skill_id()
 local center
 -- Quai/tran thu khong co get_menpai: chi nguoi choi moi vao nhanh CY.
 local menpai=(owner.get_menpai and owner:get_menpai()) or -1
 if id==map[3820] and menpai==13 then
  local doll=callbacks.get_doll_id(owner)
  local obj=doll>=0 and owner:get_scene():get_obj_by_id(doll)
  if not obj then return {} end
  center=obj:get_world_pos()
 elseif menpai==14 and (id==map[3842] or id==map[3846] or id==map[3847] or id==map[3851]) then
  center=owner:get_world_pos()
 else return nil end
 return logic:scan_unit_for_target(owner,center.x,center.y)
end
function M.scale_damage(owner,imp,logic)
 local b=bridge(owner);local row=b and b.config.tao_damage_scaling[imp:get_data_index()]
 if not row or owner:get_obj_type()~='human' or owner:get_menpai()~=13 then return end
 for _,name in ipairs({'phy','magic','cold','fire','light','posion'})do
  local v=logic['get_damage_'..name](logic,imp)
  if v>0 then logic['set_damage_'..name](logic,imp,num.scale(num.float2int(v),row,100,num.float2int))end
 end
end
function M.landing(owner,b)
 local c=b.context;local map=b.config.resolve.impacts
 if not c:is_human(owner) or owner:get_menpai()~=13 or not owner:is_alive() then return false end
 local doll=callbacks.get_doll_id(owner)
 local obj=doll>=0 and owner:get_scene():get_obj_by_id(doll)
 if not obj then return false end
 local count=0
 for _,target in ipairs(c:scan(owner,obj:get_world_pos(),50,5))do
  if target~=owner and target~=obj and target:is_alive() and c:is_enemy(owner,target) then
   local imp=c:new_data_impact(target,map[4346],0)
   -- All twelve source tooltips specify 100 direct damage, five targets.
   -- Keep the real impact event path (immunity/death/attribution included).
   imp._cy_four_landing_direct=100
   imp:set_skill_id(b.config.resolve.skill_templates[3801])
   c:emit_impact(target,owner,imp,10,imp:get_skill_id(),true)
   if target:get_obj_type()=='human' then c:send_specific(target,owner,map[4347])end
   count=count+1;if count==5 then break end
  end
 end
 return true
end
function M.dark_wound(attacker,target,mind_defend)
 local b=bridge(attacker)
 if not b or attacker:get_obj_type()~='human' or attacker:get_menpai()~=13 or target:get_obj_type()~='human' then return mind_defend end
 local id=b.config.resolve.impacts[4347]
 for _,imp in ipairs(target:get_impact_list())do
  if imp:get_data_index()==id and imp:get_caster_obj_id()==attacker:get_obj_id()
   and not imp:get_is_out() and not imp:is_fade_out() and imp:get_continuance_elapsed()<imp:get_continuance() then
   return math.max(0,mind_defend-math.min(attacker:get_mind_attack()*0.4,mind_defend*0.8))
  end
 end
 return mind_defend
end
function M.install(b)
 local c=b.context;local previous_exists=c.script_exists;local previous_fade=c.script_on_impact_fade
 function c:script_exists(owner,id,fn)
  if id==808280 and fn=='OnImpactFadeOut' then return true end
  return previous_exists(self,owner,id,fn)
 end
 function c:script_on_impact_fade(owner,id,target)
  if id==808280 then
   local row=b.config.impacts[target]
   if not row or row.donor_id<4333 or row.donor_id>4344 then return false end
   return M.landing(owner,b)
  end
  return previous_fade(self,owner,id,target)
 end
end
return M
