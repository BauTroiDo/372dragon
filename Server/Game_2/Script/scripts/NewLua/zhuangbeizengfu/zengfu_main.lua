local class = require "class"
local script_base = require "script_base"
local define = require "define"

local zengfu_main = class("zengfu_main", script_base)

zengfu_main.script_id = 990602
zengfu_main.UI_COMMAND = 2026050101
zengfu_main.UI_REFRESH_COMMAND = 2026050102
zengfu_main.AMPLIFY_MATERIAL_ID = 26000001
zengfu_main.AMPLIFY_MATERIAL_COUNT = 10
zengfu_main.PROTECT_ITEM_15_ID = 26000002
zengfu_main.PROTECT_ITEM_18_ID = 26000003
zengfu_main.COST_MONEY = 500000
zengfu_main.MAX_LEVEL = 20

zengfu_main.BONUS_TABLE = {
    [1] = 10,
    [2] = 20,
    [3] = 30,
    [4] = 40,
    [5] = 50,
    [6] = 60,
    [7] = 70,
    [8] = 80,
    [9] = 90,
    [10] = 100,
    [11] = 120,
    [12] = 150,
    [13] = 190,
    [14] = 240,
    [15] = 300,
    [16] = 420,
    [17] = 600,
    [18] = 840,
    [19] = 1140,
    [20] = 1500,
}

function zengfu_main:TryOpenAmplifyPanel(selfId, targetId, npc_script_id)
    self:BeginUICommand()
    self:UICommand_AddInt(targetId)
    self:EndUICommand()
    self:DispatchUICommand(selfId, self.UI_COMMAND)
    self:RefreshAmplifyUI(selfId, -1)
end

function zengfu_main:RequestAmplifyUIInfo(selfId, targetId, equip_pos)
    equip_pos = tonumber(equip_pos) or -1
    self:RefreshAmplifyUI(selfId, equip_pos)
end

function zengfu_main:GetAmplifyBonus(level)
    return self.BONUS_TABLE[tonumber(level) or 0] or 0
end

function zengfu_main:GetSuccessRate(target_level)
    target_level = tonumber(target_level) or 0
    if target_level <= 10 then
        -- return 50000
        return 5000 -- 50几率
    end
    return 2500 -- 25几率
    -- return 50000
end

function zengfu_main:NeedSecondConfirm(target_level)
    return (tonumber(target_level) or 0) > 18
end

function zengfu_main:IsAmplifyEquipPoint(equip_point)
    return equip_point == define.HUMAN_EQUIP.HEQUIP_CAP
        or equip_point == define.HUMAN_EQUIP.HEQUIP_ARMOR
        or equip_point == define.HUMAN_EQUIP.HEQUIP_GLOVE
        or equip_point == define.HUMAN_EQUIP.HEQUIP_BOOT
        or equip_point == define.HUMAN_EQUIP.HEQUIP_SASH
        or equip_point == define.HUMAN_EQUIP.HEQUIP_RING_1
        or equip_point == define.HUMAN_EQUIP.HEQUIP_NECKLACE
        or equip_point == define.HUMAN_EQUIP.HEQUIP_RING_2
        or equip_point == define.HUMAN_EQUIP.HEQUIP_AMULET_1
        or equip_point == define.HUMAN_EQUIP.HEQUIP_AMULET_2
        or equip_point == define.HUMAN_EQUIP.HEQUIP_CUFF
        or equip_point == define.HUMAN_EQUIP.HEQUIP_SHOULDER
end

function zengfu_main:CheckAmplifyRequest(selfId, targetId, equip_pos, protect_pos, confirm_flag)
    equip_pos = tonumber(equip_pos) or -1
    protect_pos = tonumber(protect_pos) or -1
    confirm_flag = tonumber(confirm_flag) or 0

    if not targetId or tonumber(targetId) <= 0 then
        return false, "Đối tượng NPC bất thường"
    end

    if equip_pos < 0 then
        return false, "Xin chọn trang bị cần tăng"
    end

    if not self:LuaFnIsItemAvailable(selfId, equip_pos) then
        return false, "Trang bị không tồn tại hoặc đã khóa"
    end

    local equip_index = self:LuaFnGetItemTableIndexByIndex(selfId, equip_pos)
    if not equip_index or equip_index <= 0 then
        return false, "Xin chọn trang bị cần tăng"
    end

    local equip_point = self:GetItemEquipPoint(equip_index)
    if not equip_point or not self:IsAmplifyEquipPoint(equip_point) then
        return false, "Loại trang bị này không tăng được"
    end

    local creator_name = tostring(self:LuaFnGetItemCreator(selfId, equip_pos) or "")
    local current_level = 0
    local pure_creator_name = creator_name
    local find_pos = string.find(creator_name, "&ZF", 1, true)
    if find_pos then
        pure_creator_name = string.sub(creator_name, 1, find_pos - 1)
        current_level = tonumber(string.sub(creator_name, find_pos + 3)) or 0
    end

    if current_level >= self.MAX_LEVEL then
        return false, "Trang bị đã cấp tăng tối đa"
    end

    local target_level = current_level + 1
    local protect_limit = 0

    if protect_pos >= 0 then
        if current_level < 10 then
            protect_pos = -1
        else
            if not self:LuaFnIsItemAvailable(selfId, protect_pos) then
                return false, "Vé bảo hộ không tồn tại hoặc đã khóa"
            end

            local protect_index = self:LuaFnGetItemTableIndexByIndex(selfId, protect_pos)
            if protect_index == self.PROTECT_ITEM_15_ID then
                if current_level < 10 or current_level > 14 then
                    return false, "Vé bảo hộ 15 chỉ dùng cho trang bị +10 tới +14"
                end
                protect_limit = 15
            elseif protect_index == self.PROTECT_ITEM_18_ID then
                if current_level < 15 or current_level > 17 then
                    return false, "Vé bảo hộ 18 chỉ dùng cho trang bị +15 tới +17"
                end
                protect_limit = 18
            else
                return false, "Ô phiếu bảo hộ chỉ có thể đặt vào Phiếu Bảo Hộ 15 hoặc Phiếu Bảo Hộ 18"
            end
        end
    end

    if self:LuaFnGetAvailableItemCount(selfId, self.AMPLIFY_MATERIAL_ID) < self.AMPLIFY_MATERIAL_COUNT then
        return false, string.format("%s không đủ, cần %d cái", self:GetItemName(self.AMPLIFY_MATERIAL_ID), self.AMPLIFY_MATERIAL_COUNT)
    end

    if self:GetMoney(selfId) + self:GetMoneyJZ(selfId) < self.COST_MONEY then
        return false, "Kim tệ không đủ"
    end

    if self:NeedSecondConfirm(target_level) and confirm_flag ~= 1 then
        return false, string.format("Đang chuẩn bị xung kích +%d, xin xác nhận lần hai", target_level)
    end

    return true, {
        equip_pos = equip_pos,
        protect_pos = protect_pos,
        pure_creator_name = pure_creator_name,
        current_level = current_level,
        target_level = target_level,
        protect_limit = protect_limit,
    }
end

function zengfu_main:RequestAmplify(selfId, targetId, equip_pos, protect_pos, confirm_flag)
    local ok, data = self:CheckAmplifyRequest(selfId, targetId, equip_pos, protect_pos, confirm_flag)
    if not ok then
        self:notify_tips(selfId, data)
        self:RefreshAmplifyUI(selfId, equip_pos)
        return
    end

    if not self:LuaFnDelAvailableItem(selfId, self.AMPLIFY_MATERIAL_ID, self.AMPLIFY_MATERIAL_COUNT) then
        self:notify_tips(selfId, "Trừ nguyên liệu tăng thất bại")
        self:RefreshAmplifyUI(selfId, data.equip_pos)
        return
    end

    if data.protect_pos >= 0 and not self:LuaFnDecItemLayCount(selfId, data.protect_pos, 1) then
        self:notify_tips(selfId, "Trừ vé bảo hộ thất bại")
        self:RefreshAmplifyUI(selfId, data.equip_pos)
        return
    end

    if self:LuaFnCostMoneyWithPriority(selfId, self.COST_MONEY) == -1 then
        self:notify_tips(selfId, "Trừ kim tệ thất bại")
        self:RefreshAmplifyUI(selfId, data.equip_pos)
        return
    end

    if math.random(10000) <= self:GetSuccessRate(data.target_level) then
        self:LuaFnSetItemCreator(
            selfId,
            data.equip_pos,
            string.format("%s&ZF%d", data.pure_creator_name, data.target_level)
        )
        self:LuaFnRefreshItemInfo(selfId, data.equip_pos)
        self:notify_tips(selfId, string.format("Tăng thành công, trang bị lên +%d.", data.target_level))
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 49, 0)
        self:RefreshAmplifyUI(selfId, data.equip_pos)
        return
    end

    if data.target_level <= 10 then
        local new_level = data.current_level - 1
        if new_level < 0 then
            new_level = 0
        end

        if new_level > 0 then
            self:LuaFnSetItemCreator(
                selfId,
                data.equip_pos,
                string.format("%s&ZF%d", data.pure_creator_name, new_level)
            )
        else
            self:LuaFnSetItemCreator(selfId, data.equip_pos, data.pure_creator_name)
        end
        self:LuaFnRefreshItemInfo(selfId, data.equip_pos)
        self:notify_tips(selfId, string.format("Tăng thất bại, trang bị hạ còn +%d.", new_level))
        self:RefreshAmplifyUI(selfId, data.equip_pos)
        return
    end

    if data.protect_limit > 0 then
        local new_level = data.current_level 
        if new_level < 0 then
            new_level = 0
        end

        if new_level > 0 then
            self:LuaFnSetItemCreator(
                selfId,
                data.equip_pos,
                string.format("%s&ZF%d", data.pure_creator_name, new_level)
            )
        else
            self:LuaFnSetItemCreator(selfId, data.equip_pos, data.pure_creator_name)
        end
        self:LuaFnRefreshItemInfo(selfId, data.equip_pos)
        self:notify_tips(
            selfId,
            string.format("Tăng thất bại, vé bảo hộ %d hiệu lực, trang bị không vỡ!!", data.protect_limit)
        )
        self:RefreshAmplifyUI(selfId, data.equip_pos)
        return
    end

    self:LuaFnEraseItem(selfId, data.equip_pos)
    self:notify_tips(selfId, "Tăng thất bại, trang bị đã vỡ.")
    self:RefreshAmplifyUI(selfId, -1)
end

function zengfu_main:RefreshAmplifyUI(selfId, equip_pos)
    equip_pos = tonumber(equip_pos) or -1
    local current_level = 0
    local next_level = 1
    local current_bonus = 0
    local next_bonus = self:GetAmplifyBonus(1)

    if equip_pos >= 0 and self:LuaFnIsItemAvailable(selfId, equip_pos) then
        local creator_name = tostring(self:LuaFnGetItemCreator(selfId, equip_pos) or "")
        local find_pos = string.find(creator_name, "&ZF", 1, true)
        if find_pos then
            current_level = tonumber(string.sub(creator_name, find_pos + 3)) or 0
        end
        if current_level < 0 then
            current_level = 0
        end
        if current_level > self.MAX_LEVEL then
            current_level = self.MAX_LEVEL
        end
        current_bonus = self:GetAmplifyBonus(current_level)
        next_level = current_level + 1
        if next_level > self.MAX_LEVEL then
            next_level = self.MAX_LEVEL
        end
        next_bonus = self:GetAmplifyBonus(next_level)
        if current_level >= self.MAX_LEVEL then
            next_bonus = current_bonus
        end
    end

    self:BeginUICommand()
    self:UICommand_AddInt(equip_pos)
    self:UICommand_AddInt(current_level)
    self:UICommand_AddInt(current_bonus)
    self:UICommand_AddInt(next_level)
    self:UICommand_AddInt(next_bonus)
    self:EndUICommand()
    self:DispatchUICommand(selfId, self.UI_REFRESH_COMMAND)
end

return zengfu_main
