-- Read-only: call the actual stall-buy function with isolated actors/transport.
-- HJ #123 says "bay ban shop KNB pet"; that is distinct from player-shop stores.
local root=assert(arg[1]);local expect_format_bug=arg[2]=='baseline'
local f=assert(io.open(root..'/GameServer/services/scene/scenecore.lua'))
local raw=f:read('*a');f:close()
local body=assert(raw:match('(function scenecore:char_stall_buy%b().-\nend)'))
local n=0
local function eq(a,b,msg)n=n+1;assert(a==b,(msg or '')..': '..tostring(a)..' ~= '..tostring(b))end
local function case(yuanbao)
 local pet={guid={m_uHighSection=9,m_uLowSection=123},aptitude=1234}
 function pet:have_equip()return false end
 function pet:copy_raw_data()return{guid=self.guid,aptitude=self.aptitude}end
 function pet:get_transfer()return{}end
 local bag={item=pet};function bag:get_index_by_pet_guid()return self.item and 0 end
 function bag:get_item()return self.item end
 local dest={};function dest:get_empty_item_index()return self.item and -1 or 0 end
 local box={item=pet};function box:get_index_by_pet_guid()return self.item and 0 end
 function box:erase_item()self.item=nil end
 local stall={serial=1,price=500,STALL_STATUS={STALL_OPEN=2}}
 function stall:get_stall_status()return 2 end
 function stall:get_is_yuanbao_stall()return yuanbao end
 function stall:get_pet_box_container()return box end
 function stall:get_pet_serial_by_index()return self.serial end
 function stall:get_pet_price_by_index()return self.price end
 function stall:get_trade_tax()return 2 end
 function stall:inc_pet_serial_by_index()self.serial=self.serial+1 end
 function stall:set_pet_price_by_index(_,p)self.price=p end
 function stall:get_bbs()return{new_message_id=function()return 1 end,add_new_message_by_id=function()end}end
 local function human(id,b)
  local h={id=id,bag=b,money=10000,yuanbao=20000}
  function h:get_mission_flag_by_script_id()return 1 end
  function h:get_stall_box()return stall end
  function h:get_pet_bag_container()return self.bag end
  function h:get_obj_id()return self.id end
  function h:get_name()return 'currency-fixture' end
  function h:get_money()return self.money end
  function h:set_money(v)self.money=v end
  function h:get_yuanbao()return self.yuanbao end
  function h:set_yuanbao(v)self.yuanbao=v end
  return h
 end
 local buyer,seller=human(1,dest),human(2,bag)
 local packets=setmetatable({},{__index=function(_,key)return{new=function()
  return {name=key,STALL_MSG={ERR_ILLEGAL=1,ERR_NEED_NEW_COPY=2,ERR_NOT_ENOUGH_ROOM=3,ERR_NOT_ENOUGH_MONEY=4}}
 end}end})
 local scene={objs={buyer,seller}}
 function scene:check_item_limit_exchange()return false end
 function scene:send2client(_,p)self.last=p end
 function scene:log_exchange_prop_or_pet()end
 local env=setmetatable({scenecore={},packet_def=packets,MF_TradeCard=1,define={INVAILD_ID=-1},
  item_guid={new=function()return{set_guid=function()end,vaild=function()return false end}end},
  pet_guid={new=function()return{set=function()end,is_null=function()return false end}end},
  item_operator={unlock_item=function()end,move_item=function(_,src,index,dst)dst.item=src.item;src.item=nil;return 0 end}}, {__index=_G})
 assert(load(body,'@actual-char-stall-buy','t',env))()
 local buy=env.scenecore.char_stall_buy;local r={m_objID=2,serial=1,item_guid={},pet_guid=pet.guid}
 local ok,err=pcall(buy,scene,1,r)
 if expect_format_bug and not yuanbao then
  eq(ok,false,'base currency hits integer formatter after commit')
  assert(tostring(err):find('number has no integer representation',1,true))
  print('CONFIRMED base-currency stall BBS formatter fails after transfer/payment')
 else assert(ok,err) end
 eq(dest.item,pet,'same pet object');eq(bag.item,nil,'seller bag emptied');eq(box.item,nil,'stall emptied')
 eq(pet.aptitude,1234,'aptitude retained');eq(scene.last.profit,490,'2 percent fee')
 eq(buyer.money,yuanbao and 10000 or 9500,'buyer base currency')
 eq(seller.money,yuanbao and 10000 or 10490,'seller base currency')
 eq(buyer.yuanbao,yuanbao and 19500 or 20000,'buyer yuanbao')
 eq(seller.yuanbao,yuanbao and 20490 or 20000,'seller yuanbao')
 buy(scene,1,r)
 eq(scene.last.result,2,'replay rejected');eq(dest.item,pet,'no extra pet')
 eq(buyer.yuanbao,yuanbao and 19500 or 20000,'replay no yuanbao debit')
 eq(seller.money,yuanbao and 10000 or 10490,'replay no gold credit')
 print('PASS pet stall currency='..(yuanbao and 'yuanbao' or 'base')..' balance/ownership/replay')
end
case(true);case(false)
print('PASS '..n..' checks: actual stall pet sale credits the selected currency; no runtime or database writes')
