-- Native pet bank containers and protocol. Never clone or regenerate a pet.
local packets=require 'game.packet'
local guard=require 'cys_inventory_guard'
local M={}
local function guid_ok(g)
    return type(g)=='table' and guard.integer(g.m_uHighSection,1,4294967295)
        and guard.integer(g.m_uLowSection,1,4294967295)
end
local function same(a,b)return a and b and a.m_uHighSection==b.m_uHighSection and a.m_uLowSection==b.m_uLowSection end
function M.open(scene,h,npcid)
    h._cys_pet_bank={scene=scene,npc=npcid>=0 and scene:get_obj_by_id(npcid) or nil,
        remote=npcid<0,expires=os.time()+300}
end
local function allowed(scene,h)
    local s=h._cys_pet_bank
    if not s or s.scene~=scene or h:is_die() or h._leaving then return false end
    -- CY PetBankMain starts the five-minute timer only for the remote bank.
    -- A nearby NPC session stays usable while that same NPC still exists.
    if s.remote then return s.expires>=os.time() end
    local npc=s.npc
    if not npc or scene:get_obj_by_id(npc:get_obj_id())~=npc then return false end
    local a,b=h:get_world_pos(),npc:get_world_pos()
    return a and b and (a.x-b.x)^2+(a.y-b.y)^2<=9
end
local function movable(h,p)
    if not p or p:is_lock() or p:is_in_exchange() then return false end
    local g=p:get_guid()
    return not same(g,h:get_current_pet_guid()) and not same(g,h:get_current_soul_melting_pet_guid())
end
function M.snapshot(scene,h)
    local bank=h:get_pet_bank_container();local msg=packets.GCPetBankListUPData.new()
    for i=0,math.min(10,bank:get_size())-1 do
        local pet=bank:get_item(i)
        if pet then
            local row=packets.GCDetailAttrib_Pet.new();pet:calculate_pet_detail_attrib(row);row.unknow_6=0
            msg.pet_list[i+1]=row:bos() -- preserve sparse slot identity
        end
    end
    scene:send2client(h,msg)
end
function M.handle(scene,who,r)
    local h=scene:get_obj_by_id(who)
    if not h or not guard.integer(r.type,0,3) or not allowed(scene,h) then return false end
    local bag,bank=h:get_pet_bag_container(),h:get_pet_bank_container()
    if r.type==3 then M.snapshot(scene,h);return true end
    local function fail(text)h:notify_tips(text);M.snapshot(scene,h);return false end
    if not guid_ok(r.pet_guid_from) or (r.type==2 and not guid_ok(r.pet_guid_to)) then return fail('Trân thú không hợp lệ.') end
    local source,dest=r.type==0 and bank or bag,r.type==0 and bag or bank
    local from=source:get_index_by_pet_guid(r.pet_guid_from)
    local to=r.type==2 and dest:get_index_by_pet_guid(r.pet_guid_to) or dest:get_empty_item_index()
    if not guard.accepts(source,from) or not guard.accepts(dest,to) then return fail('Trân thú đã chuyển chỗ hoặc kho đã đầy.') end
    local p,q=source:get_item(from),dest:get_item(to)
    if not movable(h,p) or (r.type==2 and not movable(h,q)) or (r.type~=2 and q) then
        return fail('Thu hồi, tách dung hồn và mở khóa trân thú trước khi chuyển kho.')
    end
    if dest:get_index_by_pet_guid(r.pet_guid_from)~=nil or (q and source:get_index_by_pet_guid(r.pet_guid_to)~=nil) then
        return fail('Dữ liệu trân thú trùng định danh; thao tác đã bị chặn.')
    end
    -- Every check above is local. These two setters do not yield; observers can
    -- only see the complete exchange. Same objects preserve gear, skills and aptitude.
    source:set_item(from,q);dest:set_item(to,p)
    local ack=packets.GCPetBankAddPet.new();ack.type=r.type
    ack.pet_guid_from=r.pet_guid_from;ack.pet_guid_to=r.pet_guid_to
    scene:send2client(h,ack);h:send_pets_detail(h);M.snapshot(scene,h)
    return true
end
return M
