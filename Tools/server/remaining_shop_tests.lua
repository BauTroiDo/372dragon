-- Execute the staged shop/containers/codecs with isolated actors; no database writes.
local root=assert(arg[1]);local stage=assert(arg[2])
package.path=stage..'/GameServer/lualib/?.lua;'..root..'/GameServer/lualib/?.lua;'..root..'/GameServer/services/?.lua;'..package.path
local n=0
local function eq(a,b,label)n=n+1;assert(a==b,(label or '')..': '..tostring(a)..' ~= '..tostring(b))end
local function clone(v)if type(v)~='table'then return v end;local r={};for k,x in pairs(v)do r[k]=clone(x)end;return r end
table.clone=clone
local skynet={getenv=function()return '1'end,send=function()end};package.loaded.skynet=skynet
package.loaded.configenginer={getinstance=function()return{}end}
local class=require 'class';local define=require 'define';local ioapi=require 'iostream'
local packets={};local gbk={fromutf8=function(s)return s end,toutf8=function(s)return s end}
for _,mod in ipairs({'packet_types.guid','packet_types.playershop_types','packet_domains.misc','packet_domains.shop','packet_domains.item'})do
    require('game.'..mod).bind(packets,ioapi.bistream,ioapi.bostream,gbk,define)
end
-- Item and pet fixtures deliberately have distinct loaders; the real containers
-- must pick pet_detail on a sparse persisted pet shop, never item.init_from_data.
local Pet=class('fixture_pet')
function Pet:init_from_data(d,owner)self.d=clone(d);self.owner=owner;self.kind='pet'end
function Pet:copy_raw_data()return clone(self.d)end
function Pet:get_guid()return self.d.guid end
function Pet:get_attrib(k)return self.d[k]end
function Pet:is_lock()return self.locked end
function Pet:is_in_exchange()return self.exchange end
function Pet:calculate_pet_detail_attrib(msg)msg.guid=self:get_guid()end
local Item=class('fixture_item')
function Item:init_from_data(d)self.d=clone(d);self.kind='item'end
function Item:copy_raw_data()return clone(self.d)end
function Item:get_guid()local g=require('guid').new();g:set_guid(self.d.guid);return g end
function Item:is_bind()return self.bound end
function Item:is_lock()return self.locked end
function Item:get_place_bag()return 'prop'end
function Item:get_index()return 10101001 end
function Item:get_lay_count()return 7 end
package.loaded.item=Item;package.loaded.pet_detail=Pet
package.loaded['game.packet']=packets
local manager={shops={}}
function manager:getinstance()return self end
function manager:get_player_shop_by_guid(g)for _,s in ipairs(self.shops)do if s:get_guid()==g then return s end end end
function manager:get_id_by_guid()return 0 end
function manager:get_com_factor()return .5 end
package.loaded.playershopmanager=manager
local Shop=require 'playershop';local Container=require 'pet_container';local Items=require 'item_container'
local function bag(size)local c=Container.new();c:init(size,{});return c end
local scene={sent={}}
local function human(id)
    local h={id=id,bag=bag(3),money=10000,current={},soul={}};h.items=Items.new();h.items:init(100,{})
    function h:get_guid()return self.id end
    function h:get_name()return 'fixture-'..self.id end
    function h:get_scene()return scene end
    function h:is_die()return self.dead end
    function h:get_pet_bag_container()return self.bag end
    function h:get_prop_bag_container()return self.items end
    function h:get_current_pet_guid()return self.current end
    function h:get_current_soul_melting_pet_guid()return self.soul end
    function h:get_money()return self.money end
    function h:set_money(v)assert(v>=0 and v<=2147483647);self.money=v;return true end
    function h:send_pets_detail()end
    return h
end
local owner,buyer,other=human(1),human(2),human(3);local humans={owner,buyer,other}
function scene:get_obj_by_id(id)return humans[id]end
function scene:check_item_limit_exchange()return false end
function scene:send2client(h,p)
    -- Serialize replies before accepting success: catches nil GUID / malformed extras.
    if p.bos then p:bos()end
    self.sent[#self.sent+1]={human=h,packet=p}
end
packets.GCDetailAttrib_Pet={new=function()return{}end}
local function make_shop(pet,id)
    local s=Shop.new(manager)
    s:load{guid={world=1,server=1,scene=0,pollpos=id},status=2,type=pet and 1 or 0,
        owner_guid=1,owner_name='owner',name='test',desc='',max_base_money=1000,base_money=1000,profit_money=0,
        founded_day=260928,stall_opend_num=1,stall_on_sal_num=0,sale_out_price=0,partner_list={},exchange_record={},manager_record={},
        stall_list_data={['1']={status=2,item_list={}}}}
    manager.shops[#manager.shops+1]=s;return s
end
local s=make_shop(true,1);local st=s:get_stall_box_by_index(1);local c=st:get_pet_container()
local M=require 'cys_player_shop'
local function pet(id)local p=Pet.new();p:init_from_data{guid={m_uHighSection=1,m_uLowSection=id},name='Pet',skills={17,99},equips={quality=255,life=0},aptitude={1234,5678}};return p end
local p=pet(11);owner.bag:set_item(0,p)
local function move(deposit,who,serial)
    local e=(deposit and packets.CGAutoMoveItemFromBagToPlayerShop_t or packets.CGAutoMovePetFromPlayerShopToBag_t).new()
    -- CG classes only read, so encode their actual schema independently.
    local w=ioapi.bostream.new();packets.PlayerShopGUID.bos(s:get_guid(),w);w:writeuchar(0)
    if not deposit then w:writeuchar(st:get_serial_by_index(c:get_index_by_pet_guid(p:get_guid()) or 0))end
    w:writeuchar(serial or s:get_serial())
    return M.move_pet(scene,who or 1,{opt=packets.CGItemSynch.OPT.OPT_MOVE_ITEM_AUTO,from_type=deposit and 2 or 5,to_type=deposit and 5 or 2,pet_guid=p:get_guid(),extra_data=w:get()})
end
local function sale(on,who,price)
    return M.on_sale(scene,who or 1,{shop_id=s:get_guid(),stall_index=0,shop_serial=s:get_serial(),serial=st:get_serial_by_index(0),is_on_sale=on,price=price or 500,
        pet_guid=p:get_guid(),item_guid={world=0,server=0,series=0,mask=0}})
end
local function request()return{shop_id=s:get_guid(),stall_index=0,serial=st:get_serial_by_index(0),pet_guid=p:get_guid(),item_guid={world=0,server=0,series=0,mask=0}}end
eq(move(true,3),false,'foreign pet');eq(owner.bag:get_item(0),p)
for _,blocked in ipairs({'locked','exchange','current','soul','dead','leaving'})do
    p.locked=blocked=='locked';p.exchange=blocked=='exchange';owner.current=blocked=='current' and p:get_guid() or {};owner.soul=blocked=='soul' and p:get_guid() or {}
    owner.dead=blocked=='dead';owner._leaving=blocked=='leaving'
    eq(move(true),false,blocked);eq(owner.bag:get_item(0),p);eq(c:get_count(),0)
end
p.locked=false;p.exchange=false;owner.current={};owner.soul={};owner.dead=false;owner._leaving=false
eq(move(true),true,'deposit');eq(owner.bag:get_item(0),nil);eq(c:get_item(0),p);eq(p.owner,nil)
eq(move(true),false,'duplicate deposit');eq(sale(1,3),false,'foreign listing')
for _,price in ipairs({0,-1,49,2147483648,1.5})do eq(sale(1,1,price),false,'invalid price')end
eq(sale(1),true,'pet GUID on-sale');eq(st:can_sale(0),true);eq(move(false),false,'unlist before withdrawal')
local r=request();local before=buyer.money
buyer.money=499;eq(M.buy(scene,2,r),false,'not enough money');eq(c:get_item(0),p)
buyer.money=before;for i=0,2 do buyer.bag:set_item(i,pet(100+i))end
eq(M.buy(scene,2,r),false,'full bag');eq(buyer.money,before);eq(c:get_item(0),p)
for i=0,2 do buyer.bag:set_item(i,nil)end
st:set_status(1);eq(M.buy(scene,2,r),false,'closed stall');st:set_status(2)
eq(M.buy(scene,1,r),false,'cannot buy own shop');eq(M.buy(scene,99,r),false,'unknown actor')
eq(M.buy(scene,2,r),true,'buy');eq(buyer.money,before-500);eq(s:get_profit_money(),490,'2 percent fee')
eq(c:get_item(0),nil);eq(buyer.bag:get_item(0),p);eq(p.owner,buyer);eq(p.d.equips.life,0);eq(p.d.equips.quality,255)
eq(M.buy(scene,3,r),false,'second buyer stale copy');eq(other.money,10000);eq(other.bag:get_count(),0)
eq(M.buy(scene,2,r),false,'replayed purchase');eq(buyer.money,before-500)
local ack=scene.sent[#scene.sent-2].packet
-- Restore the fixture pet to its owner by direct test setup, then exercise withdrawal.
buyer.bag:set_item(0,nil);owner.bag:set_item(0,p)
eq(move(true),true);eq(move(false),true);eq(owner.bag:get_item(0),p);eq(c:get_item(0),nil);eq(p.owner,owner)
eq(move(false),false,'replayed withdrawal')
eq(move(true),true);st:set_can_sale(0,true);eq(st:can_sale(0),true,'normalize boolean');st:set_can_sale(0,false);eq(st:can_sale(0),false)
local saved=s:copy_raw_data();saved.stall_list_data[1].item_list['8']=saved.stall_list_data[1].item_list['1'];saved.stall_list_data[1].item_list['1']=nil
saved.stall_list_data[1].item_is_on_sale['7']=true
local restored=Shop.new(manager);restored:load(saved);local rc=restored:get_stall_box_by_index(1):get_pet_container()
eq(rc:get_item(0),nil,'sparse reload');eq(rc:get_item(7).kind,'pet','pet class, not item');eq(rc:get_item(7).d.equips.life,0)
eq(rc:get_item(7).d.skills[2],99);eq(restored:get_serial(),s:get_serial());eq(restored:get_stall_box_by_index(1):can_sale(7),true)
-- A change arriving during a yielding DB save must not get marked clean.
skynet.call=function(_,_,method)eq(method,'safe_update','persistence uses acknowledged writes');s:set_profit_money(600);return true end
s.data_changed=true;s:heart_beat();eq(s.data_changed,true,'dirty during save remains dirty')
skynet.call=function()return true end;s:heart_beat();eq(s.data_changed,false)
skynet.call=function()return nil,'failed'end;s:set_data_changed();s:heart_beat();eq(s.data_changed,true,'failed save retried')
local P=packets.CGPlayerShopMoney
local function money(opt,amount,who,kind,serial)return M.money(scene,who or 1,{shop_id=s:get_guid(),serial=serial or s:get_serial(),opt=opt,amount=amount,type=kind or P.TYPE.TYPE_PROFIT_MONEY})end
local start=owner.money
eq(money(P.OPT.OPT_GET_MONEY,100,3),false,'foreign funds');eq(money(P.OPT.OPT_GET_MONEY,-1),false,'negative funds')
local seq=s:get_serial();eq(money(P.OPT.OPT_GET_MONEY,100),true);eq(owner.money,start+100);eq(s:get_profit_money(),500)
eq(money(P.OPT.OPT_GET_MONEY,100,1,nil,seq),false,'replayed funds');eq(owner.money,start+100)
eq(money(P.OPT.OPT_SAVE_MONEY,101),true);eq(s:get_profit_money(),597,'integer 3 percent fee');eq(owner.money,start-1)
owner.money=2147483647;eq(money(P.OPT.OPT_GET_MONEY,1),false,'no saturated balance loss');eq(s:get_profit_money(),597)
-- The real list codec must contain both shop metadata and pet view context.
eq(M.send_pet_list(s,owner,1,0,true),true)
local header
for _,row in ipairs(scene.sent)do if row.packet.extra_data and row.packet.opt==packets.GCItemList.OPT.OPT_ADD_ITEM_LIST then header=row.packet end end
eq(#header.extra_data,200,'manager metadata byte length')
eq(header.extra_data:byte(1),2,'manager metadata kind')
local detail
for _,row in ipairs(scene.sent)do if row.packet.unknow_6==16 then detail=row.packet end end
assert(detail);eq(detail.m_nTradeIndex,0);eq(detail.unknow_7[1],3);eq(detail.unknow_7[13],1);eq(detail.unknow_7[14],0)
st:set_can_sale(0,true)
eq(M.send_pet_list(s,buyer,1,0,false),true)
header=scene.sent[#scene.sent-1].packet
eq(#header.extra_data,184,'customer metadata byte length differs from manager')
eq(header.extra_data:byte(1),1,'customer metadata kind')
detail=scene.sent[#scene.sent].packet
eq(detail.unknow_7[13],0,'customer pet context')
eq(detail.unknow_7[15],1,'customer listed pet')
for _,bad in ipairs({-1,10,1.5})do local x=request();x.stall_index=bad;eq(M.buy(scene,2,x),false,'bounds')end
-- Real manager projection and list codec, including repeated initialization.
table.tostr=function()return '<test>'end
local saved_shop=s:copy_raw_data();local scene_id=saved_shop.guid.scene
skynet.call=function(_,_,method,sql)
    eq(method,'findAll');eq(sql.query['guid.scene'],scene_id)
    eq(sql.query['guid.world'],1);eq(sql.query['guid.server'],1)
    return {saved_shop}
end
local Manager=assert(loadfile(stage..'/GameServer/lualib/playershopmanager.lua'))()
local actual_manager=Manager.new();local actual_scene={get_id=function()return scene_id end}
actual_manager:init(actual_scene);actual_manager:init(actual_scene)
eq(#actual_manager:get_player_shops(),1,'reload does not append duplicates')
local list=packets.GCPlayerShopAcquireShopList.new();list.npc_id=-1;list.com_factor=.5;list.shop_infos=actual_manager:get_shop_infos()
local encoded=list:bos();local decoded=packets.GCPlayerShopAcquireShopList.new();decoded:bis(encoded)
eq(#decoded.shop_infos,1,'real shop list codec');eq(decoded.shop_infos[1].stall_open_num,s:get_stall_opend_num())
print('PASS player shop '..n..' assertions: move/list/buy/replay/money/ownership/locks/full/sparse-reload/dirty-save/actual reply codecs')
