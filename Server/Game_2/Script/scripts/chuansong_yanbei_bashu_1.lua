local class = require "class"
local script_base = require "script_base"
local chuansong_yanbei_bashu_1 = class("chuansong_yanbei_bashu_1", script_base)

function chuansong_yanbei_bashu_1:on_enter_area(scene, obj)
     self:CallScriptFunction((400900), "TransferFunc", obj:get_obj_id(), 159, 68, 95, 202)
end

return chuansong_yanbei_bashu_1