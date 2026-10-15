local class = require "class"
local script_base = require "script_base"
local chuan_song_jiange_dunhuang = class("chuan_song_jiange_dunhuang", script_base)

function chuan_song_jiange_dunhuang:on_enter_area(scene, obj)
     self:CallScriptFunction((400900), "TransferFunc", obj:get_obj_id(), 8, 230, 270,10)
end

return chuan_song_jiange_dunhuang