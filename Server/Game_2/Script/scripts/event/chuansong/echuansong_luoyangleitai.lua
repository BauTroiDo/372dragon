local class = require "class"
local define = require "define"
local script_base = require "script_base"
local echuansong_luoyangleitai = class("echuansong_luoyangleitai", script_base)
echuansong_luoyangleitai.script_id = 400916
echuansong_luoyangleitai.g_ChallengeScriptId = 806012
function echuansong_luoyangleitai:on_enter_area(scene, obj)
	self:CallScriptFunction((400900), "TransferFunc", obj:get_obj_id(), 0, 186, 327)
end

return echuansong_luoyangleitai