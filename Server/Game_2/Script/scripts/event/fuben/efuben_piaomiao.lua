--飘渺
--脚本号
local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local efuben_piaomiao = class("efuben_piaomiao", script_base)

function efuben_piaomiao:on_enter_area(scene, obj)
    self:get_scene():notify_change_scene(obj:get_obj_id(), 186, 190, 220, 246)
end
return efuben_piaomiao