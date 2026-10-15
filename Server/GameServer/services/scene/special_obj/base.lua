local class = require "class"
local define = require "define"
local base = class("base")
base.eSpecailObjType = {
    SPECIAL_OBJ_TYPE = define.INVALID_ID,
    TRAP_OBJ = 0,
    TOTEM_OBJ = 1,
}
base.type = base.eSpecailObjType.SPECIAL_OBJ_TYPE

function base:ctor()
end

function base:get_type()
    return self.type
end

function base:on_tick()

end

function base:on_time_over()

end

function base:is_scaned_target_vaild()

end

return base