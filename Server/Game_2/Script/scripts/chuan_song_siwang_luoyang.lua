local class = require "class"
local script_base = require "script_base"
local chuan_song_siwang_luoyang = class("chuan_song_siwang_luoyang", script_base)

function chuan_song_siwang_luoyang:on_enter_area(scene, obj)
     self:CallScriptFunction((400900), "TransferFunc", obj:get_obj_id(), 0, 196, 317)
end

return chuan_song_siwang_luoyang