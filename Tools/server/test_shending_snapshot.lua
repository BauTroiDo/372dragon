package.path='/mnt/c/TLBB/085/CY-Source/Tools/server/?.lua;'..package.path
package.loaded.cys_inventory_guard={}
package.loaded.human_item_logic={}
local sent
package.loaded['game.packet']={GCUICommand={new=function()return {m_Param={}}end}}
local m=require 'cys_shending'
local h={cys_shending_revision=42,cys_shending={dust=100,con=1,attack=1,con_gold=0,attack_gold=0,ice=6,fire=4,light=0,poison=0},
 get_scene=function()return {send2client=function(_,owner,p)sent={owner,p}end}end}
m.sync(h)
assert(sent[1]==h and sent[2].m_nUIIndex==990027)
local p=sent[2].m_Param;assert(p.m_IntCount==15 and #p.m_aIntValue==15)
local v=p.m_aIntValue;assert(v[1]==42 and v[2]==0 and v[3]==100 and v[8]==15 and v[9]==0)
assert(v[10]==6 and v[11]==4 and v[12]==0 and v[13]==0)
local values={};local ui={BeginUICommand=function()end,UICommand_AddInt=function(_,x)values[#values+1]=x end,
 EndUICommand=function()end,DispatchUICommand=function(_,id,index)assert(id==99 and index==990027)end}
h.get_obj_id=function()return 99 end
m.snapshot(ui,h,false);for i=1,15 do assert(values[i]==v[i])end
values={};m.snapshot(ui,h,true);assert(values[2]==1 and values[8]==15 and values[10]==6)
assert(h.cys_shending.dust==100 and h.cys_shending_revision==42)
sent=nil;m.sync({});assert(sent==nil)
print('PASS ShenDing login payload matches workshop snapshot: 15 fields, no auto-open, actual attributes, unchanged currency/revision, uninitialized guard')
