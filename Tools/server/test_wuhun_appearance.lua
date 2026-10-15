package.path='/mnt/c/TLBB/085/CY-Source/Tools/server/?.lua;'..package.path
local M=require 'cys_wuhun_appearance'
local n=0
local function eq(a,b)assert(a==b,tostring(a)..' ~= '..tostring(b));n=n+1 end
eq(M.visual(10156001,1,1,0,0,0,{}),699)
eq(M.visual(10156002,1,1,0,0,0,{}),704)
eq(M.visual(10156001,5,1,0,0,0,{}),703)
eq(M.visual(10156004,7,1,0,0,0,{}),705)
eq(M.visual(nil,1,1,0,0,0,{}),0)
eq(M.visual(10156001,1,0,0,1,0,{['1']={level=1}}),0)
eq(M.visual(10156001,1,1,0,7,0,{}),699)
eq(M.visual(10156001,1,1,0,1,0,{}),699)
local expected={{744,762},{741,759},{732,750},{735,753},{738,756},{729,747}}
for id=1,6 do
 for side=0,1 do
  for tier,level in ipairs({1,5,8}) do
   local u={[tostring(id)]={level=level}}
   local q,k=side==0 and id or 0,side==1 and id or 0
   eq(M.visual(10156001,1,1,side,q,k,u),expected[id][side+1]+tier-1)
   eq(M.visual(10156001,1,1,1-side,q,k,u),expected[id][side+1]+tier-1)
  end
 end
end
local mutated=0;local ack=0
local h={get_attrib=function(_,k)return k=='level' and 100 or 0 end,get_obj_id=function()return 1 end,
 get_equip_container=function()return{get_item=function()return{}end}end,get_wuhun_wg=function()return{['1']={level=1}}end,
 set_huanhun_qk=function()mutated=mutated+1 end,item_flush=function()end,send_refresh_attrib=function()end,send_wuhun_wg=function()end}
local s={notify_tips=function()end,BeginUICommand=function()end,UICommand_AddInt=function()end,EndUICommand=function()end,DispatchUICommand=function()ack=ack+1 end}
for _,side in ipairs({-1,2,0.5})do M.slot(s,h,side,1)end
for _,id in ipairs({-1,7,1.5,999999})do M.slot(s,h,0,id)end
M.slot(s,h,0,2);eq(mutated,0)
M.slot(s,h,0,1);eq(mutated,1);M.slot(s,h,0,0);eq(mutated,2)
print('PASS '..n..' soul visual/slot assertions')
