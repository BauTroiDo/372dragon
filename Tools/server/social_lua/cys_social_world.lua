-- Raid membership uses the existing five squads of six and existing CY packets.
-- Validate and commit the roster before sending messages; no RPC in the commit.
local skynet=require 'skynet'
local packet=require 'game.packet'
local define=require 'define'
local M={}
local function actor(w,id)return w:find_user(id)end
local function raid(w,u)return u and w.raid_list:get_raid(u.uinfo.raid_id or -1)end
local function member(r,id)return r and r:get_member_by_guid(id)end
local function error_to(w,u,key)
    if not u then return end
    local p=packet.GCRaidError.new();p.error_code=define.RAID_ERROR[key] or define.RAID_ERROR.RAID_ERROR_NOT_IN_RAID
    w:send2client(u,p)
end
local function roster(w,r,recipient,event)
    local p=packet.GCRaidList.new();p.m_nEventID=event or 2;p.m_TeamID=-1
    p.m_RaidID=r and r:get_raid_id() or -1;p.m_bLeaveRaid=r and 0 or 1
    p.member_list=table.clone(r and r:get_members() or {{},{},{},{},{}})
    p.m_nMemberCount=r and r:member_count() or 0
    if recipient then w:send2client(recipient,p)else
        for _,t in ipairs(p.member_list)do for _,m in ipairs(t)do
            local u=actor(w,m.guid);if u then w:send2client(u,p)end
        end end
    end
end
local function officer(r,u)
    local m=u and member(r,u.uinfo.guid)
    return m and (m.m_Position==0 or m.m_Position==1)
end
local function free(u)
    return u and (u.uinfo.raid_id or -1)==-1 and (u.uinfo.team_id or -1)==-1
end
local function ticket(w,kind,chief,other,r,consume)
    w.cys_raid_pending=w.cys_raid_pending or {}
    local all=w.cys_raid_pending;local now=skynet.now()
    for k,v in pairs(all)do if v.expires<now then all[k]=nil end end
    local k=kind..':'..chief.uinfo.guid..':'..other.uinfo.guid
    if consume then
        local v=all[k];all[k]=nil
        return v and v.chief==chief and v.other==other and v.raid==r and v.expires>=now
    end
    all[k]={chief=chief,other=other,raid=r,expires=now+6000}
end
local function join(w,r,u)
    if not free(u)then return error_to(w,u,'RAID_ERROR_TARGET_IN_OTHERRAID')end
    if r:is_full()then return error_to(w,u,'RAID_ERROR_FULL')end
    local t
    for _,s in ipairs(r.members)do if #s<6 then t=s;break end end
    if not t then return error_to(w,u,'RAID_ERROR_FULL')end
    local m=u.uinfo;m.raid_id=r:get_raid_id();m.m_Position=2
    m.m_ZoneWorldID=w.server_id or 0;m.m_iFightScore=m.m_iFightScore or 0;m.GuildName=m.GuildName or ''
    t[#t+1]=m;roster(w,r)
end
local function remove(w,r,u)
    if not member(r,u.uinfo.guid)then return end
    local wasLeader=u.uinfo.m_Position==0
    r:del_member(u.uinfo.guid);u.uinfo.raid_id=-1;u.uinfo.m_Position=2
    if wasLeader and not r:is_empty()then
        local successor=r:leader(1)
        if not successor then for _,t in ipairs(r.members)do if t[1]then successor=t[1];break end end end
        successor.m_Position=0
    end
    roster(w,nil,u)
    if r:is_empty()then w.raid_list:destory_raid(r:get_raid_id())else roster(w,r)end
end
function M.install(C)
    function C:char_create_raids(request)
        local u=actor(self,request.m_CreateGUID);if not u then return end
        if (u.uinfo.raid_id or -1)~=-1 then return error_to(self,u,'RAID_ERROR_INVITEDHASINRAID')end
        local t=self.team_list:get_team(u.uinfo.team_id or -1)
        if not t or not t:leader()or t:leader().guid~=u.uinfo.guid or request.m_CreateTeamId~=t:get_team_id()then
            return error_to(self,u,'RAID_ERROR_NOT_LEADER')
        end
        local members={}
        for _,m in ipairs(t:get_members())do
            if (m.raid_id or -1)~=-1 then return error_to(self,u,'RAID_ERROR_TARGET_IN_OTHERRAID')end
            members[#members+1]=m
        end
        if #members<1 or #members>6 then return end
        local id=self.raid_list:create_raid();if not id then return error_to(self,u,'RAID_ERROR_FULL')end
        local r=self.raid_list:get_raid(id);r.members={members,{},{},{},{}}
        for _,m in ipairs(members)do
            m.raid_id=id;m.m_Position=m.guid==u.uinfo.guid and 0 or 2
            m.m_ZoneWorldID=self.server_id or 0;m.m_iFightScore=m.m_iFightScore or 0;m.GuildName=m.GuildName or ''
        end
        self:char_dismiss_team(u.uinfo.guid)
        roster(self,r,nil,0)
    end
    function C:char_invite_raid(request)
        local u=actor(self,request.m_SourObjID);local r=raid(self,u)
        if not officer(r,u)then return error_to(self,u,'RAID_ERROR_NOT_LEADER')end
        local dest=self:find_user_by_name(request.m_DestName)
        if not dest or dest.status=='offline'then return error_to(self,u,'RAID_ERROR_INVITEDTARGETNOTONLINE')end
        if not free(dest)then return error_to(self,u,'RAID_ERROR_TARGET_IN_OTHERRAID')end
        if r:is_full()then return error_to(self,u,'RAID_ERROR_FULL_CANTINVITE')end
        local chief=r:leader(0);chief=chief and actor(self,chief.guid)
        if not chief then return error_to(self,u,'RAID_ERROR_RAID_NOTEXIST_OR_LEADEROUT')end
        ticket(self,'invite',chief,dest,r)
        local p=packet.GCRaidAskInvite.new();p.guid=chief.uinfo.guid;p.nickname=chief.uinfo.name
        p.m_ZoneWorldID=self.server_id or 0;p.m_uLeaderLevel=chief.uinfo.level or 0
        self:send2client(dest,p)
    end
    function C:char_ret_raid_invite(guid,request)
        local u=actor(self,guid);local chief=actor(self,request.m_GUID);local r=raid(self,chief)
        if not u or not chief or not r or chief.uinfo.m_Position~=0 or not ticket(self,'invite',chief,u,r,true)then
            return error_to(self,u,'RAID_ERROR_ADDMEMFAILED_INVITEERR')
        end
        if request.m_Return~=1 then return error_to(self,chief,'RAID_ERROR_INVITEREFUSE')end
        join(self,r,u)
    end
    function C:char_apply_raid(request)
        local u=actor(self,request.m_SourGUID);local dest=self:find_user_by_name(request.m_DestName)
        local r=raid(self,dest)
        if not u or not r then return error_to(self,u,'RAID_ERROR_NOT_IN_RAID')end
        if not free(u)then return error_to(self,u,'RAID_ERROR_TARGET_IN_OTHERRAID')end
        if r:is_full()then return error_to(self,u,'RAID_ERROR_FULL_CANTAPPLY')end
        local chief=r:leader(0);chief=chief and actor(self,chief.guid)
        if not chief then return error_to(self,u,'RAID_ERROR_RAID_NOTEXIST_OR_LEADEROUT')end
        ticket(self,'apply',chief,u,r)
        local p=packet.GCRaidAskApply.new();p.m_SourGUID=u.uinfo.guid;p.SourceName=u.uinfo.name
        p.m_uFamily=u.uinfo.menpai;p.sceneid=u.uinfo.sceneid;p.m_Level=u.uinfo.level;p.m_DetailFlag=0
        p.m_uDataID=u.uinfo.model or 0;p.m_ZoneWorldID=self.server_id or 0;p.m_iFightScore=0;p.GuildName=''
        self:send2client(chief,p)
    end
    function C:char_ret_raid_apply(guid,request)
        local chief=actor(self,guid);local u=actor(self,request.source_guid);local r=raid(self,chief)
        if not u or not chief or not r or chief.uinfo.m_Position~=0 or not ticket(self,'apply',chief,u,r,true)then
            return error_to(self,chief,'RAID_ERROR_ADDMEMFAILED_INVITEERR')
        end
        if request.return_type~=1 then return error_to(self,u,'RAID_ERROR_APPLYLEADERREFUSE')end
        join(self,r,u)
    end
    function C:raid_modify_member_position(request)
        local u=actor(self,request.m_OperateGUID);local r=raid(self,u)
        if not officer(r,u)then return error_to(self,u,'RAID_ERROR_NOT_LEADER')end
        local a,b,c,d=request.m_sSquadIndex,request.m_sMemIndex,request.m_dSquadIndex,request.m_dMemIndex
        for i,n in ipairs{a,b,c,d}do if type(n)~='number'or n%1~=0 or n<0 or n>((i==1 or i==3)and 4 or 5)then return end end
        if a==nil or b==nil or c==nil or d==nil then return end
        local src,dst=r.members[a+1],r.members[c+1]
        if not src or not dst or not src[b+1]then return end
        if dst[d+1]then src[b+1],dst[d+1]=dst[d+1],src[b+1]
        else if #dst>=6 then return error_to(self,u,'RAID_ERROR_FULL')end;local moved=table.remove(src,b+1);table.insert(dst,moved)end
        roster(self,r)
    end
    function C:char_raid_appoint(request)
        local u=actor(self,request.m_OperateGUID);local r=raid(self,u)
        local m=u and member(r,u.uinfo.guid);local target=member(r,request.m_TargetGUID)
        if not m or m.m_Position~=0 or not target or m==target then return error_to(self,u,'RAID_ERROR_NOT_LEADER')end
        local pos=request.m_Position
        if pos~=0 and pos~=1 and pos~=2 then return end
        if pos==1 and target.m_Position~=1 then
            local n=0;for _,t in ipairs(r.members)do for _,v in ipairs(t)do if v.m_Position==1 then n=n+1 end end end
            if n>=2 then return error_to(self,u,'RAID_ERROR_APPOINTFULL')end
        end
        if pos==0 then m.m_Position=2 end;target.m_Position=pos;roster(self,r)
    end
    function C:char_raid_kick(request)
        local u=actor(self,request.m_OperateGUID);local r=raid(self,u);local dest=actor(self,request.m_TargetGUID)
        local a=u and member(r,u.uinfo.guid);local b=dest and member(r,dest.uinfo.guid)
        if not officer(r,u)or not b or a==b or a.m_Position>=b.m_Position then return error_to(self,u,'RAID_ERROR_KICKNOTLEADER')end
        remove(self,r,dest)
    end
    function C:char_leave_raid(guid)
        local u=actor(self,guid);local r=raid(self,u);if u and r then remove(self,r,u)end
    end
    local oldInfo=C.char_ask_team_info
    function C:char_ask_team_info(guid,...)
        local u=actor(self,guid);local r=raid(self,u)
        if r then return roster(self,r,u)end
        return oldInfo(self,guid,...)
    end
    return C
end
return M
