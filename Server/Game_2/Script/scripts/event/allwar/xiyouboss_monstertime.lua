local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local xiyouboss_monstertime = class("xiyouboss_monstertime", script_base)
-- local gbk = require "wire_charset"
xiyouboss_monstertime.script_id = 999975
xiyouboss_monstertime.needsactId = 398
xiyouboss_monstertime.scene_delboxtime = 27
function xiyouboss_monstertime:OnHeartBeat(objId, nTick)
	local obj = self.scene:get_obj_by_id(objId)
	if obj and obj:is_alive() then
		if obj:get_model() ~= 52338 then
			return
		end
		local delboxtime = self.scene:get_param(self.scene_delboxtime)
		local curtime = os.time()
		if curtime > delboxtime then
			self.scene:delete_temp_monster(obj)
			local mostercount = self:GetMonsterCount()
			local mosterid,value
			for i = 1,mostercount do
				mosterid = self:GetMonsterObjID(i)
				obj = self.scene:get_obj_by_id(mosterid)
				if obj then
					value = obj:get_model()
					if value == 99998
					or value == 99999
					or value == 52338 then
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
return xiyouboss_monstertime

