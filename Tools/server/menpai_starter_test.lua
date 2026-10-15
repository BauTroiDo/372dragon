-- Run real join/EndAddItem code and real private-server tables in an offline scene.
local root, overlay = assert(arg[1]), assert(arg[2])
package.path = overlay..'/GameServer/lualib/?.lua;'..root..'/GameServer/lualib/?.lua;'..root..'/GameServer/services/?.lua;'..root..'/Game_2/Script/?.lua;'..package.path
package.cpath = root..'/GameServer/luaclib/?.so;'..package.cpath
local quiet=function() end
package.preload['skynet']=function() return {getenv=function(k) if k=='config_path' then return root..'/configs/%s' end end,logd=quiet,logi=quiet,logw=quiet,loge=quiet} end
package.preload['skynet.manager']=function() return {} end
package.preload['skynet.sharetable']=function() return {} end
table.tostr=table.tostr or function() return '' end
table.clone=table.clone or function(t) if type(t)~='table' then return t end;local c={};for k,v in pairs(t) do c[k]=table.clone(v) end;return c end
local cfg=require('cfghelper').new()
local cache={}
local engine={get_config=function(_,name)
    if not cache[name] then cfg['read_'..name](cfg);cache[name]=cfg['get_'..name](cfg) end
    return cache[name]
end}
local skills=engine:get_config('skill_template')
local define=require 'define'
local base={}
local file=assert(io.open(overlay..'/GameServer/lualib/script_base.lua','rb'))
local source=file:read('*a');file:close()
local env=setmetatable({script_base=base,define=define,menpai_registry=require 'menpai_registry',configenginer=engine,
    skynet=require 'skynet',packet_def=setmetatable({}, {__index=function() return {new=function() return {} end} end}),
    skillenginer={get_skill_templates=function() return skills end,get_skill_template=function(_,id) return skills[id] end}}, {__index=_G})
for _,name in ipairs({'LuaFnJoinMenpai','BeginAddItem','AddItem','EndAddItem','AddItemListToHuman'}) do
    local start=assert(source:find('function script_base:'..name..'(',1,true))
    local stop=source:find('\nfunction ',start+1,true) or #source+1
    assert(load(source:sub(start,stop-1), '@actual-script_base:'..name, 't', env))()
end
local weapons=require('menpai_starter').weapons
local function fixture(space,queued)
    local h={menpai=9,skills={0,1,2,3,21,22,34,35,43},xinfa={},items={},space=space,changes=0}
    function h:get_menpai() return self.menpai end
    function h:get_skill_list() return self.skills end
    function h:set_menpai(id) self.menpai=id;self.changes=self.changes+1;return true end
    function h:clear_xinfa_list() self.xinfa={} end
    function h:get_xinfa_list() return self.xinfa end
    function h:clear_menpai_skills() self.skills={0,1,2,3,21,22,34,35,43} end
    function h:add_skill(id) for _,v in ipairs(self.skills) do if v==id then return end end; table.insert(self.skills,id) end
    function h:get_attrib() return 100 end
    function h:get_obj_id() return 1 end
    function h:get_guid() return 200016 end
    function h:get_xinfa(id) for _,v in ipairs(self.xinfa) do if v.m_nXinFaID==id then return v end end end
    function h:get_empty_setting() return nil end
    for _,fn in ipairs({'change_menpai_points','send_refresh_attrib','set_hp','set_mp','send_setting','notify_tips'}) do h[fn]=quiet end
    function h:get_prop_bag()
        return {ipairs=function(_,bag)
            local i=0
            return function() i=i+1;if i<=((bag=='prop') and h.space or 30) then return i,nil end end
        end}
    end
    local script=setmetatable({add_item_list=queued or {},scene={objs={[1]=h},get_obj_by_id=function() return h end,send2client=quiet}}, {__index=base})
    function script:TryRecieveItemWithCount(_,id,count,bind)
        assert(h.space>=1);h.space=h.space-1;table.insert(h.items,{id=id,count=count,bind=bind});return #h.items
    end
    return script,h
end
local n=0
for sect=0,15 do if weapons[sect] then
    local equip=assert(engine:get_config('equip_base')[weapons[sect]])
    assert(equip.level==10 and equip.equip_point==0 and equip.visual>0,'must be usable combat equipment')
    local s,h=fixture(3,{{item_index=10124004,count=1},{item_index=30501001,count=20,is_bind=true}})
    assert(s:LuaFnJoinMenpai(1,sect));assert(h.menpai==sect and #h.xinfa==6 and #h.skills>9)
    assert(#h.items==3 and h.items[3].id==weapons[sect] and h.items[3].bind and #s.add_item_list==0)
    s:AddItemListToHuman(1);assert(#h.items==3,'legacy NPC must not duplicate gifts')
    assert(not s:LuaFnJoinMenpai(1,sect));assert(#h.items==3 and h.changes==1,'repeat request')
    local full,fh=fixture(2,{{item_index=10124004,count=1},{item_index=30501001,count=20,is_bind=true}})
    local ok,reason=full:LuaFnJoinMenpai(1,sect)
    assert(not ok and reason=='starter_bag_full' and fh.menpai==9 and fh.changes==0 and #fh.items==0 and #fh.xinfa==0)
    local fresh,nh=fixture(1)
    assert(fresh:LuaFnJoinMenpai(1,sect));assert(#nh.items==1 and nh.items[1].id==weapons[sect])
    n=n+1;print('PASS sect='..sect..' weapon='..weapons[sect]..' full-bag/refusal/repeat/legacy-batch/first-join')
end end
assert(n==15)
local s,h=fixture(10);assert(not s:LuaFnJoinMenpai(1,16));assert(h.changes==0 and #h.items==0)
print('PASS 15 factions; disabled faction refused; actual join + EndAddItem, real configs')
