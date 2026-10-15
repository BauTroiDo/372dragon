local class = require "class"
local define = require "define"
local script_base = require "script_base"
local common_item = class("common_item", script_base)
function common_item:IsSkillLikeScript()
    return 1
end

function common_item:CancelImpacts()
    return 0
end

function common_item:OnConditionCheck(selfId)
    if not self:LuaFnVerifyUsedItem(selfId) then
        return 0
    end
	local FreeSpace = self:LuaFnGetPropertyBagSpace(selfId)
	if( FreeSpace < 20 ) then
	    local strNotice = "Ô đạo cụ đầy, xin chừa 20 chỗ."
		self:notify_tips(selfId, strNotice)
	    return 0
	end
	return 1 --不需要任何条件，并且始终返回1。
end

function common_item:OnDeplete(selfId)
    return self:LuaFnDepletingUsedItem(selfId)
end

function common_item:OnActivateOnce(selfId)
	local FreeSpace = self:LuaFnGetPropertyBagSpace(selfId)
	if( FreeSpace < 20 ) then
	    local strNotice = "Ô đạo cụ đầy, xin chừa 20 chỗ."
		self:notify_tips(selfId, strNotice)
	    return 0
	end
    self:TryRecieveItem(selfId, 10415055, false)
    self:TryRecieveItem(selfId, 30120042, false)
	self:BeginAddItem()
    self:AddItem(30505822, 4500)
	self:AddItem(20310166, 400)
	self:AddItem(20310174, 400)
	self:AddItem(30900016, 350)
	self:AddItem(38008161, 400)
    if not self:EndAddItem(selfId) then
        self:notify_tips(selfId,"Túi đồ không đủ chỗ trống.")
        return
    end
    self:AddItemListToHuman(selfId)
    self:notify_tips(selfId, "Chúc mừng ngươi mở lễ bao siêu hời thành công!!")
	return 1
end

return common_item
