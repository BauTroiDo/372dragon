local class = require "class"
local utils = require "utils"
local gbk = require "wire_charset"
local skynet = require "skynet"
local define = require "define"
local script_base = require "script_base"
local bet = class("bet", script_base)
local Texts = {
    [38008157] = { name = "Xu Thiên Ngoại 1", options = { {id = 101, desc = "Hợp thành 1 lần"}, {id = 102, desc = "Hợp thành 10 lần"}, {id = 104, desc = "Đổi đạo cụ game"} } },
    [38008158] = { name = "Thiên Ngoại Đại Tệ 2", options = { {id = 201, desc = "Phân giải 1 lần"}, {id = 202, desc = "Phân giải 10 lần"}, {id = 104, desc = "Đổi đạo cụ game"} }},
}
local ExchangeConfigs = {
    { id = 10001, desc = "6888 cái đổi hộp Trùng Lâu tự chọn 1 cái", need_count = 6888, awards = { item_id = 38002943, item_num = 1}, need_space_count = 1},
    { id = 10002, desc = "100 cái đổi Võ Đạo Huyền Nguyên Đan 100 viên", need_count = 100, awards = { item_id = 38002397, item_num = 100}, need_space_count = 1},
    { id = 10003, desc = "688 cái đổi rương Thần Hồn Đàn 366 cái", need_count = 688, awards = { item_id = 38002499, item_num = 366}, need_space_count = 3},
}
function bet:OnBet(selfId, main,action,score,append)
    local guid = self:LuaFnGetGUID(selfId)
    local area = utils.get_node_name()
    local name = self:LuaFnGetName(selfId)
    --skynet.send(".mqttor", "lua", "client_request", area, guid, main, action, score, append, name)
end

function bet:OnDefaultEvent(selfId, bag_index)
    local itemTblIndex = self:LuaFnGetItemTableIndexByIndex(selfId,bag_index)
    local Config = Texts[itemTblIndex]
    if Config == nil then
        self:notify_tips(selfId, "Cấu hình bất thường")
        return
    end
    self:BeginEvent(self.script_id)
    self:AddText(string.format("#Y%s", Config.name))
    for _, op in ipairs(Config.options) do
        self:AddNumText(op.desc, 0, op.id)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, -1)
    return 0
end

function bet:OnEventRequest(selfId, targetId, arg, index)
    if index == 101 then
        self:DaiBiOneToDaiBiTwo(selfId, 1)
        return
    end
    if index == 102 then
        self:DaiBiOneToDaiBiTwo(selfId, 10)
        return
    end
    if index == 103 then
        self:ShowUseMethod(selfId)
        return
    end
    if index == 104 then
        self:ShowExchangeList(selfId)
        return
    end
    if index == 201 then
        self:DaiBiTwoToDaiBiOne(selfId, 1)
        return
    end
    if index == 202 then
        self:DaiBiTwoToDaiBiOne(selfId, 10)
        return
    end
    if index >= 10001 then
        self:ExchangeItems(selfId, index)
        return
    end
end

function bet:GetExchangeConfig(index)
    for _, c in ipairs(ExchangeConfigs) do
        if c.id == index then
            return c
        end
    end
end

function bet:ExchangeItems(selfId, index)
    local config = self:GetExchangeConfig(index)
    if config == nil then
        self:BeginEvent(self.script_id)
        self:AddText("Cấu hình không tồn tại")
        self:EndEvent()
        self:DispatchEventList(selfId, -1)
        return
    end
    local space_count = self:LuaFnGetPropertyBagSpace(selfId)
    if space_count < config.need_space_count then
        self:BeginEvent(self.script_id)
        self:AddText(string.format("Túi không đủ chỗ, cần %d ô, đang có %d ô", config.need_space_count, space_count))
        self:EndEvent()
        self:DispatchEventList(selfId, -1)
        return
    end
    local item_count = self:LuaFnGetAvailableItemCount(selfId, 38008157)
    if item_count < config.need_count then
        self:BeginEvent(self.script_id)
        self:AddText(string.format("Thiên Ngoại Tệ cấp 1 không đủ, cần %d, có %d", config.need_count, item_count))
        self:EndEvent()
        self:DispatchEventList(selfId, -1)
        return
    end
    local r = self:LuaFnDelAvailableItem(selfId, 38008157, config.need_count)
    if not r then
        self:notify_tips(selfId, "Trừ thất bại, xin liên hệ hỗ trợ")
        return
    end
    self:BeginAddItem()
    self:AddItem(config.awards.item_id, config.awards.item_num)
    if not self:EndAddItem(selfId) then
        self:notify_tips(selfId,"Túi đồ không đủ chỗ trống.")
        return
    end
    self:AddItemListToHuman(selfId)
    self:notify_tips(selfId, "Đổi token thành công!")
end

function bet:ShowExchangeList(selfId)
    self:BeginEvent(self.script_id)
    self:AddText("Đổi đạo cụ game:")
    for _, op in ipairs(ExchangeConfigs) do
        self:AddNumText(op.desc, 0, op.id)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, -1)
end

function bet:DaiBiOneToDaiBiTwo(selfId, count)
    count = count or 1
    local cost_count = count * 100
    local item_count = self:LuaFnGetAvailableItemCount(selfId, 38008157)
    if item_count < cost_count then 
        self:notify_tips(selfId, string.format("Token 1 không đủ, hiện %d, cần %d", item_count, cost_count))
        return
    end
    self:BeginAddItem()
    self:AddItem(38008158, count)
    if not self:EndAddItem(selfId) then
        self:notify_tips(selfId,"Túi đồ không đủ chỗ trống.")
        return
    end
    local r = self:LuaFnDelAvailableItem(selfId, 38008157, cost_count)
    if not r then
        self:notify_tips(selfId, "Trừ thất bại, xin liên hệ hỗ trợ")
        return
    end
    self:AddItemListToHuman(selfId)
    self:notify_tips(selfId, "Đổi token thành công!")
end

function bet:DaiBiTwoToDaiBiOne(selfId, count)
    count = count or 1
    local cost_count = count
    local item_count = self:LuaFnGetAvailableItemCount(selfId, 38008158)
    if item_count < cost_count then
        self:notify_tips(selfId, string.format("Token 2 không đủ, hiện %d, cần %d", item_count, cost_count))
        return
    end
    self:BeginAddItem()
    self:AddItem(38008157, count * 100)
    if not self:EndAddItem(selfId) then
        self:notify_tips(selfId,"Túi đồ không đủ chỗ trống.")
        return
    end
    local r = self:LuaFnDelAvailableItem(selfId, 38008158, cost_count)
    if not r then
        self:notify_tips(selfId, "Trừ thất bại, xin liên hệ hỗ trợ")
        return
    end
    self:AddItemListToHuman(selfId)
    self:notify_tips(selfId, "Đổi token thành công!")
end

function bet:ShowUseMethod(selfId)

end


function bet:IsSkillLikeScript(selfId) return 0 end

return bet