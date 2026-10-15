local root=assert(arg[1]);package.path=root..'/GameServer/lualib/?.lua;'..package.path
for _,rel in ipairs({'GameServer/services/msgagent.lua','GameServer/services/world/worldcore.lua','GameServer/services/scene/scenecore.lua'}) do assert(loadfile(root..'/'..rel)) end
local checks=0
local function check(v,why) assert(v,why);checks=checks+1 end
local sent,tips,money,nb,auth,creates,traps=0,{},100,100,98,0,0
package.loaded.wire_charset={toutf8=function(s)return s end}
package.loaded.class=function()return {}end
package.loaded.define={INVAILD_ID=-1}
local conf={common_item={[30602001]={name='food'}},equip_base={},gem_info={},pet_equip_base={},
 std_impact_config={[1]={}},special_obj_data={[1]={}},monster_attr_ex={[2]={}},scene_info={scene2={}}}
package.loaded.configenginer={getinstance=function()return {get_config=function(_,name)return conf[name]end}end}
package.loaded.human_item_logic={create_multi_item_to_bag=function()creates=creates+1;return true,0 end,
 erase_item_by_bag_index=function()error('must not clear without confirmation')end}
package.loaded.impactenginer={getinstance=function()return {send_impact_to_unit=function()end}end}
local valid=true
package.loaded.skynet={call=function()return valid end,logw=function()end}
local scene={get_id=function()return 2 end,get_script_engienr=function()return {call=function()return auth end}end,
 create_temp_monster=function()return -1 end,get_obj_by_id=function()return nil end}
local h={get_scene=function()return scene end,get_obj_id=function()return 1 end,get_guid=function()return 200016 end,
 get_name=function()return 'synthetic'end,get_level=function()return 95 end,get_world_pos=function()return {x=100,y=100}end,
 get_money=function()return money end,set_money=function(_,n)money=n end,get_yuanbao=function()return nb end,set_yuanbao=function(_,n)nb=n end,
 notify_tips=function(_,s)tips[#tips+1]=s end,get_max_hp=function()return 1000 end,get_max_mp=function()return 500 end,
 set_hp=function(_,v)check(v==1000,'heal hp')end,set_mp=function(_,v)check(v==500,'heal mp')end,
 skill_create_obj_specail=function()traps=traps+1;return nil end,on_teleport=function()sent=sent+1 end,
 get_prop_bag_container=function()return {get_item=function()return nil end}end,add_exp=function()sent=sent+1 end}
local gm=require'GMCommand'
check(gm:process(h,'help') and #tips==2,'help feedback')
check(gm:process(h,'info'),'position info')
for _,command in ipairs({'vothach@bad','vothach@-1','vothach@nan','vothach@1.5','nb@999999999999',
 '获取金币@bad','创建怪物@99999999@1','创建陷阱@99999999@1','monster@2@0','monster@2@101',
 'item@30602001@-1','item@999@1','clearbag','tp@999@10@10','tp@2','impact@999','no-such-command'}) do
 check(not gm:process(h,command),'reject '..command);check(not h._cys_gm_busy,'unlocked after rejection')
end
check(money==100 and nb==100 and creates==0 and sent==0,'invalid commands have no state change')
check(traps==0,'unknown trap cannot allocate an object')
check(not gm:process(h,'trap@1') and traps==1,'failed configured trap has no nil dereference')
auth=0;check(not gm:process(h,'vothach@7') and money==100,'non-GM rejected')
auth=1;check(not gm:process(h,'item@30602001@1'),'low privilege rejected')
auth=98;h._leaving=true;check(not gm:process(h,'vothach@7') and money==100,'stale owner rejected');h._leaving=nil
check(gm:process(h,'vothach@7') and money==107,'authorized add')
check(gm:process(h,'获取YB@7') and nb==107,'legacy alias')
check(gm:process(h,'item@30602001@1') and creates==1,'item valid')
check(gm:process(h,'heal'),'heal both stats')
money=2147483647;check(not gm:process(h,'vothach@1') and money==2147483647,'overflow rejected')
valid=false;check(not gm:process(h,'tp@2@100@100') and sent==0,'blocked destination')
valid=true;check(gm:process(h,'tp@2@100@100') and sent==1,'valid destination')
check(gm:process(h,'monster@2@1'),'failed spawn has no nil dereference')
local guard=require'cys_mail_guard';local state={}
local mail={dest='synthetic',content='offline only'}
check(guard.accept(state,mail,0),'first mail')
for i=1,20 do check(not guard.accept(state,mail,1),'repeat burst rejected') end
check(not guard.accept(state,mail,5),'identical duplicate rejected')
check(guard.accept(state,{dest='synthetic',content='second'},5),'new text after cooldown')
check(not guard.accept(state,{dest='synthetic',content='third'},6),'new text within cooldown rejected')
for i=2,9 do check(guard.accept(state,{dest='synthetic',content='mail'..i},i*5),'within minute budget') end
check(not guard.accept(state,{dest='synthetic',content='eleventh'},55),'minute budget exhausted')
check(guard.accept(state,mail,60),'same text allowed after duplicate window')
for _,m in ipairs({{}, {dest='',content='x'},{dest='x',content=''}, {dest='x',content=string.rep('x',1025)},{dest='x\0',content='a'}}) do
 check(not guard.accept({},m,100),'bad mail rejected')
end
-- Execute the deployed agent/world entry points without opening sockets or sending real mail.
local function source(rel,first,last)
 local f=assert(io.open(root..'/'..rel,'rb'));local s=f:read('*a');f:close()
 local a=assert(s:find(first,1,true));local b=assert(s:find(last,a+#first,true))
 return s:sub(a,b-1)
end
local clock,delivered,queued=100,0,0
local world={find_user=function(_,id)return id==200016 end,send_mail=function()delivered=delivered+1 end}
local sky={now=function()return clock*100 end}
local env=setmetatable({worldcore=world,skynet=sky},{__index=_G})
assert(load(source('GameServer/services/world/worldcore.lua','function worldcore:send_player_mail(',
 'function worldcore:send_mail('),'world-mail','t',env))()
local function agent()
 local request={}
 local e=setmetatable({request=request,skynet=sky,define={MAIL_TYPE={MAIL_TYPE_NORMAL=0}},
  ma_func={get_guid=function()return 200016 end,get_name=function()return 'synthetic-sender' end}},{__index=_G})
 local s=source('GameServer/services/msgagent.lua','local cys_mail_guard = require "cys_mail_guard"',
  '\nend')..'\nend'
 assert(load(s,'agent-mail','t',e))();return request.CGMail
end
sky.send=function(dst,kind,method,id,m)
 check(dst=='.world' and kind=='lua' and method=='send_player_mail' and id==200016,'player mail route')
 check(m.source=='synthetic-sender' and m.flag==0 and m.param_1==nil and m.param_5==nil,'server-authored mail metadata')
 queued=queued+1;return world:send_player_mail(id,m)
end
local function msg(text,id)return {guid=id or 200016,dest='synthetic-recipient',content=text or 'hello',source='spoof',flag=99,param_1=9,param_5=9}end
local submit=agent();submit(msg('hello',123));check(queued==0,'forged owner rejected at agent')
submit(msg());check(queued==1 and delivered==1,'normal mail traverses both guards')
submit(msg('burst'));check(queued==1 and delivered==1,'agent rejects before RPC')
local reconnected=agent();reconnected(msg());check(queued==2 and delivered==1,'world rejects duplicate across reconnect')
clock=105;reconnected(msg('second'));check(delivered==2,'valid subsequent mail')
check(not world:send_player_mail(999,msg('offline',999)),'offline sender rejected')
check(not world:send_player_mail(200016,msg('forged',999)),'world rejects mismatched owner')
world:send_mail(msg('system'));check(delivered==3,'internal mail remains independent of player limit')
clock=500;reconnected(msg('new window'));check(delivered==4,'expiry pruning allows later mail')
print('PASS runtime repair contracts checks='..checks)
