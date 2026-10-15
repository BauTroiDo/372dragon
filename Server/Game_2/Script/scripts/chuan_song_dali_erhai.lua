local class = require "class"
local script_base = require "script_base"
local chuan_song_dali_erhai = class("chuan_song_dali_erhai", script_base)

function chuan_song_dali_erhai:on_enter_area(scene, obj)
     self:CallScriptFunction((400900), "TransferFunc", obj:get_obj_id(), 24, 280, 37)
end

return chuan_song_dali_erhai