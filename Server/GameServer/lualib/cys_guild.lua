-- Core CY guild operations; the existing guild/city/league model remains authoritative.
local skynet=require 'skynet'
local packet=require 'game.packet'
local define=require 'define'
local M={}
local function error_packet(agent,code)
    local p=packet.GCGuildError.new();p.error_code=code or -64;agent:send2client(p)
end
local function human(a,method,...)return skynet.call(a.my_scene,'lua','call_human_function',a.my_obj_id,method,...)end
local function valid_text(s,max)return type(s)=='string'and #s>0 and #s<=max and not s:find('[%z\1-\31]')end
local function valid_desc(s)return type(s)=='string'and #s>0 and #s<=60 and not s:find('[%z\1-\8\11\12\14-\31]')end
local function find(g,id)for _,u in ipairs(g and g.users or {})do if u.guid==id then return u end end end
local function positions(p)return p==1 and 0 or p==9 and 0x7f or (p==8 or p==7)and 0x8d or 0xc0 end
function M.installHuman(C)
    function C:cys_guild_title(id,name,position)
        if id>=0 then return self:set_title(23,string.format('%s%s',name,define.GUILD_POISTION_NAME[position or 2]or ''))end
        for i=#self.titles,1,-1 do if self.titles[i].id==23 then table.remove(self.titles,i)end end
        if (self:get_current_title()or {}).id==23 then self:set_current_title({id=0,str=''})end
        self.db:mark_all_attr_dirty();self:update_titles_to_client();return true
    end
    function C:cys_guild_apply(r)
        if self.cys_guild_busy then return {flag=-1}end
        if type(r.desc)=='string'then r.desc=r.desc:gsub('%s+$','')end
        if not valid_text(r.name,24)or not valid_desc(r.desc)then
            skynet.error('CYS guild invalid create text',type(r.name),type(r.name)=='string'and #r.name or -1,type(r.desc),type(r.desc)=='string'and #r.desc or -1)
            return {flag=-2}
        end
        if self:get_guild_id()~=-1 then return {flag=-7}end
        if self:get_level()<40 or self:get_money()<500000 then
            return {flag=-1}
        end
        self.cys_guild_busy=true
        -- Reserve before the RPC yields; another purchase cannot spend the same balance.
        self:cost_money(500000)
        local info={guid=self:get_guid(),name=self:get_name(),level=self:get_level(),menpai=self:get_menpai(),position=9,access=0x7f,cur_contribute=0,max_contribute=0,week_contribute=0,is_online=1,join_time=tonumber(os.date('%y%m%d%H%M')),logout_time=0}
        r.chief_name=info.name;r.cys_chief=info
        local ok,result=pcall(skynet.call,'.Guildmanager','lua','guild_apply',self:get_guid(),r)
        if not ok then
            -- Resolve a lost reply by its unique chief before deciding whether to refund.
            local recovered,g=pcall(skynet.call,'.Guildmanager','lua','cys_guild_by_chief',self:get_guid(),r.name)
            if not recovered then self.cys_guild_busy=false;error(result)end
            result=g and {flag=0,id=g.id,name=g.name,confederate_id=g.confederate_id,confederate_name=g.confederate_name}or {flag=-64}
        end
        if not result or result.flag~=0 then
            self:set_money(self:get_money()+500000);self.cys_guild_busy=false;return result or {flag=-64}
        end
        self:set_guild_id(result.id);self:set_guild_name(result.name);self:set_confederate_id(result.confederate_id or -1);self:set_confederate_name(result.confederate_name or '')
        self:set_title(23,string.format('#-08 %s帮主',result.name));self:update_titles_to_client()
        self.cys_guild_busy=false;return result
    end
    return C
end
function M.installAgent(C)
    local original=C.CGGuild
    function C:CGGuildApply(r)
        local result=human(self,'cys_guild_apply',r)
        if not result or result.flag~=0 then return error_packet(self,result and result.flag)end
        self:set_guild_id(result.id)
        local p=packet.GCGuildReturn.new();p.return_type=0;p.id=result.id;p.confederate_id=result.confederate_id or -1;p.name=result.name;self:send2client(p)
    end
    function C:insert_my_guild_uinfo(id,position)
        local u=self:get_guild_uinfo();u.position=position;u.cur_contribute=0;u.max_contribute=0;u.week_contribute=0;u.join_time=tonumber(os.date('%y%m%d%H%M'));u.logout_time=0;u.is_online=1;u.access=positions(position)
        local ok,code=skynet.call('.Guildmanager','lua','insert_guild_uinfo',id,u)
        if not ok then error_packet(self,code)end
        return ok
    end
    function C:CGGuildJoin(r)
        if human(self,'get_guild_id')~=-1 then return error_packet(self,-7)end
        if human(self,'get_level')<10 then return error_packet(self,-1)end
        if not self:insert_my_guild_uinfo(r.guild_id,1)then return end
        local g=skynet.call('.Guildmanager','lua','ask_guild_info',{guild_id=r.guild_id})
        if not g then return error_packet(self,-8)end
        local p=packet.GCGuildReturn.new();p.return_type=2;p.id=g.id;p.confederate_id=g.confederate_id or -1;p.name=g.name;self:send2client(p)
        skynet.send('.Guildmanager','lua','on_new_prepare',g.id)
    end
    function C:CGGuild(r)
        if r.packet_type==0 then
            local all=skynet.call('.Guildmanager','lua','get_guild_list');table.sort(all,function(a,b)return a.id<b.id end)
            local p=packet.GCGuild.new();p.packet_type=57;p.askid=(r.askid or 0)+1;p.start_index=math.min(r.askid or 0,32767);p.guild_count=#all;p.guild_list={}
            for _,g in ipairs(all)do if g.id>=p.start_index and #p.guild_list<20 then p.guild_list[#p.guild_list+1]=g end end
            self:send2client(p);return
        end
        r.askid=r.askid or 0
        local id=human(self,'get_guild_id')or -1
        if r.packet_type==3 and (r.type==5 or r.type==6)then return original(self,r)end
        if id<0 then return error_packet(self,-7)end
        if r.packet_type==3 or r.packet_type==21 then return original(self,r)end
        local methods={[4]='guild_appoint',[6]='guild_recruit',[7]='guild_exp',[10]='guild_leave',[12]='guild_demise',[13]='guild_new_desc'}
        local method=methods[r.packet_type];if not method then return error_packet(self,-9)end
        r.guild_id=id
        local result,code=skynet.call('.Guildmanager','lua',method,self:get_guid(),r)
        if not result then return error_packet(self,code or -9)end
        if r.packet_type==13 then
            self:get_guild_member_list(r,id);return
        end
        local p=packet.GCGuildReturn.new();p.askid=r.askid+1;p.guild_id=id
        for k,v in pairs(result)do p[k]=v end
        if r.packet_type==4 then p.return_type=3
        elseif r.packet_type==6 then p.return_type=7;p.guid=r.m_ProposerGUID
        elseif r.packet_type==7 then p.return_type=result.return_type;p.guid=r.m_GuildUserGUID
        elseif r.packet_type==10 then p.return_type=12;p.guid=self:get_guid()
        elseif r.packet_type==12 then p.return_type=9 end
        skynet.send('.Guildmanager','lua','multicast',id,p.xy_id,p)
        -- The former member may have already unsubscribed from the guild channel.
        if r.packet_type==7 then self:send_world('lua','send_to_online_user_by_guid',p.guid,p.xy_id,p)end
        self:send2client(p)
    end
    local oldInfo=C.on_guild_info
    function C:on_guild_info(g,id)
        if not g or not find(g,self:get_guid())then return end
        return oldInfo(self,g,id)
    end
    function C:on_user_guild_recruit_or_guild_expe_or_guild_leave(u)
        self:set_guild_id(u.guild_id);self:set_guild_name(u.guild_name);self:set_confederate_id(u.confederate_id or -1);self:set_confederate_name(u.confederate_name or '')
        human(self,'cys_guild_title',u.guild_id,u.guild_name,u.position or 2)
        human(self,'update_titles_to_client')
        return true
    end
    return C
end
function M.installManager(C)
    local queue=require 'skynet.queue'
    local locked=queue()
    function C:have_guild(guid)
        for _,g in ipairs(self.guilds)do for _,u in ipairs(g.users or {})do if u.guid==guid and u.position>1 then return true end end end
        return false
    end
    function C:guild_name_duplicated(r)
        for _,g in ipairs(self.guilds)do if g.name==r.name then return true end end
        return false
    end
    local oldApply=C.guild_apply
    function C:cys_guild_by_chief(guid,name)
        for _,g in ipairs(self.guilds)do if g.chief_guid==guid and g.name==name then return g end end
    end
    function C:guild_apply(guid,r)
        if not valid_text(r.name,24)or not valid_desc(r.desc)or not r.cys_chief or r.cys_chief.guid~=guid then
            skynet.error('CYS guild invalid chief snapshot',guid,r.cys_chief and r.cys_chief.guid,type(r.name),type(r.desc));return {flag=-2}
        end
        return oldApply(self,guid,r)
    end
    function C:create_guild(guid,r)
        local id=0;for _,g in ipairs(self.guilds)do id=math.max(id,g.id+1)end
        if id>32767 then error('Guild ID capacity exceeded')end
        local g={id=id,chief_guid=guid,chief_name=r.chief_name,creator=r.chief_name,name=r.name,desc=r.desc,confederate_id=-1,confederate_name='',city_name='',port_scene_id=-1,status=1,level=1,founded_time=tonumber(os.date('%y%m%d%H%M')),prosperity=0,founded_money=10000000,users={r.cys_chief}}
        skynet.call('.db','lua','safe_insert',{collection='guild',doc=g})
        self:reload_guilds();self:remake_name_list();return self:get_guild_by_id(id)
    end
    function C:find_user_in_guild_by_guid(guid,g)return find(g,guid)end
    local oldInsert=C.insert_guild_uinfo
    function C:insert_guild_uinfo(id,u)
        local g=self:get_guild_by_id(id);if not g then return false,-8 end
        local existing=find(g,u.guid);if existing then return false,existing.position==1 and -18 or -7 end
        if self:have_guild(u.guid)then return false,-7 end
        -- CGGuildJoin is only an application; it cannot manufacture a chief.
        if u.position~=1 then return false,-9 end
        return oldInsert(self,id,u)
    end
    function C:db_get_guild_id(u)
        local d=skynet.call('.char_db','lua','findOne',{collection='character',query={['attrib.guid']=u.guid},selector={['attrib.guild_id']=1}})
        return d and d.attrib and d.attrib.guild_id or -1
    end
    function C:db_update_user_title(u,g)
        local q={['attrib.guid']=u.guid}
        local d=skynet.call('.char_db','lua','findOne',{collection='character',query=q,selector={titles=1,['attrib.title']=1}})
        if not d then return end
        local titles={};for _,t in ipairs(d.titles or {})do if t.id~=23 then titles[#titles+1]=t end end
        local text=g.id<0 and ''or string.format('%s%s',g.name,define.GUILD_POISTION_NAME[u.position]or '')
        if g.id>=0 then if u.position==9 then text='#-08 '..text end;titles[#titles+1]={id=23,str=text}end
        local changes={titles=titles};if d.attrib and d.attrib.title and d.attrib.title.id==23 then changes['attrib.title']={id=g.id<0 and 0 or 23,str=text}end
        skynet.call('.char_db','lua','update',{collection='character',selector=q,update={['$set']=changes},upsert=false,multi=false})
    end
    local oldRecruit,oldExp,oldLeave,oldAppoint,oldDemise=C.guild_recruit,C.guild_exp,C.guild_leave,C.guild_appoint,C.guild_demise
    local function validate(self,guid,r,right,target)
        local g=self:get_guild_by_id(r.guild_id);if not g then return nil,nil,nil,-8 end
        local a=find(g,guid);if not a then return nil,nil,nil,-14 end
        if ((a.access or 0)&right)~=right then return nil,nil,nil,-9 end
        local b=target and find(g,target)or nil;if target and not b then return nil,nil,nil,-14 end
        return g,a,b
    end
    function C:guild_recruit(guid,r)
        local g,a,b,e=validate(self,guid,r,4,r.m_ProposerGUID);if not g then return false,e end
        if b.position~=1 then return false,-13 end
        local n=0;for _,m in ipairs(g.users)do if m.position>1 then n=n+1 end end;if n>=200 then return false,-5 end
        if self:have_guild(b.guid)then return false,-7 end
        return oldRecruit(self,guid,r)
    end
    function C:guild_exp(guid,r)
        local g,a,b,e=validate(self,guid,r,8,r.m_GuildUserGUID);if not g then return false,e end
        if guid==b.guid or b.position>=a.position then return false,-9 end
        return oldExp(self,guid,r)
    end
    function C:guild_leave(guid,r)
        local g,a,b,e=validate(self,guid,r,128);if not g then return false,e end
        return oldLeave(self,guid,r)
    end
    function C:guild_appoint(guid,r)
        local g,a,b,e=validate(self,guid,r,1,r.guid);if not g then return false,e end
        if a.position~=9 and a.position~=8 then return false,-9 end
        if b.position<2 or b.position>=a.position or r.new_position<2 or r.new_position>=a.position then return false,-9 end
        if r.new_position==8 then for _,m in ipairs(g.users)do if m.position==8 and m.guid~=b.guid then return false,-17 end end end
        return oldAppoint(self,guid,r)
    end
    function C:guild_demise(guid,r)
        local g,a,b,e=validate(self,guid,r,16);if not g then return false,e end
        if a.position~=9 then return false,-9 end
        if not self:find_ass_cheif_in_guild(g)then return false,-15 end
        local result=oldDemise(self,guid,r)
        if result then
            g.chief_guid=result.dest_guid;g.chief_name=result.dest_name
            self:db_update_guild_attr(g,'chief_guid',g.chief_guid);self:db_update_guild_attr(g,'chief_name',g.chief_name)
        end
        return result
    end
    function C:guild_new_desc(guid,r)
        local g=self:get_guild_by_id(r.guild_id);local a=find(g,guid)
        if not g then return false,-8 end;if not a or a.position~=9 then return false,-9 end
        if type(r.new_desc)=='string'then r.new_desc=r.new_desc:gsub('%s+$','')end
        if not valid_desc(r.new_desc)then return false,-2 end
        self:db_update_guild_desc(g,r.new_desc);g.desc=r.new_desc
        self:multicast(g.id,-1,'on_guild_info_update',g);return true
    end
    -- Serialize membership/role changes across database and world RPC yields.
    -- Read-only guild info remains callable from the notified msgagent.
    for _,name in ipairs{'guild_apply','insert_guild_uinfo','guild_recruit','guild_exp','guild_leave','guild_appoint','guild_demise','guild_new_desc'}do
        local f=C[name];C[name]=function(self,...)return locked(f,self,...)end
    end
    return C
end
return M
