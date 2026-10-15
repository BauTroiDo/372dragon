local class = require "class"
local script_base = require "script_base"
local chuan_song = class("chuan_song", script_base)

function chuan_song:on_enter_area(scene, obj)
	local sceneId = scene:get_id()
     self:CallScriptFunction((400900), "TransferFunc", obj:get_obj_id(),sceneId, 223, 215)
end

return chuan_song
