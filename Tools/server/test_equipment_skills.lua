-- No live accounts: real CY tables + production helper, inventory/transport fixtures.
local root=assert(arg[1]);local stage=assert(arg[2])
package.path=stage..'/GameServer/lualib/?.lua;'..root..'/GameServer/lualib/?.lua;'..package.path
package.cpath=root..'/GameServer/luaclib/?.so;'..package.cpath
local say=print;local quiet=function()end
package.loaded.skynet={getenv=function(k)if k=='config_path' then return root..'/configs/%s' end end,logd=quiet,logi=quiet,logw=quiet,loge=quiet,error=quiet,log=quiet}
package.loaded['skynet.manager']={};package.loaded['skynet.sharetable']={};table.tostr=function()return '' end
local cfg=require('cfghelper').new();local configs={}
for _,name in ipairs({'skill_template','std_impact'})do print=quiet;cfg['read_'..name](cfg);print=say end
configs.skill_template=cfg.skill_template;configs.std_impact_config=cfg.std_impact_config
local data=require 'cy_equipment_skill_data'
configs.kfs_skill_level_up={}
for id,def in pairs(data.wuhun_skills)do configs.kfs_skill_level_up[id]={level=def.level,next=def.level<6 and id+1 or -1}end
package.loaded.configenginer={getinstance=function()return {get_config=function(_,n)return assert(configs[n],n)end}end}
local sent=0
package.loaded['game.packet']=setmetatable({},{__index=function()return {new=function()return {}end}end})
local helper=require 'cy_equipment_skills'
local pass,fail=0,0
local function check(name,ok,details)
    if ok then pass=pass+1 else fail=fail+1 end
    say((ok and 'PASS' or 'FAIL')..'\t'..name..'\t'..(details or ''))
end
local missing={}
for id,def in pairs(data.wuhun_skills)do if not helper.wuhun_valid(id,def.slot)then missing[#missing+1]=id end end
check('all_294_CY_KFS_templates_exist',#missing==0,table.concat(missing,','))
check('reject_GL_event_skills',not helper.wuhun_valid(3669) and not helper.wuhun_valid(4973))
for slot,pool in ipairs(data.wuhun_pools)do
    local ok=true
    for n,id in ipairs(pool)do for rank=1,6 do local got=helper.wuhun_roll(slot,rank,function()return n end);ok=ok and got==id+rank-1 end end
    check('KFS_pool_'..slot..'_all_roots_and_levels',ok)
end
for slot,weights in ipairs(data.dark_weights)do
    local total=0;for _,w in pairs(weights)do total=total+w end
    local counts={};local absent={};local lev=({40,70,90})[slot]
    for draw=1,total do
        local id=helper.dark_effect(slot,lev,nil,function()return draw end)
        local kind=id and helper.dark_kind(slot,id)
        if kind then counts[kind]=(counts[kind] or 0)+1 else absent[draw]=true end
    end
    local ok=next(absent)==nil
    for kind,w in pairs(weights)do ok=ok and counts[kind]==w end
    check('dark_weight_distribution_'..slot,ok,'draws='..total)
    local valid=true;local bad={}
    for kind,row in ipairs(data.dark_types[slot])do
        for level=lev,160,10 do if not helper.dark_effect(slot,level,kind) then valid=false;bad[#bad+1]=row[math.floor(level/10)] end end
    end
    check('dark_effects_exist_'..slot,valid,table.concat(bad,','))
    check('dark_below_threshold_'..slot,helper.dark_effect(slot,lev-1)==nil)
end
local items,ed,human,host,bag
local function reset(kind,level)
    sent=0;ed={skills=kind==18 and {-1,-1,-1} or {0,0,0},level=level,grow=600,writes=0}
    function ed:get_wh_level()return self.level end
    function ed:get_aq_xiulian()return self.level end
    function ed:get_wh_grow_rate()return self.grow end
    function ed:get_aq_grow_rate()return self.grow end
    function ed:get_wh_skill()return self.skills end
    function ed:get_aq_skill(i)return self.skills[i] end
    function ed:set_wh_skill(i,v)self.skills[i]=v;self.writes=self.writes+1 end
    ed.set_aq_skill=ed.set_wh_skill
    items={}
    local function make(serial)
        return {get_guid=function()return {world=1,server=1,series=serial}end,get_index=function()return kind==18 and 10156001 or 10155001 end,
            get_serial_class=function()return 1 end,is_lock=function(self)return self.locked end,
            get_base_config=function()return {equip_point=kind}end,get_equip_data=function()return ed end,copy_raw_data=function()return {}end}
    end
    items[0]=make(10);items[1]=make(11)
    bag={get_item=function(_,p)return items[p]end,ipairs=function()return next,{},nil end}
    human={money=100000,jiaozi=0,get_prop_bag_container=function()return bag end,
        get_scene=function()return {send2client=function()sent=sent+1 end}end,
        set_temp_wh_skills=function(self,p)self.pending=p end,get_temp_wh_skills=function(self)return self.pending end,
        set_temp_aq_skills=function(self,p)self.pending=p end,get_temp_aq_skills=function(self)return self.pending end,
        get_money=function(self)return self.money end,get_jiaozi=function(self)return self.jiaozi end,
        notify_tips=quiet,cost_money_with_priority=function(self,n)self.money=self.money-n end}
    host={scene={get_obj_by_id=function()return human end},IsPilferLockFlag=function()return false end,notify_tips=quiet,
        GetMoney=function()return human.money end,GetMoneyJZ=function()return human.jiaozi end}
    function human:cy_commit_equipment_skill_roll(...)return helper.commit_roll(self,...)end
    function human:cy_replace_equipment_skill_roll(...)return helper.commit_replace(self,...)end
end
for _,kind in ipairs({17,18})do
    reset(kind,90)
    check(kind..'_no_pending',not helper.replace(host,1,0,kind) and ed.writes==0)
    check(kind..'_valid_roll',helper.generate(host,1,0,kind) and sent==1)
    check(kind..'_wrong_instance',not helper.replace(host,1,1,kind) and ed.writes==0)
    ed.level=91;check(kind..'_changed_level',not helper.replace(host,1,0,kind) and ed.writes==0);ed.level=90
    items[0].locked=true;check(kind..'_locked',not helper.replace(host,1,0,kind) and ed.writes==0);items[0].locked=false
    check(kind..'_replace_once',helper.replace(host,1,0,kind) and ed.writes==3)
    check(kind..'_replay',not helper.replace(host,1,0,kind) and ed.writes==3)
    reset(kind,39);check(kind..'_underlevel',not helper.generate(host,1,0,kind) and sent==0)
    reset(kind,90);check(kind..'_empty',not helper.generate(host,1,254,kind) and sent==0)
    local consumed=0;package.loaded.human_item_logic={dec_item_lay_count=function()consumed=consumed+1;return true end}
    check(kind..'_no_material',not helper.paid_roll(host,1,0,kind,{123},50000) and human.money==100000 and consumed==0)
    local mat={get_index=function()return 123 end,is_lock=function()return false end,get_lay_count=function()return 1 end}
    bag.ipairs=function()return next,{[2]=mat},nil end
    human.money=49999
    check(kind..'_no_money',not helper.paid_roll(host,1,0,kind,{123},50000) and consumed==0)
    human.money=100000
    check(kind..'_paid_valid',helper.paid_roll(host,1,0,kind,{123},50000) and human.money==50000 and consumed==1)
end
say(string.format('SUMMARY pass=%d fail=%d',pass,fail));os.exit(fail==0 and 0 or 1)
