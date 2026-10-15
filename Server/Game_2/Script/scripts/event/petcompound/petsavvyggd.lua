local pet_gameplay = require "cy_pet_gameplay"
-- 宠物悟性提升
local gbk = require "wire_charset"
local class = require "class"
local script_base = require "script_base"
local petsavvyggd = class("petsavvyggd", script_base)
local g_Name = "云霏霏"
-- 悟性等级对应元宝
local YuanBaoCosts = {
	[0] = 96000,
	[1] = 94000,
	[2] = 93000,
	[3] = 92000,
	[4] = 91000,
	[5] = 81000,
	[6] = 79000,
	[7] = 76000,
	[8] = 74000,
	[9] = 1550,
}
function petsavvyggd:OnDefaultEvent(selfId, targetId)
    if self:GetName(targetId) ~= g_Name then		--判断该 npc 是否是指定的npc
		return
	end
	self:BeginUICommand()
    self:UICommand_AddInt(targetId)
	self:EndUICommand()
	self:DispatchUICommand(selfId, 19820425)
end

function petsavvyggd:OnEnumerate(caller, _, targetId)
    if self:GetName(targetId) ~= g_Name then		--判断该 npc 是否是指定的npc
		return
	end
    caller:AddNumTextWithTarget(self.script_id, "Dùng trân thú trưởng thành tăng ngộ tính", 6, -2)
    caller:AddNumTextWithTarget(self.script_id, "Dùng Căn Cốt Đan tăng Ngộ Tính", 6, -1)
end

function petsavvyggd:PetSavvy(selfId,high,low)
    local ok,won=pet_gameplay.savvy(self,selfId,high,low,false)
    self:notify_tips(selfId,not ok and "Trân thú, nguyên liệu hoặc tiền không hợp lệ." or won==false and "Nâng cấp thất bại." or "Nâng cấp thành công.")
    return ok
end

function petsavvyggd:PetSavvy_YuanbaoPay(selfId, ItemIndex, check)
	local hint = "#{ZSYB_160113_28"
	local index, merchadise = self:GetMerchadiseByItemIndex(selfId, ItemIndex)
	if index == nil then
		return
	end
	self:BeginUICommand()
	self:UICommand_AddInt(5)
	self:UICommand_AddInt(5)
	self:UICommand_AddInt(merchadise.price)
	self:UICommand_AddInt(index - 1)
	self:UICommand_AddInt(0)
	self:UICommand_AddInt(self.script_id)
	self:UICommand_AddInt(check)
	self:UICommand_AddInt(131071)
	self:UICommand_AddInt(1)
	local str = self:ContactArgs(hint, merchadise.id, merchadise.price, "#{XFYH_20120221_10}", "#{XFYH_20120221_12}", merchadise.pnum or 1, merchadise.id) .. "}"
	self:UICommand_AddStr(str)
	self:EndUICommand()
	self:DispatchUICommand(selfId, 20120222)
end

function petsavvyggd:QuickPetSavvy(selfId,high,low)
    local ok,won=pet_gameplay.savvy(self,selfId,high,low,true)
    self:notify_tips(selfId,not ok and "Trân thú, nguyên liệu hoặc tiền không hợp lệ." or won==false and "Nâng cấp thất bại." or "Nâng cấp thành công.")
    return ok
end

return petsavvyggd