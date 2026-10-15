-- 时装点缀转移
-- 将源时装的所有宝石转移到目标时装
local class = require "class"
local define = require "define"
local packet_def = require "game.packet"
local script_base = require "script_base"
local dress_gem_transfer = class("dress_gem_transfer", script_base)

-- 客户端参数：from_pos, to_pos, bind_check, yuanbao_pay
function dress_gem_transfer:DressGemTransfer(selfId, from_pos, to_pos, bind_check, yuanbao_pay)
    print("dress_gem_transfer:DressGemTransfer =", selfId, from_pos, to_pos, bind_check, yuanbao_pay)

    -- 获取玩家对象
    local obj = self.scene:get_obj_by_id(selfId)
    if not obj then
        return
    end

    local container = obj:get_prop_bag_container()

    -- 获取源/目标时装物品
    local from_item = container:get_item(from_pos)
    local to_item = container:get_item(to_pos)

    if not from_item then
        self:notify_tips(selfId, "Thời trang gốc không tồn tại")
        return
    end
    if not to_item then
        self:notify_tips(selfId, "Thời trang đích không tồn tại")
        return
    end

    -- 校验都是时装类型
    local from_point = from_item:get_base_config().equip_point
    local to_point = to_item:get_base_config().equip_point
    if from_point ~= define.HUMAN_EQUIP.HEQUIP_FASHION then
        self:notify_tips(selfId, "Trang bị gốc không phải thời trang")
        return
    end
    if to_point ~= define.HUMAN_EQUIP.HEQUIP_FASHION then
        self:notify_tips(selfId, "Trang bị đích không phải thời trang")
        return
    end

    -- 获取宝石列表
    local from_gem_list = from_item:get_equip_data():get_gem_list()
    local to_gem_list = to_item:get_equip_data():get_gem_list()

    -- 统计源时装的宝石数量
    local from_gem_count = 0
    for i = 1, 3 do
        if from_gem_list[i] and from_gem_list[i] > 0 then
            from_gem_count = from_gem_count + 1
        end
    end

    if from_gem_count < 1 then
        self:notify_tips(selfId, "Thời trang gốc không có bảo thạch chuyển được")
        return
    end

    -- 检查是否有同类型宝石冲突（相同位置都有宝石）
    for i = 1, 3 do
        if from_gem_list[i] and from_gem_list[i] > 0 then
            if to_gem_list[i] and to_gem_list[i] > 0 then
                self:notify_tips(selfId, "Thời trang đích trùng vị trí bảo thạch, không chuyển được")
                return
            end
        end
    end

    -- 检查目标时装空槽位是否足够
    local to_slot_count = to_item:get_equip_data():get_slot_count()
    local to_gem_count = 0
    for i = 1, 3 do
        if to_gem_list[i] and to_gem_list[i] > 0 then
            to_gem_count = to_gem_count + 1
        end
    end
    local empty_slots = to_slot_count - to_gem_count
    if empty_slots < from_gem_count then
        self:notify_tips(selfId, string.format("Ô trống thời trang đích không đủ, cần %d, hiện %d", from_gem_count, empty_slots))
        return
    end

    -- 执行转移：遍历源时装的gem_list，对每个非0的gem进行转移
    for i = 1, 3 do
        local gem = from_gem_list[i]
        if gem and gem > 0 then
            from_item:get_equip_data():remove_gem(i)
            to_item:get_equip_data():gem_embed(i, gem)
        end
    end

    -- 目标时装设置绑定
    to_item:set_is_bind(true)

    -- 修正宝石计数
    self:refix_equip_gem_count(from_item)
    self:refix_equip_gem_count(to_item)

    -- 刷新客户端：源时装
    local msg1 = packet_def.GCItemInfo.new()
    msg1.bagIndex = from_pos
    msg1.item = from_item:copy_raw_data()
    self.scene:send2client(obj, msg1)

    -- 刷新客户端：目标时装
    local msg2 = packet_def.GCItemInfo.new()
    msg2.bagIndex = to_pos
    msg2.item = to_item:copy_raw_data()
    self.scene:send2client(obj, msg2)

    -- 播放特效
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 49, 0)

    -- 通知客户端完成（GCItemInfo已刷新物品数据）
    self:notify_tips(selfId, "Chuyển phối sức thành công")
end

function dress_gem_transfer:refix_equip_gem_count(equip)
    local gem_count = 0
    local gem_list = equip:get_equip_data():get_gem_list()
    for i = 1, 3 do
        if gem_list[i] and gem_list[i] > 0 then
            gem_count = gem_count + 1
        end
    end
    equip:get_equip_data():set_gem_count(gem_count)
end

return dress_gem_transfer
