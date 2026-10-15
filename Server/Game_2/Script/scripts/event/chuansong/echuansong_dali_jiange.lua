local class = require "class"
local script_base = require "script_base"
local chuan_song = class("chuan_song", script_base)
local dunhuang = { 7, 75, 76}
function chuan_song:on_enter_area(scene, obj)
     if self:LuaFnGetDestSceneHumanCount(dunhuang[1]) < 100 then
          local to_scene_id =  dunhuang[1]
          self:CallScriptFunction((400900), "TransferFunc", obj:get_obj_id(), to_scene_id,40,278,1)
          return
     end
     if self:LuaFnGetDestSceneHumanCount(dunhuang[2]) < 200 then
          local to_scene_id =  dunhuang[2]
          self:CallScriptFunction((400900), "TransferFunc", obj:get_obj_id(), to_scene_id,40,278,1)
          return
     end
     if self:LuaFnGetDestSceneHumanCount(dunhuang[3]) < 200 then
          local to_scene_id =  dunhuang[3]
          self:CallScriptFunction((400900), "TransferFunc", obj:get_obj_id(), to_scene_id,40,278,1)
          return
     end
     self:notify_tips(obj:get_obj_id(), "Cảnh đích đã đủ người")
end

return chuan_song
