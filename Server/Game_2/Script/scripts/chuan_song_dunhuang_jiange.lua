local class = require "class"
local script_base = require "script_base"
local chuan_song_dunhuang_jiange = class("chuan_song_dunhuang_jiange", script_base)

function chuan_song_dunhuang_jiange:on_enter_area(scene, obj)
     self:CallScriptFunction((400900), "TransferFunc", obj:get_obj_id(), 7, 106, 47,1)
end

return chuan_song_dunhuang_jiange