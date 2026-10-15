-- The clone speaks CY's relation protocol; mutations are saved to the human
-- actor before acknowledging them. Invalid requests never mutate the lists.
local M = {}
function M.install(agent)
    local skynet = require 'skynet'
    local packet = require 'game.packet'
    local define = require 'define'
    local old = agent.CGRelation
    local function reply(self, kind, key, value)
        local p = packet.GCRelation.new(); p.type = kind
        if key then p[key] = value end
        self:send2client(p)
    end
    local function save(self)
        skynet.call(self.my_scene, 'lua', 'call_human_function', self.my_obj_id,
            'set_relation_list_from_agent', table.clone(self.my_data.relation))
    end
    local function group(list, id)
        if id >= 1 and id <= 4 then return list.friends end
        if id == 5 then return list.black end
        if id == 6 then return list.enemies end
        if id == 7 then return list.temp end
    end
    local function find(list, guid)
        for _, key in ipairs({'friends','black','enemies','temp'}) do
            for i, v in ipairs(list[key]) do
                if v.guid == guid then return v,list[key],i,key end
            end
        end
    end
    local function capacity(list,to)
        local rows=group(list,to); if not rows then return false end
        if to >= 5 then return #rows < 10 end
        local n=0;for _,v in ipairs(rows)do if v.group==to then n=n+1 end end
        return #rows < 80 and n < 20
    end
    local function protected(v)
        return v and v.relation_type ~= 1 and v.relation_type ~= 5 and v.relation_type ~= 4 and v.relation_type ~= 9
    end
    function agent:CGRelation(p)
        if p.type ~= 4 and p.type ~= 5 and p.type ~= 6 and p.type ~= 7 and p.type ~= 8 and p.type ~= 9 and p.type ~= 10 and p.type ~= 23 and p.type ~= 13 then
            return old(self,p)
        end
        local q=p.request_relation_info or {}
        local list=self.my_data.relation
        if not list then return end
        for _,k in ipairs({'friends','black','enemies','temp'})do list[k]=list[k] or {} end
        if p.type==13 then
            if type(q.mood)~='string' or #q.mood>29 then return reply(self,46) end
            list.mood=q.mood;save(self)
            skynet.call(self.my_scene,'lua','call_human_function',self.my_obj_id,'set_mood',q.mood)
            return reply(self,16,'new_mood',{mood=q.mood})
        end
        if p.type==9 or p.type==10 or p.type==23 then
            local v,rows,i=find(list,q.guid)
            if not v or protected(v) then return reply(self,31) end
            table.remove(rows,i);save(self)
            reply(self,10,'del_relation',{guid=q.guid,relation_type=v.relation_type})
            skynet.send('.world','lua','notify_friend_be_del',q.guid,self.my_guid,v.relation_type)
            return
        end
        if p.type==8 then
            local from,to=tonumber(q.from),tonumber(q.to)
            if not from or not to or from%1~=0 or to%1~=0 or to<1 or to>5 or from<1 or from>7 then return reply(self,30) end
            local v,rows,i,key=find(list,q.guid)
            local actual=key=='friends' and v.group or key=='black' and 5 or key=='enemies' and 6 or key=='temp' and 7
            if not v or actual~=from or from==to or (protected(v) and to==5) then return reply(self,30) end
            if not capacity(list,to) then return reply(self,27) end
            local target=group(list,to)
            if rows~=target then table.remove(rows,i);table.insert(target,v);v.friend_point=0 end
            v.group=to;v.relation_type=to==5 and 4 or (protected(v) and v.relation_type or 1)
            save(self);return reply(self,9,'relation_guid_uchar_uchar',{guid=v.guid,relation_type=v.relation_type,group=to})
        end
        local to=(p.type==5 or p.type==7) and 5 or tonumber(q.group)
        if not to or to%1~=0 or to<1 or to>5 then return reply(self,30) end
        local u
        if type(q.name)=='string' and #q.name>0 and #q.name<=29 then
            u=skynet.call('.world','lua','get_player_info_by_name',q.name)
        elseif type(q.guid)=='number' and q.guid>0 then
            u=skynet.call('.world','lua','get_player_info',q.guid)
        end
        if not u or u.guid==self.my_guid then return reply(self,26) end
        local previous=find(list,u.guid)
        if previous then return reply(self,previous.relation_type==4 and 29 or 28) end
        if to<=4 and ((u.game_flags or 0)&1)~=0 then return reply(self,42) end
        if not capacity(list,to) then return reply(self,27) end
        local v={guid=u.guid,name=u.name,mood=u.mood or '',portrait=u.portrait or 0,group=to,relation_type=to==5 and 4 or 1,friend_point=0}
        table.insert(group(list,to),v);save(self)
        local result=table.clone(u);result.group=to;result.relation_type=v.relation_type;result.friend_point=0
        reply(self,to==5 and 6 or 5,'relation_info',result)
        if to<=4 then skynet.send('.world','lua','notify_friend_be_add',u.guid,self.my_guid,1) end
    end
    return agent
end
return M
