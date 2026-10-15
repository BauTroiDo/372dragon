local pet_gameplay = require "cy_pet_gameplay"
-- 宠物悟性提升
local class = require "class"
local script_base = require "script_base"
local petsavvy = class("petsavvy", script_base)
local g_Name = "云霏霏"
function petsavvy:OnDefaultEvent(selfId, targetId)
	if self:GetName(targetId) ~= g_Name then		--判断该 npc 是否是指定的npc
		return
	end
	self:BeginUICommand()
    self:UICommand_AddInt(targetId)
	self:EndUICommand()
	self:DispatchUICommand(selfId, 19820424)
end

function petsavvy:OnEnumerate(caller, _, targetId)
    if self:GetName(targetId) ~= g_Name then		--判断该 npc 是否是指定的npc
		return
	end
    --caller:AddNumTextWithTarget(self.script_id, "提升珍兽的悟性等级", 6, -1)
end

function petsavvy:PetSavvy(selfId,high,low,assist_high,assist_low)
    local ok,won=pet_gameplay.savvy(self,selfId,high,low,false,assist_high,assist_low)
    self:notify_tips(selfId,not ok and "Trân thú, căn cốt hoặc tiền không hợp lệ." or won and "Tăng ngộ tính thành công." or "Tăng ngộ tính thất bại.")
    return ok
end

function petsavvy:OnEventRequest(selfId, targetId, arg, index)
    if index == -1 then

    end
end

return petsavvy