local class = require "class"
local define = require "define"
local utils = require "utils"
local script_base = require "script_base"
local chiji_pvp = class("chiji_pvp", script_base)
chiji_pvp.script_id = 3000009
chiji_pvp.g_IDX_CurCamp			= 8
chiji_pvp.g_IDX_InitBoxs        = 9
chiji_pvp.g_IDX_IsGameEnd       = 10
chiji_pvp.g_BackPos = {
    sceneId = 1,
    x = 181,
    z = 146
}
chiji_pvp.poss = {
    [229] = {
        {x = 45, y = 41}, {x = 39, y = 46}, {x = 59, y = 47}, {x = 98, y = 73}, {x = 132, y = 72}, {x = 132, y = 53}, {x = 142, y = 21}, {x = 158, y = 28}, {x = 187, y = 47}, {x = 202, y = 61},
        {x = 48, y = 96}, {x = 69, y = 102}, {x = 98, y = 91}, {x = 154, y = 96}, {x = 123, y = 110}, {x = 162, y = 99}, {x = 192, y = 112}, {x = 199, y = 130}, {x = 217, y = 131}, {x = 232, y = 144},
        {x = 37, y = 219}, {x = 34, y = 190}, {x = 107, y = 219}, {x = 139, y = 160}, {x = 171, y = 191}, {x = 196, y = 220}, {x = 215, y = 154}, {x = 223, y = 209}, {x = 129, y = 154}, {x = 235, y = 223},
    }
}
chiji_pvp.items = {
    10200018, 10202018, 10205018, 10206022, 10210036, 10213036, 10212036, 10211036, 10214016, 10215016, 10221018, 10220018, 10222032, 10223019
}
chiji_pvp.award_list = {
    [1] = {
        {
            itemid= 30101144,
            num= 1
        }
    }
}
function chiji_pvp:OnCopySceneTimer(nowTime)
    if self:LuaFnGetCopySceneData_Param(self.g_IDX_IsGameEnd) == 1 then
        self:LeaveGame()
    end
end

function chiji_pvp:OnPlayerEnter(selfId)
    local cur_camp = self:LuaFnGetCopySceneData_Param(self.g_IDX_CurCamp)
    local set_camp = cur_camp + 10
    print("chiji_pvp:OnPlayerEnter")
    self:SetUnitCampID(selfId, set_camp)
    cur_camp = cur_camp + 1
    self:LuaFnSetCopySceneData_Param(self.g_IDX_CurCamp, cur_camp)
    self:BeginAddItem()
	self:AddItem(10402001,1)
	self:EndAddItem(selfId)
	self:AddItemListToHuman(selfId)
    self:LuaFnCancelImpactInSpecificImpact(selfId, 66)
    self:SetPlayerDefaultReliveInfo(selfId, 0.1, nil, 0, self.g_BackPos.sceneId, self.g_BackPos.x, self.g_BackPos.z )
    if self:LuaFnGetCopySceneData_Param(self.g_IDX_InitBoxs) == 0 then
        self:LuaFnSetCopySceneData_Param(self.g_IDX_InitBoxs, 1)
        self:CreateTreasureBoxs()
    end
end

function chiji_pvp:CreateTreasureBoxs()
    local array = self.poss[229]
    array = utils.random_array(array)
    for _, pos in ipairs(array) do
        local growPointType = 620
        for i = 1, 5 do
            local itemId = self.items[math.random(1, #self.items)]
            local x = pos.x + math.random(1, 10) - 5
            local y = pos.y + math.random(1, 10) - 5
            local targetId = self:ItemBoxEnterScene(x, y, growPointType,define.QUALITY_MUST_BE_CHANGE,1,itemId, 115)
            self:AddItemToBox(targetId, define.QUALITY_MUST_BE_CHANGE, 1, 30505059)
            self:AddItemToBox(targetId, define.QUALITY_MUST_BE_CHANGE, 1, 30101144)
            self:AddItemToBox(targetId, define.QUALITY_MUST_BE_CHANGE, 1, 30101174)
        end
    end
end

function chiji_pvp:SetRankAwards(selfId, rank)
    local awards = self.award_list[rank]
    local name = self:GetName(selfId)
    if awards then
        self:SetCanGetAwards(selfId, "Đại chiến tuyết nguyên", awards)
        self:LuaFnSendSystemMail(name, string.format([[您在雪原大作战中，获得了%d名的好成绩，快去大理npc龚彩云处领取奖励]], rank))
    else
        self:LuaFnSendSystemMail(name, string.format([[很遗憾您在雪原大作战的名次为%d名，没有获得奖励]], rank))
    end
end

function chiji_pvp:OnHumanDie(selfId, killerId)
    local rank = self:GetAliveHumanCount() + 1
    self:SetRankAwards(selfId, rank)
    local human_name = self:LuaFnGetName(selfId)
    local killer_name = self:LuaFnGetName(killerId)
    local human_count = self:GetAliveHumanCount()
    local msg = string.format("Người chơi %s bị %s đánh bại, hiện còn %d người", human_name, killer_name, human_count)
    self:SceneBroadcastMsg(msg)
    if human_count == 1 then
        self:LuaFnSetCopySceneData_Param(self.g_IDX_IsGameEnd, 1)
    end
end

function chiji_pvp:LeaveGame(expect_id)
    local human_count = self:LuaFnGetCopyScene_HumanCount()
    for i = 1, human_count do
        local playerId = self:LuaFnGetCopyScene_HumanObjId(i)
        if playerId ~= expect_id then
            if self:LuaFnIsCharacterLiving(playerId) then
                self:NewWorld(playerId, self.g_BackPos.sceneId, nil, self.g_BackPos.x, self.g_BackPos.z)
            end
        end
    end
end

function chiji_pvp:OnPlayerLeave(selfId)
    self:ChangeRestoreSceneAndPos(selfId, self.g_BackPos.sceneId, self.g_BackPos.x, self.g_BackPos.z)
    if self:LuaFnIsCharacterLiving(selfId) then
        local rank = self:GetAliveHumanCount()
        self:SetRankAwards(selfId, rank)
    end
    local human_count = self:GetAliveHumanCount() - 1
    local human_name = self:LuaFnGetName(selfId)
    local msg = string.format("Người chơi %s rời trận, hiện còn %d người", human_name, human_count)
    self:SceneBroadcastMsg(msg)
    if human_count == 1 then
        self:LuaFnSetCopySceneData_Param(self.g_IDX_IsGameEnd, 1)
    end
end

function chiji_pvp:GetAliveHumanCount()
    local human_count = self:LuaFnGetCopyScene_HumanCount()
    local count = 0
    for i = 1, human_count do
        local playerId = self:LuaFnGetCopyScene_HumanObjId(i)
        if self:LuaFnIsCharacterLiving(playerId) then
            count = count + 1
        end
    end
    return count
end

return chiji_pvp
