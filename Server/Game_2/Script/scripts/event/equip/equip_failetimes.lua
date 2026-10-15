local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local script_base = require "script_base"
local equip_failetimes = class("equip_failetimes", script_base)
equip_failetimes.script_id = 809265
function equip_failetimes:OnEnumerate(caller, selfId, targetId, arg, index) end
function equip_failetimes:EquipFaileTimes(selfId, nItemIndex1, nItemIndex2)
    local ret = self:LuaFnIsItemLocked(selfId, nItemIndex1)
    if ret then
        self:BeginEvent(self.script_id)
        self:AddText("Trang bị này không dùng được.")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return
    end
    ret = self:LuaFnIsItemAvailable(selfId, nItemIndex2)
    if not ret then
        self:BeginEvent(self.script_id)
        self:AddText("Nhuận Vật Lộ không thể dùng.")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return
    end
    local szTransfer = self:GetBagItemTransfer(selfId, nItemIndex2)
    local sy_index = self:LuaFnGetItemTableIndexByIndex(selfId, nItemIndex2)
    if sy_index ~= 30900007 and sy_index ~= 30900000 then
        self:BeginEvent(self.script_id)
        self:AddText("Giảm số lần sửa chữa thất bại Yêu cầu Nhuận Vật Lộ.")
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return
    end
    local text = "Sửa chữa thành công."
    local money = self:GetMoney(selfId)
    local jiaozi = self:GetMoneyJZ(selfId)
    local need_money = self:GetBagItemLevel(selfId, nItemIndex1) * 200
    if money + jiaozi < need_money then
        text = "Giảm Số lần sửa chữa thất bại của Trang bị này Yêu cầu #{_EXCHG%d}, tiền bạc trên người không đủ."
        text = self:format(text, need_money)
        self:BeginEvent(self.script_id)
        self:AddText(text)
        self:EndEvent()
        self:DispatchMissionTips(selfId)
        return
    end
    local szMsg
    local szName
    szName = self:GetName(selfId)
    if sy_index == 30900007 then
        ret = self:LuaFnFaileTimes(selfId, nItemIndex1, nItemIndex2, 1)
        szMsg = string.format("#W#{_INFOUSR%s}#Hdùng#W#{_INFOMSG%%s}#Hxong, số lần sửa được của trang bị tăng 1, tránh vỡ sau 3 lần sửa thất bại.",  szName)
    elseif sy_index == 30900000 then
        ret = self:LuaFnFaileTimes(selfId, nItemIndex1, nItemIndex2, 0)
        szMsg = string.format("#W#{_INFOUSR%s}#Hdùng#W#{_INFOMSG%%s}#Hxong, số lần sửa trang bị khôi phục về 3, tránh vỡ sau 3 lần sửa thất bại.", szName)
    end
    szMsg = gbk.fromutf8(szMsg)
    szMsg = string.format(szMsg, szTransfer)
    if ret == 0 then
        self:LuaFnCostMoneyWithPriority(selfId, need_money)
        self:LuaFnEraseItem(selfId, nItemIndex2)
        self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 49, 0)
        self:AddGlobalCountNews(szMsg, true)
    end
    if ret == -1 then text = "Lỗi không xác định." end
    if ret == -2 then text = "Trang bị không thể dùng." end
    if ret == -3 then text = "Nhuận Vật Lộ không thể dùng." end
    if ret == -4 then text = "Số lần sửa chữa thất bại đã thấp nhất rồi." end
    self:BeginEvent(self.script_id)
    self:AddText(text)
    self:EndEvent()
    self:DispatchMissionTips(selfId)
end

return equip_failetimes