-- Actual private-server configs and staged handlers; in-memory actors/transport.
local root,stage=assert(arg[1]),assert(arg[2])
package.path=stage..'/GameServer/lualib/?.lua;'..stage..'/GameServer/services/?.lua;'
    ..root..'/GameServer/lualib/?.lua;'..root..'/GameServer/services/?.lua;'..package.path
package.cpath=root..'/GameServer/luaclib/?.so;'..package.cpath
local quiet=function()end
package.loaded.skynet={getenv=function(k)if k=='config_path'then return (arg[3]or root)..'/configs/%s'end end,logd=quiet,logi=quiet,logw=quiet,loge=quiet,error=quiet,log=quiet}
package.loaded['skynet.manager']={};package.loaded['skynet.sharetable']={};table.tostr=function()return ''end
local reader=require('cfghelper').new();local cache={};local config={}
function config:get_config(k)
    if not cache[k]then local say=print;print=quiet;assert(reader['read_'..k],k)(reader);print=say;cache[k]=reader[k]end
    return assert(cache[k],k)
end
package.loaded.configenginer={getinstance=function()return config end}
local define=require 'define';local R=define.OPERATE_RESULT
local passes,failures=0,0
local function test(n,f)
    local ok,e=xpcall(f,debug.traceback)
    if ok then passes=passes+1 else failures=failures+1;print('FAIL',n,e)end
end
local function eq(a,b)assert(math.abs(a-b)<0.000001,tostring(a)..' ~= '..tostring(b))end
local packets=setmetatable({},{__index=function()return{new=function()return{}end}end})
package.loaded['game.packet']=packets
local generation_hook
local function item(id,count)
    local cfg=config:get_config(id//10000000==1 and 'equip_base' or 'common_item')[id]
    assert(cfg,'item '..id)
    local i={id=id,count=count or 1,bound=false,identified=false}
    function i:get_index()return self.id end
    function i:get_lay_count()return self.count end
    function i:set_lay_count(n)self.count=n end
    function i:is_empty()return self.count==0 end
    function i:is_lock()return self.locked end
    function i:is_bind()return self.bound end
    function i:set_is_bind(b)self.bound=b end
    function i:is_equip()return self.id//10000000==1 end
    function i:is_identd()return self.identified end
    function i:set_is_identd(b)self.identified=b end
    function i:get_serial_type()return math.floor((self.id%100000)/1000) end
    function i:get_serial_quality()return math.floor((self.id%10000000)/100000) end
    function i:get_base_config()if self.config_hook then self.config_hook()end;return cfg end
    function i:get_max_tile_count()return self:is_equip() and 1 or math.min(250,cfg.max_tile_count)end
    function i:get_place_bag()return self.id//10000000==2 and 'material' or 'prop'end
    function i:can_lay()return self:get_max_tile_count()>1 end
    function i:set_item_creator(n)self.creator=n end
    function i:set_item_record_data_forindex(k,v)self[k]=v end
    function i:copy_raw_data()return{id=self.id,count=self.count,bound=self.bound,creator=self.creator}end
    return i
end
local logic={}
function logic:dec_item_lay_count(_,h,p,n,id)
    local i=assert(h.items[p]);assert(i.id==id and i.count>=n and not i.locked)
    i.count=i.count-n;if i.count==0 then h.items[p]=nil end;h.spent=h.spent+n;return true
end
function logic:erase_item_by_bag_index(_,h,p)
    assert(h.items[p]and not h.items[p].locked);h.spent=h.spent+h.items[p].count;h.items[p]=nil;return true
end
function logic:calc_bag_item_count(h,id)local n=0;for _,i in pairs(h.items)do if i.id==id then n=n+i.count end end;return n end
package.loaded.human_item_logic=logic
local factory={}
function factory:gen_item(_,id,way)
    if generation_hook then local fn=generation_hook;generation_hook=nil;fn()end
    local i=item(id);i.way=way;return i
end
function factory:getinstance()return self end
package.loaded.item_operator=factory
local function human()
    local h={items={},sent={},spent=0,vigor=100000,stamina=100000,ability={level=1,exp=0},op={ability_id=4,pres_id=1,mat_bag_index=255},learned=true}
    local bag={get_size=function()return{prop=100,material=100,task=20}end,
        get_item=function(_,p)return h.items[p]end,set_item=function(_,p,i)h.items[p]=i end}
    function bag:ipairs(kind)local p=(kind=='material' and 100 or kind=='task' and 200 or 0)-1;local last=p+(kind=='task' and 20 or 100)
        return function()p=p+1;if p<=last then return p,h.items[p]end end
    end
    function h:get_prop_bag_container()return bag end
    function h:is_alive()return not self.dead end
    function h:get_ability_opera()return self.op end
    function h:get_ability()return self.ability end
    function h:is_prescription_have_learnd()return self.learned end
    function h:get_vigor()return self.vigor end
    function h:set_vigor(v)self.vigor=v end
    function h:get_stamina()return self.stamina end
    function h:set_stamina(v)self.stamina=v end
    function h:is_cool_downed()return not self.cool end
    function h:set_cool_down()self.cool=true end
    function h:set_ability_exp(_,v)self.ability.exp=v end
    function h:get_name()return 'audit' end
    function h:get_menpai()return 0 end
    function h:get_scene()return{send2client=function(_,_,m)self.sent[#self.sent+1]=m end,
        get_impact_enginer=function()return{send_impact_to_unit=function()self.effect=true end}end}end
    return h
end
local identify=require 'cys_identify'
local limits=require 'cys_identify_limits'
local equips=config:get_config('equip_base');local commons=config:get_config('common_item')
local function target(point,level)
    for id,row in pairs(equips)do if row.equip_point==point and row.level<=level and row.class==1 then return id end end
    error('no target '..point..' '..level)
end
for id,maximum in pairs(limits)do
    test('identify '..id,function()
        local typ=math.floor((id%100000)/1000)
        local point=typ==7 and define.HUMAN_EQUIP.HEQUIP_ARMOR or typ==8 and define.HUMAN_EQUIP.HEQUIP_RING_1 or define.HUMAN_EQUIP.HEQUIP_WEAPON
        local h=human();h.items[0]=item(id,2);h.items[1]=item(target(point,maximum))
        assert(identify.use(h,0,1)==define.USEITEM_RESULT.USEITEM_SUCCESS);assert(h.items[1].identified and h.spent==1)
        assert(identify.use(h,0,1)~=0 and h.spent==1,'replay consumed')
    end)
end
for _,case in ipairs({'invalid-slot','locked-scroll','locked-equip','wrong-kind','too-high','identity-race','dead'})do
    test('identify refuses '..case,function()
        local h=human();h.items[0]=item(30506001,2);h.items[1]=item(target(define.HUMAN_EQUIP.HEQUIP_WEAPON,10))
        local p=1
        if case=='invalid-slot'then p=999 elseif case=='locked-scroll'then h.items[0].locked=true
        elseif case=='locked-equip'then h.items[1].locked=true elseif case=='wrong-kind'then h.items[1]=item(target(define.HUMAN_EQUIP.HEQUIP_ARMOR,10))
        elseif case=='too-high'then for id,c in pairs(equips)do if c.equip_point==0 and c.level>10 then h.items[1]=item(id);break end end
        elseif case=='identity-race'then h.items[1].config_hook=function()h.items[0]=item(30506001,2)end
        elseif case=='dead'then h.dead=true end
        assert(identify.use(h,0,p)~=0);assert(h.spent==0)
    end)
end
local recipes=config:get_config('item_compound')
local engine={get_prescription_list=function()return recipes end}
local craft=require 'cys_recipe'
local function crafting()
    local h=human();local row=recipes[1]
    for n=1,5 do local id=row['Stuff'..n..'ID'];if id>0 then h.items[99+n]=item(id,row['Stuff'..n..'num'])end end
    return h,{id=4,abilityenginer=engine},row
end
test('foundry exact materials, authored result, creator, vigor and replay',function()
    local h,a,row=crafting();assert(craft.check(a,h)==R.OR_OK)
    assert(craft.finish(a,h,'foundry')==R.OR_OK)
    assert(h.items[0].id==row.ResultID and h.items[0].creator=='audit')
    assert(h.vigor==100000-row['活力需求']);assert(h.ability.exp==0) -- authored zhuzao cap is 0
    local spent=h.spent;assert(craft.finish(a,h,'foundry')~=R.OR_OK and h.spent==spent)
end)
for _,case in ipairs({'no-material','locked','full','no-vigor','no-level','not-learned','wrong-profession','race-identity','race-count','race-full','reentrant','cancel'})do
    test('craft '..case,function()
        local h,a=crafting();local success=false
        if case=='no-material'then h.items[100]=nil elseif case=='locked'then h.items[100].locked=true
        elseif case=='full'then for p=0,99 do h.items[p]=item(recipes[1].ResultID)end
        elseif case=='no-vigor'then h.vigor=0 elseif case=='no-level'then h.ability.level=0
        elseif case=='not-learned'then h.learned=false elseif case=='wrong-profession'then h.op.ability_id=5
        elseif case=='race-identity'then generation_hook=function()h.items[100]=item(h.items[100].id,h.items[100].count)end
        elseif case=='race-count'then generation_hook=function()h.items[100].count=1 end
        elseif case=='race-full'then generation_hook=function()for p=0,99 do h.items[p]=item(recipes[1].ResultID)end end
        elseif case=='cancel'then generation_hook=function()h.op={ability_id=4,pres_id=1,mat_bag_index=255}end
        elseif case=='reentrant'then success=true;generation_hook=function()assert(craft.finish(a,h,'foundry')~=R.OR_OK)end end
        local v=h.vigor;local result=craft.finish(a,h,'foundry')
        assert((result==R.OR_OK)==success);if not success then assert(h.spent==0 and h.vigor==v)end
    end)
end
-- All four channels use the same resistance semantics, with authored faction traits.
local ordinary_count,ordinary_created,ordinary_blocked=0,0,0
for id,row in pairs(recipes)do
    local aid=row['对应技能ID'];local kind=({[1]='compound',[2]='compound',[4]='foundry',[5]='tailor',[6]='artwork'})[aid]
    local exists=equips[row.ResultID] or commons[row.ResultID]
    local valid=kind and row['脚本ID']==-1 and exists and row.ResultNum>0 and row.ResultNum<=250
        and (row['门派贡献度需求'] or 0)<=0
    for n=1,5 do
        local mat=row['Stuff'..n..'ID']
        if mat>0 and (not (equips[mat]or commons[mat])or row['Stuff'..n..'num']<=0)then valid=false end
    end
    local tool=row['需求工具ID']
    if tool>0 and not(equips[tool]or commons[tool])then valid=false end
    if valid then
        ordinary_count=ordinary_count+1
        test('ordinary recipe census '..id,function()
            local h=human();h.op={ability_id=aid,pres_id=id,mat_bag_index=255}
            h.ability={level=row['技能等级需求（此列最低填1）'],exp=math.max(0,row['熟练度需求'])}
            local need={};for n=1,5 do local mat=row['Stuff'..n..'ID'];if mat>0 then need[mat]=(need[mat]or 0)+row['Stuff'..n..'num']end end
            local seed={};for mat,n in pairs(need)do seed[mat]=n end
            if tool>0 then seed[tool]=(seed[tool]or 0)+1 end
            local position={prop=0,material=100,task=200}
            for mat,n in pairs(seed)do
                while n>0 do local i=item(mat);local region=i:get_place_bag();local take=math.min(n,i:get_max_tile_count());i.count=take
                    h.items[position[region]]=i;position[region]=position[region]+1;n=n-take
                end
            end
            local a={id=aid,abilityenginer=engine}
            local definition=config:get_config('ability')[aid]
            local costs=config:get_config('ability_level_up_'..definition['升级需求和消耗表']:gsub('%.txt$',''))
            if not costs[h.ability.level]then
                ordinary_blocked=ordinary_blocked+1
                assert(craft.finish(a,h,kind)~=R.OR_OK and h.spent==0 and h.vigor==100000 and h.stamina==100000)
                return -- Authored recipes above the profession's available level table.
            end
            local precheck=craft.check(a,h)
            local result=craft.finish(a,h,kind);assert(result==R.OR_OK,'ordinary recipe rejected '..tostring(result)..' check='..tostring(precheck)..' ability='..aid..' level='..h.ability.level)
            ordinary_created=ordinary_created+1
            local counts={};for _,i in pairs(h.items)do counts[i.id]=(counts[i.id]or 0)+i.count end
            local expected={};for mat,n in pairs(seed)do expected[mat]=n-(need[mat]or 0)end
            expected[row.ResultID]=(expected[row.ResultID]or 0)+row.ResultNum
            for mat,n in pairs(expected)do assert((counts[mat]or 0)==n,'wrong item delta '..mat)end
            for mat,n in pairs(counts)do assert(expected[mat]==n,'unexpected output '..mat)end
            local spent=h.spent;assert(craft.finish(a,h,kind)~=R.OR_OK and h.spent==spent)
        end)
    end
end
print('Ordinary authored recipe census: '..ordinary_count..' tested; '..ordinary_created..' created; '..ordinary_blocked..' safely blocked for missing profession levels (5 professions; fixtures use actual tables)')
test('missing scripted recipe refuses, authored inline-consumption recipe remains available',function()
    local h,a=crafting();local row=recipes[1];local old=row['脚本ID'];row['脚本ID']=335134
    local ok,err=pcall(function()
        function h:notify_tips(t)self.tip=t end
        function h:get_scene()return{scriptenginer={have_function=function()return false end}}end
        assert(not craft.available(a,h)and h.spent==0)
        function h:get_scene()return{scriptenginer={have_function=function(_,_,name)return name=='AbilityCheck'or name=='AbilityProduce'end}}end
        assert(craft.available(a,h))
    end)
    row['脚本ID']=old;assert(ok,err)
end)
package.loaded['scene.configs']={}
package.loaded['scene.skill.impact_logic.std_impact_003']={enum_DAMAGE_TYPE={IDX_DAMAGE_PHY=0,IDX_DAMAGE_MAGIC=1,IDX_DAMAGE_COLD=2,IDX_DAMAGE_FIRE=3,IDX_DAMAGE_LIGHT=4,IDX_DAMAGE_POISON=5}}
local core=require('scene.skill.combat_core').new()
local traits=config:get_config('attck_traits');local ids={'cold','fire','light','posion'}
local function actor()
    local a={attack=100,resist=0,reduce=0,limit=0,rate=0}
    function a:get_obj_type()return 'human'end
    function a:item_value()return self.rate end
    function a:get_dw_jinjie_effect_details()return 0,0 end
    for _,id in ipairs(ids)do
        a['get_attack_'..id]=function(s)return s.attack end
        a['get_defence_'..id]=function(s)return s.resist end
        a['get_reduce_def_'..id]=function(s)return s.reduce end
        a['get_reduce_def_'..id..'_low_limit']=function(s)return s.limit end
    end
    return a
end
for mp=0,15 do
    local trait=traits[require('cy_pvp').trait(mp)]
    for channel,id in ipairs(ids)do
        for _,resistance in ipairs({0,25,75,100,150})do
            test('element '..mp..' '..id..' resist '..resistance,function()
                local a,d=actor(),actor();d.resist=resistance
                local f=core[id..'_damage'];local coefficient=trait[channel+1]/1000000
                eq(f(core,a,d,0,0,trait),100*coefficient*math.max(0,100-resistance)/100)
                d.resist=0;d.rate=2500;eq(f(core,a,d,0,0,trait),75*coefficient)
                d.rate=20000;eq(f(core,a,d,0,0,trait),0)
                d.rate=0;a.reduce=80;a.limit=20;eq(f(core,a,d,0,0,trait),120*coefficient)
                a.reduce=0;eq(f(core,a,d,0,30,trait),70*coefficient)
                eq(f(core,a,d,50,30,trait),105*coefficient) -- skill attack and defensive effect
                a.get_dw_jinjie_effect_details=function()return 10,0 end;a.reduce=10
                local n=f(core,a,d,0,0,trait);assert(n==n and n<math.huge)
            end)
        end
    end
end
for mp=0,15 do
    for _,channel in ipairs({'physical','magic'})do
        test('defensive percentage '..channel..' school '..mp,function()
            local a,d=actor(),actor()
            function a:get_attack_physics()return 100 end
            function a:get_attack_magic()return 100 end
            function a:get_skill_info()return nil end
            function d:get_defence_physics()return 100 end
            function d:get_defence_magic()return 100 end
            function d:item_value(id)
                if id==define.ITEM_ATTRIBUTE.IATTRIBUTE_IMMUNITY_P or id==define.ITEM_ATTRIBUTE.IATTRIBUTE_IMMUNITY_M then return 0 end
                return self.rate
            end
            local f=core[channel..'_damage'];local trait=traits[require('cy_pvp').trait(mp)]
            local normal=f(core,a,d,0,0,trait)
            d.rate=2500;eq(f(core,a,d,0,0,trait),normal*.75)
            d.rate=10000;eq(f(core,a,d,0,0,trait),0)
            d.rate=12500;eq(f(core,a,d,0,0,trait),0)
        end)
    end
end
local mission=require 'cys_mission_request'
test('NPC quest stale/dead/distance/reentrant requests',function()
    local h=human();function h:get_mission_by_id()end;function h:get_world_pos()return{x=0,y=0}end
    local npc={get_script_id=function()return 42 end,get_world_pos=function()return{x=3,y=4}end}
    local scene={objs={[1]=h,[2]=npc},scriptenginer={}}
    local count=0
    function scene.scriptenginer:call(id,fn,who,tar,script)
        assert(id==42 and fn=='OnMissionSubmit' and who==1 and tar==2 and script==100)
        count=count+1;assert(mission.call(scene,1,2,100,'OnMissionSubmit')==false);return true
    end
    assert(mission.call(scene,1,2,100,'OnMissionSubmit'));assert(count==1)
    assert(mission.call(scene,1,999,100,'OnMissionSubmit')==false)
    h.dead=true;assert(mission.call(scene,1,2,100,'OnMissionSubmit')==false);h.dead=false
    npc.get_world_pos=function()return{x=6,y=0}end;assert(mission.call(scene,1,2,100,'OnMissionSubmit')==false)
    assert(count==1 and h._cys_mission_request==nil)
end)
do
    local f=assert(io.open(stage..'/GameServer/services/scene/scenecore.lua')or io.open(root..'/GameServer/services/scene/scenecore.lua'));local src=f:read('*a');f:close()
    local body=assert(src:match('(function scenecore:char_bind_equip%b()%s*.-)\nfunction scenecore:get_all_equip_gemscore'))
    local scene={};assert(load(body,'actual char_bind_equip','t',setmetatable({scenecore=scene,configenginer=config},{__index=_G})))()
    for _,case in ipairs({'unidentified','identified','no-ident-rule','locked','replaced-during-config'})do
        test('wear identification gate '..case,function()
            local h=human();h.notify_tips=function()end
            local id=10200001
            if case=='no-ident-rule' then
                for k,v in pairs(equips)do if not config:get_config('item_ruler')[v.rule].need_ident then id=k;break end end
            end
            local original=item(id);h.items[0]=original
            original.identified=case=='identified';original.locked=case=='locked'
            local old=config.get_config
            if case=='replaced-during-config' then
                config.get_config=function(self,k)config.get_config=old;h.items[0]=item(10200001);return old(self,k)end
            end
            local result=scene:char_bind_equip(h,{bagIndex=0});config.get_config=old
            local accepted=case=='identified' or case=='no-ident-rule'
            assert(result==accepted and original.bound==accepted)
            if case=='replaced-during-config'then assert(not h.items[0].bound)end
        end)
    end
end
if arg[4]then
    assert(loadfile(arg[4]))({test=test,human=human,item=item,config=config,craft=craft,engine=engine,R=R,
        generation=function(fn)generation_hook=fn end,root=root,stage=stage,logic=logic})
end
print(string.format('gameplay audit: %d passed, %d failed (actual configs and handlers)',passes,failures))
os.exit(failures==0 and 0 or 1)
