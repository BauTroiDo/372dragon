-- Regression tests against the staged source; isolated transport and persistence.
-- Transport and persistence are isolated; these are regression checks, not GUI acceptance.
local root = assert(arg[1]);local live=assert(arg[2])
package.path=root..'/GameServer/lualib/?.lua;'..live..'/GameServer/lualib/?.lua;'..package.path
local define = require 'define'
local results = 0
local function confirmed(id, condition, detail)
    assert(condition, 'Regression failed: '..id)
    results = results + 1
    print('PASS '..id..' | '..detail)
end
local skynet = {send=function()end, call=function()return true end,
    error=function()end, logi=function()end, loge=function()end}
package.loaded.skynet = skynet
package.loaded['skynet.queue'] = function()return function(f,...)return f(...)end end
package.loaded['skynet.manager'] = {}
package.loaded['skynet.datacenter'] = {}
package.loaded['skynet.multicast'] = {}
package.loaded['wire_charset'] = {fromutf8=function(s)return s end}
package.loaded.iostream = {}
package.loaded.configenginer = {getinstance=function()return {}end}
package.loaded['game.packet'] = setmetatable({}, {__index=function(_,k)
    return {new=function()return {xy_id=k, set_content=function()end}end}
end})
local manager = assert(loadfile(root..'/GameServer/services/guild/guildmanager_core.lua'))()
local function world()
    local w = setmetatable({guilds={
        {id=1, name='AuditA', chief_guid=11, chief_name='ChiefA', confederate_id=-1,
         founded_money=10000000, ambi_level=500, city_id=1,
         users={{guid=11, name='ChiefA', position=9, access=127},
                {guid=12, name='MemberA', position=2, access=192}}},
        {id=2, name='AuditB', chief_guid=21, chief_name='ChiefB', confederate_id=-1,
         ambi_level=500, city_id=2, users={{guid=21,name='ChiefB',position=9,access=127}}}
    }, leagues={}}, {__index=manager})
    function w:db_update_guild_attr()end
    function w:multicast()end
    function w:broad_guild_wild_war_msg()end
    function w:borad_guild_be_wild_war_msg()end
    function w:notice_my_guild_wild_war()end
    function w:update_guild_confederate_id_and_name(l,g)g.confederate_id=l.id;g.confederate_name=l.name end
    function w:db_update_league_info()end
    function w:db_remove_league()end
    function w:db_remove_guild_league()end
    function w:reload_leagues()end
    return w
end
local w=world()
w:guild_wild_war(12,{my_guild_id=1,tar_guild_id=2})
confirmed('WAR-01',w.guilds[1].ambi_level==500 and not w.guilds[1].wild_war_list,'nonofficer cannot spend expansion')
w:guild_wild_war(11,{my_guild_id=1,tar_guild_id=999})
confirmed('WAR-02',w.guilds[1].ambi_level==500,'missing target costs nothing')
w:guild_wild_war(11,{my_guild_id=1,tar_guild_id=2})
w:guild_wild_war(11,{my_guild_id=1,tar_guild_id=2})
confirmed('WAR-03',#w.guilds[1].wild_war_list==1 and w.guilds[1].ambi_level==400,'valid declaration once and duplicate rejected')
confirmed('WAR-04',pcall(w.initiate_guild_war,w,999,{my_guild_id=1,tar_guild_id=2}),'forged operator rejected without exception')
w.guilds[1].war_list={{id=2,remain_time=1}};w:check_war_expired(1000)
confirmed('WAR-05',#w.guilds[1].war_list==0,'unaccepted request expires')
confirmed('LEAGUE-01',w:get_guild_league_info(11,{league_id=999})==nil,'missing league returns no result')
w.leagues={{id=1,name='Test',chief_guid=11,guilds={{id=1,join_date=1},{id=2}}}}
confirmed('LEAGUE-02',w:get_guild_league_list()[1].guild_count==1,'pending guild excluded from public count')
w.guilds[1].confederate_id=1;local removed=false
function w:db_remove_league()removed=true end
w:guild_league_quit(11,1,{})
confirmed('LEAGUE-03',removed and w.guilds[2].confederate_id==-1,'no leadership transfer to pending guild')
confirmed('CITY-01',w:city_get_attr(1,7)==10000000,'same treasury as guild details')
w:city_change_attr(11,1,7,-100)
confirmed('CITY-02',w.guilds[1].founded_money==9999900,'treasury deduction updates same field')
confirmed('LEAGUE-04',not w:guild_league_ask_enter(999,1,{league_id=1}),'forged applicant rejected')
confirmed('LEAGUE-05',not w:guild_league_answer_enter(12,1,{guild_id=2,answer=1}),'nonchief cannot admit guild')
confirmed('LEAGUE-06',not w:guild_league_kick(11,1,1),'cannot kick own guild')
w=world();w.guilds[1].ambi_level=99;w:guild_wild_war(11,{my_guild_id=1,tar_guild_id=2})
confirmed('WAR-06',not w.guilds[1].wild_war_list and w.guilds[1].ambi_level==99,'insufficient expansion rejected')
w=world();w.guilds[1].confederate_id=5;w.guilds[2].confederate_id=5;w:guild_wild_war(11,{my_guild_id=1,tar_guild_id=2})
confirmed('WAR-07',not w.guilds[1].wild_war_list and w.guilds[1].ambi_level==500,'allies cannot declare hostile war')
w=world();function w:db_update_uinfo()end
w.guilds[1].users[1].cur_contribute=4;w.guilds[1].users[1].max_contribute=9
confirmed('CITY-03',w:city_get_attr(1,6,11)==4 and w:city_get_attr(1,15,11)==9,'personal contribution reads member record')
confirmed('CITY-04',w:city_change_attr(11,1,6,-5)==0 and w:city_get_attr(1,6,11)==4,'contribution cannot underflow')
confirmed('CITY-05',w:city_change_attr(11,1,6,-1)==1 and w:city_get_attr(1,6,11)==3 and w:city_get_attr(1,15,11)==9,'spending preserves lifetime contribution')
confirmed('CITY-06',w:city_change_attr(11,1,6,2)==1 and w:city_get_attr(1,15,11)==11,'earned contribution updates lifetime')
confirmed('CITY-07',w:city_change_attr(999,1,7,-1)==0,'nonmember cannot alter treasury')
confirmed('CITY-08',w:city_change_attr(11,1,7,-10000001)==0 and w.guilds[1].founded_money==10000000,'treasury cannot underflow')
confirmed('CITY-09',w:city_change_attr(11,1,7,0/0)==0 and w:city_change_attr(11,1,7,math.huge)==0,'nonfinite values rejected')
w=world();w:initiate_guild_war(11,{my_guild_id=1,tar_guild_id=2});w:initiate_guild_war(11,{my_guild_id=1,tar_guild_id=2})
confirmed('WAR-08',#w.guilds[1].war_list==1 and #w.guilds[2].be_war_list==1,'declaration creates one mirrored request')
w:accept_guild_war(12,{my_guild_id=1,tar_guild_id=2})
confirmed('WAR-09',not w.guilds[1].war_list[1].accpectd,'outsider cannot accept defending guild request')
w:accept_guild_war(21,{my_guild_id=1,tar_guild_id=2})
confirmed('WAR-10',w.guilds[1].war_list[1].accpectd and w.guilds[2].be_war_list[1].accpectd,'defending chief acceptance updates both sides')
w:check_war_expired(45*60*1000+1)
confirmed('WAR-11',#w.guilds[1].war_list==0 and #w.guilds[2].be_war_list==0,'both accepted lists expire together')
confirmed('WAR-12',w:guild_war(11,{initiate_or_accept=255})==false,'unknown war operation rejected without assert')
print('PASS advanced guild checks='..results)
