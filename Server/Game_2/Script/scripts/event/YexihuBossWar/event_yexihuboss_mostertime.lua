local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local event_yexihuboss_mostertime = class("event_yexihuboss_mostertime", script_base)
-- local gbk = require "wire_charset"
event_yexihuboss_mostertime.script_id = 999993

function event_yexihuboss_mostertime:OnHeartBeat(objId, nTick)
	local obj = self.scene:get_obj_by_id(objId)
	if obj and obj:is_alive() then
		local ai = obj:get_ai()
		if ai:get_int_param_by_index(1) == obj:get_model() then
			local curtime = os.time()
			if curtime > ai:get_int_param_by_index(2) then
				self.scene:delete_temp_monster(obj)
				local mostercount = self:GetMonsterCount()
				local mosterid,mosterdata
				for i = 1,mostercount do
					mosterid = self:GetMonsterObjID(i)
					obj = self.scene:get_obj_by_id(mosterid)
					if obj then
						mosterdata = obj:get_model()
						if mosterdata == 99998
						or mosterdata == 99999
						or mosterdata == 52338 then
							self.scene:delete_temp_monster(obj)
						end
					end
				end
				local boxpos = 
				{ 
					--第一个水晶
					[1] = 
					{
						world_pos = {x = -1, y = -1}, --水晶位置
						league_id = -1, --占领水晶同盟id
						guild_id = -1, --占领水晶帮会id
						league_name = "", --占领水晶同盟名称
						hp = 0, -- 写死传0
					},
					--第二个水晶
					[2] = 
					{
						world_pos = {x = -1, y = -1}, --水晶位置
						league_id = -1, --占领水晶同盟id
						guild_id = -1, --占领水晶帮会id
						league_name = "", --占领水晶同盟名称
						hp = 0, -- 写死传0
					},
					--第三个水晶
					[3] = 
					{
						world_pos = {x = -1, y = -1}, --水晶位置
						league_id = -1, --占领水晶同盟id
						guild_id = -1, --占领水晶帮会id
						league_name = "", --占领水晶同盟名称
						hp = 0, -- 写死传0
					},
					--第四个水晶
					[4] = 
					{
						world_pos = {x = -1, y = -1}, --水晶位置
						league_id = -1, --占领水晶同盟id
						guild_id = -1, --占领水晶帮会id
						league_name = "", --占领水晶同盟名称
						hp = 0, -- 写死传0
					},
				}
				self:DispatchPhoenixPlainWarCrystalPos(boxpos)
			end
		end
	end
end
return event_yexihuboss_mostertime

