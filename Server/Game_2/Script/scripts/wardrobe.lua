-- CYS wardrobe v1. Only Request is a gameplay entry point; no script_base
-- inheritance (CGExecuteScript may name any method of an allowed script).
local class = require 'class'
local packet = require 'game.packet'
local define = require 'define'
local skynet = require 'skynet'
local items = require 'item_operator':getinstance()
local catalog = require 'scripts.wardrobe_catalog'
local wardrobe = class('cys_wardrobe')
local byid = {}
for cat, rows in pairs(catalog) do
    byid[cat] = {}
    for _, row in ipairs(rows) do byid[cat][row.id] = row end
end
local fields = {[2]='faces',[3]='hairs',[4]='heads',[5]='headinfo',[6]='backinfo',[7]='weapon_visuals',[8]='poss',[9]='rides'}
local function integer(n, lo, hi)
    return type(n)=='number' and n==math.floor(n) and n>=lo and n<=hi
end
function wardrobe:set_scene(scene)
    if type(scene)=='table' and type(scene.get_obj_by_id)=='function' then self.scene=scene end
end
local function current(h, cat)
    if cat==1 then
        local x=h:get_equip_container():get_item(16); return x and x:get_index() or 0
    end
    local id=0
    if cat==2 then id=h:get_exterior_face_style_index()
    elseif cat==3 then id=h:get_exterior_hair_style_index()
    elseif cat==4 then id=h:get_exterior_portrait_index()
    elseif cat==5 then id=h:get_exterior_head_visual_id()
    elseif cat==6 then id=h:get_exterior_back_visual_id()
    elseif cat==7 then id=h:get_exterior_weapon_visual_id()
    elseif cat==8 then return h:get_exterior_pet_soul_id() or 0
    elseif cat==9 then return math.max(0,h:get_ride() or 0) end
    return id and id>10000 and id-10000 or 0
end
local function ownership(h, cat)
    local result={}
    if cat==1 then
        for _,id in ipairs(h.exterior.cys_fashions or {}) do result[id]=true end
        for _,container in ipairs({h:get_prop_bag_container(),h:get_fasion_bag_container()}) do
            for i=0,219 do
                local item=container:get_item(i)
                if item and byid[1][item:get_index()] then result[item:get_index()]=true end
            end
        end
        local worn=current(h,1); if worn>0 then result[worn]=true end
    else
        for _,entry in ipairs(h.exterior[fields[cat]] or {}) do
            local id=(cat==8 or cat==9) and entry.id or entry.id-10000
            if byid[cat][id] and (not entry.ntime or entry.ntime==-1 or entry.ntime>os.time())
                and (not entry.term or entry.term==-1 or entry.term>os.time()) then result[id]=true end
        end
    end
    return result
end
local function reply(scene,h,version,seq,op,cat,id,result)
    local own=ownership(h,cat); local ids={}
    for v in pairs(own) do ids[#ids+1]=v end
    table.sort(ids)
    local payload=table.concat(ids,',')
    if version==2 then
        local positions={}
        if cat==5 or cat==6 then
            for _,entry in ipairs(h.exterior[fields[cat]] or {}) do
                local id=entry.id-10000
                if own[id] then
                    positions[#positions+1]=id..':'..(entry.x | (entry.y<<8) | (entry.z<<16))
                end
            end
        end
        payload=payload..'|'..table.concat(positions,',')
    end
    -- One bounded ASCII string, parsed as integers by the client, never evaluated.
    assert(#payload<60000)
    local p=packet.GCUICommand.new()
    p.m_nUIIndex=990021
    p.m_Param.m_aIntValue={version,seq,op,cat,id,result,current(h,cat),#ids}
    p.m_Param.m_IntCount=8
    p.m_Param.m_StrCount=1
    p.m_Param.m_aStrOffset={#payload}
    p.m_Param.m_aStrValue=payload..'\0'
    scene:send2client(h,p)
end
local function acquire(h,cat,row,sex)
    if cat==1 then
        h.exterior.cys_fashions=h.exterior.cys_fashions or {}
        table.insert(h.exterior.cys_fashions,row.id)
    elseif cat==2 then h:unlock_exterior_face(row.native)
    elseif cat==3 then h:unlock_exterior_hair(row.native)
    elseif cat==4 then h:unlock_exterior_head(row.native)
    elseif cat==5 or cat==6 then
        local pos=row.pos[sex+1]
        local entry={id=row.native,x=pos[1],y=pos[2],z=pos[3],state=4,tip=0,ntime=-1}
        if cat==5 then h:set_exterior_head_id(entry) else h:set_exterior_back_id(entry) end
    elseif cat==7 then h:active_weapon_visual(row.native)
    elseif cat==9 then h:add_expiration_time(row.native,-1); h:send_exterior_info(1) end
end
local function wear_fashion(scene,h,row)
    if current(h,1)==row.id then return 0 end
    local depot=h:get_fasion_bag_container()
    local source,kind=-1,2
    for i=0,99 do local x=depot:get_item(i); if x and x:get_index()==row.id then source=i; break end end
    if source<0 then
        local bag=h:get_prop_bag_container()
        for i=0,99 do local x=bag:get_item(i); if x and x:get_index()==row.id then source=i; kind=0; break end end
    end
    local reserved=h:get_fashion_depot_index()
    local free=depot:get_empty_item_index_expect_index(reserved)
    if source<0 or kind==0 then
        if free==define.INVAILD_ID then return 5 end
        -- The worn dress must retain its reserved empty depot slot; never overwrite it.
        if reserved==define.INVAILD_ID and current(h,1)>0 then return 5 end
    end
    if source<0 then
        local item=items:gen_item({reason='cys_wardrobe'},row.id,0,0)
        if not item then return 6 end
        item:set_is_bind(true)
        depot:set_item(free,item)
        source=free
    end
    scene:char_use_equip(h:get_obj_id(),{equipPoint=16,bagIndex=source,type=kind})
    return current(h,1)==row.id and 0 or 6
end
local function apply(scene,h,cat,row,sex)
    if cat==1 then return wear_fashion(scene,h,row) end
    local native=row.native
    if cat==2 then h:set_exterior_face_style_index(native); h:set_face_style(row.visual[sex+1])
    elseif cat==3 then h:set_exterior_hair_style_index(native); h:set_hair_style(row.visual[sex+1])
    elseif cat==4 then h:set_exterior_portrait_index(native); h:set_portrait_id(row.visual[sex+1])
    elseif cat==5 or cat==6 then
        local entry=cat==5 and h:get_exterior_head_by_id(native) or h:get_exterior_back_by_id(native)
        local pos=entry and {entry.x,entry.y,entry.z} or row.pos[sex+1]
        local packed=pos[1] | (pos[2]<<8) | (pos[3]<<16)
        if cat==5 then h:set_exterior_head_visual_id(native,packed) else h:set_exterior_back_visual_id(native,packed) end
    elseif cat==7 then h:set_exterior_weapon_visual_id(native,0)
    elseif cat==9 then
        -- Selection is persistent. Mount/dismount remains the native skill 21
        -- path (CGCharAutoRide), including its cooldown and scene restrictions.
        scene:char_exterior_request(h:get_obj_id(),{type=7,list={{unknow_1=3,unknow_2=native}}})
        h:send_exterior_info(1)
        return current(h,cat)==row.id and 0 or 6
    end
    h:send_refresh_attrib()
    h:send_exterior_info(6)
    return current(h,cat)==row.id and 0 or 6
end
function wardrobe:Request(selfId,version,seq,op,cat,id,x,y,z)
    if not self.scene or (version~=1 and version~=2) or not integer(seq,1,2147483647)
        or not integer(op,0,version==2 and 4 or 2) or not integer(cat,1,9) or not integer(id,0,2147483647) then return end
    local h=self.scene:get_obj_by_id(selfId)
    if not h or not h.exterior then return end
    local function respond(result) reply(self.scene,h,version,seq,op,cat,id,result) end
    if cat==8 and op~=0 then respond(4); return end
    local now=skynet.now()
    if h._cysWardrobeAt and now-h._cysWardrobeAt<20 then respond(7); return end
    h._cysWardrobeAt=now
    if op==0 then respond(0); return end
    if op==4 then
        if cat~=1 and cat~=5 and cat~=6 and cat~=7 then respond(2);return end
        -- Compare the item the user saw with the current server item. A delayed
        -- click must not take off a different outfit that was just equipped.
        if current(h,cat)~=id then respond(11);return end
        if id==0 then respond(0);return end
        if cat==1 then
            self.scene:char_un_equip(selfId,{equipPoint=16})
            if current(h,cat)~=0 then respond(5);return end
        elseif cat==5 then h:set_exterior_head_visual_id(0,0)
        elseif cat==6 then h:set_exterior_back_visual_id(0,0)
        else h:set_exterior_weapon_visual_id(0,0) end
        h:send_refresh_attrib();h:send_exterior_info(6)
        respond(0);return
    end
    local row=byid[cat][id]; local sex=h:get_attrib('model')
    if not row or (sex~=0 and sex~=1) or not row.valid[sex+1] then respond(2); return end
    if version==2 and op==2 and cat==1 and x~=nil then
        if not integer(x,1,2147483647) or not row.dyes or not row.dyes[x] or not row.dyes[x][sex+1] then respond(2);return end
    end
    local own=ownership(h,cat)
    local result=0
    if op==1 then
        if own[id] then result=1 else acquire(h,cat,row,sex) end
    elseif not own[id] then result=3
    elseif op==3 and cat~=5 and cat~=6 then result=2
    else
        if version==2 and (op==2 or op==3) and (cat==5 or cat==6) then
            local values={x,y,z}
            for axis=1,3 do
                if not integer(values[axis],row.bounds[axis*2-1],row.bounds[axis*2]) then respond(10);return end
            end
            local saved
            if cat==5 then saved=h:set_exterior_head_pos(row.native,x,y,z)
            else saved=h:set_exterior_back_pos(row.native,x,y,z) end
            if not saved then respond(6);return end
        end
        if op==2 or current(h,cat)==id then result=apply(self.scene,h,cat,row,sex) end
        if result==0 and version==2 and op==2 and cat==1 and x~=nil then
            local item=h:get_equip_container():get_item(16)
            item:get_equip_data():set_visual(x)
            self.scene:broad_char_equioment(h,16)
        end
    end
    respond(result)
end
return wardrobe
