local class = require "class"
local script_base = require "script_base"
local chuan_song_jiange_dali = class("chuan_song_jiange_dali", script_base)

function chuan_song_jiange_dali:on_enter_area(scene, obj)
     self:CallScriptFunction((400900), "TransferFunc", obj:get_obj_id(), 71, 39, 152,1)
end

return chuan_song_jiange_dali