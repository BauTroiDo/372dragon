local class = require "class"
local define = require "define"
local script_base = require "script_base"
local yanziwu_area = class("yanziwu_area", script_base)
yanziwu_area.g_SceneId = 4
yanziwu_area.g_X = 70
yanziwu_area.g_Z = 120

function yanziwu_area:on_enter_area(scene, obj)
     self:CallScriptFunction((400900), "TransferFunc", obj:get_obj_id(), self.g_SceneId, self.g_X, self.g_Z)
end

return yanziwu_area
