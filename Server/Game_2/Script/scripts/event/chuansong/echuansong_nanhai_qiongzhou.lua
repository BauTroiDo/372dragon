local class = require "class"
local script_base = require "script_base"
local chuan_song = class("chuan_song", script_base)

function chuan_song:on_enter_area(scene, obj)
     self:CallScriptFunction((400900), "TransferFunc", obj:get_obj_id(), 35,275,277)
end

return chuan_song