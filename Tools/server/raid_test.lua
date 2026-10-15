local staged,live=assert(arg[1]),assert(arg[2])
package.path=staged..'/lualib/?.lua;'..live..'/lualib/?.lua;'..package.path
local checks=0
local function check(v,n)checks=checks+1;assert(v,n)end
local function clone(t)if type(t)~='table'then return t end local r={}for k,v in pairs(t)do r[k]=clone(v)end return r end
table.clone=clone
local now=100;package.loaded.skynet={now=function()return now end,send=function()end,call=function()return true end}
package.loaded['game.packet']=setmetatable({},{__index=function(t,k)local p={new=function()return {xy_id=k}end};t[k]=p;return p end})
local Raid=require 'raid';local Team=require 'team';local C={char_ask_team_info=function()end}
require('cys_social_world').install(C)
local users,raids,teams={},{},{}
local w=setmetatable({server_id=1},{__index=C})
w.raid_list={get_raid=function(_,id)return raids[id]end,create_raid=function()local id=#raids+1;local r=Raid.new();r:set_raid_id(id);raids[id]=r;return id end,destory_raid=function(_,id)raids[id]:clean_up();raids[id]=nil end}
w.team_list={get_team=function(_,id)return teams[id]end}
function w:find_user(id)return users[id]end
function w:find_user_by_name(name)for _,u in pairs(users)do if u.uinfo.name==name then return u end end end
function w:send2client(u,p)u.last=clone(p)end
function w:char_dismiss_team(id)local t=teams[users[id].uinfo.team_id];for _,m in ipairs(t:get_members())do m.team_id=-1 end;teams[t:get_team_id()]=nil end
for i=1,33 do users[i]={uinfo={guid=i,name='Raid'..i,raid_id=-1,team_id=-1,level=60,menpai=1,sceneid=2}}end
local t=Team.new();t:set_team_id(1);t:add_member(users[1].uinfo);t:add_member(users[2].uinfo);teams[1]=t
for i=1,2 do users[i].uinfo.team_id=1 end
w:char_create_raids{m_CreateGUID=2,m_CreateTeamId=1};check(users[2].uinfo.raid_id==-1,'member cannot create raid')
w:char_create_raids{m_CreateGUID=1,m_CreateTeamId=1};local r=raids[1]
check(r and r:member_count()==2 and users[1].uinfo.team_id==-1,'party converted to raid')
w:char_ret_raid_invite(3,{m_GUID=1,m_Return=1});check(r:member_count()==2,'unsolicited accept rejected')
local function invite(i)w:char_invite_raid{m_SourObjID=1,m_DestName='Raid'..i}end
local function accept(i)w:char_ret_raid_invite(i,{m_GUID=1,m_Return=1})end
invite(3);accept(3);accept(3);check(r:member_count()==3,'invite accepted exactly once')
invite(4);now=now+6001;accept(4);check(r:member_count()==3,'expired invitation rejected')
invite(4);users[4]=clone(users[4]);accept(4);check(r:member_count()==3,'session replacement rejects stale invitation')
w:char_apply_raid{m_SourGUID=4,m_DestName='Raid2'};check(users[1].last.m_SourGUID==4,'application addressed to chief')
w:char_ret_raid_apply(2,{source_guid=4,return_type=1});check(r:member_count()==3,'member cannot approve')
w:char_ret_raid_apply(1,{source_guid=4,return_type=1});check(r:member_count()==4,'chief approves application')
for i=5,30 do invite(i);accept(i)end
check(r:member_count()==30,'capacity thirty')
for _,s in ipairs(r.members)do check(#s==6,'each squad limited to six')end
invite(31);accept(31);check(r:member_count()==30 and users[31].uinfo.raid_id==-1,'full raid rejects thirty-first')
w:char_raid_kick{m_OperateGUID=2,m_TargetGUID=3};check(r:member_count()==30,'member cannot kick')
w:char_raid_appoint{m_OperateGUID=1,m_TargetGUID=2,m_Position=1}
w:char_raid_kick{m_OperateGUID=2,m_TargetGUID=1};check(r:member_count()==30,'assistant cannot kick chief')
w:char_raid_kick{m_OperateGUID=2,m_TargetGUID=3};check(r:member_count()==29 and users[3].uinfo.raid_id==-1,'assistant kicks regular member')
local a,b=r.members[1][1],r.members[2][1]
w:raid_modify_member_position{m_OperateGUID=4,m_sSquadIndex=0,m_sMemIndex=0,m_dSquadIndex=1,m_dMemIndex=0};check(r.members[1][1]==a,'member cannot move squad roster')
w:raid_modify_member_position{m_OperateGUID=1,m_sSquadIndex=0,m_sMemIndex=0,m_dSquadIndex=1,m_dMemIndex=0};check(r.members[1][1]==b and r.members[2][1]==a,'leader swaps full squads')
w:raid_modify_member_position{m_OperateGUID=1,m_sSquadIndex=5,m_sMemIndex=0,m_dSquadIndex=1,m_dMemIndex=0};check(r:member_count()==29,'out of bounds move rejected')
w:char_leave_raid(1);check(r:leader(0).guid==2 and r:member_count()==28,'assistant succeeds departing leader')
w:char_ask_team_info(2);check(users[2].last.m_nMemberCount==28,'fresh authoritative roster')
for i=2,30 do w:char_leave_raid(i)end
check(not raids[1],'empty raid released')
print('PASS raid checks='..checks)
