package.path='/mnt/c/TLBB/085/CY-Source/Tools/server/?.lua;'..package.path
local m=require 'cys_dual_souls'
local fields={};local ed=setmetatable({},{__index=function(_,key)
 if key=='get_wh_life' then return function()return fields.life or 300 end end
 return function(_,a,b)fields[key]=b and {a,b} or a end
end})
local function item(id)return {get_index=function()return id end,get_equip_data=function()return ed end}end
local equips={};local flags={};local action=0
local h={get_obj_type=function()return 'human' end,get_equip_container=function()return {get_item=function(_,point)return equips[point]end}end,
 get_game_flag_key=function(_,key)return flags[key] or 0 end,set_game_flag_key=function(_,key,v)flags[key]=v end,
 is_alive=function()return true end,get_action_time=function()return action end,get_obj_id=function()return 9 end}
assert(not m.initialize(item(10156001)))
assert(m.initialize(item(m.support)) and fields.set_wh_level==1)
assert(not m.authorized(h,6101) and not m.authorized(h,6102))
equips[18]=item(m.support);assert(m.authorized(h,6101) and not m.authorized(h,6100) and not m.authorized(h,6102))
equips[39]=item(m.assault);assert(m.authorized(h,6102) and m.authorized(h,6103))
assert(#m.skills(h,39)==2 and m.visual(h)==699)
flags.cys_assault_hidden=1;assert(m.visual(h)==0 and m.authorized(h,6102))
fields.life=0;assert(not m.authorized(h,6102));fields.life=300
equips[18],equips[39]=equips[39],equips[18];assert(#m.skills(h,39)==0 and #m.skills(h,18)==0)
equips[18]=item(10156001);equips[39]=nil;assert(#m.skills(h,18)==0 and m.authorized(h,1541))
action=1;assert(not m.can_swap(h,39));action=0;assert(m.can_swap(h,39))
m.combat(h);assert(not m.can_swap(h,18) and m.can_swap(h,2))
assert(m.saved_visual({equip_list={['40']={item_index=m.assault}}})==699)
assert(m.saved_visual({equip_list={['40']={item_index=m.assault}},game_flag={cys_assault_hidden=1}})==0)
assert(m.saved_visual({equip_list={['40']={item_index=m.support}}})==0)
local sent
package.preload['game.packet']=function()return {GCUICommand={new=function()return {m_Param={m_StrCount=0}}end}}end
m.snapshot({send2client=function(_,to,p)sent=p end},h)
assert(sent.m_nUIIndex==990031 and sent.m_Param.m_IntCount==6 and sent.m_Param.m_aIntValue[1]==1)
local function impact(id)return {get_skill_id=function()return id end}end
local impacts={impact(6101),impact(1397),impact(6101)};local fades=0
h.get_impact_list=function()return impacts end
h.on_impact_fade_out=function()fades=fades+1 end
h.remove_impact=function(_,imp)for i=#impacts,1,-1 do if impacts[i]==imp then table.remove(impacts,i);return end end end
m.unequip(h,item(10156001));assert(#impacts==3)
m.unequip(h,item(m.assault));assert(#impacts==3)
m.unequip(h,item(m.support));assert(#impacts==1 and impacts[1]:get_skill_id()==1397 and fades==2)
print('PASS dual souls entitlement, slot isolation, hidden appearance, dead soul, legacy compatibility, combat lock, saved visual and state packet')
print('PASS support unequip removes only its own buff instances')
local timer,ticks,hits
package.preload.skynet=function()return {timeout=function(n,f)ticks=n;timer=f end,loge=function(...)error('impact callback failed')end}end
local owner={get_obj_id=function()return 1 end,get_world_pos=function()return {x=0,y=0}end,is_alive=function()return true end}
local victim={get_obj_id=function()return 2 end,get_world_pos=function()return {x=15,y=0}end,is_alive=function()return true end,register_impact=function()hits=(hits or 0)+1 end}
local objects={[1]=owner,[2]=victim};local scene={get_obj_by_id=function(_,id)return objects[id]end}
assert(not m.schedule_impact(scene,owner,victim,{},0,4515))
assert(m.schedule_impact(scene,owner,victim,{},0,6102) and ticks==280 and hits==nil)
timer();assert(hits==1)
assert(m.schedule_impact(scene,owner,victim,{},1500,6103) and ticks==250)
objects[2]={};timer();assert(hits==1) -- replaced or transferred receiver
objects[2]=victim;objects[1]=nil;timer();assert(hits==1) -- caster left scene
objects[1]=owner;victim.is_alive=function()return false end;timer();assert(hits==1)
print('PASS projectile release/travel delay and no late hit after death or scene transfer')
