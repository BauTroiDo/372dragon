local class = require "class"
local script_base = require "script_base"
local chuan_song = class("chuan_song", script_base)
local chuansong_configs = {
     [2] = 76,
     [71] = 73,
     [72] = 73,
     [1320] = 74,
     [1321] = 74
}
function chuan_song:on_enter_area(scene, obj)
     local from_scene_id = self:get_scene():get_id()
     local to_scene_id = chuansong_configs[from_scene_id]
     self:CallScriptFunction((400900), "TransferFunc", obj:get_obj_id(), to_scene_id, 43, 172, 1)
end

return chuan_song