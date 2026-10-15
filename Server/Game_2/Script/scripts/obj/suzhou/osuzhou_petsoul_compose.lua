-- 淬魂合成 (hợp thành Thúy Hồn Thủy -> Thối Hồn Dịch -> Thối Hồn Tủy) — viết mới 2026-09-11 theo bảng công thức
-- trong client PetSoul_Compound.lua (g_PetSoul_Compound_Formula / _Item). Script id 800129.
-- Mở UI từ menu NPC Vân Thâm Thâm (800127, mục 104) -> UI 80012901 (1, targetId).
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_petsoul_compose = class("osuzhou_petsoul_compose", script_base)
osuzhou_petsoul_compose.script_id = 800129

local UI_MAIN = 80012901
local MAX_WANT = 99

-- select (1-based, client gửi g_PetSoul_Compound_Select+1): nguyên liệu, số lượng, tiền, kết quả
local g_Formula = {
    [1] = { need = 38002534, needcount = 3, money = 50000, result = 38002533 }, -- 3 淬魂水 -> 淬魂液
    [2] = { need = 38002533, needcount = 3, money = 50000, result = 38002532 }, -- 3 淬魂液 -> 淬魂髓
}

function osuzhou_petsoul_compose:RefreshUI(selfId, targetId, op)
    self:BeginUICommand()
    self:UICommand_AddInt(op) -- 0 đóng, 1 mở, 2 làm mới
    self:UICommand_AddInt(targetId or -1)
    self:EndUICommand()
    self:DispatchUICommand(selfId, UI_MAIN)
end

-- gọi từ script NPC khác: CallScriptFunction(800129, "OpenComposeUI", selfId, targetId)
function osuzhou_petsoul_compose:OpenComposeUI(selfId, targetId)
    self:RefreshUI(selfId, targetId, 1)
end

-- client: OnPetSoulComposeNew(targetId, select, wantNum, confirmed)
function osuzhou_petsoul_compose:OnPetSoulComposeNew(selfId, targetId, nSelect, nWant, bConfirmed)
    nSelect = math.tointeger(nSelect) or 0
    nWant = math.tointeger(nWant) or 0
    local f = g_Formula[nSelect]
    if f == nil then
        self:notify_tips(selfId, "Công thức không hợp lệ")
        return
    end
    if nWant < 1 then nWant = 1 end
    if nWant > MAX_WANT then nWant = MAX_WANT end
    local needCount = f.needcount * nWant
    local have = self:LuaFnGetAvailableItemCount(selfId, f.need)
    if have < needCount then
        self:notify_tips(selfId, string.format("Không đủ nguyên liệu: cần %d %s", needCount, self:GetItemName(f.need)))
        return
    end
    local needMoney = f.money * nWant
    local money = self:GetMoney(selfId) + self:GetMoneyJZ(selfId)
    if money < needMoney then
        self:notify_tips(selfId, "Kim tệ không đủ")
        return
    end
    if self:LuaFnGetPropertyBagSpace(selfId) < 1 then
        self:notify_tips(selfId, "Túi hành trang không đủ chỗ")
        return
    end
    if not self:LuaFnDelAvailableItem(selfId, f.need, needCount) then
        self:notify_tips(selfId, "Trừ nguyên liệu thất bại, kiểm tra vật phẩm có bị khoá không")
        return
    end
    self:LuaFnCostMoneyWithPriority(selfId, needMoney)
    local ok = self:TryRecieveItemWithCount(selfId, f.result, nWant, 0)
    if ok == nil or ok == false then
        -- không đưa được vật phẩm: hoàn lại nguyên liệu để không mất đồ
        self:TryRecieveItemWithCount(selfId, f.need, needCount, 0)
        self:notify_tips(selfId, "Hợp thành thất bại, đã hoàn nguyên liệu")
        return
    end
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 49, 0)
    self:notify_tips(selfId, string.format("Hợp thành thành công: %d %s", nWant, self:GetItemName(f.result)))
    self:RefreshUI(selfId, targetId, 2)
end

return osuzhou_petsoul_compose
