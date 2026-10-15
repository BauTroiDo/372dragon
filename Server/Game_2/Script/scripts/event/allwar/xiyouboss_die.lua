local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local xiyouboss_die = class("xiyouboss_die", script_base)
-- local gbk = require "wire_charset"
xiyouboss_die.script_id = 999982

-- 终极Boss最后一击奖励（直接发到背包）
xiyouboss_die.finalKillReward = {
    -- [52704] = { itemid = 38008172, count = 1 },   -- 翠云山终极Boss
    [55099] = { itemid = 38008172, count = 1 },   -- 水帘洞终极Boss
    [55100] = { itemid = 38008172, count = 1 },   -- 永宁城终极Boss
}

function xiyouboss_die:OnDie(objId, killerId)
    local scene = self:get_scene()
    local obj = scene:get_obj_by_id(objId)
    if not obj or obj:get_obj_type() ~= "monster" then
        return
    end
    local dataid = obj:get_scene_params(define.MONSTER_DATAID)
    if obj:get_model() ~= dataid then
        return
    end

    -- 获取击杀者（如果是宠物则取主人）
    local killer_name = "未知"
    local killer_playerid = nil
    if objId ~= killerId then
        local human = scene:get_obj_by_id(killerId)
        if human then
            if human:get_obj_type() == "human" then
                killer_name = human:get_name()
                killer_playerid = killerId
            elseif human:get_obj_type() == "pet" then
                killer_playerid = human:get_owner_obj_id()
                human = scene:get_obj_by_id(killer_playerid)
                if human then
                    killer_name = human:get_name()
                end
            end
        end
    end

    local bossname = obj:get_name()
    local world_pos = obj:get_world_pos()
    local bossposx = math.floor(world_pos.x)
    local bossposz = math.floor(world_pos.y)

    -- 终极Boss：直接给击杀者发奖励 + 播报（通过finalKillReward配置的怪物ID识别）
    if killer_playerid then
        local reward = self.finalKillReward[dataid]
        if reward then
            self:BeginAddItem()
            self:AddItem(reward.itemid, reward.count, true)
            local ret = self:EndAddItem(killer_playerid)
            if ret then
                self:AddItemListToHuman(killer_playerid)
                local bossShowName = self:GetItemName(reward.itemid)
                local msg1 = string.format("Ngươi giết Boss tối thượng thành công, nhận %s×%d!", bossShowName, reward.count)
                local msg2 = string.format("@*;SrvMsg;SCA:【Boss tối thượng】#cff0000%s#Pgiết thành công#G%s#P, nhận#G%s×%d#P!",
                    killer_name, bossname, bossShowName, reward.count)
                self:notify_tips(killer_playerid, msg1)
                self:AddGlobalCountNews(msg2)
            end
        end
    end
end
return xiyouboss_die