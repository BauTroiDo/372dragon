-- Actual staged/runtime methods, isolated actor/transport. No DB mutations.
local root=assert(arg[1]);local staged=arg[2] or root
package.path=staged..'/GameServer/lualib/?.lua;'..staged..'/GameServer/services/?.lua;'..
    root..'/GameServer/lualib/?.lua;'..root..'/GameServer/services/?.lua;'..package.path
package.loaded.skynet={getenv=function()end,error=function()end}
local class=require 'class';local define=require 'define'
package.loaded['scene.skill.impact_logic.base']=class('base')
function table.clone(x) if type(x)~='table' then return x end;local t={};for k,v in pairs(x)do t[k]=table.clone(v)end;return t end
local n=0
local function eq(a,b,label)n=n+1;assert(a==b,(label or '')..': '..tostring(a)..' ~= '..tostring(b))end
local function read(rel)
    local f=io.open(staged..'/'..rel,'rb') or assert(io.open(root..'/'..rel,'rb'))
    local s=f:read('a');f:close();return s:gsub('\r\n','\n')
end
local function grab(rel,name,env)
    local body=assert(read(rel):match('function '..name..'%([^\n]*\n.-\nend'),name)
    assert(load(body,'@'..rel,'t',env))()
end
local source=read('GameServer/lualib/item.lua')
local a=assert(source:find('local pet_equip_data = class',1,true))
local b=assert(source:find('\nlocal task_data = class',a,true))
local writes={}
local writer={}
for _,name in ipairs({'writeint','writeuint','writeuchar','writechar','writeushort','writeshort','writeulong'})do
    writer[name]=function(_,v)writes[#writes+1]={name,v}end
end
function writer:get()return ''end
local env=setmetatable({class=class,define=define,iostream={bostream={new=function()return writer end}}},{__index=_G})
local PE=assert(load(source:sub(a,b-1)..'\nreturn pet_equip_data','pet data','t',env))()
for _,life in ipairs({0,1,300,420,65535})do
    local one=PE.new();one.pet_equip_unknow_8=life;one:set_pet_equip_type(1)
    one:set_level(3);one:set_attr_count(2);one:set_attr_types({19,26});one:set_attr_value({123,456})
    one:set_qualifications({0,1,30,80,200,255})
    local saved=one:copy_raw_data();local two=PE.new();two:init_from_data(saved)
    eq(two.pet_equip_unknow_8,life,'soul life roundtrip')
    eq(two.attr_values[1],123);eq(two.attr_values[2],456)
    for i=1,6 do eq(two.qualifications[i],saved.qualifications[i])end
    writes={};two:get_transfer({item_index=50101001})
    local short={};for _,w in ipairs(writes)do if w[1]=='writeushort' then short[#short+1]=w[2] end end
    eq(short[1],3);eq(short[2],life,'chat life')
    writes={};two:get_stream(writer,{item_index=50101001})
    local level=false;local actual
    for _,w in ipairs(writes)do if w[1]=='writeushort' then level=true elseif level and w[1]=='writeuint' then actual=w[2];break end end
    eq(actual,life,'legacy stream life')
end
local x=PE.new();local saved=x:copy_raw_data();saved.pet_equip_unknow_8=nil
x:init_from_data(saved);eq(x.pet_equip_unknow_8,300,'legacy fallback')
print('PASS soul save/load and chat/shop serializers')

-- Exercise the real ItemInfo serializer. Bag identity packets can succeed even
-- when this separate detail response crashes for an empty soul attribute list.
local iostream=require 'iostream';local packets={}
require('game.packet_types.guid').bind(packets,iostream.bistream,iostream.bostream,{},define)
require('game.packet_types.item_types').bind(packets,iostream.bistream,iostream.bostream,{},define)
local soul=PE.new();soul:set_pet_equip_type(1);soul:set_level(1)
soul:set_pet_soul_level(0);soul:set_pet_soul_exp(0)
local detail=soul:copy_raw_data()
detail.item_index=70600000;detail.guid={world=254,server=254,series=12345,mask=0}
detail.rule=1;detail.status=2;detail.unknow_4={0,0,0,0,0,0,0,0,0,0,0,0}
detail.unknow_44=0;detail.unknow_45=0
local function soul_detail(attrs)
    detail.pet_soul_attr=attrs;local out=iostream.bostream.new()
    packets.ItemInfo.bos(detail,out);local raw=out:get()
    -- Six (signed type byte, uint32 value) rows precede the six-byte suffix.
    local input=iostream.bistream.new();input:attach(raw:sub(-36))
    for i=1,6 do
        local row=attrs and attrs[i]
        eq(input:readchar(),row and row.type or -1,'detail empty type is invalid, not attr zero')
        eq(input:readuint(),row and row.value or 0,'detail preserves attribute value')
    end
    eq(input:readuint(),0);eq(input:readushort(),0)
    return raw
end
local empty=soul_detail({});eq(soul_detail(nil),empty,'absent and empty list share wire layout')
eq(#soul_detail({[2]={type=0,value=123},[6]={type=31,value=4294967295}}),#empty,'sparse detail has fixed wire size')
eq(detail.pet_soul_attr[1],nil,'serializer never fills or rerolls item data')
print('PASS actual ItemInfo bytes: empty/absent/sparse soul attributes retain sentinel and values')

local quality=require 'cys_pet_equipment';local rows=require 'cys_pet_apt_data';local IA=define.ITEM_ATTRIBUTE
local attrs={IA.IATTRIBUTE_BASE_ATTACK_P,IA.IATTRIBUTE_BASE_DEFENCE_P,IA.IATTRIBUTE_BASE_MAGIC_P,
    IA.IATTRIBUTE_BASE_DEFENCE_M,IA.IATTRIBUTE_BASE_MISS,IA.IATTRIBUTE_BASE_HIT}
for q=0,255 do for i,ia in ipairs(attrs)do
    local raw={qualifications={0,0,0,0,0,0}};raw.qualifications[i]=q
    local expected=q>0 and math.max(0,rows[q][i]) or 0
    eq(quality.quality_bonus(raw,ia,100),expected,'table mapping')
    for j,other in ipairs(attrs)do if j~=i then eq(quality.quality_bonus(raw,other,100),0,'independent quality bytes')end end
end end
eq(quality.quality_bonus({qualifications={255}},attrs[1],101),81,'rounding')
eq(quality.quality_bonus({qualifications={255}},IA.IATTRIBUTE_STR,100),0,'affix never multiplied')
for _,rel in ipairs({'GameServer/lualib/pet_attrib.lua','GameServer/lualib/db/pet_attrib.lua'})do
    local conf={pet_equip_base={[123]={base_attrs={}}},pet_equip_set_attr={}}
    for k in pairs(define.EQUIP_BASE_ATTRIB)do conf.pet_equip_base[123].base_attrs[k]=100 end
    local raw={attr_count=1,attr_values={17},attr_types={IA.IATTRIBUTE_STR},qualifications={0,0,0,0,0,0}}
    local equip={copy_raw_data=function()return raw end,get_serial_type=function()return 1 end,
        get_index=function()return 123 end,get_base_config=function()return{}end}
    local pet={get_equip_container=function()return{get_item=function(_,i)if i==define.PET_EQUIP.PEQUIP_CAP then return equip end end}end}
    local env=setmetatable({pet_attrib={},define=define,IA=IA,configenginer={get_config=function(_,k)return conf[k]end},skynet=package.loaded.skynet},{__index=_G})
    grab(rel,'pet_attrib:cal_item_effect',env);grab(rel,'pet_attrib:item_effect_flush',env)
    local actor=setmetatable({get_pet=function()return pet end,set_not_gen_attrib=function()end,mark_all_attr_dirty=function()end},{__index=env.pet_attrib})
    actor:item_effect_flush();for _,ia in ipairs(attrs)do eq(actor.item_effect[ia],100)end
    raw.qualifications={255,254,253,252,251,250};actor:item_effect_flush()
    for i,ia in ipairs(attrs)do eq(actor.item_effect[ia],100+math.max(0,rows[raw.qualifications[i]][i]))end
    eq(actor.item_effect[IA.IATTRIBUTE_STR],17)
    actor:item_effect_flush();eq(actor.item_effect[attrs[1]],180,'reflush must not compound')
end
print('PASS all 256 aptitude values, all six independent columns, both pet calculators')

package.loaded.skillenginer={getinstance=function()return{is_skill_in_collection=function(_,id,coll)return (id==312 or id==311) and coll==117 end}end}
local L=require('scene.skill.impact_logic.std_impact_101').new()
local sent=0;local actor={get_scene=function()return{get_impact_enginer=function()return{send_impact_to_unit=function()sent=sent+1 end}end}end}
local function buff()return{params={['刀数上限']=15,['生效技能集合']=117,['加速BUFF']=32410},get_skill_id=function()return 321 end}end
local function hit(p,token,id)
    local d={damage_rate=100};L:on_damage_target(p,actor,{},d,id or 312,{get_caster_logic_count=function()return token end});return d
end
local p=buff()
for i=1,10 do eq(hit(p,1).cys_nuhuo_rate,1.5,'all AoE victims same bonus')end
eq(p.params['刀数'],1);eq(p.params['命中刀数'],1);eq(sent,1)
eq(hit(p,2).cys_nuhuo_rate,4.5);eq(hit(p,1).cys_nuhuo_rate,1.5,'delayed earlier cast')
eq(p.params['刀数'],2)
for k=3,15 do eq(hit(p,k).cys_nuhuo_rate,1.5*k*(k+1)/2)end
eq(hit(p,16).cys_nuhuo_rate,nil,'after limit');eq(p.params['刀数'],15)
eq(hit(p,15).cys_nuhuo_rate,180,'last cast delayed victim')
p=buff();L:on_miss_target(p,actor,{},312,1);L:on_miss_target(p,actor,{},312,1)
eq(p.params['刀数'],1);eq(p.params['命中刀数'],nil)
eq(hit(p,1).cys_nuhuo_rate,1.5,'mixed miss/hit AoE');eq(p.params['刀数'],1)
L:on_miss_target(p,actor,{},999,2);eq(p.params['刀数'],1,'ineligible miss')
eq(hit(p,3,999).cys_nuhuo_rate,nil,'ineligible hit')
eq(hit(p,-1).cys_nuhuo_rate,nil,'invalid cast')
eq(L.on_skill_miss,nil,'evading must not advance offensive buff')
print('PASS knives, AoE, misses, delayed/repeated callbacks, limit, native progression')

-- Exercise the real final damage function, including packet HP accounting.
-- Actor/transport hooks are isolated; arithmetic comes from runtime source.
local D=require 'scene.skill.impact_logic.std_impact_003'
package.loaded['cy_four_combat.hooks']={final_damage=function(_,_,value)return value end}
local hp,shown=10000,0
local target={is_active_obj=function()return true end,is_die=function()return false end,
    get_obj_type=function()return 'pet' end,get_obj_id=function()return 10 end,
    get_scene=function()return {get_obj_by_id=function()end} end,
    get_attrib=function(_,key)return key=='hp' and hp or 10000 end,
    set_hp=function(_,value)hp=value end,get_character_logic=function()return -1 end,
    impact_on_die_check=function()return false end,on_die=function()end,
    broadcast_heal_and_damage_msg=function(_,_,msg)
        shown=shown-(msg.hp_modification or 0)
        if msg.mp_modification then shown=shown-msg.mp_modification-100000 end
    end}
env=setmetatable({character={},define=define,DAMAGE_TYPE_RATE=D.enum_DAMAGE_TYPE_RATE,
    DAMAGE_TYPE_POINT=D.enum_DAMAGE_TYPE_POINT,DAMAGE_TYPE_BACK=D.enum_DAMAGE_TYPE_BACK,
    packet_def={GCDetailHealsAndDamages={new=function()return{dirty_flags=0}end}}},{__index=_G})
grab('GameServer/services/scene/obj/character.lua','character:on_damages',env)
setmetatable(target,{__index=env.character})
local function final_damage(bonus,immune,pierce,start_hp)
    hp=start_hp or 10000;shown=0
    local d={cys_nuhuo_rate=bonus,imm_dmg_rate=immune,chuanci=pierce}
    for i,key in ipairs(D.enum_DAMAGE_TYPE_RATE)do d[i-1]=100;d[key]=100;d[D.enum_DAMAGE_TYPE_POINT[i]]=0 end
    for _,key in ipairs(D.enum_DAMAGE_TYPE_BACK)do d[key]={}end
    target:on_damages(d,-1,false,312)
    return (start_hp or 10000)-hp,shown
end
for _,test in ipairs({{nil,0,0,700},{1.5,0,0,711},{4.5,0,0,732},{180,0,0,1960},
    {180,50,30,1010},{180,100,30,30}})do
    local loss,display=final_damage(test[1],test[2],test[3]);eq(loss,test[4]);eq(display,loss,'display matches final HP loss')
end
local loss,display=final_damage(180,0,30,123);eq(loss,123);eq(display,123,'overkill cannot inflate floating damage')
print('PASS native Nuhuo progression reaches real HP loss once, immunity, piercing, lethal display')

local pending={};local captured={};local E={}
env=setmetatable({eventenginer=E,define=define,skynet={fork=function(f)pending[#pending+1]=f end,loge=error}},{__index=_G})
for _,m in ipairs({'register_impact_event','register_skill_miss_event'})do grab('GameServer/lualib/eventenginer.lua','eventenginer:'..m,env)end
function E:real_register_impact_event(r,s,imp,delay,id,token)captured[#captured+1]=token end
function E:real_register_skill_miss_event(s,r,id,token)captured[#captured+1]=token end
local actor={token=41,get_logic_count=function(s)return s.token end}
E:register_impact_event({},actor,{get_data_index=function()return 3 end},0,312)
E:register_skill_miss_event(actor,{},312);actor.token=42
for _,f in ipairs(pending)do f()end
eq(captured[1],41,'hit frozen before fork');eq(captured[2],41,'miss frozen before fork')
env=setmetatable({human={},impactenginer={get_logic=function()return{on_skill_miss=function()error('must not be called')end,
    forbidden_this_skill=function(_,impact,id)eq(impact,p);eq(id,312);return true end}end}},{__index=_G})
grab('GameServer/services/scene/obj/human.lua','human:impact_forbidden_this_skill',env)
local h=setmetatable({get_scene=function()return{get_impact_enginer=function()return env.impactenginer end}end,get_impact_list=function()return{p}end},{__index=env.human})
eq(h:impact_forbidden_this_skill(312),true)
print('PASS event identity before yield and side-effect-free skill eligibility')

env=setmetatable({echangeusername={}},{__index=_G})
grab('Game_2/Script/scripts/event/huodong/echangeusername.lua','echangeusername:CallBackChangeUserNameAfter',env)
local consumed=0;local h=setmetatable({LuaFnIsCanDoScriptLogic=function()return true end,
    LuaFnDelAvailableItem=function()consumed=consumed+1;return true end,MsgBox=function()end},{__index=env.echangeusername})
for _,name in ipairs({'OldName','*Duplicate'})do for _,code in ipairs({1,2,3,4,99})do
    eq(h:CallBackChangeUserNameAfter(1,code,name),0);eq(consumed,0)
end end
eq(h:CallBackChangeUserNameAfter(1,0,'OldName'),1);eq(consumed,1)
eq(h:CallBackChangeUserNameAfter(1,0,'*Duplicate'),1);eq(consumed,1)
print('PASS rename callback failures preserve token, success pays once, free rename')
env=setmetatable({human={},define=define},{__index=_G})
for _,method in ipairs({'add_killer_pk_value','on_be_kill','is_counter_killed','pentalty_type_after_die','after_die'})do
    grab('GameServer/services/scene/ai/human.lua','human:'..method,env)
end
local killer;local world={get_obj_by_id=function()return killer end,get_type=function()return 0 end,
    get_pvp_rule=function()return 2 end,is_allow_add_pk_value=function()return true end,on_player_die=function()end}
local victim={get_scene=function()return world end,get_obj_id=function()return 1 end,get_level=function()return 100 end,
    get_obj_type=function()return 'human' end,get_pk_value=function()return 0 end,
    is_attackers=function()return true end,is_wild_war_guild=function()return false end,
    is_counter_killed=function()return true end,set_pk_value=function()error('self PK change')end}
local ai=setmetatable({get_character=function()return victim end,mail=0,
    on_be_human_kill=function(s)s.mail=s.mail+1 end,leave_team_follow_after_die=function()end,
    relase_pet_after_die=function()end,can_relive_after_die=function()end,pentalty_after_die=function()end},{__index=env.human})
for _,mode in ipairs({'missing','self','monster','orphan_pet'})do
    killer=mode=='self' and victim or mode=='monster' and {get_obj_type=function()return 'monster' end}
        or mode=='orphan_pet' and {get_obj_type=function()return 'pet' end,get_owner=function()end} or nil
    ai:add_killer_pk_value(1);ai:on_be_kill(1);eq(ai.mail,0,mode..' is not PvP')
    eq(ai:is_counter_killed(victim,1),false)
    eq(ai:pentalty_type_after_die(1),10+define.ENUM_HUMAN_DIE_TYPE.HUMAN_DIE_TYPE_MONSTER_KILL)
    ai:after_die(1)
end
killer={pk=0,get_obj_type=function()return 'human' end,get_pk_value=function(s)return s.pk end,
    set_pk_value=function(s,v)s.pk=v end,is_in_pk_declaration_list=function()return false end}
ai:add_killer_pk_value(2);eq(killer.pk,1,'real murderer still gains PK')
ai:on_be_kill(2);eq(ai.mail,1)
env=setmetatable({human={},define=define},{__index=_G})
grab('GameServer/services/scene/obj/human.lua','human:is_enemy_human',env)
local function player(party,kind)
    local h={party=party,kind=kind,db={get_attrib=function(_,key)return key=='pvp_rule' and 2 or 10 end,
        get_db_attrib=function()return define.PK_MODE.PERSONAL end},get_level=function()return 100 end,
        get_team_id=function(s)return s.party end,get_scene=function(s)return{get_type=function()return s.kind end}end}
    for _,method in ipairs({'is_attackers','is_in_pk_declaration_list','is_wild_war_guild','is_enemy_camp'})do h[method]=function()return false end end
    return setmetatable(h,{__index=env.human})
end
for _,kind in ipairs({0,1,4})do
    local h,other=player(10,kind),player(10,kind)
    eq(h:is_enemy_human(h),false,'never attack self')
    eq(h:is_enemy_human(other),kind==0,'same-party instance shield')
    other.party=11;eq(h:is_enemy_human(other),true,'other party follows scene PK rules')
    h.party=-1;other.party=-1;eq(h:is_enemy_human(other),true,'two solo players are not a party')
end
print('PASS self/environment death, missing killer, real murderer, party protection in both instance types')
print('PASS '..n..' assertions (isolated actual-source regression; not GUI certification)')
