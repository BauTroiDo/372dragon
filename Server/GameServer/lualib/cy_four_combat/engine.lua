-- Staged bridge to the actual Skynet class/impact event interfaces.
-- Construction is explicit: require(...).new(config, adapters).
-- Missing native adapters reject registration; no silent fallback behavior.
local native = require "cy_four_combat.native"
local num = require "cy_four_combat.numeric"
local class = require "class"
local M = {}
local capability = {
    [38]={}, -- Recovered main vtable: only timed/noninterval overrides, marker.
    [52]={"get_object","is_special","trap_faded","object_trap_record","duration","set_duration","reset_elapsed"},
    [90]={"is_human","has_scene","script_exists","script_on_impact_fade","target_impact_id"},
    [99]={"is_alive","is_active","has_scene","trap_record","find_trap_tracker","trap_counts","in_collection","create_trap","position","set_trap_skill","add_trap","new_trap_tracker","register_tracker","activate_trap","sect_trap_interval"},
    [148]={"float2int","mark_attr_dirty"},
    [149]={"float2int","random_1000","extend_duration","native_flag_bit0"},
    [156]={"float2int"},
    [162]={"attr_ex","float2int","mark_attr_dirty"},
    [167]={"resolve","in_collection","dispel_impact","send_specific","has_impact"},
    [168]={}, -- Base profile: native zero amount, timed channel marker.
    [171]={"is_human","has_scene","duration","mission_param_changed","swap_skill","float2int"},
    [180]={"expire_duration","get_impact_caster","scan_180","is_enemy","critical_roll","send_combat_180","send_specific"},
    [181]={"resolve","is_human","has_scene","target_position","get_doll_id","send_specific","talent_level","random_1000","set_position","has_impact"},
    [182]={"resolve","is_human","has_scene","target_position","get_doll_id","get_object","position","set_position","scan","is_enemy","xinfa_level","skill_instance_182","critical_roll","send_specific","send_combat_182","object_id","script_mou_dong_gan_ge","float2int"},
    [183]={"resolve","is_human","has_scene","target_position","get_doll_id","get_object","position","scan_183","in_charge_rectangle","is_enemy","send_specific","charge_doll","set_position","has_impact","talent_137_threshold","random_1000"},
    [184]={"resolve","is_human","has_scene","target_position","position","charge_doll","send_specific"},
    [189]={"float2int","mark_attr_dirty"},
    [792]={"resolve","is_human","has_scene","action_is_idle","get_doll_id","write_native_target","send_specific"},
    [793]={"resolve","is_human","has_scene","action_is_idle","get_doll_id","write_native_target","send_specific"},
    [794]={"resolve","is_human","has_scene","action_is_idle","send_specific"},
}
local damage_hooks = {[149]=true,[156]=true,[180]=true,[189]=true}

function M.new(config, adapters)
    assert(type(config)=="table" and type(config.impacts)=="table", "target impact sidecar required")
    assert(type(adapters)=="table", "native adapter table required")
    local bridge = {config=config, context=adapters, skills={}, impacts={}}
    function bridge:is_disabled_impact(id) return self.config.disabled_impacts and self.config.disabled_impacts[id]~=nil end
    function bridge:make_unavailable_impact(id)
        assert(self.config.disabled_logic_ids and self.config.disabled_logic_ids[id],"explicit disabled logic required")
        local base=require "scene.skill.impact_logic.base"
        local logic=class("cy_four_unavailable_"..id,base)
        function logic:on_active() error("disabled donor logic "..id.." must be rejected before impact initialization") end
        function logic:on_interval_over() error("disabled donor logic "..id) end
        self.impacts[id+8000]=logic.new()
        return self.impacts[id+8000]
    end
    function bridge:readiness(id)
        local names = capability[id]
        if not names then return false,{"native behavior unavailable for logic "..id} end
        local missing={}
        for _,name in ipairs(names) do
            if type(self.context[name])~="function" then missing[#missing+1]=name end
        end
        if damage_hooks[id] and self.config.final_damage_hook_verified~=true then
            missing[#missing+1]="final_damage_hook_verified"
        end
        if id==148 or id==149 or id==156 or id==162 or id==182 or id==189 then
            if self.config.float2int_verified~=true then missing[#missing+1]="float2int_verified" end
        end
        if (id==148 or id==189) and self.config.critical_bonus_hook_verified~=true then
            missing[#missing+1]="critical_bonus_hook_verified"
        end
        return #missing==0,missing
    end
    -- skill-logic guard: CY (ImpactCore_T::InitImpactFromData @0xa87fee) trả 0 khi không có mô tả hiệu ứng và người
    -- gọi bỏ qua; ở đây cũng BỎ QUA (trả nil) + ghi log một lần cho mỗi data_index, KHÔNG assert —
    -- assert cũ làm nhân vật mang buff cũ không đăng nhập được (human.ctor → init_from_db_data).
    bridge.missing_descriptor_logged = {}
    function bridge:descriptor(imp)
        local id=imp:get_data_index()
        local source=self.config.impacts[id]
        if not source and not self.missing_descriptor_logged[id] then
            self.missing_descriptor_logged[id]=true
            require("skynet").logi("[cy_four] bo qua impact khong co mo ta positional, data_index =",id)
        end
        return source
    end
    function bridge:state(imp)
        local state=require("cy_four_combat.state_cache")[imp]
        if not state or state.target_id~=imp:get_data_index() then
            local source=self:descriptor(imp)
            if not source then return nil end
            -- Sidecar is a dense 1..16 array for JSON/Lua interchange.
            local values={}
            for i=0,15 do values[i]=assert(math.tointeger(source.params[i+1]),"sidecar descriptor missing") end
            state=native.new_impact(source.donor_id,values)
            state.step0=source.step0 or 0
            state.engine_impact=imp
            state.target_id=imp:get_data_index()
            require("cy_four_combat.state_cache")[imp]=state   -- skill-logic guard
        end
        return state
    end
    function bridge:make_impact(id)
        local ready,missing=self:readiness(id)
        assert(ready,"unready donor impact "..id..": "..table.concat(missing,", "))
        local base=require "scene.skill.impact_logic.base"
        local logic=class("cy_four_impact_"..id,base)
        local b=self
        function logic:is_over_timed() return true end
        function logic:is_intervaled() return id==99 or id==167 end
        if id==38 then
            -- This is the verified native marker, not a fallback implementation.
        elseif id==52 then
            function logic:add_new_trap(imp,owner,obj_id) return native.tracker_add(b.context,b:state(imp),owner,obj_id) end
            function logic:get_trap_count_of_specific_type(imp,owner,class_id) return native.tracker_count(b.context,b:state(imp),owner,class_id) end
            function logic:special_heart_beat_check(imp,owner) return native.tracker_heartbeat(b.context,b:state(imp),owner) end
        elseif id==168 then
            assert(config.talents_enabled==false and config.tao_logic168_base_ready)
            function logic:on_active(imp) return require("cy_four_combat.tao").init_168(b:state(imp)) end
            function logic:on_fade_out(imp) assert(b:state(imp).damage==0,"unexpected talent168 amount in base release") end
        elseif id==171 then
            function logic:on_active(imp,owner) return native.active_171(b.context,b:state(imp),owner) end
            function logic:on_fade_out(imp,owner) return native.fade_171(b.context,b:state(imp),owner) end
            function logic:continuance_cal(imp,owner,delta)
                native.tick_171(b.context,b:state(imp),owner,delta)
                return base.continuance_cal(self,imp,owner,delta)
            end
        elseif id==90 then
            function logic:on_fade_out(imp,owner) return native.fade_90(b.context,b:state(imp),owner) end
        elseif id==99 then
            function logic:refix_power_by_rate(imp,rate) return native.refix_167(b:state(imp),rate) end
            function logic:on_interval_over(imp,owner) return native.interval_99(b.context,b:state(imp),owner) end
            -- Native99 speed state+0x30 is initialized0 and never written by its
            -- own methods. External writers require a separate, explicit port.
        elseif id==148 then
            function logic:critical_damage_bonus(imp,point) return native.critical_bonus_148(b.context,b:state(imp),point) end
            function logic:mark_modified_attr_dirty(imp,owner)
                if self:critical_damage_bonus(imp,0)~=0 then b.context:mark_attr_dirty(owner,"cy_four_critical_bonus") end
            end
        elseif id==189 then
            function logic:critical_damage_bonus(imp,point) return native.critical_bonus_189(b:state(imp),point) end
            function logic:mark_modified_attr_dirty(imp,owner)
                if self:critical_damage_bonus(imp,0)~=0 then b.context:mark_attr_dirty(owner,"cy_four_critical_bonus") end
            end
            function logic:on_final_damage_target(imp,owner,target,damage) return native.damage_target_189(b.context,b:state(imp),damage) end
        elseif id==149 then
            function logic:on_critical_hit_target(imp,owner)
                return native.critical_149(b.context,b:state(imp))
            end
            function logic:on_final_damage_target(imp,owner,target,damage,event)
                return native.damage_target_149(b.context,b:state(imp),owner,target,damage,b.context:native_flag_bit0(imp))
            end
            function logic:on_final_damage(imp,owner,attacker,damage,event)
                return native.damage_149(b.context,b:state(imp),owner,attacker,damage,event.critical)
            end
        elseif id==156 then
            function logic:on_final_damage(imp,owner,attacker,damage)
                return native.damage_156(b.context,b:state(imp),damage)
            end
        elseif id==162 then
            local attrs={"attrib_hit","attrib_miss","mind_attack","mind_defend"}
            for i,name in ipairs(attrs) do
                logic["get_refix_"..name]=function(_,imp,args,owner)
                    args.point=native.attr_162(b.context,b:state(imp),owner,i-1,args.point or 0)
                end
            end
            function logic:mark_modified_attr_dirty(imp,owner)
                return native.mark_dirty_162(b.context,b:state(imp),owner)
            end
        elseif id==167 then
            function logic:refix_power_by_rate(imp,rate) return native.refix_167(b:state(imp),rate) end
            function logic:on_damages(imp,owner) return native.damages_167(b.context,b:state(imp),owner) end
            function logic:on_interval_over(imp,owner) return native.interval_167(b.context,b:state(imp),owner) end
        elseif id==180 then
            function logic:on_final_damage(imp,owner,attacker,damage,event)
                native.damage_180(b.context,b:state(imp),event.critical)
                return damage
            end
            function logic:on_fade_out(imp,owner) return native.fade_180(b.context,b:state(imp),owner) end
        else
            function logic:on_active(imp,owner) return native["active_"..id](b.context,b:state(imp),owner) end
        end
        -- skill-logic guard: bọc mọi phương thức — impact không có mô tả positional thì trả giá trị TRUNG TÍNH
        -- (như CY: không dựng được impact thì coi như hiệu ứng không tồn tại), không ném lỗi.
        local neutral={
            critical_damage_bonus=function(_,_,point) return point end,
            on_final_damage=function(_,_,_,_,damage) return damage end,
            on_final_damage_target=function(_,_,_,_,damage) return damage end,
            continuance_cal=function(self_,imp,owner,delta) return base.continuance_cal(self_,imp,owner,delta) end,
            add_new_trap=function() return false end,
            get_trap_count_of_specific_type=function() return 0 end,
            refix_power_by_rate=function() return false end,
        }
        local raw={}
        for name,fn in pairs(logic) do
            -- chỉ bọc phương thức do CHÍNH lớp này định nghĩa (khác bản của base), tức các phương thức
            -- gọi b:state; phương thức kế thừa nguyên của base giữ nguyên.
            if type(fn)=="function" and base[name]~=fn and name~="is_over_timed"
               and name~="is_intervaled" and name~="new" and name~="ctor" then
                raw[name]=fn
            end
        end
        for name,fn in pairs(raw) do
            logic[name]=function(self_,imp,...)
                if type(imp)=="table" and imp.get_data_index and not b:descriptor(imp) then
                    local n=neutral[name]
                    if n then return n(self_,imp,...) end
                    return nil
                end
                return fn(self_,imp,...)
            end
        end
        self.impacts[id+8000]=logic.new()
        return self.impacts[id+8000]
    end
    function bridge:critical_bonus(owner,point)
        for _,imp in ipairs(owner:get_impact_list()) do
            local logic=self.impacts[imp:get_logic_id()]
            if logic and logic.critical_damage_bonus then point=logic:critical_damage_bonus(imp,point) end
        end
        return point
    end
    function bridge:critical_rate(owner,base_rate,skill_id)
        local bonus=self:critical_bonus(owner,0)
        local donor=self.config.donor_skill_templates and self.config.donor_skill_templates[skill_id]
        if not donor and bonus==0 then return base_rate end
        local native_multiplier=num.float2int(num.f32(num.f32(200+bonus)/100))
        -- Preserve existing world's extra critical effects. Donor skills use
        -- their native2x baseline; legacy skills retain their current2.2x base.
        return base_rate+(native_multiplier-2)*100-(donor and 20 or 0)
    end
    function bridge:make_skill(id)
        assert(id==792 or id==793 or id==794,"unsupported donor skill")
        local ready,missing=self:readiness(id)
        assert(ready,"unready donor skill "..id..": "..table.concat(missing,", "))
        local base=require "scene.skill.base"
        local logic=class("cy_four_skill_"..id,base)
        local b=self
        function logic:is_passive() return false end
        function logic:speical_operation_on_skill_start(owner) return native.skill_start(b.context,id,owner) end
        function logic:effect_on_unit_once(owner) return native.skill_effect(b.context,id,owner) end
        self.skills[id+8000]=logic.new()
        return self.skills[id+8000]
    end
    -- Integration point after the engine has composed a numeric HP damage.
    -- This does not change any event for pre-existing logic IDs.
    function bridge:final_damage(owner,attacker,damage,event)
        assert(type(event)=="table" and type(event.critical)=="boolean","critical event required")
        if attacker then
            for _,imp in ipairs(attacker:get_impact_list()) do
                local logic=self.impacts[imp:get_logic_id()]
                if logic and logic.on_final_damage_target then
                    damage=logic:on_final_damage_target(imp,attacker,owner,num.float2int(damage),event)
                end
            end
        end
        for _,imp in ipairs(owner:get_impact_list()) do
            local logic=self.impacts[imp:get_logic_id()]
            if logic and logic.on_final_damage then damage=logic:on_final_damage(imp,owner,attacker,num.float2int(damage),event) end
        end
        return damage
    end
    return bridge
end
M.capabilities=capability
return M
