-- Allocate the entire reward before EndAddItem reports success. Commit uses
-- prepared objects only; no GUID/config RPC can split a multi-item reward.
local batches=require 'cys_script_item_batches'
local guard=require 'cys_inventory_guard'
local operator=require('item_operator'):getinstance()
local cfg=require('configenginer'):getinstance()
local packets=require 'game.packet'
local skynet=require 'skynet'
local M={}
local function same(a,b)
    if type(a)~=type(b)then return false end
    if type(a)~='table'then return a==b end
    for k,v in pairs(a)do if not same(v,b[k])then return false end end
    for k in pairs(b)do if a[k]==nil then return false end end
    return true
end
local function plan(h,products)
    local bag=h:get_prop_bag_container()
    local changes={}
    for _,product in ipairs(products)do
        local left,next_new=product.count,1
        for pos,original in bag:ipairs(product.kind)do
            local change=changes[pos]
            local item=change and change.item or original
            if left>0 and guard.stackable(product.sample,item)then
                local count=change and change.count or item:get_lay_count()
                local add=math.min(left,product.maximum-count)
                if add>0 then
                    changes[pos]=change or {item=item,old=original,before=original:copy_raw_data()}
                    changes[pos].count=count+add;left=left-add
                end
            end
        end
        for pos,original in bag:ipairs(product.kind)do
            if left>0 and not original and not changes[pos]then
                local add=math.min(left,product.maximum)
                changes[pos]={item=product.prepared[next_new],count=add}
                left=left-add;next_new=next_new+1
            end
        end
        if left>0 then return nil end
    end
    return changes,bag
end
local function prepare(script,who,way)
    local batch=batches.get(script);batch.prepared=nil
    local h=script.scene:get_obj_by_id(who)
    if not h or #batch.items==0 then return false end
    local products={};way=way or 0
    for _,row in ipairs(batch.items)do
        local id,count=row.item_index,row.count
        if not guard.integer(id,10000000,79999999)or not guard.integer(count,1,65535)then return false end
        local kind=id//10000000
        local table_name=kind==1 and 'equip_base'or kind==5 and 'gem_info'or kind==7 and 'pet_equip_base'or 'common_item'
        if not cfg:get_config(table_name)[id]then return false end
        local log={reason='脚本发放',func_name='AddItemListToHuman',script_id=script.script_id,param=row.param}
        local sample=operator:gen_item(log,id,way,nil,row.param)
        if not sample then return false end
        local bound=row.is_bind~=nil and row.is_bind~=false and row.is_bind~=0
        sample:set_is_bind(bound)
        local maximum=sample:get_max_tile_count()
        if not guard.integer(maximum,1,250)then return false end
        local region=sample:get_place_bag()
        if count>(h:get_prop_bag_container():get_size()[region]or 0)*maximum then return false end
        local product={sample=sample,prepared={sample},maximum=maximum,count=count,kind=region,log=log,id=id}
        for n=2,math.ceil(count/maximum)do
            local item=operator:gen_item(log,id,way,nil,row.param)
            if not item then return false end
            item:set_is_bind(bound);product.prepared[n]=item
        end
        products[#products+1]=product
    end
    -- All service calls above can yield. Plan against the resulting current bag.
    local changes,bag=plan(h,products)
    if not changes then return false end
    batch.prepared={human=h,changes=changes,bag=bag,products=products,way=way}
    return true
end
function M.prepare(script,who,way)
    local ok,result=xpcall(prepare,debug.traceback,script,who,way)
    if not ok then skynet.error('[CYS reward] preparation failed',result)end
    if not ok or not result then batches.get(script).prepared=nil;return false end
    return true
end
function M.commit(script,who,way)
    local batch=batches.get(script)
    if #batch.items==0 then return false end
    if not batch.prepared and not M.prepare(script,who,way)then return false end
    local ready=batch.prepared
    if ready.human~=script.scene:get_obj_by_id(who)or ready.way~=(way or 0)then return false end
    for pos,c in pairs(ready.changes)do
        local old=ready.bag:get_item(pos)
        if old~=c.old or old and (old:is_lock()or not same(old:copy_raw_data(),c.before))then
            batch.prepared=nil;return false
        end
    end
    -- No calls which allocate GUIDs or consult lazy-loaded config below.
    batch.items={};batch.prepared=nil
    for pos,c in pairs(ready.changes)do c.item:set_lay_count(c.count);ready.bag:set_item(pos,c.item)end
    for pos,c in pairs(ready.changes)do
        local n=packets.GCNotifyEquip.new();n.bag_index,n.item=pos,c.item:copy_raw_data();script.scene:send2client(who,n)
        n=packets.GCItemInfo.new();n.bagIndex,n.item=pos,c.item:copy_raw_data();script.scene:send2client(who,n)
    end
    for _,p in ipairs(ready.products)do
        skynet.send('.logdb','lua','insert',{collection='create_item_to_bag_rec',doc={
            name=ready.human:get_name(),guid=ready.human:get_guid(),param=p.log,item_index=p.id,
            item_count=p.count,is_bind=p.sample:is_bind(),time=os.time()}})
    end
    return true
end
return M
