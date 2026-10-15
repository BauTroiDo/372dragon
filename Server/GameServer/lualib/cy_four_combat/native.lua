-- Behavioral translation of tlbb15 Serverhook.so, SHA256
-- 9e9a371f39003671def2dd75b39bfa7a245d8e02361468b971e17dc899e80151.
-- The context is a strict adapter for native operations, not a gameplay fallback.
-- Parameters are ZERO-BASED and reference values must already be target IDs.
local num = require "cy_four_combat.numeric"
local M = {}
local function need(c, names)
    for _, name in ipairs(names) do
        assert(type(c[name]) == "function", "unbound donor operation: " .. name)
    end
end
local function p(impact, index)
    assert(type(impact.params) == "table", "positional params missing")
    return assert(math.tointeger(impact.params[index]), "descriptor missing: " .. index)
end
local function resolve_all(c, kind, ids)
    need(c, {"resolve"})
    local result = {}
    for i, id in ipairs(ids) do
        result[i] = assert(c:resolve(kind, id), "unmapped " .. kind .. " " .. id)
    end
    return result
end
function M.new_impact(donor_id, params)
    local values = {}
    for i = 0, 15 do values[i] = assert(math.tointeger(params[i]), "descriptor missing: " .. i) end
    return {donor_id = donor_id, params = values, extension_count = 0,
        critical_count = 0, stack = 0, native_34 = 0, power_refix = 0}
end

-- Hook0x6152c, rodata b6b80=.5, b6b84=1e-5, b6b88=1.
function M.in_rectangle(a,b,target,length,width)
    local f=num.f32
    local half=f(f(width)*f(0.5));local limit=f(half*half)
    local dx,dy=f(b.x-a.x),f(b.y-a.y)
    local squared=f(f(dx*dx)+f(dy*dy))
    local tx,ty=f(target.x-a.x),f(target.y-a.y)
    if squared<f(0.00001) then return f(f(tx*tx)+f(ty*ty))<=limit end
    local inverse=f(1/f(math.sqrt(squared)))
    dx,dy=f(dx*inverse),f(dy*inverse)
    local dot=f(f(tx*dx)+f(ty*dy))
    if dot<0 or dot>length then return false end
    local px,py=f(tx-f(dx*dot)),f(ty-f(dy*dot))
    return f(f(px*px)+f(py*py))<=limit
end

-- Main0xa515cc..0xa518de: ELEVEN object slots, including index zero.
function M.tracker_slots(impact)
    if not impact.traps then
        impact.traps={}
        for i=0,10 do impact.traps[i]=-1 end
    end
    return impact.traps
end
function M.tracker_add(c,impact,owner,id)
    need(c,{"get_object","is_special","trap_faded"})
    local slots=M.tracker_slots(impact)
    for i=0,10 do
        local obj=c:get_object(owner,slots[i])
        if not obj or not c:is_special(obj) or c:trap_faded(obj) then slots[i]=id; return true end
    end
    return false
end
function M.tracker_count(c,impact,owner,class_id)
    need(c,{"get_object","is_special","trap_faded","object_trap_record"})
    local all,same=0,0
    for i=0,10 do
        local obj=c:get_object(owner,M.tracker_slots(impact)[i])
        if obj and c:is_special(obj) and not c:trap_faded(obj) then
            local data=c:object_trap_record(obj)
            if data then all=all+1; if data.class==class_id then same=same+1 end
            else impact.traps[i]=-1 end
        end
    end
    return all,same
end
function M.tracker_heartbeat(c,impact,owner)
    need(c,{"get_object","is_special","trap_faded","duration","set_duration","reset_elapsed"})
    local active=0
    for i=0,10 do
        local obj=c:get_object(owner,M.tracker_slots(impact)[i])
        if obj and c:is_special(obj) and not c:trap_faded(obj) then active=active+1
        else impact.traps[i]=-1 end
    end
    if active>0 and c:duration(impact)>=0 then c:set_duration(impact,-1);c:reset_elapsed(impact)
    elseif active==0 and c:duration(impact)==-1 then c:set_duration(impact,10000);c:reset_elapsed(impact) end
    return true
end

-- Hook0x69610/0x6925c/0x6991e: only the two imported skill-swap rows.
local function swap171(impact)
    assert(impact.donor_id==13262 or impact.donor_id==13263,"unported171 source identity")
end
function M.active_171(c,impact,owner)
    need(c,{"has_scene","duration","mission_param_changed","swap_skill","float2int"})
    swap171(impact)
    if not c:has_scene(owner) then return false end
    impact.timer=p(impact,0);impact.last_seconds=0
    c:mission_param_changed(owner,p(impact,1),c:float2int(num.f32(c:duration(impact)/1000)))
    if impact.donor_id==13263 then impact.phase=(impact.phase or 0)+1 end
    c:swap_skill(owner,p(impact,2),p(impact,3),1,0)
    return true
end
function M.fade_171(c,impact,owner)
    need(c,{"is_human","has_scene","mission_param_changed","swap_skill"})
    swap171(impact)
    if not c:is_human(owner) or not c:has_scene(owner) then return false end
    c:mission_param_changed(owner,p(impact,1),0)
    local from=p(impact,3)
    if impact.donor_id==13263 and (impact.phase or 0)>1 then from=p(impact,4) end
    if impact.donor_id==13262 or (impact.phase or 0)>0 then c:swap_skill(owner,from,p(impact,2),0,0) end
    return true
end
function M.tick_171(c,impact,owner,delta)
    need(c,{"has_scene","mission_param_changed"})
    swap171(impact)
    impact.timer=num.i32((impact.timer or p(impact,0))-delta)
    local seconds=num.trunc(impact.timer/1000)
    if seconds~=(impact.last_seconds or 0) then
        impact.last_seconds=seconds
        if c:has_scene(owner) then c:mission_param_changed(owner,p(impact,1),seconds) end
    end
end

-- Hook184: normalized displacement is always five units, even for near clicks.
function M.active_184(c,impact,owner)
    need(c,{"is_human","has_scene","target_position","position","charge_doll","send_specific"})
    local id=resolve_all(c,"impact",{4862})[1]
    if not c:is_human(owner) or not c:has_scene(owner) then return false end
    local a,b=c:position(owner),c:target_position(owner)
    local dx,dy=num.f32(b.x-a.x),num.f32(b.y-a.y)
    local len=num.f32(math.sqrt(num.f32(num.f32(dx*dx)+num.f32(dy*dy))))
    if len>0 then dx=num.f32(dx/len);dy=num.f32(dy/len) end
    c:charge_doll(owner,{x=num.f32(a.x+num.f32(dx*5)),y=num.f32(a.y+num.f32(dy*5))},1)
    c:send_specific(owner,owner,id)
    return true
end

-- Main0xa58c5e: the actual callback is OnImpactFadeOut, not OnImpactActive.
function M.fade_90(c, impact, owner)
    need(c,{"is_human","has_scene","script_exists","script_on_impact_fade","target_impact_id"})
    if not c:is_human(owner) then return false end
    local script=p(impact,0)
    if script==-1 or not c:has_scene(owner) or not c:script_exists(owner,script,"OnImpactFadeOut") then return false end
    c:script_on_impact_fade(owner,script,c:target_impact_id(impact))
    return true
end

-- Main0xa6512c: descriptor1 is unused, regardless of its misleading donor label.
-- Native character attr0x34 is critical damage multiplier correction.
function M.critical_bonus_148(c, impact, point)
    need(c,{"float2int"})
    local value=p(impact,0)
    if value==0 then return point end
    local step=impact.step0 or 0
    if step~=0 then
        need(c,{"native_factor_24"})
        value=num.i32(value+c:float2int(num.f32(num.f32(c:native_factor_24(impact))*num.f32(step))))
    end
    return num.i32(point+value)
end

-- Main0xa5b01e: repeated trap placement with a real logic52 trap tracker.
function M.interval_99(c, impact, owner)
    need(c,{"is_alive","is_active","has_scene","trap_record","find_trap_tracker",
        "trap_counts","in_collection","create_trap","position","set_trap_skill",
        "add_trap","new_trap_tracker","register_tracker","activate_trap","sect_trap_interval"})
    if not c:is_alive(owner) or not c:is_active(owner) or not c:has_scene(owner) then return false end
    local data=c:trap_record(p(impact,1))
    assert(data and math.tointeger(data.class),"invalid donor trap data")
    local tracker=c:find_trap_tracker(owner)
    if tracker then
        local all,same=c:trap_counts(tracker,owner,data.class)
        if all>10 or same>=p(impact,2) then return false end
    end
    local selected=p(impact,1)
    if c:in_collection(owner,p(impact,3))~=0 then selected=p(impact,4)
    elseif c:in_collection(owner,p(impact,5))~=0 then selected=p(impact,6) end
    assert(p(impact,0)>=0 and selected>=0,"invalid donor trap/reference ID")
    -- Validate the replacement before creating any object; native asserted here.
    assert(c:trap_record(selected),"invalid donor strengthened trap")
    local new_tracker
    if not tracker then new_tracker=c:new_trap_tracker(owner,p(impact,0)) end
    local trap=c:create_trap(owner,c:position(owner),selected,0)
    assert(trap,"could not create donor trap")
    c:set_trap_skill(trap,impact)
    if tracker then
        if not c:add_trap(tracker,owner,trap) then return false end
    else
        assert(new_tracker,"missing logic52 trap tracker")
        assert(c:add_trap(new_tracker,owner,trap),"could not add donor trap to tracker")
        c:register_tracker(owner,new_tracker,100,-1)
    end
    c:activate_trap(owner,trap,500)
    c:sect_trap_interval(owner)
    return true
end

-- Hook0x6b8a0 /0x6b8e6: p1 adds critical modifier, p0 scales outgoing damage.
function M.critical_bonus_189(impact,point) return num.i32(point+p(impact,1)) end
function M.damage_target_189(c,impact,damage)
    need(c,{"float2int"})
    if damage<=0 then return damage end
    return num.scale(damage,100+p(impact,0),100,function(v) return c:float2int(v) end)
end

-- 0x9f5b4: first matching buff wins; fifth stack refreshes itself.
function M.taohua_stack(c, owner)
    need(c, {"has_impact", "send_specific"})
    local ids = resolve_all(c, "impact", {4267,4268,4269,4270,4271})
    local next_id = ids[1]
    for i, id in ipairs(ids) do
        if c:has_impact(owner, id) then next_id = ids[math.min(i+1,5)]; break end
    end
    c:send_specific(owner, owner, next_id)
    return next_id
end

local skill_impacts = {[792]=4396,[793]=4408,[794]=4426}
-- 0x6ba46/0x6bcb0/0x6bdc8. The target write remains an explicit native operation:
-- native Obj+0xd0 layout has not been assumed from 32-bit legacy structures.
function M.skill_start(c, logic, owner)
    assert(skill_impacts[logic], "unsupported skill logic")
    need(c, {"is_human", "has_scene", "action_is_idle"})
    if logic ~= 794 then need(c, {"get_doll_id", "write_native_target"}) end
    if not c:is_human(owner) then return false end
    if logic ~= 794 and c:has_scene(owner) then
        c:write_native_target(owner, c:get_doll_id(owner))
    end
    return c:action_is_idle(owner)
end
-- 0x6b97a/0x6bbe4/0x6bd58. No parameter-based fallback impacts are invented.
function M.skill_effect(c, logic, owner)
    local donor_impact = assert(skill_impacts[logic], "unsupported skill logic")
    need(c, {"has_scene", "send_specific"})
    if logic ~= 794 then need(c, {"get_doll_id", "write_native_target"}) end
    local mapped = resolve_all(c,"impact",{donor_impact})[1]
    if not c:has_scene(owner) then return false end
    if logic ~= 794 then
        local doll_id = c:get_doll_id(owner)
        if doll_id > 0 then c:write_native_target(owner, doll_id) end
    end
    c:send_specific(owner, owner, mapped)
    return true
end

-- 0x669a6, rodata0xb6fcc = 100.0f. No clamp is present in native code.
function M.damage_156(c, impact, damage)
    need(c, {"float2int"})
    local rate = p(impact,0)
    if rate <= 0 then return damage end
    return num.scale(damage,100-rate,100,function(v) return c:float2int(v) end)
end

-- 0x67504; divisor0xb716c=1000.0f, GetArrtEx indices4..7.
function M.attr_162(c, impact, owner, index, point)
    assert(index >= 0 and index <= 3 and math.tointeger(index), "attr index outside 0..3")
    need(c, {"attr_ex", "float2int"})
    local rate = p(impact,index)
    if rate == 0 then return point end
    local delta = num.scale(c:attr_ex(owner,index+4),rate,1000,function(v) return c:float2int(v) end)
    return num.i32(point+delta)
end
function M.mark_dirty_162(c, impact, owner)
    need(c, {"mark_attr_dirty"})
    local names = {"attrib_hit","attrib_miss","mind_attack","mind_defend"}
    for i=0,3 do if p(impact,i) ~= 0 then c:mark_attr_dirty(owner,names[i+1]) end end
end

-- 0x65a62: only donor IDs3882..3893, five successful extensions at most.
function M.critical_149(c, impact)
    need(c,{"random_1000","extend_duration"})
    if impact.extension_count > 4 or impact.donor_id <= 3881 or impact.donor_id > 3893 then return false end
    if c:random_1000() > 200 then return false end
    impact.extension_count = impact.extension_count + 1
    c:extend_duration(impact,2000)
    return true
end
-- Full selected-row path of0x65afa. Nonselected p5 branch explicitly rejected:
-- native virtual getters0x490/0x2d0 still need a verified engine correspondence.
function M.damage_target_149(c, impact, owner, target, damage, native_flag_bit0)
    need(c,{"float2int"})
    local rate = p(impact,0)
    if p(impact,2) == 15 then
        need(c,{"is_human","donor_faction"})
        if not c:is_human(target) or c:donor_faction(target) ~= 15 then rate = 0 end
    end
    -- Native tests byte[impact+0x28]&1, not an OnDamage critical argument.
    -- Legacy _OWN_IMPACT bit0 is FADE_OUT. Keep this ABI input explicit.
    if not native_flag_bit0 then
        rate = num.i32(rate+p(impact,1))
        assert(p(impact,5) <= 0, "149 p5 native getter branch is not bound")
    end
    if damage <= 0 then return damage end
    return num.scale(damage,100+rate,100,function(v) return c:float2int(v) end)
end
-- 0x65da4: p3 base, p4 on noncritical, p6 excludes impact caster.
function M.damage_149(c, impact, owner, attacker, damage, critical)
    need(c,{"float2int"})
    local rate = p(impact,3)
    if p(impact,6) == 1 then
        need(c,{"is_impact_caster"})
        if c:is_impact_caster(impact,owner,attacker) then rate = 0 end
    end
    if not critical then rate = num.i32(rate+p(impact,4)) end
    if damage <= 0 then return damage end
    return num.scale(damage,1000+rate,1000,function(v) return c:float2int(v) end)
end

-- 0x685b6/0x687be: timed charging stacks, collection360 suppresses/reset logic.
function M.refix_167(impact, rate)
    impact.power_refix = num.i32(impact.power_refix+rate)
    return true
end
function M.damages_167(c, impact, owner)
    need(c,{"in_collection","dispel_impact","send_specific"})
    local collection = resolve_all(c,"collection",{360})[1]
    if c:in_collection(owner,collection) ~= 0 then return end
    local stack = impact.stack
    assert(stack >= 0 and stack <= 5, "native stack outside 0..5")
    -- Native local arrays contain literal0 at index0, not the descriptor0 time.
    local remove = stack == 0 and 0 or p(impact,stack)
    local add = stack == 0 and 0 or p(impact,stack+5)
    c:dispel_impact(owner,remove)
    c:send_specific(owner,owner,add)
    impact.native_34,impact.stack = 0,0
end
function M.interval_167(c, impact, owner)
    need(c,{"in_collection","has_impact","send_specific"})
    local collection = resolve_all(c,"collection",{360})[1]
    local present = c:in_collection(owner,collection)
    if present > 0 and impact.native_34 > 0 then impact.native_34,impact.stack = 0,0 end
    if not c:has_impact(owner,p(impact,5)) and present == 0 then
        impact.stack = math.min(impact.stack+1,5)
        c:send_specific(owner,owner,p(impact,impact.stack))
    end
    return true
end

-- 0x6a494: critical incoming hits advance the counter; duration is zeroed.
function M.damage_180(c, impact, critical)
    need(c,{"expire_duration"})
    if not critical then return end
    impact.critical_count = num.i32(impact.critical_count+1)
    if impact.critical_count >= p(impact,0) then c:expire_duration(impact) end
end
-- 0x6a4e8: first FOUR eligible enemies, excluding the marked victim.
-- Native scan center is owner bytes+0x20 (not proven normal WORLD_POS+0x24).
function M.fade_180(c, impact, owner)
    need(c,{"get_impact_caster","scan_180","is_enemy","critical_roll","send_combat_180","send_specific"})
    if impact.critical_count < p(impact,0) then return 0 end
    local caster = c:get_impact_caster(impact,owner)
    if not caster then return 0 end -- Native dereferences null; safe stop for disconnected caster.
    local count = 0
    for _,target in ipairs(c:scan_180(caster,owner,25)) do
        if target ~= owner and c:is_enemy(caster,target) then
            c:send_combat_180(target,caster,p(impact,1),c:critical_roll(caster,target))
            c:send_specific(target,caster,p(impact,2))
            count = count + 1
            if count > 3 then break end
        end
    end
    return count
end

-- 0x6a734. Native talent0 probability is inclusive [0,threshold]/1000.
function M.active_181(c, impact, owner)
    need(c,{"is_human","has_scene","target_position","get_doll_id","send_specific",
        "talent_level","random_1000","set_position","has_impact"})
    local ids = resolve_all(c,"impact",{4422,4423,4424,4267,4268,4269,4270,4271})
    if not c:is_human(owner) or not c:has_scene(owner) then return end
    local position = c:target_position(owner)
    local level = c:talent_level(owner,0)
    assert(math.tointeger(level) and level>=0 and level<=5,"native talent0 level outside0..5")
    if c:get_doll_id(owner)>0 then
        for i=1,3 do c:send_specific(owner,owner,ids[i]) end
        M.taohua_stack(c,owner)
    end
    local threshold = {[1]=12,[2]=28,[3]=48,[4]=72,[5]=100}
    if level>0 and c:random_1000()<=threshold[level] then M.taohua_stack(c,owner) end
    c:set_position(owner,position)
end

-- 0x6a8e8: inspect first five scan entries, including friendly entries.
function M.active_182(c, impact, owner)
    need(c,{"is_human","has_scene","target_position","get_doll_id","get_object",
        "position","set_position","scan","is_enemy","xinfa_level","skill_instance_182",
        "critical_roll","send_specific","send_combat_182","object_id","script_mou_dong_gan_ge","float2int"})
    local xinfa = resolve_all(c,"xinfa",{99})[1]
    local skill = resolve_all(c,"skill_template",{3807})[1]
    if not c:is_human(owner) or not c:has_scene(owner) then return end
    local destination = c:target_position(owner)
    local doll_id = c:get_doll_id(owner)
    if doll_id<=0 then return end
    local doll = c:get_object(owner,doll_id)
    if not doll then return end
    -- Bind offsets0xc0/0xd0 explicitly before mutation. Values are target impact IDs.
    local combat_id,specific_id = c:skill_instance_182(owner)
    assert(math.tointeger(combat_id) and math.tointeger(specific_id),"182 skill instance reference missing")
    local center = c:position(doll)
    local level = c:xinfa_level(owner,xinfa)
    c:set_position(owner,center)
    for index,target in ipairs(c:scan(owner,center,50,5)) do
        if index>5 then break end
        if c:is_enemy(owner,target) then
            local critical = c:critical_roll(owner,target)
            c:send_specific(target,owner,specific_id)
            c:send_combat_182(owner,target,combat_id,level,critical,skill)
        end
    end
    if c:object_id(owner)>14999 then
        c:script_mou_dong_gan_ge(owner,c:float2int(destination.x),c:float2int(destination.y))
    end
end

-- 0x6ac6a: at most three enemies in the charge rectangle, move doll and caster.
function M.active_183(c, impact, owner)
    need(c,{"is_human","has_scene","target_position","get_doll_id","get_object",
        "position","scan_183","in_charge_rectangle","is_enemy","send_specific",
        "charge_doll","set_position","has_impact","talent_137_threshold","random_1000"})
    local send_id = resolve_all(c,"impact",{4398,4267,4268,4269,4270,4271})[1]
    if not c:is_human(owner) or not c:has_scene(owner) then return end
    local destination = c:target_position(owner)
    local doll_id = c:get_doll_id(owner)
    if doll_id<=0 then return end
    local doll = c:get_object(owner,doll_id)
    if not doll then return end
    local center = c:position(owner)
    -- A nil threshold explicitly means the actual talent row has no logic137.
    local threshold = c:talent_137_threshold(impact,owner)
    local count = 0
    for _,target in ipairs(c:scan_183(owner,center,50)) do
        if c:is_enemy(owner,target) and c:in_charge_rectangle(center,destination,c:position(target)) then
            c:send_specific(target,owner,send_id)
            count = count+1
            if count>2 then break end
        end
    end
    c:charge_doll(doll,center,1)
    c:set_position(owner,destination)
    M.taohua_stack(c,owner)
    if threshold and c:random_1000()<=threshold then M.taohua_stack(c,owner) end
    return count
end
return M
