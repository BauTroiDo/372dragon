local class = require "class"
local base = require "scene.obj.base"
local static = class("static", base)

function static:ctor()
end

function static:get_agent()
end

function static:get_speed()
    return 0
end

function static:get_name()
    return "static"
end

function static:get_obj_type()
    return "static"
end

return base