-- CY automatic combat, using the normal server AI/skill/item path.
-- Never edits HP, EXP, item counts or cooldowns directly.
local M={UI=990026}
local data=require 'cys_assist_data'
local define=require 'define'
local skynet=require 'skynet'
local configenginer=require 'configenginer':getinstance()
local sizes={17,3,3,3,4,6,10,3,3,3,3}
local function integer(v,a,b) return type(v)=='number' and v%1==0 and v>=a and v<=b end
function M.defaults()
    return {{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},{0,0,0},{1,1,1},{50,50,50},
        {50,50,50,50},{1,1,50,50,0,0},{1,1,0,0,0,0,0,0,0,0},{0,0,0},{1,1,1},{50,50,50},{0,0,0}}
end
function M.config(h)
    if not h.cys_assist then h.cys_assist=M.defaults() end
    return h.cys_assist
end
local function emit(s,h,values)
    s:BeginUICommand();for _,v in ipairs(values) do s:UICommand_AddInt(v) end
    s:EndUICommand();s:DispatchUICommand(h:get_obj_id(),M.UI)
end
function M.snapshot(s,h)
    h.cys_assist_revision=h.cys_assist_revision or 1
    local cfg=M.config(h)
    emit(s,h,{0,h.cys_assist_revision,h.cys_assist_active and 1 or 0})
    for k,row in ipairs(cfg) do
        for offset=1,#row,8 do
            local v={k,offset};for i=offset,math.min(offset+7,#row) do v[#v+1]=row[i] end
            emit(s,h,v)
        end
    end
    emit(s,h,{12,h.cys_assist_revision})
end
function M.begin(s,h,revision)
    if revision~=(h.cys_assist_revision or 1) then return M.snapshot(s,h) end
    h.cys_assist_pending={revision=revision,at=os.time(),rows={}}
end
function M.chunk(s,h,revision,k,offset,...)
    local p=h.cys_assist_pending
    if not p or p.revision~=revision or os.time()-p.at>10 or not integer(k,1,11)
        or not integer(offset,1,sizes[k]) then return end
    local values={...};if #values<1 or #values>8 or offset+#values-1>sizes[k] then return end
    p.rows[k]=p.rows[k] or {}
    for i,v in ipairs(values) do
        local index=offset+i-1
        local max=(k==1 or k==3 or k==7 or k==9) and 1 or 100
        if k==2 or k==8 then max=100 end -- potion-list index; 0 is the native "do not use" entry
        if k==6 then max=index<=2 and 1 or index<=4 and 100 or 1 end
        if k==11 then max=index==3 and 200 or 9999999 end
        if not integer(v,0,max) then p.invalid=true;return end
        p.rows[k][index]=v
    end
end
function M.commit(s,h,revision)
    local p=h.cys_assist_pending;h.cys_assist_pending=nil
    if not p or p.invalid or p.revision~=revision or revision~=(h.cys_assist_revision or 1) or os.time()-p.at>10 then return M.snapshot(s,h) end
    for k,n in ipairs(sizes) do for i=1,n do if not p.rows[k] or p.rows[k][i]==nil then return M.snapshot(s,h) end end end
    h.cys_assist=p.rows;h.cys_assist_revision=revision%2147483646+1
    M.snapshot(s,h)
end
function M.stop(h,reason)
    if not h.cys_assist_active then return end
    h.cys_assist_active=nil;h.zdzd_enabled=nil
    if M.config(h)[7][5]==1 then
        h:get_double_exp_info().is_lock=true;h:send_double_exp_info()
    end
    local ai=h:get_ai()
    ai.param_ai_use_skill={auto_use_skill=-1,queued_skill=-1,auto_shoot_target_obj_id=-1};ai.param_use_item={bagindex=-1};h:set_locked_target(-1)
    ai:stop();ai:change_state(h:is_die() and 'dead' or 'idle')
    if h.cys_assist_script then M.snapshot(h.cys_assist_script,h) end
    if reason then h:notify_tips(reason) end
end
function M.start(s,h,revision)
    if revision~=(h.cys_assist_revision or 1) or h:is_die() or h:get_level()<50
        or h:get_menpai()==9 or h:get_team_follow_flag() or h._leaving then
        h:notify_tips('Tự chiến đấu cần cấp 50, đã gia nhập môn phái và không theo đội.');return M.snapshot(s,h)
    end
    h.cys_assist_script=s;h.cys_assist_active=true;h.zdzd_enabled=nil
    h.cys_assist_origin=h:get_scene():get_id();h.cys_assist_tick=0;h.cys_assist_buff={}
    h.cys_assist_script=s;M.snapshot(s,h)
end
local function ready(h,id)
    return h:have_skill(id) and h:is_skill_cool_down(id) and h:can_use_this_skill_in_this_status(id)
end
local function cast(h,id,target)
    if not target or not ready(h,id) then return false end
    local p=target:get_world_pos()
    local ret=h:get_ai():push_command_use_skill(id,target:get_obj_id(),p.x,p.y,0,target:get_guid(),0,0,0)
    return ret==define.OPERATE_RESULT.OR_OK
end
local function ratio(h,kind)
    if kind==2 then return h:get_mp()*100/math.max(1,h:get_max_mp()) end
    return h:get_hp()*100/math.max(1,h:get_max_hp())
end
local function use_item(h,index,target)
    local item=h:get_prop_bag_container():get_item(index)
    if not item or item:is_lock() or item:get_lay_count()<=0 then return false end
    local guid=target:get_obj_type()=='pet' and target:get_guid() or {m_uHighSection=0,m_uLowSection=0}
    h:get_scene():char_use_item(h:get_obj_id(),{bagIndex=index,item_index=item:get_index(),
        target_obj_id=target:get_obj_id(),target_pos=target:get_world_pos(),pet_guid=guid,target_bag_index=-1})
    return true
end
local function potion(h,cfg,off)
    local pet=h:get_pet();local enabled=cfg[off and 9 or 3];local threshold=cfg[off and 10 or 4];local choice=cfg[off and 8 or 2]
    local bag=h:get_prop_bag_container()
    for kind=1,3 do
        local target=kind==3 and pet or h
        if enabled[kind]==1 and choice[kind]>0 and target and target:is_alive() and ratio(target,kind)<threshold[kind] then
            local candidates={};local n=0
            for _,row in ipairs(data.potions) do if row[3]==kind then
                n=n+1;if choice[kind]==n then candidates[#candidates+1]=row end
            end end
            table.sort(candidates,function(a,b)return a[4]<b[4] end)
            for _,row in ipairs(candidates) do for i=0,99 do
                local item=bag:get_item(i)
                if item and not item:is_lock() and (item:get_index()==row[1] or row[2]>0 and item:get_index()==row[2]) then
                    local skill=item:get_base_config().skill_id
                    if skill and h:is_skill_cool_down(skill) and h:can_use_this_skill_in_this_status(skill) then
                        if use_item(h,i,target) then return true end
                    end
                end
            end end
        end
    end
    return false
end
local function boost(h,cfg)
    local ids={}
    if cfg[7][3]==1 and h:get_double_exp_mult()<2 then ids[30008002]=true;ids[30008027]=true;ids[30505214]=true end
    if cfg[7][4]==1 and h:get_double_exp_mult()>=2 and h:get_pet_exp_mult()<2 then ids[30008003]=true;ids[30008028]=true end
    if not next(ids) or os.time()<(h.cys_assist_boost_at or 0) then return false end
    for i=0,99 do
        local item=h:get_prop_bag_container():get_item(i)
        if item and ids[item:get_index()] and not item:is_lock() then
            h.cys_assist_boost_at=os.time()+10;return use_item(h,i,h)
        end
    end
    return false
end
local function enemies(h,cfg)
    local p=h:get_world_pos();local scene=h:get_scene()
    local near=scene:scan({obj=h,x=p.x,y=p.y,radious=cfg[7][2]==1 and 15 or 25,target_logic_by_stand=1,check_can_view=true}) or {}
    local list={}
    for _,t in ipairs(near) do
        if (t:get_obj_type()=='monster' or cfg[7][1]==0 and t:get_obj_type()=='human') and t:is_alive()
            and h:is_enemy(t) and h:is_can_view(t) then list[#list+1]=t end
    end
    table.sort(list,function(a,b)
        local pa,pb=a:get_world_pos(),b:get_world_pos()
        return (pa.x-p.x)^2+(pa.y-p.y)^2 < (pb.x-p.x)^2+(pb.y-p.y)^2
    end)
    return list
end
function M.tick(h,dt)
    if h._leaving then return M.stop(h) end
    h.cys_assist_tick=(h.cys_assist_tick or 0)+dt
    if h.cys_assist_tick<500 then return end
    h.cys_assist_tick=0
    if not h.cys_assist_active then
        if h.cys_assist and h:is_alive() and not h:get_team_follow_flag() and h:can_use_skill_now() then potion(h,M.config(h),true) end
        return
    end
    if h:get_scene():get_id()~=h.cys_assist_origin then return M.stop(h,'Đã dừng tự chiến đấu khi chuyển bản đồ.') end
    if h:is_die() then
        local cfg=M.config(h);local revive=cfg[7][9]==1
        M.stop(h,'Đã dừng tự chiến đấu vì nhân vật tử vong.')
        if revive then h:get_ai():push_command_die_result(0) end
        return
    end
    if h:get_team_follow_flag() then return M.stop(h,'Đã dừng tự chiến đấu khi theo đội.') end
    local cfg=M.config(h)
    if cfg[7][8]==0 and tonumber(os.date('%H'))>=22 then
        M.stop(h,'Đã tạm dừng tự chiến đấu trong khung giờ 22–24.');cast(h,22,h);return
    end
    if cfg[11][1]>0 and h:get_today_kill_monster_count()>=cfg[11][1] then
        M.stop(h,'Đã đạt số quái giới hạn trong ngày.');cast(h,22,h);return
    end
    if cfg[11][3]>h:get_level() and os.time()>=(h.cys_assist_level_at or 0) then
        local costs=configenginer:get_config('player_exp_level')
        if costs[h:get_level()] and h:get_exp()>=costs[h:get_level()] then
            h.cys_assist_level_at=os.time()+5;h:get_scene():char_req_level_up(h:get_obj_id())
        end
    end
    if not h:can_use_skill_now() or h:is_limit_move() then return end
    if potion(h,cfg,false) then return end
    if boost(h,cfg) then return end
    local pet=h:get_pet()
    if pet and pet:is_alive() then
        for i,ids in ipairs({{686,687},{696,697}}) do
            if cfg[6][i]==1 and ratio(h,i)<cfg[6][i+2] then
                local id=ids[cfg[6][i+4]+1]
                if pet:have_skill(id) and pet:is_skill_cool_down(id) then
                    local p=h:get_world_pos();pet:get_ai():push_command_use_skill(id,h:get_obj_id(),p.x,p.y,0,h:get_guid())
                    return
                end
            end
        end
    end
    local near=enemies(h,cfg);local target=near[1]
    local ai=h:get_ai();local last=h:get_scene():get_obj_by_id(ai.param_ai_use_skill.auto_shoot_target_obj_id or -1)
    if last and last:is_alive() then for _,t in ipairs(near) do if t==last then target=t;break end end end
    local rows={};for _,row in ipairs(data.skills) do if row[4]==h:get_menpai() then rows[#rows+1]=row end end
    -- Recovery first, then eligible area/buff skills, then non-basic attacks.
    local allies={h}
    if h:get_team_id()~=-1 then
        local p=h:get_world_pos()
        for _,t in ipairs(h:get_scene():scan({obj=h,x=p.x,y=p.y,radious=15,target_logic_by_stand=2,check_can_view=true}) or {}) do
            if t~=h and t:get_obj_type()=='human' and t:is_alive() and h:is_partner(t) then allies[#allies+1]=t end
        end
        table.sort(allies,function(a,b)return ratio(a,1)<ratio(b,1) end)
    end
    for _,row in ipairs(rows) do
        if row[5]==5 and row[2]~=407 then
            for _,ally in ipairs(allies) do
                if ratio(ally,1)<cfg[5][math.max(1,math.min(4,row[6]))] and cast(h,row[2],ally) then return end
            end
        end
    end
    if cfg[7][10]==1 then return end
    if not target then return end
    for i,row in ipairs(rows) do
        local id,kind=row[2],row[5];local template=h:get_scene():get_skill_enginer():get_skill_template(id)
        if cfg[1][i]==1 and template and not template.auto_shot_skill_flag and ready(h,id) then
            if kind==2 then
                local origin=row[6]>0 and target:get_world_pos() or h:get_world_pos();local count=0
                for _,t in ipairs(near) do local p=t:get_world_pos();if (p.x-origin.x)^2+(p.y-origin.y)^2<=row[7]^2 then count=count+1 end end
                if count>=row[8] and cast(h,id,target) then return end
            elseif kind==3 then
                local until_time=h.cys_assist_buff[id] or 0
                if os.time()>=until_time and cast(h,id,h) then h.cys_assist_buff[id]=os.time()+row[6];return end
            elseif kind==1 and cast(h,id,target) then return end
        end
    end
    cast(h,ai.auot_shot_skill_id or 0,target)
end
return M
