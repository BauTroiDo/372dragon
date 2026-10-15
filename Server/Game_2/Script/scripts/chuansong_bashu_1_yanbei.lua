local class = require "class"
local script_base = require "script_base"
local chuansong_bashu_1_yanbei = class("chuansong_bashu_1_yanbei", script_base)

function chuansong_bashu_1_yanbei:on_enter_area(scene, obj)
     self:CallScriptFunction((400900), "TransferFunc", obj:get_obj_id(), 19, 142, 256)
end

return chuansong_bashu_1_yanbei