-- Audit observations, not a claim that the observed behavior is correct.
-- Extracts the current private-server method bodies; no DB/network/server writes.
local root=assert(arg[1])
package.path=root..'/GameServer/lualib/?.lua;'..package.path
package.loaded.skynet={getenv=function()end,error=function()end}
local define=require 'define'
local function read(rel)local f=assert(io.open(root..'/'..rel,'rb'));local s=f:read('a');f:close();return s:gsub('\r\n','\n')end
local function grab(rel,name,env)
 local s=read(rel);local body=assert(s:match('function '..name..'%([^\n]*\n.-\nend'),name)
 assert(load(body,'@'..rel,'t',env))()
end
function table.clone(x)if type(x)~='table'then return x end;local t={};for k,v in pairs(x)do t[k]=table.clone(v)end;return t end
local n=0
local function observe(id,detail)n=n+1;print('OBSERVATION '..id..': '..detail)end

-- HJ 26/27: actual pet equipment constructor + save/load.
local source=read('GameServer/lualib/item.lua')
local a=assert(source:find('local pet_equip_data = class',1,true))
local b=assert(source:find('\nlocal task_data = class',a,true))
local env=setmetatable({class=require 'class',define=define},{__index=_G})
local PE=assert(load(source:sub(a,b-1)..'\nreturn pet_equip_data','actual pet equipment','t',env))()
local one=PE.new();one:set_level(3);one:set_attr_count(2);one:set_attr_types({19,26});one:set_attr_value({123,456});one:set_qualifications({1,30,80,140,200,255})
local saved=one:copy_raw_data();local two=PE.new();two:init_from_data(saved)
for i,v in ipairs(saved.qualifications)do assert(two.qualifications[i]==v)end
assert(two.attr_values[1]==123 and two.attr_values[2]==456 and two.attr_types[1]==19)
observe('26/27','six quality bytes and first two attributes survive actual pet_equip_data roundtrip; not HJ hook persistence loss')
one.pet_equip_unknow_8=420;saved=one:copy_raw_data();two=PE.new();two:init_from_data(saved)
assert(two.pet_equip_unknow_8==300)
observe('73-related','pet soul life 420 saved, actual loader restores constructor default 300 (life field not loaded)')

-- HJ 25/26 adjacent defect: changing qualification has no contribution in either calculator.
for _,rel in ipairs({'GameServer/lualib/pet_attrib.lua','GameServer/lualib/db/pet_attrib.lua'})do
 local conf={pet_equip_base={[123]={base_attrs={attack_p=100}}},pet_equip_set_attr={}}
 -- Use the actual base-column key from define, not a guessed schema.
 local basekey,baseid=next(define.EQUIP_BASE_ATTRIB);conf.pet_equip_base[123].base_attrs={[basekey]=100}
 local raw={attr_count=0,attr_values={},attr_types={},qualifications={0,0,0,0,0,0}}
 local equip={copy_raw_data=function()return raw end,get_serial_type=function()return 1 end,get_index=function()return 123 end,get_base_config=function()return{}end}
 local pet={get_equip_container=function()return{get_item=function(_,i)if i==define.PET_EQUIP.PEQUIP_CAP then return equip end end}end}
 local env=setmetatable({pet_attrib={},define=define,IA=define.ITEM_ATTRIBUTE,
   configenginer={get_config=function(_,key)return conf[key]end},skynet=package.loaded.skynet},{__index=_G})
 grab(rel,'pet_attrib:cal_item_effect',env);grab(rel,'pet_attrib:item_effect_flush',env)
 local x=setmetatable({get_pet=function()return pet end,set_not_gen_attrib=function()end,mark_all_attr_dirty=function()end},{__index=env.pet_attrib})
 x:item_effect_flush();local before=x.item_effect[baseid]
 raw.qualifications={255,255,255,255,255,255};x:item_effect_flush();local after=x.item_effect[baseid]
 assert(before==100 and after==100)
 observe('25/26-related',rel..' base=100: quality bytes 0 -> 255, contribution 100 -> 100 (ignored)')
end

-- HJ 65: replacement arbitration already compares explicit priority.
local env=setmetatable({impactenginer={}},{__index=_G})
grab('GameServer/lualib/impactenginer.lua','impactenginer:can_impactA_replace_impactB',env)
local function imp(p)return{get_mutex_priority=function()return p end}end
assert(not env.impactenginer:can_impactA_replace_impactB(imp(1),imp(2)))
assert(env.impactenginer:can_impactA_replace_impactB(imp(2),imp(1)))
observe('65','lower mutex priority cannot replace higher priority; individual buff data still needs checking')

-- HJ 98: normal human quality is calculated even with enhancement absent.
env=setmetatable({human_attrib={},define=define},{__index=_G})
for _,name in ipairs({'cal_quality_effect','cal_enhance_effect'})do grab('GameServer/lualib/db/human_attrib.lua','human_attrib:'..name,env)end
local ia,ir=next(define.EQUIP_BASE_ATTR_BASE_ATTR_RATE)
local item={get_enhance_config=function()return nil end,get_apt_config=function()return{[ir]=20}end}
assert(env.human_attrib:cal_enhance_effect(item,ia,100)==0)
assert(env.human_attrib:cal_quality_effect(item,ia,100)==20)
observe('98','normal human equipment: base100 + enhancement0 + quality20 = 120')

-- HJ 121a: actual buy-back uses same instance, including bound + metadata.
env=setmetatable({human={},define=define,utils={get_day_time=function()return 0 end},skynet={send=function()end},
 packet_def={GCShopBuy={new=function()return{BUY_RESULT={BUY_BACK_OK=0,BUY_BAG_FULL=1,BUY_MONEY_FAIL=2}}end},GCNotifyEquip={new=function()return{}end},GCItemInfo={new=function()return{}end}}},{__index=_G})
grab('GameServer/services/scene/obj/human.lua','human:buy_back',env)
local sold,bag={},{};local item={guid=42,bound=true,quality=255,enhancement=9}
function item:get_base_config()return{base_price=20}end;function item:get_lay_count()return 1 end
function item:get_place_bag()return 0 end;function item:get_index()return 10102001 end
function item:is_bind()return self.bound end;function item:copy_raw_data()return table.clone(self)end
local function container(t)return{get_item=function(_,i)return t[i]end,set_item=function(_,i,x)t[i]=x end,get_index_by_guid=function()return 0 end,get_empty_item_index=function()return 7 end}end
sold[0]=item;local s,b=container(sold),container(bag)
local h=setmetatable({money=100,get_sold_out_container=function()return s end,get_prop_bag_container=function()return b end,
 get_scene=function()return{send2client=function()end}end,get_money=function(x)return x.money end,set_money=function(x,m)x.money=m end,
 get_name=function()return'Audit'end,get_guid=function()return 1 end,send_sold_out_list=function()end},{__index=env.human})
h:buy_back({item_guid=42});assert(bag[7]==item and bag[7].bound and bag[7].quality==255 and bag[7].enhancement==9 and sold[0]==nil and h.money==80)
observe('121a','NPC buy-back preserves identical bound item/GUID/quality/+9 in isolated transaction')

-- HJ 87: repeated damage callbacks for one AoE count targets as knife stacks.
local rel='GameServer/services/scene/skill/impact_logic/std_impact_101.lua'
source=read(rel)
a=assert(source:find('local function skill_matches',1,true));b=assert(source:find('\nreturn std_impact_101',a,true))
env=setmetatable({std_impact_101={},util={num=function(imp,k,default)return imp.params[k]or default or 0 end},DAMAGE_TYPE_RATE={1,2,3,4,5,6}},{__index=_G})
assert(load(source:sub(a,b-1),'@'..rel,'t',env))()
-- Runtime StandardImpact 32411 has collection117/limit15; collection117 includes
-- skill312 (血战八方). The transport-facing collection lookup is isolated here.
package.loaded.skillenginer={getinstance=function()return{is_skill_in_collection=function(_,id,coll)return id==312 and coll==117 end}end}
local imp={params={['生效技能集合']=117,['刀数上限']=15,['刀数']=5,['_accel_sent']=true}}
local actor={get_scene=function()return{}end}
local hits={}
for i=1,10 do hits[i]={damage_rate=true};env.std_impact_101:on_damage_target(imp,actor, {id=i},hits[i],312)end
assert(imp.params['刀数']==15 and hits[1][1]==nil and hits[10][1]==115)
observe('87','ten target callbacks with skill312: knife counter 5 -> 15, tenth target rate115 (limit15); no per-cast guard')

-- HJ 112: callback consumes token before checking failed result. Current caller uses 0.
env=setmetatable({echangeusername={}},{__index=_G})
grab('Game_2/Script/scripts/event/huodong/echangeusername.lua','echangeusername:CallBackChangeUserNameAfter',env)
for fail=1,4 do
 local consumed=0
 local x=setmetatable({LuaFnIsCanDoScriptLogic=function()return true end,LuaFnDelAvailableItem=function()consumed=consumed+1;return true end,MsgBox=function()end},{__index=env.echangeusername})
 x:CallBackChangeUserNameAfter(1,fail,'AuditOldName');assert(consumed==1)
end
observe('112','failure callback result 1/2/3/4 still consumes one rename token; latent defect (current char_by_name calls success=0 only)')
print('TOTAL OBSERVATIONS '..n)
