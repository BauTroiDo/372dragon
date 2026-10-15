local pet_gameplay = require "cy_pet_gameplay"
-- 宠物幻化
local gbk = require "wire_charset"
local class = require "class"
local script_base = require "script_base"
local pet_holy = class("pet_holy", script_base)
local g_m_money = { 10000 , 12000 , 14400 ,17280 , 20736,  24883 , 29860 , 35832 ,42998 , 51598}
local g_PetJingHun = {20310116,20310160,20310175}
-- 灵性等级对应元宝
local m_YuanBaoCosts = {
	[0] = 179280,
	[1] = 178560,
	[2] = 177120,
	[3] = 175320,
	[4] = 171720,
	[5] = 165600,
	[6] = 156240,
	[7] = 47120,
	[8] = 116040,
	[9] = 77760,
}
function pet_holy:Pet_HH(selfId,high,low,keep_model)
    local ok=pet_gameplay.awaken(self,selfId,high,low,keep_model)
    self:notify_tips(selfId,ok and "Huyễn hóa thành công." or "Trân thú, ngoại hình, nguyên liệu hoặc tiền không hợp lệ.")
    if ok then self:LuaFnSendSpecificImpactToUnit(selfId,selfId,selfId,18,0) end
    return ok
end

function pet_holy:Pet_LXUP(selfId,high,low)
    local ok,won=pet_gameplay.lingxing(self,selfId,high,low,false)
    self:notify_tips(selfId,not ok and "Trân thú, nguyên liệu hoặc tiền không hợp lệ." or won==false and "Nâng cấp thất bại." or "Nâng cấp thành công.")
    return ok
end

function pet_holy:Quick_Pet_LXUP(selfId,high,low)
    local ok,won=pet_gameplay.lingxing(self,selfId,high,low,true)
    self:notify_tips(selfId,not ok and "Trân thú, nguyên liệu hoặc tiền không hợp lệ." or won==false and "Nâng cấp thất bại." or "Nâng cấp thành công.")
    return ok
end

function pet_holy:PetLingxing_Yuanbao_Pay(selfId, ItemIndex, check)
    local hint = "#{ZSYB_151109_14"
	local index, merchadise = self:GetMerchadiseByItemIndex(selfId, ItemIndex)
	if index == nil then
		return
	end
    local item_name = self:GetItemName(merchadise.id)
	self:BeginUICommand()
	self:UICommand_AddInt(check)
    self:UICommand_AddInt(10)
	self:UICommand_AddInt(5)
	self:UICommand_AddInt(merchadise.price)
	self:UICommand_AddInt(index - 1)
    self:UICommand_AddInt(0)
	self:UICommand_AddInt(131071)
	local str = self:ContactArgs(hint, item_name, merchadise.price, item_name) .. "}"
	self:UICommand_AddStr(str)
	self:EndUICommand()
	self:DispatchUICommand(selfId, 2015101514)
end

return pet_holy