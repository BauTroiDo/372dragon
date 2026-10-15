-- Player shops: native containers, integer currency and a single non-yielding commit.
local packets = require 'game.packet'
local define = require 'define'
local guard = require 'cys_inventory_guard'
local manager = require('playershopmanager'):getinstance()
local item_guid = require 'guid'
local M = {}
local MAX = 2147483647
local function equal(a,b)
    return a and b and a.m_uHighSection==b.m_uHighSection and a.m_uLowSection==b.m_uLowSection
end
local function pet_guid(g)
    return type(g)=='table' and guard.integer(g.m_uHighSection,1,4294967295)
        and guard.integer(g.m_uLowSection,1,4294967295)
end
local function pet_request(r)
    local g=r.pet_guid
    if pet_guid(g) then return true end
    if type(g)=='table' and g.m_uHighSection==0 and g.m_uLowSection==0 then return false end
end
local function fail(scene,h,code)
    if h then
        local msg=packets.GCPlayerShopError.new()
        msg.error_code=define.PLAYER_SHOP_ERR[code or 'ERR_NEED_NEW_COPY']
        scene:send2client(h,msg)
    end
    return false
end
local function human(scene,who)
    local h=scene:get_obj_by_id(who)
    if not h or h:is_die() or h._leaving or scene:check_item_limit_exchange(who) then return end
    return h
end
local function shop_for(h,g,manage)
    if type(g)~='table' or not guard.integer(g.world,0,65535) or not guard.integer(g.server,0,4294967295)
        or not guard.integer(g.scene,0,4294967295) or not guard.integer(g.pollpos,0,65535) then return end
    local shop=manager:get_player_shop_by_guid(g)
    if not shop then return end
    local status=shop:get_status()
    if status~=shop.STATUS.STATUS_PLAYER_SHOP_OPEN and status~=shop.STATUS.STATUS_PLAYER_SHOP_CLOSE then return end
    local owns=shop:get_owner_guid()==h:get_guid() or shop:is_partner(h:get_guid())
    if manage and not owns then return end
    if not manage and (owns or status~=shop.STATUS.STATUS_PLAYER_SHOP_OPEN) then return end
    return shop
end
local function stall_for(shop,index)
    if not guard.integer(index,0,shop.STALL_BOX_COUNT-1) then return end
    local st=shop:get_stall_box_by_index(index+1)
    if not st or st:get_status()==st.STATUS_STALL.STALL_INVALID then return end
    return st
end
local function find(container,r,pet)
    if pet then return container:get_index_by_pet_guid(r.pet_guid) end
    local g=r.item_guid
    if type(g)~='table' or not guard.integer(g.world,0,255) or not guard.integer(g.server,0,255)
        or not guard.integer(g.series,1,4294967295) then return end
    local key=item_guid.new();key:set_guid(g)
    return container:get_index_by_guid(key)
end
local function movable(h,p)
    return p and not p:is_lock() and not p:is_in_exchange()
        and not equal(p:get_guid(),h:get_current_pet_guid())
        and not equal(p:get_guid(),h:get_current_soul_melting_pet_guid())
end
local function income_ok(shop,n)
    local b,p,m=shop:get_base_money(),shop:get_profit_money(),shop:get_max_base_money()
    if not guard.integer(b,0,MAX) or not guard.integer(p,0,MAX) or not guard.integer(m,0,MAX) then return false end
    return p+math.max(0,n-math.max(0,m-b))<=MAX
end
local function receipt(shop,st,r,p,pet,to,deposit,is_manager)
    local msg=packets.GCItemSynch.new();msg.opt=msg.OPT.OPT_MOVE_ITEM
    msg.from_type=deposit and (pet and 2 or 0) or (pet and 5 or 4)
    msg.to_type=deposit and (pet and 5 or 4) or (pet and 2 or 0)
    msg.to_index=to
    if pet then msg.pet_guid=p:get_guid() else msg.item_guid=p:get_guid() end
    local name='GCMove'..(pet and 'Pet' or 'Item')..(deposit and 'FromBagToPlayerShop_t' or 'FromPlayerShopToBag_t')
    local e=packets[name].new();e.shop_guid=shop:get_guid();e.stall_index=r.stall_index
    e.flag=is_manager and 1 or 0;e.serial=st:get_serial_by_index(r.slot);e.shop_serial=shop:get_serial()
    msg.extra_data=e:bos()
    return msg
end
local function clear_sale(shop,st,slot)
    st:set_can_sale(slot,0);st:set_price_by_index(slot,0);st:inc_serial_by_index(slot);shop:inc_serial()
end

function M.buy(scene,who,r)
    local h=human(scene,who);if not h then return false end
    local shop=shop_for(h,r.shop_id,false);if not shop then return fail(scene,h) end
    local pet=pet_request(r);if pet==nil or shop:get_type()~=(pet and shop.TYPE.PET or shop.TYPE.ITEM) then return fail(scene,h) end
    local st=stall_for(shop,r.stall_index)
    if not st or st:get_status()~=st.STATUS_STALL.STALL_OPEN then return fail(scene,h) end
    local src=pet and st:get_pet_container() or st:get_item_container()
    local slot=find(src,r,pet)
    if not guard.accepts(src,slot) or not st:can_sale(slot) or st:get_serial_by_index(slot)~=r.serial then return fail(scene,h) end
    local p=src:get_item(slot);if not p or p:is_lock() or (pet and p:is_in_exchange()) or (not pet and p:is_bind()) then return fail(scene,h) end
    local dest=pet and h:get_pet_bag_container() or h:get_prop_bag_container()
    local to=pet and dest:get_empty_item_index() or dest:get_empty_item_index(p:get_place_bag())
    if not guard.accepts(dest,to,pet and nil or p) or dest:get_item(to) then return fail(scene,h,'ERR_NOT_ENOUGH_ROOM') end
    if find(dest,r,pet)~=nil then return fail(scene,h) end
    local price=st:get_price_by_index(slot)
    if not guard.integer(price,1,MAX) or h:get_money()<price then return fail(scene,h,'ERR_NOT_ENOUGH_MONEY') end
    local income=math.floor(price*98/100)
    if not income_ok(shop,income) then return fail(scene,h) end
    -- All validation and these setters are local; no skynet.call/config RPC here.
    -- Move the existing object, retaining GUID, skills, equipment and aptitude.
    src:set_item(slot,nil);dest:set_item(to,p)
    if pet then p.owner=h end
    h:set_money(h:get_money()-price,'CYS player shop purchase')
    shop:add_money(income);clear_sale(shop,st,slot)
    if pet then shop:record(shop.OPT_RECORD.REC_EXCHANGEPET,shop:get_exchange_record(),p:get_attrib('name'),1,income)
    else shop:record(shop.OPT_RECORD.REC_EXCHANGEITEM,shop:get_exchange_record(),p:get_index(),p:get_lay_count(),income) end
    scene:send2client(h,receipt(shop,st,{stall_index=r.stall_index,slot=slot},p,pet,to,false,false))
    if pet then h:send_pets_detail(h)
    else
        local info=packets.GCItemInfo.new();info.bagIndex=to;info.item=p:copy_raw_data()
        scene:send2client(h,info)
    end
    return true
end

function M.on_sale(scene,who,r)
    local h=human(scene,who);if not h then return false end
    local shop=shop_for(h,r.shop_id,true)
    if not shop or shop:get_serial()~=r.shop_serial or not guard.integer(r.is_on_sale,0,1) then return fail(scene,h) end
    local pet=pet_request(r);if pet==nil or shop:get_type()~=(pet and shop.TYPE.PET or shop.TYPE.ITEM) then return fail(scene,h) end
    local st=stall_for(shop,r.stall_index);if not st then return fail(scene,h) end
    local c=pet and st:get_pet_container() or st:get_item_container();local slot=find(c,r,pet)
    if not guard.accepts(c,slot) or st:get_serial_by_index(slot)~=r.serial then return fail(scene,h) end
    local p=c:get_item(slot)
    if not p or p:is_lock() or (pet and p:is_in_exchange()) or (not pet and p:is_bind()) then return fail(scene,h) end
    if r.is_on_sale==1 and not guard.integer(r.price,50,MAX) then return fail(scene,h) end
    if r.is_on_sale==0 and not st:can_sale(slot) then return fail(scene,h) end
    local old=st:get_price_by_index(slot);local price=r.is_on_sale==1 and r.price or 0
    st:set_can_sale(slot,r.is_on_sale);st:set_price_by_index(slot,price)
    local msg=packets.GCPlayerShopOnSale.new()
    msg.shop_guid=shop:get_guid();msg.stall_index=r.stall_index;msg.is_on_sale=r.is_on_sale
    msg.item_guid=r.item_guid;msg.pet_guid=r.pet_guid;msg.price=price
    msg.serial=st:inc_serial_by_index(slot);msg.shop_serial=shop:inc_serial()
    local op='REC_'..(r.is_on_sale==1 and 'ONSALE' or 'OFFSALE')..(pet and 'PET' or 'ITEM')
    shop:record(shop.OPT_RECORD[op],shop:get_manager_record(),h:get_name(),pet and p:get_attrib('name') or p:get_index(),pet and 1 or p:get_lay_count(),r.is_on_sale==1 and price or old)
    scene:send2client(h,msg);return true
end

function M.move_pet(scene,who,r)
    local h=human(scene,who);if not h then return false end
    local deposit=r.from_type==2 and r.to_type==5
    if not deposit and not (r.from_type==5 and r.to_type==2) then return fail(scene,h) end
    if r.opt~=packets.CGItemSynch.OPT.OPT_MOVE_ITEM_AUTO or not pet_guid(r.pet_guid) then return fail(scene,h) end
    -- CY deposit pet extra has the same GUID/u8/u8 layout as item deposit.
    local cls=deposit and packets.CGAutoMoveItemFromBagToPlayerShop_t or packets.CGAutoMovePetFromPlayerShopToBag_t
    if type(r.extra_data)~='string' or #r.extra_data~=(deposit and 14 or 15) then return fail(scene,h) end
    local e=cls.new();local ok=pcall(e.bis,e,r.extra_data);if not ok then return fail(scene,h) end
    local shop=shop_for(h,e.shop_guid,true)
    if not shop or shop:get_type()~=shop.TYPE.PET or shop:get_serial()~=e.shop_serial then return fail(scene,h) end
    local st=stall_for(shop,e.stall_index);if not st then return fail(scene,h) end
    local bag,box=h:get_pet_bag_container(),st:get_pet_container()
    local src,dest=deposit and bag or box,deposit and box or bag
    local slot=find(src,r,true);local to=dest:get_empty_item_index()
    if not guard.accepts(src,slot) then return fail(scene,h) end
    if not guard.accepts(dest,to) then return fail(scene,h,'ERR_NOT_ENOUGH_ROOM') end
    local p=src:get_item(slot)
    if not movable(h,p) or find(dest,r,true)~=nil or dest:get_item(to) then return fail(scene,h) end
    if not deposit and (st:can_sale(slot) or st:get_serial_by_index(slot)~=e.serial) then return fail(scene,h) end
    src:set_item(slot,nil);dest:set_item(to,p);p.owner=not deposit and h or nil
    local shop_slot=deposit and to or slot;clear_sale(shop,st,shop_slot)
    shop:record(shop.OPT_RECORD[deposit and 'REC_ADDPET' or 'REC_DELPET'],shop:get_manager_record(),h:get_name(),p:get_attrib('name'),1)
    scene:send2client(h,receipt(shop,st,{stall_index=e.stall_index,slot=shop_slot},p,true,to,deposit,true))
    h:send_pets_detail(h)
    return true
end

function M.money(scene,who,r)
    local h=human(scene,who);if not h then return false end
    local shop=shop_for(h,r.shop_id,true)
    if not shop or shop:get_serial()~=r.serial or not guard.integer(r.amount,1,MAX) then return fail(scene,h) end
    local P=packets.CGPlayerShopMoney
    local base=r.type==P.TYPE.TYPE_BASE_MONEY
    if not base and r.type~=P.TYPE.TYPE_PROFIT_MONEY then return fail(scene,h) end
    local old=base and shop:get_base_money() or shop:get_profit_money();local balance=h:get_money();local next_value
    if r.opt==P.OPT.OPT_SAVE_MONEY then
        if balance<r.amount then return fail(scene,h,'ERR_NOT_ENOUGH_MONEY') end
        next_value=old+math.floor(r.amount*97/100)
        if next_value>(base and 10000000 or MAX) then return fail(scene,h) end
        balance=balance-r.amount
    elseif r.opt==P.OPT.OPT_GET_MONEY then
        if old<r.amount or balance+r.amount>MAX then return fail(scene,h) end
        next_value=old-r.amount;balance=balance+r.amount
    else return fail(scene,h) end
    if base then shop:set_base_money(next_value) else shop:set_profit_money(next_value) end
    h:set_money(balance,'CYS player shop funds')
    local msg=packets.GCPlayerShopMoney.new();msg.shop_id=shop:get_guid();msg.type=r.type
    msg.amount=next_value;msg.serial=shop:inc_serial()
    scene:send2client(h,msg);return true
end

function M.send_pet_list(shop,h,index,sign,is_manager)
    local scene=h:get_scene();local owns=shop:get_owner_guid()==h:get_guid() or shop:is_partner(h:get_guid())
    if (is_manager and not owns) or (not is_manager and owns) then return false end
    local st=stall_for(shop,index-1);if not st then return false end
    if not owns and shop:get_status()~=shop.STATUS.STATUS_PLAYER_SHOP_OPEN then return false end
    local e=packets[owns and 'GCPlayerShopItemListForSelf_t' or 'GCPlayerShopItemListForOther_t'].new()
    e.flag=owns and 2 or 1;e.shop_guid=shop:get_guid();e.shop_id=shop:get_manager():get_id_by_guid(e.shop_guid)
    e.is_item_list=0;e.ui_flag=sign;e.is_sale_out=0;e.sale_out_price=shop:get_sale_out_price() or 0
    e.base_money=shop:get_base_money();e.profit_money=shop:get_profit_money();e.owner_guid=shop:get_owner_guid()
    e.stall_num=shop:get_stall_opend_num();e.type=shop:get_type();e.serial=shop:get_serial()
    e.owner_name=shop:get_owner_name();e.shop_name=shop:get_name();e.desc=shop:get_desc();e.stall_is_open={}
    e.ex_rec_list_num=#shop:get_exchange_record();e.ma_rec_list_num=#shop:get_manager_record();e.com_factor=shop:get_manager():get_com_factor()
    for i=1,shop.STALL_BOX_COUNT do local s=shop:get_stall_box_by_index(i);e.stall_is_open[i]=s:get_status()==s.STATUS_STALL.STALL_OPEN and 2 or 1 end
    local msg=packets.GCItemList.new();msg.opt=msg.OPT.OPT_ADD_ITEM_LIST;msg.extra_data=e:bos()
    local details={};local c=st:get_pet_container()
    for i=0,c:get_size()-1 do
        local p=c:get_item(i)
        if p and (owns or (st:get_status()==st.STATUS_STALL.STALL_OPEN and st:can_sale(i))) then
            local d=packets.GCDetailAttrib_Pet.new();p:calculate_pet_detail_attrib(d);d.m_nTradeIndex=i
            -- Native GCPlayerShopPetView: flag, alignment, price, serial, own/stall/sale, alignment.
            local bytes=string.pack('<BxxxI4I4BBBx',3,st:get_price_by_index(i),st:get_serial_by_index(i),owns and 1 or 0,index-1,st:can_sale(i) and 1 or 0)
            d.unknow_6=#bytes;d.unknow_7={bytes:byte(1,#bytes)};details[#details+1]=d
        elseif owns then
            local x=packets.GCPlayerShopItemListEachSerialForSelf_t.new();x.stall_index=index-1;x.item_serial=st:get_serial_by_index(i)
            msg.item_list[#msg.item_list+1]={index=i,type=msg.TYPE.TYPE_SERIALS,extra_info=x:bos()}
        end
    end
    scene:send2client(h,msg)
    for _,d in ipairs(details) do scene:send2client(h,d) end
    if owns then shop:send_partner_list(h) end
    return true
end
function M.send_item_details(shop,h,index,is_manager)
    local owns=shop:get_owner_guid()==h:get_guid() or shop:is_partner(h:get_guid())
    if (is_manager and not owns) or (not is_manager and owns) then return end
    local st=stall_for(shop,index-1);if not st then return end
    if not owns and shop:get_status()~=shop.STATUS.STATUS_PLAYER_SHOP_OPEN then return end
    local c=st:get_item_container()
    for i=0,c:get_size()-1 do
        local p=c:get_item(i)
        if p and (owns or (st:get_status()==st.STATUS_STALL.STALL_OPEN and st:can_sale(i))) then
            local info=packets.GCItemInfo.new();info.bagIndex=1000+(owns and 200 or 0)+(index-1)*20+i
            info.item=p:copy_raw_data();h:get_scene():send2client(h,info)
        end
    end
end
return M
