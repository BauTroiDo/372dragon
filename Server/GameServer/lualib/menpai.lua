local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local menpai = {}
menpai.influence = {
    hp_max = {
        init = "AINFOTYPE0",
        con = "AINFOTYPE1",
        level = "AINFOTYPE2"
    },
    mp_max = {
        init = "AINFOTYPE6",
        int = "AINFOTYPE7",
        level = "AINFOTYPE8"
    },
    attrib_att_physics = {
        init = "AINFOTYPE12",
        str = "AINFOTYPE13",
        level = "AINFOTYPE14"
    },
    attrib_att_magic = {
        init = "AINFOTYPE15",
        spr = "AINFOTYPE16",
        level = "AINFOTYPE17"
    },
    attrib_def_physics = {
        init = "AINFOTYPE18",
        con = "AINFOTYPE19",
        level = "AINFOTYPE20"
    },
    attrib_def_magic = {
        init = "AINFOTYPE21",
        int = "AINFOTYPE22",
        level = "AINFOTYPE23"
    },
    attrib_hit = {
        init = "AINFOTYPE24",
        dex = "AINFOTYPE25",
        level = "AINFOTYPE26"
    },
    attrib_miss = {
        init = "AINFOTYPE27",
        dex = "AINFOTYPE28",
        level = "AINFOTYPE29"
    },
    mind_attack = {
        init = "AINFOTYPE30",
        dex = "AINFOTYPE31",
        level = "AINFOTYPE32"
    },
    mind_defend = {
        init = "AINFOTYPE33",
        dex = "AINFOTYPE34",
        level = "AINFOTYPE35"
    },
}

function menpai:on_damage(obj_me, damage)
    if damage <= 0 then
        return
    end
    local rage = 5
    obj_me:rage_increment(rage, obj_me)
end

function menpai:on_damage_target(obj_me, damage)
    if damage <= 0 then
        return
    end
    local rage = 7
    obj_me:rage_increment(rage, obj_me)
end

function menpai:on_heart_beat(obj_me)
    require("cy_four_combat.hooks").on_rage_regeneration(obj_me, 1)
    obj_me:rage_increment(2, obj_me)
end

function menpai:on_hit_target(obj_me, skill)
    if obj_me:get_menpai() == define.MENPAI_ATTRIBUTE.MATTRIBUTE_MANTUOSHANZHUANG then
        if skillenginer:is_skill_in_collection(skill, define.MANTUO_XUANYINQV_COLLECTION_ID) then
            obj_me:datura_flower_increment(1, obj_me)
        end
    end
end

return menpai