-- Complete authority checks around the original CY guild/league operations.
local queue=require 'skynet.queue'
local M={}
local function chief(self,guid,id)
    local g=self:get_guild_by_id(id)
    local u=g and self:find_user_in_guild_by_guid(guid,g)
    if u and u.position==9 then return g,u end
end
local function officer(self,guid,g)
    local u=g and self:find_user_in_guild_by_guid(guid,g)
    return u and (u.position==9 or u.position==8)
end
local function leader(self,guid,id)
    local g=chief(self,guid,id);local l=g and self:get_guild_league_by_id(g.confederate_id)
    if l and l.chief_guid==guid then return g,l end
end
function M.install(C)
    local locked=queue()
    local oldAttr=C.city_get_attr
    function C:city_get_attr(id,attr,guid)
        if attr==6 or attr==15 then
            local g=self:get_guild_by_id(id);local u=g and self:find_user_in_guild_by_guid(guid,g)
            return u and (u[attr==6 and 'cur_contribute' or 'max_contribute'] or 0) or 0
        end
        return oldAttr(self,id,attr)
    end
    function C:city_change_attr(guid,id,attr,change)
        if type(change)~='number' or change~=change or math.abs(change)>2147483647 then return 0 end
        change=math.floor(change)
        local g=self:get_guild_by_id(id);local u=g and self:find_user_in_guild_by_guid(guid,g)
        if not u or (u.position or 0)<2 then return 0 end
        local value=self:city_get_attr(id,attr,guid)+change
        if value<0 or value>2147483647 then return 0 end
        if attr==6 then
            u.cur_contribute=value
            if change>0 then u.max_contribute=(u.max_contribute or 0)+change;u.week_contribute=(u.week_contribute or 0)+change end
            self:db_update_uinfo(id,u)
        else
            local keys={[0]='ind_level',[1]='agr_level',[2]='com_level',[3]='def_level',[4]='tech_level',[5]='ambi_level',[7]='founded_money'}
            local key=keys[attr];if not key then return 0 end
            g[key]=value;self:db_update_guild_attr(g,key,value)
        end
        return 1
    end
    local oldWild=C.guild_wild_war
    function C:guild_wild_war(guid,r)
        local a=self:get_guild_by_id(r.my_guild_id);local b=self:get_guild_by_id(r.tar_guild_id)
        if not a or not b or a==b or not officer(self,guid,a) then return false end
        if (a.ambi_level or 0)<100 or self:is_wild_war_list_full(a) or self:is_be_wild_war_list_full(b) or
           self:is_in_wild_war_list(a,b) or self:is_in_wild_war_list(b,a) then return false end
        if (a.confederate_id or -1)>=0 and a.confederate_id==b.confederate_id then return false end
        return oldWild(self,guid,r)
    end
    function C:guild_war(guid,r)
        if type(r)~='table' then return false end
        if r.initiate_or_accept==0 then return self:initiate_guild_war(guid,r) end
        if r.initiate_or_accept==1 then return self:accept_guild_war(guid,r) end
        return false
    end
    local oldWar=C.initiate_guild_war;local oldAccept=C.accept_guild_war
    function C:initiate_guild_war(guid,r)
        local a=self:get_guild_by_id(r.my_guild_id);local b=self:get_guild_by_id(r.tar_guild_id)
        if not a or not b or a==b or not officer(self,guid,a) or (b.city_id or -1)<0 then return false end
        if (a.confederate_id or -1)>=0 and a.confederate_id==b.confederate_id then return false end
        return oldWar(self,guid,r)
    end
    function C:accept_guild_war(guid,r)
        local a=self:get_guild_by_id(r.my_guild_id);local b=self:get_guild_by_id(r.tar_guild_id)
        if not a or not b or a==b or not officer(self,guid,b) then return false end
        if self:is_guild_war_accpectd(a) or self:is_guild_be_war_accpectd(b) then return false end
        return oldAccept(self,guid,r)
    end
    local oldCreate=C.create_guild_league
    function C:create_guild_league(guid,id,r)
        local g=chief(self,guid,id)
        if not g or (g.confederate_id or -1)~=-1 or type(r.name)~='string' or type(r.desc)~='string' then return end
        r.name=r.name:gsub('%z.*',''):match('^%s*(.-)%s*$');r.desc=r.desc:gsub('%z.*',''):match('^%s*(.-)%s*$')
        if r.name=='' or #r.name>31 or #r.desc>63 or r.name:find('[%c]') or r.desc:find('[%c]') then return end
        return oldCreate(self,guid,id,r)
    end
    local oldAsk=C.guild_league_ask_enter
    function C:guild_league_ask_enter(guid,id,r)
        local g=chief(self,guid,id);local l=self:get_guild_league_by_id(r.league_id)
        if not g or not l or (g.confederate_id or -1)~=-1 or self:get_league_guilds_member_count(l)>=3 then return false end
        if #l.guilds>=128 then return false end
        return oldAsk(self,guid,id,r)
    end
    local oldApps=C.guild_league_member_apply_list
    function C:guild_league_member_apply_list(guid,id,r)
        if not leader(self,guid,id) then return end
        return oldApps(self,guid,id,r)
    end
    local oldAnswer=C.guild_league_answer_enter
    function C:guild_league_answer_enter(guid,id,r)
        local g,l=leader(self,guid,id)
        local m=l and self:get_guild_in_league_by_id(l,r.guild_id)
        local target=m and self:get_guild_by_id(m.id)
        if not g or not m or m.join_date or not target or (target.confederate_id or -1)~=-1 then return false end
        if r.answer~=0 and r.answer~=1 then return false end
        if r.answer==1 and self:get_league_guilds_member_count(l)>=3 then return false end
        return oldAnswer(self,guid,id,r)
    end
    local oldKick=C.guild_league_kick
    function C:guild_league_kick(guid,id,target)
        local g,l=leader(self,guid,id)
        local m=l and self:get_guild_in_league_by_id(l,target)
        if not g or target==id or not m or not m.join_date or not self:get_guild_by_id(target) then return false end
        return oldKick(self,guid,id,target)
    end
    function C:guild_league_quit(guid,id)
        local g=chief(self,guid,id);local l=g and self:get_guild_league_by_id(g.confederate_id)
        if not l then return false end
        self:remove_guild_in_league_by_id(g,l)
        self:update_guild_confederate_id_and_name({id=-1,name=''},g)
        if l.chief_guid==guid then
            local successor
            for _,m in ipairs(l.guilds)do
                if m.join_date then local nextGuild=self:get_guild_by_id(m.id);successor=nextGuild and self:find_cheif_in_guild(nextGuild);if successor then break end end
            end
            if successor then l.chief_guid=successor.guid;l.chief_name=successor.name;self:db_update_league_info(l)
            else self:db_remove_league(l) end
            self:reload_leagues()
        end
        return true
    end
    -- One outer lock also covers the previously implemented role operations.
    -- The database yields cannot interleave removal/demotion with a declaration.
    for _,name in ipairs{'guild_wild_war','guild_war','initiate_guild_war','accept_guild_war',
        'create_guild_league','guild_league_ask_enter','guild_league_member_apply_list','guild_league_answer_enter',
        'guild_league_kick','guild_league_quit','city_change_attr',
        'guild_apply','insert_guild_uinfo','guild_recruit','guild_exp','guild_leave','guild_appoint','guild_demise','guild_new_desc'} do
        local f=C[name];if f then C[name]=function(self,...)return locked(f,self,...)end end
    end
    return C
end
return M
