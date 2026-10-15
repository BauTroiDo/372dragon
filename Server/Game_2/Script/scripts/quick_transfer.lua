local gbk = require "wire_charset"
local define = require "define"
local class = require "class"
local script_base = require "script_base"
local skynet = require "skynet"
local configenginer = require "configenginer":getinstance()
local quick_transfer = class("quick_transfer", script_base)

function quick_transfer:ClientQueryTrans(selfId, TransID)
    print("ClientQueryTrans selfId, TransID =", selfId, TransID)

    local tran_sport_define = configenginer:get_config("tran_sport_define")
    local Trans = tran_sport_define and tran_sport_define[TransID]

    -- 配置不存在，非法 TransID
    if not Trans then
        return
    end

    local cur_scene_id = self:get_scene_id()

    -- 校验：必须在配置中指定的源场景内
    if Trans.source_scene_id ~= cur_scene_id then
        return
    end

    -- 校验：玩家当前坐标与NPC坐标的距离必须在合理范围内（6格以内）
    local cur_x, cur_z = self:GetWorldPos(selfId)
    local npc_x = Trans.pos_x
    local npc_z = Trans.pos_z
    if cur_x == nil or cur_z == nil or npc_x == nil or npc_z == nil then
        return
    end
    local dx = cur_x - npc_x
    local dz = cur_z - npc_z
    local dist = math.floor(math.sqrt(dx * dx + dz * dz))
    if dist > 6 then
        return
    end

    -- 校验：玩家等级必须满足需求等级
    local need_level = Trans.need_level or 0
    if need_level > 0 and self:GetLevel(selfId) < need_level then
        return
    end

    -- 校验：目标场景必须有效且不是当前场景
    local tar_scene = Trans.tar_scene
    local tar_x    = Trans.tar_pos_x
    local tar_z    = Trans.tar_pos_z
    if not tar_scene or not tar_x or not tar_z then
        return
    end
    if tar_scene == cur_scene_id then
        return
    end
    
    self:CallScriptFunction((400900), "TransferFunc", selfId, tar_scene, tar_x, tar_z)
end

return quick_transfer
