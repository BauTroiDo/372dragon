-- Canonical Skynet engine adapter. Only evidence-backed operations are bound.
-- Extensions supply native packet/resource/geometry contracts from their ports.
local num=require "cy_four_combat.numeric"
local M={}
local kinds={impact="impacts",skill_template="skill_templates",xinfa="xinfa",collection="collections",special_object="special_objects"}
function M.new(config,extensions)
    assert(type(config.resolve)=="table","explicit donor-to-target maps required")
    local c={config=config}
    function c:resolve(kind,id)
        local map=self.config.resolve[assert(kinds[kind],"unknown reference kind")]
        return map and map[id]
    end
    function c:float2int(v) return num.float2int(v) end
    function c:random_1000() return math.random(0,999) end
    function c:is_human(o) return o and o:get_obj_type()=="human" end
    function c:has_scene(o) return o and o:get_scene()~=nil end
    function c:is_alive(o) return o:is_alive() end
    function c:is_active(o) return o:is_active_obj() end
    function c:is_special(o) return o:get_obj_type()=="special" end
    function c:object_id(o) return o:get_obj_id() end
    function c:get_object(o,id) local s=o:get_scene();return s and s:get_obj_by_id(id) end
    function c:position(o) local p=o:get_world_pos();return {x=p.x,y=p.y} end
    function c:target_position(o) local p=o:get_targeting_and_depleting_params():get_target_position();return {x=p.x,y=p.y} end
    function c:write_native_target(o,id) o:get_targeting_and_depleting_params():set_target_obj(id) end
    function c:action_is_idle(o) return o:get_action_logic()==nil end
    function c:charge_doll(o,p,mode) assert(mode==1,"unsupported native charge mode");o:skill_charge({x=p.x,y=p.y}) end
    function c:is_enemy(o,t) return o:is_enemy(t) end
    function c:scan(o,center,cap,radius)
        return o:get_scene():scan{obj=o,x=center.x,y=center.y,radious=radius,count=cap,target_logic_by_stand=0}
    end
    function c:scan_183(o,center,cap) return self:scan(o,center,cap,15) end
    function c:scan_180(caster,victim,cap)
        -- Deliberate donor fix approved by root: native copied+0x20 (active byte
        -- and padding). The actual WORLD_POS is+0x24. Same victim, same radius5.
        return self:scan(caster,self:position(victim),cap,5)
    end
    function c:in_charge_rectangle(a,b,target) return require("cy_four_combat.native").in_rectangle(a,b,target,10,2) end
    function c:skill_instance_182(o)
        local skill=o:get_skill_info()
        local row=assert(self.config.skill_instances and self.config.skill_instances[skill._cy_four_data_id],"182 positional skill data missing")
        assert(row.donor_logic==793,"182 requires real donor793 skill instance")
        return row.combat,row.specific
    end
    function c:xinfa_level(o,id) local x=o:get_xinfa(id);return x and x.m_nXinFaLevel or 0 end
    function c:critical_roll(o,target)
        local skill=o:get_skill_info()
        assert(skill,"native critical roll requires current skill info")
        return require("scene.skill.base").is_critical_hit(nil,o,target,skill:get_critical_rate(),skill)
    end
    if config.talents_enabled==false then
        -- Explicitly selected base-four-faction release: donor talents have not
        -- been imported/learned. Never read identically numbered legacy talents.
        function c:talent_level() return 0 end
        function c:talent_137_threshold() return nil end
        function c:sect_trap_interval() return true end
    end
    function c:owner_hp(o) return o:get_hp() end
    function c:owner_max_hp(o) return o:get_max_hp() end
    function c:donor_faction(o)
        local id=o:get_menpai()
        return self.config.reverse_faction and self.config.reverse_faction[id] or id
    end
    function c:duration(s) return s.engine_impact:get_continuance() end
    function c:set_duration(s,value) s.engine_impact:set_continuance(value) end
    function c:reset_elapsed(s) s.engine_impact:set_continuance_elapsed(0) end
    function c:expire_duration(s) self:set_duration(s,0) end
    function c:extend_duration(s,delta) self:set_duration(s,self:duration(s)+delta) end
    function c:native_flag_bit0(imp) return imp:is_fade_out() end
    function c:get_impact_caster(s,o) return self:get_object(o,s.engine_impact:get_caster_obj_id()) end
    function c:is_impact_caster(s,o,t) return t and t:get_obj_id()==s.engine_impact:get_caster_obj_id() end
    function c:target_impact_id(s) return s.engine_impact:get_data_index() end
    function c:has_impact(o,id) return o:impact_get_first_impact_of_specific_data_index(id)~=nil end
    function c:dispel_impact(o,id) return o:impact_cancel_impact_in_specific_data_index(id) end
    function c:new_data_impact(target,id,level)
        assert(math.tointeger(id) and id>0,"impact ID required")
        local imp=require("scene.skill.impact").new()
        assert(target:get_scene():get_impact_enginer():init_impact_from_data(id,imp),"missing selected impact "..id)
        imp:set_skill_level(level)
        return imp
    end
    function c:emit_impact(target,caster,imp,delay,skill,notify_be_skill)
        local scene=target:get_scene();local target_id=target:get_obj_id()
        local caster_id=caster and caster:get_obj_id()
        if caster then imp:set_caster_logic_count(caster:get_logic_count()) end
        local function deliver()
            if target:get_scene()~=scene or scene:get_obj_by_id(target_id)~=target then return end
            if caster and scene:get_obj_by_id(caster_id)~=caster then return end
            local event=scene:get_event_enginer()
            if notify_be_skill then event:register_be_skill_event(target,caster,skill,imp:get_stand_flag()) end
            return event:register_impact_event(target,caster,imp,0,skill)
        end
        if delay>0 then require("skynet").timeout(math.ceil(delay/10),deliver) else deliver() end
        return true
    end
    -- Main SendImpactToUnit0xa88156 proves r9=delay; helper passes10ms.
    -- Existing Skynet register_impact_event ignores delay, so schedule here.
    function c:send_specific_delay(target,caster,id,delay)
        if id==0 then return false end -- native InitImpactFromData(0) fails/no event.
        local imp=self:new_data_impact(target,id,0)
        imp:set_skill_id(-1)
        return self:emit_impact(target,caster,imp,delay,-1)
    end
    function c:send_specific(target,caster,id) return self:send_specific_delay(target,caster,id,10) end
    function c:send_combat_180(target,caster,id,critical)
        -- Main0xa88566 hardcodes500ms despite caller's r9=5.
        local imp=self:new_data_impact(target,id,9)
        if critical then imp:mark_critical_hit_flag() end
        require("scene.skill.combat_core").new():get_result_impact(caster,target,imp)
        imp:set_skill_id(-1)
        return self:emit_impact(target,caster,imp,500,-1,true)
    end
    function c:send_combat_182(caster,target,id,level,critical,skill)
        local imp=self:new_data_impact(target,id,level)
        if imp:get_logic_id()==3 then require("scene.skill.combat_core").new():get_result_impact(caster,target,imp) end
        imp:set_skill_id(skill)
        if critical then imp:mark_critical_hit_flag() end
        return self:emit_impact(target,caster,imp,10,skill)
    end
    function c:in_collection(o,id)
        local row=assert(self.config.collections and self.config.collections[id],"donor collection sidecar required")
        for _,imp in ipairs(o:get_impact_list()) do
            local t,value=row.type
            if (t==0 or t==5) and imp:get_is_over_timed() then value=imp:get_impact_id()
            elseif t==1 then value=imp:get_mutex_id()
            elseif t==2 then value=imp:get_logic_id()
            elseif t==3 then value=imp:get_skill_id()
            elseif t==7 and imp:get_is_over_timed() then value=imp:get_class_id() end
            if value~=nil then for _,member in ipairs(row.ids) do if value==member then return 1 end end end
        end
        return 0
    end
    function c:mark_attr_dirty(o,name)
        -- Critical bonus is computed from live impacts on every critical event.
        if name~="cy_four_critical_bonus" then o:mark_attrib_refix_dirty(name) end
    end
    function c:attr_ex(o,index)
        if not self:is_human(o) then return 0 end
        local key=assert(({[4]="attrib_hit",[5]="attrib_miss",[6]="mind_attack",[7]="mind_defend"})[index])
        local configengine=require("configenginer"):getinstance()
        local row=assert(configengine:get_config("base_value_table")["MENPAI"..o:get_menpai()])
        local influence=assert(require("menpai").influence[key])
        local value=assert(row[influence.init])
        for attr,column in pairs(influence) do if attr~="init" then value=num.i32(value+num.i32(row[column]*o.db:get_attrib(attr))) end end
        local base=math.max(0,num.float2int(num.f32(num.f32(value)/100)))
        -- Hook Get*Ex: active item35/36/37/47; item47 is critical DEFENCE.
        return num.i32(base+o:item_value(({[4]=35,[5]=36,[6]=37,[7]=47})[index]))
    end
    function c:trap_record(id) return require("configenginer"):getinstance():get_config("special_obj_data")[id] end
    function c:object_trap_record(o) return self:trap_record(o:get_data_id()) end
    function c:trap_faded(o) return o:is_fade_out() end
    function c:find_trap_tracker(o)
        for _,imp in ipairs(o:get_impact_list()) do if imp:get_logic_id()==8052 then return imp end end
    end
    function c:trap_counts(imp,o,class)
        return o:get_scene():get_impact_enginer():get_logic(imp):get_trap_count_of_specific_type(imp,o,class)
    end
    function c:add_trap(imp,o,trap)
        return o:get_scene():get_impact_enginer():get_logic(imp):add_new_trap(imp,o,trap:get_obj_id())
    end
    function c:new_trap_tracker(o,id)
        local imp=require("scene.skill.impact").new()
        assert(o:get_scene():get_impact_enginer():init_impact_from_data(id,imp),"tracker data missing")
        assert(imp:get_logic_id()==8052,"donor tracker must use eleven-slot logic8052")
        return imp
    end
    function c:register_tracker(o,imp,delay,skill)
        return self:emit_impact(o,o,imp,delay,skill)
    end
    function c:create_trap(o,p,id,skill)
        local trap=o:skill_create_obj_specail(p,id,skill)
        if trap then trap._cy_four_armed=false end
        return trap
    end
    function c:set_trap_skill(o,s) return o:set_skill_id(s.engine_impact:get_skill_id()) end
    function c:activate_trap(o,trap,delay)
        -- Existing eventenginer ignores delay. Schedule explicitly for donor traps.
        local scene=o:get_scene();local id=trap:get_obj_id()
        require("skynet").timeout(math.ceil(delay/10),function()
            if scene:get_obj_by_id(id)==trap and not trap:is_fade_out() then trap._cy_four_armed=true end
        end)
    end
    for name,fn in pairs(extensions or {}) do assert(type(fn)=="function","adapter extension must be function");c[name]=fn end
    return c
end
return M
