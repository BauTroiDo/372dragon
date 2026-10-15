local root='/home/ubuntu/cys-test-20260913'
local plan=assert(arg[1],'Pass staged GameServer directory ending in /')
package.path=plan..'lualib/?.lua;'..plan..'services/?.lua;'..root..'/GameServer/lualib/?.lua;'..root..'/GameServer/services/?.lua;'..package.path
local time,queue=1000,{}
package.loaded.skynet={now=function()return time end,timeout=function(n,f)queue[#queue+1]={time+n,f}end,logi=function()end}
local function advance(n)
 local endtime=time+n
 while true do local at,index=endtime+1
  for i,v in ipairs(queue)do if v[1]<at then at,index=v[1],i end end
  if not index then break end
  time=at;local row=table.remove(queue,index);row[2]()
 end;time=endtime
end
local io=require 'iostream';local packets={}
require('game.packet_domains.core').bind(packets,io.bistream,io.bostream,{},{})
require('game.packet_domains.cys_mount_flight').bind(packets,io.bistream,io.bostream)
package.loaded['game.packet']=packets
package.loaded['cys_flight_nav']={for_scene=function(scene)if scene.missing_nav then return nil end;return {walkable=function()return not scene.blocked end}end}
local M=require 'cys_mount_flight';local D=require 'cys_mount_flight_data';local count=0
local function check(msg,ok)assert(ok,msg);count=count+1;print('PASS '..msg)end
local p=packets.CGFlyOperation.new();p.object=0x12345678;p.operation=1
check('native2242 exactly five little-endian bytes',p:bos()==string.char(0x78,0x56,0x34,0x12,1))
local q=packets.CGFlyOperation.new();q:bis(p:bos());check('native decoder roundtrip',q.object==p.object and q.operation==1)
check('truncated native packet rejected',not pcall(q.bis,q,'1234'))
check('extra native bytes rejected',not pcall(q.bis,q,'123456'))
local h={mount=94,pos={x=77,y=89},alive=true};local sent={};local scene={id=12,blocked=false}
function scene:get_id()return self.id end;function scene:get_obj_by_id(id)return id==5 and h or nil end
function scene:get_map()return {findpath=function()return self.blocked and {} or {{x=77,y=89}}end}end
function scene:send2client(to,p)sent[#sent+1]={to=to,packet=p};p:bos()end
function scene:broadcast(who,p,selfsend)assert(who==h and selfsend);self:send2client('all',p)end
function h:get_obj_id()return 5 end;function h:get_obj_type()return 'human'end;function h:get_ride_model()return self.mount end
function h:is_alive()return self.alive end;function h:is_limit_move()return self.limited end;function h:get_team_follow_flag()return self.follow end
function h:get_stall_box()return {get_stall_is_open=function()return self.stall end}end;function h:get_action_time()return self.action or 0 end
function h:get_world_pos()return self.pos end;function h:get_ai()return {stop=function()self.stops=(self.stops or 0)+1 end}end
function h:do_stop()end
local function req(op,id)return M.request(scene,5,{object=id or 5,operation=op})end
check('canonical mount94 capable and ground21 incapable',D.mounts[94] and not D.mounts[21])
check('spoofed actor denied',not req(0,6) and not M.active(h))
check('unknown operation denied',not req(255) and not M.active(h))
check('native op2 cannot take off',req(2) and not M.active(h))
h.mount=21;check('ground mount refused',not req(0));h.mount=94
scene.id=999999;check('unsupported scene refused',not req(0));scene.id=12
scene.missing_nav=true;check('missing landing mesh prevents takeoff',not req(0));scene.missing_nav=false
for _,key in ipairs({'limited','follow','stall'})do h[key]=true;check(key..' gate enforced',not req(0));h[key]=false end
h.alive=false;check('dead gate enforced',not req(0));h.alive=true
h.action=100;check('unfinished action gate',not req(0));h.action=0
check('takeoff accepted and locks movement',req(0) and M.changing(h) and h.stops==1)
local n=#sent;check('spam cannot queue another takeoff',not req(0) and #sent==n)
advance(100);M.sync(scene,h,19);local snap=sent[#sent].packet
check('new observer gets remaining transition duration',snap.m_Param.m_aIntValue[4]==1000 and snap.m_Param.m_IntCount==4)
advance(100);check('server completes airborne state',h._cys_mount_flight.state==1 and not M.changing(h))
check('all viewers receive final state',sent[#sent].to=='all' and sent[#sent].packet.m_Param.m_aIntValue[2]==1)
check('normal skill cannot target airborne human',not M.skill_allowed({},h,1))
check('Lac Ma Tien37 exception preserved',M.skill_allowed({},h,37))
check('airborne human cannot attack',not M.skill_allowed(h,{},37))
scene.blocked=true;check('blocked landing refused without changing state',not req(1) and h._cys_mount_flight.state==1);scene.blocked=false
check('landing accepted',req(1) and h._cys_mount_flight.state==3)
advance(200);check('landing fully unlocks',not M.active(h) and h._cys_mount_flight.state==0)
check('second takeoff',req(0));h.mount=21;advance(20);check('mount removal resets transient flight',not M.active(h));h.mount=94
check('third takeoff',req(0));h.alive=false;advance(20);check('death clears flight state',not M.active(h));h.alive=true
check('fourth takeoff',req(0));M.reset(h);advance(500);check('obsolete timer cannot resurrect reset flight',not M.active(h))
check('NaN and infinity movement refused',not M.bounds(scene,{x=0/0,y=1}) and not M.bounds(scene,{x=math.huge,y=1}))
check('map edges bounded',not M.bounds(scene,{x=144,y=0}) and not M.bounds(scene,{x=-1,y=5}))
print('RESULT '..count..' checks passed')
