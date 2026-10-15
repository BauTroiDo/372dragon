
local class = require "class"
local define = require "define"
local gbk = require "wire_charset"
local script_base = require "script_base"
local item_shenshoubaotu = class("item_shenshoubaotu", script_base)
item_shenshoubaotu.script_id = 893081

item_shenshoubaotu.needsceneid = 41
item_shenshoubaotu.needitemid = 38002496

item_shenshoubaotu.distance = 5

item_shenshoubaotu.g_RandomPosInfo = {
    {["startX"] = 123, ["endX"] = 176, ["startY"] = 91, ["endY"] = 160},
    {["startX"] = 243, ["endX"] = 275, ["startY"] = 90, ["endY"] = 101},
    {["startX"] = 258, ["endX"] = 276, ["startY"] = 137, ["endY"] = 191},
    {["startX"] = 173, ["endX"] = 194, ["startY"] = 219, ["endY"] = 233},
    {["startX"] = 72, ["endX"] = 86, ["startY"] = 231, ["endY"] = 246},
    {["startX"] = 65, ["endX"] = 75, ["startY"] = 106, ["endY"] = 121}
}
item_shenshoubaotu.g_RandomMonsterInfo = {
    {["mosterid"] = 49556, ["bossid"] = 126},
    {["mosterid"] = 49557, ["bossid"] = 129},
    {["mosterid"] = 49558, ["bossid"] = 127},
    {["mosterid"] = 49559, ["bossid"] = 128},
    {["mosterid"] = 49564, ["bossid"] = 130}
}
item_shenshoubaotu.DataId2DropId = {
    [49556] = 38002515,
    [49557] = 38002516,
    [49558] = 38002517,
    [49559] = 38002518,
    [49564] = 38002519,
}
item_shenshoubaotu.hunchen_id = 38002497
item_shenshoubaotu.g_ShenShouScriptID = 893084
function item_shenshoubaotu:IsSkillLikeScript(selfId) return 1 end

function item_shenshoubaotu:CancelImpacts(selfId) return 0 end


function item_shenshoubaotu:CheckUseItem(selfId, BagPos)
	local posx,posz,index = 0,0,0
    local sceneId = self:GetSceneID()
	if sceneId ~= self.needsceneid then
		-- self:NotifyFailTips(selfId, "请到"..self:GetSceneName(self.needsceneid).."使用。")
		self:NotifyFailTips(selfId, "Xin tới gương Huyền Vũ Đảo dùng.")
		return posx,posz,index
	end
	if self:LuaFnGetItemTableIndexByIndex(selfId, BagPos) ~= self.needitemid then
		self:NotifyFailTips(selfId, "Đạo cụ không khớp.")
		return posx,posz,index
	end
    if self:GetLevel(selfId) < 60 then
        self:NotifyFailTips(selfId, "#{ZSPVP_211231_08}")
		return posx,posz,index
	end
	posx = self:GetBagItemParam(selfId, BagPos, 3, "ushort")
	posz = self:GetBagItemParam(selfId, BagPos, 5, "ushort")
	index = self:GetBagItemParam(selfId, BagPos, 7, "uchar")
	if not posx or posx < 1
	or not posz or posz < 1
	or not index or index < 1 then
		local ranidx = math.random(1,#self.g_RandomPosInfo)
		posx = math.random(self.g_RandomPosInfo[ranidx]["startX"],
								  self.g_RandomPosInfo[ranidx]["endX"])
		posz = math.random(self.g_RandomPosInfo[ranidx]["startY"],
									  self.g_RandomPosInfo[ranidx]["endY"])
		index = math.random(1,#self.g_RandomMonsterInfo)							  
		self:SetBagItemParam(selfId, BagPos, 3, posx, "ushort")
		self:SetBagItemParam(selfId, BagPos, 5, posz, "ushort")
		self:SetBagItemParam(selfId, BagPos, 7, index, "ushort")
	end
    local PlayerX = self:GetHumanWorldX(selfId)
    local PlayerZ = self:GetHumanWorldZ(selfId)
    local Distance = math.floor(math.sqrt(
                                    (posx - PlayerX) * (posx - PlayerX) +
                                        (posz - PlayerZ) *
                                        (posz - PlayerZ)))
	if Distance > self.distance then
		self:NotifyFailTips(selfId, "Xin tới vị trí ["..posx..","..posz.."]dùng ở gần.")
		posx,posz,index = 0,0,0
	end
	return posx,posz,index
end

function item_shenshoubaotu:OnConditionCheck(selfId)
    if not self:LuaFnVerifyUsedItem(selfId) then return 0 end
    local BagPos = self:LuaFnGetBagIndexOfUsedItem(selfId)
	local posx,posz,index = self:CheckUseItem(selfId,BagPos)
	if posx == 0 then
		return 0
	end
    return 1
end

function item_shenshoubaotu:OnDeplete(selfId)
	return 1
end

function item_shenshoubaotu:OnActivateOnce(selfId)
    if not self:LuaFnVerifyUsedItem(selfId) then return 0 end
    local BagPos = self:LuaFnGetBagIndexOfUsedItem(selfId)
	local posx,posz,index = self:CheckUseItem(selfId,BagPos)
	if posx == 0 then
		return 0
	end
	self:LuaFnDecItemLayCount(selfId, BagPos, 1)
    local nRandMosterIdx = math.random(1, #(self.g_RandomMonsterInfo))
    local nMonsterID = self.g_RandomMonsterInfo[nRandMosterIdx]["mosterid"]
    local nMonsterBossId = self.g_RandomMonsterInfo[nRandMosterIdx]["bossid"]
    local MonsterId = self:LuaFnCreateMonster(nMonsterID, posx,
                                              posz, 0, -1, self.script_id)
    self:SetCharacterDieTime(MonsterId, 60 * 60000)
    self:SetUnitReputationID(selfId, MonsterId, 28)
    self:LuaFnSetNpcIntParameter(MonsterId, 0, self:LuaFnGetGUID(selfId))
    local PlayerName = self:LuaFnGetName(selfId)
    local strText = string.format(
      "#PHoang thú hồn mất kiểm soát, đột hiện#GHuyền Vũ Đảo#P! Nay hiệp khách #{_INFOUSR%s} khi thăm dò chân tướng dị biến#GHuyền Vũ Đảo#P, vô tình triệu ra#G#{_BOSS%d}#P!#G#{_BOSS%d}#Phiện thân#GHuyền Vũ Đảo·Kính (%d,%d)#P! Thế không thể cản!", 
      PlayerName, nMonsterBossId, nMonsterBossId,posx, posz
    )
    strText = gbk.fromutf8(strText)
    self:BroadMsgByChatPipe(selfId, strText, 4)
    return 1
end

function item_shenshoubaotu:OnActivateEachTick(selfId) return 1 end

function item_shenshoubaotu:OnDie(selfId)
    local DataId = self:GetMonsterDataID(selfId)
    local drop_id = self.DataId2DropId[DataId]
    if drop_id == nil then
        return
    end
    local guid = self:LuaFnGetNpcIntParameter(selfId, 0)
    local occupant_guid = self:LuaFnGetOccupantGUID(selfId)
    local owner_obj_ids = self:LuaFnGetMonsterOwnerObjIds(selfId)
    if guid == occupant_guid or self:LuaFnIsTeamMate(guid, occupant_guid) then
        local user_oid = self:LuaFnGuid2ObjId(guid)
        self:AddMonsterDropItem(selfId, user_oid, drop_id)
        for _, oid in ipairs(owner_obj_ids) do
            if oid ~= user_oid then
                self:AddMonsterDropItem(selfId, oid, self.hunchen_id)
            end
        end
    else
        local n = #owner_obj_ids
        for i, oid in ipairs(owner_obj_ids) do
            if i == n then
                self:AddMonsterDropItem(selfId, oid, drop_id)
            else
                self:AddMonsterDropItem(selfId, oid, self.hunchen_id)
            end
        end
    end
end

function item_shenshoubaotu:LuaFnGetMonsterOwnerObjIds(selfId)
    local monster = self:get_scene():get_obj_by_id(selfId)
    local _, owners = monster:caculate_owner_list()
    local owner_obj_ids = {}
    for _, o in ipairs(owners) do
        table.insert(owner_obj_ids, o:get_obj_id())
    end
    return owner_obj_ids
end

function item_shenshoubaotu:LuaFnIsTeamMate(guid, other_guid)
    local human = self:get_scene():get_obj_by_guid(guid)
    local other = self:get_scene():get_obj_by_guid(other_guid)
    return human:is_teammate(other)
end

function item_shenshoubaotu:NotifyFailTips(selfId, Tip)
    self:BeginEvent(self.script_id)
    self:AddText(Tip)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return item_shenshoubaotu
