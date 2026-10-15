-- Execute the real method bodies extracted from baseline or staged runtime.
-- Side effects are recorded at the inventory/packet boundary; no Mongo access.
local root, lib = ...
assert(root and lib, 'runtime root, staged lualib required')
package.path = lib .. '/?.lua;' .. package.path
local rules = require 'cy_pet_rules'
local results, failed = 0, 0
local function test(name, fn)
    results=results+1
    local ok, err=pcall(fn)
    print((ok and 'PASS ' or 'FAIL ')..name..(ok and '' or ': '..tostring(err)))
    if not ok then failed=failed+1 end
end
local function eq(a,b) assert(a==b, tostring(a)..' ~= '..tostring(b)) end
local function read(rel) local f=assert(io.open(root..'/'..rel,'rb'));local s=f:read('a');f:close();return s:gsub('\r\n','\n') end
local function grab(rel, name, env)
    local source=read(rel)
    local chunk=assert(source:match('function '..name..'%([^\n]*\n.-\nend'),name)
    assert(load(chunk,'@'..rel,'t',env))()
end
local templates={}
for i=1,40 do templates[100+i]={group_id=i,operate_mode=0} end
templates[501]={group_id=50,operate_mode=1};templates[502]={group_id=51,operate_mode=1}
templates[601]={group_id=1,operate_mode=0}
local rows={}
for i=0,10 do rows[i]={max_skill_count=10,non_skill_count=i,odd=i==10 and 1000 or 0} end
local cfg={skill_template=templates,pet_study_skill_table=rows,pet_skill_book={[33000001]=101},
    pet_attr_table={[3009]={take_level=5}},cy_pet_rules_data={cost_takelevel5=1000,cost_ExtendCortrolByPlayer=990000},
    pet_skill_level_up={[101]={['升级后的珍兽技能ID']=601,['需要消耗的物品ID']=30503000,['需要消耗的金钱']=500,['是否广播']=0}}}
local ce={get_config=function(_,k) return assert(cfg[k],k) end}
local se={get_skill_template=function(_,k)return templates[k]end}
local define={INVAILD_ID=-1,PET_SKILL_OPERATEMODE={PET_SKILL_OPERATE_NEEDOWNER=1}}
local function classenv(name)
    local env={pet_rules=rules,configenginer=ce,skillenginer=se,define=define};env[name]={}
    env.math=setmetatable({random=function(n)return n end},{__index=math})
    return setmetatable(env,{__index=_G})
end
local petEnv=classenv('pet_detail');local P=petEnv.pet_detail
local petRel='GameServer/lualib/pet_detail.lua'
for _,n in ipairs({'get_activate_skill','get_positive_skill','set_activate_skill','set_positive_skill','get_skill_by_index','set_skill_by_index','skill_modify_study','skill_register','get_skill_max_control_by_ai','get_skill_max_control_by_player','manual_attr','is_in_exchange','set_in_exchange'}) do grab(petRel,'pet_detail:'..n,petEnv) end
local function pet(a,p)
    local v=setmetatable({skill_list={activate=a or {},positive=p or {}},dirty=0,send=0,attrib={}}, {__index=P})
    local lv={point_remain=5,str=10,con=10,dex=10,spr=10,int=10}
    v.db={mark_skill_dirty=function()v.dirty=v.dirty+1 end,get_lv1_attrib=function()return lv end,
        set_lv1_attrib=function(_,t)for k,val in pairs(t)do lv[k]=val end end}
    function v:set_db_attrib(t)for k,val in pairs(t)do self.attrib[k]=val end end
    function v:set_current_title(n)self.title=n end
    function v:send_refresh_attrib()self.send=self.send+1 end
    function v:is_lock()return self.locked or false end
    function v:is_in_exchange()return self.exchange or false end
    function v:get_data_index()return 3009 end
    return v,lv
end

test('skill upgrade marks dirty',function()local p=pet();eq(p:set_skill_by_index(2,101),true);eq(p.dirty,1)end)
for _,n in ipairs({-1,12,13,0.5,1000000}) do
    test('reject skill write index '..n,function()local p=pet();eq(p:set_skill_by_index(n,101),false);eq(p.dirty,0);eq(next(p.skill_list.activate),nil);eq(next(p.skill_list.positive),nil)end)
end
test('duplicate passive in slot 10 is rejected',function()local p=pet({}, {[10]=110});eq(p:skill_modify_study(110),false);eq(p.dirty,0)end)
test('1000/1000 opens first slot even at upper RNG edge',function()local p=pet();eq(p:skill_modify_study(101),true);eq(p:get_skill_by_index(2),101)end)
test('replacement selects occupied sparse slot',function()local p=pet({}, {[10]=110});eq(p:skill_modify_study(101),true);eq(p:get_skill_by_index(11),101);eq(p:get_skill_by_index(2),nil)end)
test('same group replaces in place',function()local p=pet({}, {[4]=101});eq(p:skill_modify_study(601),true);eq(p:get_skill_by_index(5),601)end)
test('unknown stored template preserved without exception',function()local p=pet({}, {[4]=99999});eq(p:skill_modify_study(101),false);eq(p:get_skill_by_index(5),99999)end)
test('two manual skills supported',function()local p=pet({501});eq(p:skill_modify_study(502),true);eq(p:get_skill_by_index(1),502)end)
test('unknown requested skill rejected',function()local p=pet();eq(p:skill_modify_study(99999),false)end)
for _,n in ipairs({-1,6,0.5,4294967295,math.huge}) do
    test('manual points reject '..n..' before name change',function()local p,lv=pet();p:manual_attr({str_increment=n,name='changed'});eq(lv.str,10);eq(lv.point_remain,5);eq(p.attrib.name,nil)end)
end
test('mixed negative increments cannot mint points',function()local p,lv=pet();p:manual_attr({str_increment=4,con_increment=-5});eq(lv.str,10);eq(lv.con,10);eq(lv.point_remain,5)end)
test('legal point allocation exact budget',function()local p,lv=pet();p:manual_attr({str_increment=2,spr_increment=3});eq(lv.str,12);eq(lv.spr,13);eq(lv.point_remain,0);eq(p.send,1)end)

local G={};G.__index=G;G.__eq=function(a,b)return a.h==b.h and a.l==b.l end
function G:set(h,l)self.h=h;self.l=l end
local guid={new=function()return setmetatable({},G)end}
local target, human, bag, book, sent
local it={}
function it:dec_item_lay_count(_,h,pos,count)
    if book.reject then return false end
    local v=bag[pos];if not v or v.count<count then return false end
    v.count=v.count-count;return true
end
package.preload.define=function()return define end
package.preload.pet_guid=function()return guid end
package.preload.configenginer=function()return{getinstance=function()return ce end}end
package.preload.skillenginer=function()return{getinstance=function()return se end}end
package.preload.human_item_logic=function()return it end
local gameplay=require 'cy_pet_gameplay'
local function setup(id)
    target=pet();sent=0;book={id=id or 33000001,count=2}
    function book:get_index()return self.id end
    function book:get_lay_count()return self.count end
    function book:is_lock()return self.locked or false end
    bag={[0]=book}
    human={money=2000,banked=0}
    function human:get_pet_bag_container()return{get_pet_by_guid=function(_,g)if g.h==12 and g.l==34 then return target end end}end
    function human:get_prop_bag_container()return{get_item=function(_,n)return bag[n]end}end
    function human:get_current_pet_guid()local g=guid.new();g:set(self.fighting and 12 or 0,self.fighting and 34 or 0);return g end
    function human:get_current_soul_melting_pet_guid()local g=guid.new();g:set(self.melting and 12 or 0,self.melting and 34 or 0);return g end
    function human:check_money_with_priority(n)return self.money>=n end
    function human:cost_money_with_priority(n)self.money=self.money-n;return true end
    function human:send_pet_detail()sent=sent+1 end
    local s={scene={get_obj_by_id=function()return human end}}
    function s:LuaFnGetHighSectionOfTargetPetGuid()return self.high or 12 end
    function s:LuaFnGetLowSectionOfTargetPetGuid()return self.low or 34 end
    function s:LuaFnGetBagIndexOfUsedItem()return 0 end
    return s
end
local itemEnv=classenv('item_6096');itemEnv.pet_gameplay=gameplay
for _,n in ipairs({'OnConditionCheck','OnActivateOnce'})do grab('Game_2/Script/scripts/obj/commonitem/item_6096.lua','item_6096:'..n,itemEnv)end
local function itemscript()
    local s=setup();setmetatable(s,{__index=itemEnv.item_6096})
    function s:LuaFnVerifyUsedItem()return true end
    function s:LuaFnIsPetAvailableByGUIDNoPW()return true end
    function s:GetPetBookId()return book.id end
    function s:GetPetBookSkillID()return 101 end
    function s:LuaFnGetCurrentPetGUID()return 0,0 end
    function s:LuaFnDepletingUsedItem()book.count=book.count-1;return true end
    function s:CallScriptFunction()return target:skill_modify_study(101)end
    function s:LuaFnSendSpecificImpactToUnit()end
    return s
end
test('real book condition accepts available boolean Pet',function()local s=itemscript();eq(s:OnConditionCheck(1),1);eq(book.count,2)end)
test('real book activation learns exactly one and charges CY cost',function()local s=itemscript();eq(s:OnActivateOnce(1),1);eq(book.count,1);eq(human.money,1000);eq(target:get_skill_by_index(2),101);eq(sent,1)end)
test('real duplicate book activation preserves resources',function()local s=itemscript();target.skill_list.positive[10]=101;s:OnActivateOnce(1);eq(book.count,2);eq(human.money,2000)end)
test('real poor owner keeps book',function()local s=itemscript();human.money=999;s:OnActivateOnce(1);eq(book.count,2);eq(target:get_skill_by_index(2),nil)end)
test('real nonexistent Pet keeps book',function()local s=itemscript();s.high=13;s:OnActivateOnce(1);eq(book.count,2);eq(human.money,2000)end)
for _,kind in ipairs({'locked','exchange','fighting','melting'})do
    test('gameplay book rejects '..kind,function()local s=setup();if kind=='locked' or kind=='exchange' then target[kind]=true else human[kind]=true end;eq(gameplay.study(s,1,true),false);eq(book.count,2);eq(human.money,2000)end)
end
for _,kind in ipairs({'empty','unknown','locked','poor','delete_failure','wrong_slot','wrong_item'})do
    test('upgrade atomic rejection '..kind,function()
        local s=setup(30503000);target.skill_list.positive[1]=101;local slot=0
        if kind=='empty'then target.skill_list.positive={} elseif kind=='unknown'then target.skill_list.positive[1]=99999
        elseif kind=='locked'then book.locked=true elseif kind=='poor'then human.money=499
        elseif kind=='delete_failure'then book.reject=true elseif kind=='wrong_slot'then slot=1 elseif kind=='wrong_item'then book.id=33000001 end
        local money=human.money;local before=target:get_skill_by_index(2)
        eq(gameplay.upgrade(s,1,12,34,2,slot),false);eq(book.count,2);eq(human.money,money);eq(target:get_skill_by_index(2),before)
    end)
end
test('upgrade success and replay rejects without spending',function()local s=setup(30503000);target.skill_list.positive[1]=101;eq(gameplay.upgrade(s,1,12,34,2,0),true);eq(book.count,1);eq(human.money,1500);eq(target:get_skill_by_index(2),601);eq(target.dirty,1);eq(gameplay.upgrade(s,1,12,34,2,0),false);eq(book.count,1);eq(human.money,1500)end)
local data=require 'cy_pet_rules_data'
test('real CfgDB getter loads shared Pet rules on first request',function()
    local env=classenv('cfghelper');env.require=function(name)eq(name,'cy_pet_rules_data');return data end
    grab('GameServer/lualib/cfghelper.lua','cfghelper:read_cy_pet_rules_data',env)
    grab('GameServer/lualib/cfghelper.lua','cfghelper:get_cy_pet_rules_data',env)
    local helper=setmetatable({}, {__index=env.cfghelper})
    eq(helper:get_cy_pet_rules_data(),data);eq(helper:get_cy_pet_rules_data(),data)
end)
test('exchange state follows add/cancel trade',function()
    local p=pet();eq(P.is_in_exchange(p),false);p:set_in_exchange(true);eq(P.is_in_exchange(p),true)
    p:set_in_exchange(false);eq(P.is_in_exchange(p),false)
end)
local registered=classenv('common_item');registered.pet_gameplay=gameplay
for _,n in ipairs({'OnConditionCheck','OnActivateOnce'})do grab('Game_2/Script/scripts/obj/pet/6096.lua','common_item:'..n,registered)end
for _,failure in ipairs({'duplicate','poor','missing','reject_delete','success'})do
    test('registered 336096 activation '..failure,function()
        local s=itemscript();setmetatable(s,{__index=registered.common_item})
        if failure=='duplicate' then target.skill_list.positive[10]=101 end
        if failure=='poor' then human.money=999 end
        if failure=='missing' then s.high=13 end
        if failure=='reject_delete' then book.reject=true end
        local money=human.money;s:OnActivateOnce(1)
        eq(book.count,failure=='success' and 1 or 2)
        eq(human.money,failure=='success' and money-1000 or money)
        if failure=='success' then eq(target:get_skill_by_index(2),101) end
    end)
end

local function progression(kind,level)
    local s=setup(kind=='lingxing' and 20310116 or 30502000)
    cfg.cy_pet_rules_data=data
    human.money=1000000;human.yb=1000000;human.level=100
    target.savvy=level or 0;target.lx=level or 0;target.awake=true
    function target:get_wuxing()return self.savvy end
    function target:set_wuxing(n)self.savvy=n end
    function target:get_ling_xing()return self.lx end
    function target:set_ling_xing(n)self.lx=n end
    function target:have_huan_hua()return self.awake end
    function target:get_attrib(k)if k=='main_perception' then return 1000 end end
    function human:get_level()return self.level end
    function human:get_yuanbao()return self.yb end
    function human:cost_yuanbao(n)
        self.yb=self.yb-n
        -- At the first possible yield both Pet and currency must be committed.
        eq(kind=='lingxing' and target.lx or target.savvy,10)
        if self.reenter then eq(gameplay[kind](s,1,12,34,true),false) end
        return true
    end
    return s
end
for _,kind in ipairs({'savvy','lingxing'})do
    for _,bad in ipairs({'wrong_guid','max','fighting','melting','poor','locked','no_material'})do
        test(kind..' rejects '..bad..' without spending',function()
            local s=progression(kind);local high=12
            if bad=='wrong_guid'then high=13 elseif bad=='max'then target.savvy=10;target.lx=10
            elseif bad=='poor'then human.money=0 elseif bad=='locked'then book.locked=true
            elseif bad=='no_material'then book.id=33000001 else human[bad]=true end
            local money=human.money;eq(gameplay[kind](s,1,high,34,false),false);eq(book.count,2);eq(human.money,money)
        end)
    end
    test(kind..' quick CY price, no double charge on reentry',function()
        local s=progression(kind);human.reenter=true
        eq(gameplay[kind](s,1,12,34,true),true);eq(human.yb,1000000-86666);eq(book.count,2)
        eq(gameplay[kind](s,1,12,34,true),false);eq(human.yb,1000000-86666)
    end)
end
test('savvy guaranteed first level charges exactly one material',function()
    local s=progression('savvy');eq(gameplay.savvy(s,1,12,34,false),true)
    eq(target.savvy,1);eq(book.count,1);eq(human.money,1000000-data.GenGu_cost_savvy0)
end)
test('lingxing non-awakened rejects before material',function()
    local s=progression('lingxing');target.awake=false
    eq(gameplay.lingxing(s,1,12,34,false),false);eq(book.count,2)
end)
for _,bad in ipairs({'invalid_guid','equipped','wild','savvy','awake','model','missing_model','poor','locked','exchange','success'})do
    test('awakening '..bad..' atomic resources',function()
        local s=progression('savvy',5);book.id=30502005;target.awake=false
        cfg.pet_attr_table[3009]={take_level=5,is_baby_type=true}
        cfg.pet_huan_hua_table={[3009]={[1]=3009,[2]=-1,cost=100000}}
        function target:have_equip()return self.equipped end
        function target:set_huan_huad()self.awake=true;self.lx=0 end
        function target:set_data_index(id)self.newid=id end
        local high,keep=12,1
        if bad=='invalid_guid'then high=13 elseif bad=='equipped'then target.equipped=true
        elseif bad=='wild'then cfg.pet_attr_table[3009].is_baby_type=false
        elseif bad=='savvy'then target.savvy=4 elseif bad=='awake'then target.awake=true
        elseif bad=='model'then keep=2 elseif bad=='missing_model'then cfg.pet_huan_hua_table[3009][1]=-1
        elseif bad=='poor'then human.money=99999 elseif bad=='locked'then book.locked=true
        elseif bad=='exchange'then target.exchange=true end
        local money,awake=human.money,target.awake
        eq(gameplay.awaken(s,1,high,34,keep),bad=='success')
        eq(book.count,bad=='success' and 1 or 2);eq(human.money,bad=='success' and money-100000 or money)
        if bad=='success'then eq(target.awake,true);eq(target.newid,3009);eq(gameplay.awaken(s,1,high,34,keep),false);eq(book.count,1)
        else eq(target.awake,awake);eq(target.newid,nil) end
    end)
end
test('bound low grade savvy pill is accepted',function()
    local s=progression('savvy');book.id=30504038
    eq(gameplay.savvy(s,1,12,34,false),true);eq(target.savvy,1);eq(book.count,1)
end)
for _,rel in ipairs({'GameServer/lualib/pet_attrib.lua','GameServer/lualib/db/pet_attrib.lua'})do
    for _,kind in ipairs({'missing_level','missing_extension','unknown_extension'})do
        test(rel..' soul '..kind..' keeps elf effects and dirties cache',function()
            local env=classenv('pet_attrib');local A=env.pet_attrib
            env.define={INVAILD_ID=-1,PET_EQUIP={PEQUIP_CAP=0,PEQUIP_AMULET=4,PEQUIP_SOUL=5},ITEM_ATTRIBUTE={
                IATTRIBUTE_RATE_STR_PERCEPTION=100,IATTRIBUTE_RATE_SPR_PERCEPTION=101,IATTRIBUTE_RATE_CON_PERCEPTION=102,
                IATTRIBUTE_RATE_DEX_PERCEPTION=103,IATTRIBUTE_RATE_INT_PERCEPTION=104},PET_SOUL_EXTENSION_2_IA={},EQUIP_BASE_ATTRIB={}}
            env.elf_rate_to_point={};env.require=function(n)eq(n,'skynet');return{error=function()end}end
            local c={pet_equip_base={},pet_equip_set_attr={},pet_soul_level_up_info={},pet_soul_skill={},pet_jl_attr={[1]={[42]=7}}}
            env.configenginer={get_config=function(_,n)return assert(c[n],n)end}
            if kind~='missing_level'then c.pet_soul_level_up_info[900]={[2]={add_str_perception=0,add_spr_perception=0,add_con_perception=0,add_dex_perception=0,add_int_perception=0}} end
            local soul={copy_raw_data=function()return{item_index=900,level=2,pet_soul_attr=kind=='unknown_extension' and {{type=999,value=100}} or {}}end,
                get_index=function()return 900 end,get_pet_soul_base=function()return nil end,
                get_pet_equip_data=function()return{get_pet_soul_level=function()return 0 end}end}
            local owner={get_obj_id=function()return 1 end,get_equip_container=function()return{get_item=function(_,i)if i==5 then return soul end end}end}
            local obj=setmetatable({elf_slots={{activated=1,level=1,attrs={42}}},get_pet=function()return owner end,
                set_not_gen_attrib=function()end,mark_all_attr_dirty=function(v)v.dirty=true end,
                cal_item_effect=function(v,k,n)v.item_effect[k]=(v.item_effect[k] or 0)+n end}, {__index=A})
            grab(rel,'pet_attrib:item_effect_flush',env);obj:item_effect_flush()
            eq(obj.item_effect[42],7);eq(obj.dirty,true);eq(obj.pet_soul_skill,-1)
        end)
    end
end
for _,bad in ipairs({'empty','unknown','poor','fighting','exchange','success'})do
    test('quick skill '..bad..' exact currency and duplicate handling',function()
        local s=progression('savvy');target.skill_list.positive[1]=656
        templates[1200]={group_id=1200,operate_mode=0}
        function human:cost_yuanbao(n)
            self.yb=self.yb-n;eq(target:get_skill_by_index(2),1200)
            eq(gameplay.upgrade_quick(s,1,12,34,2),false);return true
        end
        if bad=='empty'then target.skill_list.positive={}
        elseif bad=='unknown'then target.skill_list.positive[1]=1656
        elseif bad=='poor'then human.yb=4723 elseif bad=='fighting'then human.fighting=true
        elseif bad=='exchange'then target.exchange=true end
        local yb=human.yb;eq(gameplay.upgrade_quick(s,1,12,34,2),bad=='success')
        eq(human.yb,bad=='success' and yb-4724 or yb);eq(book.count,2)
    end)
end
for _,kind in ipairs({'missing','exchange','locked','equipped','fighting','melting','elf','normal'})do
    test('real release rejects '..kind..' before deletion',function()
        local env=classenv('human');env.define={OPERATE_RESULT={OR_ERROR=-1,OR_OK=0}}
        grab('GameServer/services/scene/obj/human.lua','human:free_pet_to_nature',env)
        local g=guid.new();g:set(12,34);function g:is_null()return false end
        local p={is_lock=function()return kind=='locked'end,is_in_exchange=function()return kind=='exchange'end,
            have_equip=function()return kind=='equipped'end,elf_slots=kind=='elf' and {{activated=1}} or {}}
        local h=setmetatable({removed=0},{__index=env.human})
        function h:get_pet_bag_container()return{get_pet_by_guid=function()return kind~='missing' and p or nil end}end
        function h:get_current_pet_guid()return kind=='fighting' and g or nil end
        function h:get_current_soul_melting_pet_guid()return kind=='melting' and g or nil end
        function h:recall_pet()end
        function h:remove_pet()self.removed=self.removed+1;return true end
        eq(h:free_pet_to_nature({},g),kind=='normal' and 0 or -1);eq(h.removed,kind=='normal' and 1 or 0)
    end)
end
for _,kind in ipairs({'missing','same','equipped','baby','variant','low_take_level','zero_gengu','low_gengu','elf','locked','exchange','fighting','melting','poor','remove_failure','success'})do
    test('savvy assist '..kind..' preserves or consumes exactly one Pet',function()
        local s=progression('savvy');human.removed=0
        cfg.pet_attr_table={[3009]={take_level=25},[3010]={take_level=25}}
        local assist=pet();local ag=guid.new();ag:set(12,35)
        function assist:get_data_index()return 3010 end
        function assist:have_equip()return kind=='equipped'end
        function assist:get_attrib(k)eq(k,'gengu');return kind=='zero_gengu' and 0 or 5 end
        function human:get_pet_bag_container()return{get_pet_by_guid=function(_,g)
            if g.h==12 and g.l==34 then return target end
            if g.h==12 and g.l==35 and kind~='missing'then return assist end
        end}end
        function human:remove_pet(_,g)eq(g,ag);if kind=='remove_failure'then return false end;self.removed=self.removed+1;return true end
        if kind=='baby'then cfg.pet_attr_table[3010].is_baby_type=true
        elseif kind=='variant'then cfg.pet_attr_table[3010].is_var_type=true
        elseif kind=='low_take_level'then cfg.pet_attr_table[3010].take_level=15
        elseif kind=='low_gengu'then target.savvy=6
        elseif kind=='elf'then assist.elf_slots={{activated=1}}
        elseif kind=='locked'then assist.locked=true
        elseif kind=='exchange'then assist.exchange=true
        elseif kind=='fighting'then function human:get_current_pet_guid()return ag end
        elseif kind=='melting'then function human:get_current_soul_melting_pet_guid()return ag end
        elseif kind=='poor'then human.money=9999 end
        local before,level=human.money,target.savvy
        eq(gameplay.savvy(s,1,12,34,false,12,kind=='same' and 34 or 35),kind=='success')
        eq(human.removed,kind=='success' and 1 or 0);eq(book.count,2)
        eq(human.money,kind=='success' and before-10000 or before)
        eq(target.savvy,kind=='success' and 1 or level)
    end)
end
test('actual internal removal clears soul before erasing Pet',function()
    local env=classenv('human');env.packet_def={GCRemovePet={new=function()return{}end}}
    grab('GameServer/services/scene/obj/human.lua','human:remove_pet',env)
    local g=guid.new();g:set(12,34);local order={};local p={get_guid=function()return g end}
    local bag={get_pet_by_guid=function()return p end,get_item_data=function()return{[0]=p}end,get_size=function()return 1 end,
        erase_item=function()order[#order+1]='erase'end}
    local h=setmetatable({},{__index=env.human})
    function h:get_pet_bag_container()return bag end
    function h:get_current_soul_melting_pet_guid()return g end
    function h:get_current_pet_guid()return nil end
    function h:remelting_pet_soul()order[#order+1]='separate'end
    function h:get_scene()return{send2client=function()order[#order+1]='notify'end}end
    eq(h:remove_pet({},g),true);eq(table.concat(order,','),'separate,erase,notify')
end)
test('CY savvy decline exact levels 3 and 6',function()eq(data.Compound_leveldown_savvy3,2);eq(data.Compound_leveldown_savvy6,2)end)
test('CY lingxing every row and boundary agrees with source data',function()
    local count=0
    for _,list in pairs(data.lingxing)do for _,r in ipairs(list)do
        for level=101,110 do
            local first=rules.lingxing_row(list,r[1]);eq(rules.lingxing_bonus(list,r[1],level),first[level-98])
        end
        eq(rules.lingxing_bonus({r},r[2],110),0);eq(rules.lingxing_bonus({r},r[1],100),0);count=count+1
    end end
    assert(count>20000)
end)
print(string.format('TOTAL %d PASS %d FAIL %d',results,results-failed,failed))
os.exit(failed==0 and 0 or 1)
