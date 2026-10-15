-- 封魂录主系统 (Phong Hồn Lục) — chuyển từ tlbb15/Public/Data/Script/event/huodong/FengHunLu/eFengHunLu_Main.lua
-- sang khung skynet (2026-09-11). Script id 791010. Client: PetSoul_FengHunLu.lua + MiniMap (AskOpenMainUI, 79101001/79101002).
-- Khác bản gốc: (1) bit helper viết bằng Lua 5.4; (2) "hoạt lực hôm nay" dùng điểm hoạt lực tuần (server không lưu theo ngày);
-- (3) điểm tích luỹ được nối qua human:add_mission_huoyuezhi (OnHuoYueActivity) và human:on_kill_object (OnKillMonster).
local skynet = require "skynet"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local eFengHunLu_Main = class("eFengHunLu_Main", script_base)
eFengHunLu_Main.script_id = 791010

-- Mission data ex index (giữ đúng số của tlbb15; Game_2 chưa dùng 108..112)
local MDEX_FENHUNLUDAYINDEX       = 108 -- thời điểm bắt đầu
local MDEX_PETSOUL_FENGHUNLU_POS1 = 109 -- điểm tích luỹ (bit) 1
local MDEX_PETSOUL_FENGHUNLU_POS2 = 110 -- điểm tích luỹ (bit) 2
local MDEX_PETSOUL_FENGHUNLU_AWORD1 = 111 -- cờ đã nhận (bit) 1
local MDEX_PETSOUL_FENGHUNLU_AWORD2 = 112 -- cờ đã nhận (bit) 2

local g_nMaxTotalDay        = 8   -- số ngày hoạt động
local g_nMaxEventPerDay     = 5   -- sự kiện mỗi ngày
local g_nMaxSavePos         = 32  -- bit mỗi MD
local g_nMaxPointRewardLevel = 5
local g_MDIndex      = { MDEX_PETSOUL_FENGHUNLU_POS1, MDEX_PETSOUL_FENGHUNLU_POS2 }
local g_MDPrizeIndex = { MDEX_PETSOUL_FENGHUNLU_AWORD1, MDEX_PETSOUL_FENGHUNLU_AWORD2 }
local UI_MAIN = 79101001
local UI_ICON = 79101002
local MIN_LEVEL = 85

-- Điểm tích luỹ: nSaveMDIndex / vị trí bit / độ dài / giá trị tối đa
local g_tabMaiDianSaveInfo = {
    [1]  = { nSaveMDIndex = 1, nSavePosStart = 0,  nSaveLen = 12, nMaxValue = 2500 }, -- giết quái
    [2]  = { nSaveMDIndex = 1, nSavePosStart = 12, nSaveLen = 5,  nMaxValue = 20 },   -- lão tam hoàn
    [3]  = { nSaveMDIndex = 1, nSavePosStart = 17, nSaveLen = 5,  nMaxValue = 15 },   -- nhiệm vụ bang hội
    [4]  = { nSaveMDIndex = 1, nSavePosStart = 22, nSaveLen = 5,  nMaxValue = 10 },   -- nhiệm vụ sư môn
    [5]  = { nSaveMDIndex = 1, nSavePosStart = 27, nSaveLen = 5,  nMaxValue = 9 },    -- Yến Tử Ổ
    [6]  = { nSaveMDIndex = 2, nSavePosStart = 0,  nSaveLen = 3,  nMaxValue = 4 },    -- kỳ cục
    [7]  = { nSaveMDIndex = 2, nSavePosStart = 3,  nSaveLen = 3,  nMaxValue = 4 },    -- khoái hoạt tam
    [8]  = { nSaveMDIndex = 2, nSavePosStart = 6,  nSaveLen = 3,  nMaxValue = 2 },    -- chạy thương
    [9]  = { nSaveMDIndex = 2, nSavePosStart = 9,  nSaveLen = 3,  nMaxValue = 2 },    -- khoa cử
    [10] = { nSaveMDIndex = 2, nSavePosStart = 12, nSaveLen = 3,  nMaxValue = 2 },    -- tiền thế kim sinh
    [11] = { nSaveMDIndex = 2, nSavePosStart = 15, nSaveLen = 3,  nMaxValue = 2 },    -- trình hung đả đồ
    [12] = { nSaveMDIndex = 2, nSavePosStart = 18, nSaveLen = 2,  nMaxValue = 1 },    -- hiệu trường tỉ võ
    [13] = { nSaveMDIndex = 2, nSavePosStart = 20, nSaveLen = 2,  nMaxValue = 1 },    -- bách biến kiểm phổ
}

-- Ánh xạ loại hoạt lực tuần (Weekactive.txt Index) -> điểm tích luỹ
local g_HuoYueToMaiDian = {
    [10] = 2, [11] = 2, [12] = 2, [13] = 2, [14] = 2,   -- 老三环
    [3] = 4, [4] = 4, [5] = 4,                          -- 师门任务
    [20] = 5, [21] = 5, [22] = 5,                       -- 讨伐燕子坞
    [36] = 6,                                           -- 棋局
    [40] = 8, [41] = 8,                                 -- 跑商
    [37] = 9,                                           -- 科举
    [2] = 11,                                           -- 藏宝图 (逞凶打图)
    [38] = 12,                                          -- 校场比武
    [39] = 13,                                          -- 百变脸谱
}

-- Sự kiện mỗi ngày: id điểm, giá trị cần, điểm thưởng, chỉ số sự kiện
local g_tabEventInfo = {
    [1] = {
        { nMaiDianID = 1,  nMaiDianValue = 100, nGetPoint = 1, nEventIndex = 1 },
        { nMaiDianID = 6,  nMaiDianValue = 1,   nGetPoint = 1, nEventIndex = 2 },
        { nMaiDianID = 7,  nMaiDianValue = 1,   nGetPoint = 1, nEventIndex = 3 },
        { nMaiDianID = 3,  nMaiDianValue = 1,   nGetPoint = 1, nEventIndex = 4 },
        { nMaiDianID = -1, nMaiDianValue = 100, nGetPoint = 1, nEventIndex = 5 },
    },
    [2] = {
        { nMaiDianID = 1,  nMaiDianValue = 200, nGetPoint = 1, nEventIndex = 6 },
        { nMaiDianID = 2,  nMaiDianValue = 5,   nGetPoint = 1, nEventIndex = 7 },
        { nMaiDianID = 12, nMaiDianValue = 1,   nGetPoint = 1, nEventIndex = 8 },
        { nMaiDianID = 8,  nMaiDianValue = 1,   nGetPoint = 1, nEventIndex = 9 },
        { nMaiDianID = 3,  nMaiDianValue = 5,   nGetPoint = 1, nEventIndex = 10 },
    },
    [3] = {
        { nMaiDianID = 1,  nMaiDianValue = 400, nGetPoint = 1, nEventIndex = 11 },
        { nMaiDianID = 11, nMaiDianValue = 1,   nGetPoint = 1, nEventIndex = 12 },
        { nMaiDianID = 13, nMaiDianValue = 1,   nGetPoint = 1, nEventIndex = 13 },
        { nMaiDianID = 7,  nMaiDianValue = 2,   nGetPoint = 1, nEventIndex = 14 },
        { nMaiDianID = 5,  nMaiDianValue = 3,   nGetPoint = 1, nEventIndex = 15 },
    },
    [4] = {
        { nMaiDianID = 1,  nMaiDianValue = 700, nGetPoint = 1, nEventIndex = 16 },
        { nMaiDianID = 2,  nMaiDianValue = 10,  nGetPoint = 1, nEventIndex = 17 },
        { nMaiDianID = 6,  nMaiDianValue = 2,   nGetPoint = 1, nEventIndex = 18 },
        { nMaiDianID = 9,  nMaiDianValue = 1,   nGetPoint = 1, nEventIndex = 19 },
        { nMaiDianID = 10, nMaiDianValue = 1,   nGetPoint = 1, nEventIndex = 20 },
    },
    [5] = {
        { nMaiDianID = 1,  nMaiDianValue = 1000, nGetPoint = 1, nEventIndex = 21 },
        { nMaiDianID = 4,  nMaiDianValue = 5,    nGetPoint = 1, nEventIndex = 22 },
        { nMaiDianID = 8,  nMaiDianValue = 2,    nGetPoint = 1, nEventIndex = 23 },
        { nMaiDianID = 7,  nMaiDianValue = 3,    nGetPoint = 1, nEventIndex = 24 },
        { nMaiDianID = 3,  nMaiDianValue = 10,   nGetPoint = 1, nEventIndex = 25 },
    },
    [6] = {
        { nMaiDianID = 1,  nMaiDianValue = 1500, nGetPoint = 1, nEventIndex = 26 },
        { nMaiDianID = 2,  nMaiDianValue = 15,   nGetPoint = 1, nEventIndex = 27 },
        { nMaiDianID = 6,  nMaiDianValue = 3,    nGetPoint = 1, nEventIndex = 28 },
        { nMaiDianID = 11, nMaiDianValue = 2,    nGetPoint = 1, nEventIndex = 29 },
        { nMaiDianID = 5,  nMaiDianValue = 6,    nGetPoint = 1, nEventIndex = 30 },
    },
    [7] = {
        { nMaiDianID = 1,  nMaiDianValue = 2000, nGetPoint = 1, nEventIndex = 31 },
        { nMaiDianID = 4,  nMaiDianValue = 10,   nGetPoint = 1, nEventIndex = 32 },
        { nMaiDianID = 7,  nMaiDianValue = 4,    nGetPoint = 1, nEventIndex = 33 },
        { nMaiDianID = 9,  nMaiDianValue = 2,    nGetPoint = 1, nEventIndex = 34 },
        { nMaiDianID = 10, nMaiDianValue = 2,    nGetPoint = 1, nEventIndex = 35 },
    },
    [8] = {
        { nMaiDianID = 1,  nMaiDianValue = 2500, nGetPoint = 1, nEventIndex = 36 },
        { nMaiDianID = 2,  nMaiDianValue = 20,   nGetPoint = 1, nEventIndex = 37 },
        { nMaiDianID = 6,  nMaiDianValue = 4,    nGetPoint = 1, nEventIndex = 38 },
        { nMaiDianID = 5,  nMaiDianValue = 9,    nGetPoint = 1, nEventIndex = 39 },
        { nMaiDianID = 3,  nMaiDianValue = 15,   nGetPoint = 1, nEventIndex = 40 },
    },
}

-- Thưởng theo tổng điểm
local g_tabPointRewardInfo = {
    [1] = { nNeedPoint = 5,  nRewardItemID = 38002535, nRewardItemNum = 2 },
    [2] = { nNeedPoint = 10, nRewardItemID = 38002535, nRewardItemNum = 2 },
    [3] = { nNeedPoint = 15, nRewardItemID = 38002535, nRewardItemNum = 3 },
    [4] = { nNeedPoint = 25, nRewardItemID = 38002535, nRewardItemNum = 3 },
    [5] = { nNeedPoint = 35, nRewardItemID = 38002536, nRewardItemNum = 4 },
}

-- ---------------------------------------------------------------- bit helper (thay LuaFnGet/SetBitValueInUINT)
local function get_bits(value, pos, len)
    value = math.tointeger(value) or 0
    return (value >> pos) & ((1 << len) - 1)
end

local function set_bits(value, pos, len, newv)
    value = math.tointeger(value) or 0
    local mask = ((1 << len) - 1) << pos
    return (value & ~mask) | ((newv << pos) & mask)
end

-- ---------------------------------------------------------------- tiện ích
function eFengHunLu_Main:NotifyTips(selfId, tip)
    self:BeginEvent(self.script_id)
    self:AddText(tip)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

function eFengHunLu_Main:GetTodayActivePoint(selfId)
    -- server skynet chỉ có hoạt lực tuần; dùng làm thay thế cho "hoạt lực hôm nay"
    local ok, v = pcall(self.GetWeekActiveHuoYue, self, selfId)
    if ok and type(v) == "number" then return v end
    return 0
end

function eFengHunLu_Main:GetStartTime(selfId)
    return math.tointeger(self:GetMissionDataEx(selfId, MDEX_FENHUNLUDAYINDEX)) or 0
end

-- số ngày kể từ lúc bắt đầu (1-based)
function eFengHunLu_Main:GetCurrentDayIndex(selfId)
    local start = self:GetStartTime(selfId)
    if start <= 0 then return 1 end
    local sub = self:LuaFnGetCurrentTime() - start
    local d = math.ceil(sub / (60 * 60 * 24))
    if d < 1 then d = 1 end
    return d
end

-- trả về: thời điểm kết thúc, năm, tháng, ngày
function eFengHunLu_Main:GetEndTime(selfId)
    local endt = self:GetStartTime(selfId) + g_nMaxTotalDay * 24 * 60 * 60
    local t = os.date("*t", endt)
    return endt, t.year, t.month, t.day
end

function eFengHunLu_Main:CheckActivityBasic(selfId)
    if self:GetLevel(selfId) < MIN_LEVEL then
        return 0, "#{XYSHFC_20211229_101}"
    end
    if self:GetStartTime(selfId) <= 0 then
        self:OnPlayerLogin(selfId)
    end
    local endt = self:GetEndTime(selfId)
    if self:LuaFnGetCurrentTime() > endt then
        self:BeginUICommand()
        self:UICommand_AddInt(0)
        self:EndUICommand()
        self:DispatchUICommand(selfId, UI_ICON)
        return 0, "#{XYSHFC_20211229_131}"
    end
    return 1, ""
end

-- ---------------------------------------------------------------- cờ / điểm
function eFengHunLu_Main:SetPointRewardFlag(selfId, level)
    if level == nil or level < 1 or level > g_nMaxPointRewardLevel then return -1 end
    local md = g_MDPrizeIndex[2]
    local pos = g_nMaxSavePos - level
    local data = self:GetMissionDataEx(selfId, md)
    self:SetMissionDataEx(selfId, md, set_bits(data, pos, 1, 1))
end

function eFengHunLu_Main:GetPointRewardFlag(selfId, level)
    if level == nil or level < 1 or level > g_nMaxPointRewardLevel then return -1 end
    local md = g_MDPrizeIndex[2]
    local pos = g_nMaxSavePos - level
    return get_bits(self:GetMissionDataEx(selfId, md), pos, 1)
end

function eFengHunLu_Main:SetEventRewardFlag(selfId, nDay, nIndexOfDay)
    if nDay == nil or nDay < 1 or nDay > g_nMaxTotalDay then return end
    if nIndexOfDay == nil or nIndexOfDay < 1 or nIndexOfDay > g_nMaxEventPerDay then return end
    local md = g_MDPrizeIndex[1]
    local pos = g_nMaxEventPerDay * (nDay - 1) + nIndexOfDay - 1
    if pos >= g_nMaxSavePos then
        md = g_MDPrizeIndex[2]
        pos = pos - g_nMaxSavePos
    end
    local data = self:GetMissionDataEx(selfId, md)
    self:SetMissionDataEx(selfId, md, set_bits(data, pos, 1, 1))
end

function eFengHunLu_Main:GetEventRewardFlag(selfId, nDay, nIndexOfDay)
    if nDay == nil or nDay < 1 or nDay > g_nMaxTotalDay then return -1 end
    if nIndexOfDay == nil or nIndexOfDay < 1 or nIndexOfDay > g_nMaxEventPerDay then return -1 end
    local md = g_MDPrizeIndex[1]
    local pos = g_nMaxEventPerDay * (nDay - 1) + nIndexOfDay - 1
    if pos >= g_nMaxSavePos then
        md = g_MDPrizeIndex[2]
        pos = pos - g_nMaxSavePos
    end
    return get_bits(self:GetMissionDataEx(selfId, md), pos, 1)
end

function eFengHunLu_Main:GetMaiDianValue(selfId, nMaiDianID)
    if nMaiDianID == nil or nMaiDianID <= 0 then return 0 end
    local info = g_tabMaiDianSaveInfo[nMaiDianID]
    if info == nil then return 0 end
    local md = g_MDIndex[info.nSaveMDIndex]
    if md == nil then return 0 end
    return get_bits(self:GetMissionDataEx(selfId, md), info.nSavePosStart, info.nSaveLen)
end

-- cộng 1 vào điểm tích luỹ nIndex (có kiểm tra thời gian + trần)
function eFengHunLu_Main:AddPointData(selfId, nIndex, count)
    -- [2026-09-17] CYS: chi lam viec khi doi tuong con nam trong canh cua script.
    -- script_base:GetLevel index thang scene.objs[selfId] nen selfId la va/ban sao cu
    -- se lam ca chuoi giet quai nem loi (canh 6, 16/09 14:47/14:50/14:52).
    local scene = self:get_scene()
    if not selfId or not scene or not scene:get_obj_by_id(selfId) then
        if not self._miss_obj_logged then
            self._miss_obj_logged = true
            skynet.logw("[FENGHUNLU_STALE] bo qua AddPointData: obj khong co trong canh",
                " selfId=", tostring(selfId),
                " scene=", tostring(scene and scene:get_id()),
                " nIndex=", tostring(nIndex))
        end
        return
    end
    if self:GetLevel(selfId) < MIN_LEVEL then return end
    if self:GetStartTime(selfId) <= 0 then self:OnPlayerLogin(selfId) end
    if self:LuaFnGetCurrentTime() > self:GetEndTime(selfId) then return end
    nIndex = math.tointeger(nIndex)
    if nIndex == nil or nIndex < 1 or nIndex > #g_tabMaiDianSaveInfo then return end
    count = math.tointeger(count) or 1
    if count < 1 then count = 1 end
    local info = g_tabMaiDianSaveInfo[nIndex]
    local md = g_MDIndex[info.nSaveMDIndex]
    if md == nil then return end
    local data = self:GetMissionDataEx(selfId, md)
    local value = get_bits(data, info.nSavePosStart, info.nSaveLen)
    if value >= info.nMaxValue then return end
    value = math.min(info.nMaxValue, value + count)
    self:SetMissionDataEx(selfId, md, set_bits(data, info.nSavePosStart, info.nSaveLen, value))
end

function eFengHunLu_Main:FengHunLu_GetTotalPoint(selfId)
    local total = 0
    local days = self:GetCurrentDayIndex(selfId)
    if days > g_nMaxTotalDay then days = g_nMaxTotalDay end
    for i = 1, days do
        for j = 1, g_nMaxEventPerDay do
            local f = self:GetEventRewardFlag(selfId, i, j)
            if f == 1 then total = total + 1 end
        end
    end
    return total
end

-- ---------------------------------------------------------------- UI
function eFengHunLu_Main:SendMainUI(selfId, op)
    local _, y, m, d = self:GetEndTime(selfId)
    self:BeginUICommand()
    self:UICommand_AddInt(op) -- 0 đóng, 1 mở, 2 làm mới
    self:UICommand_AddInt(self:GetCurrentDayIndex(selfId))
    self:UICommand_AddInt(self:GetMissionDataEx(selfId, MDEX_PETSOUL_FENGHUNLU_POS1))
    self:UICommand_AddInt(self:GetMissionDataEx(selfId, MDEX_PETSOUL_FENGHUNLU_POS2))
    self:UICommand_AddInt(self:GetMissionDataEx(selfId, MDEX_PETSOUL_FENGHUNLU_AWORD1))
    self:UICommand_AddInt(self:GetMissionDataEx(selfId, MDEX_PETSOUL_FENGHUNLU_AWORD2))
    self:UICommand_AddInt(self:GetTodayActivePoint(selfId))
    self:UICommand_AddInt(y)
    self:UICommand_AddInt(m)
    self:UICommand_AddInt(d)
    self:EndUICommand()
    self:DispatchUICommand(selfId, UI_MAIN)
end

-- client (MiniMap) yêu cầu mở UI
function eFengHunLu_Main:AskOpenMainUI(selfId)
    local state, tips = self:CheckActivityBasic(selfId)
    if state == 0 then
        self:NotifyTips(selfId, tips)
        return
    end
    self:SendMainUI(selfId, 1)
end

-- gọi khi vào game (Char_DataBase:OnPlayerUpdateIconDisplay) -> hiện/ẩn icon
function eFengHunLu_Main:OnPlayerLogin(selfId)
    if self:GetLevel(selfId) < MIN_LEVEL then
        self:BeginUICommand()
        self:UICommand_AddInt(0)
        self:EndUICommand()
        self:DispatchUICommand(selfId, UI_ICON)
        return
    end
    local start = self:GetStartTime(selfId)
    if start <= 0 then
        self:SetMissionDataEx(selfId, MDEX_FENHUNLUDAYINDEX, self:LuaFnGetCurrentTime())
        self:SetMissionDataEx(selfId, MDEX_PETSOUL_FENGHUNLU_POS1, 0)
        self:SetMissionDataEx(selfId, MDEX_PETSOUL_FENGHUNLU_POS2, 0)
        self:SetMissionDataEx(selfId, MDEX_PETSOUL_FENGHUNLU_AWORD1, 0)
        self:SetMissionDataEx(selfId, MDEX_PETSOUL_FENGHUNLU_AWORD2, 0)
    end
    if self:LuaFnGetCurrentTime() > self:GetEndTime(selfId) then
        self:BeginUICommand()
        self:UICommand_AddInt(0)
        self:EndUICommand()
        self:DispatchUICommand(selfId, UI_ICON)
        return
    end
    self:BeginUICommand()
    self:UICommand_AddInt(1)
    self:UICommand_AddInt(0)
    self:EndUICommand()
    self:DispatchUICommand(selfId, UI_ICON)
end

-- nhận thưởng 1 sự kiện trong ngày
function eFengHunLu_Main:GetRewardOfEvent(selfId, nDayIndex, nDayTimes)
    nDayIndex = math.tointeger(nDayIndex); nDayTimes = math.tointeger(nDayTimes)
    if nDayIndex == nil or nDayTimes == nil then return end
    if g_tabEventInfo[nDayIndex] == nil or g_tabEventInfo[nDayIndex][nDayTimes] == nil then return end
    local state, tips = self:CheckActivityBasic(selfId)
    if state == 0 then
        self:NotifyTips(selfId, tips)
        return
    end
    local cur = self:GetCurrentDayIndex(selfId)
    if cur > g_nMaxTotalDay then
        self:NotifyTips(selfId, "#{XYSHFC_20211229_132}")
        return
    end
    if nDayIndex > cur then
        self:NotifyTips(selfId, "#{XYSHFC_20211229_132}")
        return
    end
    local ev = g_tabEventInfo[nDayIndex][nDayTimes]
    if self:GetEventRewardFlag(selfId, nDayIndex, nDayTimes) == 1 then
        self:NotifyTips(selfId, "#{XYSHFC_20211229_133}")
        return
    end
    local curValue = 0
    if ev.nMaiDianID > 0 then
        curValue = self:GetMaiDianValue(selfId, ev.nMaiDianID)
    elseif ev.nMaiDianID == -1 then
        curValue = self:GetTodayActivePoint(selfId)
    else
        return
    end
    if curValue < ev.nMaiDianValue then
        self:NotifyTips(selfId, "#{XYSHFC_20211229_134}")
        return
    end
    self:SetEventRewardFlag(selfId, nDayIndex, nDayTimes)
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 49, 0)
    self:SendMainUI(selfId, 2)
end

-- nhận thưởng tổng điểm
function eFengHunLu_Main:GetRewardOfPoint(selfId)
    local state, tips = self:CheckActivityBasic(selfId)
    if state == 0 then
        self:NotifyTips(selfId, tips)
        return
    end
    local total = self:FengHunLu_GetTotalPoint(selfId)
    local pending = {}
    for i = 1, #g_tabPointRewardInfo do
        local r = g_tabPointRewardInfo[i]
        if total >= r.nNeedPoint and self:GetPointRewardFlag(selfId, i) ~= 1 then
            table.insert(pending, i)
        end
    end
    if #pending == 0 then
        self:NotifyTips(selfId, "#{XYSHFC_20211229_134}")
        return
    end
    self:BeginAddItem()
    for _, i in ipairs(pending) do
        self:AddItem(g_tabPointRewardInfo[i].nRewardItemID, g_tabPointRewardInfo[i].nRewardItemNum)
    end
    if not self:EndAddItem(selfId) then
        self:NotifyTips(selfId, "Túi hành trang không đủ chỗ")
        return
    end
    self:AddItemListToHuman(selfId)
    for _, i in ipairs(pending) do
        local r = g_tabPointRewardInfo[i]
        self:SetPointRewardFlag(selfId, i)
        self:NotifyTips(selfId, self:ScriptGlobal_Format("#{XYSHFC_20211229_144}", r.nRewardItemNum, self:GetItemName(r.nRewardItemID)))
    end
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 49, 0)
    self:SendMainUI(selfId, 2)
end

function eFengHunLu_Main:ShowHelp(selfId)
    if self:GetLevel(selfId) < MIN_LEVEL then return end
    local _, y, m, d = self:GetEndTime(selfId)
    self:BeginEvent(self.script_id)
    self:AddText(self:ScriptGlobal_Format("#{XYSHFC_20211229_105}", y, m, d))
    self:EndEvent()
    self:DispatchEventList(selfId, -1)
end

-- ---------------------------------------------------------------- hook từ server
-- human:add_mission_huoyuezhi -> loại hoạt lực tuần
function eFengHunLu_Main:OnHuoYueActivity(selfId, huoyue_type)
    local idx = g_HuoYueToMaiDian[math.tointeger(huoyue_type) or -1]
    if idx then self:AddPointData(selfId, idx, 1) end
end

-- human:on_kill_object -> giết quái
function eFengHunLu_Main:OnKillMonster(selfId, model)
    self:AddPointData(selfId, 1, 1)
end

return eFengHunLu_Main
