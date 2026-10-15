--天鉴神券
--普通
local gbk = require "wire_charset"
local ScriptGlobal = require "scripts.ScriptGlobal"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local shenquan = class("shenquan", script_base)
local Items = { 38002761, 38002797}
function shenquan:AskOpenMainUI(selfId)
    self:CheckReset(selfId)
    local today = self:GetTime2Day()
    local point = self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_SHENQUAN_POINT)
    local count = self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_SHENQUAN_GET_COUNT)
    local di_active = self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_SHENQUAN_GET_DI_ACTIVE)
    local di_count = self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_SHENQUAN_GET_DI_COUNT)
    local tian_active = self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_SHENQUAN_GET_TIAN_ACTIVE)
    local tian_count = self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_SHENQUAN_GET_TIAN_COUNT)
    local endDate = self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_SHENQUAN_END_DATE)
    self:BeginUICommand()
    self:UICommand_AddInt(1)
    self:UICommand_AddInt(today)
    self:UICommand_AddInt(point)
    self:UICommand_AddInt(1)
    self:UICommand_AddInt(count)    --普通领取
    self:UICommand_AddInt(di_count)
    self:UICommand_AddInt(di_active)    --地珍篇
    self:UICommand_AddInt(0)    --地珍普通领取
    self:UICommand_AddInt(tian_count)    --天宝篇
    self:UICommand_AddInt(tian_active)    --天宝领取
    self:UICommand_AddInt(endDate)
    self:EndUICommand()
    self:DispatchUICommand(selfId, 89021501)
end

function shenquan:AskOpenMissionUI(selfId)
    self:BeginUICommand()
    self:UICommand_AddInt(0)
    self:UICommand_AddInt(0)
    self:EndUICommand()
    self:DispatchUICommand(selfId, 89021505)
end

function shenquan:AskOpenAddProgressUI(selfId)
    local yuanbao_count = self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_SHENQUAN_YUANBAO_COUNT)
    local left_count = 120 - yuanbao_count
    self:BeginUICommand()
    self:UICommand_AddInt(1)
    self:UICommand_AddInt(0)
    self:UICommand_AddInt(left_count)
    self:UICommand_AddInt(1)
    self:EndUICommand()
    self:DispatchUICommand(selfId, 89021503)
end

function shenquan:AskAddProgress(selfId, count)
    local cost_yuanbao = count * 50
    if self:GetYuanBao(selfId) < cost_yuanbao then
        self:notify_tips(selfId, "Không đủ số nguyên bảo")
        return
    end
    local yuanbao_count = self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_SHENQUAN_YUANBAO_COUNT)
    local left_count = 120 - yuanbao_count
    if left_count <= 0 then
        self:notify_tips(selfId, "Tâm đắc nghiên tập mua tối đa 120 điểm")
        return
    end
    if true then
        self:notify_tips(selfId, "Thiên Giám Thần Khoán tạm chưa mở")
        return
    end
    self:LuaFnCostYuanBao(selfId, count)
    local point = self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_SHENQUAN_POINT)
    point = point + count
    yuanbao_count = yuanbao_count + count
    self:SetMissionDataEx(selfId, ScriptGlobal.MDEX_SHENQUAN_POINT, point)
    self:SetMissionDataEx(selfId, ScriptGlobal.MDEX_SHENQUAN_YUANBAO_COUNT, yuanbao_count)
    self:AskOpenAddProgressUI(selfId)
    self:AskOpenMainUI(selfId)
end

function shenquan:AskActRMBReward(selfId, check, Type)
    local ItemIndex = Items[Type]
    if Type == 2 then
        if self:LuaFnGetAvailableItemCount(selfId, ItemIndex) > 0 then
            self:LuaFnDelAvailableItem(selfId, ItemIndex, 1)
            self:SetMissionDataEx(selfId, ScriptGlobal.MDEX_SHENQUAN_GET_TIAN_ACTIVE, 1)
            self:AskOpenMainUI(selfId)
        else
            local index, merchadise = self:GetMerchadiseByItemIndex(selfId, ItemIndex)
            if index == nil then
                return
            end
            self:BeginUICommand()
            self:UICommand_AddInt(13)
            self:UICommand_AddInt(5)
            self:UICommand_AddInt(merchadise.price)
            self:UICommand_AddInt(index - 1)
            self:UICommand_AddInt(0)
            self:UICommand_AddInt(self.script_id)
            self:UICommand_AddInt(1)
            self:UICommand_AddInt(131071)
            self:UICommand_AddStr("#{SWXT_221213_258}")
            self:EndUICommand()
            self:DispatchUICommand(selfId, 89021506)
        end
    else
        if self:LuaFnGetAvailableItemCount(selfId, ItemIndex) > 0 then
            self:LuaFnDelAvailableItem(selfId, ItemIndex, 1)
            self:SetMissionDataEx(selfId, ScriptGlobal.MDEX_SHENQUAN_GET_DI_ACTIVE, 1)
            self:AskOpenMainUI(selfId)
        else
            local index, merchadise = self:GetMerchadiseByItemIndex(selfId, ItemIndex)
            if index == nil then
                return
            end
            self:BeginUICommand()
            self:UICommand_AddInt(14)
            self:UICommand_AddInt(5)
            self:UICommand_AddInt(merchadise.price)
            self:UICommand_AddInt(index - 1)
            self:UICommand_AddInt(0)
            self:UICommand_AddInt(self.script_id)
            self:UICommand_AddInt(1)
            self:UICommand_AddInt(131071)
            self:UICommand_AddStr("#{SWXT_221213_256}")
            self:EndUICommand()
            self:DispatchUICommand(selfId, 89021506)
        end
    end
end

function shenquan:AskGetReward(selfId, index, Type)
    local point = self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_SHENQUAN_POINT)
    local level = math.ceil(point / 10)
    if level < index then
        self:notify_tips(selfId, "Cấp độ không đủ")
        return
    end
    local is_active
    if Type == 0 then
        is_active = true
    elseif Type == 1 then
        is_active = self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_SHENQUAN_GET_DI_ACTIVE) == 1
    elseif Type == 2 then
        is_active = self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_SHENQUAN_GET_TIAN_ACTIVE) == 1
    end
    if not is_active then
        self:notify_tips(selfId, "Chưa kích hoạt chiến lệnh chỉ định")
        return
    end
    local count_key
    if Type == 0 then
        count_key = ScriptGlobal.MDEX_SHENQUAN_GET_COUNT
    elseif Type == 1 then
        count_key = ScriptGlobal.MDEX_SHENQUAN_GET_DI_COUNT
    elseif Type == 2 then
        count_key = ScriptGlobal.MDEX_SHENQUAN_GET_TIAN_COUNT
    end
    local mask = self:GetMissionDataEx(selfId, count_key)
    local bit = (0x1 << index - 1)
    if mask & bit == bit then
        self:notify_tips(selfId, "Đã nhận thưởng")
        return
    end
    mask = mask | bit
    self:SetMissionDataEx(selfId, count_key, mask)
    local ItemID, ItemCount = self:GetZhanLingAwardConfig(index, Type + 1)
    self:TryRecieveItemWithCount(selfId, ItemID, ItemCount)
    self:AskOpenMainUI(selfId)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 18, 0)
end

function shenquan:CheckReset(selfId)
    local today = self:GetTime2Day()
    local endDate = self:GetZhanLingEndDate(today)
    local RecordEndDate = self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_SHENQUAN_END_DATE)
    if endDate and endDate > RecordEndDate then
        self:SetMissionDataEx(selfId, ScriptGlobal.MDEX_SHENQUAN_END_DATE, endDate)
        self:SetMissionDataEx(selfId, ScriptGlobal.MDEX_SHENQUAN_POINT, 0)
        self:SetMissionDataEx(selfId, ScriptGlobal.MDEX_SHENQUAN_GET_COUNT, 0)
        self:SetMissionDataEx(selfId, ScriptGlobal.MDEX_SHENQUAN_GET_DI_ACTIVE, 0)
        self:SetMissionDataEx(selfId, ScriptGlobal.MDEX_SHENQUAN_GET_DI_COUNT, 0)
        self:SetMissionDataEx(selfId, ScriptGlobal.MDEX_SHENQUAN_GET_TIAN_ACTIVE, 0)
        self:SetMissionDataEx(selfId, ScriptGlobal.MDEX_SHENQUAN_GET_TIAN_COUNT, 0)
        self:SetMissionDataEx(selfId, ScriptGlobal.MDEX_SHENQUAN_YUANBAO_COUNT, 0)
    end
end

function shenquan:AddPoint(selfId, add)
    local point = self:GetMissionDataEx(selfId, ScriptGlobal.MDEX_SHENQUAN_POINT)
    point = point + add
    self:SetMissionDataEx(selfId, ScriptGlobal.MDEX_SHENQUAN_POINT, point)
end

return shenquan