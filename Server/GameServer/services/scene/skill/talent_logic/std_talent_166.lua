local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_166 = class("std_talent_166", base)
function std_talent_166:on_stealth_level_update(talent, level, obj_me)
    if obj_me:get_stealth_level() > 0 then
        impactenginer:send_impact_to_unit(obj_me, 63028, obj_me, 0, false, 0) -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
    end
end

return std_talent_166