-- 时装点缀镶嵌
-- 适配新版UI：客户端丄1�7次发送时裄1�7+朄1�7处1�73颗点缄1�7石，服务端自动查扣点缄1�7笄1�7
local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local packet_def = require "game.packet"
local human_item_logic = require "human_item_logic"
local script_base = require "script_base"
local skynet = require "skynet"
local dress_gem_embed = class("dress_gem_embed", script_base)
local MAT_ITEM_INDEX = 30503135

-- 客户端参数：equip_index, gem1, gem2, gem3, isTip, reserved
function dress_gem_embed:OnDress_Enchase(selfId, equip_index, gem1_index, gem2_index, gem3_index, isTip, reserved)
    skynet.logi("[DBG_DRESS_GEM] OnDress_Enchase enter: selfId=", selfId, " equip_index=", equip_index, " gem1=", gem1_index, " gem2=", gem2_index, " gem3=", gem3_index)

    -- 校验时装
    local equip = self:GetBagItem(selfId, equip_index)
    if equip == nil or equip:get_serial_class() ~= define.ITEM_CLASS.ICLASS_EQUIP then
        self:notify_tips(selfId, "#{SZPR_XML_39}")
        return
    end
    local e_pointx = equip:get_base_config().equip_point
    if e_pointx ~= define.HUMAN_EQUIP.HEQUIP_FASHION then
        self:notify_tips(selfId, "该装备并非时裄1�7")
        return
    end

    -- 收集有效的新点缀石（客户端只发新放入的，-1表示该槽位无新石＄1�7
    local gem_indices = {}
    for _, idx in ipairs({gem1_index, gem2_index, gem3_index}) do
        if idx and idx >= 0 then
            table.insert(gem_indices, idx)
        end
    end
    if #gem_indices < 1 then
        self:notify_tips(selfId, "请放入至射1�71个点缄1�7矄1�7")
        return
    end

    -- 预校验：扄1�7有点缄1�7石必须合泄1�7
    for _, gem_index in ipairs(gem_indices) do
        local gem = self:GetBagItem(selfId, gem_index)
        if gem == nil or gem:get_serial_class() ~= define.ITEM_CLASS.ICLASS_GEM then
            self:notify_tips(selfId, "#{SZPR_XML_40}")
            return
        end
        local gemid = gem:get_index()
        local gemval1 = gemid % 100000
        local gemtype = math.floor(gemval1 / 1000)
        if gemtype < 31 or gemtype > 33 then
            self:notify_tips(selfId, "请放入点缄1�7矄1�7")
            return
        end
    end

    -- 预校验：空槽位是否够甄1�7
    local empty_slots = 0
    local gem_list = equip:get_equip_data():get_gem_list()
    local slot_count = equip:get_equip_data():get_slot_count()
    for i = 1, 3 do
        if i <= slot_count and gem_list[i] == 0 then
            empty_slots = empty_slots + 1
        end
    end
    if empty_slots < #gem_indices then
        self:notify_tips(selfId, "Không đủ ô khảm trống")
        return
    end

    -- 预校验：点缀符数量是否足处1�7
    local matCount = self:LuaFnGetAvailableItemCount(selfId, MAT_ITEM_INDEX)
    if matCount < #gem_indices then
        self:notify_tips(selfId, string.format("背包中点缄1�7符不足，霄1�7覄1�7%d个，当前%d个�1�7�1�7", #gem_indices, matCount))
        return
    end

    local obj = self.scene:get_obj_by_id(selfId)
    local logparam = {}
    local success_count = 0
    local last_gem_transfer = ""

    -- 逐颗镶嵌
    for _, gem_index in ipairs(gem_indices) do
        local gem = self:GetBagItem(selfId, gem_index)
        if not gem then break end
        local gemid = gem:get_index()

        local location = self:get_gem_location(equip)
        if location == define.INVAILD_ID then
            self:notify_tips(selfId, "Không còn ô khảm trống")
            break
        end

        -- 记录宝石信息（用于广播）
        last_gem_transfer = self:GetBagItemTransfer(selfId, gem_index)

        -- 扣除点缀矄1�7
        local del = human_item_logic:dec_item_lay_count(logparam, obj, gem_index, 1)
        if not del then
            self:notify_tips(selfId, "点缀石扣除失贄1�7")
            break
        end

        -- 扣除1个点缄1�7笄1�7
        local matDel = self:LuaFnDelAvailableItem(selfId, MAT_ITEM_INDEX, 1)
        if not matDel then
            self:notify_tips(selfId, "点缀符扣除失贄1�7")
            break
        end

        -- 镶嵌
        equip:get_equip_data():gem_embed(location, gemid)
        success_count = success_count + 1
    end

    if success_count > 0 then
        -- 刷新宝石计数
        self:refix_equip_gem_count(equip)

        -- 刷新客户端装备信恄1�7
        local msg = packet_def.GCItemInfo.new()
        msg.bagIndex = equip_index
        msg.item = equip:copy_raw_data()
        self.scene:send2client(selfId, msg)

        -- 播放特效
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 49, 0)

        -- 广播消息
        local name = self:GetName(selfId)
        local szTransferEquip = self:GetBagItemTransfer(selfId, equip_index)
        local fmt = gbk.fromutf8(
                        "#W#{_INFOUSR%s}#H各1�7#W#{_INFOMSG%s}#H镶嵌了一预1�7#W#{_INFOMSG%s}#H，大幅的提升了装备的能力〄1�7")
        local message = string.format(fmt, gbk.fromutf8(name), szTransferEquip,
                                      last_gem_transfer)
        self:BroadMsgByChatPipe(selfId, message, 4)

        -- 通知客户端刷新UI（type=2: 刷新点缀界面＄1�7
        self:BeginUICommand()
        self:UICommand_AddInt(0)
        self:UICommand_AddInt(2)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 20091029)
    end
end

-- 购买点缀符（客户端BuyDressFu按钮调用＄1�7
function dress_gem_embed:BuyDressFu(selfId, buyCount)
    print("dress_gem_embed:BuyDressFu =", selfId, buyCount)
    if not buyCount or buyCount < 1 or buyCount > 3 then
        return
    end
    -- 如需实现购买逻辑可在此扩展，目前点缀符�1�7�过背包自动扣除
end

function dress_gem_embed:get_gem_location(equip)
    if not equip then return define.INVAILD_ID end
    local equip_data = equip:get_equip_data()
    if not equip_data then return define.INVAILD_ID end
    local gem_list = equip_data:get_gem_list()
    if not gem_list then return define.INVAILD_ID end
    for i = 1, 3 do
        if gem_list[i] == 0 then
            return i
        end
    end
    return define.INVAILD_ID
end

function dress_gem_embed:refix_equip_gem_count(equip)
    local gem_count = 0
    local gem_list = equip:get_equip_data():get_gem_list()
    local slot_count = equip:get_equip_data():get_slot_count()
    for i = 1, slot_count do  -- [DBG_GEM] fix: count all slots not just 3
        if gem_list[i] and gem_list[i] > 0 then
            gem_count = gem_count + 1
        end
    end
    equip:get_equip_data():set_gem_count(gem_count)
end

-- 客户竄1�7 Dress_Gem.lua 调用：scriptID=891736, func=OnDressGem_Enchase, 4参数(equip, gem1, gem2, gem3)
function dress_gem_embed:OnDressGem_Enchase(selfId, equip_index, gem1_index, gem2_index, gem3_index)
    skynet.logi("[DBG_DRESS_GEM] OnDressGem_Enchase enter: selfId=", selfId, " equip_index=", equip_index, " gem1=", gem1_index, " gem2=", gem2_index, " gem3=", gem3_index)
    -- 转发组1�7 OnDress_Enchase，isTip=0, reserved=0
    self:OnDress_Enchase(selfId, equip_index, gem1_index, gem2_index, gem3_index, 0, 0)
end

return dress_gem_embed
