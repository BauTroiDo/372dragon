local class = require "class"
local define = require "define"
local base = require "scene.skill.impact_logic.base"
local std_impact_036 = class("std_impact_036", base)

function std_impact_036:is_over_timed()
    return true
end

function std_impact_036:is_intervaled()
    return false
end

function std_impact_036:get_refix_detect_level(imp, args)
    local value = imp.params["反隐级别修正（0为无效）"]
    if value ~= define.INVAILD_ID then
        args.replace = value
    end
end

return std_impact_036