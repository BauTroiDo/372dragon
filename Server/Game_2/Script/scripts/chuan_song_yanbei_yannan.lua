local class = require "class"
local script_base = require "script_base"
local chuan_song_yanbei_yannan = class("chuan_song_yanbei_yannan", script_base)

function chuan_song_yanbei_yannan:on_enter_area(scene, obj)
     self:CallScriptFunction((400900), "TransferFunc", obj:get_obj_id(), 18, 248, 43)
end

return chuan_song_yanbei_yannan