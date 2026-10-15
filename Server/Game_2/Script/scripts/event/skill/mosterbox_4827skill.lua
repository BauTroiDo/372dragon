local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local mosterbox_4827skill = class("mosterbox_4827skill", script_base)
mosterbox_4827skill.script_id = 998739
mosterbox_4827skill.skill_id = 4827		--拾取中
mosterbox_4827skill.scriptids = {
	-- [id] = true,

}
function mosterbox_4827skill:skill_effect_on_uint_once(selfId,targetId,skill_id,script_id)
	if skill_id ~= self.skill_id then
		self:LuaFnSendOResultToPlayer(selfId,define.OPERATE_RESULT.OR_INVALID_SKILL)
		return
	end
	script_id = script_id or -1
	if script_id ~= -1 then
		if self.scriptids[script_id] then
			self:CallScriptFunction(script_id,"skill_effect_on_uint_once",selfId,targetId,skill_id)
		end
		return
	end
	
	if selfId >= 0 then
		self:notify_tips(selfId,"#{ResultText_16}。")
		return
	end
	selfId = math.abs(selfId)
	if not self:CheckSkillOnMonsterBox(selfId,targetId,skill_id) then
		return
	end
    local obj = self:get_scene():get_obj_by_id(targetId)
	if obj then
		local have_guid = obj:get_scene_params(define.MONSTER_KILLBOX_GUID)
		if have_guid > 0 then
			local protect_time = obj:get_scene_params(define.MONSTER_KILLBOX_PROTECT_TIME)
			if protect_time >= os.time() then
				if self:LuaFnGetGUID(selfId) ~= have_guid then
					self:notify_tips(selfId,"#{ZNDB_230215_96}")
					return
				end
			end
		end
		local item_count = obj:get_scene_params(define.MONSTER_DROPBOX_ITEM_COUNT)
		if item_count < 1 then
			self:LuaFnGmKillObj(targetId,targetId)
			self:notify_tips(selfId,"Đây là rương trống.")
			return
		end
		local msgs = {}
		self:BeginAddItem()
		local index = define.MONSTER_DROPBOX_ITEM_COUNT + 1
		local id,num,bind
		local item_name
		for i = 1,item_count do
			id = obj:get_scene_params(index)
			index = index + 1
			num = obj:get_scene_params(index)
			index = index + 1
			bind = obj:get_scene_params(index)
			index = index + 1
			item_name = self:GetItemName(id)
			if item_name ~= -1 and num > 0 then
				if bind == 0 then
					bind = false
				end
				self:AddItem(id,num,bind)
				table.insert(msgs,{num,item_name})
			end
		end
		if #msgs > 0 then
			if not self:EndAddItem(selfId) then
				return
			end
			self:ShowObjBuffEffect(selfId,targetId,-1,18)
			if self:LuaFnGmKillObj(targetId,selfId) then
				self:AddItemListToHuman(selfId)
				obj = self:get_scene():get_obj_by_id(selfId)
				if obj then
					for _,j in ipairs(msgs) do
						local msg = self:ScriptGlobal_Format("#{OBCS_200916_04}",j[1],j[2])
						obj:notify_tips(msg)
					end
				end
			end
		else
			self:LuaFnGmKillObj(targetId,targetId)
			self:notify_tips(selfId,"Đây là rương trống.")
		end
	end
end


return mosterbox_4827skill
