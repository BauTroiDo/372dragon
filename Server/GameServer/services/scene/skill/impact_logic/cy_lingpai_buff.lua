local class=require 'class'
local base=require 'scene.skill.impact_logic.base'
local C=class('cy_lingpai_buff',base)
function C:is_over_timed()return true end
function C:on_active(imp,receiver)
    local chosen=imp.params.cy_convert
    if chosen then
        local names={'cold','fire','light','poison'};local values={};local sum=0
        for i,name in ipairs(names)do values[i]=receiver['get_attack_'..name](receiver);sum=sum+values[i]end
        for i,name in ipairs(names)do imp.params['cy_delta_'..name]=(i==chosen and sum or 0)-values[i]end
        self:mark_modified_attr_dirty(imp,receiver)
    end
end
for _,element in ipairs({'cold','fire','light','poison'})do
    C['get_refix_att_'..element]=function(self,imp,args)
        args.point=(args.point or 0)+(imp.params['cy_delta_'..element] or 0)
    end
end
function C:on_be_heal(imp,obj,sender,health,skill_id)
    if (skill_id or -1)<1 then return end -- CY says healing skills, not food/natural regeneration
    local rate=imp.params.cy_heal_reduction or 0
    if rate>0 and health.hp_modify>0 then health.hp_modify=math.ceil(health.hp_modify*(100-rate)/100)end
end
function C:refix_critical_rate(imp,rate)
    return (imp.params.cy_critical or 0)>0 and 1 or rate
end
function C:on_damage_target(imp,owner,target,damages,skill_id,damage_imp)
    if not imp.params.cy_critical or (skill_id or -1)<1 or not damage_imp then return end
    local sequence=damage_imp:get_caster_logic_count()
    if imp.params.cy_last_attack==sequence then return end
    imp.params.cy_last_attack=sequence;imp.params.cy_critical=imp.params.cy_critical-1
    if imp.params.cy_critical<=0 then owner:on_impact_fade_out(imp);owner:remove_impact(imp)end
end
return C
