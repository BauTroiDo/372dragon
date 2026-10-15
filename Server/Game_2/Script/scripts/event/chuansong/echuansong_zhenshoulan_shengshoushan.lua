--事件
--事件：传送到圣兽山

local class = require "class"
local script_base = require "script_base"
local chuansong_to_shengshoushan = class("chuansong_to_shengshoushan", script_base)
local g_MissionName="#{QSSS_090302_1}"

function chuansong_to_shengshoushan:on_enter_area(scene, obj)
	self:CallScriptFunction((400900), "TransferFunc", obj:get_obj_id(), 158, 233, 225, 21)
end

return chuansong_to_shengshoushan