-- Native resource fields are packed mission328/331/332, never life-skill energy.
-- RE: client/native-resource-evidence. Mixed MP/empathy is an explicit repair
-- from source tooltips, not a claim of native parity for malformed donor rows.
local num=require "cy_four_combat.numeric"
local M={}
local TAO={[3801]=true,[3818]=true,[3819]=true,[3806]=true,[3807]=true,[3809]=true,[3820]=true,[3822]=true}
local JUE={[3851]=true,[3846]=true,[3847]=true,[3843]=true}
local function integer(v) local n=math.tointeger(v);assert(n,"integer resource value required");return n end
local function packed(v,base)
    v=integer(v);assert(v>=0,"negative packed resource state")
    return v//base,v%base
end
local function info_id(info) return info:get_skill_id() end
function M.new(config,c)
    assert(type(config.resource_costs or {})=="table")
    for _,name in ipairs{"resource_get","resource_set","get_doll_id","donor_faction","talent_level","random_1000","float2int"} do
        assert(type(c[name])=="function","resource adapter missing: "..name)
    end
    local self={config=config,context=c,pending=setmetatable({},{__mode="k"})}
    local function round(value) return c:float2int(value) end
    local reverse={}
    for source,target in pairs(assert(config.resolve.skill_templates)) do reverse[target]=tonumber(source) end
    local function result(o,ok,err)
        local d=require "define"
        o:get_targeting_and_depleting_params():set_errcode(ok and d.OPERATE_RESULT.OR_OK or d.OPERATE_RESULT[err or "OR_U_CANNT_DO_THIS_RIGHT_NOW"])
        return ok
    end
    function self:repair(info)
        return (self.config.resource_costs or {})[info._cy_four_data_id]
    end
    function self:proposal(o,data,selected_doll)
        local info=o:get_skill_info();local repair=self:repair(info)
        if data.type==4 and not repair then return nil end
        if data.type~=4 and data.type~=8016 and data.type~=8017 and data.type~=8018 then return nil end
        assert(o:get_obj_type()=="human","four-school resource condition requires human")
        local faction=c:donor_faction(o);local donor=assert(reverse[info_id(info)],"resource skill is not imported")
        if data.type==8018 then return {kind="collection",value=integer(data.params[1])} end
        local need=math.max(0,integer(data.params[1]));local doll=selected_doll
        if doll==nil then doll=c:get_doll_id(o)>0 end
        if repair then
            assert(faction==13 and repair.mode=="doll_alternative","invalid source resource repair")
            assert(need==integer(data.type==4 and repair.mp or repair.empathy),"repaired resource cost changed")
            if data.type==4 then return {kind=doll and "skip" or "mp",need=need} end
            assert(data.type==8016,"mixed cost requires empathy condition")
            return {kind=doll and "empathy" or "skip",need=need}
        end
        if data.type==8016 then
            assert(faction==13 and TAO[donor],"unproven Tao resource skill")
            return {kind="empathy",need=need,requires_doll=donor~=3801 and donor~=3818 and donor~=3819}
        end
        assert(data.type==8017 and faction==14 and JUE[donor],"unproven Jue resource skill")
        return {kind="blade",need=need}
    end
    function self:check_proposal(o,p)
        if p.kind=="skip" then return result(o,true) end
        if p.kind=="collection" then return result(o,not o:impact_have_impact_in_specific_collection(p.value)) end
        if p.requires_doll and c:get_doll_id(o)<=0 then return result(o,false) end
        local current
        if p.kind=="mp" then current=o:get_mp()
        elseif p.kind=="empathy" then local _,v=packed(c:resource_get(o,328),10000);current=v
        else local _,v=packed(c:resource_get(o,331),10);current=v end
        if current<p.need then require("cy_four_combat.resource_feedback").notify(o,true)end
        return result(o,current>=p.need,"OR_LACK_MANA")
    end
    function self:condition_check(o,data)
        local p=self:proposal(o,data);assert(p,"not a resource condition")
        local ok=self:check_proposal(o,p)
        if not ok then self.pending[o]=nil end
        return ok
    end
    function self:deplete(o,data)
        local info=o:get_skill_info();local pending=self.pending[o]
        if not pending or pending.info~=info then pending={info=info,id=info_id(info),data_id=info._cy_four_data_id,costs={}} end
        if self:repair(info) and pending.selected_doll==nil then pending.selected_doll=c:get_doll_id(o)>0 end
        local p=self:proposal(o,data,pending.selected_doll);assert(p)
        if not self:check_proposal(o,p) then self.pending[o]=nil;return false end
        if p.kind=="collection" then return true end
        self.pending[o]=pending
        if p.kind=="skip" then return true end
        pending.costs[data.type]=p -- repeated Deplete for one cast cannot double-charge.
        return true
    end
    function self:cancel(o,info)
        local p=self.pending[o]
        if p and (not info or p.info==info) then self.pending[o]=nil end
    end
    function self:refund_empathy_talent(o,spent)
        local level=integer(c:talent_level(o,0));assert(level>=0 and level<=5)
        local threshold=({[0]=0,30,70,120,250,0})[level]
        if level>0 and c:random_1000()<=threshold then
            local cap,current=packed(c:resource_get(o,328),10000)
            current=math.max(0,current+num.scale(spent,10,100,round))
            c:resource_set(o,328,cap*10000+current)
        end
    end
    function self:on_use_skill_successfully(o,info)
        local pending=self.pending[o]
        if not pending then return false end
        self.pending[o]=nil -- clear before callbacks/re-entry.
        if pending.info~=info or pending.id~=info_id(info) or pending.data_id~=info._cy_four_data_id then return false end
        for _,p in pairs(pending.costs) do
            if p.kind=="mp" then o:mana_increment(-p.need,o)
            else
                local field,base=p.kind=="empathy" and 328 or 331,p.kind=="empathy" and 10000 or 10
                local cap,current=packed(c:resource_get(o,field),base)
                c:resource_set(o,field,cap*base+math.max(0,current-p.need))
                if p.kind=="empathy" then self:refund_empathy_talent(o,p.need) end
            end
        end
        require("cy_four_combat.resource_feedback").notify(o,true)
        return true
    end
    function self:on_rage_regeneration(o,periods)
        if periods<=0 or o:get_obj_type()~="human" or not o:get_scene() then return end
        local faction=c:donor_faction(o)
        if faction==13 then
            local _,current=packed(c:resource_get(o,328),10000);local cap,regen=1000,80
            for _,imp in ipairs(o:get_impact_list()) do
                local r=config.impacts[imp:get_data_index()]
                if r and r.donor_id>=4272 and r.donor_id<=4283 then cap=cap+integer(r.params[1]) end
                if r and r.donor_id>=4284 and r.donor_id<=4295 then regen=num.scale(regen,100+integer(r.params[1]),100,round) end
            end
            current=math.max(0,math.min(cap,current+(c:get_doll_id(o)>0 and -15 or regen)))
            if current==0 and c:get_doll_id(o)>0 then assert(c.clear_doll,"validated doll cleanup adapter required")(c,o) end
            c:resource_set(o,328,cap*10000+current)
        elseif faction==14 then
            local ticks=integer(c:resource_get(o,332));local nextticks=ticks+1
            local level=integer(c:talent_level(o,11));assert(level>=0 and level<=5)
            local threshold=20-({[0]=0,1,2,3,4,6})[level]
            if ticks>=threshold then
                local _,current=packed(c:resource_get(o,331),10);local cap=3
                local sid=config.resolve.skill_templates[3855] or config.resolve.skill_templates['3855']
                local buff=config.resolve.impacts[53252] or config.resolve.impacts['53252']
                if (sid and o:have_skill(sid)) or (buff and o:impact_get_first_impact_of_specific_data_index(buff)) then cap=4 end
                c:resource_set(o,331,cap*10+math.min(cap,current+1));nextticks=0
            end
            c:resource_set(o,332,nextticks)
        end
        require("cy_four_combat.resource_feedback").notify(o,false)
    end
    return self
end
-- Thin routing hook: preserve every old condition ID, including live16.
function M.dispatch(phase,o,data)
    local engine=o:get_scene() and o:get_scene():get_impact_enginer()
    local bridge=engine and engine.cy_four_bridge
    local instance=bridge and bridge.resources
    local owned=data.type==8016 or data.type==8017 or data.type==8018
    local mixed=data.type==4 and instance and instance:repair(o:get_skill_info())
    if not owned and not mixed then return false end
    assert(instance,"four-school resource bridge is not configured")
    return true,instance[phase](instance,o,data)
end
return M
