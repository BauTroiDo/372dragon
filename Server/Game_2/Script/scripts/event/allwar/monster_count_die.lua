local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local monster_count_die = class("monster_count_die", script_base)
-- local gbk = require "wire_charset"
--非配置信息
monster_count_die.script_id = 999970
function monster_count_die:OnDie(objId,killerId)
	local obj = self.scene:get_obj_by_id(objId)
	if not obj then
		return
	end
	local ai = obj:get_ai()
	local index = ai:get_int_param_by_index(11)
	local respawn_time = ai:get_int_param_by_index(12)
	-- self:LOGI("index:",index,"respawn_time:",respawn_time)
    -- self:BeginEvent(self.script_id)
    -- self:AddText("index:"..index..",respawn_time:"..respawn_time)
    -- self:EndEvent()
    -- self:DispatchEventList(killerId,killerId)
	if index > 100 and respawn_time > 0 then
		self.scene:set_param(index,respawn_time + os.time())
	end
end
return monster_count_die