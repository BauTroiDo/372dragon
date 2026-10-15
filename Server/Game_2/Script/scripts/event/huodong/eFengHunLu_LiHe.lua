-- 封魂录礼包 (Hồn Ngọc Quỳnh Hạp 38002535 / Hồn Ngọc Phúc Hạp 38002536) — chuyển từ tlbb15 eFengHunLu_LiHe.lua (2026-09-11)
-- Script id 791011. Dùng vật phẩm -> OnDefaultEvent(selfId, BagPos); client PetSoul_FengHunLuGift (UI 79101101 / 79101102).
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local eFengHunLu_LiHe = class("eFengHunLu_LiHe", script_base)
eFengHunLu_LiHe.script_id = 791011

local ITEM_QIONG_XIA = 38002535 -- 魂玉琼匣: chọn thưởng
local ITEM_FU_XIA    = 38002536 -- 魂玉福匣: ngẫu nhiên
local UI_SELECT  = 79101101
local UI_CONFIRM = 79101102
local MIN_LEVEL  = 85

local g_HunYuFuXia = {
    { 38002528, 2 },
    { 38002524, 3 },
    { 38002519, 4 },
}
local g_tableRewardInfo = {
    [1] = { nGiveItemID = 38002528, nGiveItemNum = 2, nGiveAddItemID = 0,        nGiveAddItemNum = 0, nCostYuanBao = 0 },
    [2] = { nGiveItemID = 38002528, nGiveItemNum = 2, nGiveAddItemID = 38002524, nGiveAddItemNum = 3, nCostYuanBao = 500 },
    [3] = { nGiveItemID = 38002528, nGiveItemNum = 2, nGiveAddItemID = 38002519, nGiveAddItemNum = 4, nCostYuanBao = 2000 },
}

function eFengHunLu_LiHe:IsSkillLikeScript()
    return 0
end

function eFengHunLu_LiHe:CancelImpacts()
    return 0
end

function eFengHunLu_LiHe:NotifyFailTips(selfId, tip)
    self:BeginEvent(self.script_id)
    self:AddText(tip)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

-- dùng vật phẩm
function eFengHunLu_LiHe:OnDefaultEvent(selfId, BagPos)
    local itemId = self:GetItemTableIndexByIndex(selfId, BagPos)
    if itemId ~= ITEM_QIONG_XIA and itemId ~= ITEM_FU_XIA then
        return 0
    end
    if self:GetLevel(selfId) < MIN_LEVEL then
        self:NotifyFailTips(selfId, "#{ZSPVP_211231_08}")
        return 0
    end
    if itemId == ITEM_FU_XIA then
        local pick = g_HunYuFuXia[math.random(1, #g_HunYuFuXia)]
        self:BeginAddItem()
        self:AddItem(pick[1], pick[2])
        if not self:EndAddItem(selfId) then
            self:NotifyFailTips(selfId, "Túi hành trang không đủ chỗ")
            return 0
        end
        self:EraseItem(selfId, BagPos)
        self:AddItemListToHuman(selfId)
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 18, 0)
        self:NotifyFailTips(selfId, self:ScriptGlobal_Format("#{XYSHFC_20211229_151}", tostring(pick[2]), self:GetItemName(pick[1])))
        return 1
    end
    -- 琼匣: mở UI cho người chơi chọn
    self:BeginUICommand()
    self:UICommand_AddInt(1) -- 0 đóng, 1 mở, 2 làm mới, 3 hộp xác nhận
    self:UICommand_AddInt(BagPos)
    self:EndUICommand()
    self:DispatchUICommand(selfId, UI_SELECT)
    return 0
end

-- client chọn: nItemPos (ô túi), nSelect (1..3), nConfirm (0/1)
function eFengHunLu_LiHe:OnUIClickCallBack(selfId, nItemPos, nSelect, nConfirm)
    nItemPos = math.tointeger(nItemPos); nSelect = math.tointeger(nSelect); nConfirm = math.tointeger(nConfirm) or 0
    if nItemPos == nil or nSelect == nil then return end
    if self:GetItemTableIndexByIndex(selfId, nItemPos) ~= ITEM_QIONG_XIA then
        return
    end
    if nSelect > 1 and nConfirm ~= 1 then
        self:BeginUICommand()
        self:UICommand_AddInt(3)
        self:UICommand_AddInt(nItemPos)
        self:UICommand_AddInt(nSelect)
        if nSelect == 2 then
            self:UICommand_AddStr("#{XYSHFC_20211229_159}")
        elseif nSelect == 3 then
            self:UICommand_AddStr("#{XYSHFC_20211229_162}")
        end
        self:EndUICommand()
        self:DispatchUICommand(selfId, UI_CONFIRM)
        return
    end
    local prize = g_tableRewardInfo[nSelect]
    if prize == nil then return end
    self:BeginAddItem()
    self:AddItem(prize.nGiveItemID, prize.nGiveItemNum)
    if prize.nGiveAddItemID > 0 then
        self:AddItem(prize.nGiveAddItemID, prize.nGiveAddItemNum)
    end
    if not self:EndAddItem(selfId) then
        self:NotifyFailTips(selfId, "Túi hành trang không đủ chỗ")
        return
    end
    if prize.nCostYuanBao > 0 then
        local yb = self:GetYuanBao(selfId) or 0
        if yb < prize.nCostYuanBao then
            self:NotifyFailTips(selfId, "#{XYSHFC_20211229_152}")
            return
        end
        self:LuaFnCostYuanBao(selfId, prize.nCostYuanBao)
    end
    self:EraseItem(selfId, nItemPos)
    self:AddItemListToHuman(selfId)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 18, 0)
    self:NotifyFailTips(selfId, self:ScriptGlobal_Format("#{XYSHFC_20211229_151}", tostring(prize.nGiveItemNum), self:GetItemName(prize.nGiveItemID)))
    if prize.nGiveAddItemID > 0 then
        self:NotifyFailTips(selfId, self:ScriptGlobal_Format("#{XYSHFC_20211229_151}", tostring(prize.nGiveAddItemNum), self:GetItemName(prize.nGiveAddItemID)))
    end
    self:BeginUICommand()
    self:UICommand_AddInt(0)
    self:EndUICommand()
    self:DispatchUICommand(selfId, UI_SELECT)
end

return eFengHunLu_LiHe
