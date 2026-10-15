-- CY party commands. Membership commits do not yield; notifications follow the commit.
local skynet=require 'skynet'
local packet=require 'game.packet'
local define=require 'define'
local M={}
local function user(w,id)return w:find_user(id)end
local function team(w,u)return u and w.team_list:get_team(u.uinfo.team_id or -1)end
local function raid(u)return u and (u.uinfo.raid_id or -1)~=-1 end
local function err(w,u,code)
    if u then local p=packet.GCTeamError.new();p.error_code=code;w:send2client(u,p)end
end
local function list(w,t,recipient)
    local p=packet.GCTeamList.new();p.type=define.TEAM_LIST_TYPE.REFRESH
    p.team_id=t and t:get_team_id() or 65535;p.exp_mode=t and t:get_exp_mode() or 0
    p.member_list={};for _,m in ipairs(t and t:get_members() or {})do p.member_list[#p.member_list+1]=table.clone(m)end
    p.uinfos=p.member_list;p.member_size=#p.member_list;p.leader_guid=t and t:leader().guid or -1
    if recipient then w:send2client(recipient,p)else
        -- Snapshot recipients before sending; a disconnect must not skip the next member.
        for _,m in ipairs(p.member_list)do if m.agent then skynet.send(m.agent,'lua','send2client',p.xy_id,p)end end
    end
end
local function remember(w,kind,from,to,t)
    w.cys_party_pending=w.cys_party_pending or {}
    local q=w.cys_party_pending;local now=skynet.now()
    for k,v in pairs(q)do if v.expires<now then q[k]=nil end end
    q[kind..':'..from.uinfo.guid..':'..to.uinfo.guid]={a=from,b=to,team=t,expires=now+6000}
end
local function take(w,kind,from,to,t)
    local q=w.cys_party_pending or {};local k=kind..':'..from.uinfo.guid..':'..to.uinfo.guid
    local v=q[k];q[k]=nil
    return v and v.a==from and v.b==to and v.team==t and v.expires>=skynet.now()
end
local function invite(w,a,b)
    local t=team(w,a)
    if team(w,b)then return err(w,a,0)end
    if t and (not t:leader()or t:leader().guid~=a.uinfo.guid)then return err(w,a,14)end
    if t and t:is_full()then return err(w,a,2)end
    local p=packet.GCTeamAskInvite.new();p.guid=a.uinfo.guid;p.nickname=a.uinfo.name
    w:create_invite_info(p,t and t:get_members() or {a.uinfo})
    remember(w,'invite',a,b,t);w:send2client(b,p)
end
function M.install(C)
    local oldInvite,oldApply,oldInfo=C.char_invite_team,C.char_team_apply,C.char_ask_team_info
    function C:char_invite_team(guid,r)
        local a=user(self,guid);if not a then return end
        local b=self:find_user_by_name(r.dest_name);if not b then return err(self,a,20)end
        if raid(a)or raid(b)then return oldInvite(self,guid,r)end
        if a==b then
            if team(self,a)then return err(self,a,0)end
            local id=self.team_list:create_team();local t=self.team_list:get_team(id);if not t then return end
            t:add_member(a.uinfo,true);return list(self,t)
        end
        local ta,tb=team(self,a),team(self,b)
        local ok,info=pcall(skynet.call,b.uinfo.agent,'lua','get_player_info')
        if not ok or user(self,guid)~=a or user(self,b.uinfo.guid)~=b then return err(self,a,20)end
        if ta~=team(self,a)or tb~=team(self,b)then return err(self,a,16)end
        if info and ((info.game_flags or 0)&8)~=0 then return err(self,a,19)end
        if tb then return err(self,a,0)end
        if ta and ta:leader().guid~=guid then
            local leader=user(self,ta:leader().guid);if not leader then return err(self,a,20)end
            local p=packet.GCTeamLeaderAskInvite.new();p.source_guid=guid;p.dest_guid=b.uinfo.guid;p.source_name=a.uinfo.name;p.dest_name=b.uinfo.name
            remember(self,'member',a,b,ta);return self:send2client(leader,p)
        end
        return invite(self,a,b)
    end
    function C:char_leader_ret_invite(guid,r)
        local leader=user(self,guid);local a=user(self,r.source_guid);local b=user(self,r.dest_guid);local t=team(self,leader)
        if not leader or not a or not b then return err(self,leader,20)end
        if not t or t:leader().guid~=guid or team(self,a)~=t or not take(self,'member',a,b,t)then return err(self,leader,16)end
        if r.return_type~=1 then return err(self,a,3)end
        return self:char_invite_team(guid,{dest_name=b.uinfo.name})
    end
    function C:char_ret_invite(guid,r)
        local a=user(self,r.guid);local b=user(self,guid)
        if not a or not b then return err(self,b,20)end
        local t=team(self,a)
        if not take(self,'invite',a,b,t)or (t and t:leader().guid~=a.uinfo.guid)then return err(self,b,16)end
        if r.return_type~=1 then return err(self,a,1)end
        if team(self,b)or raid(a)or raid(b)then return err(self,b,0)end
        if t and t:is_full()then return err(self,b,2)end
        if not t then local id=self.team_list:create_team();t=self.team_list:get_team(id);if not t then return end;t:add_member(a.uinfo,true)end
        t:add_member(b.uinfo,true);list(self,t)
    end
    function C:char_team_apply(guid,r)
        local a=user(self,guid);if not a then return end
        local b=self:find_user_by_name(r.dest_name);if not b then return err(self,a,20)end
        if raid(a)or raid(b)then return oldApply(self,guid,r)end
        if team(self,a)then return err(self,a,17)end
        local t=team(self,b);if not t then return err(self,a,7)end
        if t:is_full()then return err(self,a,9)end
        b=user(self,t:leader().guid);if not b then return err(self,a,20)end
        local p=packet.GCTeamAskApply.new();p.source_guid=guid;p.dest_guid=b.uinfo.guid;p.source_name=a.uinfo.name;p.dest_name=b.uinfo.name;p.uinfo=table.clone(a.uinfo);p.uinfo.detail_flag=0
        remember(self,'apply',a,b,t);self:send2client(b,p)
    end
    function C:char_ret_team_apply(guid,r)
        local b=user(self,guid);local a=user(self,r.source_guid);local t=team(self,b)
        if not a or not b then return err(self,b,20)end
        if not t or t:leader().guid~=guid or not take(self,'apply',a,b,t)then return err(self,b,10)end
        if r.return_type~=1 then return err(self,a,8)end
        if team(self,a)or raid(a)then return err(self,b,6)end
        if t:is_full()then return err(self,b,9)end
        t:add_member(a.uinfo,true);list(self,t)
    end
    function C:char_dismiss_team(guid)
        local a=user(self,guid);local t=team(self,a);if not t then return err(self,a,11)end
        if t:leader().guid~=guid then return err(self,a,4)end
        local members={};for _,m in ipairs(t:get_members())do members[#members+1]=m.guid end
        self.team_list:destory_team(t:get_team_id())
        self:notify_stop_team_follow(members)
        for _,id in ipairs(members)do local u=user(self,id);if u then list(self,nil,u)end end
    end
    function C:char_team_kick(guid,r)
        local a=user(self,guid);local b=user(self,r.dest_guid);local t=team(self,a)
        if not t or t:leader().guid~=guid then return err(self,a,5)end
        if not b or team(self,b)~=t or a==b then return err(self,a,12)end
        t:del_member(b.uinfo);self:notify_stop_team_follow({b.uinfo.guid});list(self,nil,b);list(self,t)
    end
    function C:char_team_appoint(guid,r)
        local a=user(self,guid);local b=user(self,r.dest_guid);local t=team(self,a)
        if not t or t:leader().guid~=guid then return err(self,a,14)end
        if not b or team(self,b)~=t then return err(self,a,13)end
        t:appoint(b.uinfo);t:clear_followed_members();local ids={};for _,m in ipairs(t:get_members())do ids[#ids+1]=m.guid end
        self:notify_stop_team_follow(ids);list(self,t)
    end
    function C:char_team_change_option(guid,r)
        local a=user(self,guid);local t=team(self,a)
        if not t or t:leader().guid~=guid then return err(self,a,14)end
        if r.exp_mode~=0 and r.exp_mode~=1 then return end
        t:set_option(r);list(self,t)
    end
    function C:ask_team_member_info(guid,r)
        local t=team(self,user(self,guid));return t and t:get_member_by_guid(r.guid)
    end
    function C:char_ask_team_info(guid)
        local a=user(self,guid);if not a then return end
        if raid(a)then return oldInfo(self,guid)end
        list(self,team(self,a),a)
    end
    return C
end
return M
