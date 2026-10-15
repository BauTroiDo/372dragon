-- 统一场景区域传送系统
-- 通过场景ID和玩家位置（posx, posy）来判断传送目标
local class = require "class"
local script_base = require "script_base"
local chuan_song = class("chuan_song", script_base)
local skynet = require "skynet"

-- 传送配置表
-- 使用圆形区域判断：以 x, z 为中心，radious 为半径（默认半径为5）
-- 格式: [场景ID] = {
--     {x = 中心X, z = 中心Z, radious = 半径(可选，默认5),
--      target_scene = 目标场景ID, target_x = 目标X, target_y = 目标Y},
--     ...
-- }
local TransferConfig = {
    -- map-convert 2026-08-26: Lac Duong (0) <-> Summoner Rift (2219)
    [0] = {
        -- quang truong phia bac diem hoi sinh Lac Duong -> san choi Summoner Rift
        {x = 160, z = 268, radious = 7, target_scene = 2219, target_x = 124, target_y = 166},
    },
    [2219] = {
        -- san choi Summoner Rift -> diem hoi sinh Lac Duong
        {x = 124, z = 178, radious = 7, target_scene = 0, target_x = 160, target_y = 278},
    },

	-- 锁龙古塔一层 (1350)
    [1350] = {
        -- 一层->二层 1号点
        {x = 48, z = 49, radious = 5, target_scene = 1351, target_x = 31, target_y = 154},
        -- 一层->二层 2号点
        {x = 208, z = 55, radious = 5, target_scene = 1351, target_x = 161, target_y = 154},
    },
    
    -- 锁龙古塔二层 (1351)
    [1351] = {
        -- 二层->一层 1号点
        {x = 30, z = 162, radious = 5, target_scene = 1350, target_x = 52, target_y = 54},
        -- 二层->一层 2号点
        {x = 162, z = 160, radious = 5, target_scene = 1350, target_x = 206, target_y = 57},
        -- 二层->三层 1号点
        {x = 28, z = 27, radious = 5, target_scene = 1352, target_x = 64, target_y = 130},
        -- 二层->三层 2号点
        {x = 172, z = 33, radious = 5, target_scene = 1352, target_x = 129, target_y = 127},
    },
    
    -- 锁龙古塔三层 (1352)
    [1352] = {
        -- 三层->二层 1号点
        {x = 134, z = 133, radious = 5, target_scene = 1351, target_x = 169, target_y = 38},
        -- 三层->二层 2号点
        {x = 60, z = 134, radious = 5, target_scene = 1351, target_x = 33, target_y = 31},
        -- 三层->四层 1号点
        {x = 148, z = 77, radious = 5, target_scene = 1353, target_x = 127, target_y = 128},
        -- 三层->四层 2号点
        {x = 37, z = 66, radious = 5, target_scene = 1353, target_x = 66, target_y = 125},
    },
    
    -- 锁龙古塔四层 (1353)
    [1353] = {
        -- 四层->三层 1号点
        {x = 60, z = 125, radious = 5, target_scene = 1352, target_x = 41, target_y = 69},
        -- 四层->三层 2号点
        {x = 135, z = 128, radious = 5, target_scene = 1352, target_x = 142, target_y = 81},
    },
}

-- 计算两点之间的距离平方
local function calculate_dist_sq(x1, y1, x2, y2)
    local dx = x1 - x2
    local dy = y1 - y2
    return dx * dx + dy * dy
end

-- 检查玩家位置是否在指定区域内
-- 使用圆形区域判断：以 x, z 为中心，radious 为半径（默认5）
local function is_in_area(posx, posy, config)
    if not config.x or not config.z then
        return false
    end
    
    -- 使用配置的半径，如果没有指定则默认使用5
    local radious = config.radious or 5
    local dist_sq = calculate_dist_sq(posx, posy, config.x, config.z)
    local radious_sq = radious * radious
    return dist_sq < radious_sq
end

-- 查找传送配置
local function find_transfer_config(scene_id, posx, posy)
    local scene_config = TransferConfig[scene_id]
    if not scene_config then
        return nil
    end
    
    -- 遍历该场景的所有传送点配置
    for _, config in ipairs(scene_config) do
        if is_in_area(posx, posy, config) then
            return config
        end
    end
    
    return nil
end

function chuan_song:on_enter_area(scene, obj)
    local scene_id = scene:get_id()
    local obj_id = obj:get_obj_id()
    
    -- 获取玩家当前位置
    local posx, posy = self:GetWorldPos(obj_id)
    if not posx or not posy then
        -- skynet.logw("eSceneAreaTransfer:on_enter_area: failed to get player position, obj_id =", obj_id)
        return
    end
    
    -- 查找传送配置
    local transfer_config = find_transfer_config(scene_id, posx, posy)
    if not transfer_config then
        -- skynet.logw("eSceneAreaTransfer:on_enter_area: no transfer config found, scene_id =", scene_id, "posx =", posx, "posy =", posy)
        return
    end
    
    -- 执行传送
    -- skynet.logw("eSceneAreaTransfer:on_enter_area: transferring player", obj_id, 
    --             "from scene", scene_id, "(", posx, ",", posy, ")",
    --             "to scene", transfer_config.target_scene, "(", transfer_config.target_x, ",", transfer_config.target_y, ")")
    
    self:CallScriptFunction((400900), "TransferFunc", obj_id, 
                           transfer_config.target_scene, 
                           transfer_config.target_x, 
                           transfer_config.target_y)
end

return chuan_song
