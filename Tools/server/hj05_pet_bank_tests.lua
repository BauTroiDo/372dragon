local root=assert(arg[1]);local stage=arg[2] or root
package.path=stage..'/GameServer/lualib/?.lua;'..root..'/GameServer/lualib/?.lua;'..package.path
package.loaded.skynet={getenv=function()end}
local packets={}
for _,name in ipairs({'GCPetBankAddPet','GCPetBankListUPData','GCDetailAttrib_Pet'})do
    packets[name]={new=function()return{kind=name,pet_list={},bos=function(s)return s.guid end}end}
end
package.loaded['game.packet']=packets
local M=require 'cys_pet_bank';local n=0
local function eq(a,b,why)n=n+1;assert(a==b,(why or '')..' '..tostring(a)..' ~= '..tostring(b))end
local function equal(a,b)return a and b and a.m_uHighSection==b.m_uHighSection and a.m_uLowSection==b.m_uLowSection end
local function container(size)
    local c={size=size,items={}}
    function c:get_size()return self.size end
    function c:get_item(i)return self.items[i]end
    function c:set_item(i,p)assert(i>=0 and i<self.size);self.items[i]=p end
    function c:get_empty_item_index()for i=0,self.size-1 do if not self.items[i]then return i end end;return -1 end
    function c:get_index_by_pet_guid(g)for i,p in pairs(self.items)do if equal(p.guid,g)then return i end end end
    return c
end
local function pet(id)
    local p={guid={m_uHighSection=200016,m_uLowSection=id},locked=false,exchange=false,
        aptitude={1234,2345,3456,4567,5678},lingxing=120,skills={101,202},gear={quals={1,2,3,4,5,255},life=200}}
    function p:get_guid()return self.guid end
    function p:is_lock()return self.locked end
    function p:is_in_exchange()return self.exchange end
    function p:calculate_pet_detail_attrib(msg)msg.guid=self.guid end
    return p
end
local bag,bank=container(3),container(10)
local scene={sent={}}
local npc={get_obj_id=function()return 5 end,get_world_pos=function()return{x=10,y=10}end}
local h={dead=false,pos={x=10,y=10},current={},soul={},tips=0}
function h:get_pet_bag_container()return bag end
function h:get_pet_bank_container()return bank end
function h:get_current_pet_guid()return self.current end
function h:get_current_soul_melting_pet_guid()return self.soul end
function h:get_world_pos()return self.pos end
function h:is_die()return self.dead end
function h:notify_tips()self.tips=self.tips+1 end
function h:send_pets_detail()end
function scene:get_obj_by_id(id)return id==1 and h or id==5 and npc or nil end
function scene:send2client(_,msg)self.sent[#self.sent+1]=msg end
local a,b=pet(11),pet(12);bag.items[0]=a;bank.items[7]=b
local function req(kind,p,q)return{type=kind,pet_guid_from=p and p.guid,pet_guid_to=q and q.guid or {m_uHighSection=0,m_uLowSection=0}}end
eq(M.handle(scene,1,req(1,a)),false,'unopened bank')
M.open(scene,h,5)
eq(M.handle(scene,1,req(3)),true);eq(scene.sent[#scene.sent].pet_list[8],b.guid,'sparse slot retained')
eq(scene.sent[#scene.sent].pet_list[1],nil,'no fake first slot')
local gear=a.gear
eq(M.handle(scene,1,req(1,a)),true);eq(bag.items[0],nil);eq(bank.items[0],a);eq(bank.items[0].gear,gear)
eq(M.handle(scene,1,req(1,a)),false,'duplicate deposit');eq(bank.items[0],a)
eq(M.handle(scene,1,req(0,a)),true);eq(bag.items[0],a);eq(bank.items[0],nil)
eq(M.handle(scene,1,req(0,a)),false,'duplicate withdrawal')
eq(M.handle(scene,1,req(2,a,b)),true);eq(bag.items[0],b);eq(bank.items[7],a);eq(a.gear,gear)
eq(a.aptitude[5],5678);eq(a.lingxing,120);eq(a.gear.life,200);eq(a.skills[2],202)
eq(M.handle(scene,1,req(2,a,b)),false,'duplicate swap')
for _,block in ipairs({'lock','exchange','active','soul','dead','leaving','far','scene'})do
    M.open(scene,h,5);b.locked=block=='lock';b.exchange=block=='exchange'
    h.current=block=='active' and b.guid or {};h.soul=block=='soul' and b.guid or {}
    h.dead=block=='dead';h._leaving=block=='leaving';h.pos={x=block=='far' and 20 or 10,y=10}
    if block=='scene'then h._cys_pet_bank.scene={}end
    eq(M.handle(scene,1,req(1,b)),false,block);eq(bag.items[0],b);eq(bank.items[7],a)
end
h.dead=false;h._leaving=false;h.pos={x=10,y=10};h.current={};h.soul={};b.locked=false;b.exchange=false;M.open(scene,h,5)
h._cys_pet_bank.expires=0
eq(M.handle(scene,1,req(3)),true,'nearby NPC bank has no remote timeout')
M.open(scene,h,-1);h.pos={x=100,y=100}
eq(M.handle(scene,1,req(3)),true,'remote bank does not require NPC distance')
h._cys_pet_bank.expires=0
eq(M.handle(scene,1,req(1,b)),false,'expired remote bank');eq(bag.items[0],b);eq(bank.items[7],a)
h.pos={x=10,y=10};M.open(scene,h,5)
local original_npc=npc;npc={get_obj_id=function()return 5 end,get_world_pos=function()return{x=10,y=10}end}
eq(M.handle(scene,1,req(1,b)),false,'replacement NPC cannot reuse session');eq(bag.items[0],b)
npc=original_npc;M.open(scene,h,5)
for i=0,9 do if not bank.items[i]then bank.items[i]=pet(100+i)end end
eq(M.handle(scene,1,req(1,b)),false,'full bank');eq(bag.items[0],b)
for i=1,2 do bag.items[i]=pet(200+i)end
eq(M.handle(scene,1,req(0,a)),false,'full bag');eq(bank.items[7],a)
eq(M.handle(scene,1,req(2,b,a)),true,'swap allowed when both containers full');eq(bag.items[0],a);eq(bank.items[7],b)
bank.items[0]=a
eq(M.handle(scene,1,req(2,a,b)),false,'duplicate GUID blocks entire swap');eq(bag.items[0],a);eq(bank.items[7],b)
for _,r in ipairs({{type=-1},{type=4},{type=1,pet_guid_from={}},{type=1,pet_guid_from={m_uHighSection=0,m_uLowSection=1}}})do eq(M.handle(scene,1,r),false,'malformed request')end
print('PASS pet bank '..n..' assertions: ownership/replay/slot-zero/sparse/full/swap/locked/active/session/metadata')
