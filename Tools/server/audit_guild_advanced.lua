-- Read-only regression reproductions for the existing guild implementation.
-- All RPC, persistence and player objects below are isolated doubles. No server
-- service, socket or database is contacted. CONFIRMED means a defect reproduced,
-- not that the gameplay feature passed acceptance testing.
local root = assert(arg[1], 'path to the private CY server root')
package.path = root..'/GameServer/lualib/?.lua;'..package.path
local define = require 'define'
local results = 0
local function confirmed(id, condition, detail)
    assert(condition, 'Reproduction changed: '..id)
    results = results + 1
    print('CONFIRMED '..id..' | '..detail)
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
do
    local w=world()
    w:guild_wild_war(12,{my_guild_id=1,tar_guild_id=2})
    confirmed('WAR-01',w.guilds[1].ambi_level==400 and not w.guilds[1].wild_war_list,
        'regular member loses 100 guild expansion although declaration is rejected')
end
do
    local w=world()
    w:guild_wild_war(11,{my_guild_id=1,tar_guild_id=999})
    confirmed('WAR-02',w.guilds[1].ambi_level==400,
        'missing target guild still consumes 100 expansion')
end
do
    local w=world()
    w:guild_wild_war(11,{my_guild_id=1,tar_guild_id=2})
    w:guild_wild_war(11,{my_guild_id=1,tar_guild_id=2})
    confirmed('WAR-03',#w.guilds[1].wild_war_list==2 and w.guilds[1].ambi_level==300,
        'same target can be inserted twice and charged twice')
end
do
    local w=world()
    local ok=pcall(w.initiate_guild_war,w,999,{my_guild_id=1,tar_guild_id=2})
    confirmed('WAR-04',not ok,'unknown requesting member raises Lua error instead of rejection')
end
do
    local w=world()
    w.guilds[1].war_list={{id=2,remain_time=1}}
    w:check_war_expired(1000)
    confirmed('WAR-05',#w.guilds[1].war_list==1,
        'unaccepted battle request never reaches expiry timer')
end
do
    local w=world()
    local ok=pcall(w.get_guild_league_info,w,11,{league_id=999})
    confirmed('LEAGUE-01',not ok,'requesting a missing league raises Lua error')
end
do
    local w=world()
    w.leagues={{id=1,name='AuditLeague',guilds={{id=1,join_date=2609280700},{id=2}}}}
    confirmed('LEAGUE-02',w:get_guild_league_list()[1].guild_count==2,
        'public count includes a pending guild as an accepted member')
end
do
    local w=world()
    w.guilds[1].confederate_id=1
    w.leagues={{id=1,name='AuditLeague',chief_guid=11,chief_name='ChiefA',
        guilds={{id=1,join_date=2609280700},{id=2}}}}
    w:guild_league_quit(11,1,{})
    confirmed('LEAGUE-03',w.leagues[1].chief_guid==21 and w.guilds[2].confederate_id==-1,
        'departing leader transfers alliance to a pending, unaccepted guild')
end
do
    local w=world()
    confirmed('CITY-01',w.guilds[1].founded_money==10000000 and w:city_get_attr(1,7)==0,
        'detail treasury and script treasury use different fields')
end

-- Exercise the real NPC event function, with only engine primitives replaced.
local global={GUILD_MONEY=7,GUILD_CONTRIB_POINT=6,
    TICKET_ITEM_PARAM_CUR_MONEY_START=4,TICKET_ITEM_PARAM_CUR_MONEY_TYPE='uint',
    TICKET_ITEM_PARAM_MAX_MONEY_START=8,TICKET_ITEM_PARAM_MAX_MONEY_TYPE='uint'}
package.loaded['scripts.ScriptGlobal']=global
package.loaded.script_base=require('class')('audit_script_base')
local npc=assert(loadfile(root..'/Game_2/Script/scripts/obj/city/pc_guilddirector.lua'))()
local function trader(balance,ticket)
    local t=setmetatable({balance=balance,ticket=ticket,granted=0,reward=0,experience=0,
        changes={},params={},tips={}}, {__index=npc})
    function t:IsValidEvent()return 0 end
    function t:GetHumanGuildID()return 1 end
    function t:GetCityGuildID()return 1 end
    function t:GetGuildPos()return define.GUILD_POSITION_CHIEFTAIN end
    function t:GetLevel()return 60 end
    function t:GetBagPosByItemSn()return self.ticket and 0 or -1 end
    function t:CityGetAttr()return self.balance end
    function t:BeginEvent()end
    function t:AddText(s)table.insert(self.tips,s)end
    function t:EndEvent()end
    function t:DispatchMissionTips()end
    function t:DispatchEventList()end
    function t:BeginAddItem()end
    function t:AddItem()end
    function t:EndAddItem()return true end
    function t:AddItemListToHuman()self.granted=self.granted+1;self.ticket=true end
    function t:SetBagItemParam(_,_,start,value,vtype)
        self.params[#self.params+1]={start=start,value=value,vtype=vtype}
    end
    function t:CityChangeAttr(_,attr,amount)
        self.changes[#self.changes+1]={attr=attr,amount=amount}
    end
    function t:LuaFnRefreshItemInfo()end
    function t:GetBagItemParam()return 150000 end
    function t:AddMoney(_,n)self.reward=self.reward+n end
    function t:AddExp(_,n)self.experience=self.experience+n end
    function t:DelItem()return false end
    return t
end
do
    local t=trader(0,false)
    t:OnEventRequest(1,2,t.script_id,16)
    confirmed('TRADE-01',t.granted==1,
        'NPC grants a ticket after reporting insufficient treasury')
    confirmed('TRADE-02',type(t.params[1].value)=='string' and type(t.params[1].vtype)=='number',
        'ticket setter receives type as value and money as type')
end
do
    local t=trader(1000000,true)
    t:OnEventRequest(1,2,t.script_id,17)
    confirmed('TRADE-03',t.ticket and t.reward==15000 and t.experience==20000 and #t.changes==2,
        'NPC rewards money, EXP and guild resources despite failed ticket deletion')
end
print('REPRODUCED '..results..' defects using isolated objects; live state unchanged')
