local class = require "class"
local script_base = require "script_base"
local chuan_song = class("chuan_song", script_base)

function chuan_song:on_enter_area(scene, obj)
     local nSceneInfo = {2,1302}
     local IsOpen = 0
     for i = 1,#nSceneInfo do
         if self:LuaFnGetDestSceneHumanCount(nSceneInfo[i]) < 300 then
             IsOpen = i
             break
         end
     end
     if IsOpen ~= 0 then
         self:CallScriptFunction((400900), "TransferFunc",  obj:get_obj_id(), nSceneInfo[IsOpen], 160, 277) --根据人数分配玩家所进入的场景。
         return
     else
         self:notify_tips(obj:get_obj_id(),"Cảnh Đại Lý đã đủ người, xin tạm sang bản đồ khác.")
         return
     end
     --self:CallScriptFunction((400900), "TransferFunc", obj:get_obj_id(), 2,160,277)
end

return chuan_song