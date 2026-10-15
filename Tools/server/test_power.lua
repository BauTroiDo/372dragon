local root,stage=assert(arg[1]),assert(arg[2])
package.path=stage..'/GameServer/lualib/?.lua;'..root..'/GameServer/lualib/?.lua;'..package.path
package.cpath=root..'/GameServer/luaclib/?.so;'..package.cpath
local say,quiet=print,function()end
package.loaded.skynet={getenv=function(k)if k=='config_path' then return root..'/configs/%s' end end,logd=quiet,logi=quiet,logw=quiet,loge=quiet,error=quiet,log=quiet}
package.loaded['skynet.manager']={};package.loaded['skynet.sharetable']={};table.tostr=function()return '' end
function table.clone(x)if type(x)~='table' then return x end;local c={};for k,v in pairs(x)do c[k]=table.clone(v)end;return c end
print=quiet;local reader=require('cfghelper').new();local configs={}
for _,name in ipairs({'pet_soul_base','pet_soul_level_cost','pet_soul_level_up_info','pet_soul_extension'})do reader['read_'..name](reader);configs[name]=reader[name] end
print=say
package.loaded.configenginer={getinstance=function()return {get_config=function(_,k)return assert(configs[k],k)end}end}
package.loaded['game.packet']=setmetatable({},{__index=function()return {new=function()return {}end}end})
package.loaded.human_item_logic={dec_item_lay_count=function(_,_,h,pos,count,id)local i=h.items[pos];assert(i and i.id==id and i.count>=count);i.count=i.count-count;h.spent_items=h.spent_items+count;return true end}
local ding=require 'cys_shending';local soul=require 'cys_petsoul';local xl=require 'cys_xiulian'
local data=require 'cys_power_data';local pass=0
local function check(name,ok)assert(ok,name);pass=pass+1;say('PASS '..name) end
local function item(id,count)
 local i={id=id,count=count,locked=false,guid={world=1,server=1,series=id}}
 function i:get_index()return self.id end;function i:get_lay_count()return self.count end
 function i:is_empty()return self.count==0 end;function i:is_lock()return self.locked end;function i:is_bind()return false end
 function i:set_is_bind(v)self.bound=v end;function i:get_guid()return self.guid end
 function i:get_serial_class()return self.id//10000000 end
 function i:copy_raw_data()return {item_index=self.id} end
 return i
end
local function human()
 local h={items={},money=10000000,spent_items=0,exp=1000000,power=1000,level=100,cys_shending=ding.init(),cys_shending_revision=1,xiulian_list=xl.init()}
 function h:get_obj_id()return 1 end;function h:get_level()return self.level end;function h:is_die()return false end
 function h:get_prop_bag_container()return {get_item=function(_,i)return self.items[i]end}end
 function h:get_scene()return {send2client=function()end}end;function h:item_flush()end
 function h:check_money_with_priority(v)return self.money>=v end;function h:cost_money_with_priority(v)assert(self.money>=v);self.money=self.money-v end
 function h:get_exp()return self.exp end;function h:set_exp(v)self.exp=v end;function h:get_gong_li()return self.power end;function h:cost_gong_li(v)self.power=self.power-v end
 function h:get_xiulian_list()return self.xiulian_list end;function h:send_xiulian_list()end
 function h:xiulian_level_up(i)self.xiulian_list[i].level=self.xiulian_list[i].level+1 end
 local s={IsPilferLockFlag=function()return false end,notify_tips=function()end,BeginUICommand=function()end,EndUICommand=function()end,UICommand_AddInt=function()end,UICommand_AddStr=function()end,DispatchUICommand=function()end}
 function s:get_scene()return {get_obj_by_id=function()return h end}end
 function s:GetXiuLianDetail()return {cost_exp=1145,cost_gold=100}end
 local missions={};function s:GetMissionData(_,i)return missions[i] or 0 end;function s:SetMissionData(_,i,v)missions[i]=v end
 return h,s
end
local h,s=human();h.items[0]=item(38000945,2)
check('dust consumes exactly one real material',ding.action(s,h,7,1) and h.cys_shending.dust==200 and h.items[0].count==1)
ding.action(s,h,7,1);check('replayed revision cannot consume twice',h.items[0].count==1)
check('first con pill costs 200 adds 15',ding.action(s,h,1,2) and h.cys_shending.dust==0 and ding.values(h.cys_shending)==15)
check('insufficient dust has no mutation',not ding.action(s,h,1,3) and h.cys_shending.con==1)
h.cys_shending.dust=10000
check('attack pill adds 10 distributable points',ding.action(s,h,2,3) and select(2,ding.values(h.cys_shending))==10)
check('negative allocation rejected',not ding.action(s,h,5,4,-1,0,0,0))
check('over-allocation rejected',not ding.action(s,h,5,4,11,0,0,0))
check('valid split applied once',ding.action(s,h,5,4,6,4,0,0) and select(2,ding.values(h.cys_shending))==0)
check('cannot refund by forged smaller totals',not ding.action(s,h,5,5,0,0,0,0))
check('reset restores full points and costs2000',ding.action(s,h,6,5) and h.cys_shending.dust==7800 and select(2,ding.values(h.cys_shending))==10)
check('grade8 limit matches CY item descriptions',ding.max_gold(36)==7 and ding.max_gold(45)==10)
h.cys_shending.con=15;h.items[1]=item(38000993,1)
check('attack gold cannot feed con track',not ding.action(s,h,3,6) and h.items[1].count==1)
h.items[2]=item(38000943,1)
check('correct gold consumed',ding.action(s,h,3,6) and h.items[2].count==0 and h.cys_shending.con_gold==1)
local restored=ding.init(table.clone(h.cys_shending));check('restored totals stable',ding.values(restored)==ding.values(h.cys_shending))
check('old eleven-scroll character expands without reset',#xl.init({{level=10,upper_limit=20}})==15)
check('cultivation invalid index is harmless',not xl.operate(s,1,99,false) and h.exp==1000000)
h.level=69;check('cultivation requires70',not xl.operate(s,1,0,false));h.level=100
check('cultivation consumes real exp money power',xl.operate(s,1,0,false) and h.exp==998855 and h.power==967 and h.xiulian_list[1].level==1)
h.xiulian_list[1]={level=60,upper_limit=60};h.xiulian_list[2].upper_limit=60;h.xiulian_list[3].upper_limit=60
local money=h.money;check('realm60 to75 uses UI cost70000',xl.operate(s,1,0,true) and h.xiulian_list[1].upper_limit==75 and h.money==money-70000)
h.xiulian_list[1]={level=150,upper_limit=150};check('cultivation150 stops without charge',not xl.operate(s,1,0,false))
money=h.money;local exp=h.exp;local power=h.power
check('inactive advancement never charges',not xl.operate(s,1,11,false) and h.money==money and h.exp==exp and h.power==power)
check('legacy realm migration preserves earned level',xl.init({{level=110,upper_limit=120}})[1].upper_limit==120 and xl.init({{level=70,upper_limit=70}})[1].upper_limit==75)
-- Use the real item.lua pet_equip_data methods and real server tables.
local f=io.open(stage..'/GameServer/lualib/item.lua','rb') or assert(io.open(root..'/GameServer/lualib/item.lua','rb'));local source=f:read('*a');f:close()
local begin=assert(source:find('local pet_equip_data = class',1,true));local ending=assert(source:find('\nlocal ',begin+7,true))
local env={class=require 'class',define=require 'define',configenginer={get_config=function(_,k)return configs[k]end}}
setmetatable(env,{__index=_G})
local e=assert(load(source:sub(begin,ending-1)..'\nreturn pet_equip_data','pet_equip','t',env))().new()
e:set_level(1);e:set_pet_equip_type(1);e:set_pet_soul_quanlity(2);e:set_pet_soul_level(0);e:set_pet_soul_exp(0);e.pet_equip_unknow_8=200
local i=item(70600000,1);function i:get_pet_equip_data()return e end
h,s=human();h.items[0]=i;h.items[1]=item(38002530,50);h.items[2]=item(38002515,3);h.items[3]=item(38002532,3)
soul.quote(s,h,0,false);local rev=h._cys_soul_revision;local cost=configs.pet_soul_level_cost[1]
check('native soul level costs table gold/materials',soul.action(s,h,1,0,rev,-1) and e:get_level()==2 and h.items[1].count==50-cost.cost_count[3] and h.money==10000000-cost.cost_money[3])
local spent=h.spent_items;soul.action(s,h,1,0,rev,-1);check('soul duplicate revision keeps items',h.spent_items==spent)
check('blood feed consumes one',soul.action(s,h,2,0,h._cys_soul_revision,2) and e:get_pet_soul_exp()==20 and h.items[2].count==2)
check('wash produces pending without replacing',soul.action(s,h,3,0,h._cys_soul_revision,-1) and h._cys_soul_pending and #e:get_pet_soul_attr()==0)
local previous=h._cys_soul_revision;i.guid.series=i.guid.series+1
check('swapping identity rejects pending apply',not soul.action(s,h,4,0,previous,-1) and #e:get_pet_soul_attr()==0)
check('new wash succeeds',soul.action(s,h,3,0,h._cys_soul_revision,-1) and h._cys_soul_pending)
check('wash reward counter counts only successful paid rolls',s:GetMissionData(1,require('define').MD_ENUM.MD_COST_CHU_HUN_SUI)==2)
check('receive applies six attributes once',soul.action(s,h,4,0,h._cys_soul_revision,-1) and #e:get_pet_soul_attr()==6 and not h._cys_soul_pending)
check('life restore consumes one and clamps',soul.action(s,h,5,0,h._cys_soul_revision,2) and e.pet_equip_unknow_8==300 and h.items[2].count==1)
spent=h.spent_items;check('full life rejects with no cost',not soul.action(s,h,5,0,h._cys_soul_revision,2) and h.spent_items==spent)
e:set_level(100);soul.quote(s,h,0,false);check('max soul level no cost',not soul.action(s,h,1,0,h._cys_soul_revision,-1) and h.spent_items==spent)
e:set_pet_soul_level(5);soul.quote(s,h,0,false);check('max blood no cost',not soul.action(s,h,2,0,h._cys_soul_revision,2) and h.spent_items==spent)
local text='';function s:UICommand_AddStr(t)text=t end
e:set_pet_soul_attr({{type=15,value=966},{type=22,value=1640}});soul.quote(s,h,0,false)
check('GL percentage floors to one decimal and one percent sign',text:find('9.6%%') and text:find('16.4%%') and not text:find('%%%%'))
-- New CY locks use the actual native generator and transaction entry, not a
-- copy of their formula. Keep the old no-lock path above as compatibility proof.
do
 local hh,ss=human();local soul_item=item(70600000,1)
 local ee=getmetatable(e).new and getmetatable(e).new() or nil
 -- class.lua instances expose new() through their class metatable.
 assert(ee);ee:set_level(1);ee:set_pet_equip_type(1);ee:set_pet_soul_quanlity(1);ee:set_pet_soul_level(0);ee:set_pet_soul_exp(0)
 ee:set_pet_soul_attr({{type=0,value=1},{type=1,value=1},{type=2,value=1},{type=3,value=1},{type=22,value=1},{type=-1,value=0}})
 function soul_item:get_pet_equip_data()return ee end
 hh.items[0]=soul_item;hh.items[1]=item(38002533,50);hh.items[2]=item(38002636,3);hh.items[3]=item(38002633,3)
 hh.items[2].is_bind=function()return true end
 local function roll(mask,color)soul.quote(ss,hh,0,false);return soul.action(ss,hh,3,0,hh._cys_soul_revision,-1,mask,color)end
 local money=hh.money
 check('hidden soul row lock does not charge',not roll(1,-1) and hh.money==money and hh.spent_items==0)
 check('wrong quality color item is retained',not roll(10,3) and hh.money==money and hh.items[3].count==3)
 hh.items[2].locked=true;check('locked color item is retained',not roll(10,2) and hh.spent_items==0);hh.items[2].locked=false
 check('locked high row and color guarantee roll',roll(10,2) and hh.money==money-50000 and hh.items[1].count==48 and hh.items[2].count==2)
 check('bound color binds resulting soul',soul_item.bound==true)
 local attrs=hh._cys_soul_pending.attrs;local colored,high=0,false
 for j=1,5 do local a=attrs[j];if a.type==22 then high=true end;if a.value>=configs.pet_soul_extension[a.type][7] and a.value<=configs.pet_soul_extension[a.type][8] then colored=colored+1 end end
 check('locked type22 survives five-row sort',high and attrs[6].type==-1)
 check('three top-band rows guaranteed',colored>=3)
 check('paid counter includes locked-row fee',ss:GetMissionData(1,require('define').MD_ENUM.MD_COST_CHU_HUN_YE)==2)
 check('locked wash stays pending',ee:get_pet_soul_attr()[5].value==1)
 local rev=hh._cys_soul_revision
 check('receive locked result once',soul.action(ss,hh,4,0,rev,-1) and not hh._cys_soul_pending)
 check('replayed receive cannot change result',not soul.action(ss,hh,4,0,rev,-1) and hh.items[1].count==48)
 money=hh.money;local before=hh.spent_items;local ext=configs.pet_soul_extension[0];configs.pet_soul_extension[0]=nil
 check('malformed extension never consumes fees',not roll(0,-1) and hh.money==money and hh.spent_items==before)
 configs.pet_soul_extension[0]=ext
 -- Exercise YunShenShen's native request too. Both entry points must refuse
 -- invalid lock/color selections before charging, and pass the prepared roll.
 local nf=assert(io.open(stage..'/Game_2/Script/scripts/obj/suzhou/osuzhou_yunshenshen.lua','rb'))
 local ns=nf:read('a');nf:close()
 local body=assert(ns:match('function osuzhou_yunshenshen:OnPetSoulXiShuXing%([^\n]*\n.-\nend'))
 local native={};local reforge=require 'cys_soul_reforge'
 local ne=setmetatable({osuzhou_yunshenshen=native,define=require 'define',PetSoulXiShuXingItems={[1]={38002533,38002541}},PetXiShuXingLockColorCount=reforge.colors},{__index=_G})
 assert(load(body,'native soul reforge','t',ne))()
 setmetatable(native,{__index=ss});native.scene={get_obj_by_id=function()return hh end}
 function native:GetPetEquipType()return 1 end
 function native:GetPetSoulQuanlity()return 1 end
 function native:LuaFnIsItemLocked(_,p)local x=hh.items[p];return x and x.locked or false end
 function native:GetBagItemIndex(_,p)local x=hh.items[p];return x and x:get_index() or -1 end
 native.GetItemTableIndexByIndex=native.GetBagItemIndex
 function native:GetBagItemLayCount(_,p)local x=hh.items[p];return x and x.count or 0 end
 function native:GetBagItemIsBind(_,p)local x=hh.items[p];return x and x:is_bind() or false end
 function native:GetMoney()return hh.money end;function native:GetMoneyJZ()return 0 end
 function native:LuaFnDecItemLayCount(_,p,n)hh.items[p].count=hh.items[p].count-n;hh.spent_items=hh.spent_items+n end
 function native:LuaFnCostMoneyWithPriority(_,n)hh.money=hh.money-n end
 function native:PetSoulXiShuXing(_,_,_,_,prepared)assert(#prepared==6);self.result=prepared;return true end
 function native:LuaFnSendSpecificImpactToUnit()end
 money=hh.money;before=hh.spent_items
 native:OnPetSoulXiShuXing(1,0,-1,3,0)
 check('native wrong color quality preserves costs',hh.money==money and hh.spent_items==before and not native.result)
 native:OnPetSoulXiShuXing(1,0,-1,-1,1)
 check('native hidden row preserves costs',hh.money==money and hh.spent_items==before and not native.result)
 native:OnPetSoulXiShuXing(1,0,-1,2,10)
 check('native valid locked roll charges same fee once',hh.money==money-50000 and hh.spent_items==before+3 and native.result)
end
-- Exercise the real entry validation before the native pet equip transaction.
local guid=require('pet_guid').new();guid:set(1,2)
local none=require('pet_guid').new();none:set(0,0)
local pet={locked=false,exchange=false,level=1,items={}}
function pet:is_lock()return self.locked end;function pet:is_in_exchange()return self.exchange end
function pet:get_level()return self.level end;function pet:get_equip_container()return {get_item=function(_,p)return self.items[p]end}end
function h:get_current_pet_guid()return self.current or none end
function h:get_current_soul_melting_pet_guid()return self.melting or none end
function h:get_pet_bag_container()return {get_pet_by_guid=function(_,g)return g==guid and pet end}end
function h:notify_tips()end
function h:get_prop_bag_container()return {get_item=function(_,p)return self.items[p]end,get_size=function()return 100 end}end
function i:get_base_config()return {equip_point=5,level=1}end
local scene={get_obj_by_id=function()return h end}
local request={from=0,to=5,pet_guid={m_uHighSection=1,m_uLowSection=2}}
check('owned inactive pet accepts soul',soul.can_equip(scene,1,request,false))
pet.locked=true;check('locked pet rejects before binding',not soul.can_equip(scene,1,request,false));pet.locked=false
request.to=0;check('wrong equipment slot rejects',not soul.can_equip(scene,1,request,false));request.to=5
h.current=guid;check('active pet rejects',not soul.can_equip(scene,1,request,false));h.current=nil
h.melting=guid;check('melting pet rejects',not soul.can_equip(scene,1,request,false));h.melting=nil
i.locked=true;check('locked soul rejects',not soul.can_equip(scene,1,request,false));i.locked=false
request.pet_guid.m_uLowSection=3;check('unowned pet rejects',not soul.can_equip(scene,1,request,false));request.pet_guid.m_uLowSection=2
request.from=5;check('empty equipped soul rejects unequip',not soul.can_equip(scene,1,request,true));pet.items[5]=i
check('owned equipped soul accepts unequip',soul.can_equip(scene,1,request,true))
-- Execute the production Wuhun book path against a 250-count physical stack.
package.loaded.script_base=require('class')('power_test_script_base')
package.loaded.wire_charset={fromutf8=function(v)return v end}
local wh=assert(loadfile(stage..'/Game_2/Script/scripts/event/equip/wuhun.lua') or loadfile(root..'/Game_2/Script/scripts/event/equip/wuhun.lua'))().new()
-- OnAction now resolves the actual bag before the dual-soul guard. Keep this
-- fixture an ordinary Võ hồn and exercise that guard, rather than bypassing it.
local normal_soul={get_index=function()return 10156001 end}
wh.scene={get_obj_by_id=function()return{get_prop_bag=function()return{get_item=function()return normal_soul end}end}end}
local record={ex_attr_number=2,ex_attr={0,0,0,0,0,0,0,0,0,0}}
local book_count,paid,locked=250,0,false
function wh:IsPilferLockFlag()return false end
function wh:LuaFnIsItemLocked(_,pos)return pos==1 and locked end
function wh:LuaFnGetBagEquipType(_,pos)return pos==0 and 18 or -1 end
function wh:LuaFnGetItemTableIndexByIndex()return 30700200 end
function wh:GetKfsAttrExBookConfig()return {[30700200]={attr=1}}end
function wh:LuaFnIsItemAvailable()return book_count>0 end
function wh:GetEquipWuHunData()return record end
function wh:GetMoneyJZ()return 100000 end;function wh:GetMoney()return 0 end
function wh:SetEquipWuHunData(_,_,update)for k,v in pairs(update.ex_attr)do record.ex_attr[k]=v end end
function wh:LuaFnCostMoneyWithPriority(_,n)paid=paid+n end
function wh:LuaFnDecItemLayCount(_,_,n)book_count=book_count-n end
function wh:notify_tips()end;function wh:LuaFnSendSpecificImpactToUnit()end
wh:OnAction(1,2,0,1)
check('native Wuhun book250 consumes one and applies attribute',book_count==249 and paid==80000 and record.ex_attr[1]==1)
wh:OnAction(1,2,0,1)
check('duplicate Wuhun attribute never consumes book or gold',book_count==249 and paid==80000)
record.ex_attr[1]=0;locked=true;wh:OnAction(1,2,0,1)
check('locked Wuhun book never consumes or applies',book_count==249 and paid==80000 and record.ex_attr[1]==0)
say('RESULT power server PASS '..pass)
