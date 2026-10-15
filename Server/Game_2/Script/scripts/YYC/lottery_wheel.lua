local class = require "class"
local define = require "define"
local script_base = require "script_base"
local lottery_wheel = class("lottery_wheel", script_base)
lottery_wheel.script_id = 893998

local LOTTERY_ITEM = 38003929
local REFRESH_ITEM = 38003929
local TOTAL = 20
local CMD_INFO = 2013001
local CMD_DRAW = 2013002
local CMD_RESULT = 2013003

local POOL = {
    {itemid = 38003929, count = 1, weight = 100},
    {itemid = 38003929, count = 1, weight = 90},
    {itemid = 38003929, count = 1, weight = 80},
    {itemid = 38003929, count = 1, weight = 70},
    {itemid = 38003929, count = 1, weight = 60},
    {itemid = 38003929, count = 1, weight = 50},
    {itemid = 38003929, count = 1, weight = 40},
    {itemid = 38003929, count = 5, weight = 30},
    {itemid = 38003929, count = 3, weight = 25},
    {itemid = 38003929, count = 1, weight = 20},
    {itemid = 38003929, count = 50, weight = 15},
    {itemid = 38003929, count = 100, weight = 10},
    {itemid = 38003929, count = 200, weight = 8},
    {itemid = 38003929, count = 1, weight = 5},
    {itemid = 38003929, count = 1, weight = 5},
    {itemid = 38003929, count = 1, weight = 4},
    {itemid = 38003929, count = 1, weight = 3},
    {itemid = 38003929, count = 1, weight = 2},
    {itemid = 38003929, count = 1, weight = 2},
    {itemid = 38003929, count = 1, weight = 1},
}

function lottery_wheel:OnDefaultEvent(selfId, targetId)
    self:BeginEvent()
        self:AddText("Chào mừng tới Vòng quay may mắn!")
        self:AddNumText("Mở vòng quay", 6, 1)
        self:AddNumText("Đóng", 11, 0)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function lottery_wheel:OnEventRequest(selfId, targetId, arg, index)
    if index == 1 then
        self:SendPool(selfId)
    end
end

function lottery_wheel:SendPool(selfId)
    local sb = {}
    for i = 1, TOTAL do
        local p = POOL[i]
        sb[i] = (p and p.itemid .. "," .. p.count) or "0,0"
    end
    self:BeginUICommand()
    self:UICommand_AddStr(table.concat(sb, ";"))
    self:UICommand_AddStr("")
    self:UICommand_AddStr("")
    self:EndUICommand()
    self:DispatchUICommand(selfId, CMD_INFO)
end

function lottery_wheel:DoLotteryDraw(selfId, drawType)
    drawType = tonumber(drawType) or 1
    local cost = drawType >= 10 and 9 or 1
    local has = self:LuaFnGetAvailableItemCount(selfId, LOTTERY_ITEM)
    if has < cost then
        self:notify_tips(selfId, "Không đủ vé rút thưởng!")
        return
    end
    self:LuaFnDelAvailableItem(selfId, LOTTERY_ITEM, cost)
    local tw = 0
    for _, p in ipairs(POOL) do tw = tw + p.weight end
    if tw == 0 then return end
    local slots = {}
    local multiItems = {}
    self:BeginAddItem()
    for k = 1, drawType do
        local r = math.random(1, tw)
        local a = 0
        for i, p in ipairs(POOL) do
            a = a + p.weight
            if r <= a then
                self:AddItem(p.itemid, p.count, false)
                table.insert(slots, i)
                table.insert(multiItems, p.itemid)
                break
            end
        end
    end
    self:EndAddItem(selfId)
    self:AddItemListToHuman(selfId)
    local winIdx = slots[1] or 1
    local winItem = POOL[winIdx]
    self:BeginUICommand()
    self:UICommand_AddInt(winIdx)
    self:UICommand_AddInt(winItem and winItem.itemid or 0)
    self:UICommand_AddInt(drawType >= 10 and 1 or 0)
    self:EndUICommand()
    self:DispatchUICommand(selfId, CMD_DRAW)
    if drawType >= 10 then
        self.lottery_multi_result = multiItems
    else
        self.lottery_multi_result = nil
    end
end

function lottery_wheel:RequestResult(selfId, itemId)
    itemId = tonumber(itemId) or 0
    if self.lottery_multi_result and #self.lottery_multi_result > 0 then
        local names = {}
        for _, id in ipairs(self.lottery_multi_result) do
            table.insert(names, tostring(id))
        end
        self:BeginUICommand()
        self:UICommand_AddStr(table.concat(names, ","))
        self:UICommand_AddInt(1)
        self:EndUICommand()
        self:DispatchUICommand(selfId, CMD_RESULT)
        self.lottery_multi_result = nil
    elseif itemId > 0 then
        local poolIdx
        for i, p in ipairs(POOL) do
            if p.itemid == itemId then poolIdx = i; break end
        end
        local winItem = poolIdx and POOL[poolIdx]
        if winItem then
            self:BeginUICommand()
            self:UICommand_AddInt(winItem.itemid)
            self:UICommand_AddStr(self:GetItemName(winItem.itemid))
            self:UICommand_AddInt(winItem.count)
            self:EndUICommand()
            self:DispatchUICommand(selfId, CMD_RESULT)
        end
    end
end

return lottery_wheel