-- Exercise the real patched methods with two identical template IDs and different GUIDs.
local root='/mnt/c/TLBB/085/CY-Source/'
local function method(path,name)
 local f=assert(io.open(path));local s=f:read('*a');f:close()
 local start=assert(s:find('function '..name..'(',1,true));local finish=s:find('\nfunction ',start+1,true) or #s+1
 return s:sub(start,finish-1)
end
scenecore={};character={}
define={HUMAN_EQUIP={HEQUIP_RING_1=6,HEQUIP_RING_2=11,HEQUIP_AMULET_1=12,HEQUIP_AMULET_2=13,HEQUIP_UNKNOW1=9,HEQUIP_UNKNOW2=10,SHENBING=37},
 ITEM_OPERATOR_ERROR={ITEMOE_SUCCESS=0},UseEquipResultCode={USEEQUIP_SUCCESS=0},CHUANCI_INFO={DAMAGE_HUMAN=1,DAMAGE_PET=5,DAMAGE_MONSTER=5,IS_CRITICAL_HIT=1}}
local src=root..'Build/Logs/2026-09-25-smart-equip/server/scenecore.lua'
assert(load(method(src,'scenecore:ring_or_amulet_select_slot')))()
assert(load(method(src,'scenecore:char_use_bag_equip')))()
local base={};configenginer={get_config=function()return base end}
item_operator={exchange_item=function(_,bag,from,equips,to)bag[from],equips[to]=equips[to],bag[from];return 0 end}
local function container()return {get_item=function(self,i)return self[i]end}end
local function item(id,point,serial)
 base[id]={level=1};return {item_index=id,guid={series=serial},get_item_point=function()return point end,get_index=function()return id end}
end
for _,points in ipairs({{6,11},{12,13}}) do
 local first,second=table.unpack(points);local bag,equips=container(),container();local cleaned
 local h={get_prop_bag=function()return bag end,get_equip_container=function()return equips end,get_level=function()return 100 end,
 get_mission_data_by_script_id=function()return 0 end,set_mission_data_by_script_id=function()end,impact_clean_when_unequip=function(_,e)cleaned=e end,
 notify_tips=function()error('Unexpected rejected equip')end}
 for n=1,3 do
  local new=item(10122001,first,n);bag[0]=new;local reply={};local previous=equips[first]
  local actual=scenecore:char_use_bag_equip(h,{bagIndex=0,equipPoint=first},reply)
  local expected=n==2 and second or first
  assert(actual==new and equips[expected]==new and reply.equipPoint==expected)
  assert(reply.item_guid==new.guid)
  if n<=2 then assert(bag[0]==nil and reply.equipTableIndex==-1 and reply.equip_guid.series==0)
  else assert(bag[0]==previous and reply.equip_guid==previous.guid and cleaned==previous) end
 end
 -- First empty is selected regardless of table.sort implementation/order.
 equips[first]=nil;assert(scenecore:ring_or_amulet_select_slot(equips,points)==first)
 equips[first]=equips[second];equips[second]=nil;assert(scenecore:ring_or_amulet_select_slot(equips,points)==second)
end
local path='/home/ubuntu/cys-test-20260913/GameServer/services/scene/obj/character.lua'
assert(load(method(path,'character:get_chuanci_damage')))()
for _,case in ipairs({{'human',42,0,false,42},{'human',42,42,false,0},{'human',42,50,true,0},{'monster',42,0,false,210},{'pet',42,2,false,200},{'monster',42,0,true,420},{'human',42,1,true,82}}) do
 local kind,attack,defence,critical,expected=table.unpack(case)
 local victim={get_obj_type=function()return kind end,get_obj_fangchuan=function()return defence end}
 local sender={get_obj_chuanci=function()return attack end}
 assert(character.get_chuanci_damage(victim,sender,critical)==expected)
end
-- Initial list only has 200 remapped entries: higher combat IDs must be sent separately.
human={};define.MAX_CHAR_MISSION_NUM=0;define.MD_2_CLIENT={}
local synced=false;package.loaded.cys_shending={sync=function()synced=true end}
packet_def={GCMissionList={new=function()return {}end}}
assert(load(method(root..'Build/Logs/2026-09-25-smart-equip/server/GameServer/services/scene/obj/human.lua','human:send_mission_list')))()
local sent={};local scene={send2client=function(_,_,p)assert(#p.mission_datas==200)end}
local h={db={get_chuanci=function()return 126 end,get_fangchuan=function()return 42 end},mission_data={char_missions={},mission_have_done_flags={}},
 get_obj_id=function()return 1 end,get_scene=function()return scene end,sync_dfeng_learn_md_to_client=function()end,
 set_mission_data_by_script_id=function(_,id,value)sent[id]=value end}
human.send_mission_list(h);assert(sent[602]==126 and sent[603]==42 and synced)
print('PASS real server methods: paired slots, GUID replies, replaced item cleanup, piercing difference/factors/critical/clamp')
