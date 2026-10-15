local gbk = require "wire_charset"
local class = require "class"
local script_base = require "script_base"
local TJCPvPCnm = class("TJCPvPCnm", script_base)
local Exchange_Items = {
    { target = 20600002, need = 25 },
    { target = 20600045, need = 15 },
    { target = 20600003, need = 110 },
    { target = 20600046, need = 60 },
    { target = 38002818, need = 80 },
    { target = 38002817, need = 40 },
}
function TJCPvPCnm:Callback_Exchange(selfId, index)
    index = index + 1
    local Item = Exchange_Items[index]
    local Material_count = self:LuaFnGetAvailableItemCount(selfId, 38002808)
    if Material_count < Item.need then
        self:notify_tips(selfId, "Không đủ Uẩn Linh Mộc")
        return
    end
    self:BeginAddItem()
    self:AddItem(Item.target, 1)
    local ret = self:EndAddItem(selfId)
    if not ret then
        self:notify_tips(selfId, "Túi hành trang không đủ chỗ")
        return
    end
    self:LuaFnDelAvailableItem(selfId, 38002808, Item.need)
    self:AddItemListToHuman(selfId)
    self:notify_tips(selfId, "Đổi thành công.")
    self:LuaFnSendSpecificImpactToUnit(selfId, selfId, selfId, 49, 0)
    local fmt = "#W#{_INFOUSR%s}#Psau một phen nỗ lực, tại#GTrường Xuân Cốc - Bất Lão Điện#Pgom đủ#Y%d#Pcái#G%s#P. Để đáp tạ, Thanh Diên tặng một#G%s#P."
    local playerName = self:GetName(selfId)
    local msg = string.format(fmt, playerName, Item.need, self:GetItemName(38002808), self:GetItemName(Item.target))
    msg = gbk.fromutf8(msg)
    self:BroadMsgByChatPipe(selfId, msg, 4)
end

return TJCPvPCnm