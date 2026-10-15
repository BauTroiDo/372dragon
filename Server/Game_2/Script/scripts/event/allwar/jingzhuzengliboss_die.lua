local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local jingzhuzengliboss_die = class("jingzhuzengliboss_die", script_base)
-- local gbk = require "wire_charset"
jingzhuzengliboss_die.script_id = 999991
function jingzhuzengliboss_die:OnDie(objId,killerId)
	if objId == killerId then
		return
	end
	local scene = self:get_scene()
	local obj = scene:get_obj_by_id(objId)
	if not obj or obj:get_obj_type() ~= "monster" then
		return
	end
	local item_num = obj:get_scene_params(define.MONSTER_KILLBOX_ITEM_COUNT)
	if item_num > 0 then
		local item_info = {}
		local tip = {}
		local index,id,num,bind,item_name,msg
		index = define.MONSTER_KILLBOX_ITEM_COUNT
		for i = 1,item_num do
			index = index + 1
			id = obj:get_scene_params(index)
			index = index + 1
			num = obj:get_scene_params(index)
			index = index + 1
			bind = obj:get_scene_params(index)
			item_name = self:GetItemName(id)
			if item_name ~= -1 and num > 0 then
				table.insert(item_info,{id,num,bind})
				msg = self:ScriptGlobal_Format("#{OBCS_200916_04}",num,item_name)
				table.insert(tip,msg)
			end
		end
		if #item_info == 0 then
			return
		end
		local playerid
		local guid,name,human
		if objId ~= killerId then
			human = scene:get_obj_by_id(killerId)
			if human then
				if human:get_obj_type() == "human" then
					playerid = killerId
					name = human:get_name()
				elseif human:get_obj_type() == "pet" then
					playerid = human:get_owner_obj_id()
					human = scene:get_obj_by_id(playerid)
					if human then
						name = human:get_name()
					else
						playerid = nil
					end
				else
					human = nil
				end
			end
		end
		if human and playerid then
			self:BeginAddItem()
			for _,j in ipairs(item_info) do
				self:AddItem(j[1],j[2],j[3])
			end
			if not self:EndAddItem(playerid) then
				human:notify_tips("Thưởng giết vào túi thất bại.")
				return
			end
			self:AddItemListToHuman(playerid)
			for _,msg in ipairs(tip) do
				human:notify_tips(msg)
			end
		end
	end
end
return jingzhuzengliboss_die