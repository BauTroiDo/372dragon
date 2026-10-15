-- Actual staged party implementation, real team class, isolated transport/clock.
local base=assert(arg[1]);local live=assert(arg[2]);local checks=0
local function check(v,s)checks=checks+1;assert(v,s)end
local function clone(t)if type(t)~='table'then return t end local r={}for k,v in pairs(t)do r[k]=clone(v)end return r end
table.clone=clone
package.path=live..'/lualib/?.lua;'..package.path
local sent,users,now={}, {},100
local skynet={now=function()return now end,send=function(...)end}
function skynet.call(target,_,name,...)if name=='get_player_info'then return {game_flags=users[target].flags or 0}end return true end
package.loaded.skynet=skynet
local packet=setmetatable({},{__index=function(t,k)local p={new=function()return {xy_id=k}end};rawset(t,k,p);return p end})
package.loaded['game.packet']=packet
local define=require 'define';local Team=require 'team'
local C={char_invite_team=function()error('unexpected raid')end,char_team_apply=function()error('unexpected raid')end,char_ask_team_info=function()error('unexpected raid')end}
assert(loadfile(base..'/lualib/cys_party.lua'))().install(C)
local w=setmetatable({},{__index=C});local teams={};local nextid=0
w.team_list={get_team=function(_,id)return teams[id]end,create_team=function()nextid=nextid+1;local t=Team.new();t:set_team_id(nextid);teams[nextid]=t;return nextid end,destory_team=function(_,id)teams[id]:clean_up();teams[id]=nil end}
function w:find_user(id)return users[id]end
function w:find_user_by_name(n)for _,u in pairs(users)do if u.uinfo.name==n then return u end end end
function w:send2client(u,p)sent[#sent+1]={guid=u.uinfo.guid,p=clone(p)}end
function w:create_invite_info(p,m)p.member_list=clone(m)end
function w:notify_stop_team_follow()end
for i=1,9 do users[i]={uinfo={guid=i,name='Test'..i,agent=i,team_id=-1,raid_id=-1}}end
local function size(id)local t=w.team_list:get_team(users[id].uinfo.team_id);return t and t:member_count()or 0 end
w:char_ret_invite(2,{guid=1,return_type=1});check(size(1)==0 and size(2)==0,'forged acceptance cannot create a team')
w:char_invite_team(1,{dest_name='Test1'});check(size(1)==1,'self creation')
w:char_invite_team(1,{dest_name='Test2'});w:char_ret_invite(2,{guid=1,return_type=1});check(size(1)==2,'invite accepted')
w:char_ret_invite(2,{guid=1,return_type=1});check(size(1)==2,'duplicate accept no duplicate member')
w:char_invite_team(1,{dest_name='Test3'});w:char_team_appoint(1,{dest_guid=2});w:char_ret_invite(3,{guid=1,return_type=1});check(size(3)==0,'old leader invitation invalidated')
w:char_invite_team(2,{dest_name='Test3'});now=now+6001;w:char_ret_invite(3,{guid=2,return_type=1});check(size(3)==0,'expired invitation rejected')
w:char_ret_team_apply(2,{source_guid=3,return_type=1});check(size(3)==0,'forged approval rejected')
w:char_team_apply(3,{dest_name='Test1'});w:char_ret_team_apply(2,{source_guid=3,return_type=1});check(size(3)==3,'application routed to current leader')
w:char_team_kick(1,{dest_guid=3});check(size(3)==3,'nonleader cannot kick')
w:char_dismiss_team(1);check(size(1)==3,'nonleader cannot dismiss')
w:char_team_kick(2,{dest_guid=2});check(size(2)==3,'leader cannot kick self')
users[4].flags=8;w:char_invite_team(2,{dest_name='Test4'});w:char_ret_invite(4,{guid=2,return_type=1});check(size(4)==0,'refuse setting enforced')
users[4].flags=0
for i=4,6 do w:char_invite_team(2,{dest_name='Test'..i});w:char_ret_invite(i,{guid=2,return_type=1})end
check(size(1)==6,'party capacity six')
w:char_invite_team(2,{dest_name='Test7'});w:char_ret_invite(7,{guid=2,return_type=1});check(size(7)==0 and size(1)==6,'full party rejects seventh')
w:char_team_change_option(1,{exp_mode=1});check(teams[1]:get_exp_mode()==0,'nonleader cannot change sharing')
w:char_team_change_option(2,{exp_mode=9});check(teams[1]:get_exp_mode()==0,'invalid sharing rejected')
w:char_team_change_option(2,{exp_mode=1});check(teams[1]:get_exp_mode()==1,'leader sharing accepted')
w:char_team_kick(2,{dest_guid=3});check(size(3)==0 and size(1)==5,'kick removes authoritative membership')
check(w:ask_team_member_info(3,{guid=1})==nil,'former member cannot query team')
w:char_dismiss_team(2);for i=1,6 do check(size(i)==0,'dismiss clears member '..i)end
w:char_dismiss_team(2);w:ask_team_member_info(2,{guid=1});check(true,'stale requests do not assert')
w:char_invite_team(1,{dest_name='Test8'});local old=users[8];users[8]=clone(old);w:char_ret_invite(8,{guid=1,return_type=1});check(size(8)==0,'reconnected session cannot accept stale invite')
print('PASS party checks='..checks)
