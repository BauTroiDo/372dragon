-- Five JueQing success branches from donor hook0xa173c, suffix0xa1b53.
-- These are post-cast operations, not ordinary target impacts in logic0.
local M={}
local SOURCES={
    [3840]={mode="conditional_self",p4=13262,p5=4890},
    [3842]={mode="dispel_self",p4=13262},
    [3851]={mode="append_self",p4=13263},
    [3846]={mode="append_self",p4=13264},
    [3847]={mode="append_self",p4=13264},
}
M.required_capabilities={"is_human","has_scene","donor_faction","has_impact","send_specific","dispel_impact"}
local function number(v) return type(v)=="number" and math.tointeger(v) end
local function resolved(config,kind,id)
    local map=config.resolve and config.resolve[kind]
    return map and (map[id] or map[tostring(id)])
end
function M.readiness(config,c)
    local missing={}
    local function need(ok,why) if not ok then missing[#missing+1]=why end end
    for _,name in ipairs(M.required_capabilities) do need(type(c[name])=="function","jue adapter:"..name) end
    local rows=config.jue_skill_instances
    need(type(rows)=="table","jue_skill_instances required")
    local covered={}
    if type(rows)=="table" then
        for target,row in pairs(rows) do
            if type(row)~="table" then need(false,"invalid Jue sidecar row")
            else
                local source=SOURCES[row.donor_template_id]
                need(source~=nil,"unverified Jue donor template:"..tostring(row.donor_template_id))
                need(number(target) and target>0,"numeric target SkillData key required")
                need(number(row.donor_data_id) and resolved(config,"skill_data",row.donor_data_id)==target,"SkillData namespace mismatch:"..tostring(target))
                need(number(row.target_template_id) and resolved(config,"skill_templates",row.donor_template_id)==row.target_template_id,"template namespace mismatch:"..tostring(target))
                need(row.donor_logic==0,"source Jue skill logic must be0")
                if source then
                    covered[row.donor_template_id]=true
                    need(number(row.p4) and row.p4>0 and row.p4==resolved(config,"impacts",source.p4),"p4 impact namespace mismatch:"..tostring(target))
                    if source.p5 then need(number(row.p5) and row.p5>0 and row.p5==resolved(config,"impacts",source.p5),"p5 impact namespace mismatch:"..tostring(target))
                    else need(row.p5==0 or row.p5==-1,"unexpected p5:"..tostring(target)) end
                end
            end
        end
    end
    for source in pairs(SOURCES) do need(covered[source],"missing Jue template sidecar:"..source) end
    return #missing==0,missing
end
function M.new(config,c)
    local ready,missing=M.readiness(config,c)
    assert(ready,"unready Jue success hooks: "..table.concat(missing,", "))
    local self={config=config,context=c,by_template={}}
    for source in pairs(SOURCES) do self.by_template[resolved(config,"skill_templates",source)]=source end
    function self:on_use_skill_successfully(owner,info)
        -- The caller emits this event once for a successful cast. Never call
        -- it during condition checks, charging, cancellation or failed casts.
        if self.config.gameplay_enabled~=true then return false end
        if not owner or not info or not c:is_human(owner) or not c:has_scene(owner) or c:donor_faction(owner)~=14 then return false end
        local target_template=info:get_skill_id()
        local donor=self.by_template[target_template]
        if not donor then return false end
        local row=assert(self.config.jue_skill_instances[info._cy_four_data_id],"missing actual Jue SkillData sidecar")
        assert(row.target_template_id==target_template and row.donor_template_id==donor,"Jue success SkillData/template mismatch")
        local mode=SOURCES[donor].mode
        if mode~="dispel_self" and self.config.disabled_impacts and self.config.disabled_impacts[row.p4] then
            return false,"disabled_impact" -- Preserve the explicit client171 gate.
        end
        if mode=="conditional_self" then
            if not c:has_impact(owner,row.p5) then return false end
            c:send_specific(owner,owner,row.p4)
        elseif mode=="dispel_self" then
            -- Native DispelSpecificImpactByDataIndex(self,p4,1). Runtime
            -- adapter cancellation executes OnFadeOut, as flag1 requires.
            c:dispel_impact(owner,row.p4,1)
        else c:send_specific(owner,owner,row.p4) end
        return true
    end
    return self
end
return M
