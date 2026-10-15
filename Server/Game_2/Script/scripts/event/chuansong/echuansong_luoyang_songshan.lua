local class = require "class"
local script_base = require "script_base"
local chuan_song_luoyang_yannan = class("chuan_song_luoyang_yannan", script_base)
local dunhuang = { 3, 1322 }
function chuan_song_luoyang_yannan:on_enter_area(scene, obj)
     if self:LuaFnGetDestSceneHumanCount(dunhuang[1]) < 200 then
          self:CallScriptFunction((400900), "TransferFunc", obj:get_obj_id(), dunhuang[1],42,54, 1)
          return
     end
     if self:LuaFnGetDestSceneHumanCount(dunhuang[2]) < 200 then
          self:CallScriptFunction((400900), "TransferFunc", obj:get_obj_id(), dunhuang[2],42,54, 1)
          return
     end
     self:notify_tips(obj:get_obj_id(), "Cảnh đích đã đủ người")
end

return chuan_song_luoyang_yannan