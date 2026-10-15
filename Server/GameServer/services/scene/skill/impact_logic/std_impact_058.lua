local class = require "class"
local base = require "scene.skill.impact_logic.base"
local std_impact_058 = class("std_impact_058", base)

function std_impact_058:ctor()

end

function std_impact_058:is_over_timed()
    return false
end

function std_impact_058:is_intervaled()
    return false
end

function std_impact_058:get_add_friend_point(imp)
    return imp.params["改善的友好度数值"] or 0
end

function std_impact_058:on_active(imp, obj)
    if not obj:is_alive() then
        return
    end
    local add_value = self:get_add_friend_point(imp)
    local caster_id = imp:get_caster_obj_id()
    local sender = obj:get_scene():get_obj_by_id(caster_id)
    local my_relation = obj:get_relation_info()
    local other_relation = sender:get_relation_info()
    for _, friend in ipairs(my_relation.friends) do
        if friend.guid == sender:get_guid() then
            friend.friend_point = (friend.friend_point or 0) + add_value
            break
        end
    end
    for _, friend in ipairs(other_relation.friends) do
        if friend.guid == obj:get_guid() then
            friend.friend_point = (friend.friend_point or 0) + add_value
            break
        end
    end
    obj:set_relation_info(my_relation)
    sender:set_relation_info(other_relation)
end

return std_impact_058