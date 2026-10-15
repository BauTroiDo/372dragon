local class = require "class"
local script_base = require "script_base"
local chuan_song = class("chuan_song", script_base)
local dunhuang = { 8, 1313, 1314}
function chuan_song:on_enter_area(scene, obj)
     if self:LuaFnGetDestSceneHumanCount(dunhuang[1]) < 300 then
          self:CallScriptFunction((400900), "TransferFunc", obj:get_obj_id(), dunhuang[1],230,270, 10)
          return
     end
     if self:LuaFnGetDestSceneHumanCount(dunhuang[2]) < 400 then
          self:CallScriptFunction((400900), "TransferFunc", obj:get_obj_id(), dunhuang[2],230,270, 10)
          return
     end
     if self:LuaFnGetDestSceneHumanCount(dunhuang[3]) < 400 then
          self:CallScriptFunction((400900), "TransferFunc", obj:get_obj_id(), dunhuang[3],230,270, 10)
          return
     end
     self:notify_tips(obj:get_obj_id(), "Cảnh đích đã đủ người")
end

return chuan_song
