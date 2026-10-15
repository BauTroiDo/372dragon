-- Exercise actual manager guards and creation fee against deterministic RPC stubs.
local base=assert(arg[1]);local live=assert(arg[2]);local checks=0
local function check(v,s)checks=checks+1;assert(v,s)end
package.path=live..'/lualib/?.lua;'..package.path
local define=require 'define';local calls={};local failCreate=false;local repeatCall
local skynet={send=function()end,error=function()end}
function skynet.call(target,_,method,...)
 local a={...};calls[#calls+1]={method=method,args=a}
 if method=='guild_apply'then if repeatCall then repeatCall()end;return failCreate and {flag=-3}or {flag=0,id=12,name='NewGuild',confederate_id=-1}end
 if method=='findOne'then return {attrib={guild_id=7,title={id=23,str='old'}},titles={{id=14,str='keep'},{id=23,str='old'}}}end
 if method=='safe_insert'then return true end
 return true
end
package.loaded.skynet=skynet
package.loaded['skynet.queue']=function()return function(f,...)return f(...)end end
package.loaded['game.packet']=setmetatable({},{__index=function(_,k)return {new=function()return {xy_id=k}end}end})
local mod=assert(loadfile(base..'/lualib/cys_guild.lua'))()
local C={};local reached={}
for _,n in ipairs{'guild_apply','guild_recruit','guild_exp','guild_leave','guild_appoint','guild_demise','insert_guild_uinfo'}do C[n]=function(_,...)reached[n]=(reached[n]or 0)+1;return {dest_guid=2,dest_name='Vice'}end end
function C:get_guild_by_id(id)for _,g in ipairs(self.guilds)do if g.id==id then return g end end end
function C:find_ass_cheif_in_guild(g)for _,u in ipairs(g.users)do if u.position==8 then return u end end end
function C:db_update_guild_attr(g,k,v)check(type(g)=='table','DB update receives guild record');g[k]=v end
function C:db_update_guild_desc(g,s)g.desc=s end
function C:multicast()end
mod.installManager(C)
local w=setmetatable({guilds={{id=7,name='OldGuild',chief_guid=1,users={{guid=1,position=9,access=127},{guid=2,position=8,access=141},{guid=3,position=2,access=192},{guid=4,position=1,access=0}}}}},{__index=C})
check(w:have_guild(3)and not w:have_guild(4),'membership includes regulars, excludes applicants')
check(w:guild_name_duplicated{name='OldGuild'},'duplicate checks wire name')
check(not w:insert_guild_uinfo(999,{guid=8,position=1}),'nonexistent guild cannot receive applicant')
local ok,e=w:insert_guild_uinfo(7,{guid=4,position=1});check(not ok and e==-18,'duplicate application rejected')
ok,e=w:insert_guild_uinfo(7,{guid=5,position=9});check(not ok and e==-9,'application cannot forge chief role')
ok,e=w:guild_recruit(3,{guild_id=7,m_ProposerGUID=4});check(not ok and e==-9,'regular cannot recruit')
ok,e=w:guild_recruit(1,{guild_id=7,m_ProposerGUID=3});check(not ok and e==-13,'existing member cannot be recruited twice')
check(w:guild_recruit(1,{guild_id=7,m_ProposerGUID=4})and reached.guild_recruit==1,'chief approves valid applicant')
ok,e=w:guild_exp(1,{guild_id=7,m_GuildUserGUID=1});check(not ok,'self expulsion rejected')
ok,e=w:guild_exp(2,{guild_id=7,m_GuildUserGUID=1});check(not ok,'lower role cannot expel chief')
ok,e=w:guild_leave(1,{guild_id=7});check(not ok,'chief must transfer before leave')
check(w:guild_leave(3,{guild_id=7}),'regular can leave')
ok,e=w:guild_appoint(1,{guild_id=7,guid=4,new_position=8});check(not ok,'applicant cannot skip admission')
ok,e=w:guild_appoint(1,{guild_id=7,guid=3,new_position=9});check(not ok,'appointment cannot create a second chief')
ok,e=w:guild_appoint(1,{guild_id=7,guid=3,new_position=8});check(not ok and e==-17,'single vice chief enforced')
ok,e=w:guild_new_desc(3,{guild_id=7,new_desc='bad'});check(not ok and e==-9,'regular cannot alter description')
ok,e=w:guild_new_desc(1,{guild_id=7,new_desc=string.rep('x',61)});check(not ok,'overlength description rejected')
check(w:guild_new_desc(1,{guild_id=7,new_desc='Valid\n'})and w.guilds[1].desc=='Valid','CEGUI trailing newline removed from saved description')
check(w:guild_new_desc(1,{guild_id=7,new_desc='Line 1\nLine 2\n'})and w.guilds[1].desc=='Line 1\nLine 2','intentional multiline description retained')
check(not w:guild_new_desc(1,{guild_id=7,new_desc='bad\0text'}),'NUL description rejected')
check(w:db_get_guild_id{guid=3}==7,'offline guild id comes from nested attrib')
w:db_update_user_title({guid=3,position=2},{id=-1,name=''})
local update=calls[#calls].args[1].update['$set'];check(#update.titles==1 and update.titles[1].id==14 and update['attrib.title'].str=='','leave clears guild title, preserves unrelated title')
w:db_update_user_title({guid=3,position=2},{id=7,name='OldGuild'})
update=calls[#calls].args[1].update['$set'];check(#update.titles==2 and update.titles[2].id==23,'guild title upsert works')
local H={};mod.installHuman(H)
local h=setmetatable({money=1000000,level=40,guild=-1,titles={}},{__index=H})
function h:get_money()return self.money end;function h:set_money(n)self.money=n end;function h:cost_money(n)self.money=self.money-n end
function h:get_level()return self.level end;function h:get_guild_id()return self.guild end;function h:get_guid()return 1 end
function h:get_name()return 'Owner'end;function h:get_menpai()return 0 end;function h:set_guild_id(n)self.guild=n end
function h:set_guild_name()end;function h:set_confederate_id()end;function h:set_confederate_name()end;function h:set_title()end;function h:update_titles_to_client()end
h.level=39;check(h:cys_guild_apply{name='NewGuild',desc='Description'}.flag==-1 and h.money==1000000,'low level costs nothing')
h.level=40;check(h:cys_guild_apply{name='bad\0name',desc='Description'}.flag==-2 and h.money==1000000,'invalid name costs nothing')
failCreate=true;check(h:cys_guild_apply{name='NewGuild',desc='Description'}.flag==-3 and h.money==1000000,'duplicate creation refunds reservation')
failCreate=false;repeatCall=function()check(h:cys_guild_apply{name='NewGuild',desc='Description'}.flag==-1,'double click while yielding rejected')end
check(h:cys_guild_apply{name='NewGuild',desc='Description\n'}.flag==0 and h.money==500000 and h.guild==12,'creation accepts CEGUI trailing newline and consumes fee once')
repeatCall=nil;check(h:cys_guild_apply{name='NewGuild',desc='Description'}.flag==-7 and h.money==500000,'member cannot create again')
-- Load the actual manager, including its original appointment table and response builder.
package.loaded['wire_charset']={};package.loaded['skynet.datacenter']={};package.loaded['skynet.multicast']={};package.loaded['skynet.manager']={};package.loaded.iostream={}
package.loaded.configenginer={getinstance=function()return {}end};package.loaded.cys_guild=mod
local manager=assert(loadfile(base..'/services/guild/guildmanager_core.lua'))()
local choices=manager.guild_appoint_info(w,1,7);local vice=false
for _,v in ipairs(choices)do if v.pos==8 then vice=true end end
check(#choices==6 and vice,'real manager returns chief appointment choices')
check(#manager.guild_appoint_info(w,3,7)==0,'regular member has no appointment choices')
check(manager.get_guild_list(w)[1].user_count==3,'public member count excludes pending applicants')
print('PASS guild checks='..checks)
