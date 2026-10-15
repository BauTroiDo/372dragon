local class = require "class"
local define = require "define"
local script_base = require "script_base"
local item_999978 = class("item_999978", script_base)
item_999978.script_id = 999978
--一次创建影蜃个数  （包含金影蜃）
item_999978.createbosscount = 3
--金影蜃 开出概率  1%
item_999978.jinyingshenrate = 1
--影蜃id
item_999978.yingshenId = 51939
--影蜃血量 = 0 时以怪物表血量为准   > 0 时则修正至该血量
item_999978.yingshenHp = 0
--金影蜃id
item_999978.jinyingshenId = 51941
--金影蜃血量 = 0 时以怪物表血量为准   > 0 时则修正至该血量
item_999978.jinyingshenHp = 0
--位置池
item_999978.create_pos = {
	{95,78},
	{132,36},
	{196,40},
	{149,109},
	{55,172},
	{124,190},
	{151,122},
	{209,123},
	{179,200},
	{120,183},
}
--开启场景
-- item_999978.need_sceneid = {1299,1300}
item_999978.need_sceneid = {1300}
--等级需求
item_999978.need_level = 100


-- item_999978.boss_scriptid = 999977
function item_999978:OnDefaultEvent(selfId, bagIndex)
end

function item_999978:IsSkillLikeScript(selfId)
    return 1
end

function item_999978:CancelImpacts(selfId)
    return 0
end

function item_999978:OnConditionCheck(selfId)
    if (not self:LuaFnVerifyUsedItem(selfId)) then
        return 0
    end
	local useid = self:LuaFnGetItemIndexOfUsedItem(selfId )
	if useid ~= 38008177 and useid ~= 38008178 then
		return 0
	end
	local usepos = self:LuaFnGetBagIndexOfUsedItem(selfId)
	if self:LuaFnGetItemTableIndexByIndex(selfId,usepos) ~= useid then
		return 0
	elseif self:GetLevel(selfId) < self.need_level then
		local msg = self:ScriptGlobal_Format("#{ZXBB_250224_02}",self.need_level)
		self:notify_tips(selfId, msg)
		return
	end
	-- local msg = {"开启此道具请到:"}
	local sceneId = self:GetSceneID()
	for i,j in ipairs(self.need_sceneid) do
		if j == sceneId then
			return 1
		end
		-- table.insert(msg,self:GetSceneName(j))
		-- table.insert(msg,"、")
	end
	-- local text = table.concat(msg)
	self:notify_tips(selfId, "Xin tới Ô Y Hạng mở.")
	return 0
end

function item_999978:OnDeplete(selfId)
    -- if (self:LuaFnDepletingUsedItem(selfId)) then
        -- return 1
    -- end
    return 1
end

function item_999978:OnActivateOnce(selfId)
    local human = self.scene:get_obj_by_id(selfId)
	if not human then
		return 1
	end
	local useid = self:LuaFnGetItemIndexOfUsedItem(selfId )
	if useid ~= 38008177 and useid ~= 38008178 then
		return 1
	end
	local usepos = self:LuaFnGetBagIndexOfUsedItem(selfId)
	if self:LuaFnGetItemTableIndexByIndex(selfId,usepos) ~= useid then
		return 1
	elseif self:GetLevel(selfId) < self.need_level then
		local msg = self:ScriptGlobal_Format("#{ZXBB_250224_02}",self.need_level)
		self:notify_tips(selfId, msg)
		return
	end
	-- local havemenpai = self:GetMenPai(selfId)
	-- if not havemenpai or havemenpai < 0 or havemenpai > 11 or havemenpai == 9 then
		-- self:notify_tips(selfId, "加入门派后方可打开该道具。")
		-- return 1
	-- end
	-- local msg = {"开启此道具请到:"}
	local sceneId = self:GetSceneID()
	local ret = 0
	for i,j in ipairs(self.need_sceneid) do
		if j == sceneId then
			ret = 1
		-- else
			-- table.insert(msg,self:GetSceneName(j))
			-- table.insert(msg,"、")
		end
	end
	if ret == 1 then
		self:LuaFnDecItemLayCount(selfId, usepos, 1)
		local createbosscount = self.createbosscount <= #self.create_pos and self.createbosscount or #self.create_pos
		local create_pos = table.clone(self.create_pos)
		local jinyingshenId = 0
		if math.random(100) <= self.jinyingshenrate and math.random(100) > 100 - self.jinyingshenrate then
			jinyingshenId = self.jinyingshenId
		end
		local iscreate = false
		local name = human:get_name()
		if jinyingshenId > 0 and createbosscount > 0 then
			createbosscount = createbosscount - 1
			local select_pos = table.remove(create_pos,math.random(1,#create_pos))
			local objId = self:LuaFnCreateMonster(jinyingshenId,select_pos[1],select_pos[2],4,0,-1)
			if objId and objId ~= -1 then
				obj = self.scene:get_obj_by_id(objId)
				if obj then
					if self.jinyingshenHp > 0 then
						self:LuaFnSetLifeTimeAttrRefix_MaxHP(objId,self.jinyingshenHp)
						self:RestoreHp(objId)
					end
					self:SetCharacterTitle(objId,name.."Thi triển")
					self:SetUnitReputationID(objId,objId,0)
				end
				iscreate = true
			end
		end
		for i = 1,createbosscount do
			local select_pos = table.remove(create_pos,math.random(1,#create_pos))
			local objId = self:LuaFnCreateMonster(self.yingshenId,select_pos[1],select_pos[2],4,0,-1)
			if objId and objId ~= -1 then
				obj = self.scene:get_obj_by_id(objId)
				if obj then
					if self.yingshenHp > 0 then
						self:LuaFnSetLifeTimeAttrRefix_MaxHP(objId,self.yingshenHp)
						self:RestoreHp(objId)
					end
					self:SetCharacterTitle(objId,name.."Thi triển")
					self:SetUnitReputationID(objId,objId,0)
				end
			end
		end
		-- local strText = self:ContactArgs("@*;SrvMsg;SCA:#{CBTBOSS_Text1","乌衣巷")
		-- self:AddGlobalCountNews(strText .. "}")
		self:AddGlobalCountNews("@*;SrvMsg;SCA:#{CBTBOSS_Text1}Ô Y Hạng")
	else
		-- local text = table.concat(msg)
		-- self:notify_tips(selfId, text)
		self:notify_tips(selfId, "Xin tới Ô Y Hạng mở.")
	end
	return 1
end

function item_999978:OnActivateEachTick(selfId)
    return 1
end

return item_999978
