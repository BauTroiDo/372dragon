-- Source-backed phase2 Tao callbacks. No legacy Mission328/329/351 storage.
-- Integration supplies only certified live capabilities and complete ID maps.
local num=require 'cy_four_combat.numeric'
local callbacks=require 'cy_four_combat.callbacks'
local M={}
M.required_literal_impacts={4400,4549,4543,4518,4517}
M.native_skills={3801,3804,3809,3820,3822}
local capabilities={
 [3801]={'is_human','position','create_doll','special','send_specific','send_specific_delay','has_impact','charge','cooldown','set_cooldown','float2int'},
 [3804]={'is_human','position','charge','cooldown','set_cooldown','special','send_specific_delay','float2int'},
 [3809]={'is_human','position','scan_characters','is_enemy','send_specific','do_action'},
 [3820]={'is_human','send_specific','do_action'},
 [3822]={'is_human','position','scan_characters','is_enemy','send_specific','do_action','charge','in_impact_collection'},
}
local refs={
 [3801]={impacts={4267,4268,4269,4270,4271,4345},special_objects={936},monsters={17097}},
 [3804]={impacts={4372},special_objects={939}},
 [3809]={impacts={4400}},[3820]={impacts={4549,4543}},
 [3822]={impacts={4400,4518,4517},collections={281}},
}
local function finite(v)return type(v)=='number' and v==v and math.abs(v)<math.huge end
local function pos(p)assert(p and finite(p.x) and finite(p.y),'finite position');return{x=p.x,y=p.y}end
function M.new(c,map)
 assert(type(c)=='table' and type(map)=='table')
 local self={context=c,mapping=map,reverse={}}
 for _,source in ipairs(M.native_skills)do
  local target=(map.skill_templates or {})[source]
  if target then assert(not self.reverse[target],'duplicate template mapping');self.reverse[target]=source end
 end
 function self:ref(kind,id)return assert((map[kind] or {})[id],'unmapped '..kind..':'..id)end
 function self:ready(source)
  if not capabilities[source] then return false,'outside_bounded_port'end
  if type(c.menpai)~='function' or not(map.faction or {})[13]then return false,'missing_faction_binding'end
  for _,name in ipairs(capabilities[source])do if type(c[name])~='function'then return false,'missing_adapter:'..name end end
  for kind,ids in pairs(refs[source])do for _,id in ipairs(ids)do if not(map[kind] or {})[id]then return false,'missing_reference:'..kind..':'..id end end end
  if source==3801 and c.summon_lifecycle_verified~=true then return false,'summon_lifecycle_unverified'end
  if source==3820 and c.logic168_verified~=true then return false,'logic168_unverified'end
  return true
 end
 function self:doll(owner)
  local id=callbacks.get_doll_id(owner)
  return id>=0 and owner:get_scene():get_obj_by_id(id) or nil
 end
 function self:send(target,owner,id,delay)
  if delay~=nil then return c:send_specific_delay(target,owner,self:ref('impacts',id),delay)end
  return c:send_specific(target,owner,self:ref('impacts',id))
 end
 function self:special(owner,id,p)return c:special(owner,self:ref('special_objects',id),pos(p),0)end
 function self:increase_layers(owner)
  for id=4267,4271 do
   if c:has_impact(owner,self:ref('impacts',id)) then self:send(owner,owner,math.min(id+1,4271));return end
  end
  self:send(owner,owner,4267)
 end
 function self:call_doll(owner,requested)
  local p=pos(requested);local o=pos(c:position(owner))
  if p.x<0 or p.x>512 then p.x=o.x end
  if p.y<0 or p.y>512 then p.y=o.y end
  if math.floor(math.sqrt((p.x-o.x)^2+(p.y-o.y)^2))>15 then return false,'too_far'end
  -- create_doll must install the certified NPC timer/lifecycle and actual visual.
  -- A source configuration is passed rather than guessing a generic NPC profile.
  local doll=c:create_doll(owner,self:ref('monsters',17097),p,{base_ai=6,ai_file=-1,source_script=808281,timer_ms=1000})
  if not doll then return false,'spawn_failed'end
  callbacks.set_doll(owner,doll)
  self:send(owner,owner,4267,0);self:send(owner,owner,4345,0)
  for _,v in ipairs({{170,5000},{58,15000}})do
   local cd=c:cooldown(owner,v[1]);if cd>=v[2]then c:set_cooldown(owner,v[1],cd-v[2])end
  end
  self:special(owner,936,p);return true
 end
 function self:on_skill_success(owner,target_skill,click)
  local source=self.reverse[target_skill];if not source then return false,'outside_bounded_port'end
  local ready,why=self:ready(source);if not ready then return false,why end
  if not owner or not c:is_human(owner) or not owner:get_scene()then return false,'no_human_scene'end
  if c:menpai(owner)~=self:ref('faction',13)then return false,'wrong_faction'end
  local doll=self:doll(owner)
  if source==3801 then
   local p=pos(click);p.x=c:float2int(p.x);p.y=c:float2int(p.y)
   if not doll then
    local ok,reason=self:call_doll(owner,p)
    -- The donor success hook advances layers even if Lua rejects the location.
    self:increase_layers(owner);return ok,reason
   end
   c:charge(doll,pos(click),1);self:special(owner,936,p);return true
  end
  if not doll then return false,'no_doll'end
  if source==3804 then
   for _,v in ipairs({{171,58},{172,170}})do local cd=c:cooldown(owner,v[1]);if cd>0 then c:set_cooldown(owner,v[2],cd)end end
   local p=pos(c:position(owner));c:charge(doll,p,1)
   p.x=c:float2int(p.x);p.y=c:float2int(p.y)
   self:special(owner,939,p);self:send(owner,owner,4372,500)
   -- Delayed fade clears shared state; the native lifecycle removes the doll.
  elseif source==3820 then
   c:do_action(doll,167,doll:get_obj_id());self:send(doll,owner,4549);self:send(owner,owner,4543)
  else
   local center=pos(c:position(doll));local count=0
   -- Return ordering must match the existing native-style scan (limit50,radius5).
   for _,target in ipairs(c:scan_characters(owner,center,50,5))do
    if target and c:is_enemy(owner,target)then
     if source==3822 then c:charge(target,center,1)end
     self:send(target,owner,4400)
     if source==3822 then
      local member=c:in_impact_collection(target,self:ref('collections',281),0)
      if member==1 then self:send(target,owner,4518)elseif member==0 then self:send(target,owner,4517)end
     end
     count=count+1;if count>=(source==3809 and 1 or 6)then break end
    end
   end
   c:do_action(doll,source==3809 and 165 or 166,doll:get_obj_id())
  end
  return true
 end
 -- Native168 fade callback's Lua body. Humans are selected before monsters.
 function self:li_kai_ro(owner,damage)
  local doll=self:doll(owner);if not doll then return false,'no_doll'end
  assert(type(c:humans(owner))=='table' and type(c:monsters(owner))=='table','ordered scene populations')
  local chosen={};local center=pos(c:position(doll))
  for _,list in ipairs({c:humans(owner),c:monsters(owner)})do
   for _,target in ipairs(list)do
    if #chosen>=6 then break end
    if target~=owner and target~=doll and c:is_valid(target) and c:is_alive(target) and c:is_enemy(owner,target)
       and c:is_in_distance(target,center,5)then chosen[#chosen+1]=target end
   end
  end
  -- Source draws random(#chosen) into an unused local before the loop.
  if #chosen>0 then c:random(#chosen)end
  for _,target in ipairs(chosen)do c:damage_ex(owner,target,self:ref('impacts',4515),0,damage)end
  return true
 end
 function self:tick_doll(doll)
  -- 0xa1432. GUID numeric ranges belong to the donor; the adapter validates the
  -- retained owner identity against the current server's scene object registry.
  if not doll or not doll:get_scene()then return false,'no_doll_scene'end
  local tag=doll._cy_four_summon
  local owner=c:resolve_owner(tag)
  if not owner or not c:is_human(owner)then c:set_die_time(doll,200);return true,'owner_gone'end
  if not owner:get_scene()then return false,'owner_no_scene'end
  if c:has_impact(doll,self:ref('impacts',4549))then
   c:do_action(doll,167,doll:get_obj_id())
   if not c:has_impact(owner,self:ref('impacts',4543))then
    c:do_action(doll,0,doll:get_obj_id());c:dispel_specific(doll,self:ref('impacts',4549),1)
   end
   -- Source exits here even when far away or the recall flag has been cleared.
   return true,'active_dance'
  end
  local p,o=pos(c:position(doll)),pos(c:position(owner))
  local dx,dy=num.f32(p.x)-num.f32(o.x),num.f32(p.y)-num.f32(o.y)
  local far=num.f32(dx*dx+dy*dy)>180.0
  if far or doll:get_scene()~=owner:get_scene()then
   c:set_die_time(doll,200);callbacks.clear_doll(owner)
   return true,far and 'too_far' or 'scene_changed'
  end
  local state=callbacks.state(owner)
  if state.doll_id<0 then c:set_die_time(doll,200);return true,'recalled'end
  return true,'retained'
 end
 return self
end

-- These three native168 methods are ported. A talent138 setter is proven, but
-- the complete amount producer has not been verified: no invented accumulation.
M.logic168_complete=false
function M.init_168(state)state.damage=0;return true end
function M.fade_168(c,state,owner)
 if state.damage<=0 or state.elapsed>9999 or not c:is_human(owner) or not owner:get_scene()then return false end
 return c:li_kai_ro(owner,state.damage)
end
function M.continuance_168(c,state,owner,delta)
 if state.duration==-1 then return end
 local elapsed=state.elapsed
 if elapsed<=state.duration then elapsed=num.i32(elapsed+delta)end
 -- The callback runs before elapsed is written back, matching0x68af0/0x68af9.
 if elapsed>state.duration then c:expire_impact(owner,state)end
 state.elapsed=elapsed
end
-- Native0xa08e2 runs only for source4504..4515 after normal damage construction.
function M.scale_tao_damage(source_id,descriptor7,damages)
 if source_id<4504 or source_id>4515 or descriptor7<=0 then return damages end
 for i=1,6 do
  if damages[i]>0 then damages[i]=num.float2int(num.f32(num.f32(num.i32(damages[i]*descriptor7))/100))end
 end
 return damages
end
return M
