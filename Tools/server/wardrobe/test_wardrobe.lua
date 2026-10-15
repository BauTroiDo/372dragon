-- Contract tests: exercise the real handler with bounded in-memory native APIs.
local catalogPath,handlerPath=arg[1],arg[2]
local time=1000
package.preload['class']=function() return function() local c={};c.__index=c;c.new=function()return setmetatable({},c)end;return c end end
package.preload['game.packet']=function()return {GCUICommand={new=function()return {m_Param={}}end}}end
package.preload['define']=function()return {INVAILD_ID=-1}end
package.preload['skynet']=function()return {now=function()return time end}end
local function item(id)
 local data={set_visual=function(self,v)self.visual=v end,get_visual=function(self)return self.visual or 0 end}
 return {get_index=function()return id end,set_is_bind=function()end,get_equip_data=function()return data end}
end
local operator={gen_item=function(_,_,id)return item(id)end}
package.preload['item_operator']=function()return {getinstance=function()return operator end}end
package.preload['scripts.wardrobe_catalog']=function()return dofile(catalogPath)end
local class=dofile(handlerPath)
local function container(n)
 local c={slots={}}
 function c:get_item(i)return self.slots[i]end
 function c:set_item(i,it)assert(not self.slots[i]);self.slots[i]=it end
 function c:get_empty_item_index_expect_index(reserved)for i=0,n-1 do if i~=reserved and not self.slots[i]then return i end end;return -1 end
 return c
end
local h={exterior={faces={},hairs={},heads={},headinfo={},backinfo={},weapon_visuals={},poss={},rides={}},cur={},bag=container(20),depot=container(100),equip=container(20)}
function h:get_obj_id()return 77 end
function h:get_attrib()return 1 end
function h:get_prop_bag_container()return self.bag end
function h:get_fasion_bag_container()return self.depot end
function h:get_equip_container()return self.equip end
function h:get_fashion_depot_index()return self.reserved or -1 end
function h:send_refresh_attrib()end
function h:send_exterior_info()end
function h:set_face_style(v)self.face=v end
function h:set_hair_style(v)self.hair=v end
function h:set_portrait_id(v)self.portrait=v end
local suffix={[2]='face_style_index',[3]='hair_style_index',[4]='portrait_index',[5]='head_visual_id',[6]='back_visual_id',[7]='weapon_visual_id',[8]='pet_soul_id'}
for cat,s in pairs(suffix)do h['get_exterior_'..s]=function(self)return self.cur[cat]or 0 end;h['set_exterior_'..s]=function(self,v)self.cur[cat]=v end end
function h:unlock_exterior_face(id)table.insert(self.exterior.faces,{id=id,term=-1})end
function h:unlock_exterior_hair(id)table.insert(self.exterior.hairs,{id=id,term=-1})end
function h:unlock_exterior_head(id)table.insert(self.exterior.heads,{id=id,term=-1})end
function h:set_exterior_head_id(v)table.insert(self.exterior.headinfo,v)end
function h:set_exterior_back_id(v)table.insert(self.exterior.backinfo,v)end
for cat,key in pairs({[5]='head',[6]='back'}) do
 h['get_exterior_'..key..'_by_id']=function(self,id)for _,e in ipairs(self.exterior[key..'info'])do if e.id==id then return e end end end
 h['set_exterior_'..key..'_pos']=function(self,id,x,y,z)local e=self['get_exterior_'..key..'_by_id'](self,id);if not e then return false end;e.x=x;e.y=y;e.z=z;return true end
end
function h:active_weapon_visual(id)table.insert(self.exterior.weapon_visuals,{id=id,term=-1,level=0})end
function h:get_ride()return self.ride or -1 end
function h:add_expiration_time(id,term)
 assert(term==-1)
 for _,r in ipairs(self.exterior.rides)do if r.id==id then r.term=-1;r.terminable=0;return end end
 table.insert(self.exterior.rides,{id=id,term=-1,terminable=0})
end
local scene={reply=nil}
function scene:char_exterior_request(who,request)
 assert(who==77 and request.type==7 and request.list[1].unknow_1==3)
 h.ride=request.list[1].unknow_2;self.nativeRideSelections=(self.nativeRideSelections or 0)+1
end
function scene:get_obj_by_id(id)if id==77 then return h end end
function scene:send2client(_,p)self.reply=p end
function scene:char_use_equip(_,use)
 local it=h.depot.slots[use.bagIndex];assert(it)
 h.depot.slots[use.bagIndex]=nil
 if h.equip.slots[16] then h.depot.slots[h.reserved]=h.equip.slots[16]end
 h.equip.slots[16]=it;h.reserved=use.bagIndex
end
local w=class.new();w:set_scene(scene);local seq=0;local checks=0
local function request(op,cat,id,result)
 time=time+30;seq=seq+1;scene.reply=nil;w:Request(77,1,seq,op,cat,id)
 assert(scene.reply,'missing response');local r=scene.reply.m_Param.m_aIntValue
 assert(r[6]==result,table.concat(r,','));checks=checks+1;return r
end
for cat=1,7 do
 local id=cat==1 and 10124000 or 1
 request(2,cat,id,3)
 local first=request(1,cat,id,0);assert(first[8]==1)
 local twice=request(1,cat,id,1);assert(twice[8]==1)
 assert(request(2,cat,id,0)[7]==id)
 request(1,cat,2147483647,2)
end
request(1,8,1,4);request(2,8,1,4);assert(#h.exterior.poss==0)
for i=0,99 do h.depot.slots[i]=item(999)end
request(1,1,10124003,0);request(2,1,10124003,5);assert(h.equip.slots[16]:get_index()==10124000)
scene.reply=nil;w:Request(77,99,999,1,1,10124004);assert(scene.reply==nil)
scene.reply=nil;w:Request(77,1,999,1,10,1);assert(scene.reply==nil)
request(2,9,2,3);request(1,9,2,0);request(1,9,2,1)
assert(#h.exterior.rides==1 and h.exterior.rides[1].term==-1)
assert(request(2,9,2,0)[7]==2 and scene.nativeRideSelections==1)
request(1,9,2147483647,2)
h.exterior.rides[1].term=os.time()-1;h.exterior.rides[1].terminable=1
assert(request(0,9,0,0)[8]==0)
request(2,9,2,3);request(1,9,2,0)
assert(#h.exterior.rides==1 and h.exterior.rides[1].term==-1)
-- Deserialize-style new handler instance reads the same persisted exterior data.
w=class.new();w:set_scene(scene)
for cat=1,7 do local r=request(0,cat,0,0);assert(r[8]>=1)end
local ride=request(0,9,0,0);assert(ride[7]==2 and ride[8]==1)
print('wardrobe server contract PASS '..checks..' replies: whitelist, duplicate, eight acquirable types, native ride selection, expiration, full depot, event-only, reload')
local function v2(op,cat,id,result,x,y,z)
 time=time+30;seq=seq+1;scene.reply=nil;w:Request(77,2,seq,op,cat,id,x,y,z)
 assert(scene.reply,'missing v2 response');assert(scene.reply.m_Param.m_aIntValue[1]==2)
 assert(scene.reply.m_Param.m_aIntValue[6]==result,table.concat(scene.reply.m_Param.m_aIntValue,','))
 checks=checks+1;return scene.reply.m_Param.m_aStrValue
end
for _,cat in ipairs({5,6})do
 local key=cat==5 and 'head' or 'back'
 v2(3,cat,2,3,129,130,131) -- unowned
 v2(3,cat,1,10,-1,130,131);v2(3,cat,1,10,256,130,131)
 v2(3,cat,1,10,128,0/0,131);v2(3,cat,1,10,128,130.5,131)
 v2(3,cat,1,10,128,nil,131)
 assert(h['get_exterior_'..key..'_by_id'](h,10001).x==128)
 local payload=v2(3,cat,1,0,129,130,131)
 assert(payload:find('1:8618625',1,true))
 assert(h['get_exterior_'..key..'_by_id'](h,10001).z==131)
 request(2,cat,1,0) -- old client wear must retain the saved position
 assert(h['get_exterior_'..key..'_by_id'](h,10001).z==131)
 w=class.new();w:set_scene(scene)
 assert(v2(0,cat,0,0):find('1:8618625',1,true))
end
v2(3,8,1,4,128,128,128);v2(3,7,1,2,128,128,128)
print('wardrobe position contract PASS '..checks..' replies: bounds, integers, ownership, persistence, v1 compatibility')
function scene:broad_char_equioment(who,point)assert(who==h and point==16);self.dyeBroadcast=(self.dyeBroadcast or 0)+1 end
h.depot.slots={};h.reserved=0
request(1,1,10124067,0)
v2(2,1,10124067,2,999999) -- not a dye of this family
v2(2,1,10124067,2,63.5)
v2(2,1,10124067,2,0/0)
v2(2,1,10124067,0,63) -- colour with no independent shop item
assert(h.equip.slots[16]:get_equip_data():get_visual()==63 and scene.dyeBroadcast==1)
w=class.new();w:set_scene(scene)
assert(h.equip.slots[16]:get_equip_data():get_visual()==63)
v2(2,1,10124067,0,33) -- restore base while already wearing the item
assert(h.equip.slots[16]:get_equip_data():get_visual()==33 and scene.dyeBroadcast==2)
time=time+30;seq=seq+1;scene.reply=nil;w:Request(77,1,seq,2,1,10124067,999999)
assert(scene.reply.m_Param.m_aIntValue[6]==0)
assert(h.equip.slots[16]:get_equip_data():get_visual()==33 and scene.dyeBroadcast==2)
checks=checks+1 -- v1 extra parameters cannot bypass the v2 dye whitelist
v2(2,8,2,4,3);assert(#h.exterior.poss==0)
print('wardrobe dye contract PASS '..checks..' replies: family whitelist, fractions, NaN, native dye storage/broadcast, reset, event-only soul')

function scene:char_un_equip(who,request)
 assert(who==77 and request.equipPoint==16)
 local dest=h.reserved
 if not dest or dest<0 or h.depot.slots[dest] then dest=h.depot:get_empty_item_index_expect_index(-1) end
 if dest<0 then return end
 h.depot.slots[dest]=h.equip.slots[16];h.equip.slots[16]=nil;h.reserved=-1
end
for _,cat in ipairs({5,6,7})do
 local own=request(0,cat,0,0)[8]
 v2(4,cat,99999,11);assert(h.cur[cat]==10001)
 v2(4,cat,1,0);assert(h.cur[cat]==0)
 assert(request(0,cat,0,0)[8]==own) -- no ownership is deleted
 v2(4,cat,1,11);v2(4,cat,0,0)
 request(2,cat,1,0)
end
v2(4,8,1,4);v2(4,2,1,2);v2(4,9,2,2)
local worn=h.equip.slots[16];local reserved=h.reserved
for i=0,99 do h.depot.slots[i]=item(999)end
v2(4,1,10124067,5);assert(h.equip.slots[16]==worn)
h.depot.slots[reserved]=nil
v2(4,1,10124067,0);assert(not h.equip.slots[16] and h.depot.slots[reserved]==worn)
assert(request(0,1,0,0)[8]>=1)
v2(4,1,10124067,11)
scene.reply=nil;time=time+30;w:Request(77,1,seq+1,4,1,0);assert(scene.reply==nil)
print('wardrobe remove contract PASS '..checks..' replies: stale selection, preserved ownership, full depot, native inventory move, restricted categories, v1 isolation')
