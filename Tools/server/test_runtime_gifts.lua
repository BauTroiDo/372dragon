local root=assert(...)
local boxes={[38007057]={bind=1,items={{38007035,1},{38007036,1},{38007037,1},{38007038,1}}}}
local h,full,race,granted,consumed
local logic={}
function logic:create_multi_item_to_bag(log,human,id,count,bind,shop,quality,extra,commit)
 assert(id==38007035 and count==1 and bind==1)
 if full then return false end
 if race then race() end
 if not commit() then return false end
 granted=granted+count;return true
end
function logic:dec_item_lay_count(log,human,pos,count,id)
 assert(human.item.id==id and human.item.n>=count)
 human.item.n=human.item.n-count;consumed=consumed+count;return true
end
local modules={cys_gift_boxes_data=boxes,configenginer={getinstance=function()return{}end},human_item_logic=logic,cys_inventory_guard={},cys_mount_flight={active=function(x)return x.air end}}
local env=setmetatable({require=function(n)return assert(modules[n],n)end},{__index=_G})
local m=assert(loadfile(root..'/cys_gift_boxes.lua','t',env))()
local function item()
 return {id=38007057,n=2,get_index=function(s)return s.id end,get_lay_count=function(s)return s.n end,is_lock=function(s)return s.lock end,get_base_config=function()return{level=1}end}
end
local script={BeginUICommand=function()end,UICommand_AddInt=function()end,EndUICommand=function()end,DispatchUICommand=function(_,id,command)assert(command==99825604)end}
local function setup()
 full=false;race=nil;granted=0;consumed=0
 h={item=item(),level=15,get_level=function(s)return s.level end,get_obj_id=function()return 1 end,notify_tips=function()end}
 function h:get_prop_bag_container() return {get_item=function(_,pos)if pos==0 then return self.item end end} end
 assert(m.open(script,h,0))
end
setup();assert(m.claim(script,h,0,1,0,0,0,-1));assert(granted==1 and consumed==1 and h.item.n==1)
assert(not m.claim(script,h,0,1,0,0,0,-1));assert(granted==1 and consumed==1)
setup();full=true;assert(not m.claim(script,h,0,1,0,0,0,-1));assert(granted==0 and consumed==0 and h.item.n==2)
setup();race=function()h.item=item()end;assert(not m.claim(script,h,0,1,0,0,0,-1));assert(granted==0 and consumed==0)
setup();race=function()h.item.n=0 end;assert(not m.claim(script,h,0,1,0,0,0,-1));assert(granted==0 and consumed==0)
setup();assert(not m.claim(script,h,0,1,1,0,0,-1));assert(consumed==0)
setup();assert(not m.claim(script,h,1,1,0,0,0,-1));assert(consumed==0)
setup();assert(not m.claim(script,h,0,2,0,0,0,-1));assert(consumed==0)
setup();h.air=true;assert(not m.claim(script,h,0,1,0,0,0,-1));assert(consumed==0)
setup();h.level=0;assert(not m.claim(script,h,0,1,0,0,0,-1));assert(consumed==0)
setup();race=function()assert(not m.open(script,h,0));assert(not m.claim(script,h,0,1,0,0,0,-1))end
assert(m.claim(script,h,0,1,0,0,0,-1));assert(granted==1 and consumed==1)
print('PASS CY gift: exact reward/bind/count, replay, full bag, identity race, consumed race, forged flags, wrong slot, level, flight, reentrant request')
