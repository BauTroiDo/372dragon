-- Five native-dispatched formation timers, recovered from Serverhook.so.
-- All IDs here are donor identities and resolve through an explicit phase2 map.
local N=require 'cy_four_combat.numeric'
local M={}
M.profiles={
 [808254]={monster=16916,interval=3000,life=30000,phase=0,skill=3438},
 [808255]={monster=16917,interval=1000,life=10000,skill=3439},
 [808256]={monster=16918,interval=1000,life=10000,phase=0,skill=3447},
 [808257]={monster=16927,interval=2000,life=15000,skill=3451},
 [808258]={monster=16928,interval=1000,life=15000,phase=0,skill=3453},
}
M.required_impacts={4079,4251,4258,4259,4260}
M.required_skills={3430,3438,3439,3447,3451,3453}
local methods={'owner','phase','set_phase','set_die_time','position','party_targets','max_hp',
 'send_specific','matching_impacts','expire','heal','target','attack_elements','damage',
 'target_visual','scan','enemy','has_impact','resolve'}
function M.readiness(config,ctx)
 local missing={}
 if config.talents_enabled~=false then missing[#missing+1]='base release requires talents_enabled=false' end
 for _,name in ipairs(methods)do if type(ctx[name])~='function' then missing[#missing+1]=name end end
 for _,kind in ipairs({'impacts','skill_templates'})do
  for _,id in ipairs(kind=='impacts' and M.required_impacts or M.required_skills)do
   if not(config.resolve and config.resolve[kind] and config.resolve[kind][id])then missing[#missing+1]=kind..':'..id end
  end
 end
 return #missing==0,missing
end
local function square_distance(ctx,a,b)
 local p,q=ctx:position(a),ctx:position(b)
 local x=N.f32(N.f32(p.x)-N.f32(q.x));local y=N.f32(N.f32(p.y)-N.f32(q.y))
 return N.f32(N.f32(x*x)+N.f32(y*y))
end
M.square_distance=square_distance
local function cvttsd(value)
 if value~=value or value>=2147483648 or value< -2147483648 then return -2147483648 end
 return N.trunc(value)
end
function M.new(config,ctx)
 local ok,missing=M.readiness(config,ctx);assert(ok,table.concat(missing,', '))
 local out={config=config,context=ctx}
 local function send(target,formation,id)return ctx:send_specific(target,formation,ctx:resolve('impacts',id))end
 local function clear(target,formation,id,check_caster)
  for _,imp in ipairs(ctx:matching_impacts(target,ctx:resolve('impacts',id),check_caster and formation or nil))do ctx:expire(imp)end
 end
 function out:tick(formation,script)
  if config.gameplay_enabled==false then return false,'gameplay_gated' end
  assert(M.profiles[script],'unknown formation timer')
  local owner=ctx:owner(formation)
  if not owner then ctx:set_die_time(formation,200);return false,'owner_missing' end
  local phase=ctx:phase(formation)
  if script==808254 then
   -- Source computes i32(maxHP*3), then SSE single division and Float2Int.
   local amount=N.scale(ctx:max_hp(owner),3,100,N.float2int)
   for _,target in ipairs(ctx:party_targets(owner))do
    local distance=square_distance(ctx,formation,target)
    if distance<100 and phase==0 then send(target,formation,4079)end
    if distance<100 and (phase==0 or phase==1) then
     -- SendSpecific schedules10ms; first tick heals only a pre-existing aura.
     for _ in ipairs(ctx:matching_impacts(target,ctx:resolve('impacts',4079),formation))do
      ctx:heal(owner,target,amount,ctx:resolve('skill_templates',3438))
     end
    elseif distance>100 and phase==1 then clear(target,formation,4079,true) end
   end
   ctx:set_phase(formation,1)
  elseif script==808255 then
   local target=ctx:target(owner)
   if not target then return false,'no_target' end
   if square_distance(ctx,formation,target)>100 then return false,'out_of_range' end
   ctx:target_visual(formation,owner,target,ctx:resolve('skill_templates',3430))
   local sum=0
   for _,v in ipairs(ctx:attack_elements(owner))do sum=N.i32(sum+N.i32(v))end
   -- Native uses double0.4 and CVTTSD2SI, not Float2Int/ceil.
   ctx:damage(owner,target,cvttsd(sum*0.4),ctx:resolve('skill_templates',3439))
  elseif script==808256 then
   local distance=square_distance(ctx,formation,owner)
   if distance<100 and phase==0 then send(owner,formation,4251)
   elseif distance>100 and phase==1 then
    -- Unlike ChangSheng/TanLang, source YinYang clears every4251 caster.
    clear(owner,formation,4251,false)
   end
   ctx:set_phase(formation,1)
  elseif script==808257 then
   local amount=N.scale(ctx:max_hp(owner),1,100,N.float2int)
   local targets=ctx:scan(owner,ctx:position(formation),50,10)
   -- Native increments its limit for EVERY scanned entry, including friends.
   -- Six entries are examined (break after count>5), not six hostile hits.
   for index=1,math.min(6,#targets)do
    local target=targets[index]
    if ctx:enemy(owner,target) then
     if not ctx:has_impact(target,ctx:resolve('impacts',4258))then send(target,formation,4258)end
     if ctx:has_impact(target,ctx:resolve('impacts',4258))then send(target,formation,4259)end
     ctx:damage(owner,target,amount,ctx:resolve('skill_templates',3451))
    end
   end
  else
   for _,target in ipairs(ctx:party_targets(owner))do
    local distance=square_distance(ctx,formation,target)
    if distance<100 and phase==0 then send(target,formation,4260)
    elseif distance>100 and phase==1 then clear(target,formation,4260,true)end
   end
   ctx:set_phase(formation,1)
  end
  return true
 end
 return out
end
return M
