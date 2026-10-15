-- CY 3.71 mount flight. CGFlyOperation2242 = u32 actor + u8 operation.
-- Native evidence: 140613380 checks CharMount[19] and uses op0 takeoff/op1 land.
-- The private 085-derived server lacks CY's extended flight attributes: publish
-- explicit states through its existing GCUICommand codec (990030), including AOI sync.
local clock=require 'skynet'
local packet=require 'game.packet'
local data=require 'cys_mount_flight_data'
local nav=require 'cys_flight_nav'
local M={UI=990030,DURATION=200}
local function info(h) return h and h._cys_mount_flight end
function M.active(h) local s=info(h);return s and s.state~=0 or false end
function M.changing(h) local s=info(h);return s and s.state>=2 or false end
function M.sync(scene,h,to,text)
 local s=info(h);local state=s and s.state or 0
 local p=packet.GCUICommand.new();p.m_nUIIndex=M.UI
 local ms=s and state>=2 and math.max(0,(s.deadline-clock.now())*10) or 0
 p.m_Param.m_aIntValue={h:get_obj_id(),state,h:get_ride_model() or -1,ms}
 p.m_Param.m_IntCount=4;p.m_Param.m_aStrValue=text or ''
 p.m_Param.m_StrCount=text and 1 or 0;p.m_Param.m_aStrOffset={#p.m_Param.m_aStrValue}
 if to then scene:send2client(to,p) else scene:broadcast(h,p,true) end
end
function M.reset(h)
 h._cys_mount_flight=nil
end
function M.refuse(scene,h,text)
 M.sync(scene,h,h:get_obj_id(),text);return false
end
function M.bounds(scene,pos)
 local s=data.scenes[scene:get_id()]
 return s and pos and type(pos.x)=='number' and type(pos.y)=='number' and pos.x==pos.x and pos.y==pos.y and pos.x>=0 and pos.y>=0 and pos.x<s[1] and pos.y<s[2]
end
function M.landing(scene,pos)
 if not M.bounds(scene,pos) then return false end
 if scene.blockmap and scene.blockmap:is_blocked(pos.x,pos.y) then return false end
 local mesh=nav.for_scene(scene)
 return mesh and mesh:walkable(pos.x,pos.y) or false
end
local function watch(scene,h,s)
 clock.timeout(20,function()
  if h._cys_mount_flight~=s or scene:get_obj_by_id(h:get_obj_id())~=h then return end
  if not h:is_alive() or h:get_ride_model()~=s.mount or not data.scenes[scene:get_id()] then
   M.reset(h);M.sync(scene,h);return
  end
  if s.state>=2 and clock.now()>=s.deadline then
   s.state=s.state==2 and 1 or 0
   M.sync(scene,h,nil,s.state==1 and 'Đã cất cánh. Ctrl + chuột trái để hạ cánh.' or 'Đã hạ cánh. Ctrl + chuột trái để bay lên cao.')
  end
  if s.state~=0 then watch(scene,h,s) end
 end)
end
function M.request(scene,id,req)
 local h=scene:get_obj_by_id(id)
 if not h or h:get_obj_type()~='human' or req.object~=id then return false end
 local op=req.operation
 if op~=0 and op~=1 and op~=2 then return M.refuse(scene,h,'Lệnh bay không hợp lệ.') end
 -- Native op2 acknowledges grounded-state application; it never authorizes takeoff.
 if op==2 then return true end
 local s=info(h);local state=s and s.state or 0
 if (s and clock.now()<s.deadline) or state>=2 then return false end
 if op==0 and state~=0 or op==1 and state~=1 then return false end
 if not data.mounts[h:get_ride_model()] then return M.refuse(scene,h,'Thú cưỡi này không hỗ trợ bay lên cao.') end
 if not h:is_alive() or h:is_limit_move() or h:get_team_follow_flag() or h:get_stall_box():get_stall_is_open() then
  return M.refuse(scene,h,'Không thể bay trong trạng thái hiện tại.')
 end
 if h:get_action_time()>0 then return M.refuse(scene,h,'Hãy đợi động tác hiện tại kết thúc.') end
 local pos=h:get_world_pos()
 if not M.bounds(scene,pos) or not nav.for_scene(scene) then return M.refuse(scene,h,'Bản đồ này không hỗ trợ thú cưỡi bay cao.') end
 if op==1 and not M.landing(scene,pos) then return M.refuse(scene,h,'Hãy bay tới vị trí có thể đứng trên mặt đất để hạ cánh.') end
 h:get_ai():stop();h:do_stop()
 s={state=op==0 and 2 or 3,mount=h:get_ride_model(),deadline=clock.now()+M.DURATION}
 h._cys_mount_flight=s
 M.sync(scene,h);watch(scene,h,s)
 clock.logi('[CYS_MOUNT_FLIGHT] actor=',id,' mount=',s.mount,' op=',op,' scene=',scene:get_id())
 return true
end
function M.skill_allowed(actor,target,skill)
 if M.active(actor) then return false end
 if not M.active(target) then return true end
 return data.knockoff[skill] or false
end
return M
