-- CY equipment skills: validated item identity, table-driven rolls, one-shot replacement.
local data = require 'cy_equipment_skill_data'
local config = require('configenginer'):getinstance()
local packets = require 'game.packet'
local M = {}
local levels = {40,70,90}
local function integer(n) return type(n)=='number' and n==math.floor(n) end
local function copy3(a) return {a[1],a[2],a[3]} end
local function guid(item)
    local g=item:get_guid()
    if type(g)~='table' or not g.series or g.series==0 then return nil end
    return table.concat({g.world or 0,g.server or 0,g.mask or 0,g.series},':')
end
local function snapshot(item,kind)
    local ed=item:get_equip_data()
    if kind==18 then
        return {guid=guid(item),id=item:get_index(),level=ed:get_wh_level(),grow=ed:get_wh_grow_rate(),skills=copy3(ed:get_wh_skill())}
    end
    return {guid=guid(item),id=item:get_index(),level=ed:get_aq_xiulian(),grow=ed:get_aq_grow_rate(),
        skills={ed:get_aq_skill(1),ed:get_aq_skill(2),ed:get_aq_skill(3)}}
end
function M.item(host,selfId,pos,kind)
    if not integer(pos) or pos<0 or pos>254 then return nil end
    local human=host.scene:get_obj_by_id(selfId)
    if not human then return nil end
    local item=human:get_prop_bag_container():get_item(pos)
    if not item or item:get_serial_class()~=1 or item:is_lock() then return nil end
    local base=item:get_base_config()
    if not base or base.equip_point~=kind or not guid(item) then return nil end
    if host:IsPilferLockFlag(selfId) then return nil end
    return item,human
end
function M.wuhun_valid(skill,slot)
    local def=data.wuhun_skills[skill]
    return def and (not slot or def.slot==slot) and config:get_config('skill_template')[skill]~=nil
end
function M.wuhun_roll(slot,level,random)
    local pool=data.wuhun_pools[slot]
    if not pool or not integer(level) or level<1 then return nil end
    local id=pool[(random or math.random)(#pool)]
    local rows=config:get_config('kfs_skill_level_up')
    for _=2,level do
        local row=rows[id]
        if not row or row.next<0 then return nil end
        id=row.next
    end
    return M.wuhun_valid(id,slot) and id or nil
end
function M.dark_kind(slot,impact)
    for kind,row in ipairs(data.dark_types[slot] or {}) do
        for _,id in ipairs(row)do if id==impact then return kind end end
    end
end
function M.dark_effect(slot,level,kind,random)
    if not integer(slot) or not levels[slot] or level<levels[slot] then return nil end
    if not kind then
        local weights=data.dark_weights[slot];local total=0
        for _,weight in pairs(weights)do total=total+weight end
        local roll=(random or math.random)(total)
        -- Stable iteration makes exhaustive probability checks reproducible.
        for candidate=1,#data.dark_types[slot] do
            roll=roll-(weights[candidate] or 0)
            if roll<=0 then kind=candidate;break end
        end
    end
    local row=data.dark_types[slot][kind]
    local id=row and row[math.min(16,math.floor(level/10))]
    return id and config:get_config('std_impact_config')[id] and id or nil
end
function M.prepare(host,selfId,pos,kind)
    local item,human=M.item(host,selfId,pos,kind)
    if not item then return nil end
    local before=snapshot(item,kind)
    if not integer(before.level) or before.level<40 then return nil end
    local skills={kind==18 and -1 or 0,kind==18 and -1 or 0,kind==18 and -1 or 0}
    for i,required in ipairs(levels)do
        if before.level>=required then
            if kind==18 then
                local old=before.skills[i];local olddef=data.wuhun_skills[old]
                if old~=-1 and (not olddef or olddef.slot~=i) then return nil end
                skills[i]=M.wuhun_roll(i,olddef and olddef.level or 1)
            else
                skills[i]=M.dark_effect(i,before.level)
            end
            if not skills[i] then return nil end
        end
    end
    return {version=1,kind=kind,before=before,skills=skills},human
end
function M.publish(human,pos,pending)
    local msg
    if pending.kind==18 then
        human:set_temp_wh_skills(pending)
        msg=packets.GCRefreshKFSSkill.new();msg.bag_index=pos
    else
        human:set_temp_aq_skills(pending)
        msg=packets.GCRefreshDarkSkill.new();msg.bag_pos=pos
    end
    msg.skills=copy3(pending.skills)
    human:get_scene():send2client(human,msg)
    return true
end
function M.generate(host,selfId,pos,kind)
    local pending,human=M.prepare(host,selfId,pos,kind)
    if not pending then return false end
    return M.publish(human,pos,pending)
end
function M.replace(host,selfId,pos,kind)
    local item,human=M.item(host,selfId,pos,kind)
    if not item then return false end
    return human:cy_replace_equipment_skill_roll(pos,kind)
end
function M.commit_replace(human,pos,kind)
    if (kind~=17 and kind~=18) or not integer(pos) or pos<0 or pos>254 then return false end
    local item=human:get_prop_bag_container():get_item(pos)
    if not item or item:is_lock() or item:get_serial_class()~=1 or item:get_base_config().equip_point~=kind then return false end
    local pending=kind==18 and human:get_temp_wh_skills() or human:get_temp_aq_skills()
    if type(pending)~='table' or pending.version~=1 or pending.kind~=kind then return false end
    local now=snapshot(item,kind);local before=pending.before
    if not before or now.guid~=before.guid or now.id~=before.id or now.level~=before.level or now.grow~=before.grow then return false end
    for i=1,3 do
        if now.skills[i]~=before.skills[i] then return false end
        local skill=pending.skills[i]
        if kind==18 then
            if skill~=-1 and not M.wuhun_valid(skill,i) then return false end
        elseif skill~=0 and not M.dark_kind(i,skill) then return false end
    end
    -- Clear BEFORE mutating/sending: a duplicate packet cannot apply the result twice.
    if kind==18 then human:set_temp_wh_skills(nil) else human:set_temp_aq_skills(nil) end
    for i=1,3 do
        if kind==18 then item:get_equip_data():set_wh_skill(i,pending.skills[i])
        else item:get_equip_data():set_aq_skill(i,pending.skills[i]) end
    end
    local msg=packets.GCItemInfo.new();msg.bagIndex=pos;msg.item=item:copy_raw_data()
    human:get_scene():send2client(human,msg)
    return true
end
function M.paid_roll(host,selfId,pos,kind,materials,cost)
    local pending,human=M.prepare(host,selfId,pos,kind)
    if not pending then host:notify_tips(selfId,'Vật phẩm hoặc kỹ năng chưa đủ điều kiện tẩy.');return false end
    if host:GetMoney(selfId)+host:GetMoneyJZ(selfId)<cost then
        host:notify_tips(selfId,'Không đủ kim tiền.');return false
    end
    -- One RPC enters the owning human actor. Revalidate and commit both costs there,
    -- avoiding the yield between separate remote material and money mutations.
    return human:cy_commit_equipment_skill_roll(pos,pending,materials,cost)
end
function M.commit_roll(human,pos,pending,materials,cost)
    local itemlogic=require 'human_item_logic'
    if type(pending)~='table' or pending.version~=1 or (pending.kind~=17 and pending.kind~=18) then return false end
    local bag=human:get_prop_bag_container();local item=bag:get_item(pos)
    if not item or item:is_lock() or item:get_serial_class()~=1 or item:get_base_config().equip_point~=pending.kind then return false end
    local now=snapshot(item,pending.kind);local before=pending.before
    if not before or now.guid~=before.guid or now.id~=before.id or now.level~=before.level or now.grow~=before.grow then return false end
    for i=1,3 do if now.skills[i]~=before.skills[i] then return false end end
    if not integer(cost) or cost<1 or human:get_money()+human:get_jiaozi()<cost then return false end
    local wanted={};for _,id in ipairs(materials)do wanted[id]=true end
    local material_pos,material_id
    for _,page in ipairs({'prop','material'})do
        for p,mat in bag:ipairs(page)do
            if mat and wanted[mat:get_index()] and not mat:is_lock() and mat:get_lay_count()>=1 then
                material_pos,material_id=p,mat:get_index();break
            end
        end
        if material_pos then break end
    end
    if not material_pos then human:notify_tips('Không đủ nguyên liệu hợp lệ hoặc nguyên liệu đang khóa.');return false end
    -- The local bag decrement and money writes do not yield in the human actor.
    if not itemlogic:dec_item_lay_count({reason='cy_equipment_skill_roll'},human,material_pos,1,material_id) then return false end
    human:cost_money_with_priority(cost,'cy_equipment_skill_roll')
    return M.publish(human,pos,pending)
end
return M
