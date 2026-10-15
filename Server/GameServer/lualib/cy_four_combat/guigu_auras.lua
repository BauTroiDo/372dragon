-- Donor hook b2f69..b34a3, talent level zero. Constants b8c30=200,b8c34=1000.
-- Getter consumers 9dfe2/9e084 choose the LAST matching aura, never sum copies.
local N=require 'cy_four_combat.numeric'
local M={}
local attrs={'att_cold','att_fire','att_light','att_poison'}
local getters={'get_attack_cold','get_attack_fire','get_attack_light','get_attack_posion'}
local function strongest(values)
 local index,max=1,values[1]
 for i=2,4 do if values[i]>max then index,max=i,values[i]end end
 return index,max
end
M.strongest=strongest
local function raw_elements(owner)
 local result={};for i,key in ipairs(attrs)do result[i]=N.i32(owner:get_attrib(key) or 0)end;return result
end
function M.payload(source,target,caster)
 local values={0,0,0,0}
 if source==4251 then
  local current={};for i,name in ipairs(getters)do current[i]=N.i32(target[name](target))end
  local index,max=strongest(current)
  values[index]=math.min(100,N.float2int(N.f32(N.f32(max)/200)))
 elseif source==4260 then
  if not caster then return nil end
  local index=strongest(raw_elements(target));local _,max=strongest(raw_elements(caster))
  values[index]=math.min(2000,N.scale(max,100,1000,N.float2int))
 else return nil end
 return values
end
function M.install(bridge)
 assert(bridge.config.talents_enabled==false,'GuiGu aura port covers base talents only')
 local logic=assert(bridge.impacts[8038]);local prior=logic.on_active
 function logic:on_active(imp,owner)
  local reverse=bridge.config.resolve.impacts
  local source=imp:get_data_index()==reverse[4251] and 4251 or imp:get_data_index()==reverse[4260] and 4260
  if source and bridge.config.gameplay_enabled==true then
   local caster=owner:get_scene():get_obj_by_id(imp:get_caster_obj_id())
   if caster and caster._cy_four_summon then caster=require('cy_four_combat.summon_runtime').resolve_owner(caster._cy_four_summon)end
   imp._cy_four_formation_attr={source=source,values=M.payload(source,owner,caster)}
  end
  if prior then return prior(self,imp,owner)end
 end
end
function M.bonus(owner,source,index)
 local scene=owner:get_scene();local engine=scene and scene:get_impact_enginer();local bridge=engine and engine.cy_four_bridge
 if not bridge or bridge.config.gameplay_enabled~=true or bridge.config.guigu_aura_payload_verified~=true then return 0 end
 local target=bridge.config.resolve.impacts[source];local result=0
 for _,imp in ipairs(owner:get_impact_list())do
  if imp:get_data_index()==target then
   local data=imp._cy_four_formation_attr
   result=data and data.source==source and data.values and data.values[index] or 0
  end
 end
 return result
end
return M
