local ScriptGlobal = require "scripts.ScriptGlobal"
local class = require "class"
local periods = require "scripts.new_zhanling_info"
local script_base = require "script_base"

local zhenghe = class("zhenghe", script_base)

local MAX_POINT = 8000
local POINT_PER_PURCHASE = 200
local COST_PER_PURCHASE = 100
local ACTIVATE_COST = 2488
local ACTIVE_MDEX = ScriptGlobal.MDEX_JINGE_ACTIVE
local NEW_HOT_POINT_MF = 1082

local function valid_integer(value, min_value, max_value)
    value = tonumber(value)
    if not value or value ~= math.floor(value) then
        return nil
    end
    if min_value and value < min_value then
        return nil
    end
    if max_value and value > max_value then
        return nil
    end
    return value
end

local function date_to_time(date)
    local year = math.floor(date / 10000)
    local month = math.floor(date / 100) % 100
    local day = date % 100
    return os.time({ year = year, month = month, day = day, hour = 0 })
end

local function get_page_progress(packed, page)
    local factor = 100 ^ (4 - page)
    return math.floor(packed / factor) % 100
end

local function set_page_progress(packed, page, progress)
    local factor = 100 ^ (4 - page)
    local old = math.floor(packed / factor) % 100
    return packed + (progress - old) * factor
end

function zhenghe:GetCurrentPeriod()
    local today = self:GetTime2Day()
    for _, period in ipairs(periods) do
        if today >= period.begin_date and today <= period.end_date then
            return period
        end
    end
end

function zhenghe:CheckReset(selfId)
    local period = self:GetCurrentPeriod()
    if not period then
        return nil
    end

    local record_begin = self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_JINGE_PERIOD_BEGIN)
    if record_begin ~= period.begin_date then
        self:SetMissionDataEx(selfId, ScriptGlobal.MDEX_JINGE_PERIOD_BEGIN, period.begin_date)
        self:SetMissionDataEx(selfId, ScriptGlobal.MDEX_JINGE_POINT, 0)
        self:SetMissionDataEx(selfId, ScriptGlobal.MDEX_JINGE_PREMIUM_CLAIM, 0)
        self:SetMissionDataEx(selfId, ScriptGlobal.MDEX_JINGE_BUY_COUNT, 0)
        self:SetMissionDataEx(selfId, ACTIVE_MDEX, 0)
        self:SetMissionFlag(selfId, NEW_HOT_POINT_MF, 0)
    end
    return period
end

function zhenghe:IsActive(selfId)
    return self:GetMissionDataEx(selfId, ACTIVE_MDEX) > 0
end

function zhenghe:IsPageUnlocked(period, page)
    local unlock_time = date_to_time(period.begin_date) + (page - 1) * 7 * 24 * 60 * 60
    return os.time() >= unlock_time
end

function zhenghe:HasClaimableReward(selfId, period)
    if not self:IsActive(selfId) then
        return false
    end
    local point = self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_JINGE_POINT)
    local packed = self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_JINGE_PREMIUM_CLAIM)
    for page = 1, 4 do
        if self:IsPageUnlocked(period, page) then
            local progress = get_page_progress(packed, page)
            local level = (page - 1) * 5 + progress + 1
            local reward = period.rewards[level]
            if progress < 5 and reward and point >= reward.need_point then
                return true
            end
        end
    end
    return false
end

function zhenghe:DispatchState(selfId, update_type)
    local period = self:CheckReset(selfId)
    local point = self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_JINGE_POINT)
    local premium_claim = self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_JINGE_PREMIUM_CLAIM)
    local human = self:get_scene():get_obj_by_id(selfId)
    local day_active = human and human:get_week_active_day() or 0
    local hot_point = period and self:HasClaimableReward(selfId, period) and 1 or 0

    self:BeginUICommand()
    self:UICommand_AddInt(hot_point)
    self:UICommand_AddInt(0)
    self:UICommand_AddInt(0)
    self:UICommand_AddInt(0)
    self:UICommand_AddInt(0)
    self:UICommand_AddInt(point)
    self:UICommand_AddInt(update_type or 0)
    self:UICommand_AddInt(0)
    self:UICommand_AddInt(self:IsActive(selfId) and 1 or 0)
    self:UICommand_AddInt(day_active)
    self:UICommand_AddInt(premium_claim)
    self:EndUICommand()
    self:DispatchUICommand(selfId, 99852605)
end

function zhenghe:OpenZhengHeUI(selfId)
    self:BeginUICommand()
    self:EndUICommand()
    self:DispatchUICommand(selfId, 99852604)
    self:DispatchState(selfId, 0)
end

function zhenghe:OpenUI(selfId)
    self:DispatchState(selfId, 0)
end

function zhenghe:ClickHotPoint(selfId)
    self:CheckReset(selfId)
    self:SetMissionFlag(selfId, NEW_HOT_POINT_MF, 1)
end

function zhenghe:CanActivate(selfId)
    local period = self:CheckReset(selfId)
    if not period then
        self:notify_tips(selfId, "Hiện không trong kỳ Kim Qua Hiệu Lệnh")
        return false
    end
    if self:IsActive(selfId) then
        self:notify_tips(selfId, "Kim Qua Hiệu Lệnh kỳ này đã kích hoạt")
        return false
    end
    return true
end

function zhenghe:ActiveYueKa(selfId, mode)
    mode = valid_integer(mode, 0, 2)
    if not mode or not self:CanActivate(selfId) then
        return false
    end

    if mode == 0 then
        self:BeginUICommand()
        self:UICommand_AddStr("Có tốn 2488 nguyên bảo kích hoạt Kim Qua Hiệu Lệnh kỳ này không?")
        self:EndUICommand()
        self:DispatchUICommand(selfId, 99852601)
        return false
    end

    if mode == 1 then
        if self:GetYuanBao(selfId) < ACTIVATE_COST then
            self:notify_tips(selfId, "Không đủ nguyên bảo, không kích hoạt Kim Qua Hiệu Lệnh được")
            return false
        end
        self:LuaFnCostYuanBao(selfId, ACTIVATE_COST)
    end

    self:SetMissionDataEx(selfId, ACTIVE_MDEX, 1)
    self:notify_tips(selfId, "Kích hoạt Kim Qua Hiệu Lệnh thành công")
    self:DispatchState(selfId, 2)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 18, 0)
    return true
end

function zhenghe:AskOpenAddProgressUI(selfId)
    local period = self:CheckReset(selfId)
    if not period then
        self:notify_tips(selfId, "Hiện không trong kỳ Kim Qua Hiệu Lệnh")
        return
    end
    local point = self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_JINGE_POINT)
    local max_count = math.ceil((MAX_POINT - point) / POINT_PER_PURCHASE)
    if max_count <= 0 then
        self:notify_tips(selfId, "Điểm Kim Qua Hiệu Lệnh đã tối đa")
        return
    end

    self:BeginUICommand()
    self:UICommand_AddInt(1)
    self:UICommand_AddInt(point)
    self:UICommand_AddInt(MAX_POINT - point)
    self:UICommand_AddInt(1)
    self:EndUICommand()
    self:DispatchUICommand(selfId, 99852603)
end

function zhenghe:AskAddProgress(selfId, count, confirmed)
    count = valid_integer(count, 1)
    confirmed = valid_integer(confirmed or 0, 0, 1)
    local period = self:CheckReset(selfId)
    if not count or not confirmed or not period then
        self:notify_tips(selfId, "Số lượng mua không đúng")
        return
    end

    local point = self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_JINGE_POINT)
    local max_count = math.ceil((MAX_POINT - point) / POINT_PER_PURCHASE)
    if count > max_count then
        self:notify_tips(selfId, "Mua xong sẽ vượt giới hạn điểm Kim Qua Hiệu Lệnh")
        return
    end

    local cost = count * COST_PER_PURCHASE
    local yuanbao = self:GetYuanBao(selfId)
    if yuanbao < cost then
        self:notify_tips(selfId, "Không đủ Nguyên Bảo")
        return
    end

    if confirmed == 0 then
        self:BeginUICommand()
        self:UICommand_AddInt(count)
        self:UICommand_AddStr(string.format("Có tốn %d Nguyên Bảo mua %d điểm Kim Qua Hiệu Lệnh không?", cost,
            count * POINT_PER_PURCHASE))
        self:EndUICommand()
        self:DispatchUICommand(selfId, 99852602)
        return
    end

    self:LuaFnCostYuanBao(selfId, cost)

    self:SetMissionDataEx(selfId, ScriptGlobal.MDEX_JINGE_POINT,
        math.min(MAX_POINT, point + count * POINT_PER_PURCHASE))
    local bought = self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_JINGE_BUY_COUNT)
    self:SetMissionDataEx(selfId, ScriptGlobal.MDEX_JINGE_BUY_COUNT, bought + count)
    self:notify_tips(selfId, "Mua điểm Kim Qua Hiệu Lệnh thành công")

    local new_point = self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_JINGE_POINT)
    local left_count = math.ceil((MAX_POINT - new_point) / POINT_PER_PURCHASE)
    self:BeginUICommand()
    self:UICommand_AddInt(left_count > 0 and 2 or 0)
    self:UICommand_AddInt(new_point)
    self:UICommand_AddInt(MAX_POINT - new_point)
    self:UICommand_AddInt(1)
    self:EndUICommand()
    self:DispatchUICommand(selfId, 99852603)
    self:DispatchState(selfId, 2)
end

function zhenghe:GetYueKaAward(selfId, page, is_rmb)
    page = valid_integer(page, 1, 4)
    is_rmb = valid_integer(is_rmb, 1, 1)
    local period = self:CheckReset(selfId)
    if not page or not is_rmb or not period then
        self:notify_tips(selfId, "Tham số nhận không đúng")
        return
    end
    if not self:IsActive(selfId) then
        self:notify_tips(selfId, "Xin kích hoạt Kim Qua Hiệu Lệnh trước")
        return
    end
    if not self:IsPageUnlocked(period, page) then
        self:notify_tips(selfId, "Thưởng trang này chưa mở")
        return
    end

    local packed = self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_JINGE_PREMIUM_CLAIM)
    local progress = get_page_progress(packed, page)
    if progress >= 5 then
        self:notify_tips(selfId, "Thưởng trang này đã nhận hết")
        return
    end

    local level = (page - 1) * 5 + progress + 1
    local reward = period.rewards[level]
    local point = self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_JINGE_POINT)
    if not reward then
        self:notify_tips(selfId, "Thiếu cấu hình thưởng Kim Qua Hiệu Lệnh")
        return
    end
    if point < reward.need_point then
        self:notify_tips(selfId, "Không đủ điểm Kim Qua Hiệu Lệnh")
        return
    end

    self:BeginAddItem()
    self:AddItem(reward.item_id, reward.item_count, reward.is_bind)
    if not self:EndAddItem(selfId) then
        return
    end
    self:AddItemListToHuman(selfId, 0)
    packed = set_page_progress(packed, page, progress + 1)
    self:SetMissionDataEx(selfId, ScriptGlobal.MDEX_JINGE_PREMIUM_CLAIM, packed)
    self:notify_tips(selfId, "Nhận thưởng Kim Qua Hiệu Lệnh thành công")
    self:DispatchState(selfId, 2)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 18, 0)
end

function zhenghe:AddPoint(selfId, add)
    add = valid_integer(add, 1)
    local period = self:CheckReset(selfId)
    if not add or not period then
        return false
    end
    local point = self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_JINGE_POINT)
    self:SetMissionDataEx(selfId, ScriptGlobal.MDEX_JINGE_POINT,
        math.min(MAX_POINT, point + add))
    self:DispatchState(selfId, 2)
    return true
end

return zhenghe
