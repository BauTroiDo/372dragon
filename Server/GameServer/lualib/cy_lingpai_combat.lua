-- Native StdImpact151 selects the proc; CY RSSkill supplies each rank's values.
-- New data indices keep unrelated users of the donor rows unchanged.
local data=require 'cy_equipment_skill_data'
local M={effects={}}
local function copy(t)local r={};for k,v in pairs(t)do r[k]=type(v)=='table' and copy(v) or v end;return r end
local function sorted(t)local a={};for k in pairs(t)do a[#a+1]=k end;table.sort(a);return a end
-- Human actors can use the index without owning the scene's config loader.
do
    local id=64100
    for _,group in ipairs(sorted(data.rl_specs))do
        M.effects[group]={}
        for star,spec in ipairs(data.rl_specs[group])do
            local ids={};for i=1,group==16 and 6 or 1 do ids[i]=id;id=id+1 end
            M.effects[group][star]={ids=ids,target=({[5]=true,[12]=true,[17]=true,[19]=true,[21]=true,[22]=true,[24]=true})[group] or false,cooldown=spec.cooldown}
        end
    end
end
function M.install(config)
    local nextid=64100;M.effects={}
    local function clone(source)
        local row=copy(assert(config[source],source));local id=nextid;nextid=nextid+1
        assert(id<65535 and (not config[id] or config[id].cy_lingpai),'LingPai impact ID collision: '..id)
        row.id=id;row.cy_lingpai=true;row.fade_out_when_unit_offline=true
        config[id]=row;return row
    end
    for _,group in ipairs(sorted(data.rl_specs))do
        M.effects[group]={}
        for star,spec in ipairs(data.rl_specs[group])do
            local root=assert(config[spec.source]);assert(root.logic_id==151)
            local p=root.params;local list={};local target=p['类型']==2
            local count=group==16 and 6 or 1
            for channel=1,count do
                local source=group==16 and p['子效果'..channel] or p['给自己buff'] or p['给目标buff']
                local row=clone(assert(source));local a=row.params
                if spec.duration then row.continuance=spec.duration end
                if group<=4 then a[({'冰系攻击修正','火系攻击修正','电系攻击修正','毒系攻击修正'})[group]]=spec.value
                elseif group==5 then a['命中率调整百分比']=spec.value
                elseif group==6 then a['闪避率调整百分比']=spec.value
                elseif group>=7 and group<=10 then row.logic_id=7991;a.cy_convert=group-6
                elseif group==11 then a['会心防御+']=spec.value
                elseif group==13 then a['护体生命值']=spec.value
                elseif group==15 then a['怒气增长修正']=spec.value
                elseif group==16 then
                    a={};row.params=a
                    for i,key in ipairs({'外功伤害免疫标记','内功伤害免疫标记','冰伤害免疫标记','火伤害免疫标记','电伤害免疫标记','毒伤害免疫标记'})do a[key]=i==channel and 1 or 0 end
                elseif group==17 then row.interval=1000;assert(config[a['子效果1数据索引']].params['伤害数值+']==spec.value)
                elseif group==21 or group==24 then row.logic_id=7991;a.cy_heal_reduction=group==24 and 100 or spec.value
                elseif group==23 then row.logic_id=7991;a.cy_critical=2
                end
                list[#list+1]=row.id
            end
            M.effects[group][star]={ids=list,target=target,cooldown=spec.cooldown}
        end
    end
end
function M.proc(human,target,skill_id,random,now)
    if not skill_id or skill_id<1 or not human.get_equip_container or not target then return false end
    local item=human:get_equip_container():get_item(20)
    if not item or not data.tables.RLBase[item:get_index()]then return false end
    local state=require('cy_lingpai').decode(item:get_item_creator())
    if not state or state.group==0 or state.group==12 or state.group==14 then return false end
    local spec=M.effects[state.group] and M.effects[state.group][state.star]
    if not spec then return false end
    now=now or require('skynet').time()
    -- Shared persisted cooldown prevents equip/relog/switch from resetting a proc.
    if now<(tonumber(human.mission_data.cy_rl_ready_at) or 0)then return false end
    random=random or math.random
    if random(100)>21 then return false end -- native rand()%100 < 0x15
    local engine=human:get_scene():get_impact_enginer()
    local id=spec.ids[#spec.ids==1 and 1 or random(#spec.ids)]
    local deadline=now+spec.cooldown/1000
    human.mission_data.cy_rl_ready_at=deadline -- reserve before the queued event
    local ok=engine:send_impact_to_unit(spec.target and target or human,id,human,0,false,0,-1)
    if not ok then human.mission_data.cy_rl_ready_at=now end
    return ok
end
return M
