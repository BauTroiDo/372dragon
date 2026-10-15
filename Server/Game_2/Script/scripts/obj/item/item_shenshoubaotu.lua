local class = require "class"
local define = require "define"
local gbk = require "wire_charset"
local script_base = require "script_base"
local item_shenshoubaotu = class("item_shenshoubaotu", script_base)
item_shenshoubaotu.script_id = 893081
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

function item_shenshoubaotu:GetItemParam(selfId, BagPos)
    local targetsceneId = self:GetBagItemParam(selfId, BagPos, 1, "uchar")
    local targetX = self:GetBagItemParam(selfId, BagPos, 3, "ushort")
    local targetZ = self:GetBagItemParam(selfId, BagPos, 5, "ushort")
    local r = self:GetBagItemParam(selfId, BagPos, 7, "uchar")
    return targetsceneId, targetX, targetZ, r
end

function item_shenshoubaotu:GenerateItemParam(selfId, BagPos)
    self:SetBagItemParam(selfId, BagPos, 0, 1, "uchar")
    self:SetBagItemParam(selfId, BagPos, 1, 41, "uchar")
    local nRandIdx = math.random(1, #(self.g_RandomPosInfo))
    local nRandPosX = math.random(self.g_RandomPosInfo[nRandIdx]["startX"],
                                  self.g_RandomPosInfo[nRandIdx]["endX"])
    local nRandPosZ = math.random(self.g_RandomPosInfo[nRandIdx]["startY"],
                                  self.g_RandomPosInfo[nRandIdx]["endY"])
    self:SetBagItemParam(selfId, BagPos, 3, nRandPosX, "ushort")
    self:SetBagItemParam(selfId, BagPos, 5, nRandPosZ, "ushort")
    self:SetBagItemParam(selfId, BagPos, 7, 5, "ushort")
    self:LuaFnRefreshItemInfo(selfId, BagPos)
    return nRandPosX, nRandPosZ
end

function item_shenshoubaotu:OnConditionCheck(selfId)
    if not self:LuaFnVerifyUsedItem(selfId) then return 0 end
    if self:GetLevel(selfId) < 60 then
        self:NotifyFailTips(selfId, "#{ZSPVP_211231_08}")
        return 0
    end
    local sceneId = self:GetSceneID()
    local BagPos = self:LuaFnGetBagIndexOfUsedItem(selfId)
    local targetSceneId, targetX, targetZ, r = self:GetItemParam(selfId, BagPos)
    if targetSceneId == nil or targetSceneId <= 0 or targetX == nil or targetX <=
        0 or targetZ == nil or targetZ <= 0 or r == nil or r <= 0 then
        targetX, targetZ = self:GenerateItemParam(selfId, BagPos)
        targetSceneId = self:GetItemParam(selfId, BagPos)
    end
    local PlayerX = self:GetHumanWorldX(selfId)
    local PlayerZ = self:GetHumanWorldZ(selfId)
    local Distance = math.floor(math.sqrt(
                                    (targetX - PlayerX) * (targetX - PlayerX) +
                                        (targetZ - PlayerZ) *
                                        (targetZ - PlayerZ)))
    if targetSceneId ~= sceneId or Distance > r then
        if targetSceneId ~= sceneId then
            self:NotifyFailTips(selfId, "#{ZSPVP_211231_11}")
        end
        if Distance > r then
            self:NotifyFailTips(selfId, "#{ZSPVP_211231_12}")
        end
        self:BeginEvent(self.script_id)
        self:AddText(string.format(
                         "    Trên cuộn có khắc bằng màu mực đen một hàng chữ lớn: #GHuyền Vũ Đảo·Kính#W#{_INFOAIM%d,%d,%d,-1}#r    Nếu nhìn kỹ, chẳng khó gì nhận ra bên dưới hàng chữ lớn còn có một hàng chữ nhỏ màu nhạt hơn: Sau khi Đến nơi đây, Sử dụng #YHồn Linh Chi Quyển#W, có thể nhận được chỉ dẫn. #r    #GMẹo：Chỉ một người mới có thể Nhận được phần thưởng.",
                         targetX, targetZ, 579))
        self:EndEvent()
        self:DispatchEventList(selfId, -1)
        return 0
    end
    return 1
end

function item_shenshoubaotu:OnDeplete(selfId)
    if self:LuaFnDepletingUsedItem(selfId) then return 1 end
    return 0
end

function item_shenshoubaotu:OnActivateOnce(selfId)
    local PlayerX = math.floor(self:GetHumanWorldX(selfId))
    local PlayerZ = math.floor(self:GetHumanWorldZ(selfId))
    local nRandMosterIdx = math.random(1, #(self.g_RandomMonsterInfo))
    local nMonsterID = self.g_RandomMonsterInfo[nRandMosterIdx]["mosterid"]
    local nMonsterBossId = self.g_RandomMonsterInfo[nRandMosterIdx]["bossid"]
    local MonsterId = self:LuaFnCreateMonster(nMonsterID, PlayerX + 1,
                                              PlayerZ + 1, 0, -1, self.script_id)
    self:SetCharacterDieTime(MonsterId, 60 * 60000)
    self:SetUnitReputationID(selfId, MonsterId, 28)
    self:LuaFnSetNpcIntParameter(MonsterId, 0, self:LuaFnGetGUID(selfId))
    local PlayerName = self:LuaFnGetName(selfId)
    local strText = string.format(
      "#PHoang thú hồn mất kiểm soát, đột hiện#GHuyền Vũ Đảo#P! Nay hiệp khách #{_INFOUSR%s} khi thăm dò chân tướng dị biến#GHuyền Vũ Đảo#P, vô tình triệu ra#G#{_BOSS%d}#P!#G#{_BOSS%d}#Phiện thân#GHuyền Vũ Đảo·Kính (%d,%d)#P! Thế không thể cản!", 
      PlayerName, nMonsterBossId, nMonsterBossId,PlayerX, PlayerZ
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
