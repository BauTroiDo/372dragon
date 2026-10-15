local class = require "class"
local script_base = require "script_base"
local chuan_song = class("chuan_song", script_base)
local dunhuang = {6, 73, 74}
function chuan_song:on_enter_area(scene, obj)
     local to_scene_id =  dunhuang[math.random(1, #dunhuang)]
     self:CallScriptFunction((400900), "TransferFunc", obj:get_obj_id(), to_scene_id, 43, 172, 1)
end

return chuan_song
