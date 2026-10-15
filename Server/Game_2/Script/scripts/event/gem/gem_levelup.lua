-- 宝石升级系统
-- ScriptID=900011
-- 客户端通过XSCRIPT调用:
--   GemLevelup_Check(装备背包位置)      -- 获取装备上4颗宝石ID发给客户端
--   OnAskGemLevelup(装备位置, 选中宝石序号, 客户端校验经验值, MingJingShi类型)  -- 执行升级
local skynet = require "skynet"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local gbk = require "wire_charset"
local packet_def = require "game.packet"

local gem_levelup = class("gem_levelup", script_base)
gem_levelup.script_id = 900011

-- ============================================
-- 宝石升级检查：读取装备上4颗宝石ID发给客户端
-- 参数：selfId, GemUp_Item(装备背包位置0-99)
-- 客户端用 Get_XParam_INT(0~3) 接收4个宝石ID
-- ============================================
function gem_levelup:GemLevelup_Check(selfId, GemUp_Item)
    if GemUp_Item == nil then
        return
    end
    if GemUp_Item < 0 or GemUp_Item > 99 then
        return
    end

    local obj = self.scene:get_obj_by_id(selfId)
    if not obj then return end
    local item = obj:get_prop_bag_container():get_item(GemUp_Item)
    if not item then
        self:BeginUICommand()
        for i = 1, 4 do
            self:UICommand_AddInt(0)
        end
        self:EndUICommand()
        self:DispatchUICommand(selfId, 2016012298)
        return
    end

    local equip_data = item:get_equip_data()
    if not equip_data then
        self:BeginUICommand()
        for i = 1, 4 do
            self:UICommand_AddInt(0)
        end
        self:EndUICommand()
        self:DispatchUICommand(selfId, 2016012298)
        return
    end

    -- 读取4个宝石槽的ID（slot从1开始，返回0表示空）
    local gemIds = {}
    for i = 1, 4 do
        local gid = equip_data:get_slot_gem(i)
        gemIds[i] = gid or 0
    end

    self:BeginUICommand()
    for i = 1, 4 do
        self:UICommand_AddInt(gemIds[i])
    end
    self:EndUICommand()
    self:DispatchUICommand(selfId, 2016012298)
end

-- ============================================
-- 宝石升级主函数
-- 参数：
--   selfId    - 玩家ID
--   nEquipPos - 装备背包位置(0-99)
--   nSel      - 选中的宝石序号(1-4)
--   nSubSel   - 客户端计算的需要经验值（二次校验）
--   MingJingShi - 0=普通升级, 100=明镜石升级, 200=精石升级
-- ============================================
function gem_levelup:OnAskGemLevelup(selfId, nEquipPos, nSel, nSubSel, MingJingShi)
    -- 装备位置校验
    if nEquipPos == nil or nEquipPos < 0 or nEquipPos > 99 then
        self:NotifyTip(selfId, "Thăng cấp bảo thạch bất thường:" .. tostring(nEquipPos))
        return
    end

    -- 选中槽位校验：必须为 1~4
    if nSel == nil or nSel < 1 or nSel > 4 then
        self:NotifyTip(selfId, "Thăng cấp bảo thạch bất thường: tham số ô chọn sai")
        return
    end

    local obj = self.scene:get_obj_by_id(selfId)
    if not obj then return end
    local container = obj:get_prop_bag_container()
    local equip_item = container:get_item(nEquipPos)
    if not equip_item then
        self:NotifyTip(selfId, "Không thấy trang bị, xin xác nhận vị trí túi")
        return
    end

    local equip_data = equip_item:get_equip_data()
    if not equip_data then
        self:NotifyTip(selfId, "Vật phẩm chọn không phải trang bị")
        return
    end

    -- 读取4个宝石槽ID
    local nItemIDDest = {}
    for i = 1, 4 do
        local gid = equip_data:get_slot_gem(i)
        nItemIDDest[i] = gid or 0
    end

    -- 检查4个槽都有宝石（必须全部镶嵌才能升级）
    for i = 1, 4 do
        if nItemIDDest[i] == 0 then
            self:NotifyTip(selfId, "Phải đủ 4 viên đã khảm mới thăng cấp bảo thạch được")
            return
        end
    end

    -- 选中的宝石ID
    local GemOldID = nItemIDDest[nSel]
    if not GemOldID or GemOldID == 0 then
        self:NotifyTip(selfId, "Ô đã chọn không có bảo thạch khảm")
        return
    end

    -- 宝石等级（品质）
    local Gem_Level = self:GetItemQuality(GemOldID)

    -- 计算新宝石ID
    local GemNewID = 0
    if MingJingShi == 0 then
        -- 普通升级
        GemNewID = GemOldID + 100000
    elseif MingJingShi == 100 then
        -- 明镜石升级（双钻宝石系列专用）
        if Gem_Level > 7 then
            self:NotifyTip(selfId, "Bảo thạch này đã cấp tối đa:" .. tostring(Gem_Level))
            return
        else
            GemNewID = GemOldID + 100000
        end
    elseif MingJingShi == 200 then
        -- 精石升级（双钻宝石的精石等级提升）
        if math.fmod(GemOldID, 10) >= Gem_Level then
            self:NotifyTip(selfId, "Cấp bảo thạch tinh thạch đã chọn là" .. tostring(math.fmod(GemOldID, 10)) .. ", tinh thạch đã tối đa, xin nâng cấp bảo thạch song toản rồi hãy nâng tinh thạch")
            return
        else
            GemNewID = GemOldID + 1
        end
    else
        self:NotifyTip(selfId, "Tham số loại thăng cấp bất thường")
        return
    end

    -- 检查宝石名称是否含"暗"（暗宝石不支持升级）
    local GemName = self:GetItemName(GemOldID)
    if type(GemName) == "string" and string.find(GemName, gbk.fromutf8("Ám")) then
        self:NotifyTip(selfId, "Ám bảo thạch không hỗ trợ thăng cấp")
        return
    end

    -- 宝石等级是否满足5级
    if Gem_Level < 5 then
        self:NotifyTip(selfId, "Bảo thạch dưới cấp 5 không thăng cấp được (xin dùng hợp thành trước)")
        return
    end

    -- 7级以上只能用明镜石或精石升级
    if Gem_Level > 7 and MingJingShi == 0 then
        self:NotifyTip(selfId, "Bảo thạch trên cấp 7 không thăng thường được, xin dùng Minh Kính Thạch hoặc tinh thạch")
        return
    end

    -- 计算价格倍率
    local GemMStour = 1
    local GemTapy = math.floor(math.fmod(GemOldID, 10000) / 100)

    -- 双钻宝石价格 3倍
    if GemTapy == 10 then
        GemMStour = 3
    end

    -- 双钻系列宝石（11-14）必须用明镜石或精石模式
    if GemTapy >= 11 and GemTapy <= 14 then
        if MingJingShi == 0 then
            self:NotifyTip(selfId, "Mẹo: bảo thạch dòng song toản xin chọn [Minh Kính Thạch] hoặc [tinh thạch] để thăng cấp!")
            return
        end
    end

    --         3级    4级     5级         6级          7级        8级
    local YuanBaonum = { 0, 0, 0, 0, 50000000, 300000000, 0, 0, 0 }

    -- 计算需要的经验值
    local NeedYuanBaoNum = YuanBaonum[Gem_Level] or 0

    -- 服务端与客户端二次校验
    if NeedYuanBaoNum ~= nSubSel then
        self:NotifyTip(selfId, "Kiểm tra thất bại, GemMStour:" .. tostring(GemMStour) .. "-GemTapy:" .. tostring(GemTapy))
        self:NotifyTip(selfId, "Kiểm tra thất bại, phía server:" .. tostring(NeedYuanBaoNum) .. "-Client:" .. tostring(nSubSel) .. "-OID:" .. tostring(GemOldID))
        return
    end

    -- 检查经验值是否足够
    local curExp = self:GetExp(selfId)
    if curExp < NeedYuanBaoNum then
        self:BroadMsgByChatPipe(selfId, gbk.fromutf8("Kinh nghiệm sở hữu không đủ" .. tostring(NeedYuanBaoNum) .. ", không thử thăng cấp được!"), 0)
        return
    end

    -- 扣除经验值
    self:LuaFnCostExp(selfId, NeedYuanBaoNum)

    -- 发送升级成功特效
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 49, 0)

    -- 替换装备上的宝石ID（直接更新槽位，不触发 gem_count 计数变化）
    -- 注意：不能用 gem_embed，该函数会导致 gem_count +1，升级场景只需要替换 ID
    equip_data:get_gem_list()[nSel] = GemNewID

    -- 刷新客户端装备显示
    local msg = packet_def.GCItemInfo.new()
    msg.bagIndex = nEquipPos
    msg.item = equip_item:copy_raw_data()
    self.scene:send2client(obj, msg)

    self:NotifyTip(selfId, "Chúc mừng! Thăng cấp bảo thạch thành công!")

    -- 发送升级成功全服公告
    local szTransferEquip = self:GetBagItemTransfer(selfId, nEquipPos)
    local playerName = self:GetName(selfId)
    local oldGemName = self:GetItemName(GemOldID)
    local newGemName = self:GetItemName(GemNewID)
    local fmtMsg = string.format(
        gbk.fromutf8("#P#{_INFOUSR%s} tốn#G%d#Pkinh nghiệm, nâng thành công#G[%s]#Ptrong #{_INFOMSG%s} lên#G[%s]"),
        gbk.fromutf8(tostring(playerName)),
        NeedYuanBaoNum,
        szTransferEquip,
        gbk.fromutf8(tostring(oldGemName)),
        gbk.fromutf8(tostring(newGemName))
    )
    self:AddGlobalCountNews(fmtMsg, true)

    -- 刷新界面
    self:OnAskGemLevelupNum(selfId, nEquipPos)
end

-- ============================================
-- 升级后刷新界面
-- ============================================
function gem_levelup:OnAskGemLevelupNum(selfId, nEquipPos)
    self:BeginUICommand()
    self:UICommand_AddInt(201107281)
    self:UICommand_AddInt(nEquipPos)
    self:EndUICommand()
    self:DispatchUICommand(selfId, 201408141)
end

-- ============================================
-- 提示消息
-- ============================================
function gem_levelup:NotifyTip(selfId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return gem_levelup
