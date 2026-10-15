local class = require "class"
local script_base = require "script_base"
local chuan_song_luoyang_yannan = class("chuan_song_luoyang_yannan", script_base)

function chuan_song_luoyang_yannan:on_enter_area(scene, obj)
     if self:LuaFnGetDestSceneHumanCount(8) < 400 then
          self:CallScriptFunction((400900), "TransferFunc", obj:get_obj_id(), 8, 276, 145)
     else
          obj:notify_tips("Cảnh đích đã đủ người")
     end
end

return chuan_song_luoyang_yannan