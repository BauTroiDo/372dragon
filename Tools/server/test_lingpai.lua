local root,stage=assert(arg[1]),assert(arg[2])
package.path=stage..'/GameServer/lualib/?.lua;'..stage..'/GameServer/services/?.lua;'..root..'/GameServer/lualib/?.lua;'..root..'/GameServer/services/?.lua;'..package.path
package.cpath=root..'/GameServer/luaclib/?.so;'..package.cpath
local say,quiet=print,function()end
package.loaded.skynet={getenv=function(k)if k=='config_path'then return root..'/configs/%s'end end,logd=quiet,logi=quiet,logw=quiet,loge=quiet,error=quiet,log=quiet}
package.loaded['skynet.manager']={};package.loaded['skynet.sharetable']={};table.tostr=function()return ''end
local cfg=require('cfghelper').new();print=quiet;cfg:read_std_impact();print=say
local data=require 'cy_equipment_skill_data';local combat=require 'cy_lingpai_combat';local helper=require 'cy_lingpai'
local pass,fail=0,0
local function check(name,ok)if ok then pass=pass+1 else fail=fail+1 end;say((ok and 'PASS' or 'FAIL')..'\t'..name)end
local original=cfg.std_impact_config[12076].params['命中率调整百分比']
combat.install(cfg.std_impact_config)
check('negative_control_donor_is_not_CY',original==-10 and cfg.std_impact_config[combat.effects[5][1].ids[1]].params['命中率调整百分比']==-1)
local projected,roundtrips=0,0
for group,ranks in pairs(data.rl_specs)do for star,spec in ipairs(ranks)do
    local state=helper.decode('&LP'..star..string.rep('0',18)..string.char(64+group))
    if state and state.star==star and state.group==group then roundtrips=roundtrips+1 end
    local effect=combat.effects[group][star]
    local good=effect.cooldown==spec.cooldown
    for _,id in ipairs(effect.ids)do
        local row=cfg.std_impact_config[id]
        good=good and row and (not spec.duration or row.continuance==spec.duration)
    end
    if good then projected=projected+1 end
end end
check('207_ranks_duration_and_cooldown',projected==207)
check('207_item_state_roundtrips',roundtrips==207)
check('malformed_and_missing_group_18',not helper.decode('&LP00000000000000000000') and not helper.decode('&LP1000000000000000000R'))
check('donor_rows_unchanged',cfg.std_impact_config[12076].params['命中率调整百分比']==original)
local sent,used,item,book,human,bag,procid,proctarget
local function reset(group,star)
    sent,used,procid,proctarget=0,0,nil,nil
    item={id=10158005,creator='&LP'..(star or 1)..string.rep('0',18)..(group and string.char(64+group) or '0'),
        get_index=function(self)return self.id end,is_lock=function(self)return self.locked end,
        get_item_creator=function(self)return self.creator end,set_item_creator=function(self,v)self.creator=v end,
        get_equip_data=function()return {set_equip_type=quiet}end,copy_raw_data=function(self)return {creator=self.creator}end}
    book={id=38000971,n=1,get_index=function(self)return self.id end,is_lock=function(self)return self.locked end,get_lay_count=function(self)return self.n end}
    bag={get_item=function(_,pos)return pos==0 and item or pos==1 and book end}
    local engine={send_impact_to_unit=function(_,target,id)sender=human;proctarget=target;procid=id;return true end}
    human={money=100000,mission_data={},get_prop_bag_container=function()return bag end,
        get_equip_container=function()return {get_item=function(_,slot)return slot==20 and item end}end,
        get_money=function(self)return self.money end,get_jiaozi=function()return 0 end,
        cost_money_with_priority=function(self,n)self.money=self.money-n end,notify_tips=quiet,
        get_scene=function()return {send2client=function(_,_,msg)sent=sent+1;if msg.item then assert(msg.bagIndex==0)end end,get_impact_enginer=function()return engine end}end}
end
package.loaded['game.packet']=setmetatable({},{__index=function()return {new=function()return {}end}end})
package.loaded.human_item_logic={dec_item_lay_count=function(_,logparam,who,pos,n,id)
    assert(type(logparam)=='table','human_item_logic requires logparam even after removing the item')
    assert(who==human and pos==1 and n==1 and id==book.id);used=used+1;book.n=book.n-1;return true end}
reset();check('unlearned_rejected_no_cost',not helper.switch(human,0,7) and human.money==100000)
check('learn_consumes_one_book',helper.learn(human,1) and used==1 and helper.learned(human,7))
book.n=1;check('duplicate_book_not_consumed',not helper.learn(human,1) and used==1)
check('switch_learned_cost_100000',helper.switch(human,0,7) and human.money==0 and helper.decode(item.creator).group==7)
reset();book.locked=true;check('locked_book',not helper.learn(human,1) and used==0)
for _,group in ipairs({12,14})do
    reset();local found=false
    for id,row in pairs(data.tables.RLSkillBook)do if row[2]==group then book.id=id;found=true;break end end
    check('unsupported_book_'..group..'_preserved',found and not helper.learn(human,1) and used==0 and book.n==1 and not helper.learned(human,group))
end
reset();item.locked=true;check('locked_token',not helper.switch(human,0,1) and human.money==100000)
reset();item.id=10158004;check('grade4_rejected',not helper.switch(human,0,1) and human.money==100000)
reset();human.money=99999;check('insufficient_money',not helper.switch(human,0,1) and human.money==99999)
reset();check('wrong_slot',not helper.switch(human,1,1) and not helper.switch(human,-1,1))
check('unknown_and_unverified_groups',not helper.switch(human,0,18) and not helper.switch(human,0,12) and not helper.switch(human,0,14) and human.money==100000)
reset(1);local draws=0
for roll=1,100 do human.mission_data.cy_rl_ready_at=0;if combat.proc(human,{},1,function()return roll end,1000)then draws=draws+1 end end
check('native_proc_21_of_100',draws==21)
reset(5);local target={};check('target_proc',combat.proc(human,target,1,function()return 1 end,1000) and proctarget==target)
check('cooldown_reservation_blocks_same_tick',not combat.proc(human,target,1,function()return 1 end,1000))
check('cooldown_boundary',not combat.proc(human,target,1,function()return 1 end,1029.999) and combat.proc(human,target,1,function()return 1 end,1030))
local saved=human.mission_data;reset(5);human.mission_data=saved
check('relogin_and_switch_cannot_reset_cooldown',not combat.proc(human,target,1,function()return 1 end,1031))
reset(1);human.get_equip_container=function()return {get_item=function()end}end
check('unequipped_no_proc',not combat.proc(human,target,1,function()return 1 end,1000))
reset(1);check('proc_damage_does_not_recurse',not combat.proc(human,target,-1,function()return 1 end,1000))
reset(16,9);for channel=1,6 do
    human.mission_data.cy_rl_ready_at=0;combat.proc(human,target,1,function(n)return n==100 and 1 or channel end,1000)
    local p=cfg.std_impact_config[procid].params;local count=0;for _,v in pairs(p)do count=count+v end
    check('immunity_channel_'..channel,count==1)
end
local base=require('class')('test_base');function base:mark_modified_attr_dirty()end
package.loaded['scene.skill.impact_logic.base']=base
local buff=require('scene.skill.impact_logic.cy_lingpai_buff').new()
local values={100,200,300,400};local names={'cold','fire','light','poison'};local who={}
for i,name in ipairs(names)do who['get_attack_'..name]=function()return values[i]end end
for selected=1,4 do
    local imp={params={cy_convert=selected}};buff:on_active(imp,who)
    local sum=0;local good=true
    for i,name in ipairs(names)do local args={point=0};buff['get_refix_att_'..name](buff,imp,args);local v=values[i]+args.point;sum=sum+v;good=good and v==(i==selected and 1000 or 0)end
    check('conversion_conserves_total_'..selected,good and sum==1000)
end
for _,rate in ipairs({20,60,100})do local health={hp_modify=1000};buff:on_be_heal({params={cy_heal_reduction=rate}},nil,nil,health,1);check('healing_reduction_'..rate,health.hp_modify==1000*(100-rate)/100)end
local health={hp_modify=1000};buff:on_be_heal({params={cy_heal_reduction=100}},nil,nil,health,-1);check('food_control',health.hp_modify==1000)
local imp={params={cy_critical=2}};local removed=0;local actor={on_impact_fade_out=quiet,remove_impact=function()removed=removed+1 end};local hit={get_caster_logic_count=function()return 1 end}
check('guaranteed_critical',buff:refix_critical_rate(imp,0.05)==1)
buff:on_damage_target(imp,actor,nil,{},1,hit);buff:on_damage_target(imp,actor,nil,{},1,hit)
check('aoe_targets_count_as_one_attack',imp.params.cy_critical==1 and removed==0)
hit.get_caster_logic_count=function()return 2 end;buff:on_damage_target(imp,actor,nil,{},1,hit)
check('second_attack_expires',removed==1 and buff:refix_critical_rate(imp,0.05)==0.05)
say(('SUMMARY pass=%d fail=%d'):format(pass,fail));os.exit(fail==0 and 0 or 1)
