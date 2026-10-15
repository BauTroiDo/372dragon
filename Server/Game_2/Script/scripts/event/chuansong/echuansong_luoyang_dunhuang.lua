local class = require "class"
local script_base = require "script_base"
local chuan_song_luoyang_yannan = class("chuan_song_luoyang_yannan", script_base)
local dunhuang = { 8, 1313, 1314, 1317, 1318, 1319}
function chuan_song_luoyang_yannan:on_enter_area(scene, obj)
     if self:LuaFnGetDestSceneHumanCount(dunhuang[1]) < 200 then
          self:CallScriptFunction((400900), "TransferFunc", obj:get_obj_id(), dunhuang[1], 276, 145)
          return
     end
     if self:LuaFnGetDestSceneHumanCount(dunhuang[2]) < 200 then
          self:CallScriptFunction((400900), "TransferFunc", obj:get_obj_id(), dunhuang[2], 276, 145)
          return
     end
     if self:LuaFnGetDestSceneHumanCount(dunhuang[3]) < 200 then
          self:CallScriptFunction((400900), "TransferFunc", obj:get_obj_id(), dunhuang[3], 276, 145)
          return
     end
     if self:LuaFnGetDestSceneHumanCount(dunhuang[4]) < 200 then
          self:CallScriptFunction((400900), "TransferFunc", obj:get_obj_id(), dunhuang[4], 276, 145)
          return
     end
     if self:LuaFnGetDestSceneHumanCount(dunhuang[5]) < 200 then
          self:CallScriptFunction((400900), "TransferFunc", obj:get_obj_id(), dunhuang[5], 276, 145)
          return
     end
     if self:LuaFnGetDestSceneHumanCount(dunhuang[6]) < 200 then
          self:CallScriptFunction((400900), "TransferFunc", obj:get_obj_id(), dunhuang[6], 276, 145)
          return
     end
     self:notify_tips(obj:get_obj_id(), "Cảnh đích đã đủ người")
end

return chuan_song_luoyang_yannan