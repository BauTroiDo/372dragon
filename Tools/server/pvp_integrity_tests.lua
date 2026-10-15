-- Runs actual runtime method bodies against deterministic boundary fixtures.
local root,lib=...;package.path=lib..'/?.lua;'..package.path
local total,failed=0,0
local function test(n,f)total=total+1;local ok,e=pcall(f);print((ok and 'PASS 'or'FAIL ')..n..(ok and ''or': '..tostring(e)));if not ok then failed=failed+1 end end
local function eq(a,b)assert(a==b,tostring(a)..' ~= '..tostring(b))end
local function near(a,b)assert(math.abs(a-b)<0.000001,tostring(a)..' ~= '..tostring(b))end
local function grab(path,name,env)local f=assert(io.open(root..'/'..path,'rb'));local t=f:read('a'):gsub('\r\n','\n');f:close();assert(load(assert(t:match('function '..name..'%([^\n]*\n.-\nend'),name),'@'..path,'t',env))()end
local define={PK_MODE={PEACE=0,PERSONAL=1,GOD_AND_EVIL=2,TEAM=3,BANG_HUI=4,RAID=5},PK_MODE_CHANGE_DELAY=600000,LIMIT_PK_MODE_ON_SCENE={},INVAILD_ID=-1,ITEM_ATTRIBUTE={IATTRIBUTE_IMMUNITY_P=25,IATTRIBUTE_IMMUNITY_M=32},MD_ENUM={MD_TIAOZHAN_SCRIPT=77},OPERATE_RESULT={OR_PVP_MODE_SWITCH_DELAY=1}}
local enum={IDX_DAMAGE_PHY=0,IDX_DAMAGE_MAGIC=1,IDX_DAMAGE_COLD=2,IDX_DAMAGE_FIRE=3,IDX_DAMAGE_LIGHT=4,IDX_DAMAGE_POISON=5}
local env=setmetatable({human={},combat_core={},scenecore={},leitai={},define=define,enum_damage_type=enum,skynet={error=function()end,logi=function()end}},{__index=_G})
local H,C,S,L=env.human,env.combat_core,env.scenecore,env.leitai
env.skill={};env.combat_core=C;C.new=function()return C end
package.preload['cy_four_combat.release']=function()return{dark_wound=function(_,_,v)return v end}end
for _,n in ipairs({'is_hit','is_critical_hit'})do grab('GameServer/services/scene/skill/base.lua','skill:'..n,env)end
define.MENPAI_ATTACK_TRAITS={[11]=17,[12]=18,[13]=19,[14]=20}
env.packet_def={GCChallenge={new=function()return{member_list={}}end}}
env.configs={get_fluctuation=function()return 0 end,get_menpai_fluctuation=function()return 0 end}
local traitRows={};for i=0,20 do traitRows[i]={id=i}end
env.configenginer={get_config=function()return traitRows end}
env.damage_impact_logic={new=function()return setmetatable({},{__index=function()return function()return 0 end end})end}
for _,n in ipairs({'get_attack_traits_type','change_pk_mode','check_pk_mode_can_change','is_enemy_human'})do grab('GameServer/services/scene/obj/human.lua','human:'..n,env)end
for _,n in ipairs({'get_result_impact','reset','calculate_hit_rate','calculate_critical_rate','is_hit','is_critical_hit','physical_damage','magic_damage','cold_damage','fire_damage','light_damage','posion_damage'})do grab('GameServer/services/scene/skill/combat_core.lua','combat_core:'..n,env)end
grab('GameServer/services/scene/scenecore.lua','scenecore:char_challenge',env)
grab('GameServer/services/scene/scenecore.lua','scenecore:get_team_challenge_members',env)
for _,n in ipairs({'GetSelfTeamId','GetTargetTeamId','GetSelfMembersCount','GetTargetMembersCount','OnPlayerLeave','OnCopySceneReady','CalcPosOffset'})do grab('Game_2/Script/scripts/event/challenge/eluoyang_challenge.lua','leitai:'..n,env)end
local function human(id)
 local h=setmetatable({id=id or 1,level=90,mode=0,pk_min_level=20,pvp_rule=11,team=-1,guild=-1,alliance=-1,raid=-1,camp=0,pk=0,school=0,flag=806012,alive=true,leader=true},{__index=H})
 h.db={get_attrib=function(_,k)return h[k]end,get_db_attrib=function(_,k)if k=='pk_mode'then return h.mode end;return h[k]end,set_db_attrib=function(_,v)for k,x in pairs(v)do if k=='pk_mode'then h.mode=x else h[k]=x end end end,set_db_attrib_nil=function(_,k)h[k]=nil end}
 function h:get_obj_type()return 'human'end;function h:get_obj_id()return self.id end;function h:get_guid()return self.id+1000 end
 function h:get_scene_id()return 2 end;function h:get_level()return self.level end;function h:get_menpai()return self.school end
 function h:get_world_pos()return{x=0,y=0}end
 function h:notify_tips()end;function h:send_operate_result_msg()end;function h:is_alive()return self.alive end;function h:get_team_id()return self.team end
 function h:get_is_team_leader()return self.leader end;function h:get_guild_id()return self.guild end
 function h:get_confederate_id()return self.alliance end;function h:get_raid_id()return self.raid end
 function h:get_server_id()return 1 end;function h:get_pk_value()return self.pk end
 function h:is_enemy_camp(o)return self.camp~=o.camp end;function h:is_attackers(o)return self.attacker==o.id end
 function h:is_in_pk_declaration_list(o)return self.declare==o.id end;function h:is_wild_war_guild()return false end
 function h:get_mission_data_by_script_id()return self.flag end
 function h:get_team_info()return {get_team_leader=function()return self:get_guid()end,has_team=function()return self.team~=-1 end}end
 return h
end
for _,mode in ipairs({0,1,2,3,4,5})do test('mode '..mode,function()local h=human();h:change_pk_mode(mode);eq(h.mode,mode)end)end
for _,mode in ipairs({-1,6,8,255,0.5,'1'})do test('invalid mode '..mode,function()local h=human();h:change_pk_mode(mode);eq(h.mode,0);eq(h.want_change_pk_mode,nil)end)end
test('peace waits ten minutes expires exactly zero',function()local h=human();h.mode=1;h:change_pk_mode(0);eq(h.mode,1);eq(h.change_pk_mode_delay,600000);h:check_pk_mode_can_change(600000);eq(h.mode,0);eq(h.want_change_pk_mode,nil)end)
test('missing timer safe fallback',function()local h=human();h.mode=1;h.want_change_pk_mode=0;h:check_pk_mode_can_change(1000);eq(h.mode,1);eq(h.change_pk_mode_delay,599000)end)
for _,rate in ipairs({0,0.5,1})do test('hit probability '..rate,function()local n=0;for i=1,100 do if C:is_hit(rate,i)then n=n+1 end end;eq(n,rate*100)end)end
test('hit critical basic ratios',function()near(C:calculate_hit_rate(100,100),.5);near(C:calculate_critical_rate(100,100),.05)end)
for _,rate in ipairs({-1,0,50,80,85,90,95,100})do test('actual skill hit percent '..rate,function()
 local me={get_hit=function()return 75 end,get_skill_info=function()return{get_accuracy_rate_up=function()return 0 end}end}
 local other={get_miss=function()return 25 end,refix_miss_rate=function()return 0 end,target_refix_accuracy_rate=function()return 0 end}
 local old=math.random;local count=0
 local ok,err=pcall(function()for roll=1,100 do math.random=function()return roll end;if env.skill:is_hit(me,other,rate)then count=count+1 end end end)
 math.random=old;assert(ok,err);eq(count,rate==-1 and 75 or rate)
end)end
for _,rate in ipairs({-1,0,7,50,100})do test('actual skill critical percent '..rate,function()
 local me={get_mind_attack=function()return 100 end,impact_refix_critical_rate=function(_,r)return r end}
 local other={get_mind_defend=function()return 100 end};local info={get_mind_attack_rate_up=function()return .02 end}
 local old=math.random;local count=0
 local ok,err=pcall(function()for roll=1,100 do math.random=function()return roll end;if env.skill:is_critical_hit(me,other,rate,info)then count=count+1 end end end)
 math.random=old;assert(ok,err);eq(count,rate==-1 and 7 or rate)
end)end
local map={[0]=0,1,2,3,4,5,6,7,8,9,16,17,18,19,20,15}
for school,trait in pairs(map)do test('school '..school..' final trait '..trait,function()
 local h=human();h.school=school;function h:on_impact_get_combat_result()end
 local used;local c=setmetatable({physical_damage=function(_,a,b,c,d,t)used=t.id;error('stop after recording selected trait')end},{__index=C});c:reset()
 pcall(function()c:get_result_impact(h,h,{})end);eq(used,trait)
end)end
test('peace neutral protected',function()eq(human():is_enemy_human(human(2)),false)end)
test('personal target',function()local a,b=human(),human(2);a.mode=1;eq(a:is_enemy_human(b),true)end)
test('safe bit mask',function()local a,b=human(),human(2);a.pvp_rule=0;a.pk_min_level=1;b.pk_min_level=1;a.mode=1;eq(a:is_enemy_human(b),false)end)
test('underlevel attacker',function()local a,b=human(),human(2);a.level=19;a.mode=1;eq(a:is_enemy_human(b),false)end)
test('peace counterattack',function()local a,b=human(),human(2);a.attacker=b.id;eq(a:is_enemy_human(b),true)end)
test('declaration respects scene permission',function()local a,b=human(),human(2);a.declare=b.id;a.pvp_rule=2;eq(a:is_enemy_human(b),false);a.pvp_rule=10;eq(a:is_enemy_human(b),true)end)
test('team friend and enemy',function()local a,b=human(),human(2);a.mode=3;a.team=7;b.team=7;eq(a:is_enemy_human(b),false);b.team=8;eq(a:is_enemy_human(b),true)end)
test('guild alliance',function()local a,b=human(),human(2);a.mode=4;a.guild=7;b.guild=7;eq(a:is_enemy_human(b),false);b.guild=8;a.alliance=4;b.alliance=4;eq(a:is_enemy_human(b),false);b.alliance=5;eq(a:is_enemy_human(b),true)end)
test('raid friend and enemy',function()local a,b=human(),human(2);a.mode=5;a.raid=7;b.raid=7;eq(a:is_enemy_human(b),false);b.raid=8;eq(a:is_enemy_human(b),true)end)
test('good evil',function()local a,b=human(),human(2);a.mode=2;eq(a:is_enemy_human(b),false);b.pk=1;eq(a:is_enemy_human(b),true)end)
test('competitive camp without free PK',function()local a,b=human(),human(2);a.pvp_rule=4;a.camp=10;b.camp=11;eq(a:is_enemy_human(b),true);b.camp=10;a.mode=1;eq(a:is_enemy_human(b),false)end)
local traits={[0]=1000000,1000000,1000000,1000000,1000000,1000000}
local function fighter()
 local v={p=0,m=0,atk=1000,def=100,reduce=0,floor=0}
 setmetatable(v,{__index=function(t,k)
  if k:match('^get_attack_')then return function()return t.atk end end
  if k:match('^get_defence_')then return function()return t.def end end
  if k:match('^get_reduce_def_.*low')then return function()return t.floor end end
  if k:match('^get_reduce_def_')then return function()return t.reduce end end
 end})
 function v:get_obj_type()return 'human'end
 function v:item_value(n)return n==25 and self.p or n==32 and self.m or 0 end
 function v:get_skill_info()return nil end
 function v:get_dw_jinjie_effect_details()return 0,1 end
 return v
end
for _,kind in ipairs({'physical','magic'})do test(kind..' independent immunity',function()local a,b=fighter(),fighter();local f=C[kind..'_damage'];local base=f(C,a,b,0,0,traits);b.p=50;b.m=25;near(f(C,a,b,0,0,traits),base*(kind=='physical' and .5 or .75))end)end
for _,kind in ipairs({'cold','fire','light','posion'})do test(kind..' resistance penetration floor',function()local a,b=fighter(),fighter();local f=C[kind..'_damage'];b.def=50;near(f(C,a,b,0,0,traits),500);a.reduce=50;near(f(C,a,b,0,0,traits),1000);a.reduce=100;a.floor=30;near(f(C,a,b,0,0,traits),1300);b.def=200;near(f(C,a,b,0,0,traits),0)end)end
local now=100;package.preload.skynet=function()return{time=function()return now end}end
package.preload.define=function()return define end
package.preload['game.packet']=function()return{GCChallenge={new=function()return{member_list={}}end}}end
local function scene()
 local a,b=human(1),human(2);local s=setmetatable({objs={[1]=a,[2]=b},calls=0,sent=0},{__index=S})
 s.scriptenginer={call=function(_,id,f,x,y)if f=='HaveChallengeFlag'then return s.objs[x].flag>0 end;s.calls=s.calls+1 end}
 function s:send2client()self.sent=self.sent+1 end;function s:get_team_challenge_members(h)return{h}end
 function s:make_challenge_member(h)return{name='fixture'}end
 function s:get_obj_by_guid(g)for _,h in pairs(self.objs)do if h:get_guid()==g then return h end end end
 function s:get_obj_by_id(id)return self.objs[id]end
 return s,a,b
end
test('forged accept',function()local s=scene();s:char_challenge(2,{type=1,m_objID=1});eq(s.calls,0)end)
test('invite accept and replay',function()local s=scene();s:char_challenge(1,{type=0,m_objID=2});eq(s.sent,1);s:char_challenge(2,{type=1,m_objID=1});eq(s.calls,1);s:char_challenge(2,{type=1,m_objID=1});eq(s.calls,1)end)
test('reject consumes',function()local s=scene();s:char_challenge(1,{type=0,m_objID=2});s:char_challenge(2,{type=2,m_objID=1});s:char_challenge(2,{type=1,m_objID=1});eq(s.calls,0)end)
test('expired invitation',function()local s=scene();s:char_challenge(1,{type=0,m_objID=2});now=now+31;s:char_challenge(2,{type=1,m_objID=1});eq(s.calls,0)end)
for _,key in ipairs({'dead','left platform','same team','non leader','reused object'})do test('arena rejects '..key,function()local s,a,b=scene();s:char_challenge(1,{type=0,m_objID=2});if key=='dead'then b.alive=false elseif key=='left platform'then b.flag=0 elseif key=='same team'then a.team=8;b.team=8 elseif key=='non leader'then b.team=8;b.leader=false else a.id=7 end;s:char_challenge(2,{type=1,m_objID=1});eq(s.calls,0)end)end
for _,value in ipairs({-13,0,123,127})do test('arena packed team count '..value,function()local x=setmetatable({LuaFnGetCopySceneData_Param=function()return value end},{__index=L});eq(x:GetSelfMembersCount(),math.abs(value)%10);eq(x:GetTargetMembersCount(),math.abs(value)%10);eq(x:GetSelfTeamId(),value<0 and math.ceil(value/10)or math.floor(value/10));eq(x:GetTargetTeamId(),x:GetSelfTeamId())end)end
test('arena leave clears camp',function()local order={};local x=setmetatable({SetUnitCampID=function(_,id,c)eq(c,-1);order[#order+1]='camp'end,LuaFnChallengeRestoreSkillCoolDown=function()order[#order+1]='cool'end},{__index=L});x:OnPlayerLeave(1);eq(order[1],'camp')end)
test('actual arena member filter and six member cap',function()
 local leader=human(1);leader.team=3;local near={}
 for i=2,11 do local h=human(i);h.team=3;near[#near+1]=h end
 near[1].alive=false;near[2].flag=0;near[3].team=4
 local old=env.configenginer.get_config;env.configenginer.get_config=function()return{Human={CanGetExpRange=50}}end
 local s=setmetatable({scan=function()return near end},{__index=S});local list=s:get_team_challenge_members(leader)
 env.configenginer.get_config=old;eq(#list,6);eq(list[1],leader)
 for _,h in ipairs(list)do assert(h.alive and h.flag==leader.flag and h.team==leader.team)end
end)
for _,condition in ipairs({'valid','missing','dead','left platform'})do test('allocator revalidation '..condition,function()
 local s,a,b=scene();local moved=0
 if condition=='missing'then s.objs[2]=nil elseif condition=='dead'then b.alive=false elseif condition=='left platform'then b.flag=0 end
 local x=setmetatable({scene=s,g_Pos={x=31,z=32,offset=3.53},g_client_res=92,get_scene_id=function()return 0 end,LuaFnSetCopySceneData_Param=function()end,LuaFnGetCopySceneData_Sn=function()return 7 end,LuaFnGetCopySceneData_TeamLeader=function()return 1 end,LuaFnGuid2ObjId=function(_,id)return id end,LuaFnGetCopySceneData_Param=function()return 2 end,GetTeamId=function(_,id)assert(s.objs[id]);return -1 end,LuaFnIsCanDoScriptLogic=function()return true end,NewWorld=function()moved=moved+1 end},{__index=L})
 x.LuaFnHasTeam=function()return false end
 x:OnCopySceneReady(2000);eq(moved,condition=='valid'and 2 or 0)
end)end
print(('RESULT tests=%d failed=%d'):format(total,failed));os.exit(failed==0 and 0 or 1)
