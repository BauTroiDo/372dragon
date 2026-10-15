local class = require "class"
local define = require "define"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_350 = class("std_impact_350", base)

function std_impact_350:get_refix_mind_attack(imp, args, obj)
    local rate = imp.params["会心修正%(0为无效)"] or 0
    args.rate = (args.rate or 0) + rate
end

return std_impact_350