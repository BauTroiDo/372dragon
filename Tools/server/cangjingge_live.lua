-- Bounded private-server exercise through existing scene RPCs. No code injection.
local skynet=require 'skynet'
local step='identity';local notes={}
local ok=xpcall(function()
 assert(skynet.call('.cluster_agent','lua','get_processid')==2)
 local notices=skynet.call('.CfgDB','lua','get_activity_notice')
 local activity=assert(notices[228]);assert(activity.scriptid==402110)
 for _,id in ipairs({18,24,30})do
  local scene='.SCENE_'..id;step='entry-'..id
  assert(skynet.call(scene,'lua','get_id')==id)
  assert(skynet.call(scene,'lua','get_human_count')==0)
  local before=skynet.call(scene,'lua','get_monster_count')
  skynet.call(scene,'lua','activity_open',activity)
  local once=skynet.call(scene,'lua','get_monster_count');assert(once==before+18)
  skynet.call(scene,'lua','activity_open',activity)
  local twice=skynet.call(scene,'lua','get_monster_count');assert(twice==once)
  notes[#notes+1]=string.format('scene%d=%d,%d,%d',id,before,once,twice)
 end
 step='render-samples'
 for i,race in ipairs({113574,113583,113592})do
  local id=skynet.call('.SCENE_18','lua','create_temp_monster',race,261+i*2,260,3,-1,-1)
  assert(id and id>0);notes[#notes+1]=string.format('race%d=%d',race,id)
 end
 step='complete'
end,function()return false end)
local result='CYS-CJG '..(ok and ('PASS '..table.concat(notes,';')) or ('FAIL '..step))
-- This console's run command lacks table.tostr. Restore it immediately after
-- its one formatting call, after all yielding RPCs have completed.
local previous=table.tostr
table.tostr=function()table.tostr=previous;return result end
return result
