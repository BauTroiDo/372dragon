local root,stage=assert(arg[1]),assert(arg[2])
package.path=stage..'/GameServer/lualib/?.lua;'..root..'/GameServer/lualib/?.lua;'..package.path
package.cpath=root..'/GameServer/luaclib/?.so;'..package.cpath
local say,quiet=print,function()end
package.loaded.skynet={getenv=function(k)if k=='config_path'then return root..'/configs/%s'end end,logd=quiet,logi=quiet,logw=quiet,loge=quiet,error=quiet,log=quiet}
package.loaded['skynet.manager']={};package.loaded['skynet.sharetable']={};table.tostr=function()return ''end
function table.clone(v)if type(v)~='table'then return v end;local t={};for k,x in pairs(v)do t[k]=table.clone(x)end;return t end
print=quiet;local reader=require('cfghelper').new();local conf={}
for _,n in ipairs({'equip_base','common_item','diaowen_info','diaowen_rule'})do reader['read_'..n](reader);conf[n]=reader[n]end
print=say
package.loaded.configenginer={getinstance=function()return {get_config=function(_,k)return assert(conf[k],k)end}end}
package.loaded['game.packet']=setmetatable({},{__index=function()return {new=function()return {}end}end})
package.loaded.human_item_logic={dec_item_lay_count=function(_,_,h,p,n,id)
 local i=h.items[p];assert(i and i.id==id and i.count>=n and not i.locked);i.count=i.count-n;h.charged=h.charged+n;if i.count==0 then h.items[p]=nil end;return true
end}
local source=assert(io.open(root..'/GameServer/lualib/item.lua','rb')):read('*a')
local first=assert(source:find('local equip_data = class',1,true));local last=assert(source:find('\nlocal material_data =',first+7,true))
local env=setmetatable({class=require 'class',define=require 'define',configenginer=package.loaded.configenginer:getinstance()},{__index=_G})
local Equip=assert(load(source:sub(first,last-1)..'\nreturn equip_data','actual equip_data','t',env))()
local serial=0
local function item(id,count)
 serial=serial+1;local i={id=id,count=count or 1,guid={world=1,server=1,series=serial},bound=false,locked=false}
 if id//10000000==1 then i.e=Equip.new();i.e:set_equip_type(0);i.e:set_quality(6);i.e:set_creator('Smith&ZF3');i.e:set_dur(100);i.e:set_max_dur(100)end
 function i:get_index()return self.id end;function i:get_lay_count()return self.count end;function i:set_lay_count(n)self.count=n end
 function i:is_empty()return self.count==0 end;function i:is_lock()return self.locked end;function i:is_bind()return self.bound end
 function i:set_is_bind(b)self.bound=b end;function i:get_guid()return self.guid end;function i:is_equip()return self.e~=nil end
 function i:get_equip_data()return self.e end;function i:get_base_config()return conf[self.e and 'equip_base' or 'common_item'][self.id]end
 function i:is_identd()return not self.unidentified end;function i:get_item_creator()return self.e.creator end;function i:set_item_creator(v)self.e:set_creator(v)end
 function i:copy_raw_data()return {id=self.id,count=self.count,guid=table.clone(self.guid),bound=self.bound,e=self.e and self.e:copy_raw_data()}end
 function i:get_max_tile_count()return 250 end;function i:get_place_bag()return 'prop'end
 return i
end
local generation_hook
package.loaded.item_operator={gen_item=function(_,_,id)
 if generation_hook then local hook=generation_hook;generation_hook=nil;if hook()==false then return nil end end
 return item(id)
end}
local M=require 'cys_equipcraft';local passes=0
local function check(name,ok)assert(ok,name);passes=passes+1;say('PASS '..name)end
reader:read_allowable_script_fun()
check('new Action is registered in actual server allowlist',reader.allowable_script_fun[990029]~=nil)
check('legacy LevelUp is registered in actual server allowlist',reader.allowable_script_fun[880036]~=nil)
local function human()
 local h={items={},money=10000000,charged=0,level=100,locked=false}
 local bag={get_size=function()return {prop=100,material=100,task=20}end,get_item=function(_,p)return h.items[p]end,set_item=function(_,p,i)h.items[p]=i end}
 function bag:ipairs()local p=-1;return function()p=p+1;if p<100 then return p,h.items[p]end end end
 function h:get_prop_bag_container()return bag end;function h:get_level()return self.level end;function h:get_obj_id()return 1 end;function h:is_die()return self.dead end
 function h:get_scene()return {send2client=function()end}end;function h:item_flush()end
 function h:check_money_with_priority(n)return self.money>=n end;function h:cost_money_with_priority(n)assert(self.money>=n);self.money=self.money-n;return true end
 local s={IsPilferLockFlag=function()return h.locked end,BeginUICommand=function()end,EndUICommand=function()end,DispatchUICommand=function()end,UICommand_AddInt=function()end}
 function s:UICommand_AddStr(v)h.text=v end
 return h,s
end
local equip_id
for id,b in pairs(conf.equip_base)do if b.equip_point==2 and b.level==80 and (not equip_id or id<equip_id)then equip_id=id end end
assert(equip_id)
local d
for _,v in pairs(conf.diaowen_info)do local rule=conf.diaowen_rule[v.rule];if v.level==1 and rule and rule[2]==1 and v.tupu_material>0 and (not d or v.id<d.id)then d=v end end
assert(d);say('FIXTURE equip='..equip_id..' dw='..d.id..' product='..d.product..' blueprint='..d.tupu_material)
for _,id in ipairs({20800031,20800032,30503149,30503150,20310166,d.product,d.tupu_material,d.huangzhi_material})do check('native material exists '..id,conf.common_item[id]~=nil)end
local h,s=human();h.items[0]=item(equip_id);h.items[1]=item(equip_id);h.items[2]=item(20800031,250);h.items[2].bound=true
local function quote(mode,mat,target) M.quote(s,h,mode,0,mat or -1,target or -1,false);return h._cys_craft_revision end
local function act(mode,mat,target,revision)return M.action(s,h,1,mode,0,mat or -1,target or -1,revision or h._cys_craft_revision)end
local r=quote(1);check('spirit first upgrade exact costs',act(1) and h.items[0].e.creator=='Smith&W01&ZF3' and h.money==9900000 and h.items[2].count==245 and h.items[0].bound)
check('duplicate quote cannot pay twice',not act(1,nil,nil,r) and h.items[2].count==245)
for level=2,9 do quote(1);check('spirit tier '..level,act(1) and select(3,M.shengling(h.items[0].e.creator))==level)end
local charged=h.charged
check('spirit real stat bonus and excluded resistance',M.bonus(h.items[0],42,100)==119 and M.bonus(h.items[0],7,100)==100)
local copy=Equip.new();copy:init_from_data(h.items[0].e:copy_raw_data());check('spirit creator persists through actual loader',copy:get_creator()=='Smith&W09&ZF3')
quote(1);local money=h.money;charged=h.charged
check('advance at nine costs sixty souls and500000',act(1) and h.items[0].e.creator=='Smith&W30&ZF3' and h.money==money-500000 and h.charged==charged+60)
h.items[2]=item(20800031,250);h.items[10]=item(20800032,250)
for level=1,9 do quote(1);check('royal spirit tier '..level,act(1) and h.items[0].e.creator==string.format('Smith&W%02d&ZF3',30+level))end
quote(1);check('royal nine advances to heavenly sixty percent',act(1) and h.items[0].e.creator=='Smith&W60&ZF3' and M.bonus(h.items[0],44,100)==160)
quote(1);money=h.money;charged=h.charged;check('heavenly maximum never charges',not act(1) and h.money==money and h.charged==charged)
check('malformed creator boundary does not grant bonus',select(4,M.shengling('Smith&W09oops'))==0)

h.items[3]=item(d.product,2);h.items[4]=item(30503149,2)
quote(2,3);check('etch native engraving and solvent',act(2,3) and h.items[0].e:get_diaowen_id()==d.id and h.items[3].count==1 and h.items[4].count==1)
quote(2,3);charged=h.charged;check('cannot overwrite existing engraving',not act(2,3) and h.charged==charged)
h.items[5]=item(20310166,250);quote(3);local n=d.enhance_material_count
check('upgrade consumes actual table cost once',act(3) and h.items[0].e:get_diaowen_id()==d.id+1 and h.items[5].count==250-n)
quote(6,nil,1);h.items[0].e:set_dw_jinjie_details(5,12,3);quote(6,nil,1)
check('transfer preserves all fine engraving fields',act(6,nil,1) and h.items[1].e:get_diaowen_id()==d.id+1 and h.items[1].e.dw_rankexp==12 and h.items[1].e.dw_featuresid==3 and h.items[0].e.dw_rankexp==0 and h.items[0].e:get_diaowen_id()==0)
copy=Equip.new();copy:init_from_data(h.items[1].e:copy_raw_data());check('engraving full save-load roundtrip',copy:get_diaowen_id()==d.id+1 and copy.dw_rankexp==12 and copy.dw_featuresid==3)
h.items[0],h.items[1]=h.items[1],h.items[0];h.items[6]=item(30503150,10)
quote(4);check('fine engraving removal keeps metadata safe',not act(4))
h.items[0].e:set_dw_jinjie_details(0,12,0);quote(4)
check('unspent fine engraving experience cannot be lost by removal',not act(4))
h.items[0].e:set_dw_jinjie_details(0,0,0);h.items[0].e.diaowen_material_count=8192;quote(4)
check('invalid saved silk progress cannot create refunds',not act(4))
h.items[0].e:set_dw_jinjie_details(0,0,0);h.items[0].e:set_diaowen_material_count(3);quote(4)
local money=h.money;charged=h.charged
for pos=0,99 do if pos>=7 or not h.items[pos] then h.items[pos]=item(20502009,250) end end
check('full bag removal never deducts',not act(4) and h.money==money and h.charged==charged and h.items[0].e:get_diaowen_id()==d.id+1)
h.items[97]=nil;h.items[98]=nil;h.items[99]=nil;quote(4)
generation_hook=function()h.items[0].guid.series=h.items[0].guid.series+1 end
check('identity change during GUID allocation rejects atomically',not act(4) and h.money==money and h.charged==charged)
quote(4);generation_hook=function()return false end
check('reward allocation failure never charges',not act(4) and h.money==money and h.charged==charged)
quote(4);check('remove returns same-level engraving and unused silk',act(4) and h.items[0].e:get_diaowen_id()==0 and h.money==money-50000 and h.items[97].id==conf.diaowen_info[d.id+1].product and h.items[98].id==20310166 and h.items[98].count==3)
h.items[7]=item(d.tupu_material);h.items[8]=item(d.danqing_material[1],20);h.items[9]=item(d.huangzhi_material,20);quote(5,7)
local function quantity(id)local n=0;for _,i in pairs(h.items)do if i.id==id then n=n+i.count end end;return n end
local paper=quantity(d.huangzhi_material)
money=h.money;check('combine deterministic level1 output costs correct',act(5,7) and h.money==money-50000 and h.items[99].id==d.product and h.items[7]==nil and h.items[8]==nil and quantity(d.huangzhi_material)==paper-20)
h.items[0].e:set_creator('Smith');h.items[2]=item(20800032,250)
quote(1);h.items[0].locked=true;money=h.money;check('locked equipment rejects',not act(1) and h.money==money);h.items[0].locked=false
quote(1);h.locked=true;check('security lock rejects',not act(1) and h.money==money);h.locked=false
h.level=84;quote(1);check('level85 enforced',not act(1) and h.money==money);h.level=100
h.items[0].e:set_quality(5);quote(1);check('six stars enforced',not act(1) and h.money==money);h.items[0].e:set_quality(6)
quote(1);h.money=0;charged=h.charged;check('insufficient money preserves materials',not act(1) and h.charged==charged)
check('negative and oversized indices rejected',not M.action(s,h,1,1,-1,-1,99999,h._cys_craft_revision))
say('RESULT equipcraft '..passes..' checks passed')
