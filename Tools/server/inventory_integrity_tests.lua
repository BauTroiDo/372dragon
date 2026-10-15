-- Execute real deployed/extracted server methods with deterministic containers.
-- No server/session/database mutation. Failure must leave GUID/count state intact.
local root, guardpath, mode = ...
assert(root and guardpath, 'usage: lua inventory_integrity_tests.lua GameServer guard.lua [baseline]')
local guard = dofile(guardpath)
local function read(path) local f=assert(io.open(path,'rb')); local s=f:read('a');f:close();return s:gsub('\r\n','\n') end
local function clone(t)
    if type(t)~='table' then return t end
    local c={}; for k,v in pairs(t) do c[k]=clone(v) end
    return setmetatable(c,getmetatable(t))
end
table.clone=clone
local define={INVAILD_ID=-1,ITEM_OPERATOR_ERROR={ITEMOE_SUCCESS=0,ITEMOE_UNKNOW=-1,
 ITEMOE_SOUROPERATOR_EMPTY=-2,ITEMOE_SOUROPERATOR_LOCK=-3,ITEMOE_DESTOPERATOR_FULL=-4,
 ITEMOE_DESTOPERATOR_HASITEM=-5,ITEMOE_CREATEGUID_FAIL=-6},
 ITEM_CLASS={ICLASS_EQUIP=1,ICLASS_PET_EQUIP=8},ITEM_DATA_TYPE={IDT_ITEM=1,IDT_PET=2},
 CONTAINER_INDEX={HUMAN_BAG=1,HUMAN_BANK=2,HUMAN_SELF=3,HUMAN_FASION=4,HUMAN_SHANGHUI_ITEM=5,HUMAN_PET_EQUIP=6}}
define.ITEMBOX_TYPE={ITYPE_DROPBOX=1}
local function class(_, base)
 local c={};c.__index=c;setmetatable(c,{__index=base})
 function c.new() local o=setmetatable({},c);if o.ctor then o:ctor() end;return o end
 return c
end
local seq=100
local Item={};Item.__index=Item
function Item.new(id,n,bag,bind,locked)
 seq=seq+1
 return setmetatable({id=id or 0,n=n or 0,bag=bag or 'prop',bound=bind or false,locked=locked or false,guid=seq,max=20,record={}},Item)
end
function Item:get_index() return self.id end
function Item:set_index(id) self.id=id end
function Item:get_place_bag() return self.bag end
function Item:get_lay_count() return self.n end
function Item:set_lay_count(n) self.n=n end
function Item:get_max_tile_count() return self.max end
function Item:is_bind() return self.bound end
function Item:set_is_bind(v) self.bound=v end
function Item:is_lock() return self.locked end
function Item:can_lay() return self.max>1 end
function Item:is_empty() return self.n==0 end
function Item:is_full() return self.n>=self.max end
function Item:get_type() return 1 end
function Item:get_serial_class() return 3 end
function Item:set_guid(g) self.guid=g end
function Item:get_guid() return self.guid end
function Item:copy_raw_data() return {guid=self.guid,item_index=self.id,count=self.n,lay_count=self.n,bind=self.bound,record_data=self.record} end
function Item:init_from_data(d) self.id=d.item_index;self.n=d.count;self.guid=d.guid;self.bag=d.bag or 'prop';self.max=20;self.record={};self.bound=false;self.locked=false end
local packet=setmetatable({}, {__index=function(t,k) local v={new=function()return {_type=k}end};rawset(t,k,v);return v end})
local sky={error=function()end,send=function()end}
local utils={get_day_time=function()return 'test'end}
local modules={class=class,define=define,skynet=sky,configenginer={getinstance=function()return{}end},item=Item,guid={},pet_guid={},human_item_logic={},cys_inventory_guard=guard}
modules.human_item_logic.get_place_bag=function()return'prop'end
local env=setmetatable({require=function(k)return assert(modules[k],k)end,define=define,packet_def=packet,item_cls=Item,inventory_guard=guard,skynet=sky,utils=utils}, {__index=_G})
env.item_guid={new=function()return 0 end}
local function module(path) return assert(load(read(root..'/'..path),'@'..path,'t',env))() end
local base=module('lualib/item_container.lua');modules.item_container=base
local Bag=module('lualib/human_bag_container.lua')
local function extract(path, prefix, names)
 local src=read(root..'/'..path);local target={};env[prefix]=target
 for _,name in ipairs(names) do
  local body=assert(src:match('function '..prefix..':'..name..'%([^\n]*%)[^\n]*\n.-\nend'),name)
  assert(load(body,'@'..path..':'..name,'t',env))()
 end
 return target
end
local scene=extract('services/scene/scenecore.lua','scenecore',{'package_swap_item'})
local op=extract('lualib/item_operator.lua','item_operator',{'move_item','exchange_item','split_item','create_item','set_item_guid','set_item_lay_count'})
function op:gen_item_guid()seq=seq+1;return seq end
local logic=extract('lualib/human_item_logic.lua','human_item_logic',{'create_multi_item_to_bag','calc_item_space','get_item'})
local function newbag(p,m,q)
 local b=Bag.new();b:init({prop=p or 20,material=m or 20,task=q or 20},{},1);return b
end
local function fingerprint(b)
 local rows={};for i,item in pairs(b.item_list) do rows[#rows+1]=string.format('%s:%s:%s:%s:%s',i,item.id,item.n,item.guid,tostring(item.bound)) end
 table.sort(rows);return table.concat(rows,'|')
end
local function total(b) local n=0;for _,x in pairs(b.item_list) do n=n+x.n end;return n end
local function swap(b,from,to)
 local h={get_prop_bag_container=function()return b end,notify_tips=function()end}
 local s=setmetatable({objs={[1]=h},send2client=function()end},{__index=scene})
 return s:package_swap_item(1,{index_from=from,index_to=to,count=0})
end
local cases={}
local function test(name,fn)cases[#cases+1]={name,fn}end
local function unchanged(b,fn) local before=fingerprint(b);fn();assert(before==fingerprint(b),'container changed')end
test('swap_same_slot',function()local b=newbag();b:set_item(0,Item.new(301,3));unchanged(b,function()swap(b,0,0)end)end)
for _,dst in ipairs({20,99,220,65535,-1,0.5}) do
 test('swap_unopened_'..dst,function()local b=newbag();b:set_item(0,Item.new(301,3));unchanged(b,function()swap(b,0,dst)end)end)
end
test('swap_wrong_region',function()local b=newbag();b:set_item(0,Item.new(301,3));unchanged(b,function()swap(b,0,100)end)end)
test('swap_locked_source',function()local b=newbag();b:set_item(0,Item.new(301,3,'prop',false,true));unchanged(b,function()swap(b,0,1)end)end)
test('swap_locked_dest',function()local b=newbag();b:set_item(0,Item.new(301,3));b:set_item(1,Item.new(302,2,'prop',false,true));unchanged(b,function()swap(b,0,1)end)end)
test('swap_valid_empty',function()local b=newbag();local x=Item.new(301,3);b:set_item(0,x);swap(b,0,19);assert(b:get_item(19)==x and not b:get_item(0))end)
test('swap_stack_conserves',function()local b=newbag();b:set_item(0,Item.new(301,3));b:set_item(1,Item.new(301,18));swap(b,0,1);assert(total(b)==21 and b:get_item(0).n==1 and b:get_item(1).n==20)end)
test('swap_bind_kept',function()local b=newbag();local a=Item.new(301,3);local z=Item.new(301,4,'prop',true);b:set_item(0,a);b:set_item(1,z);swap(b,0,1);assert(total(b)==7 and b:get_item(0)==z and b:get_item(1)==a)end)
test('swap_metadata_kept',function()local b=newbag();local a=Item.new(301,3);local z=Item.new(301,4);z.record.expires=123;b:set_item(0,a);b:set_item(1,z);swap(b,0,1);assert(total(b)==7 and b:get_item(0)==z and b:get_item(1)==a)end)
for _,race in ipairs({'source_consumed','source_count','dest_replaced','dest_count','source_locked'}) do
 test('swap_cfgdb_yield_'..race,function()
  local b=newbag(100);local a,z=Item.new(301,1),Item.new(301,249);a.max=250;z.max=250;b:set_item(19,a);b:set_item(18,z)
  local once=false;local after
  function a:get_max_tile_count()
   if not once then
    once=true
    if race=='source_consumed' then b:set_item(19,nil);z.n=250
    elseif race=='source_count' then a.n=2
    elseif race=='dest_replaced' then b:set_item(18,Item.new(301,5))
    elseif race=='dest_count' then z.n=250
    else a.locked=true end
    after=fingerprint(b)
   end
   return self.max
  end
  swap(b,19,18);assert(after==fingerprint(b),'stale swap overwrote interleaved operation')
 end)
end
for _,num in ipairs({-1,0,0.5,3,99}) do
 test('split_invalid_'..num,function()local b=newbag();b:set_item(0,Item.new(301,3));unchanged(b,function()op:split_item({},b,0,num,b,1)end)end)
end
test('split_new_guid',function()local b=newbag();local x=Item.new(301,7);b:set_item(0,x);assert(op:split_item({},b,0,2,b,1)==0);assert(total(b)==7 and x.n==5 and b:get_item(1).n==2 and b:get_item(1).guid~=x.guid)end)
test('split_unopened',function()local b=newbag();b:set_item(0,Item.new(301,7));unchanged(b,function()op:split_item({},b,0,2,b,20)end)end)
test('split_wrong_region',function()local b=newbag();b:set_item(0,Item.new(301,7));unchanged(b,function()op:split_item({},b,0,2,b,100)end)end)
test('move_same_slot',function()local b=newbag();b:set_item(0,Item.new(301,7));unchanged(b,function()op:move_item(b,0,b,0)end)end)
for _,target in ipairs({1,-1}) do
 for _,race in ipairs({'source_consumed','source_count','dest_replaced','dest_count','source_locked'}) do
  test('move_cfgdb_yield_'..target..'_'..race,function()
   local b=newbag();local a,z=Item.new(301,3),Item.new(301,4);b:set_item(0,a);b:set_item(1,z)
   local once=false;local after
   function a:get_max_tile_count()
    if not once then
     once=true
     if race=='source_consumed' then b:set_item(0,nil);z.n=7
     elseif race=='source_count' then a.n=2
     elseif race=='dest_replaced' then b:set_item(1,Item.new(301,5))
     elseif race=='dest_count' then z.n=5
     else a.locked=true end
     after=fingerprint(b)
    end
    return self.max
   end
   op:move_item(b,0,b,target);assert(after==fingerprint(b),'stale transfer overwrote interleaved operation')
  end)
 end
end
test('move_wrong_item',function()local b=newbag();b:set_item(0,Item.new(301,7));b:set_item(1,Item.new(302,4));unchanged(b,function()op:move_item(b,0,b,1)end)end)
test('move_bind_mismatch',function()local b=newbag();b:set_item(0,Item.new(301,7));b:set_item(1,Item.new(301,4,'prop',true));unchanged(b,function()op:move_item(b,0,b,1)end)end)
test('move_unopened',function()local b=newbag();b:set_item(0,Item.new(301,7));unchanged(b,function()op:move_item(b,0,b,20)end)end)
test('exchange_unopened',function()local b=newbag();b:set_item(0,Item.new(301,7));unchanged(b,function()op:exchange_item(b,0,b,20)end)end)
test('shrink_occupied_preserved',function()local b=newbag(30);b:set_item(29,Item.new(301,7));unchanged(b,function()b:set_size({prop=20,material=20,task=20})end);assert(b:get_size().prop==30)end)
test('shrink_boundary_free',function()local b=newbag(30);b:set_item(19,Item.new(301,7));b:set_size({prop=20,material=20,task=20});assert(b:get_size().prop==20 and total(b)==7)end)
test('expand_to_100',function()local b=newbag();b:set_size({prop=100,material=100,task=20});b:set_item(99,Item.new(301,1));b:set_item(199,Item.new(601,1,'material'));assert(total(b)==2 and b:get_size().prop==100)end)
test('shrink_material_preserved',function()local b=newbag(20,30);b:set_item(129,Item.new(601,7,'material'));unchanged(b,function()b:set_size({prop=20,material=20,task=20})end);assert(b:get_size().material==30)end)
test('reload_overflow_preserved',function()local b=Bag.new();b:init({prop=20,material=20,task=20},{['30']={item_index=301,count=7,guid=9}},1);assert(b:get_save_data()['30'].count==7)end)
test('pack_keeps_guid_counts_regions',function()local b=newbag(40);b:set_item(39,Item.new(305,5));b:set_item(4,Item.new(301,7));b:set_item(100,Item.new(601,3,'material'));local all=total(b);local a=b:get_item(39);assert(guard.pack(b,0));assert(b:get_item(1)==a and b:get_item(0).id==301 and b:get_item(100).n==3 and total(b)==all);local fp=fingerprint(b);assert(guard.pack(b,0) and fp==fingerprint(b))end)
test('pack_locked_no_mutation',function()local b=newbag();b:set_item(5,Item.new(301,7,'prop',false,true));unchanged(b,function()assert(not guard.pack(b,0))end)end)
test('pack_invalid_tab',function()local b=newbag();b:set_item(5,Item.new(301,7));unchanged(b,function()assert(not guard.pack(b,3))end)end)
for _,race in ipairs({'source_moved','source_count','destination_filled','capacity_changed'}) do
 test('split_yield_'..race,function()
  local b=newbag(30);local item=Item.new(301,7);b:set_item(0,item)
  local saved=op.gen_item_guid;local external
  op.gen_item_guid=function()
   if race=='source_moved' then b:set_item(1,item);b:set_item(0,nil)
   elseif race=='source_count' then item.n=1
   elseif race=='destination_filled' then b:set_item(29,Item.new(303,4))
   else b:set_size({prop=20,material=20,task=20}) end
   external=fingerprint(b);return 9999
  end
  local ok,err=pcall(function()op:split_item({},b,0,2,b,29);assert(external==fingerprint(b),'race overwritten')end)
  op.gen_item_guid=saved;assert(ok,err)
 end)
end
test('split_repeat_conserves',function()local b=newbag();b:set_item(0,Item.new(301,7));for i=1,12 do op:split_item({},b,0,2,b,i) end;assert(total(b)==7);local guids={};for _,x in pairs(b.item_list)do assert(x.n>0 and not guids[x.guid]);guids[x.guid]=true end end)
test('packed_union_count_stackable',function()
 local a,z=Item.new(301,3),Item.new(301,4)
 function a:copy_raw_data()return{item_index=self.id,count=self.n,unknow_20={self.n,5},guid=self.guid}end
 z.copy_raw_data=a.copy_raw_data
 assert(guard.stackable(a,z))
end)
local messages={}
local function buyer(b)
 return {get_prop_bag_container=function()return b end,get_prop_bag=function()return b end,
 get_scene=function()return{send2client=function(_,_,msg)messages[#messages+1]=msg end}end,get_name=function()return'test'end,get_guid=function()return 200016 end}
end
local function multi(b,n,bind,hook,check)
 local old=op.gen_item
 op.gen_item=function(_,_,id) if hook then hook();hook=nil end;return Item.new(id,1)end
 local ok,a,c=pcall(logic.create_multi_item_to_bag,logic,{},buyer(b),301,n,bind,1,nil,nil,check)
 op.gen_item=old;assert(ok,a);return a,c
end
-- Old helper is the real loop's create-item dependency, modeled with the same
-- GUID yield and one-at-a-time insertion. New helper plans all inserts at once.
function logic:create_item_to_bag(_,human,id,bind)
 local b=human:get_prop_bag_container()
 local existing=b:get_no_full_item_index(id,bind)
 if existing>=0 then local x=b:get_item(existing);x.n=x.n+1;return existing end
 local item=op:gen_item({},id);item:set_is_bind(bind)
 local slot=b:get_empty_item_index('prop');if slot<0 then return -1 end;b:set_item(slot,item);return slot
end
test('multi_full_rejected_no_mutation',function()local b=newbag(1);b:set_item(0,Item.new(302,1));unchanged(b,function()assert(not multi(b,2,false))end)end)
test('multi_stack_full_bag',function()local b=newbag(1);local x=Item.new(301,5);b:set_item(0,x);assert(multi(b,7,false));assert(total(b)==12 and b:get_item(0)==x)end)
test('multi_bound_stack_not_mixed',function()local b=newbag(2);local x=Item.new(301,5,'prop',true);b:set_item(0,x);assert(multi(b,7,false));assert(total(b)==12 and x.n==5 and not b:get_item(1).bound)end)
test('multi_locked_stack_not_counted',function()local b=newbag(1);b:set_item(0,Item.new(301,5,'prop',false,true));unchanged(b,function()assert(not multi(b,7,false))end)end)
test('multi_splits_maximum',function()local b=newbag(3);assert(multi(b,43,false));assert(b:get_item(0).n==20 and b:get_item(1).n==20 and b:get_item(2).n==3 and total(b)==43)end)
test('multi_invalid_negative',function()local b=newbag();unchanged(b,function()assert(not multi(b,-1,false))end)end)
test('multi_invalid_fraction',function()local b=newbag();unchanged(b,function()assert(not multi(b,1.5,false))end)end)
test('multi_money_changed_during_guid',function()local b=newbag(2);local money=100;unchanged(b,function()assert(not multi(b,21,false,function()money=0 end,function()return money>=100 end))end)end)
test('multi_capacity_changed_during_guid',function()local b=newbag(2);local after;local ok=multi(b,21,false,function()b:set_item(1,Item.new(302,1));after=fingerprint(b)end);assert(not ok and after==fingerprint(b))end)
test('reload_misplaced_preserved',function()local b=Bag.new();b:init({prop=20,material=20,task=20},{['101']={item_index=301,count=7,guid=9,bag='prop'}},1);assert(b:get_save_data()['101'].count==7)end)
test('multi_identity_before_details',function()
 local b=newbag(3);messages={};assert(multi(b,43,false));assert(#messages==6)
 for i=1,#messages,2 do
  local a,z=messages[i],messages[i+1]
  assert(a._type=='GCNotifyEquip' and z._type=='GCItemInfo','details before slot identity')
  assert(a.bag_index==z.bagIndex and a.item.guid==z.item.guid and a.item.item_index==z.item.item_index)
 end
end)
test('pack_wire_rebuilds_client_slots',function()
 local b=newbag(20);b:set_item(2,Item.new(302,1));b:set_item(18,Item.new(301,9));b:set_item(19,Item.new(301,7))
 local slots={};for i,x in pairs(b.item_list)do slots[i]=x:copy_raw_data()end
 local packer=extract('services/scene/scenecore.lua','scenecore',{'char_pack_up_packet'})
 local h=buyer(b);local ack=false
 local s=setmetatable({objs={[1]=h},send2client=function(_,_,msg)
  if msg._type=='GCNotifyEquip' then slots[msg.bag_index]=clone(msg.item)
  elseif msg._type=='GCItemInfo' then
   local old=slots[msg.bagIndex]
   if msg.unknow_1==1 then slots[msg.bagIndex]=nil
   else
    assert(old and old.item_index==msg.item.item_index and old.guid==msg.item.guid,'detail targeted stale/missing identity')
    slots[msg.bagIndex]=clone(msg.item)
   end
  elseif msg._type=='GCPackUpPacket' then ack=true end
 end},{__index=packer})
 s:char_pack_up_packet(1,{unknow=0});assert(ack)
 for i=0,19 do local a,z=b:get_item(i),slots[i];assert((not a and not z) or (a and z and a.id==z.item_index and a.n==z.count and a.guid==z.guid)) end
end)
local function loot(b,source,kind,objtype)
 kind=kind or 1
 local boxbag=base.new();boxbag:init(10,{},7);boxbag:set_item(0,source)
 local picker=extract('services/scene/scenecore.lua','scenecore',{'char_pick_box_item'})
 env.configenginer={get_config=function()return {[2]={["脚本ID"]=-1}}end}
 local box={get_container=function()return boxbag end,get_item_box_type=function()return kind end,
  get_obj_type=function()return objtype or 'itembox' end,
  get_open_flag=function()return true end,get_type=function()return kind end,set_open_flag=function()end,
  erase_item=function(_,i)boxbag:erase_item(i)end,recycle=function()end}
 local h=buyer(b);h.on_pick_up_item=function()end
 local sent={};local s=setmetatable({objs={[1]=h,[2]=box},pick_notify=function()end,
  send2client=function(_,_,msg)sent[#sent+1]=msg end},{__index=picker})
 -- Baseline dependency increments one unit, exactly as its actual operator.
 function op:inc_item_lay_count(c,i)local x=c:get_item(i);x.n=x.n+1;return true end
 s:char_pick_box_item(1,{m_objID=2,item_guid=source.guid})
 return boxbag,sent
end
test('loot_whole_stack_conserved_and_source_guid',function()
 local b=newbag();local dest=Item.new(301,5);b:set_item(0,dest);local x=Item.new(301,3)
 local source,sent=loot(b,x);assert(total(b)==8 and total(source)==0,'whole loot row not transferred')
 assert(b:get_item(0)==dest and sent[#sent].item_guid==x.guid,'ack must identify source loot GUID')
end)
test('loot_full_bag_rejects_partial_stack',function()
 local b=newbag(1);b:set_item(0,Item.new(301,19));local x=Item.new(301,3)
 local before=fingerprint(b);local source,sent=loot(b,x)
 assert(before==fingerprint(b) and total(source)==3 and sent[#sent].result~=0)
end)
test('loot_large_stack_uses_empty_slot',function()
 local b=newbag(2);b:set_item(0,Item.new(301,19));local x=Item.new(301,3)
 local source=loot(b,x);assert(total(b)==22 and total(source)==0 and b:get_item(1)==x)
end)
test('loot_metadata_kept',function()
 local b=newbag(2);b:set_item(0,Item.new(301,5));local x=Item.new(301,3);x.record.expires=120
 local source=loot(b,x);assert(b:get_item(0).n==5 and b:get_item(1)==x and total(source)==0)
end)
test('loot_binding_kept',function()
 local b=newbag(2);b:set_item(0,Item.new(301,5,'prop',true));local x=Item.new(301,3)
 local source=loot(b,x);assert(b:get_item(0).n==5 and b:get_item(1)==x and total(source)==0)
end)
test('loot_locked_source_unchanged',function()
 local b=newbag();b:set_item(0,Item.new(301,5));local x=Item.new(301,3,'prop',false,true)
 local source=loot(b,x);assert(total(b)==5 and total(source)==3)
end)
test('gather_whole_stack_and_source_guid',function()
 local b=newbag();b:set_item(0,Item.new(301,5));local x=Item.new(301,3)
 local source,sent=loot(b,x,2);assert(total(b)==8 and total(source)==0 and sent[#sent].item_guid==x.guid)
end)
test('gather_bound_source_not_merged_into_unbound',function()
 local b=newbag(2);b:set_item(0,Item.new(301,5));local x=Item.new(301,3,'prop',true)
 local source=loot(b,x,2);assert(b:get_item(0).n==5 and b:get_item(1)==x and total(source)==0)
end)
test('gather_full_bag_unchanged',function()
 local b=newbag(1);b:set_item(0,Item.new(301,19));local x=Item.new(301,3)
 local before=fingerprint(b);local source=loot(b,x,2);assert(before==fingerprint(b) and total(source)==3)
end)
test('loot_wrong_object_type_rejected',function()
 local b=newbag();b:set_item(0,Item.new(301,5));local x=Item.new(301,3)
 local source,sent=loot(b,x,1,'monster');assert(total(b)==5 and total(source)==3 and #sent==0)
end)
test('round2_slot99_stack250_conservation',function()
 local b=newbag(100,100,20)
 local a,c=Item.new(301,249),Item.new(301,1);a.max=250;c.max=250
 b:set_item(0,a);b:set_item(99,c)
 local original=total(b)
 swap(b,99,0)
 assert(total(b)==original and b:get_item(0).n==250 and not b:get_item(99))
 unchanged(b,function()swap(b,99,0)end) -- replay of consumed source
end)
test('round2_full100_loot_replay_does_not_duplicate',function()
 local b=newbag(100,100,20)
 for i=0,99 do local x=Item.new(301,250);x.max=250;b:set_item(i,x)end
 local x=Item.new(301,1);x.max=250
 local before=fingerprint(b);local source=loot(b,x)
 assert(before==fingerprint(b) and total(b)==25000 and total(source)==1)
end)
test('round2_region99_100_and199_200_separate',function()
 local b=newbag(100,100,20)
 b:set_item(99,Item.new(301,1));b:set_item(199,Item.new(302,1,'material'))
 unchanged(b,function()swap(b,99,100);swap(b,199,200)end)
end)
-- Exercise the actual temporary-bag transaction module against the same real
-- containers/operators as swaps and loot, including repeated/stale requests.
modules.item_operator={getinstance=function()return op end};modules['game.packet']=packet
local tem=assert(load(read(guardpath:gsub('[^/]+$','cys_tembank.lua')),'@cys_tembank','t',env))()
local function temfixture()
 local b=newbag(100,100,20);local t=base.new();t:init(120,{},2)
 local h={cys_tembank=t,cys_tembank_revision=1,is_die=function()return false end,get_prop_bag_container=function()return b end,
  get_obj_id=function()return 1 end,get_scene=function()return {send2client=function()end}end}
 local s=setmetatable({},{__index=function()return function()end end})
 local x=Item.new(301,250);x.max=250;x.guid={world=1,server=2,series=1234};b:set_item(99,x)
 return h,s,b,t,x
end
test('tembank_deposit_withdraw_retains_guid_and_metadata',function()
 local h,s,b,t,x=temfixture();x.record.enhance=9;x.record.gems={12,24,36};x.bound=true
 tem.move(s,h,0,99,1,1,2,1234);assert(not b:get_item(99) and t:get_item(0)==x and h.cys_tembank_revision==2)
 tem.move(s,h,1,0,2,1,2,1234);assert(b:get_item(0)==x and not t:get_item(0) and x.n==250 and x.record.enhance==9 and x.bound)
end)
test('tembank_replay_cannot_move_replacement_item',function()
 local h,s,b,t,x=temfixture();tem.move(s,h,0,99,1,1,2,1234)
 local y=Item.new(302,1);y.guid={world=1,server=2,series=2345};b:set_item(99,y)
 tem.move(s,h,0,99,1,1,2,1234);assert(b:get_item(99)==y and t:get_item(0)==x and total(t)==250)
end)
for _,kind in ipairs({'guid','lock','revision','index','dead'}) do
 test('tembank_reject_'..kind,function()
  local h,s,b,t,x=temfixture();if kind=='lock' then x.locked=true end;if kind=='dead' then h.is_die=function()return true end end
  tem.move(s,h,0,kind=='index' and 200 or 99,kind=='revision' and 2 or 1,1,2,kind=='guid' and 99 or 1234)
  assert(b:get_item(99)==x and total(t)==0 and h.cys_tembank_revision==1)
 end)
end
test('tembank_full_destination_does_not_consume_source',function()
 local h,s,b,t,x=temfixture();for i=0,119 do local z=Item.new(999,250);z.max=250;t:set_item(i,z)end
 tem.move(s,h,0,99,1,1,2,1234);assert(b:get_item(99)==x and total(t)==30000 and h.cys_tembank_revision==1)
end)
test('tembank_take_all_full_bag_keeps_overflow',function()
 local h,s,b,t,x=temfixture();for i=0,99 do local z=Item.new(999,250);z.max=250;b:set_item(i,z)end
 t:set_item(119,x);tem.take_all(s,h,1);assert(t:get_item(119)==x and total(b)==25000 and h.cys_tembank_revision==1)
 b:erase_item(99);tem.take_all(s,h,1);assert(b:get_item(99)==x and total(t)==0 and h.cys_tembank_revision==2)
 tem.take_all(s,h,1);assert(total(b)==25000 and total(t)==0)
end)
test('tembank_sort_keeps_distinct_instances',function()
 local h,s,b,t,x=temfixture();b:erase_item(99);t:set_item(119,x)
 local y=Item.new(300,1);y.guid={world=1,server=2,series=999};t:set_item(90,y)
 tem.sort(s,h,1);assert(t:get_item(0)==y and t:get_item(1)==x and total(t)==251)
end)
local fails=0
for _,c in ipairs(cases) do local ok,err=pcall(c[2]);if not ok then fails=fails+1 end;print((ok and 'PASS ' or 'FAIL ')..c[1]..(ok and '' or ': '..tostring(err)))end
print(string.format('RESULT tests=%d failures=%d mode=%s time=%s',#cases,fails,mode or 'patched',os.date('!%FT%TZ')))
if mode=='baseline' then assert(fails>=10,'negative control did not detect original defects') else assert(fails==0,'inventory integrity failures') end
