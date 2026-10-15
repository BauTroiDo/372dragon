-- The CY temporary-bag UI, backed by a separate persistent container.
-- A revision and source GUID bind every move to the snapshot the player saw.
local guard=require "cys_inventory_guard"
local operator=require "item_operator":getinstance()
local packets=require "game.packet"
local item_cls=require "item"
local M={UI=990025,SIZE=120,OFFSET=600}
local function emit(s,h,kind)
    s:BeginUICommand();s:UICommand_AddInt(kind);s:UICommand_AddInt(h.cys_tembank_revision)
    s:EndUICommand();s:DispatchUICommand(h:get_obj_id(),M.UI)
end
local function update(h,index,item)
    if item and index<200 then
        local n=packets.GCNotifyEquip.new();n.bag_index=index;n.item=item:copy_raw_data()
        h:get_scene():send2client(h,n)
    end
    local p=packets.GCItemInfo.new();p.bagIndex=index
    p.item=(item or item_cls.new()):copy_raw_data()
    if not item then p.unknow_1=1 end
    h:get_scene():send2client(h,p)
end
function M.snapshot(s,h)
    emit(s,h,0)
    for i=0,M.SIZE-1 do
        local item=h.cys_tembank:get_item(i)
        if item then update(h,M.OFFSET+i,item) end
    end
    emit(s,h,1)
end
local function ready(h,revision)
    return h.cys_tembank and not h:is_die() and not h._leaving
        and guard.integer(revision,1,2147483646) and revision==h.cys_tembank_revision
end
local function advance(h) h.cys_tembank_revision=h.cys_tembank_revision%2147483646+1 end
local function same(item,world,server,series)
    local g=item and item:get_guid()
    return g and g.world==world and g.server==server and (g.series&0xffffffff)==(series&0xffffffff)
end
function M.move(s,h,dir,index,revision,world,server,series)
    if not ready(h,revision) or not guard.integer(dir,0,1)
        or not guard.integer(world,0,255) or not guard.integer(server,0,255)
        or not guard.integer(series,-2147483648,2147483647) then return M.snapshot(s,h) end
    local bag=h:get_prop_bag_container()
    local from=dir==0 and bag or h.cys_tembank
    local to=dir==0 and h.cys_tembank or bag
    if not guard.integer(index,0,dir==0 and 199 or M.SIZE-1) then return M.snapshot(s,h) end
    local item=from:get_item(index)
    if not same(item,world,server,series) or item:is_lock() or item:is_empty() then return M.snapshot(s,h) end
    -- Use the existing guarded operator: complete-stack merge or an empty slot;
    -- it preserves binding, expiry, sockets, enhancement and the unique GUID.
    local dest=operator:move_item(from,index,to,-1)
    if dest and dest>=0 then
        advance(h)
        update(h,dir==0 and index or dest,bag:get_item(dir==0 and index or dest))
    else s:notify_tips(h:get_obj_id(),"Túi đích đã đầy; vật phẩm vẫn ở nguyên vị trí.") end
    M.snapshot(s,h)
end
function M.take_all(s,h,revision)
    if not ready(h,revision) then return M.snapshot(s,h) end
    local bag=h:get_prop_bag_container();local moved=0
    for i=0,M.SIZE-1 do
        local item=h.cys_tembank:get_item(i)
        if item and not item:is_lock() then
            local dest=operator:move_item(h.cys_tembank,i,bag,-1)
            if dest and dest>=0 then moved=moved+1;update(h,dest,bag:get_item(dest)) end
        end
    end
    if moved>0 then advance(h) end
    M.snapshot(s,h)
end
function M.sort(s,h,revision)
    if not ready(h,revision) then return M.snapshot(s,h) end
    local rows={}
    for i=0,M.SIZE-1 do
        local item=h.cys_tembank:get_item(i)
        if item then
            if item:is_lock() then return M.snapshot(s,h) end
            rows[#rows+1]={item=item,pos=i}
        end
    end
    table.sort(rows,function(a,b)if a.item:get_index()~=b.item:get_index() then return a.item:get_index()<b.item:get_index() end;return a.pos<b.pos end)
    for i=0,M.SIZE-1 do h.cys_tembank:erase_item(i) end
    for i,row in ipairs(rows) do h.cys_tembank:set_item(i-1,row.item) end
    advance(h);M.snapshot(s,h)
end
return M
