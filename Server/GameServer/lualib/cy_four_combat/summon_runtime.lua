-- Instance-scoped adapter for verified native summon timers.
-- Uses existing scene/monster APIs; never changes the global monster update loop.
local M={}
local function positive(v)return type(v)=='number' and v>0 and v<math.huge end
function M.resolve_owner(tag)
 local owner=tag and tag.owner
 if not owner or owner:get_guid()~=tag.guid then return nil end
 local scene=owner:get_scene()
 -- A disconnected/recycled object must not stay alive merely through our tag.
 if not scene or scene:get_obj_by_id(owner:get_obj_id())~=owner then return nil end
 if owner.is_alive and not owner:is_alive() then return nil end
 return owner
end
function M.attach(obj,owner,profile,tick)
 assert(obj:get_scene()==owner:get_scene(),'summon scene mismatch')
 assert(positive(profile.interval) and type(tick)=='function','verified interval/timer required')
 assert(not obj._cy_four_summon,'summon timer already installed')
 local original=assert(obj.update,'native live monster update required')
 local tag={owner=owner,guid=owner:get_guid(),scene=obj:get_scene(),source_script=profile.source_script,
  interval=profile.interval,elapsed=0,phase=profile.phase or 0}
 obj._cy_four_summon=tag
 -- Native dispatch replaces Lua callbacks for these six IDs. No duplicate timer.
 obj:set_script_timer(0)
 obj.is_unconstrained_monster=true
 function obj:update(delta,...)
  assert(type(delta)=='number' and delta>=0 and delta<math.huge,'finite delta')
  if not self:get_scene() then return end
  if self:get_scene() then
   tag.elapsed=tag.elapsed+delta
   if tag.elapsed>=tag.interval then tag.elapsed=0;tick(self,tag.source_script)end
  end
  return original(self,delta,...)
 end
 return tag
end
function M.spawn(owner,monster_id,p,profile,tick)
 local scene=owner:get_scene();if not scene then return nil end
 assert(positive(monster_id) and positive(profile.interval),'allocated monster and timer required')
 assert(monster_id==math.floor(monster_id) and monster_id<=65535,'monster wire ID')
 assert(p and type(p.x)=='number' and type(p.y)=='number' and p.x==p.x and p.y==p.y
  and math.abs(p.x)<math.huge and math.abs(p.y)<math.huge,'finite summon position')
 -- Source scripts have native timer bodies and no Lua OnInit. The tag replaces
 -- their numeric script slot, preventing calls into unrelated live registries.
 local id=scene:create_temp_monster(monster_id,p.x,p.y,profile.base_ai,profile.ai_file,-1)
 local obj=id and scene:get_obj_by_id(id);if not obj then return nil end
 obj:set_temp_camp_id(owner:get_camp_id())
 if profile.name then obj:set_name(profile.name)end
 obj.ai:set_int_param_by_index(0,owner:get_guid())
 for i,value in pairs(profile.int_params or {})do assert(i~=0,'owner GUID reserved');obj.ai:set_int_param_by_index(i,value)end
 if profile.life then obj:set_die_time(profile.life)end
 M.attach(obj,owner,profile,tick)
 return obj
end
return M
